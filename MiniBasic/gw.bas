10 rem Tiny Basic interpreter for MiniBasic (https://github.com/JoeStrout/minibasic)
20 rem No subs or functions. No local variables. Plays Star Trek.
30 rem By Ed Davis
40 maxlines = 1000: atmax = 500: maxvar = 26: true = -1: false = 0
50 rem
60 dim pgm$(maxlines): rem (0) used for work line; programs stored here
70 dim vars(maxvar):   rem variables a-z
80 dim atarry(atmax):  rem the @ array
90 dim nstack(50):     rem stack for results in expressions
100 dim pstack(50):     rem stack for results in expressions
110 dim gstackln(200):  rem gosub return line stack
120 dim gstacktp(200):  rem gosub return textp stack
130 dim forvar(maxvar)
140 dim forlimit(maxvar)
150 dim forline(maxvar)
160 dim forpos(maxvar)
170 rem
180 rem dim atndx      'index into @ array
190 rem dim curline    'number of the current line
200 rem dim forndx     'temp, used in forstmt and nextstmt
210 rem dim gsp        'gosub stack(s) index
220 rem dim i          '
230 rem dim n          'used in expression parser and a few other places
240 rem dim nsp        'stack pointer for nstack, opstack
250 rem dim num        'set to current number by scanner
260 rem dim printnl    'used by printstmt
270 rem dim printwidth 'used by printstmt
280 rem dim retval     'only used by expression parser
290 rem dim textp      'column pointer in current line
300 rem dim tracing
310 rem dim var        'used in inputstmt and assign
320 rem
330 rem dim thech$     'only used in scanner
340 rem dim filename$  'used in load
350 rem dim tmp$       'used in inputstmt and printstmt
360 rem dim thelin$    'text of the current line
370 rem dim tok$       'returned by scanner
380 rem dim toktype$   '"number", "ident", "punct", "string"
390 rem
400 gsp = 0: tracing = false
410 gosub 910
420 rem main loop
430 errors = false
440 input "mb> ", pgm$(0)
450 if pgm$(0) = "" then goto 420
460 num = 0: gosub 3610
470 rem if line starts with a number, store it, otherwise run it
480 if toktype$ <> "number" then gosub 530: goto 420
490 gosub 2750
500 if not errors then pgm$(num) = mid$(pgm$(0), textp)
510 goto 420
520 rem
530 rem main command processor
540 if errors or curline > maxlines then return
550 if tok$ <> "" then goto 600
560 if curline = 0 or curline >= maxlines then return
570 num = curline + 1: gosub 3610
580 goto 530
590 rem
600 if tracing and left$(tok$, 1) <> ":" then print curline; tok$; thech$; mid$(thelin$, textp)
610 if tok$ = "bye" or tok$ = "quit" then end
620 if tok$ = "end" or tok$ = "stop" then return
630 if tok$ = "clear"   then gosub 1290: return
640 if tok$ = "help"    then gosub 910: return
650 if tok$ = "list"    then gosub 1840: return
660 if tok$ = "load" or tok$ = "old" then gosub 3760: gosub 1910: return
670 if tok$ = "new"     then gosub 2140: return
680 if tok$ = "run"     then gosub 2700: goto 530
690 if tok$ = "tron"    then gosub 3760: tracing = true: goto 530
700 if tok$ = "troff"   then gosub 3760: tracing = false: goto 530
710 if tok$ = "cls"     then gosub 3760: cls: goto 530
720 if tok$ = "for"     then gosub 3760: gosub 1390: goto 530
730 if tok$ = "gosub"   then gosub 3760: gosub 1540: goto 530
740 if tok$ = "goto"    then gosub 3760: gosub 1590: goto 530
750 if tok$ = "if"      then gosub 3760: gosub 1650: goto 530
760 if tok$ = "input"   then gosub 3760: gosub 1720: goto 530
770 if tok$ = "next"    then gosub 3760: gosub 2210: goto 530
780 if tok$ = "print" or tok$ = "?" then gosub 3760: gosub 2330: goto 530
790 if tok$ = "return"  then gosub 3760: gosub 2630: goto 530
800 if tok$ = ":"       then gosub 3760: goto 530
810 if tok$ = "let"     then gosub 3760: rem fall-through
820 if tok$ = "@"       then gosub 3760: gosub 1190: goto 530
830 if toktype$ = "ident" then gosub 1080:  goto 530
840 if tok$ = ""        then                  goto 530
850 rem
860 print "Unknown token '"; tok$; "' at line:"; curline; " Col:"; textp; " : "; thelin$
870 return
880 rem
890 rem statements
900 rem
910 rem show the help screen
920 print "+---------------Tiny Basic Help (MiniBasic version)---------------+"
930 print "| bye, clear, cls, end, help, list, load, new, run, tron, troff   |"
940 print "| for <var> = <expr1> to <expr2> ... next <var>                   |"
950 print "| gosub <expr> ... return                                         |"
960 print "| goto <expr>                                                     |"
970 print "| if <expr> then <statement>                                      |"
980 print "| input [prompt,] <var>                                           |"
990 print "| [let] <var>=<expr>                                              |"
1000 print "| print <expr|string>[,<expr|string>][;]                          |"
1010 print "| rem <anystring> or '<anystring>                                 |"
1020 print "| Operators: + - * / < <= > >= <> =                               |"
1030 print "| Integer variables a..z, and array @(expr)                       |"
1040 print "| Functions: abs(expr), asc(ch), rnd(expr), sgn(expr)             |"
1050 print "+-----------------------------------------------------------------+"
1060 return
1070 rem
1080 rem assignment: ident = expression - side effect: var has variable index
1090 gosub 3390
1100 var = n
1110 gosub 3760
1120 if tok$ <> "=" then print "("; curline; ") "; "Assign: Expecting '=', found:"; tok$: errors = true: return
1130 gosub 3760
1140 gosub 2900
1150 vars(var) = retval
1160 if tracing then print "*** "; chr$(var + asc("a")); " = "; retval
1170 return
1180 rem
1190 rem array assignment: @(expr) = expr
1200 gosub 2790
1210 atndx = retval
1220 if tok$ <> "=" then print "("; curline; ") "; "Array Assign: Expecting '=', found:"; tok$: errors = true: return
1230 gosub 3760:     rem skip the "="
1240 gosub 2900
1250 atarry(atndx) = retval
1260 if tracing then print "*** @("; atndx; ") = "; retval
1270 return
1280 rem
1290 rem clear statement
1300 for i = 1 to maxvar
1310 vars(i) = 0
1320 next i
1330 for i = 0 to atmax
1340 atarry(i) = 0
1350 next i
1360 gsp = 0
1370 return
1380 rem
1390 rem for i = expr to expr
1400 gosub 1080
1410 rem vars(var) has the value; var has the number value of the variable in 0..25
1420 forndx = var
1430 forvar(forndx) = vars(var)
1440 if tok$ <> "to" then print "("; curline; ") "; "For: Expecting 'to', found:"; tok$: errors = true: return
1450 gosub 3760
1460 gosub 2900: rem result in retval
1470 forlimit(forndx) = retval
1480 rem need to store iter, limit, line, and col
1490 forline(forndx) = curline
1500 forpos(forndx) = textp
1510 if tok$ <> "" then forpos(forndx) = textp - 2
1520 return
1530 rem
1540 rem gosub expr
1550 gosub 3550
1560 gosub 1590
1570 return
1580 rem
1590 rem goto expr
1600 gosub 2900: num = retval
1610 gosub 2750
1620 gosub 3610
1630 return
1640 rem
1650 rem if expr [then] statment
1660 gosub 2900
1670 if retval = 0 then gosub 3710: return
1680 if tok$ = "then" then gosub 3760
1690 if toktype$ = "number" then gosub 1590
1700 return
1710 rem
1720 rem "input" [string ","] var
1730 if toktype$ <> "string" then print "? ": goto 1780
1740 print mid$(tok$, 2);
1750 gosub 3760
1760 if tok$ <> "," then print "("; curline; ") "; "Input: Expecting ',', found:"; tok$: errors = true: return
1770 gosub 3760
1780 gosub 3390: var = n: gosub 3760
1790 input tmp$: if tmp$ = "" then tmp$ = "0"
1800 vars(var) = asc(tmp$)
1810 if left$(tmp$, 1) >= "0" and left$(tmp$, 1) <= "9" then vars(var) = val(tmp$)
1820 return
1830 rem
1840 rem list the code
1850 for i = 1 to maxlines
1860 if pgm$(i) <> "" then print i; " "; pgm$(i)
1870 next i
1880 print
1890 return
1900 rem
1910 rem load statement
1920 gosub 2140
1930 if toktype$ <> "string" then goto 1960
1940 filename$ = mid$(tok$, 2)
1950 goto 1980
1960 input "Program?", filename$
1970 if filename$ = "" then return
1980 if instr(filename$, ".") = 0 then filename$ = filename$ + ".bas"
1990 open 1, 0, filename$
2000 n = 0
2010 if eof(1) then goto 2080
2020 input# 1, pgm$(0)
2030 num = 0: gosub 3610
2040 if toktype$ = "number" and num > 0 and num <= maxlines then n = num: goto 2060
2050 n = n + 1: textp = 1
2060 pgm$(n) = mid$(pgm$(0), textp)
2070 goto 2010
2080 close 1
2090 filename$ = ""
2100 curline = 0
2110 tok$ = ""
2120 return
2130 rem
2140 rem new statement
2150 gosub 1290
2160 for i = 1 to maxlines
2170 pgm$(i) = ""
2180 next i
2190 return
2200 rem
2210 rem next ident
2220 rem tok$ needs to have the variable
2230 gosub 3390
2240 forndx = n
2250 forvar(forndx) = forvar(forndx) + 1
2260 vars(forndx) = forvar(forndx)
2270 if forvar(forndx) > forlimit(forndx) then gosub 3760: return
2280 curline = forline(forndx)
2290 textp   = forpos(forndx)
2300 gosub 3650
2310 return
2320 rem
2330 rem "print" [[#num "," ] expr { "," [#num ","] expr }] [","] {":" stmt} eol: expr can also be a literal string
2340 printnl = true
2350 if tok$ = ":" or tok$ = "" or tok$ = "else" then goto 2600
2360 printnl = true
2370 printwidth = 0
2380 if tok$ <> "#" then goto 2450
2390 num = 0: gosub 3760
2400 if num <= 0 then print "("; curline; ") "; "Expecting a print width, found:"; tok$: errors = true: return
2410 printwidth = num
2420 gosub 3760
2430 if tok$ <> "," then print "("; curline; ") "; "Print: Expecting a ',', found:"; tok$: errors = true: return
2440 gosub 3760
2450 if toktype$ <> "string" then goto 2490
2460 junk$ = mid$(tok$, 2)
2470 gosub 3760
2480 goto 2510
2490 gosub 2900
2500 junk$ = str$(retval)
2510 printwidth = printwidth - len(junk$)
2520 if printwidth > 0 then goto 2550
2530 print junk$;
2540 goto 2560
2550 print space$(printwidth); junk$;
2560 if tok$ <> "," and tok$ <> ";" then goto 2600
2570 gosub 3760
2580 printnl = false
2590 goto 2350
2600 if printnl then print
2610 return
2620 rem
2630 rem return from a subroutine
2640 curline = gstackln(gsp)
2650 textp   = gstacktp(gsp)
2660 gsp = gsp - 1
2670 gosub 3650
2680 return
2690 rem
2700 rem run statement
2710 gosub 1290
2720 num = 1: gosub 3610
2730 return
2740 rem
2750 rem is it a valid line number?
2760 if num < 1 or num > maxlines then print "Line "; num; " out of range": errors = true
2770 return
2780 rem
2790 rem paren expression: external entry point
2800 nsp = 0: retval = 0: prec = 0
2810 rem
2820 rem paren expression: internal entry point
2830 if tok$ <> "(" then print "("; curline; ") "; "Paren Expr: Expecting '(', found:"; tok$: errors = true: return
2840 gosub 3760:     rem skip the "("
2850 prec = 0: gosub 2930:  rem get the expression
2860 if tok$ <> ")" then print "("; curline; ") "; "Paren Expr: Expecting ')', found:"; tok$: errors = true: return
2870 gosub 3760:     rem skip closing ")"
2880 return
2890 rem
2900 rem expression processing - external entry point
2910 nsp = 0: retval = 0: prec = 0: minprec = 0
2920 rem
2930 rem expression processing - internal entry point
2940 gosub 3430
2950 n = 0: minprec = prec
2960 rem handle numeric operands - numbers and unary operators
2970 if tok$ = "-"   then gosub 3760: prec = 7: gosub 2930: n = -retval:    goto 3110
2980 if tok$ = "+"   then gosub 3760: prec = 7: gosub 2930: n =  retval:    goto 3110
2990 if tok$ = "not" then gosub 3760: prec = 3: gosub 2930: n = not retval: goto 3110
3000 if tok$ = "("   then gosub 2820:                     n =  retval:    goto 3110
3010 rem built-in functions: rnd(e), abs(e), sgn(e), asc(var)
3020 if tok$ = "abs" then gosub 3760:  gosub 2820: n = abs(retval):    goto 3110
3030 if tok$ = "asc" then gosub 3760:  gosub 3310:     n = retval:         goto 3110
3040 if tok$ = "rnd" or tok$ = "irnd" then gosub 3760:  gosub 2820: n = int(rnd(0) * retval) + 1: goto 3110
3050 if tok$ = "sgn" then gosub 3760:  gosub 2820: n = sgn(retval):    goto 3110
3060 rem array: @(expr), variable, or number
3070 if tok$ = "@" then gosub 3760: gosub 2820: n = atarry(retval):   goto 3110
3080 if toktype$ = "ident" then gosub 3390: n = vars(n): gosub 3760: goto 3110
3090 if toktype$ = "number" then n = num: gosub 3760:                       goto 3110
3100 print "("; curline; ") "; "syntax error: expecting an operand, found: ", tok$: errors = true: goto 3280
3110 rem while binary operator and precedence of tok$ >= minprec
3120 if errors then goto 3280
3130 if minprec <= 1 and tok$ = "or"  then gosub 3760: prec = 2: gosub 2930: n = n or retval:      goto 3110
3140 if minprec <= 2 and tok$ = "and" then gosub 3760: prec = 3: gosub 2930: n = n and retval:     goto 3110
3150 if minprec <= 4 and tok$ = "="   then gosub 3760: prec = 5: gosub 2930: n = abs(n =  retval): goto 3110
3160 if minprec <= 4 and tok$ = "<"   then gosub 3760: prec = 5: gosub 2930: n = abs(n <  retval): goto 3110
3170 if minprec <= 4 and tok$ = ">"   then gosub 3760: prec = 5: gosub 2930: n = abs(n >  retval): goto 3110
3180 if minprec <= 4 and tok$ = "<>"  then gosub 3760: prec = 5: gosub 2930: n = abs(n <> retval): goto 3110
3190 if minprec <= 4 and tok$ = "<="  then gosub 3760: prec = 5: gosub 2930: n = abs(n <= retval): goto 3110
3200 if minprec <= 4 and tok$ = ">="  then gosub 3760: prec = 5: gosub 2930: n = abs(n >= retval): goto 3110
3210 if minprec <= 5 and tok$ = "+"   then gosub 3760: prec = 6: gosub 2930: n = n + retval:       goto 3110
3220 if minprec <= 5 and tok$ = "-"   then gosub 3760: prec = 6: gosub 2930: n = n - retval:       goto 3110
3230 if minprec <= 6 and tok$ = "*"   then gosub 3760: prec = 7: gosub 2930: n = n * retval:       goto 3110
3240 if minprec <= 6 and tok$ = "/"   then gosub 3760: prec = 7: gosub 2930: n = n \ retval:       goto 3110:  rem use integer division, 'cause QB64, even with defint a-z, 3/2!=2!
3250 if minprec <= 6 and tok$ = "\"   then gosub 3760: prec = 7: gosub 2930: n = n \ retval:       goto 3110
3260 if minprec <= 6 and tok$ = "mod" then gosub 3760: prec = 7: gosub 2930: n = n mod retval:     goto 3110
3270 if minprec <= 8 and tok$ = "^"   then gosub 3760: prec = 9: gosub 2930: n = n ^ retval:       goto 3110
3280 retval = n: gosub 3490
3290 return
3300 rem
3310 rem asc("x")
3320 if tok$ <> "(" then print "("; curline; ") "; "Asc: Expecting '(', found:"; tok$: errors = true: return
3330 gosub 3760
3340 retval = asc(mid$(tok$, 2, 1)): gosub 3760
3350 if tok$ <> ")" then print "("; curline; ") "; "Asc: Expecting ')', found:"; tok$: errors = true: return
3360 gosub 3760
3370 return
3380 rem
3390 rem get index into vars store for variable
3400 if toktype$ = "ident" then n = asc(left$(tok$, 1)) - asc("a"): return
3410 print "("; curline; ") "; "Expecting a variable": errors = true: return
3420 rem
3430 rem for expressions: save the current context
3440 nsp = nsp + 1
3450 nstack(nsp) = n
3460 pstack(nsp) = minprec
3470 return
3480 rem
3490 rem for expressions: restore the current context
3500 n       = nstack(nsp)
3510 minprec = pstack(nsp)
3520 nsp = nsp - 1
3530 return
3540 rem
3550 rem for gosub: save the line and column
3560 gsp = gsp + 1
3570 gstackln(gsp) = curline
3580 gstacktp(gsp) = textp
3590 return
3600 rem
3610 rem lexical analyzer
3620 curline = num
3630 textp = 1
3640 rem
3650 rem called with preset line and column
3660 thelin$ = pgm$(curline)
3670 thech$ = " "
3680 gosub 3760
3690 return
3700 rem
3710 rem skip to the end of the line
3720 tok$ = "": toktype$ = ""
3730 textp = len(thelin$) + 1
3740 return
3750 rem
3760 rem get the next token
3770 tok$ = "": toktype$ = ""
3780 if thech$ = "" then return
3790 if thech$ <= " " then gosub 4190: goto 3760
3800 tok$ = thech$
3810 if (thech$ >= "a" and thech$ <= "z") or (thech$ >= "A" and thech$ <= "Z") then gosub 4120: return
3820 if thech$ >= "0" and thech$ <= "9" then gosub 4050: return
3830 if thech$ = chr$(34) then gosub 3970: return
3840 if thech$ = chr$(39) then gosub 3710: return
3850 toktype$ = "punct"
3860 tok$ = thech$ + mid$(thelin$, textp, 1)
3870 if tok$ = ">=" then gosub 4190: gosub 4190: return
3880 if tok$ = "<=" then gosub 4190: gosub 4190: return
3890 if tok$ = "<>" then gosub 4190: gosub 4190: return
3900 tok$ = thech$
3910 if instr("#()*+,-/:;<=>?@\^", thech$) > 0 then gosub 4190: return
3920 toktype$ = "": print "("; curline; ") "; "What->"; thech$: errors = true:
3930 return
3940 rem
3950 rem leave the " as the beginning of the string, so it won't get confused with other tokens
3960 rem especially in the print routines
3970 rem read a string
3980 toktype$ = "string"
3990 gosub 4190
4000 if thech$ = chr$(34) then gosub 4190: return
4010 if thech$ = "" then print "("; curline; ") "; "String not terminated": errors = true: return
4020 tok$ = tok$ + thech$
4030 goto 3990
4040 rem
4050 rem read a number
4060 toktype$ = "number"
4070 gosub 4190
4080 if thech$ < "0" or thech$ > "9" then num = val(tok$): return
4090 tok$ = tok$ + thech$
4100 goto 4070
4110 rem
4120 rem read an identifier
4130 tok$ = "": toktype$ = "ident"
4140 if thech$ >= "A" and thech$ <= "Z" then thech$ = chr$(asc(thech$) + 32)
4150 if thech$ >= "a" and thech$ <= "z" then tok$ = tok$ + thech$: gosub 4190: goto 4140
4160 if tok$ = "rem" then gosub 3710
4170 return
4180 rem
4190 rem get the next char from the current line
4200 if textp > len(thelin$) then thech$ = "": return
4210 thech$ = mid$(thelin$, textp, 1)
4220 textp = textp + 1
4230 return
