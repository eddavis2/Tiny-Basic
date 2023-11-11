'Ed Davis. Tiny Basic that can play Star Trek

const c_maxlines = 7000, c_maxvars = 26, c_at_max = 1000

dim pgm()      ' program stored here
dim vars()     ' variable store
dim atarry()   ' the @ array

dim gstackln   ' gosub line stack
dim gstacktp   ' gosub textp stack

dim forvar()
dim forlimit()
dim forline()
dim forpos()

dim tok, toktype    ' current token, and it's type
dim thelin, thech   ' current program line, current character
dim curline, textp  ' position in current line
dim num             ' last number read by scanner
dim errors
dim tracing

main()

sub main()
  redim pgm(c_maxlines)
  redim vars(c_maxvars)
  redim atarry(c_at_max)
  Set gstackln = CreateObject("System.Collections.Stack")
  Set gstacktp = CreateObject("System.Collections.Stack")
  redim forvar(c_maxvars)
  redim forlimit(c_maxvars)
  redim forline(c_maxvars)
  redim forpos(c_maxvars)

  newstmt()
  help()
  do
    errors = false
    WScript.StdOut.Write("vbs> ")
    pgm(0) = WScript.StdIn.ReadLine
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
  do
    if tracing and left(tok, 1) <> ":" then WScript.StdOut.WriteLine("[" & curline & "] " & tok & " " & thech & " " & mid(thelin, textp))
    select case tok
      case "bye", "quit" : nexttok(): WScript.Quit
      case "end", "stop" : nexttok(): exit sub
      case "clear"       : nexttok(): clearvars(): exit sub
      case "help"        : nexttok(): help():      exit sub
      case "list"        : nexttok(): liststmt():  exit sub
      case "load"        : nexttok(): loadstmt():  exit sub
      case "new"         : nexttok(): newstmt():   exit sub
      case "run"         : nexttok(): runstmt()
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
          WScript.StdOut.WriteLine("Unknown token " & tok & " at line " & curline): errors = true
        end if
    end select

    if errors then exit sub
    if curline > c_maxlines then exit sub
    do while tok = ""
      if curline = 0 or curline >= c_maxlines then exit sub
      initlex(curline + 1)
    loop
  loop
end sub

sub help
   WScript.StdOut.WriteLine("+---------------------- Tiny Basic (VB.NET) --------------------------+")
   WScript.StdOut.WriteLine("| bye, clear, cls, end/stop, help, list, load/save, new, run, tron/off|")
   WScript.StdOut.WriteLine("| for <var> = <expr1> to <expr2> ... next <var>                       |")
   WScript.StdOut.WriteLine("| gosub <expr> ... return                                             |")
   WScript.StdOut.WriteLine("| goto <expr>                                                         |")
   WScript.StdOut.WriteLine("| if <expr> then <statement>                                          |")
   WScript.StdOut.WriteLine("| input [prompt,] <var>                                               |")
   WScript.StdOut.WriteLine("| <var>=<expr>                                                        |")
   WScript.StdOut.WriteLine("| print <expr|string>[,<expr|string>][;]                              |")
   WScript.StdOut.WriteLine("| rem <anystring>                                                     |")
   WScript.StdOut.WriteLine("| Operators: ^, * / \ mod + - < <= > >= = <>, not, and, or            |")
   WScript.StdOut.WriteLine("| Integer variables a..z, and array @(expr)                           |")
   WScript.StdOut.WriteLine("| Functions: abs(expr), asc(ch), rnd(expr), sgn(expr)                 |")
   WScript.StdOut.WriteLine("+---------------------- Tiny Basic Help ------------------------------+")
end sub

sub gosubstmt()   ' for gosub: save the line and column
  num = expression(0)
  gstackln.Push(curline)
  if tok = "" then gstacktp.Push(textp) else gstacktp.Push(textp - 1)
  call validlinenum
  call initlex(num)
end sub

sub assign()
  dim var
  var = getvarindex()
  nexttok()
  expect("=")
  vars(var) = expression(0)
  if tracing then WScript.StdOut.WriteLine("*** " & chr(var + asc("a")) & " = " & vars(var))
end sub

sub arrassn()   ' array assignment: @(expr) = expr
  dim n, atndx

  atndx = CInt(parenexpr())
  if tok <> "=" then
    WScript.StdOut.WriteLine("Array Assign: Expecting '=', found: " & tok): errors = true
  else
    nexttok()     ' skip the "="
    n = expression(0)
    atarry(atndx) = n
    if tracing then WScript.StdOut.WriteLine("*** @(" & atndx & ") = " & n)
  end if
