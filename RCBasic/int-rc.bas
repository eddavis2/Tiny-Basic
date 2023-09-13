' RCBasic version of Tiny Basic interpreter, by Ed Davis
' Can play star trek

const c_maxlines = 7000
const c_maxvars = 26
const c_at_max = 500
const c_g_stack = 100

dim pgm$[c_maxlines + 1] ' program stored here
dim vars[c_maxvars + 1]
dim gstackln[c_g_stack]    ' gosub line stack
dim gstacktp[c_g_stack]    ' gosub textp stack
dim gsp
dim atarry[c_at_max] ' the @ array
dim forvar[c_maxvars + 1]
dim forlimit[c_maxvars + 1]
dim forline[c_maxvars + 1]
dim forpos[c_maxvars + 1]

dim tok$, toktype$   ' current token, and it's type
dim thelin$, thech$  ' current program line, current character
dim curline, textp ' position in current line
dim num   ' last number read by scanner
dim errors
dim tracing
dim timestart

sub getch()
  ' Any more text on this line?
  if textp > len(thelin) then
    thech$ = "": return
  end if
  thech$ = mid(thelin, textp - 1, 1)
  textp = textp + 1
end sub

sub skiptoeol()
  tok$ = "": toktype$ = ""
  textp = len(thelin$) + 1
end sub

' leave the " as the beginning of the string, so it won't get confused with other tokens
' especially in the print routines
sub readstr()
  tok$ = thech$: toktype$ = "string"
  getch()
  do
    if thech$ = "" then
      print "String not terminated": errors = true: return
    end if
    if asc(thech$) = 34 then ' a double quote
      exit do
    end if
    tok$ = tok$ + thech$
    getch()
  loop
  getch()
end sub

sub readint()
  tok$ = "": toktype$ = "number"
  while thech$ <> ""
    if asc(thech$) >= asc("0") and asc(thech$) <= asc("9") then
      tok$ = tok$ + thech$
      getch()
    else
      exit while
    end if
  wend
  num = val(tok$)
end sub

sub readident()
  tok$ = "": toktype$ = "ident"
  while thech$ <> ""
    if (asc(thech$) >= asc("a") and asc(thech$) <= asc("z")) or (asc(thech$) >= asc("A") and asc(thech$) <= asc("Z")) then
      tok$ = tok$ + lcase(thech$)
      getch()
    else
      exit while
    end if
  wend
end sub

sub nexttok()
  tok$ = "": toktype$ = ""
  do
    if thech$ = "" then
      return
    end if
    if asc(thech$) > asc(" ") then
      exit do
    end if
    getch()
  loop
  if (asc(thech$) >= asc("a") and asc(thech$) <= asc("z")) or (asc(thech$) >= asc("A") and asc(thech$) <= asc("Z")) then
    readident()
    if tok$ = "rem" then
      skiptoeol()
    end if
  elseif asc(thech$) >= asc("0") and asc(thech$) <= asc("9") then
    readint()
  elseif asc(thech$) = 34 then  ' double quote
    readstr()
  elseif asc(thech$) = asc("'") then
    skiptoeol()
  else
    p = instr("#()*+,-/:;<=>?@\\^", thech$)
    if p >= 0 and p < 17 then
        toktype$ = "punct"
        tok$ = thech$
        getch
        if tok$ = "<" or tok$ = ">" then
          if thech$ = "=" or thech$ = ">" then
            tok$ = tok$ + thech$
            getch
          end if
        end if
        return
    else
        toktype$ = ""
        print "("; curline; ") "; "What?"; thech$; " : "; thelin: errors = true
        getch
        return
    end if
  end if
end sub

sub initlex2()
  thelin$ = pgm$[curline]
  thech$ = " "
  nexttok()
end sub

sub initlex(n)
  curline = n
  textp = 1
  initlex2()
end sub

sub validlinenum()
  if num <= 0 or num > c_maxlines then
    print "Line number out of range": errors = true
  end if
