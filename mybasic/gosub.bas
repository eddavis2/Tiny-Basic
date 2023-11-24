'Ed Davis. Tiny Basic that can play Star Trek
'$console:only
'option _explicit

deflng a-z
true = -1: false = 0: c_maxlines = 7000: c_maxvars = 26: c_at_max = 500: c_g_stack = 100
c_squote$ = chr$(39): c_dquote$ = chr$(34)
c_default = 0: c_ident = 1: c_number = 2: c_string = 3: c_punct = 4

dim pgm$(7000) ' program stored here
dim vars(26)
dim gstackln(100) ' gosub line stack
dim gstacktp(100) ' gosub textp stack
dim atarry(500) ' the @ array
dim forvar(26)
dim forlimit(26)
dim forline(26)
dim forpos(26)
dim nstack(50)      ' stack for results in expressions
dim pstack(50)      ' stack for results in expressions

rem dim gsp
rem dim as string tok$              ' current token, and it's type
rem dim as string thelin$, thech$    ' current program line, current character
rem dim as integer curline, textp  ' position in current line
rem dim num as long                ' last number read by scanner
rem dim as integer toktype, errors, tracing

gsp = 0: tracing = false: nsp = 0: n = 0
gosub newstmt
if command$ <> "" then
  pgm$(0) = "run " + c_dquote$ + command$ + c_dquote$
  num = 0: gosub initlex
  gosub docmd
else
  gosub helpstmt
end if
do
  errors = false
  line input "qb> ", pgm$(0)
  if pgm$(0) <> "" then
    num = 0: gosub initlex
    rem if line starts with a number, store it, otherwise run it
    if toktype = c_number then
      gosub validlinenum
      if not errors then pgm$(num) = mid$(pgm$(0), textp)
    else
      gosub docmd
    end if
  end if
loop

docmd:
  do while not errors
    if tracing and left$(tok$, 1) <> ":" then print curline; tok$; thech$; mid$(thelin$, textp)
    need_colon = false
    if tok$ = "bye" or tok$ = "quit" then
      gosub nexttok: end
    elseif tok$ = "end" or tok$ = "stop" then
      gosub nexttok: return
    elseif tok$ = "load" or tok$ = "old" then
      gosub nexttok: gosub loadstmt: return
    elseif tok$ = "new" then
      gosub nexttok: gosub newstmt:  return
    elseif tok$ = "gosub" then
      gosub nexttok: gosub gosubstmt
    elseif tok$ = "goto" then
      gosub nexttok: gosub gotostmt
    elseif tok$ = "if" then
      gosub nexttok: gosub ifstmt
    elseif tok$ = "next" then
      gosub nexttok: gosub nextstmt
    elseif tok$ = "return" then
      gosub nexttok: gosub returnstmt
    elseif tok$ = "run" then
      gosub nexttok: gosub runstmt
    elseif tok$ = "clear" then
      gosub nexttok: gosub clearstmt:need_colon = true
    elseif tok$ = "cls" then
      gosub nexttok: cls:need_colon = true
    elseif tok$ = "for" then
      gosub nexttok: gosub forstmt:need_colon = true
    elseif tok$ = "helpstmt" then
      gosub nexttok: gosub helpstmt:need_colon = true
    elseif tok$ = "input" then
      gosub nexttok: gosub inputstmt:need_colon = true
    elseif tok$ = "list" then
      gosub nexttok: gosub liststmt:need_colon = true
    elseif tok$ = "print" or tok$ = "?" then
      gosub nexttok: gosub printstmt: need_colon = true
    elseif tok$ = "save" then
      gosub nexttok: gosub savestmt   :need_colon = true
    elseif tok$ = "troff" then
      gosub nexttok: tracing = false :need_colon = true
    elseif tok$ = "tron" then
      gosub nexttok: tracing = true  :need_colon = true
    elseif tok$ = ":" or tok$ = "" then
      gosub nexttok
    else
      if tok$ = "let" then gosub nexttok
      if toktype = c_ident then
        gosub assign
      elseif tok$ = "@" then
        gosub nexttok: gosub arrassn
      else
        print "Unknown token '"; tok$; "' at line:"; curline; " Col:"; textp; " : "; thelin$: errors = true
      end if
    end if

    if tok$ = "" then
      while tok$ = "" and not errors
        if curline = 0 or curline >= c_maxlines then
          errors = true
        else
          num = curline + 1: gosub initlex
        end if
      wend
    elseif need_colon then
      if tok$ = ":" then
        gosub nexttok
      else
        print ": expected but found: "; tok$: errors = true
      end if
    end if
  loop
  return

