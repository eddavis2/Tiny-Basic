' Ed Davis. Tiny Basic with string variables. POC.
$console:only
option _explicit
'Tiny Basic
'supports integers a-z, and strings a$-z$

defint a-z

const true = -1, false = 0, c_maxlines = 700, c_maxvars = 26
dim shared as string c_tab, c_squote, c_dquote
c_tab = chr$(9): c_squote = chr$(39): c_dquote = chr$(34)

dim shared as string thelin, thech      ' current program line, current character
dim shared as string pgm(c_maxlines)    ' program stored here
dim shared as string tok, toktype       ' current token, and it's type
dim shared as long nvars(c_maxvars)
dim shared as string svars(c_maxvars)
dim shared as long numstack(100), nstx
dim shared as string stringstack(100)
dim shared as long sstx
dim shared as long curline, textp       ' position in current line
dim shared as long num                  ' last number read by scanner
dim shared as long errors

declare function accept(s as string)
declare function expression$(minprec as integer)
declare function getvarindex
declare function nexpression(minprec as integer)
declare function popstring$
declare function primary$
declare function seval$(op as string)
declare function sexpression$(minprec as integer)

nstx = 0: sstx = 0
call help
do
  errors = false
  line input "> ", pgm(0)
  if pgm(0) <> "" then
    call initlex(0)
    if toktype = "number" then
      call validlinenum
      pgm(num) = mid$(pgm(0), textp, len(pgm(0)) - textp + 1)
    else
      call docmd
    end if
  end if
loop

sub docmd
  do
    select case tok
      case "bye", "quit": end
      case "end", "stop": exit sub
      case "clear":      call clearvars:exit sub
      case "help":       call help:     exit sub
      case "list":       call liststmt: exit sub
      case "new":        call newstmt:  exit sub
      case "run":        call runstmt
      case "goto":       call nexttok: call gotostmt
      case "if":         call nexttok: call ifstmt
      case "input":      call nexttok: call inputstmt
      '@review: add: case "mid$":
      case "print", "?": call nexttok: call printstmt
      case ":":          call nexttok
      case "":
      case else
        if toktype = "nident" then
          call nassign
        elseif toktype = "sident" then
          call sassign
        else
          print "Unknown token '"; tok; "' at line:"; curline; " Col:"; textp; " : "; thelin: errors = true
        end if
    end select

    if errors or curline > c_maxlines then exit sub
    while tok = ""
      if curline = 0 or curline >= c_maxlines then exit sub
      call initlex(curline + 1)
    wend
  loop
end sub

sub help
   print "ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Tiny Basic Help (QBASIC)ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿"
   print "³ bye, clear, end, help, list, new, run, stop                         ³Û"
   print "³ goto <expr>                                                         ³Û"
   print "³ if <expr> then <statement>                                          ³Û"
   print "³ input [prompt,] <var>                                               ³Û"
   print "³ <var>=<expr>                                                        ³Û"
   print "³ print <expr|string>[,<expr|string>][;]                              ³Û"
   print "³ rem <anystring>                                                     ³Û"
   print "³ Operators: + - * / < <= > >= <> =                                   ³Û"
   print "³ Integer variables a..z, and string variables a$..z$                 ³Û"
   print "ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙÛ"
   print "  ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß"
end sub

sub nassign
  dim var as integer
  var = getvarindex: call nexttok
  call expect("=")
  nvars(var) = nexpression(0)
end sub

sub sassign
  dim var as integer
  var = getvarindex: call nexttok
  call expect("=")
  svars(var) = sexpression$(0)
end sub

sub ifstmt
  if nexpression(0) = 0 then call skiptoeol: exit sub
  if tok = "then" then call nexttok
  if toktype = "number" then call gotostmt
end sub

rem "input" [string ","] var
rem @review - need to support string input
sub inputstmt
  dim var as integer
  if toktype = "string" then
    print mid$(tok, 2);
    call nexttok
    call expect(",")
  else
    print "? ";
  end if
  var = getvarindex: call nexttok
  input nvars(var)