end sub

function getvarindex()
  if toktype$ <> "ident" then
    print "Not a variable:"; tok$:
    errors = true:
    return
  end if
  return asc(left(tok$, 1)) - asc("a")
end function

sub clearvars()
  dim i
  for i = 1 to c_maxvars
    vars[i] = 0
  next
  gsp = 0
end sub

function expect(s$)
  if tok$ = s$ then
    nexttok()
    return true
  end if
  print "Expecting: "; s$; " but found: "; tok$: errors = true
  return false
end function

function accept(s$)
  if tok$ = s$ then
    nexttok()
    return true
  end if
  return false
end function

' minprec of -1 means must be: (expr)
function expression(minprec)
  dim n

  if minprec = -1 then
    if tok$ = "(" then
      return expression(999)
    else
      expect("("): return 0
    end if
  end if

  ' handle numeric operands - numbers and unary operators
  if     toktype$ = "number" then: n = num: nexttok()
  elseif tok$ = "(" then
    nexttok(): n = expression(0)
    expect(")")
  elseif tok$ = "not" then: nexttok(): n = not expression(3)
  elseif tok$ = "abs" then: nexttok(): n = abs(expression(-1))
  elseif tok$ = "asc" then:
    nexttok():
    expect("(")
    n = asc(mid(tok$, 1, 1)):
    nexttok()
    expect(")")
  elseif tok$ = "rnd" or tok$ = "irnd" then:
    nexttok()
    n = rand(expression(-1))
    if n = 0 then
      n = n + 1
    end if
  elseif tok$ = "sgn" then: nexttok(): n = sign(expression(-1))
  elseif toktype$ = "ident" then: n = vars[getvarindex()]: nexttok()
  elseif tok$ = "@"   then: nexttok(): n = atarry[expression(-1)]
  elseif tok$ = "-"   then: nexttok(): n = -expression(7)
  elseif tok$ = "+"   then: nexttok(): n =  expression(7)
  else: print "syntax error: expecting an operand, found: "; tok$: errors = true: return
  end if

  do  ' while binary operator and precedence of tok$ >= minprec
    if     minprec <= 1 and tok$ = "or"  then: nexttok(): n = n or expression(2)
    elseif minprec <= 2 and tok$ = "and" then: nexttok(): n = n and expression(3)
    elseif minprec <= 4 and tok$ = "="   then: nexttok(): n = n = expression(5)
    elseif minprec <= 4 and tok$ = "<"   then: nexttok(): n = n < expression(5)
    elseif minprec <= 4 and tok$ = ">"   then: nexttok(): n = n > expression(5)
    elseif minprec <= 4 and tok$ = "<>"  then: nexttok(): n = n <> expression(5)
    elseif minprec <= 4 and tok$ = "<="  then: nexttok(): n = n <= expression(5)
    elseif minprec <= 4 and tok$ = ">="  then: nexttok(): n = n >= expression(5)
    elseif minprec <= 5 and tok$ = "+"   then: nexttok(): n = n + expression(6)
    elseif minprec <= 5 and tok$ = "-"   then: nexttok(): n = n - expression(6)
    elseif minprec <= 6 and tok$ = "*"   then: nexttok(): n = n * expression(7)
    elseif minprec <= 6 and (tok$ = "/" or tok$ = "\\") then: nexttok(): n = int(n / expression(7))
    elseif minprec <= 6 and tok$ = "mod" then: nexttok(): n = n mod expression(7)
    elseif minprec <= 8 and tok$ = "^"   then: nexttok(): n = n ^ expression(9)
    else: exit do
    end if
  loop

  return n
end function

function getfilename$(action$)
  dim filename$
  if toktype$ = "string" then
    filename$ = right$(tok$, length(tok$) - 1)
  else
    filename$ = input$(action$)
  end if
  if filename$ <> "" then
    if instr(filename$, ".") > length(filename$) then
      filename$ = filename$ + ".bas"
    end if
  end if
  return filename$
