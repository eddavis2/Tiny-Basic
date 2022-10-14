'Ed Davis. Tiny Basic that can play Star Trek

imports system.console
imports system.io
imports System.Collections

module TinyBasic

const c_maxlines = 7000, c_maxvars = 26, c_at_max = 1000

dim pgm(c_maxlines) as string         ' program stored here
dim vars(c_maxvars) as long           ' variable store
dim atarry(c_at_max) as long          ' the @ array

dim gstackln As Stack = New Stack()   ' gosub line stack
dim gstacktp As Stack = New Stack()   ' gosub textp stack

dim forvar(c_maxvars) as long
dim forlimit(c_maxvars) as long
dim forline(c_maxvars) as integer
dim forpos(c_maxvars) as integer

dim tok as string, toktype as string    ' current token, and it's type
dim thelin as string, thech as string   ' current program line, current character
dim curline as integer, textp as integer ' position in current line
dim num as long      ' last number read by scanner
dim errors as boolean
dim tracing as boolean

dim timestart as double

sub main()
  newstmt()
  help()
  do
    errors = false
    write("vb> ")
    pgm(0) = ReadLine()
    if pgm(0) <> "" then
      initlex(0)
      if toktype = "number" then
        validlinenum()
        pgm(CInt(num)) = mid(pgm(0), textp)
      else
        docmd()
      end if
    end if
  loop
end sub

sub docmd()
  dim running as boolean
  running = false
  do
    if tracing and left(tok, 1) <> ":" then writeline("[" & curline & "] " & tok & " " & thech & " " & mid(thelin, textp))
    select case tok
      case "bye", "quit" : nexttok(): end
      case "end", "stop" : nexttok(): exit sub
      case "clear"       : nexttok(): clearvars(): exit sub
      case "help"        : nexttok(): help():      exit sub
      case "list"        : nexttok(): liststmt():  exit sub
      case "load"        : nexttok(): loadstmt():  exit sub
      case "new"         : nexttok(): newstmt():   exit sub
      case "run"         : nexttok(): runstmt(): running = true
      case "save"        : nexttok(): savestmt():  exit sub
      case "tron"        : nexttok(): tracing = true
      case "troff"       : nexttok(): tracing = false
      case "cls"         : nexttok(): clear()
      case "for"         : nexttok(): forstmt()
      case "gosub"       : nexttok(): gosubstmt()
      case "goto"        : nexttok(): gotostmt()
      case "if"          : nexttok(): ifstmt()
      case "input"       : nexttok(): inputstmt()
      case "next"        : nexttok(): nextstmt()
      case "print", "?"  : nexttok(): printstmt()
      case "return"      : nexttok(): returnstmt()
      case "@"           : nexttok(): arrassn()
      case ":"           : nexttok()  ' just continue
      case ""            : ' handled below
      case else
        if tok = "let" then nexttok()
        if toktype = "ident" then
          assign()
        else
          writeline("Unknown token " & tok & " at line " & curline): errors = true
        end if
    end select

    if errors then exit sub
    if curline > c_maxlines then showtime(running): exit sub
    do while tok = ""
      if curline = 0 or curline >= c_maxlines then showtime(running): exit sub
      initlex(curline + 1)
    loop
  loop
end sub

sub showtime(running as boolean)
  if running then writeline("Took : " & Microsoft.VisualBasic.Timer - timestart & " seconds")
end sub

sub help
   writeline("+---------------------- Tiny Basic (VB.NET) --------------------------+")
   writeline("| bye, clear, cls, end/stop, help, list, load/save, new, run, tron/off|")
   writeline("| for <var> = <expr1> to <expr2> ... next <var>                       |")
   writeline("| gosub <expr> ... return                                             |")
   writeline("| goto <expr>                                                         |")
   writeline("| if <expr> then <statement>                                          |")
   writeline("| input [prompt,] <var>                                               |")
   writeline("| <var>=<expr>                                                        |")
   writeline("| print <expr|string>[,<expr|string>][;]                              |")
   writeline("| rem <anystring>                                                     |")
   writeline("| Operators: ^, * / \ mod + - < <= > >= = <>, not, and, or            |")
   writeline("| Integer variables a..z, and array @(expr)                           |")
   writeline("| Functions: abs(expr), asc(ch), rnd(expr), sgn(expr)                 |")
   writeline("+---------------------- Tiny Basic Help ------------------------------+")
