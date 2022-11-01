'Ed Davis. Tiny Basic that can play Star Trek
$console:only
option _explicit

const true = -1, false = 0, c_maxlines = 7000, c_maxvars = 26, c_at_max = 500, c_g_stack = 100
dim shared as string c_tab, c_squote, c_dquote
c_tab = chr$(9): c_squote = chr$(39): c_dquote = chr$(34)

dim shared pgm(c_maxlines) as string  ' program stored here
dim shared vars(c_maxvars) as long
dim shared gstackln(c_g_stack) as integer        ' gosub line stack
dim shared gstacktp(c_g_stack) as integer        ' gosub textp stack
dim shared gsp as long
dim shared atarry(c_at_max) as integer           ' the @ array
dim shared forvar(c_maxvars) as integer
dim shared forlimit(c_maxvars) as integer
dim shared forline(c_maxvars) as integer
dim shared forpos(c_maxvars) as integer

dim shared as string tok, toktype     ' current token, and it's type
dim shared as string thelin, thech    ' current program line, current character
dim shared as integer curline, textp  ' position in current line
dim shared num as long                ' last number read by scanner
dim shared as integer errors, tracing, need_colon

declare function accept&(s as string)
declare function expression&(minprec as integer)
declare function getfilename$(action as string)
declare function getvarindex&
declare function inputexpression&(s as string)
declare function parenexpr&

call newstmt
if command$ <> "" then
    toktype = "string": tok = c_dquote + command$
    call loadstmt
    tok = "run": call docmd
else
    call help
end if
do
  errors = false
  line input "qb> ", pgm(0)
  if pgm(0) <> "" then
    call initlex(0)
    if toktype = "number" then
      call validlinenum
      if not errors then pgm(num) = mid$(pgm(0), textp)
    else
      call docmd
    end if
  end if
loop

sub docmd
  do
    if tracing and left$(tok, 1) <> ":" then print curline; tok; thech; mid$(thelin, textp)
    need_colon = true
    select case tok
      case "bye", "quit" : call nexttok: end
      case "end", "stop" : call nexttok: exit sub
      case "clear"       : call nexttok: call clearvars: exit sub
      case "help"        : call nexttok: call help:      exit sub
      case "list"        : call nexttok: call liststmt:  exit sub
      case "load", "old" : call nexttok: call loadstmt:  exit sub
      case "new"         : call nexttok: call newstmt:   exit sub
      case "run"         : call nexttok: call runstmt
      case "save"        : call nexttok: call savestmt:  exit sub
      case "tron"        : call nexttok: tracing = true
      case "troff"       : call nexttok: tracing = false
      case "cls"         : call nexttok: cls
      case "for"         : call nexttok: call forstmt
      case "gosub"       : call nexttok: call gosubstmt
      case "goto"        : call nexttok: call gotostmt
      case "if"          : call nexttok: call ifstmt
      case "input"       : call nexttok: call inputstmt
      case "next"        : call nexttok: call nextstmt
      case "print", "?"  : call nexttok: call printstmt
      case "return"      : call nexttok: call returnstmt
      case "@"           : call nexttok: call arrassn
      case ":", ""         ' handled below
      case else
        if tok = "let" then call nexttok
        if toktype = "ident" then
          call assign
        else
          print "Unknown token '"; tok; "' at line:"; curline; " Col:"; textp; " : "; thelin: errors = true
        end if
    end select

    if errors then exit sub
    if tok = "" then
      while tok = ""
        if curline = 0 or curline >= c_maxlines then exit sub
        call initlex(curline + 1)
      wend
    elseif tok = ":" then call nexttok
    elseif need_colon and not accept(":") then
      print ": expected but found: "; tok
      exit sub
    end if
  loop
end sub