end function

sub runstmt()
  timestart = timer
  clearvars()
  initlex(1)
end sub

sub returnstmt()    ' return from a subroutine
  curline = gstackln[gsp]
  textp   = gstacktp[gsp]
  gsp = gsp - 1
  initlex2()
end sub

' "print" [[#num "," ] expr { "," [#num ","] expr }] [","] {":" stmt} eol
' expr can also be a literal string
sub printstmt()
  dim printnl, printwidth, n
  dim junk$

  printnl = true
  while tok$ <> ":" and tok$ <> "" and tok$ <> "else"
    printnl = true
    printwidth = 0
    if accept("#") then
      if num <= 0 then
        print "Expecting a print width, found:"; tok$:
        return
      end if
      printwidth = num
      nexttok()
      if not accept(",") then
        print "Print: Expecting a ',', found:"; tok$:
        return
      end if
    end if

    if toktype$ = "string" then
      junk = right$(tok$, length(tok$) - 1)
      nexttok()
    else
      n = expression(0)
      junk = ltrim(str(n))
    end if
    printwidth = printwidth - len(junk)
    if printwidth <= 0 then
      print junk;
    else
      print StringFill$(" ", printwidth); junk;
    end if

    if accept(",") or accept(";") then
      printnl = false
    else
      exit while
    end if
  wend

  if printnl then
    print ""
  end if
end sub

sub nextstmt()
  dim forndx

  ' tok$ needs to have the variable
  forndx = getvarindex()
  forvar[forndx] = forvar[forndx] + 1
  vars[forndx] = forvar[forndx]
  if forvar[forndx] <= forlimit[forndx] then
    curline = forline[forndx]
    textp   = forpos[forndx]
    'print "nextstmt tok$>"; tok$; " textp>"; textp; " >"; mid(thelin$, textp)
    initlex2()
  else
    nexttok() ' skip the ident for now
  end if
end sub

sub newstmt()
  dim i
  clearvars()
  for i = 1 to c_maxlines
    pgm$[i] = ""
  next
end sub

sub loadstmt()
  dim f, n, filename$

  newstmt()
  filename$ = getfilename("Load: ")
  if filename$ = "" then
    return
  end if

  if not fileopen(f, filename$, TEXT_INPUT) then
    print "Could not open: "; filename$
    return
  end if
  n = 0
  while not eof(f)
    pgm$[0] = readline$(f)
    initlex(0)
    if toktype$ = "number" and num > 0 and num <= c_maxlines then
      n = num
    else
      n = n + 1: textp = 1
    end if
    pgm$[n] = right$(pgm$[0], length(pgm$[0]) - textp + 1)
  wend
  fileclose(f)
  curline = 0
end sub

sub liststmt()
  dim i
  for i = 1 to c_maxlines
    if pgm$[i] <> "" then
      print i; " "; pgm$[i]
    end if
  next
  print ""
end sub

sub inputstmt()   ' "input" [string ","] var
  dim thevar, st$, prompt$
  prompt$ = "? "
  if toktype$ = "string" then
    prompt$ = right(tok$, length(tok$) - 1)
    nexttok()
    expect(",")
  end if
  thevar = getvarindex(): nexttok()
  st$ = input$(prompt$)
  if st$ = "" then
    st$ = "0"
  end if
  if asc(left(st$, 1)) >= asc("0") and asc(left(st$, 1)) <= asc("9") then
    vars[thevar] = val(st$)
  else
    vars[thevar] = asc(st$)
  end if
end sub

sub gotostmt()
  num = expression(0)
  validlinenum()
  initlex(num)
end sub

sub gosubstmt()   ' for gosub: save the line and column
  gsp = gsp + 1
  gstackln[gsp] = curline
  gstacktp[gsp] = textp

  gotostmt()
end sub