end sub

sub forstmt() ' for i = expr to expr
  dim var, forndx, n
  var = getvarindex()
  assign()
  ' vars(var) has the value; var has the number value of the variable in 0..25
  forndx = var
  forvar(forndx) = vars(var)
  if tok <> "to" then
    WScript.StdOut.WriteLine("For: Expecting 'to', found:" & tok): errors = true
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
  dim var
  dim st
  if toktype = "string" then
    WScript.StdOut.Write(mid(tok, 2))
    nexttok()
    expect(",")
  else
    WScript.StdOut.Write("? ")
  end if
  var = getvarindex: nexttok()
  st = WScript.StdIn.ReadLine
  if st = "" then st = "0"
  if left(st, 1) >= "0" and left(st, 1) <= "9" then
    vars(var) = CLng(st)
  else
    vars(var) = asc(st) ' turn characters into their ascii value
  end if
end sub

sub liststmt()
  dim i
  for i = 1 to c_maxlines
    if pgm(i) <> "" then WScript.StdOut.WriteLine(i & " " & pgm(i))
  next
  WScript.StdOut.WriteLine("")
end sub

sub loadstmt()
  dim n, filename
  dim f

  newstmt()
  filename = getfilename("Load")
  if filename = "" then exit sub

  Set f = CreateObject("Scripting.FileSystemObject")
  if not f.FileExists(filename) then
      WScript.StdOut.WriteLine "File '" & filename & "' not found"
      exit sub
  end if

  Set f = f.OpenTextFile(filename, 1, 0)

  n = 0
  do until f.AtEndOfStream
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
  dim i
  clearvars()
  for i = 1 to c_maxlines
    pgm(i) = ""
  next
end sub

sub nextstmt ' next ident
  dim forndx

  ' tok needs to have the variable
  forndx = getvarindex()
  forvar(forndx) = forvar(forndx) + 1
  vars(forndx) = forvar(forndx)
  if tracing then WScript.StdOut.WriteLine("*** " & chr(forndx + asc("a")) & " = " & vars(forndx))
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
  dim printnl, printwidth, n, junk

  printnl = true
  do while tok <> ":" and tok <> "" and tok <> "else"
    printnl = true
    printwidth = 0
    if accept("#") then
      if num <= 0 then WScript.StdOut.WriteLine("Expecting a print width, found:" + tok): exit sub
      printwidth = CInt(num)
      nexttok()
      if not accept(",") then WScript.StdOut.WriteLine("Print: Expecting a ',', found:" + tok): exit sub
    end if

    if toktype = "string" then
      junk = mid(tok, 2)
      nexttok()
    else
      n = expression(0)
      junk = ltrim(CStr(n))
    end if
    printwidth = printwidth - len(junk)
    if printwidth <= 0 then WScript.StdOut.Write(junk) else WScript.StdOut.Write(space(printwidth) + junk)

    if accept(",") or accept(";") then printnl = false else exit do
  loop

  if printnl then WScript.StdOut.WriteLine()
end sub

sub returnstmt()    ' return from a subroutine
  curline = CInt(gstackln.Pop())
  textp   = CInt(gstacktp.Pop())
  initlex2()
end sub

sub runstmt()
  clearvars()
  initlex(1)
end sub

sub gotostmt()
  num = expression(0)
  validlinenum()
  initlex(CInt(num))
end sub

sub savestmt()
  dim i, filename
  dim f

  filename = getfilename("Save")
  if filename = "" then exit sub

  Set f = f.OpenTextFile(filename, 2, 0)
  for i = 1 to c_maxlines
    if pgm(i) <> "" then f.WriteLine(i & " " & pgm(i))
  next
  f.close()
end sub

function getfilename(action)
  dim filename
  if toktype = "string" then
    filename = mid(tok, 2)
  else
    WScript.StdOut.Write(action & ": ")
    filename = readline()
  end if
  if filename <> "" then
    if instr(filename, ".") = 0 then filename = filename + ".bas"
  end if
  getfilename = filename
end function

sub validlinenum()
  if num <= 0 or num > c_maxlines then WScript.StdOut.WriteLine("Line number out of range"): errors = true
end sub

sub clearvars()
  dim i
  for i = 1 to c_maxvars
    vars(i) = 0
  next

  gstackln.Clear()
  gstacktp.Clear()
