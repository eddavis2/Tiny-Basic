'Ed Davis - Tiny Basic in SmallBasic.

dim pgm() ' program stored here
dim vars()
dim gstackln()    ' gosub line stack
dim gstacktp()    ' gosub textp stack

c_maxlines = 10000
c_maxvars = 27

for i = 0 to c_maxlines
  append pgm, ""
next

for i = 0 to c_maxvars
  append vars, 0
next

pgm(0) = "help"
while true
  errors = false
  if pgm(0) <> "" then
    initlex(0)
    if toktype = "number" then
      validlinenum
      pgm(num) = mid$(pgm(0), textp)
    else
      docmd
    end if
  end if
  print "sb> ";
  lineinput pgm(0)
wend

sub docmd
  local done, i, var, printnl, prtdone
  done = false
  while not errors and not done
    select case tok
      case "bye", "quit" :nexttok: stop
      case "end", "stop" :nexttok: done = true
      case "help"        :nexttok
        print "┌────────────────────── Tiny Basic Help (SmallBasic)────────────┐"
        print "│ bye, end, help, list, load, new, quit, run, save              │█"
        print "│ gosub <expr>, return                                          │█"
        print "│ goto <expr>                                                   │█"
        print "│ if <expr> then <statement>                                    │█"
        print "│ input [prompt,] <var>                                         │█"
        print "│ [let] <var>=<expr>                                            │█"
        print "│ print <expr|string>[,<expr|string>][;]                        │█"
        print "│ rem <anystring> or ' <anystring>                              │█"
        print "│ Operators: + - * / < <= > >= <> =                             │█"
        print "│ Integer variables a..z                                        │█"
        print "└───────────────────────────────────────────────────────────────┘█"
        print "  ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀"
      case "list"        :nexttok: done = true
        for i = 1 to c_maxlines
          if pgm(i) <> "" then print i; " "; pgm(i)
        next i
        print
      case "load", "old" :nexttok:loadstmt: done = true
      case "new"         :nexttok:newstmt:  done = true
      case "run"         :nexttok
        clearvars
        initlex(1)
      case "save"        :nexttok:savestmt: done = true
      case "gosub"       :nexttok
        append gstackln, curline
        append gstacktp, textp
        gotostmt
      case "goto"        :nexttok:gotostmt
      case "if"          :nexttok
        if expression(0) = 0 then
          skiptoeol
        else
          if tok = "then" then nexttok
          if toktype = "number" then gotostmt
        end if
      case "input"       :nexttok
        rem "input" [string ","] var
        if toktype = "string" then
          print mid$(tok, 2);
          nexttok
          expect(",")
        else
          print "? ";
        end if
        var = getvarindex:nexttok
        input vars(var)
      case "print", "?"  :nexttok
        rem "print" [ expr  "," expr ] [","]
        rem expr can also be a literal string

        printnl = true: prtdone = false
        while tok <> "" and tok <> ":" and not prtdone
          printnl = true
          if toktype = "string" then
            print mid$(tok, 2);
            nexttok
          else
            print expression(0);
          end if

          if tok = "," or tok = ";" then
            nexttok
            printnl = false
          else
            prtdone = true
          end if
        wend

        if printnl then print
      case "return"      :    nexttok
        curline = gstackln(ubound(gstackln))
        textp   = gstacktp(ubound(gstacktp))

        delete gstackln, ubound(gstackln)
        delete gstacktp, ubound(gstacktp)

        initlex2
      case ":"           :nexttok  ' just continue
      case ""            : ' handled below
      case else
        if tok = "let" then nexttok
        if toktype = "ident" then
          var = getvarindex:nexttok
          expect("=")
          vars(var) = expression(0)
        else
          print "Unknown token "; tok; " at line "; curline: errors = true
        end if
    end select

    if not errors and not done and curline <= c_maxlines then
      while tok = "" and not done
        if curline = 0 or curline >= c_maxlines then done = true
        initlex(curline + 1)
      wend
    end if
  wend
end sub

sub gotostmt
  num = expression(0)
  validlinenum
  initlex(num)
end sub

sub loadstmt
  local n, filename

  newstmt
  filename = getfilename("Load")
  open filename for input as #1
  n = 0
  while not eof(1)
    line input #1, pgm(0)
    initlex(0)
    if toktype = "number" and num > 0 and num <= c_maxlines then
      n = num
    else
      n = n + 1
      textp = 1
    end if
    pgm(n) = mid$(pgm(0), textp)
  wend
  close #1
  curline = 0
end sub

sub newstmt
  local i
  clearvars
  for i = 1 to c_maxlines
    pgm(i) = ""
  next i
end sub

sub savestmt
  local i,  filename

  newstmt
  filename = getfilename("Save")
  open filename for output as #1
  for i = 1 to c_maxlines
    if pgm(i) <> "" then print #1, i; pgm(i)
  next i
  close #1
