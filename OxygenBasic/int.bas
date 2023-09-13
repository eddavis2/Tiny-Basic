'Ed Davis. Tiny Basic that can play Star Trek
'Supports: end, list, load, new, run, save
'gosub/return, goto, if, input, print, multi-statement lines (:)
'a single numeric array: @(n), and rnd(n)

$Filename "int.exe"
extern lib "kernel32.dll"
!GetTickCount() as sys
includepath "$\inc\"
include "console.inc"

#lookahead

% c_maxlines = 7000
% c_maxvars  = 26
% c_at_max   = 1000
% c_g_stack  = 100

dim pgm(c_maxlines) as string         ' program stored here
dim vars(c_maxvars) as integer        ' variable store
dim gstackln(c_g_stack) as integer    ' gosub line stack
dim gstacktp(c_g_stack) as integer    ' gosub textp stack
dim gsp as integer                    ' gosub stack index
dim atarry(c_at_max) as integer       ' the @ array

dim tok as string, toktype as string    ' current token, and it's type
dim thelin as string, thech as string   ' current program line, current character
dim intch as integer                    ' current character as an integer
dim curline as integer, textp as integer ' position in current line
dim num as integer   ' last number read by scanner
dim errors as boolean

dim timestart as sys

main()

sub main()
  gsp = 0
  help()
  do
    errors = false
    print("> ")
    pgm(0) = myinput()
    if pgm(0) <> "" then
      initlex(0)
      if toktype = "number" then
        validlinenum()
        pgm(num) = mid(pgm(0), textp, len(pgm(0)) - textp + 1)
      else
        if not docmd() then exit sub
      end if
    end if
  loop
end sub

function docmd() as boolean
  dim running as boolean
  running = false
  do
    if accept("bye") or accept("quit") then
      return false
    elseif accept("end") or accept("stop") then
      return true
    elseif accept("clear") then
      clearvars(): return true
    elseif accept("help") then
      help(): return true
    elseif accept("list") then
      liststmt(): return true
    elseif accept("load") then
      loadstmt(): return true
    elseif accept("new") then
      newstmt(): return true
    elseif accept("run") then
      runstmt(): running = true
    elseif accept("save") then
      savestmt(): return true
    elseif accept("gosub") then
      gosubstmt()
    elseif accept("goto") then
      gotostmt()
    elseif accept("if") then
      ifstmt()
    elseif accept("input") then
      inputstmt()
    elseif accept("print") or accept("?") then
      printstmt()
    elseif accept("return") then
      returnstmt()
    elseif accept("@")  then
      arrassn()
    elseif accept(":")  then
      ' just continue
    elseif toktype = "ident" then
      assign()
    elseif tok = ""     then
      ' handled below
    else
      print "unknown command: " tok cr: return true
    end if
    if errors then return true
    if curline > c_maxlines then showtime(running): return true
    while tok = ""
      if curline = 0 or curline >= c_maxlines then showtime(running): return true
      initlex(curline + 1)
    end while
  loop
end function

sub showtime(running as boolean)
  double t
  t = (GetTickCount() - timestart) / 1000.0
  if running then print("Took : " & t & " seconds" & cr)
end sub

sub help()
  print("bye, quit - exits the interpreter               " & cr)
  print("clear     - clears variables                    " & cr)
  print("help      - this screen                         " & cr)
  print("list      - lists current program               " & cr)
  print("load      - loads a program into the interpreter" & cr)
  print("new       - discards the current program        " & cr)
  print("run       - runs the current program            " & cr)
  print("save      - saves the current program           " & cr)
  print(cr)
  print("statements: end, gosub/return, goto, if, input, print" & cr)
  print("multi-statement lines (:), a single numeric array: @(n), and rnd(n)" & cr)
end sub

sub gosubstmt()   ' for gosub: save the line and column
  gsp = gsp + 1
  gstackln(gsp) = curline
  gstacktp(gsp) = textp

  gotostmt()
end sub

sub assign()
  dim var as integer
  var = getvarindex(): nexttok()
  expect("=")
  vars(var) = expression(0)
end sub

sub arrassn()   ' array assignment: @(expr) = expr
  dim n as integer, atndx as integer

  atndx = parenexpr()
  if tok <> "=" then
    print "Array Assign: Expecting '=', found: " & tok & cr: errors = true
  else
    nexttok()     ' skip the "="
    n = expression(0)
    atarry(atndx) = n
  end if