sub ifstmt()
  if expression(0) = 0 then
    skiptoeol()
    return
  end if
  accept("then")
  if toktype$ = "number" then
    gotostmt()
  end if
end sub

sub arrassn()   ' array assignment: @(expr) = expr
  dim n, atndx

  atndx = expression(-1)
  expect("=")
  n = expression(0)
  atarry[atndx] = n
  if tracing then
    print "*** @("; atndx; ") = "; n
  end if
end sub

sub assign()
  dim thevar
  thevar = getvarindex(): nexttok()
  expect("=")
  vars[thevar] = expression(0)
  if tracing then
    print "*** "; chr(thevar + asc("a")); " = "; vars[thevar]
  end if
end sub

sub forstmt()   ' for i = expr to expr
  dim thevar, n, forndx

  thevar = getvarindex()
  assign()
  ' vars(thevar) has the value; thevar has the number value of the variable in 0..25
  forndx = thevar
  forvar[forndx] = vars[thevar]
  expect("to")
  n = expression(0)
  forlimit[forndx] = n
  ' need to store iter, limit, line, and col
  forline[forndx] = curline
  if tok$ = "" then
    forpos[forndx] = textp
  else
    forpos[forndx] = textp - 2
  end if
end sub

sub help()
   print "┌────────────────────── Tiny Basic Help (FreeBasic)───────────────────┐"
   print "│ bye, clear, end, help, list, load, new, run, save, stop             │█"
   print "│ goto <expr>                                                         │█"
   print "│ gosub <expr> ... return                                             │█"
   print "│ if <expr> then <statement>                                          │█"
   print "│ input [prompt,] <var>                                               │█"
   print "│ <var>=<expr>                                                        │█"
   print "│ print <expr|string>[,<expr|string>][;]                              │█"
   print "│ rem <anystring>                                                     │█"
   print "│ Operators: + - * / < <= > >= <> =                                   │█"
   print "│ Integer variables a..z, and array @(expr)                           │█"
   print "│ Functions: rnd(expr)                                                │█"
   print "└─────────────────────────────────────────────────────────────────────┘█"
   print "  ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀"
end sub

sub showtime(running)
  if running then
    print "Took : " + str(timer - timestart) + " seconds"
  end if
end sub

sub docmd()
  dim running
  do
    if tracing and left(tok$, 1) <> ":" then
      print curline; tok$; thech$; mid(thelin$, textp, length(thelin$) - textp)
    end if
    select case tok$
      case "bye", "quit" : nexttok(): end
      case "end", "stop" : nexttok(): return
      case "clear"       : nexttok(): clearvars(): return
      case "help"        : nexttok(): help():      return
      case "list"        : nexttok(): liststmt():  return
      case "load"        : nexttok(): loadstmt():  return
      case "new"         : nexttok(): newstmt():   return
      case "run"         : nexttok(): runstmt(): running = true
'      case "save"        : nexttok(): savestmt():  return
      case "tron"        : nexttok(): tracing = true
      case "troff"       : nexttok(): tracing = false
      case "cls"         : nexttok():
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
      default
        if tok$ = "let" then
          nexttok()
        end if
        if toktype$ = "ident" then
          assign()
        else
          print "Unknown token "; tok$; " at line "; curline: errors = true
        end if
    end select

    if errors then
      return
    end if
    if curline > c_maxlines then
      showtime(running): return
    end if
    while tok$ = ""
      if curline = 0 or curline >= c_maxlines then
        showtime(running): return
      end if
      initlex(curline + 1)
    wend
  loop
end sub

newstmt()
help()
do
  errors = false
  pgm$[0] = input$("rcb>: ")
  if ltrim(pgm$[0]) <> "" then
    initlex(0)
    if toktype$ = "number" then
      validlinenum()
      pgm$[num] = right$(pgm$[0], length(pgm$[0]) - textp + 1)
    else
      docmd
    end if
  end if
loop