end sub

sub gosubstmt()   ' for gosub: save the line and column
  gstackln.Push(curline)
  gstacktp.Push(textp)

  gotostmt()
end sub

sub assign()
  dim var as integer
  var = getvarindex(): nexttok()
  expect("=")
  vars(var) = expression(0)
  if tracing then writeline("*** " & chr(var + asc("a")) & " = " & vars(var))
end sub

sub arrassn()   ' array assignment: @(expr) = expr
  dim n as long, atndx as integer

  atndx = CInt(parenexpr())
  if tok <> "=" then
    writeline("Array Assign: Expecting '=', found: " & tok): errors = true
  else
    nexttok()     ' skip the "="
    n = expression(0)
    atarry(atndx) = n
    if tracing then writeline("*** @(" & atndx & ") = " & n)
  end if
end sub

sub forstmt() ' for i = expr to expr
  dim var, forndx as integer, n as long
  var = getvarindex()
  assign()
  ' vars(var) has the value; var has the number value of the variable in 0..25
  forndx = var
  forvar(forndx) = vars(var)
  if tok <> "to" then
    writeline("For: Expecting 'to', found:" & tok): errors = true
  else
    nexttok()
    n = expression(0)
    forlimit(forndx) = n
    ' need to store iter, limit, line, and col
    forline(forndx) = curline
    if tok = "" then forpos(forndx) = textp else forpos(forndx) = textp - 2
  end if
end sub

sub ifstmt()
  if expression(0) = 0 then skiptoeol(): exit sub
  if tok = "then" then nexttok()      ' "then" is optional
  if toktype = "number" then gotostmt()
end sub

sub inputstmt()   ' "input" [string ","] var
  dim var as integer
  dim st as string
  if toktype = "string" then
    write(mid(tok, 2))
    nexttok()
    expect(",")
  else
    write("? ")
  end if
  var = getvarindex: nexttok()
  st = readline()
  if st = "" then st = "0"
  if left(st, 1) >= "0" and left(st, 1) <= "9" then
    vars(var) = CLng(st)
  else
    vars(var) = asc(st) ' turn characters into their ascii value
  end if
end sub

sub liststmt()
  dim i as integer
  for i = 1 to c_maxlines
    if pgm(i) <> "" then writeline(i & " " & pgm(i))
  next i
  writeline("")
end sub

sub loadstmt()
  dim n as integer, filename as string
  dim f as StreamReader

  newstmt()
  filename = getfilename("Load")
  if filename = "" then exit sub
  f = new StreamReader(filename)
  n = 0
  do until f.peek = -1
    pgm(0) = f.ReadLine()
    initlex(0)
    if toktype = "number" and num > 0 and num <= c_maxlines then
      pgm(CInt(num)) = mid(pgm(0), textp)
      n = CInt(num)
    else
      n = n + 1
      pgm(n) = pgm(0)
    end if
  loop
  f.Close()
  curline = 0
end sub

sub newstmt()
  dim i as integer
  clearvars()
  for i = 1 to c_maxlines
    pgm(i) = ""
  next i
end sub

sub nextstmt ' next ident
  dim forndx as integer

  ' tok needs to have the variable
  forndx = getvarindex()
  forvar(forndx) = forvar(forndx) + 1
  vars(forndx) = forvar(forndx)
  if tracing then writeline("*** " & chr(forndx + asc("a")) & " = " & vars(forndx))
  if forvar(forndx) <= forlimit(forndx) then
    curline = forline(forndx)
    textp   = forpos(forndx)
    'print "nextstmt tok>"; tok; " textp>"; textp; " >"; mid$(thelin, textp)
    call initlex2
  else
    call nexttok ' skip the ident for now
  end if
end sub