sub help
   print "ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Tiny Basic (QBASIC) --------ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿"
   print "³ bye, clear, cls, end/stop, help, list, load/save, new, run, tron/off³Û"
   print "³ for <var> = <expr1> to <expr2> ... next <var>                       ³Û"
   print "³ gosub <expr> ... return                                             ³Û"
   print "³ goto <expr>                                                         ³Û"
   print "³ if <expr> then <statement>                                          ³Û"
   print "³ input [prompt,] <var>                                               ³Û"
   print "³ <var>=<expr>                                                        ³Û"
   print "³ print <expr|string>[,<expr|string>][;]                              ³Û"
   print "³ rem <anystring>  or ' <anystring>                                   ³Û"
   print "³ Operators: ^, * / \ mod + - < <= > >= = <>, not, and, or            ³Û"
   print "³ Integer variables a..z, and array @(expr)                           ³Û"
   print "³ Functions: abs(expr), asc(ch), rnd(expr), sgn(expr)                 ³Û"
   print "ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙÛ"
   print "  ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß"
end sub

sub assign
  dim var as long
  var = getvarindex: call nexttok
  call expect("=")
  vars(var) = expression(0)
  if tracing then print "*** "; chr$(var + asc("a")); " = "; vars(var)
end sub

sub arrassn   ' array assignment: @(expr) = expr
  dim as long n, atndx

  atndx = parenexpr
  if tok <> "=" then
    print "Array Assign: Expecting '=', found:"; tok: errors = true
  else
    call nexttok     ' skip the "="
    n = expression(0)
    atarry(atndx) = n
    if tracing then print "*** @("; atndx; ") = "; n
  end if
end sub

sub forstmt   ' for i = expr to expr
  dim as long var, n, forndx

  var = getvarindex
  call assign
  ' vars(var) has the value; var has the number value of the variable in 0..25
  forndx = var
  forvar(forndx) = vars(var)
  if tok <> "to" then
    print "For: Expecting 'to', found:"; tok: errors = true
  else
    call nexttok
    n = expression(0)
    forlimit(forndx) = n
    ' need to store iter, limit, line, and col
    forline(forndx) = curline
    if tok = "" then forpos(forndx) = textp else forpos(forndx) = textp - 2
  end if
end sub

sub gosubstmt   ' for gosub: save the line and column
  gsp = gsp + 1
  gstackln(gsp) = curline
  gstacktp(gsp) = textp

  call gotostmt
end sub

sub gotostmt
  num = expression(0)
  call validlinenum
  call initlex(num)
end sub

sub ifstmt
  need_colon = false
  if expression(0) = 0 then call skiptoeol: exit sub
  if tok = "then" then call nexttok
  if toktype = "number" then call gotostmt
end sub

sub inputstmt   ' "input" [string ","] var
  dim var as long, st as string
  if toktype = "string" then
    print mid$(tok, 2);
    call nexttok
    call expect(",")
  else
    print "? ";
  end if
  var = getvarindex: call nexttok
  line input st
  if st = "" then st = "0"

  if left$(st, 1) >= "0" and left$(st, 1) <= "9" then
    vars(var) = val(st)
  else
    vars(var) = asc(st)
  end if
  ' to emulate Palo Alto Tiny Basic
  'vars(var) = inputexpression(st)
end sub

sub liststmt
  dim i as integer
  for i = 1 to c_maxlines
    if pgm(i) <> "" then print i; " "; pgm(i)
  next i
  print
end sub

sub loadstmt
  dim n as long, filename as string

  call newstmt
  filename = getfilename("Load")
  if filename = "" then exit sub
  open filename for input as #1
  n = 0
  while not eof(1)
    line input #1, pgm(0)
    call initlex(0)
    if toktype = "number" and num > 0 and num <= c_maxlines then
      n = num
    else
      n = n + 1: textp = 1
    end if
    pgm(n) = mid$(pgm(0), textp)
  wend
  close #1
  curline = 0
end sub

sub newstmt
  dim i as integer
  call clearvars
  for i = 1 to c_maxlines
    pgm(i) = ""
  next i
end sub

