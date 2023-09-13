'Ed Davis. Tiny Basic that can play Star Trek
'Supports: end, list, load, new, run, save
'gosub/return, goto, if input, print, multi-statement lines (:)
'a single numeric array: @(n), and rnd(n)
'fb -O 3 -gen gcc int-st.bas

const c_maxlines = 7000, c_maxvars = 26, c_at_max = 500, c_g_stack = 100
const c_tab = chr$(9), c_squote = chr$(39), c_dquote = chr$(34)

dim shared pgm(c_maxlines) as string ' program stored here
dim shared vars(c_maxvars) as long
dim shared gstackln(c_g_stack) as long    ' gosub line stack
dim shared gstacktp(c_g_stack) as long    ' gosub textp stack
dim shared gsp as long
dim shared atarry(c_at_max) as long ' the @ array
dim shared forvar(c_maxvars) as integer
dim shared forlimit(c_maxvars) as integer
dim shared forline(c_maxvars) as integer
dim shared forpos(c_maxvars) as integer

dim shared as string tok, toktype   ' current token, and it's type
dim shared as string thelin, thech  ' current program line, current character
dim shared curline as long, textp as long ' position in current line
dim shared num as long   ' last number read by scanner
dim shared errors as long
dim shared tracing as long
dim shared timestart as single

declare sub arrassn
declare sub assign
declare sub clearvars
declare sub docmd
declare sub expect(s as string)
declare sub forstmt
declare sub getch
declare sub gosubstmt
declare sub gotostmt
declare sub help
declare sub ifstmt
declare sub initlex(n as long)
declare sub initlex2
declare sub inputstmt
declare sub liststmt
declare sub loadstmt
declare sub newstmt
declare sub nextstmt
declare sub nexttok
declare sub printstmt
declare sub readident
declare sub readint
declare sub readstr
declare sub returnstmt
declare sub runstmt
declare sub savestmt
declare sub showtime(running as long)
declare sub skiptoeol
declare sub validlinenum
declare function accept(s as string) as long
declare function expression(minprec as long) as long
declare function getfilename(action as string) as string
declare function getvarindex as long
declare function parenexpr as long

call newstmt
if command <> "" then
    toktype = "string"
    tok = chr(34) + command
    loadstmt
    tok = "run"
    docmd
else
    help
end if
do
  errors = false
  line input "fb> ", pgm(0)
  if pgm(0) <> "" then
    initlex(0)
    if toktype = "number" then
      validlinenum
      if not errors then pgm(num) = mid(pgm(0), textp)
    else
      docmd
    end if
  end if
loop

sub docmd
  dim running as long
  do
    if tracing and left(tok, 1) <> ":" then print curline; tok; thech; mid(thelin, textp)
    select case tok
      case "bye", "quit" : nexttok: end
      case "end", "stop" : nexttok: return
      case "clear"       : nexttok: clearvars: return
      case "help"        : nexttok: help:      return
      case "list"        : nexttok: liststmt:  return
      case "load", "old" : nexttok: loadstmt:  return
      case "new"         : nexttok: newstmt:   return
      case "run"         : nexttok: runstmt: running = true
      case "save"        : nexttok: savestmt:  return
      case "tron"        : nexttok: tracing = true
      case "troff"       : nexttok: tracing = false
      case "cls"         : nexttok: cls
      case "for"         : nexttok: forstmt
      case "gosub"       : nexttok: gosubstmt
      case "goto"        : nexttok: gotostmt
      case "if"          : nexttok: ifstmt
      case "input"       : nexttok: inputstmt
      case "next"        : nexttok: nextstmt
      case "print", "?"  : nexttok: printstmt
      case "return"      : nexttok: returnstmt
      case "@"           : nexttok: arrassn
      case ":"           : nexttok  ' just continue
      case ""            : ' handled below
      case else
        if tok = "let" then nexttok
        if toktype = "ident" then
          assign
        else
          print "Unknown token "; tok; " at line "; curline: errors = true
        end if
    end select

    if errors then return
    if curline > c_maxlines then showtime(running): return
    do while tok = ""
      if curline = 0 or curline >= c_maxlines then showtime(running): return
      initlex(curline + 1)
    loop
  loop
end sub

sub showtime(running as long)
  if running then print "Took : " + str(timer - timestart) + " seconds"
end sub