end sub

function parenexpr()
  dim n

  expect("("): if errors then parenexpr = 0: exit function
  n = expression(0)
  expect(")")
  parenexpr =  n
end function

'1  Or
'2  And
'3  Not
'4  = <> < <= > >=
'5  + -
'6  * / \ Mod
'7  - + (unary)
'8  ^
function expression(minprec)
  dim n

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
    nexttok(): n = abs(parenexpr())
  elseif tok = "asc" then
    nexttok(): expect("("): n = asc(mid(tok, 2, 1)): nexttok(): expect(")")
  elseif tok = "rnd" or tok = "irnd" then
    nexttok(): n = Int(rnd * parenexpr() + 1)
  elseif tok = "sgn" then
    nexttok(): n = sgn(parenexpr())
  elseif toktype = "ident"  then
    n = vars(getvarindex()): nexttok()
  elseif tok = "@"  then
    nexttok(): n = atarry(CInt(parenexpr()))
  elseif tok = "("  then
    n =  parenexpr()
  else
    WScript.StdOut.WriteLine("syntax error: expecting an operand, found: " & tok): errors = true: expression = 0: exit function
  end if

  do  ' while binary operator and precedence of tok >= minprec
    if     minprec <= 1 and tok = "or" then
      nexttok(): n = abs(n or expression(2))
    elseif minprec <= 2 and tok = "and" then
      nexttok(): n = abs(n and expression(3))
    elseif minprec <= 4 and tok = "=" then
      nexttok(): n = abs(n = expression(5))
    elseif minprec <= 4 and tok = "<" then
      nexttok(): n = abs(n < expression(5))
    elseif minprec <= 4 and tok = ">" then
      nexttok(): n = abs(n > expression(5))
    elseif minprec <= 4 and tok = "<>" then
      nexttok(): n = abs(n <> expression(5))
    elseif minprec <= 4 and tok = "<=" then
      nexttok(): n = abs(n <= expression(5))
    elseif minprec <= 4 and tok = ">=" then
      nexttok(): n = abs(n >= expression(5))
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
      nexttok(): n = Int(n ^ expression(9))
    else
      exit do
    end if
  loop

  expression = n
end function

function getvarindex()
  if toktype <> "ident" then WScript.StdOut.WriteLine("Not a variable:" & tok): errors = true: getvarindex = 0: exit function
  getvarindex = asc(left(tok, 1)) - asc("a")
end function

sub expect(s)
  if accept(s) then exit sub
  WScript.StdOut.WriteLine("(" & curline & ") expecting " & s & " but found " & tok & " =>" & pgm(curline)): errors = true
end sub

function accept(s)
  accept = false
  if tok = s then nexttok(): accept = true
end function

sub initlex(n)
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
  do while thech = " ": getch(): loop
  if thech = "" then exit sub

  if ((thech >= "a") and (thech <= "z")) or ((thech >= "A") and (thech <= "Z")) then
    readident(): if tok = "rem" then skiptoeol()
  elseif isNumeric(thech) then
    readint()
  elseif asc(thech) = 34 then     ' double quote
    readstr()
  elseif asc(thech) = asc("'") then
    skiptoeol()
  elseif InStr("#()*+,-/:;<=>?@\^", thech) > 0 then
      toktype = "punct"
      tok = thech
      getch()
      if tok = "<" or tok = ">" then
        if thech = "=" or thech = ">" then
          tok = tok + thech
          getch()
        end if
      end if
  else
    toktype = ""
    WScript.StdOut.WriteLine("What?" & thech & thelin): getch(): errors = true
  end if
end sub

' leave the " as the beginning of the string, so it won't get confused with other tokens
' especially in the print routines
sub readstr()
  tok = thech: toktype = "string"
  getch()
  do while thech <> chr(34)  ' while not a double quote
    if thech = "" then WScript.StdOut.WriteLine("String not terminated"): errors = true: exit sub
    tok = tok + thech
    getch()
  loop
  getch()
end sub

sub readint()
  tok = "": toktype = "number"
  do while isNumeric(thech)
    tok = tok + thech
    getch()
  loop
  num = CLng(tok)
end sub

sub readident()
  tok = "": toktype = "ident"
  do while ((thech >= "a") and (thech <= "z")) or ((thech >= "A") and (thech <= "Z"))
    tok = tok + lcase(thech)
    getch()
  loop
end sub

sub getch()
  thech = mid(thelin, textp, 1)
  textp = textp + 1
end sub