end sub

func getfilename(action)
  local filename
  if toktype = "string" then
    filename = mid$(tok, 2)
  else
    print action; ": ";
    lineinput filename
  end if
  if filename <> "" then
    if instr(filename, ".") = 0 then filename = filename + ".bas"
  end if
  getfilename = filename
end func

sub validlinenum
  if num <= 0 or num > c_maxlines then print "Line number out of range": errors = true
end sub

sub clearvars
  local i
  for i = 1 to c_maxvars
    vars(i) = 0
  next i
end sub

func expression(minprec)
  local n, done

  done = false
  ' handle numeric operands - numbers and unary operators
  if 0 then ' to allow elseif
  elseif tok = "-" then
    nexttok: n = -expression(4)
  elseif tok = "+" then
    nexttok: n =  expression(4)
  elseif tok = "(" then
    nexttok: n =  expression(0):expect(")")
  elseif toktype = "number" then
    n = num:nexttok
  elseif toktype = "ident" then
    n = vars(getvarindex):nexttok
  else
    print "syntax error: expecting an operand, found: ", tok
    errors = true
  end if

  ' while binary operator and precedence of tok >= minprec
  while not errors and not done
    if 0 then ' to allow elseif
    elseif minprec <= 1 and tok = "="  then
      nexttok: n = abs(n =  expression(2))
    elseif minprec <= 1 and tok = "<"  then
      nexttok: n = abs(n <  expression(2))
    elseif minprec <= 1 and tok = ">"  then
      nexttok: n = abs(n >  expression(2))
    elseif minprec <= 1 and tok = "<>" then
      nexttok: n = abs(n <> expression(2))
    elseif minprec <= 1 and tok = "<=" then
      nexttok: n = abs(n <= expression(2))
    elseif minprec <= 1 and tok = ">=" then
      nexttok: n = abs(n >= expression(2))
    elseif minprec <= 2 and tok = "+"  then
      nexttok: n = n +  expression(3)
    elseif minprec <= 2 and tok = "-"  then
      nexttok: n = n -  expression(3)
    elseif minprec <= 3 and tok = "*"  then
      nexttok: n = n *  expression(4)
    elseif minprec <= 3 and tok = "/"  then
      nexttok: n = n \  expression(4)
    else
      done = true
    end if
  wend

  expression = n
end func

func getvarindex
  if toktype <> "ident" then
    print "Not a variable:"; tok: errors = true
    getvarindex = 0
  else
    getvarindex = asc(left$(tok, 1)) - asc("a")
  end if
end func

sub expect(s)
  if tok = s then
    nexttok
  else
    print "("; curline; ") expecting "; s; " but found "; tok; " =>"; pgm(curline): errors = true
  end if
end sub

sub initlex(n)
  curline = n
  textp = 1
  initlex2
end sub

sub initlex2
  if curline < len(pgm) then
    thelin = pgm(curline)
    thech = " "
  else
    thelin = ""
    thech = ""
  end if
  nexttok
end sub

sub skiptoeol
  tok = "": toktype = ""
  textp = len(thelin) + 1
end sub

sub nexttok
  tok = "": toktype = ""
  while thech <= " " and thech <> ""
    getch
  wend
  if thech <> "" then
    toktype = "punct"
    tok = thech + mid$(thelin, textp, 1)
    if tok = ">=" or tok = "<=" or tok = "<>" then
     getch:getch:
    else
      tok = thech
      if instr("()*+,-/:;<=>?", thech) > 0 then
        getch
      elseif tok = chr$(34) then
        ' leave the " as the beginning of the string, so it won't get confused with other tokens
        ' especially in the print routines
        toktype = "string"
        getch
        while thech <> chr$(34) and thech <> ""
          tok = tok + thech
          getch
        wend
        if thech <> chr$(34) then
          print "String not terminated": errors = true
        else
          getch
        end if
      elseif (thech >= "a" and thech <= "z") or (thech >= "A" and thech <= "Z") then
        tok = "": toktype = "ident"
        while (thech >= "a" and thech <= "z") or (thech >= "A" and thech <= "Z")
          tok = tok + lcase$(thech)
          getch
        wend
        if tok = "rem" then skiptoeol
      elseif isnumber(thech) then
        tok = "": toktype = "number"
        while thech >= "0" and thech <= "9"
          tok = tok + thech
          getch
        wend
        num = val(tok)
      elseif tok = chr$(39) then
        skiptoeol
      else
        toktype = ""
        print "("; curline; ","; textp; ") What?"; thech: errors = true
      end if
    end if
  end if
end sub

sub getch
  if textp > len(thelin) then
    thech = ""
  else
    thech = mid$(thelin, textp, 1)
    textp = textp + 1
  end if
end sub