sub help
   print "ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Tiny Basic Help (FreeBasic)ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿"
   print "³ bye, clear, end, help, list, load, new, run, save, stop             ³Û"
   print "³ goto <expr>                                                         ³Û"
   print "³ gosub <expr> ... return                                             ³Û"
   print "³ if <expr> then <statement>                                          ³Û"
   print "³ input [prompt,] <var>                                               ³Û"
   print "³ <var>=<expr>                                                        ³Û"
   print "³ print <expr|string>[,<expr|string>][;]                              ³Û"
   print "³ rem <anystring>                                                     ³Û"
   print "³ Operators: + - * / < <= > >= <> =                                   ³Û"
   print "³ Integer variables a..z, and array @(expr)                           ³Û"
   print "³ Functions: rnd(expr)                                                ³Û"
   print "ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙÛ"
   print "  ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß"
end sub

sub assign
  dim thevar as long
  thevar = getvarindex: nexttok
  expect("=")
  vars(thevar) = expression(0)
  if tracing then print "*** "; chr(thevar + asc("a")); " = "; vars(thevar)
end sub

sub arrassn   ' array assignment: @(expr) = expr
  dim n as long, atndx as long

  atndx = parenexpr
  if tok <> "=" then
    print "Array Assign: Expecting '=', found:"; tok: errors = true
  else
    nexttok     ' skip the "="
    n = expression(0)
    atarry(atndx) = n
    if tracing then print "*** @("; atndx; ") = "; n
  end if
end sub

sub forstmt   ' for i = expr to expr
  dim as long thevar, n, forndx

  thevar = getvarindex
  assign
  ' vars(thevar) has the value; thevar has the number value of the variable in 0..25
  forndx = thevar
  forvar(forndx) = vars(thevar)
  if tok <> "to" then
    print "For: Expecting 'to', found:"; tok: errors = true
  else
    nexttok
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

  gotostmt
end sub

sub gotostmt
  num = expression(0)
  validlinenum
  initlex(num)
end sub

sub ifstmt
  if expression(0) = 0 then skiptoeol: return
  if tok = "then" then nexttok
  if toktype = "number" then gotostmt
end sub

sub inputstmt   ' "input" [string ","] var
  dim thevar as long, st as string
  if toktype = "string" then
    print mid(tok, 2);
    nexttok
    expect(",")
  else
    print "? ";
  end if
  thevar = getvarindex: nexttok
  line input st
  if st = "" then st = "0"
  if left(st, 1) >= "0" and left(st, 1) <= "9" then
    vars(thevar) = val(st)
  else
    vars(thevar) = asc(st)
  end if
end sub

sub liststmt
  dim i as long
  for i = 1 to c_maxlines
    if pgm(i) <> "" then print i; " "; pgm(i)
  next i
  print
end sub

sub loadstmt
  dim n as long, filename as string

  newstmt
  filename = getfilename("Load")
  if filename = "" then return
  open filename for input as #1
  n = 0
  while not eof(1)
    line input #1, pgm(0)
    initlex(0)
    if toktype = "number" and num > 0 and num <= c_maxlines then
      n = num
    else
      n = n + 1: textp = 1
    end if
    pgm(n) = mid(pgm(0), textp)
  wend
  close #1
  curline = 0
end sub

sub newstmt
  dim i as long
  clearvars
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
    'print "nextstmt tok>"; tok; " textp>"; textp; " >"; mid(thelin, textp)
    initlex2
  else
    nexttok ' skip the ident for now
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
      if num <= 0 then print "Expecting a print width, found:"; tok: return
      printwidth = num
      nexttok
      if not accept(",") then print "Print: Expecting a ',', found:"; tok: return
    end if

    if toktype = "string" then
      junk = mid(tok, 2)
      nexttok
    else
      n = expression(0)
      junk = ltrim(str(n))
    end if
    printwidth = printwidth - len(junk)
    if printwidth <= 0 then print junk; else print space(printwidth); junk;

    if accept(",") or accept(";") then printnl = false else exit do
  loop

  if printnl then print
end sub

sub returnstmt    ' return from a subroutine
  curline = gstackln(gsp)
  textp   = gstacktp(gsp)
  gsp = gsp - 1
  initlex2
end sub

sub runstmt
  timestart = timer
  clearvars
  initlex(1)
end sub

sub savestmt
  dim i as long, filename as string

  newstmt
  filename = getfilename("Save")
  if filename = "" then return
  open filename for output as #1
  for i = 1 to c_maxlines
    if pgm(i) <> "" then print #1, i; pgm(i)
  next i
  close #1
end sub

function getfilename(action as string) as string
  dim filename as string
  if toktype = "string" then
    filename = mid(tok, 2)
  else
    print action; ": ";
    line input filename
  end if
  if filename <> "" then
    if instr(filename, ".") = 0 then filename = filename + ".bas"
  end if
  return filename
end function

sub validlinenum
  if num <= 0 or num > c_maxlines then print "Line number out of range": errors = true
end sub

sub clearvars
  dim i as long
  for i = 1 to c_maxvars
    vars(i) = 0
  next i
  gsp = 0
