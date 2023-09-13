      rem Ed Davis. Tiny Basic that can play Star Trek

      install @lib$+"stringlib"
      _toktype$ = "" : _tok$ = "" : thech$ = "": thelin$ = ""

      gsp% = 0: curline% = 0: textp% = 0: num% = 0
      _errors% = 0: tracing% = 0: needcolon% = 0

      MAXLINES% = 7000 : MAXVARS% = 26 : ATMAX% = 500 : GSTACK% = 100
      SQUOTE$ = chr$(39) : DQUOTE$ = chr$(34)

      dim pgm$(MAXLINES%) : rem  program stored here
      dim vars%(MAXVARS%)
      dim gstackln%(GSTACK%) : rem  gosub line stack
      dim gstacktp%(GSTACK%) : rem  gosub textp stack
      dim atarry%(ATMAX%) : rem  the @ array
      dim _forvar%(MAXVARS%)
      dim _forlimit%(MAXVARS%)
      dim _forline%(MAXVARS%)
      dim _forpos%(MAXVARS%)

      rem  current token, and it's type
      rem  current program line, current character
      rem  position in current line
      rem  last number read by scanner

      procnewstmt
      rem if @cmd$ <> "" then
      rem   _toktype$ = "string" : _tok$ = DQUOTE$ + @cmd$
      rem   procloadstmt
      rem   _tok$ = "run" : procdocmd
      rem else
      rem   prochelp
      rem endif
      prochelp
      repeat
        _errors% = false
        input line "qb> " pgm$(0)
        if pgm$(0) <> "" then
          procinitlex(0)
          if _toktype$ = "number" then
            procvalidlinenum
            if not _errors% then pgm$(num%) = mid$(pgm$(0), textp%)
          else
            procdocmd
          endif
        endif
      until false

      def procdocmd
      repeat
        if tracing% and left$(_tok$, 1) <> ":" then print str$(curline%) " " ; _tok$; thech$; mid$(thelin$, textp%)
        needcolon% = true
        case _tok$ of
          when "bye", "quit" : procnexttok : oscli"REFRESH ON":end
          when "end", "stop" : procnexttok : endproc
          when "clear" : procnexttok : procclearvars : endproc
          when "help" : procnexttok : prochelp : endproc
          when "list" : procnexttok : procliststmt : endproc
          when "load", "old" : procnexttok : procloadstmt : endproc
          when "new" : procnexttok : procnewstmt : endproc
          when "run" : procnexttok : procrunstmt
          when "save" : procnexttok : procsavestmt : endproc
          when "tron" : procnexttok : tracing% = true
          when "troff" : procnexttok : tracing% = false
          when "cls" : procnexttok : cls
          when "for" : procnexttok : procforstmt
          when "gosub" : procnexttok : procgosubstmt
          when "goto" : procnexttok : procgotostmt
          when "if" : procnexttok : procifstmt
          when "input" : procnexttok : procinputstmt
          when "next" : procnexttok : procnextstmt
          when "print", "?" : procnexttok : procprintstmt
          when "return" : procnexttok : procreturnstmt
          when "@" : procnexttok : procarrassn
          when ":", "" : rem  handled below
          otherwise:
            if _tok$ = "let" then procnexttok
            if _toktype$ = "ident" then
              procassign
            else
              print "Unknown token '"; _tok$; "' at line:"; str$(curline%) " " ; " Col:"; str$(textp%) " " ; " : "; thelin$ : _errors% = true
            endif
        endcase

        if _errors% then endproc
        if _tok$ = "" then
          while _tok$ = ""
            if curline% = 0 or curline% >= MAXLINES% then endproc
            procinitlex(curline% + 1)
          endwhile
        elseif _tok$ = ":" then;
          procnexttok
        elseif needcolon% and not fnaccept(":") then;
          print ": expected but found: "; _tok$
          endproc
        endif
      until false
      endproc

      def prochelp
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
      endproc

      def procassign
      local var%
      var% = fngetvarindex : procnexttok
      procexpect("=")
      vars%(var%) = fnexpression(0)
      if tracing% then print "*** "; chr$(var% + asc("a")); " = "; str$(vars%(var%)) " "
      endproc

      def procarrassn
      local _atndx%, n%
      rem  array assignment: @(expr) = expr

      _atndx% = fnparenexpr
      if _tok$ <> "=" then
        print "Array Assign: Expecting '=', found:"; _tok$ : _errors% = true
      else
        procnexttok : rem  skip the "="
        n% = fnexpression(0)
        atarry%(_atndx%) = n%
        if tracing% then print "*** @("; str$(_atndx%) " " ; ") = "; str$(n%) " "
      endif
      endproc

      def procforstmt
      local var%, _forndx%, n%
      rem  for i = expr to expr

      var% = fngetvarindex
      procassign
      rem  vars(var) has the value; var has the number value of the variable in 0..25
      _forndx% = var%
      _forvar%(_forndx%) = vars%(var%)
      if _tok$ <> "to" then
        print "For: Expecting 'to', found:"; _tok$ : _errors% = true
      else
        procnexttok
        n% = fnexpression(0)
        _forlimit%(_forndx%) = n%
        rem  need to store iter, limit, line, and col
        _forline%(_forndx%) = curline%
        if _tok$ = "" then _forpos%(_forndx%) = textp% else _forpos%(_forndx%) = textp% - 2
      endif
      endproc

      def procgosubstmt
      rem  for gosub: save the line and column
      gsp% = gsp% + 1
      gstackln%(gsp%) = curline%
      gstacktp%(gsp%) = textp%

      procgotostmt
      endproc

      def procgotostmt
      num% = fnexpression(0)
      procvalidlinenum
      procinitlex(num%)
      endproc

      def procifstmt
      needcolon% = false
      if fnexpression(0) = 0 then procskiptoeol : endproc
      if _tok$ = "then" then procnexttok
      if _toktype$ = "number" then procgotostmt
      endproc

      def procinputstmt
      local var%, st$
      rem  "input" [string ","] var
      if _toktype$ = "string" then
        print mid$(_tok$, 2);
        procnexttok
        procexpect(",")
      else
        print "? ";
      endif
      var% = fngetvarindex : procnexttok
      input line st$
      if st$ = "" then st$ = "0"

      if left$(st$, 1) >= "0" and left$(st$, 1) <= "9" then
        vars%(var%) = val(st$)
      else
        vars%(var%) = asc(st$)
      endif
      endproc

      def procliststmt
      local i%
      for i% = 1 to MAXLINES%
        if pgm$(i%) <> "" then print str$(i%) " " ; " "; pgm$(i%)
      next i%
      print
      endproc

      def procloadstmt
      local filename$, n%, file%

      procnewstmt
      filename$ = fngetfilename("Load")
      if filename$ = "" then endproc
      file% = openin(filename$) : if file%=0 error 53, "Cannot open file": endproc
      n% = 0
      while not eof#file%
        pgm$(0) = get$#file%
        procinitlex(0)
        if _toktype$ = "number" and num% > 0 and num% <= MAXLINES% then
          n% = num%
        else
          n% = n% + 1 : textp% = 1
        endif
        pgm$(n%) = mid$(pgm$(0), textp%)
      endwhile
      close #file%
      curline% = 0
      endproc

      def procnewstmt
      local i%
      procclearvars
      for i% = 1 to MAXLINES%
        pgm$(i%) = ""
      next i%
      endproc

      def procnextstmt
      local _forndx%

      rem  tok needs to have the variable
      _forndx% = fngetvarindex
      _forvar%(_forndx%) = _forvar%(_forndx%) + 1
      vars%(_forndx%) = _forvar%(_forndx%)
      if _forvar%(_forndx%) <= _forlimit%(_forndx%) then
        curline% = _forline%(_forndx%)
        textp% = _forpos%(_forndx%)
        rem print "nextstmt tok>"; tok; " textp>"; textp; " >"; mid$(thelin, textp)
        procinitlex2
      else
        procnexttok : rem  skip the ident for now
      endif
      endproc

      rem  "print" [[#num "," ] expr { "," [#num ","] expr }] [","] {":" stmt} eol
      rem  expr can also be a literal string
      def procprintstmt
      local n%, junk$, _printwidth%, _printnl%

      _printnl% = true
      while (_tok$ <> ":" and _tok$ <> "" and _tok$ <> "else")
        _printnl% = true
        _printwidth% = 0
        if fnaccept("#") then
          if num% <= 0 then print "Expecting a print width, found:"; _tok$ : endproc
          _printwidth% = num%
          procnexttok
          if not fnaccept(",") then print "Print: Expecting a ',', found:"; _tok$ : endproc
        endif

        if _toktype$ = "string" then
          junk$ = mid$(_tok$, 2)
          procnexttok
        else
          n% = fnexpression(0)
          junk$ = fn_trim(str$(n%))
        endif
        _printwidth% = _printwidth% - len(junk$)
        if _printwidth% <= 0 then
            print junk$;
        else
            print spc(_printwidth%); junk$;
        endif

        if fnaccept(",") or fnaccept(";") then
            _printnl% = false
        else
            exit while
        endif
      endwhile

      if _printnl% then print
      endproc

      def procreturnstmt
      rem  exit sub from a subroutine
      curline% = gstackln%(gsp%)
      textp% = gstacktp%(gsp%)
      gsp% = gsp% - 1
      procinitlex2
      endproc

      def procrunstmt
      procclearvars
      procinitlex(1)
      endproc

      def procsavestmt
      local filename$, i%, file%

      filename$ = fngetfilename("Save")
      if filename$ = "" then endproc
      file% = openout(filename$) : if file%=0 error 53, "Cannot create file": endproc
      for i% = 1 to MAXLINES%
        if pgm$(i%) <> "" then print#file%, str$(i%) + " " + pgm$(i%)
      next i%
      close #file%
      endproc

      def fngetfilename(action$)
      local filename$, _getfilename$
      if _toktype$ = "string" then
        filename$ = mid$(_tok$, 2)
      else
        print action$; ": ",;
        input line filename$
      endif
      if filename$ <> "" then
        if instr(filename$,".") = 0 then filename$ = filename$ + ".bas"
      endif
      _getfilename$ = filename$
      = _getfilename$

      def procvalidlinenum
      if num% <= 0 or num% > MAXLINES% then print "Line number out of range" : _errors% = true
      endproc

      def procclearvars
      local i%
      for i% = 1 to MAXVARS%
        vars%(i%) = 0
      next i%
      gsp% = 0
      endproc

      def fnparenexpr
      local n%: n% = 0
      procexpect("(")
      n% = fnexpression(0)
      procexpect(")")
      = n%

      def fnexpression(minprec%)
      local n%: n% = 0

      rem  handle numeric operands - numbers and unary operators
      if _toktype$ = "number" then
        n% = num% : procnexttok
      elseif _tok$ = "(" then;
        n% = fnparenexpr
      elseif _tok$ = "not" then;
        procnexttok : n% = not fnexpression(3)
      elseif _tok$ = "abs" then;
        procnexttok : n% = abs(fnparenexpr)
      elseif _tok$ = "asc" then;
        procnexttok : procexpect(("(")) : n% = asc(mid$(_tok$, 2, 1)) : procnexttok : procexpect((")"))
      elseif _tok$ = "rnd" or _tok$ = "irnd" then;
        procnexttok : n% = int(rnd(1) * fnparenexpr) + 1
      elseif _tok$ = "sgn" then;
        procnexttok : n% = sgn(fnparenexpr)
      elseif _toktype$ = "ident" then;
        n% = vars%(fngetvarindex) : procnexttok
      elseif _tok$ = "@" then;
        procnexttok : n% = atarry%(fnparenexpr)
      elseif _tok$ = "-" then;
        procnexttok : n% = -fnexpression(7)
      elseif _tok$ = "+" then;
        procnexttok : n% = fnexpression(7)
      else
        print "syntax error: expecting an operand, found: ", _tok$
        _errors% = true
      endif

      while not _errors% : rem  while binary operator and precedence of tok >= minprec
        if minprec% <= 1 and _tok$ = "or" then
          procnexttok : n% = n% or fnexpression(2)
        elseif minprec% <= 2 and _tok$ = "and" then;
          procnexttok : n% = n% and fnexpression(3)
        elseif minprec% <= 4 and _tok$ = "=" then;
          procnexttok : n% = abs(n% = fnexpression(5))
        elseif minprec% <= 4 and _tok$ = "<" then;
          procnexttok : n% = abs(n% < fnexpression(5))
        elseif minprec% <= 4 and _tok$ = ">" then;
          procnexttok : n% = abs(n% > fnexpression(5))
        elseif minprec% <= 4 and _tok$ = "<>" then;
          procnexttok : n% = abs(n% <> fnexpression(5))
        elseif minprec% <= 4 and _tok$ = "<=" then;
          procnexttok : n% = abs(n% <= fnexpression(5))
        elseif minprec% <= 4 and _tok$ = ">=" then;
          procnexttok : n% = abs(n% >= fnexpression(5))
        elseif minprec% <= 5 and _tok$ = "+" then;
          procnexttok : n% = n% + fnexpression(6)
        elseif minprec% <= 5 and _tok$ = "-" then;
          procnexttok : n% = n% - fnexpression(6)
        elseif minprec% <= 6 and _tok$ = "*" then;
          procnexttok : n% = n% * fnexpression(7)
        elseif minprec% <= 6 and (_tok$ = "/" or _tok$ = "\") then;
          procnexttok : n% = n% div fnexpression(7)
        elseif minprec% <= 6 and _tok$ = "mod" then;
          procnexttok : n% = n% mod fnexpression(7)
        elseif minprec% <= 8 and _tok$ = "^" then;
          procnexttok : n% = int(n% ^ fnexpression(9))
        else
            exit while
        endif
      endwhile

      = n%

      def fngetvarindex
      local _getvarindex%
      if _toktype$ <> "ident" then print "Not a variable:"; _tok$ : _errors% = true : = _getvarindex%
      _getvarindex% = asc(left$(_tok$, 1)) - asc("a")
      = _getvarindex%

      def procexpect(s$)
      if fnaccept(s$) then endproc
      print "("; str$(curline%) " " ; ") expecting "; s$; " but found "; _tok$; " =>"; pgm$(curline%) : _errors% = true
      endproc

      def fnaccept(s$)
      local accept%
      accept% = false
      if _tok$ = s$ then accept% = true : procnexttok
      = accept%

      def procinitlex(n%)
      curline% = n% : textp% = 1
      procinitlex2
      endproc

      def procinitlex2
      needcolon% = false
      thelin$ = pgm$(curline%)
      thech$ = " "
      procnexttok
      endproc

      def procnexttok
      _tok$ = "" : _toktype$ = ""
      while thech$ <= " "
        if thech$ = "" then endproc
        procgetch
      endwhile
      _tok$ = thech$ : procgetch
      case _tok$ of
        when "0","1","2","3","4","5","6","7","8","9" :
          procreadint
        when SQUOTE$ : procskiptoeol
        when DQUOTE$ : procreadstr
        when "#", "(", ")", "*", "+", ",", "-", "/", ":", ";", "<", "=", ">", "?", "@", "\", "^" :
          _toktype$ = "punct"
          if (_tok$ = "<" and (thech$ = ">" or thech$ = "=")) or (_tok$ = ">" and thech$ = "=") then
            _tok$ = _tok$ + thech$
            procgetch
          endif
        otherwise:
            if (_tok$ >= "a" and _tok$ <= "z") or (_tok$ >= "A" and _tok$ <= "Z") then
                procreadident : if _tok$ = "rem" then procskiptoeol
            else
                print "("; str$(curline%) " " ; ") "; "What?"; _tok$; " : "; thelin$ : _errors% = true
            endif
      endcase
      endproc

      def procskiptoeol
      _tok$ = "" : _toktype$ = ""
      textp% = len(thelin$) + 1
      endproc

      def procreadint
      _toktype$ = "number"
      while thech$ >= "0" and thech$ <= "9"
        _tok$ = _tok$ + thech$
        procgetch
      endwhile
      num% = val(_tok$)
      endproc

      def procreadident
      _toktype$ = "ident"
      while (thech$ >= "a" and thech$ <= "z") or (thech$ >= "A" and thech$ <= "Z")
        _tok$ = _tok$ + thech$
        procgetch
      endwhile
      _tok$ = fn_lower(_tok$)
      endproc

      def procreadstr
      rem  store double quote as first char of string, to distinguish from idents
      _toktype$ = "string"
      while thech$ <> DQUOTE$ : rem  while not a double quote
        if thech$ = "" then print "String not terminated" : _errors% = true : endproc
        _tok$ = _tok$ + thech$
        procgetch
      endwhile
      procgetch : rem  skip closing double quote
      endproc

      def procgetch
      if textp% > len(thelin$) then
        thech$ = ""
      else
        thech$ = mid$(thelin$, textp%, 1)
        textp% = textp% + 1
      endif
      endproc
