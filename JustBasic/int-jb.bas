'Ed Davis. Tiny Basic that can play Star Trek
global true, false, cmaxlines, cmaxvars, catmax, cgstack
global cdefault, cident, cnumber, cstring, cpunct

true = -1: false = 0: cmaxlines = 7000: cmaxvars = 26: catmax = 500: cgstack = 100
cdefault = 0: cident = 1: cnumber = 2: cstring = 3: cpunct = 4

dim pgm$(cmaxlines)            ' program stored here
dim vars(cmaxvars)
dim gstackln(cgstack)         ' gosub line stack
dim gstacktp(cgstack)         ' gosub textp stack

dim  atarry(catmax)           ' the @ array
dim  forvar(cmaxvars)
dim  forlimit(cmaxvars)
dim  forline(cmaxvars)
dim  forpos(cmaxvars)

global gsp                  ' gosub stack index
global tok$                 ' current token, and it's type
global thelin$, thech$      ' current program line, current character
global curline, textp       ' position in current line
global num                  ' last number read by scanner
global toktype, errors, tracing, needcolon

call newstmt
if command$ <> "" then
    toktype = cstring: tok$ = chr$(34) + command$
    call loadstmt
    tok$ = "run": call docmd
else
    call help
end if
do while true
  errors = false
  print "lb> ";
  line input pgm$(0)
  if pgm$(0) <> "" then
    call initlex 0
    if toktype = cnumber then
      call validlinenum
      if errors = 0 then pgm$(num) = mid$(pgm$(0), textp)
    else
      call docmd
    end if
  end if
loop

sub docmd
  do while true
    if tracing and left$(tok$, 1) <> ":" then print "["; curline; "] "; tok$; thech$; mid$(thelin$, textp)
    needcolon = true
    select case tok$
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
        if tok$ = "let" then call nexttok
        if toktype = cident then
          call assign
        else
          print "Unknown token '"; tok$; "' at line:"; curline; " Col:"; textp; " : "; thelin$: errors = true
        end if
    end select

    if errors then exit sub
    if tok$ = "" then
      while tok$ = ""
        if curline = 0 or curline >= cmaxlines then exit sub
        call initlex curline + 1
      wend
    else
      if tok$ = ":" then
        call nexttok
      else
        if needcolon and accept(":") = false then
          print ": expected but found: "; tok$
          exit sub
        end if
      end if
    end if
  loop
end sub

sub help
   print "+---------------------- Tiny Basic (Just Basic)-----------------------+"
   print "| bye, clear, cls, end/stop, help, list, load/save, new, run, tron/off|"
   print "| for <var> = <expr1> to <expr2> ... next <var>                       |"
   print "| gosub <expr> ... return                                             |"
   print "| goto <expr>                                                         |"
   print "| if <expr> then <statement>                                          |"
   print "| input [prompt,] <var>                                               |"
   print "| <var>=<expr>                                                        |"
   print "| print <expr|string>[,<expr|string>][;]                              |"
   print "| rem <anystring>  or ' <anystring>                                   |"
   print "| Operators: ^, * / \ mod + - < <= > >= = <>, not, and, or            |"
   print "| Integer variables a..z, and array @(expr)                           |"
   print "| Functions: abs(expr), asc(ch), rnd(expr), sgn(expr)                 |"
   print "+---------------------------------------------------------------------+"
end sub

sub assign
  var = getvarindex(): call nexttok
  call expect "="
  vars(var) = expression(0)
  if tracing then print "*** "; chr$(var + asc("a")); " = "; vars(var)
end sub

sub arrassn   ' array assignment: @(expr) = expr
  atndx = parenexpr()
  if tok$ <> "=" then
    print curline; " Array Assign: Expecting '=', found:"; tok$: errors = true
  else
    call nexttok     ' skip the "="
    n = expression(0)
    atarry(atndx) = n
    if tracing then print "*** @("; atndx; ") = "; n
  end if
end sub

sub forstmt   ' for i = expr to expr
  var = getvarindex()
  call assign
  ' vars(var) has the value; var has the number value of the variable in 0..25
  forndx = var
  forvar(forndx) = vars(var)
  if tok$ <> "to" then
    print "For: Expecting 'to', found:"; tok$: errors = true
  else
    call nexttok
    forlimit(forndx) = expression(0)
    ' need to store iter, limit, line, and col
    forline(forndx) = curline
    if tok$ = "" then forpos(forndx) = textp else forpos(forndx) = textp - 1
  end if
end sub

sub gosubstmt   ' for gosub: save the line and column
  gsp = gsp + 1
  num = expression(0)
  gstackln(gsp) = curline
  if tok$ = "" then gstacktp(gsp) = textp else gstacktp(gsp) = textp - 1
  call validlinenum
  call initlex num