end sub

sub liststmt
  dim i as integer
  for i = 1 to c_maxlines
    if pgm(i) <> "" then print i; " "; pgm(i)
  next i
  print
end sub

sub newstmt
  dim i as integer
  call clearvars
  for i = 1 to c_maxlines
    pgm(i) = ""
  next i
end sub

rem "print" [ expr  "," expr ] [","]
rem expr can also be a literal string
sub printstmt
  dim printnl, etype as string

  printnl = true
  do while tok <> "" and tok <> ":"
    printnl = true
    etype = expression$(0)
    if etype = "string" then
      print mid$(popstring, 2);
    else
      print str$(popnum);
    end if

    if accept(",") or accept(";") then printnl = false else exit do
  loop

  if printnl then print
end sub

sub runstmt
  call clearvars
  call initlex(1)
end sub

sub gotostmt
  num = nexpression(0)
  call validlinenum
  call initlex(num)
end sub

sub validlinenum
  if num <= 0 or num > c_maxlines then print "Line number out of range": errors = true
end sub

sub clearvars
  dim i as integer
  for i = 1 to c_maxvars
    nvars(i) = 0
  next i
end sub

function nexpression(minprec as integer)
  dim etype as string

  etype = expression$(minprec)
  if etype <> "number" then
    print "Expecting a numeric expression"
    errors = true
  else
    nexpression = popnum
  end if
end function

function sexpression$(minprec as integer)
  dim etype as string

  etype = expression$(minprec)
  if etype <> "string" then
    print "Expecting a string expression"
    errors = true
  else
    sexpression$ = popstring
  end if
end function

function primary$
  dim lefttype as string, s as string, n as long

  lefttype = ""
  if tok = "-" then
    call nexttok
    lefttype = expression$(4)
    if lefttype = "number" then
      call pushnum(-popnum)
    else
      print "Cannot negate a string"
      errors = true
    end if
  elseif tok = "(" then
    call nexttok
    lefttype = expression$(0)
    call expect(")")
  elseif toktype = "number" then
    lefttype = "number"
    call pushnum(num)
    call nexttok
  elseif toktype = "nident" then
    lefttype = "number"
    select case tok
      case "sgn"
        call nexttok
        call expect("(")
        n = nexpression(0)
        call expect(")")
        n = sgn(n)
        call pushnum(n)
      case "val"
        call nexttok
        call expect("(")
        s = sexpression(0)
        call expect(")")
        n = val(s)
        call pushnum(n)
      case else
        call pushnum(nvars(getvarindex))
        call nexttok
    end select
  elseif toktype = "string" then
    lefttype = "string"
    call pushstring(tok)
    call nexttok
  elseif toktype = "sident" then
    lefttype = "string"
    select case tok
      case "left$"
        call nexttok
        call expect("(")
        s = sexpression(0)
        expect(",")
        n = nexpression(0)
        call expect(")")
        s = left$(s, n)
        call pushstring(s)
      case "right$"
        call nexttok
        call expect("(")
        s = sexpression(0)
        expect(",")
        n = nexpression(0)
        call expect(")")
        s = right$(s, n)
        call pushstring(s)
      case else
        call pushstring(svars(getvarindex))
        call nexttok
    end select
  '@review: add: left$(st, iexpr), right$(st, iexpr), mid$(st, start [, len]), str$(iexpr),
  '@review: val(st), chr$(iexpr), asc(str), rnd(iexpr), sgn(expr)
  else
    print "syntax error: expecting an operand, found: ", tok
    errors = true
  end if

  primary$ = lefttype
end function