end sub

sub ifstmt()
  dim b as boolean
  if expression(0) = 0 then skiptoeol(): exit sub
  b = accept("then")      ' "then" is optional
  if toktype = "number" then gotostmt()
end sub

sub inputstmt()   ' "input" [string ","] var
  dim var as integer
  dim st as string
  if toktype = "string" then
    print(mid(tok, 2))
    nexttok()
    expect(",")
  else
    print("? ")
  end if
  var = getvarindex: nexttok()
  st = myinput()
  if left(st, 1) >= "0" and left(st, 1) <= "9" then
    vars(var) = val(st)
  else
    vars(var) = asc(st) ' turn characters into their ascii value
  end if
end sub

sub liststmt()
  dim i as integer
  for i = 1 to c_maxlines
    if pgm(i) <> "" then print i & " " & pgm(i) & cr
  next i
  print cr
end sub

sub loadstmt()
  dim n, p, flen as integer
  dim filename, text, s as string

  newstmt()
  if toktype = "string" then
    filename = mid(tok, 2)
  else
    print("Load? "): filename = myinput()
  end if
  if filename = "" then exit sub
  if instr(filename, ".") = 0 then filename = filename + ".bas"

  text = getfile(filename)
  flen = len(text)
  if flen > 0 then
    n = 0
    p = 1
    do
      s = getline(text, p)
      pgm(0) = s
      initlex(0)
      if toktype = "number" and num > 0 and num <= c_maxlines then
        pgm(num) = mid(pgm(0), textp, len(pgm(0)) - textp + 1)
        n = num
      else
        n = n + 1
        pgm(n) = pgm(0)
      end if
      if p > flen then exit do
    loop
  end if
  curline = 0
end sub

sub newstmt()
  dim i as integer
  clearvars()
  for i = 1 to c_maxlines
    pgm(i) = ""
  next i
end sub

' "print" expr { "," expr }] [","] {":" stmt} eol
' expr can also be a literal string
sub printstmt()
  dim printnl as boolean

  printnl = true
  while tok <> ":" and tok <> ""
    printnl = true

    if toktype = "string" then
      print mid(tok, 2)
      nexttok()
    else
      print ltrim(str(expression(0)))
    end if

    if accept(",") then
      print " "
      printnl = false
    elseif accept(";") then
      printnl = false
    else
      exit do
    end if
  end while

  if printnl then print " " cr
end sub

sub returnstmt()    ' return from a subroutine
  curline = gstackln(gsp)
  textp   = gstacktp(gsp)
  gsp = gsp - 1
  initlex2()
end sub

sub runstmt()
  timestart = GetTickCount()
  clearvars()
  initlex(1)
end sub

sub gotostmt()
  num = expression(0)
  validlinenum()
  initlex(num)
end sub

sub savestmt()
  dim i as integer, filename as string, text as string

  if toktype = "string" then
    filename = mid(tok, 2)
  else
    print("Save? "): filename = myinput()
  end if
  if filename = "" then exit sub
  if instr(filename, ".") = 0 then filename = filename + ".bas"

  text = ""
  for i = 1 to c_maxlines
    if pgm(i) <> "" then text = text + pgm(i) + cr
  next i
  putfile(filename, text)
end sub

sub validlinenum()
  if num <= 0 or num > c_maxlines then print "Line number out of range" & cr: errors = true
end sub

sub clearvars()
  dim i as integer

  for i = 1 to c_maxvars
    vars(i) = 0
  next i
  gsp = 0
end sub

function parenexpr() as integer
  dim n as integer

  expect("("): if errors then return 0
  n = expression(0)
  expect(")")
  return n
end function