helpstmt:
  print "+---------------------- Tiny Basic (QBASIC) --------------------------+"
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
  return

assign:
  gosub getvarindex: var = n
  gosub nexttok
  s$ = "=": gosub expect
  gosub expression: vars(var) = retval
  if tracing then print "*** "; chr$(var + asc("a")); " = "; vars(var)
  return

arrassn:   ' array assignment: @(expr) = expr
  gosub parenexpr: atndx = retval
  s$ = "=": gosub expect
  gosub expression: atarry(atndx) = retval
  if tracing then print "*** @("; atndx; ") = "; atarry(atndx)
  return

clearstmt: rem clear out variables
  for i = 0 to maxvar
    vars(i) = 0
  next i
  for i = 0 to atmax
    atarry(i) = 0
  next i
  gsp = 0
  return

forstmt:   rem for i = expr to expr
  gosub assign
  ' vars(var) has the value; var has the number value of the variable in 0..25
  forndx = var
  forvar(forndx) = vars(var)
  if tok$ <> "to" then
    print "For: Expecting 'to', found:"; tok: errors = true
  else
    gosub nexttok
    gosub expression
    forlimit(forndx) = retval
    ' need to store iter, limit, line, and col
    forline(forndx) = curline
    if tok$ = "" then forpos(forndx) = textp else forpos(forndx) = textp - 1
  end if
  return

gosubstmt:   rem for gosub: save the line and column
  gsp = gsp + 1
  gosub expression: num = retval
  gstackln(gsp) = curline
  if tok$ = "" then gstacktp(gsp) = textp else gstacktp(gsp) = textp - 1
  gosub validlinenum
  gosub initlex
  return

gotostmt:
  gosub expression: num = retval
  gosub validlinenum
  gosub initlex
  return

ifstmt:
  gosub expression
  if retval = 0 then gosub skiptoeol: return
  if tok$ = "then" then gosub nexttok
  if toktype = c_number then gosub gotostmt
  return

inputstmt:   rem "input" [string ","] var
  if toktype = c_string then
    print mid$(tok$, 2);
    gosub nexttok
    s$ = ",": gosub expect
  else
    print "? ";
  end if
  gosub getvarindex
  var = n: gosub nexttok
  line input st$
  if st$ = "" then st$ = "0"
  if (left$(st$, 1) >= "0" and left$(st$, 1) <= "9") or left$(st$, 1) = "-" then
    vars(var) = val(st$)
  else
    vars(var) = asc(st$)
  end if
  return

liststmt:
  for i = 1 to c_maxlines
    if pgm$(i) <> "" then print i; " "; pgm$(i)
  next i
  print
  return