end sub

function parenexpr as long
  dim n as long
  expect("(")
  n = expression(0)
  expect(")")
  return n
end function

function expression(minprec as long) as long
  dim n as long

  ' handle numeric operands - numbers and unary operators
  if 0 then ' to allow elseif
  elseif toktype = "number" then n = num: nexttok
  elseif tok = "("   then n =  parenexpr
  elseif tok = "not" then nexttok: n = not expression(3)
  elseif tok = "abs" then nexttok: n = abs(parenexpr)
  elseif tok = "asc" then nexttok: expect("("): n = asc(mid(tok, 2, 1)): nexttok: expect(")")
  elseif tok = "rnd" or tok = "irnd" then nexttok: n = int(rnd * parenexpr) + 1
  elseif tok = "sgn" then nexttok: n = sgn(parenexpr)
  elseif toktype = "ident" then n = vars(getvarindex): nexttok
  elseif tok = "@"   then nexttok: n = atarry(parenexpr)
  elseif tok = "-"   then nexttok: n = -expression(7)
  elseif tok = "+"   then nexttok: n =  expression(7)
  else print "syntax error: expecting an operand, found: ", tok: errors = true: return 0
  end if

  do  ' while binary operator and precedence of tok >= minprec
    if 0 then ' to allow elseif
    elseif minprec <= 1 and tok = "or"  then nexttok: n = n or expression(2)
    elseif minprec <= 2 and tok = "and" then nexttok: n = n and expression(3)
    elseif minprec <= 4 and tok = "="   then nexttok: n = abs(n = expression(5))
    elseif minprec <= 4 and tok = "<"   then nexttok: n = abs(n < expression(5))
    elseif minprec <= 4 and tok = ">"   then nexttok: n = abs(n > expression(5))
    elseif minprec <= 4 and tok = "<>"  then nexttok: n = abs(n <> expression(5))
    elseif minprec <= 4 and tok = "<="  then nexttok: n = abs(n <= expression(5))
    elseif minprec <= 4 and tok = ">="  then nexttok: n = abs(n >= expression(5))
    elseif minprec <= 5 and tok = "+"   then nexttok: n = n + expression(6)
    elseif minprec <= 5 and tok = "-"   then nexttok: n = n - expression(6)
    elseif minprec <= 6 and tok = "*"   then nexttok: n = n * expression(7)
    elseif minprec <= 6 and (tok = "/" or tok = "\") then nexttok: n = n \ expression(7)
    elseif minprec <= 6 and tok = "mod" then nexttok: n = n mod expression(7)
    elseif minprec <= 8 and tok = "^"   then nexttok: n = CLng(n ^ expression(9))
    else exit do
    end if
  loop

  return n
end function

function getvarindex as long
  if toktype <> "ident" then print "Not a variable:"; tok: errors = true: return 0
  return asc(left(tok, 1)) - asc("a")
end function

sub expect(s as string)
  if tok = s then nexttok: return
  print "("; curline; ") expecting "; s; " but found "; tok; " =>"; pgm(curline): errors = true
end sub

function accept(s as string) as long
  if tok = s then nexttok: return true else return false
end function

sub initlex(n as long)
  curline = n
  textp = 1
  initlex2
end sub

sub initlex2
  thelin = pgm(curline)
  thech = " "
  nexttok
end sub

sub nexttok
  tok = "": toktype = ""
  while thech <= " "
    if thech = "" then return
    getch
  wend
  tok = thech: getch
  select case tok
    case "a" to "z", "A" to "Z": readident: if tok = "rem" then skiptoeol
    case "0" to "9": readint
    case c_squote: skiptoeol
    case c_dquote: readstr
    case "#","(",")","*","+",",","-","/",":",";","<","=",">","?","@","\","^":
      toktype = "punct"
      if (tok = "<" and (thech = ">" or thech = "=")) or (tok = ">" and thech = "=") then
        tok = tok + thech
        getch
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
    getch
  wend
  num = val(tok)
end sub

sub readident
  toktype = "ident"
  while (thech >= "a" and thech <= "z") or (thech >= "A" and thech <= "Z")
    tok = tok + thech
    getch
  wend
  tok = lcase$(tok)
end sub

sub readstr ' store double quote as first char of string, to distinguish from idents
  toktype = "string"
  while thech <> chr$(34) ' while not a double quote
    if thech = "" then print "String not terminated": errors = true: return
    tok = tok + thech
    getch
  wend
  getch  ' skip closing double quote
end sub

sub getch
  if textp > len(thelin) then
    thech = ""
  else
    thech = mid$(thelin, textp, 1)
    textp = textp + 1
  end if
end sub