function expression(minprec as integer) as integer
  dim n as integer

  ' handle numeric operands - numbers and unary operators
  if accept("-") then
    n = -expression(4)
  elseif accept("+") then
    n =  expression(4)
  elseif tok = "(" then
    n =  parenexpr()
  elseif accept("rnd") then
    n = myrnd(parenexpr())
  elseif toktype = "number" then
    n = num: nexttok()
  elseif toktype = "ident" then
    n = vars(getvarindex()): nexttok()
  elseif accept("@") then
    n = atarry(parenexpr())
  else
    print "syntax error: expecting an operand, found: " tok & cr: errors = true: return 0
  end if

  do  ' while binary operator and precedence of tok >= minprec
    if minprec <= 1 and tok = "=" then
      nexttok(): n = abs(n =  expression(2))
    elseif minprec <= 1 and tok = "<" then
      nexttok(): n = abs(n <  expression(2))
    elseif minprec <= 1 and tok = ">" then
      nexttok(): n = abs(n >  expression(2))
    elseif minprec <= 1 and tok = "<>" then
      nexttok(): n = abs(n <> expression(2))
    elseif minprec <= 1 and tok = "<=" then
      nexttok(): n = abs(n <= expression(2))
    elseif minprec <= 1 and tok = ">=" then
      nexttok(): n = abs(n >= expression(2))
    elseif minprec <= 2 and tok = "+" then
      nexttok(): n = n +  expression(3)
    elseif minprec <= 2 and tok = "-" then
      nexttok(): n = n -  expression(3)
    elseif minprec <= 3 and tok = "*" then
      nexttok(): n = n *  expression(4)
    elseif minprec <= 3 and tok = "/" then
      nexttok(): n = n \  expression(4)
    else
      exit do
    end if
  loop

  return n
end function

function getvarindex() as integer
  if toktype <> "ident" then print "Not a variable:" & tok cr: errors = true: return 0
  return asc(left(tok, 1)) - asc("a")
end function

sub expect(s as string)
  if accept(s) then exit sub
  print "expected: " s cr: errors = true
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
  thech = " ": intch = asc(thech)
  nexttok()
end sub

sub skiptoeol()
  tok = "": toktype = "": thech = "": intch = -1
  textp = len(thelin) + 1
end sub

sub nexttok()
  tok = "": toktype = ""
  do
    if thech = "" then exit sub
    if intch > asc(" ") then exit do
    getch()
  loop

  toktype = "punct"
  tok = thech + mid(thelin, textp, 1)
  if tok = ">=" or tok = "<=" or tok = "<>" then
    getch(): getch(): exit sub
  end if

  tok = left(tok, 1)
  if instr("()*+,-/:;<=>?@", tok) > 0 then getch(): exit sub

  if tok = chr(34) then readstr(): exit sub    ' double quote

  if (intch >= asc("a") and intch <= asc("z")) or (intch >= asc("A") and intch <= asc("Z")) then
    readident()
    if tok = "rem" then skiptoeol()
    exit sub
  end if

  if intch >= asc("0") and intch <= asc("9") then readint(): exit sub

  if tok = chr(39) then skiptoeol(): exit sub  'single quote

  toktype = ""
  print "What?" chr(intch) thelin cr: getch(): errors = true
end sub

' leave the " as the beginning of the string, so it won't get confused with other tokens
' especially in the print routines
sub readstr()
  toktype = "string"
  getch()
  do
    if thech = "" then print "String not terminated" cr: errors = true: exit sub
    if thech = chr(34) then exit do
    tok = tok + thech
    getch()
  loop
  getch()
end sub

sub readint()
  tok = "": toktype = "number"
  do
    if intch = -1 then exit do
    if intch >= asc("0") and intch <= asc("9") then
      tok = tok + thech
      getch()
    else
      exit do
    end if
  loop
  num = val(tok)
end sub

sub readident()
  tok = "": toktype = "ident"
  do
    if intch = -1 then exit do
    if (intch >= asc("a") and intch <= asc("z")) or (intch >= asc("A") and intch <= asc("Z")) then
      tok = tok + lcase(thech)
      getch()
    else
      exit do
    end if
  loop
end sub

sub getch()
  ' Any more text on this line?
  if textp > len(thelin) then thech = "": intch = -1: exit sub
  thech = mid(thelin, textp, 1)
  intch = asc(thech)
  textp = textp + 1
end sub

function myinput() as string
  return rtrim(input())
end function

function myrnd(limit as integer) as integer
  static ulong rnd_next = 1
  rnd_next = rnd_next * 1103515245 + 12345
  return mod((rnd_next / 65536), limit)
end function

function getline(string s, int *i) as string
  int sl = i, el = i
  byte b at strptr(s)
  do
    select b[el]
      case 0
        i = el + 1 : exit do
      case 10 'lf
        i= el + 1 : exit do
      case 13 'cr
        i = el + 1
        if b[i] = 10 then i++ 'crlf
        exit do
    end select
    el++
  loop
  return mid(s, sl, el - sl)
end function