sub printstmt()
  dim printnl as boolean, printwidth as integer, n as long, junk as string

  printnl = true
  do while tok <> ":" and tok <> "" and tok <> "else"
    printnl = true
    printwidth = 0
    if accept("#") then
      if num <= 0 then writeline("Expecting a print width, found:" + tok): exit sub
      printwidth = CInt(num)
      nexttok()
      if not accept(",") then writeline("Print: Expecting a ',', found:" + tok): exit sub
    end if

    if toktype = "string" then
      junk = mid(tok, 2)
      nexttok()
    else
      n = expression(0)
      junk = ltrim(str(n))
    end if
    printwidth = printwidth - len(junk)
    if printwidth <= 0 then write(junk) else write(space(printwidth) + junk)

    if accept(",") or accept(";") then printnl = false else exit do
  loop

  if printnl then writeline()
end sub

sub returnstmt()    ' return from a subroutine
  curline = CInt(gstackln.Pop())
  textp   = CInt(gstacktp.Pop())
  initlex2()
end sub

sub runstmt()
  timestart = Microsoft.VisualBasic.Timer
  clearvars()
  initlex(1)
end sub

sub gotostmt()
  num = expression(0)
  validlinenum()
  initlex(CInt(num))
end sub

sub savestmt()
  dim i as integer, filename as string
  dim f as StreamWriter

  filename = getfilename("Save")
  if filename = "" then exit sub
  f = new StreamWriter(filename, false)
  for i = 1 to c_maxlines
    if pgm(i) <> "" then f.writeline(i & " " & pgm(i))
  next i
  f.close()
end sub

function getfilename(action as string) as string
  dim filename as string
  if toktype = "string" then
    filename = mid(tok, 2)
  else
    write(action & ": ")
    filename = readline()
  end if
  if filename <> "" then
    if instr(filename, ".") = 0 then filename = filename + ".bas"
  end if
  return filename
end function

sub validlinenum()
  if num <= 0 or num > c_maxlines then writeline("Line number out of range"): errors = true
end sub

sub clearvars()
  dim i as integer
  for i = 1 to c_maxvars
    vars(i) = 0
  next i

  gstackln.Clear()
  gstacktp.Clear()
end sub

function parenexpr() as long
  dim n as long

  expect("("): if errors then return 0
  n = expression(0)
  expect(")")
  return n
end function