sub neval(op as string)
  dim n as long, n2 as long

  n2 = popnum
  n  = popnum
  if 0 then ' to allow elseif
  elseif op$ = "="  then n = abs(n =  n2)
  elseif op$ = "<"  then n = abs(n <  n2)
  elseif op$ = ">"  then n = abs(n >  n2)
  elseif op$ = "<>" then n = abs(n <> n2)
  elseif op$ = "<=" then n = abs(n <= n2)
  elseif op$ = ">=" then n = abs(n >= n2)
  elseif op$ = "+"  then n = n +  n2
  elseif op$ = "-"  then n = n -  n2
  elseif op$ = "*"  then n = n *  n2
  elseif op$ = "/"  then n = n \  n2
  end if

  call pushnum(n)
end sub

function seval$(op as string)
  dim s as string, s2 as string, lefttype as string, n as long

  lefttype = "string"

  s2 = popstring$
  s  = popstring$

  if 0 then ' to allow elseif
  elseif op = "="  then n = abs(s =  s2): lefttype = "number"
  elseif op = "<"  then n = abs(s <  s2): lefttype = "number"
  elseif op = ">"  then n = abs(s >  s2): lefttype = "number"
  elseif op = "<>" then n = abs(s <> s2): lefttype = "number"
  elseif op = "<=" then n = abs(s <= s2): lefttype = "number"
  elseif op = ">=" then n = abs(s >= s2): lefttype = "number"
  elseif op = "+"  then s = s +  mid$(s2, 2):   ' account for leading dquote
  else print "Operation "; op; " is not defined for strings": errors = true
  end if

  if lefttype = "number" then
    call pushnum(n)
  else
    call pushstring(s)
  end if

  seval$ = lefttype
end function

function expression$(minprec as integer)
  dim lefttype as string

  ' get first operand
  lefttype = primary$
  if errors then exit function

  do  ' while binary operator and precedence of tok >= minprec
    dim righttype as string, op as string, prec as integer

    prec = getprec
    if prec = 0 or prec < minprec then exit do

    prec = prec + 1 ' add one for left associative operators
    op = tok
    call nexttok
    righttype$ = expression$(prec)
    if errors then exit function

    if lefttype = "number" and righttype$ = "number" then
      neval(op)
    elseif lefttype = "string" and righttype$ = "string" then
      lefttype = seval(op)
    else
      print "type mismatch in expression"
      errors = true
      exit function
    end if
  loop

  expression$ = lefttype
end function

sub pushnum(n as long)
  nstx = nstx + 1
  numstack(nstx) = n
end sub

sub pushstring(s as string)
  sstx = sstx + 1
  stringstack(sstx) = s
end sub

function popnum
  popnum = numstack(nstx)
  nstx = nstx - 1
end function

function popstring$
  popstring$ = stringstack(sstx)
  sstx = sstx - 1
end function

function getprec
  getprec = 0

  if tok = "=" or tok = "<>" or tok = "<" or tok = "<=" or tok = ">" or tok = ">=" then
    getprec = 1
  elseif tok = "+" or tok = "-" then
    getprec = 2
  elseif tok = "*" or tok = "/" or tok = "mod" then
    getprec = 3
  end if
end function

function getvarindex
  if toktype = "nident" or toktype = "sident" then
    getvarindex = asc(left$(tok, 1)) - asc("a")
  else
    print "Not a variable:"; tok: errors = true
  end if
end function

sub expect(s as string)
  if accept(s) then exit sub
  print "("; curline; ") expecting "; s; " but found "; tok; " =>"; pgm(curline): errors = true
end sub

function accept(s as string)
  accept = false
  if tok = s then accept = true: call nexttok
end function

sub initlex(n as integer)
  curline = n
  textp = 1
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
  toktype = "nident"
  while (thech >= "a" and thech <= "z") or (thech >= "A" and thech <= "Z")
    tok = tok + thech
    call getch
  wend
  tok = lcase$(tok)
  if thech = "$" then
    tok = tok + thech
    toktype = "sident"
    call getch
  end if
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