loadstmt:
  action$ = "Load": gosub getfilename
  if filename$ = "" then return
  gosub newstmt
  open filename$ for input as #1
  n = 0
  while not eof(#1)
    line input #1, pgm$(0)
    num = 0: gosub initlex
    if toktype = c_number and num > 0 and num <= c_maxlines then
      n = num
    else
      n = n + 1: textp = 1
    end if
    pgm$(n) = mid$(pgm$(0), textp)
  wend
  close #1
  curline = 0
  return

newstmt: rem clear out program and variables
  gosub clearstmt
  for i = 1 to c_maxlines
    pgm$(i) = ""
  next i
  return

nextstmt:
  ' tok needs to have the variable
  gosub getvarindex
  forndx = n
  forvar(forndx) = forvar(forndx) + 1
  vars(forndx) = forvar(forndx)
  if forvar(forndx) <= forlimit(forndx) then
    curline = forline(forndx)
    textp   = forpos(forndx)
    gosub initlex2
  else
    gosub nexttok ' skip the ident for now
    if tok$ <> "" and tok$ <> ":" then
      print "Next: expected ':' before statement, but found:"; tok: errors = true
    end if
  end if
  return

' "print" [[#num "," ] expr { "," [#num ","] expr }] [","] {":" stmt} eol
' expr can also be a literal string
printstmt:
  printnl = true
  do while tok$ <> ":" and tok$ <> "" and tok$ <> "else"
    printnl = true
    printwidth = 0
    if tok$ = "#" then
      gosub nexttok
      if num <= 0 then print "Expecting a print width, found:"; tok$: return
      printwidth = num
      gosub nexttok
      if tok$ <> "," then print "Print: Expecting a ',', found:"; tok$: return
      gosub nexttok
    end if

    if toktype = c_string then
      junk$ = mid$(tok$, 2)
      gosub nexttok
    elseif toktype = c_ident and tok$ = "chr" and thech$ = "$" then
        textp = textp + 1  ' consume $
        gosub nexttok      ' get (
        gosub parenexpr
        junk$ = chr$(retval)
    else
      gosub expression
      junk$ = ltrim$(str$(retval))
    end if
    printwidth = printwidth - len(junk$)
    if printwidth <= 0 then print junk$; else print space$(printwidth); junk$;

    if tok$ = "," or tok$ = ";" then
      gosub nexttok
      printnl = false
    else
      exit do
    end if
  loop

  if printnl then print
  return

returnstmt: rem return from a subroutine
  curline = gstackln(gsp)
  textp   = gstacktp(gsp)
  gsp = gsp - 1
  gosub initlex2
  if tok$ <> "" and tok$ <> ":" then
    print "Return: expected ':' before statement, but found:"; tok$: errors = true
  end if
  return

runstmt:
  if toktype = c_string then gosub loadstmt
  gosub clearstmt
  num = 1: gosub initlex
  return

savestmt:
  action$ = "Save": gosub getfilename
  if filename$ = "" then return
  open filename$ for output as #1
  for i = 1 to c_maxlines
    if pgm$(i) <> "" then print #1, i; pgm$(i)
  next i
  close #1
  return

getfilename: rem passed action, returns filename
  if toktype = c_string then
    filename$ = mid$(tok$, 2)
  else
    print action$; ": ";
    line input filename$
  end if
  if filename$ <> "" then
    if instr(filename$, ".") = 0 then filename$ = filename$ + ".bas"
  end if
  return

validlinenum:
  if num <= 0 or num > c_maxlines then print "Line number out of range": errors = true
  return

parenexpr: rem parenthesized expression processing, external entry point
  nsp = 0: retval = 0: prec = 0

parenexpr2: rem internal entry point
  s$ = "(": gosub expect: if errors then return
  prec = 0: gosub expr2
  s$ = ")": gosub expect
  return

expression: rem expression processing, external entry point
  nsp = 0: retval = 0: prec = 0: minprec = 0

expr2: rem expression processing - internal entry point
  gosub pushexp
  n = 0: minprec = prec

  ' handle numeric operands - numbers and unary operators
  if toktype = c_number then
    n = num: gosub nexttok
  elseif tok$ = "("   then
    gosub parenexpr2: n = retval
  elseif tok$ = "not" then
    gosub nexttok: prec = 3: gosub expr2: n = not retval
  elseif tok$ = "abs" then
    gosub nexttok:  gosub parenexpr2: n = abs(retval)
  elseif tok$ = "asc" then
    gosub nexttok
    s$ = "(": gosub expect
    n = asc(mid$(tok$, 2, 1))
    gosub nexttok
    s$ = ")": gosub expect
  elseif tok$ = "rnd" or tok$ = "irnd" then
    gosub nexttok: gosub parenexpr2: n = int(rnd * retval) + 1
  elseif tok$ = "sgn" then
    gosub nexttok:  gosub parenexpr2: n = sgn(retval)
  elseif toktype = c_ident then
    gosub getvarindex: n = vars(n): gosub nexttok
  elseif tok$ = "@"   then
    gosub nexttok: gosub parenexpr2: n = atarry(retval)
  elseif tok$ = "-"   then
    gosub nexttok: prec = 7: gosub expr2: n = -retval
  elseif tok$ = "+"   then
    gosub nexttok: prec = 7: gosub expr2: n =  retval
  else
    print "("; curline; ") syntax error: expecting an operand, found: ", tok$
    errors = true
  end if

  do while not errors  ' while binary operator and precedence of tok$ >= minprec
    if minprec <= 1 and tok$ = "or"  then
      gosub nexttok: prec = 2: gosub expr2: n = n or retval
    elseif minprec <= 2 and tok$ = "and" then
      gosub nexttok: prec = 3: gosub expr2: n = n and retval
    elseif minprec <= 4 and tok$ = "="   then
      gosub nexttok: prec = 5: gosub expr2: n = abs(n =  retval)
    elseif minprec <= 4 and tok$ = "<"   then
      gosub nexttok: prec = 5: gosub expr2: n = abs(n <  retval)
    elseif minprec <= 4 and tok$ = ">"   then
      gosub nexttok: prec = 5: gosub expr2: n = abs(n >  retval)
    elseif minprec <= 4 and tok$ = "<>"  then
      gosub nexttok: prec = 5: gosub expr2: n = abs(n <> retval)
    elseif minprec <= 4 and tok$ = "<="  then
      gosub nexttok: prec = 5: gosub expr2: n = abs(n <= retval)
    elseif minprec <= 4 and tok$ = ">="  then
      gosub nexttok: prec = 5: gosub expr2: n = abs(n >= retval)
    elseif minprec <= 5 and tok$ = "+"   then
      gosub nexttok: prec = 6: gosub expr2: n = n + retval
    elseif minprec <= 5 and tok$ = "-"   then
      gosub nexttok: prec = 6: gosub expr2: n = n - retval
    elseif minprec <= 6 and tok$ = "*"   then
      gosub nexttok: prec = 7: gosub expr2: n = n * retval
    elseif minprec <= 6 and tok$ = "/"   then
      gosub nexttok: prec = 7: gosub expr2: n = n \ retval
    elseif minprec <= 6 and tok$ = "\"   then
      gosub nexttok: prec = 7: gosub expr2: n = n \ retval
    elseif minprec <= 6 and tok$ = "mod" then
      gosub nexttok: prec = 7: gosub expr2: n = n mod retval
    elseif minprec <= 8 and tok$ = "^"   then
      gosub nexttok: prec = 9: gosub expr2: n = n ^ retval
    else
      exit do
    end if
  loop

  retval = n: gosub popexp
  return

getvarindex: rem get index into vars store for variable
  if toktype = c_ident then n = asc(left$(tok$, 1)) - asc("a"): return
  print "("; curline; ") "; "Expecting a variable": errors = true: return

expect: rem s$ must be preloaded
  if s$ = tok$ then gosub nexttok: return
  print "("; curline; ") expecting "; s; " but found "; tok$; " =>"; pgm$(curline): errors = true
  return

pushexp: rem for expressions: save the current context
  nsp = nsp + 1
  nstack(nsp) = n
  pstack(nsp) = minprec
  return

popexp: rem for expressions: restore the current context
  n       = nstack(nsp)
  minprec = pstack(nsp)
  nsp = nsp - 1
  return

initlex:    rem lexical analyzer - num must be preset
  curline = num: textp = 1

initlex2:   rem called with preset line and column
  thelin$ = pgm$(curline)
  gosub nexttok
  return

nexttok:    rem get the next token
  tok$ = "": toktype = c_default: thech$ = ""
  do while textp <= len(thelin$)
    thech$ = mid$(thelin$, textp, 1)
    if toktype = c_default then
      if (thech$ >= "a" and thech$ <= "z") or (thech$ >= "A" and thech$ <= "Z") then
        toktype = c_ident
      elseif thech$ >= "0" and thech$ <= "9" then
        toktype = c_number
      elseif thech$ = c_dquote$ then
        toktype = c_string
      elseif thech$ = c_squote$ then
        gosub skiptoeol: return
      elseif instr("#()*+,-/:;<=>?@\^", thech$) > 0 then
        toktype = c_punct
      elseif thech$ = " " then ' skip spaces
        rem
      else
          print "("; curline; ","; textp; ") "; "What>"; tok$; "< "; thelin$: errors = true: return
      end if
    elseif toktype = c_ident then
        if not ((thech$ >= "a" and thech$ <= "z") or (thech$ >= "A" and thech$ <= "Z")) then exit do
    elseif toktype = c_number then
        if not (thech$ >= "0" and thech$ <= "9") then exit do
    elseif toktype = c_string then
        if thech$ = c_dquote$ then textp = textp + 1: return
    elseif toktype = c_punct then
        if (tok$ = "<" and (thech$ = ">" or thech$ = "=")) or (tok$ = ">" and thech$ = "=") then
          tok$ = tok$ + thech$
          textp = textp + 1
        end if
        return
    end if
    if toktype <> c_default then tok$ = tok$ + thech$
    textp = textp + 1
  loop
  if toktype = c_number then num = val(tok$)
  if toktype = c_string then print "String not terminated": errors = true
  if toktype = c_ident then
    tok$ = lcase$(tok$)
    if tok$ = "rem" then gosub skiptoeol
  end if
  return

skiptoeol:
  tok$ = "": toktype = c_default
  textp = len(thelin$) + 1
  return