sub nextstmt
  dim forndx as long

  ' tok needs to have the variable
  forndx = getvarindex
  forvar(forndx) = forvar(forndx) + 1
  vars(forndx) = forvar(forndx)
  if forvar(forndx) <= forlimit(forndx) then
    curline = forline(forndx)
    textp   = forpos(forndx)
    'print "nextstmt tok>"; tok; " textp>"; textp; " >"; mid$(thelin, textp)
    call initlex2
  else
    call nexttok ' skip the ident for now
  end if
end sub

' "print" [[#num "," ] expr { "," [#num ","] expr }] [","] {":" stmt} eol
' expr can also be a literal string
sub printstmt
  dim as long printnl, printwidth, n
  dim junk as string

  printnl = true
  do while tok <> ":" and tok <> "" and tok <> "else"
    printnl = true
    printwidth = 0
    if accept("#") then
      if num <= 0 then print "Expecting a print width, found:"; tok: exit sub
      printwidth = num
      call nexttok
      if not accept(",") then print "Print: Expecting a ',', found:"; tok: exit sub
    end if

    if toktype = "string" then
      junk = mid$(tok, 2)
      call nexttok
    else
      n = expression(0)
      junk = ltrim$(str$(n))
    end if
    printwidth = printwidth - len(junk)
    if printwidth <= 0 then print junk; else print space$(printwidth); junk;

    if accept(",") or accept(";") then printnl = false else exit do
  loop

  if printnl then print
end sub

sub returnstmt ' exit sub from a subroutine
  curline = gstackln(gsp)
  textp   = gstacktp(gsp)
  gsp = gsp - 1
  call initlex2
end sub

sub runstmt
  call clearvars
  call initlex(1)
end sub

sub savestmt
  dim i as long,  filename as string

  filename = getfilename("Save")
  if filename = "" then exit sub
  open filename for output as #1
  for i = 1 to c_maxlines
    if pgm(i) <> "" then print #1, i; pgm(i)
  next i
  close #1
end sub

function getfilename$(action as string)
  dim filename as string
  if toktype = "string" then
    filename = mid$(tok, 2)
  else
    print action; ": ";
    line input filename
  end if
  if filename <> "" then
    if instr(filename, ".") = 0 then filename = filename + ".bas"
  end if
  getfilename = filename
end function

sub validlinenum
  if num <= 0 or num > c_maxlines then print "Line number out of range": errors = true
end sub

sub clearvars
  dim i as integer
  for i = 1 to c_maxvars
    vars(i) = 0
  next i
  gsp = 0
end sub

function parenexpr&
  call expect("("): if errors then exit function
  parenexpr = expression(0)
  call expect(")")
end function