'1  Or
'2  And
'3  Not
'4  = <> < <= > >=
'5  + -
'6  * / \ Mod
'7  - + (unary)
'8  ^
function expression(minprec as integer) as long
  dim n as long

  ' handle numeric operands - numbers and unary operators
  if toktype = "number" then
    n = num: nexttok()
  elseif tok = "-" then
    nexttok(): n = -expression(7)
  elseif tok = "+" then
    nexttok(): n =  expression(7)
  elseif tok = "not" then
    nexttok(): n = not expression(3)
  elseif tok = "abs" then
    nexttok(): n = Math.abs(parenexpr())
  elseif tok = "asc" then
    nexttok(): expect("("): n = asc(mid(tok, 2, 1)): nexttok(): expect(")")
  elseif tok = "rnd" or tok = "irnd" then
    nexttok(): n = Convert.ToInt32(rnd * parenexpr() + 1)
  elseif tok = "sgn" then
    nexttok(): n = Math.sign(parenexpr())
  elseif toktype = "ident"  then
    n = vars(getvarindex()): nexttok()
  elseif tok = "@"  then
    nexttok(): n = atarry(CInt(parenexpr()))
  elseif tok = "("  then
    n =  parenexpr()
  else
    writeline("syntax error: expecting an operand, found: " & tok): errors = true: return 0
  end if

  do  ' while binary operator and precedence of tok >= minprec
    if     minprec <= 1 and tok = "or" then
      nexttok(): n = Convert.ToInt32(n or expression(2))
    elseif minprec <= 2 and tok = "and" then
      nexttok(): n = Convert.ToInt32(n and expression(3))
    elseif minprec <= 4 and tok = "=" then
      nexttok(): n = Convert.ToInt32(n = expression(5))
    elseif minprec <= 4 and tok = "<" then
      nexttok(): n = Convert.ToInt32(n < expression(5))
    elseif minprec <= 4 and tok = ">" then
      nexttok(): n = Convert.ToInt32(n > expression(5))
    elseif minprec <= 4 and tok = "<>" then
      nexttok(): n = Convert.ToInt32(n <> expression(5))
    elseif minprec <= 4 and tok = "<=" then
      nexttok(): n = Convert.ToInt32(n <= expression(5))
    elseif minprec <= 4 and tok = ">=" then
      nexttok(): n = Convert.ToInt32(n >= expression(5))
    elseif minprec <= 5 and tok = "+" then
      nexttok(): n = n + expression(6)
    elseif minprec <= 5 and tok = "-" then
      nexttok(): n = n - expression(6)
    elseif minprec <= 6 and tok = "*" then
      nexttok(): n = n * expression(7)
    elseif minprec <= 6 and (tok = "/" or tok = "\") then
      nexttok(): n = n \ expression(7)
    elseif minprec <= 6 and tok = "mod" then
      nexttok(): n = n mod expression(7)
    elseif minprec <= 8 and tok = "^" then
      nexttok(): n = CLng(n ^ expression(9))
    else
      exit do
    end if
  loop

  return n
end function

function getvarindex() as integer
  if toktype <> "ident" then writeline("Not a variable:" & tok): errors = true: return 0
  return asc(left(tok, 1)) - asc("a")
end function

sub expect(s as string)
  if accept(s) then exit sub
  writeline("(" & curline & ") expecting " & s & " but found " & tok & " =>" & pgm(curline)): errors = true
end sub

function accept(s as string) as boolean
  if tok = s then nexttok(): return true
  return false
end function

sub initlex(n as integer)
  curline = n
  textp = 1
  initlex2()
end sub

sub initlex2()
  thelin = pgm(curline)
  thech = " "
  nexttok()
end sub

sub skiptoeol()
  tok = "": toktype = ""
  textp = len(thelin) + 1
end sub

sub nexttok()
  tok = "": toktype = ""
  begin:
  if thech <> "" then
    select case asc(thech)
      case is <= 32: getch(): goto begin
      case asc("a") to asc("z"), asc("A") to asc("Z"): readident(): if tok = "rem" then skiptoeol()
      case asc("0") to asc("9"): readint()
      case 34: readstr()             ' double quote
      case asc("'"): skiptoeol()
      case asc("#"),asc("("),asc(")"),asc("*"),asc("+"),asc(","),asc("-"),asc("/"),asc(":"),asc(";"),asc("<"),asc("="),asc(">"),asc("?"),asc("@"),asc("\"),asc("^")
        toktype = "punct"
        tok = thech
        getch()
        if tok = "<" or tok = ">" then
          if thech = "=" or thech = ">" then
            tok = tok + thech
            getch()
          end if
        end if
      case else
        toktype = ""
        writeline("What?" & thech & thelin): getch(): errors = true
    end select
  end if
end sub

' leave the " as the beginning of the string, so it won't get confused with other tokens
' especially in the print routines
sub readstr()
  tok = thech: toktype = "string"
  getch()
  do while thech <> chr(34)  ' while not a double quote
    if thech = "" then writeline("String not terminated"): errors = true: exit sub
    tok = tok + thech
    getch()
  loop
  getch()
end sub

sub readint()
  tok = "": toktype = "number"
  do while thech >= "0" and thech <= "9"
    tok = tok + thech
    getch()
  loop
  num = Convert.ToInt32(val(tok))
end sub

sub readident()
  tok = "": toktype = "ident"
  do while (thech >= "a" and thech <= "z") or (thech >= "A" and thech <= "Z")
    tok = tok + lcase(thech)
    getch()
  loop
end sub

sub getch()
  ' Any more text on this line?
  if textp > len(thelin) then thech = "": exit sub
  thech = mid(thelin, textp, 1)
  textp = textp + 1
end sub

end module