end sub

sub gotostmt
  num = expression(0)
  call validlinenum
  call initlex num
end sub

sub ifstmt
  needcolon = false
  if expression(0) = 0 then call skiptoeol: exit sub
  if tok$ = "then" then call nexttok
  if toktype = cnumber then call gotostmt
end sub

sub inputstmt   ' "input" [string ","] var
  if toktype = cstring then
    print mid$(tok$, 2);
    call nexttok
    call expect ","
  else
    print "? ";
  end if
  var = getvarindex(): call nexttok
  line input st$
  if st$ = "" then st$ = "0"
  if (left$(st$, 1) >= "0" and left$(st$, 1) <= "9") or left$(st$, 1) = "-" then
    vars(var) = val(st$)
  else
    vars(var) = asc(st$)
  end if
end sub

sub liststmt
  for i = 1 to cmaxlines
    if pgm$(i) <> "" then print i; " "; pgm$(i)
  next i
  print
end sub

sub loadstmt
  call newstmt
  filename$ = getfilename$("Load")
  if filename$ = "" then exit sub
  open filename$ for input as #1
  n = 0
  while eof(#1) = 0
    line input #1, pgm$(0)
    call initlex 0
    if toktype = cnumber and num > 0 and num <= cmaxlines then
      n = num
    else
      n = n + 1: textp = 1
    end if
    pgm$(n) = mid$(pgm$(0), textp)
  wend
  close #1
  curline = 0
end sub

sub newstmt
  call clearvars
  for i = 1 to cmaxlines
    pgm$(i) = ""
  next i
end sub

sub nextstmt
  ' tok$ needs to have the variable
  forndx = getvarindex()
  forvar(forndx) = forvar(forndx) + 1
  vars(forndx) = forvar(forndx)
  if forvar(forndx) <= forlimit(forndx) then
    curline = forline(forndx)
    textp   = forpos(forndx)
    call initlex2
  else
    call nexttok ' skip the ident for now
  end if
end sub

' "print" [[#num "," ] expr { "," [#num ","] expr }] [","] {":" stmt} eol
' expr can also be a literal string
sub printstmt
  printnl = true
  do while tok$ <> ":" and tok$ <> "" and tok$ <> "else"
    printnl = true
    printwidth = 0
    if accept("#") then
      if num <= 0 then print "Expecting a print width, found:"; tok$: exit sub
      printwidth = num
      call nexttok
      if accept(",") = false then print "Print: Expecting a ',', found:"; tok$: exit sub
    end if

    if toktype = cstring then
      junk$ = mid$(tok$, 2)
      call nexttok
    else
      if toktype = cident and tok$ = "chr" and thech$ = "$" then
        textp = textp + 1 ' consume $
        call nexttok      ' get (
        n = parenexpr()
        junk$ = chr$(n)
      else
        n = expression(0)
        junk$ = trim$(str$(n))
      end if
    end if
    printwidth = printwidth - len(junk$)
    if printwidth <= 0 then print junk$; else print space$(printwidth); junk$;

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
  call initlex 1
end sub

sub savestmt
  filename$ = getfilename$("Save")
  if filename$ = "" then exit sub
  open filename$ for output as #1
  for i = 1 to cmaxlines
    if pgm$(i) <> "" then print #1, i; pgm$(i)
  next i
  close #1
end sub

function getfilename$(action$)
  if toktype = cstring then
    filename$ = mid$(tok$, 2)
  else
    print action$; ": ";
    line input filename$
  end if
  if filename$ <> "" then
    if instr(filename$, ".") = 0 then filename$ = filename$ + ".bas"
  end if
  getfilename$ = filename$
end function

sub validlinenum
  if num <= 0 or num > cmaxlines then print "Line number out of range": errors = true
end sub

sub clearvars
  for i = 1 to cmaxvars
    vars(i) = 0
  next i
  gsp = 0
end sub

function parenexpr()
  call expect "(": if errors <> 0 then exit function
  parenexpr = expression(0)
  call expect ")"
end function

function expression(minprec)
  ' handle numeric operands - numbers and unary operators
  select case
    case toktype = cnumber: n = num: call nexttok
    case tok$ = "("  : n =  parenexpr()
    case tok$ = "not": call nexttok: n = expression(3) = 0
    case tok$ = "abs": call nexttok: n = abs(parenexpr())
    case tok$ = "asc": call nexttok: call expect "(": n = asc(mid$(tok$, 2, 1)): call nexttok: call expect ")"
    case tok$ = "rnd" or tok$ = "irnd": call nexttok: n = int(rnd(1) * parenexpr()) + 1
    case tok$ = "sgn": call nexttok: n = parenexpr()
      select case
        case n < 0: n = -1
        case n > 0: n = 1
      end select
    case toktype = cident: n = vars(getvarindex()): call nexttok
    case tok$ = "@"  : call nexttok: n = atarry(parenexpr())
    case tok$ = "-"  : call nexttok: n = 0 - expression(7)
    case tok$ = "+"  : call nexttok: n =  expression(7)
    case else: print "("; curline; ") syntax error: expecting an operand, found: ", tok$: errors = true: exit function
  end select

  do while 1 ' while binary operator and precedence of tok$ >= minprec
    select case
      case minprec <= 1 and tok$ = "or" : call nexttok: n = n or expression(2)
      case minprec <= 2 and tok$ = "and": call nexttok: n = n and expression(3)
      case minprec <= 4 and tok$ = "="  : call nexttok: n = abs(n = expression(5))
      case minprec <= 4 and tok$ = "<"  : call nexttok: n = abs(n < expression(5))
      case minprec <= 4 and tok$ = ">"  : call nexttok: n = abs(n > expression(5))
      case minprec <= 4 and tok$ = "<>" : call nexttok: n = abs(n <> expression(5))
      case minprec <= 4 and tok$ = "<=" : call nexttok: n = abs(n <= expression(5))
      case minprec <= 4 and tok$ = ">=" : call nexttok: n = abs(n >= expression(5))
      case minprec <= 5 and tok$ = "+"  : call nexttok: n = n + expression(6)
      case minprec <= 5 and tok$ = "-"  : call nexttok: n = n - expression(6)
      case minprec <= 6 and tok$ = "*"  : call nexttok: n = n * expression(7)
      case minprec <= 6 and (tok$ = "/" or tok$ = "\"): call nexttok: n = int(n / expression(7))
      case minprec <= 6 and tok$ = "mod": call nexttok: n = int(n mod expression(7))
      case minprec <= 8 and tok$ = "^"  : call nexttok: n = n ^ expression(9)
      case else: exit do
    end select
  loop

  expression = n
end function

function getvarindex()
  if toktype <> cident then print "Not a variable:"; tok$: errors = true: exit function
  getvarindex = asc(left$(tok$, 1)) - asc("a")
end function

sub expect s$
  if accept(s$) then exit sub
  print "("; curline; ") expecting "; s$; " but found "; tok$; " =>"; pgm$(curline): errors = true
end sub

function accept(s$)
  accept = false
  if tok$ = s$ then accept = true: call nexttok
end function

sub initlex n
  curline = n: textp = 1
  call initlex2
end sub

sub initlex2
  needcolon = false
  thelin$ = pgm$(curline)
  call nexttok
end sub

sub nexttok
  tok$ = "": toktype = cdefault: thech$ = ""
  do while textp <= len(thelin$)
    thech$ = mid$(thelin$, textp, 1)
    select case toktype
      case cdefault
        select case thech$
          case chr$(34):     toktype = cstring
          case chr$(39):     call skiptoeol: exit sub
          case "#","(",")","*","+",",","-","/",":",";","<","=",">","?","@","\","^": toktype = cpunct
          case " " ' skip spaces
          case else
            if isalpha(thech$) then
              toktype = cident
            else
              if isdigit(thech$) then
                toktype = cnumber
              else
                print "("; curline; ") "; "What?"; thech$; " : "; thelin$: errors = true: exit sub
              end if
            end if
        end select
      case cident:  if isalpha(thech$) = false then exit do
      case cnumber: if isdigit(thech$) = false then exit do
      case cstring: if thech$ = chr$(34) then textp = textp + 1: exit sub
      case cpunct
        if (tok$ = "<" and (thech$ = ">" or thech$ = "=")) or (tok$ = ">" and thech$ = "=") then
          tok$ = tok$ + thech$
          textp = textp + 1
        end if
        exit sub
    end select
    if toktype <> cdefault then tok$ = tok$ + thech$
    textp = textp + 1
  loop
  if toktype = cnumber then num = val(tok$)
  if toktype = cstring then print "String not terminated": errors = true
  if toktype = cident then
    tok$ = lower$(tok$)
    if tok$ = "rem" then call skiptoeol
  end if
end sub

sub skiptoeol
  tok$ = "": toktype = cdefault
  textp = len(thelin$) + 1
end sub

function isdigit(c$)
  isdigit = left$(c$, 1) >= "0" and left$(c$, 1) <= "9"
end function

function isalpha(c$)
  isalpha = (left$(c$, 1) >= "a" and left$(c$, 1) <= "z") or (left$(c$, 1) >= "A" and left$(c$, 1) <= "Z")
end function