function expression&(minprec as integer)
  dim n as long

  ' handle numeric operands - numbers and unary operators
  if 0 then ' to allow elseif
  elseif toktype = "number" then n = num: call nexttok
  elseif tok = "("   then n =  parenexpr
  elseif tok = "not" then call nexttok: n = not expression(3)
  elseif tok = "abs" then call nexttok: n = abs(parenexpr)
  elseif tok = "asc" then call nexttok: expect("("): n = asc(mid$(tok, 2, 1)): call nexttok: expect(")")
  elseif tok = "rnd" or tok = "irnd" then call nexttok: n = int(rnd * parenexpr) + 1
  elseif tok = "sgn" then call nexttok: n = sgn(parenexpr)
  elseif toktype = "ident" then n = vars(getvarindex): call nexttok
  elseif tok = "@"   then call nexttok: n = atarry(parenexpr)
  elseif tok = "-"   then call nexttok: n = -expression(7)
  elseif tok = "+"   then call nexttok: n =  expression(7)
  else print "syntax error: expecting an operand, found: ", tok: errors = true: exit function
  end if

  do  ' while binary operator and precedence of tok >= minprec
    if 0 then ' to allow elseif
    elseif minprec <= 1 and tok = "or"  then call nexttok: n = n or expression(2)
    elseif minprec <= 2 and tok = "and" then call nexttok: n = n and expression(3)
    elseif minprec <= 4 and tok = "="   then call nexttok: n = abs(n = expression(5))
    elseif minprec <= 4 and tok = "<"   then call nexttok: n = abs(n < expression(5))
    elseif minprec <= 4 and tok = ">"   then call nexttok: n = abs(n > expression(5))
    elseif minprec <= 4 and tok = "<>"  then call nexttok: n = abs(n <> expression(5))
    elseif minprec <= 4 and tok = "<="  then call nexttok: n = abs(n <= expression(5))
    elseif minprec <= 4 and tok = ">="  then call nexttok: n = abs(n >= expression(5))
    elseif minprec <= 5 and tok = "+"   then call nexttok: n = n + expression(6)
    elseif minprec <= 5 and tok = "-"   then call nexttok: n = n - expression(6)
    elseif minprec <= 6 and tok = "*"   then call nexttok: n = n * expression(7)
    elseif minprec <= 6 and (tok = "/" or tok = "\") then call nexttok: n = n \ expression(7)
    elseif minprec <= 6 and tok = "mod" then call nexttok: n = n mod expression(7)
    elseif minprec <= 8 and tok = "^"   then call nexttok: n = CLng(n ^ expression(9))
    else exit do
    end if
  loop

  expression = n
end function

function inputexpression&(s as string)
  dim as long save_curline, save_textp
  dim as string save_thelin, save_thech, save_tok, save_toktype

  save_curline = curline: save_textp = textp: save_thelin = thelin: save_thech = thech: save_tok = tok: save_toktype = toktype

  pgm(0) = s
  call initlex(0)
  inputexpression = expression(0)

  curline = save_curline: textp = save_textp: thelin = save_thelin: thech = save_thech: tok = save_tok: toktype = save_toktype
end function

function getvarindex&
  if toktype <> "ident" then print "Not a variable:"; tok: errors = true: exit function
  getvarindex = asc(left$(tok, 1)) - asc("a")
end function

sub expect(s as string)
  if accept(s) then exit sub
  print "("; curline; ") expecting "; s; " but found "; tok; " =>"; pgm(curline): errors = true
end sub

function accept&(s as string)
  accept = false
  if tok = s then accept = true: call nexttok
end function

sub initlex(n as integer)
  curline = n: textp = 1
  call initlex2
end sub

sub initlex2
  need_colon = false
  thelin = pgm(curline)
  thech = " "
  call nexttok
end sub

sub nexttok
  tok = "": toktype = ""
  while thech <= " "
    if thech = "" then exit sub
    call getch
  wend
  tok = thech: call getch
  select case tok
    case "a" to "z", "A" to "Z": call readident: if tok = "rem" then call skiptoeol
    case "0" to "9": call readint
    case c_squote: call skiptoeol
    case c_dquote: call readstr
    case "#","(",")","*","+",",","-","/",":",";","<","=",">","?","@","\","^":
      toktype = "punct"
      if (tok = "<" and (thech = ">" or thech = "=")) or (tok = ">" and thech = "=") then
        tok = tok + thech
        call getch
      end if
    case else: print "("; curline; ") "; "What?"; tok; " : "; thelin: errors = true
  end select
end sub

sub skiptoeol
  tok = "": toktype = ""
  textp = len(thelin) + 1
end sub

sub readint
  toktype = "number"
  while thech >= "0" and thech <= "9"
    tok = tok + thech
    call getch
  wend
  num = val(tok)
end sub

sub readident
  toktype = "ident"
  while (thech >= "a" and thech <= "z") or (thech >= "A" and thech <= "Z")
    tok = tok + thech
    call getch
  wend
  tok = lcase$(tok)
end sub

sub readstr ' store double quote as first char of string, to distinguish from idents
  toktype = "string"
  while thech <> c_dquote ' while not a double quote
    if thech = "" then print "String not terminated": errors = true: exit sub
    tok = tok + thech
    call getch
  wend
  call getch  ' skip closing double quote
end sub

sub getch
  if textp > len(thelin) then
    thech = ""
  else
    thech = mid$(thelin, textp, 1)
    textp = textp + 1
  end if
end sub
