1 'Tiny Basic interpreter.  Runs under GW-Basic. Can play Star Trek
2 'By Ed Davis
3 maxlines = 1000: atmax = 500: maxvar = 26: true = -1: false = 0
4 dim pgm$(maxlines) ' (0) used for work line; programs stored here
5 dim vars(maxvar)   ' variables a-z
6 dim atarry(atmax)  ' the @ array
7 dim nstack(30)     ' stack for results in expressions
8 dim pstack(30)     ' stack for results in expressions
9 dim gstackln(200)  ' gosub return line stack
10 dim gstacktp(200)  ' gosub return textp stack
11 dim forvar(maxvar)
12 dim forlimit(maxvar)
13 dim forline(maxvar)
14 dim forpos(maxvar)
15 'dim atndx      'index into @ array
16 'dim curline    'number of the current line
17 'dim forndx     'temp, used in forstmt and nextstmt
18 'dim gsp        'gosub stack(s) index
19 'dim i          '
20 'dim n          'used in expression parser and a few other places
21 'dim nsp        'stack pointer for nstack, opstack
22 'dim num        'set to current number by scanner
23 'dim printnl    'used by printstmt
24 'dim printwidth 'used by printstmt
25 'dim retval     'only used by expression parser
26 'dim textp      'column pointer in current line
27 'dim tracing
28 'dim var        'used in inputstmt and assign
29 '
30 'dim thech$     'only used in scanner
31 'dim filename$  'used in load
32 'dim tmp$       'used in inputstmt and printstmt
33 'dim thelin$    'text of the current line
34 'dim tok$       'returned by scanner
35 'dim toktype$   '"number", "ident", "punct", "string"
36 gsp = 0
37 gosub 82
38 ' main loop
39 errors = false
40 line input "gw> ", pgm$(0)
41 if pgm$(0) = "" then goto 38
42 num = 0: gosub 315
43 ' if line starts with a number, store it, otherwise run it
44 if toktype$ <> "number" then gosub 48: goto 38
45 gosub 239
46 if not errors then pgm$(num) = mid$(pgm$(0), textp)
47 goto 38
48 ' main command processor
49 if errors or curline > maxlines then return
50 if tok$ <> "" then goto 54
51 if curline = 0 or curline >= maxlines then return
52 num = curline + 1: gosub 315
53 goto 48
54 if tracing and left$(tok$, 1) <> ":" then print curline; tok$; thech$; mid$(thelin$, textp)
55 if tok$ = "bye" or tok$ = "quit" then end
56 if tok$ = "end" or tok$ = "stop" then     return
57 if tok$ = "clear"   then gosub 117: return
58 if tok$ = "help"    then gosub 82:   return
59 if tok$ = "list"    then gosub 163:  return
60 if tok$ = "load" or tok$ = "old" then gosub 327: gosub 169: return
61 if tok$ = "new"     then gosub 191:   return
62 if tok$ = "run"     then gosub 235: goto 48
63 if tok$ = "tron"    then gosub 327: tracing = true: goto 48
64 if tok$ = "troff"   then gosub 327: tracing = false: goto 48
65 if tok$ = "cls"     then gosub 327: cls: goto 48
66 if tok$ = "for"     then gosub 327: gosub 126:   goto 48
67 if tok$ = "gosub"   then gosub 327: gosub 138: goto 48
68 if tok$ = "goto"    then gosub 327: gosub 142:  goto 48
69 if tok$ = "if"      then gosub 327: gosub 147:    goto 48
70 if tok$ = "input"   then gosub 327: gosub 153: goto 48
71 if tok$ = "next"    then gosub 327: gosub 197:  goto 48
72 if tok$ = "print" or tok$ = "?" then gosub 327: gosub 208: goto 48
73 if tok$ = "return"  then gosub 327: gosub 229:goto 48
74 if tok$ = ":"       then gosub 327: goto 48
75 if tok$ = "let"     then gosub 327 ' fall-through
76 if tok$ = "@"       then gosub 327: gosub 108:   goto 48
77 if toktype$ = "ident" then gosub 98:  goto 48
78 if tok$ = ""        then                  goto 48
79 print "Unknown token '"; tok$; "' at line:"; curline; " Col:"; textp; " : "; thelin$
80 return
81 ' statements
82 ' show the help screen
83 print "+---------------------- Tiny Basic Help (GW-Basic)--------------------+"
84 print "| bye, clear, cls, end, help, list, load, new, run, tron, troff, stop |"
85 print "| for <var> = <expr1> to <expr2> ... next <var>                       |"
86 print "| gosub <expr> ... return                                             |"
87 print "| goto <expr>                                                         |"
88 print "| if <expr> then <statement>                                          |"
89 print "| input [prompt,] <var>                                               |"
90 print "| [let] <var>=<expr>                                                  |"
91 print "| print <expr|string>[,<expr|string>][;]                              |"
92 print "| rem <anystring> or '<anystring>                                     |"
93 print "| Operators: + - * / < <= > >= <> =                                   |"
94 print "| Integer variables a..z, and array @(expr)                           |"
95 print "| Functions: abs(expr), asc(ch), rnd(expr), sgn(expr)                 |"
96 print "+---------------------------------------------------------------------+"
97 return
98 ' assignment: ident = expression - side effect: var has variable index
99 gosub 297
100 var = n
101 gosub 327
102 if tok$ <> "=" then print "("; curline; ") "; "Assign: Expecting '=', found:"; tok$: errors = true: return
103 gosub 327
104 gosub 251
105 vars(var) = retval
106 if tracing then print "*** "; chr$(var + asc("a")); " = "; retval
107 return
108 ' array assignment: @(expr) = expr
109 gosub 242
110 atndx = retval
111 if tok$ <> "=" then print "("; curline; ") "; "Array Assign: Expecting '=', found:"; tok$: errors = true: return
112 gosub 327     ' skip the "="
113 gosub 251
114 atarry(atndx) = retval
115 if tracing then print "*** @("; atndx; ") = "; retval
116 return
117 ' clear statement
118 for i = 1 to maxvar
119 vars(i) = 0
120 next i
121 for i = 0 to atmax
122 atarry(i) = 0
123 next i
124 gsp = 0
125 return
126 ' for i = expr to expr
127 gosub 98
128 ' vars(var) has the value; var has the number value of the variable in 0..25
129 forndx = var
130 forvar(forndx) = vars(var)
131 if tok$ = "to" then gosub 327 else print "("; curline; ") "; "For: Expecting 'to', found:"; tok$: errors = true: return
132 gosub 251 ' result in retval
133 forlimit(forndx) = retval
134 ' need to store iter, limit, line, and col
135 forline(forndx) = curline
136 if tok$ = "" then forpos(forndx) = textp else forpos(forndx) = textp - 2
137 return
138 ' gosub expr
139 gosub 310
140 gosub 142
141 return
142 ' goto expr
143 gosub 251: num = retval
144 gosub 239
145 gosub 315
146 return
147 ' if expr [then] statment
148 gosub 251
149 if retval = 0 then gosub 323: return
150 if tok$ = "then" then gosub 327
151 if toktype$ = "number" then gosub 142
152 return
153 ' "input" [string ","] var
154 if toktype$ <> "string" then print "? ": goto 159
155 print mid$(tok$, 2);
156 gosub 327
157 if tok$ <> "," then print "("; curline; ") "; "Input: Expecting ',', found:"; tok$: errors = true: return
158 gosub 327
159 gosub 297: var = n: gosub 327
160 line input tmp$: if tmp$ = "" then tmp$ = "0"
161 if left$(tmp$, 1) >= "0" and left$(tmp$, 1) <= "9" then vars(var) = val(tmp$) else vars(var) = asc(tmp$)
162 return
163 ' list the code
164 for i = 1 to maxlines
165 if pgm$(i) <> "" then print i; " "; pgm$(i)
166 next i
167 print
168 return
169 ' load statement
170 gosub 191
171 if toktype$ <> "string" then goto 174
172 filename$ = mid$(tok$, 2)
173 goto 176
174 line input "Program?", filename$
175 if filename$ = "" then return
176 if instr(filename$, ".") = 0 then filename$ = filename$ + ".bas"
177 open filename$ for input as #1
178 n = 0
179 if eof(1) then goto 186
180 line input #1, pgm$(0)
181 num = 0: gosub 315
182 if toktype$ = "number" and num > 0 and num <= maxlines then n = num: goto 184
183 n = n + 1: textp = 1
184 pgm$(n) = mid$(pgm$(0), textp)
185 goto 179
186 close #1
187 filename$ = ""
188 curline = 0
189 tok$ = ""
190 return
191 ' new statement
192 gosub 117
193 for i = 1 to maxlines
194 pgm$(i) = ""
195 next i
196 return
197 ' next ident
198 ' tok$ needs to have the variable
199 gosub 297
200 forndx = n
201 forvar(forndx) = forvar(forndx) + 1
202 vars(forndx) = forvar(forndx)
203 if forvar(forndx) > forlimit(forndx) then gosub 327: return
204 curline = forline(forndx)
205 textp   = forpos(forndx)
206 gosub 318
207 return
208 ' "print" [[#num "," ] expr { "," [#num ","] expr }] [","] {":" stmt} eol: expr can also be a literal string
209 printnl = true
210 if tok$ = ":" or tok$ = "" or tok$ = "else" then goto 227
211 printnl = true
212 printwidth = 0
213 if tok$ <> "#" then goto 220
214 num = 0: gosub 327
215 if num <= 0 then print "("; curline; ") "; "Expecting a print width, found:"; tok$: errors = true: return
216 printwidth = num
217 gosub 327
218 if tok$ <> "," then print "("; curline; ") "; "Print: Expecting a ',', found:"; tok$: errors = true: return
219 gosub 327
220 if toktype$ = "string" then junk$ = mid$(tok$, 2): gosub 327: else gosub 251: junk$ = str$(retval)
221 printwidth = printwidth - len(junk$)
222 if printwidth <= 0 then print junk$; else print space$(printwidth); junk$;
223 if tok$ <> "," and tok$ <> ";" then goto 227
224 gosub 327
225 printnl = false
226 goto 210
227 if printnl then print
228 return
229 ' return from a subroutine
230 curline = gstackln(gsp)
231 textp   = gstacktp(gsp)
232 gsp = gsp - 1
233 gosub 318
234 return
235 ' run statement
236 gosub 117
237 num = 1: gosub 315
238 return
239 ' is it a valid line number?
240 if num < 1 or num > maxlines then print "Line "; num; " out of range": errors = true
241 return
242 ' paren expression: external entry point
243 nsp = 0: retval = 0: prec = 0
244 ' paren expression: internal entry point
245 if tok$ <> "(" then print "("; curline; ") "; "Paren Expr: Expecting '(', found:"; tok$: errors = true: return
246 gosub 327     ' skip the "("
247 prec = 0: gosub 253  ' get the expression
248 if tok$ <> ")" then print "("; curline; ") "; "Paren Expr: Expecting ')', found:"; tok$: errors = true: return
249 gosub 327     ' skip closing ")"
250 return
251 ' expression processing - external entry point
252 nsp = 0: retval = 0: prec = 0
253 ' expression processing - internal entry point
254 gosub 300
255 n = 0: minprec = prec
256 ' handle numeric operands - numbers and unary operators
257 if tok$ = "-"   then gosub 327: prec = 7: gosub 253: n = -retval:    goto 271
258 if tok$ = "+"   then gosub 327: prec = 7: gosub 253: n =  retval:    goto 271
259 if tok$ = "not" then gosub 327: prec = 3: gosub 253: n = not retval: goto 271
260 if tok$ = "("   then gosub 244:                     n =  retval:    goto 271
261 ' built-in functions: rnd(e), abs(e), sgn(e), asc(var)
262 if tok$ = "abs" then gosub 327:  gosub 244: n = abs(retval):    goto 271
263 if tok$ = "asc" then gosub 327:  gosub 290:     n = retval:         goto 271
264 if tok$ = "rnd" or tok$ = "irnd" then gosub 327:  gosub 244: n = int(rnd * retval) + 1: goto 271
265 if tok$ = "sgn" then gosub 327:  gosub 244: n = sgn(retval):    goto 271
266 ' array: @(expr), variable, or number
267 if tok$ = "@" then gosub 327: gosub 244: n = atarry(retval):   goto 271
268 if toktype$ = "ident" then gosub 297: n = vars(n): gosub 327: goto 271
269 if toktype$ = "number" then n = num: gosub 327:                       goto 271
270 print "("; curline; ") "; "syntax error: expecting an operand, found: ", tok$: errors = true: goto 288
271 ' while binary operator and precedence of tok$ >= minprec
272 if errors then goto 288
273 if minprec <= 1 and tok$ = "or"  then gosub 327: prec = 2: gosub 253: n = n or retval:      goto 271
274 if minprec <= 2 and tok$ = "and" then gosub 327: prec = 3: gosub 253: n = n and retval:     goto 271
275 if minprec <= 4 and tok$ = "="   then gosub 327: prec = 5: gosub 253: n = abs(n =  retval): goto 271
276 if minprec <= 4 and tok$ = "<"   then gosub 327: prec = 5: gosub 253: n = abs(n <  retval): goto 271
277 if minprec <= 4 and tok$ = ">"   then gosub 327: prec = 5: gosub 253: n = abs(n >  retval): goto 271
278 if minprec <= 4 and tok$ = "<>"  then gosub 327: prec = 5: gosub 253: n = abs(n <> retval): goto 271
279 if minprec <= 4 and tok$ = "<="  then gosub 327: prec = 5: gosub 253: n = abs(n <= retval): goto 271
280 if minprec <= 4 and tok$ = ">="  then gosub 327: prec = 5: gosub 253: n = abs(n >= retval): goto 271
281 if minprec <= 5 and tok$ = "+"   then gosub 327: prec = 6: gosub 253: n = n + retval:       goto 271
282 if minprec <= 5 and tok$ = "-"   then gosub 327: prec = 6: gosub 253: n = n - retval:       goto 271
283 if minprec <= 6 and tok$ = "*"   then gosub 327: prec = 7: gosub 253: n = n * retval:       goto 271
284 if minprec <= 6 and tok$ = "/"   then gosub 327: prec = 7: gosub 253: n = n \ retval:       goto 271  ' use integer division, 'cause QB64, even with defint a-z, 3/2!=2!
285 if minprec <= 6 and tok$ = "\"   then gosub 327: prec = 7: gosub 253: n = n \ retval:       goto 271
286 if minprec <= 6 and tok$ = "mod" then gosub 327: prec = 7: gosub 253: n = n mod retval:     goto 271
287 if minprec <= 8 and tok$ = "^"   then gosub 327: prec = 9: gosub 253: n = n ^ retval:       goto 271
288 retval = n: gosub 305
289 return
290 ' asc("x")
291 if tok$ <> "(" then print "("; curline; ") "; "Asc: Expecting '(', found:"; tok$: errors = true: return
292 gosub 327
293 retval = asc(mid$(tok$, 2, 1)): gosub 327
294 if tok$ <> ")" then print "("; curline; ") "; "Asc: Expecting ')', found:"; tok$: errors = true: return
295 gosub 327
296 return
297 ' get index into vars store for variable
298 if toktype$ = "ident" then n = asc(left$(tok$, 1)) - asc("a"): return
299 print "("; curline; ") "; "Expecting a variable": errors = true: return
300 ' for expressions: save the current context
301 nsp = nsp + 1
302 nstack(nsp) = n
303 pstack(nsp) = minprec
304 return
305 ' for expressions: restore the current context
306 n       = nstack(nsp)
307 minprec = pstack(nsp)
308 nsp = nsp - 1
309 return
310 ' for gosub: save the line and column
311 gsp = gsp + 1
312 gstackln(gsp) = curline
313 gstacktp(gsp) = textp
314 return
315 ' lexical analyzer
316 curline = num
317 textp = 1
318 ' called with preset line and column
319 thelin$ = pgm$(curline)
320 thech$ = " "
321 gosub 327
322 return
323 ' skip to the end of the line
324 if thech$ <> "" then gosub 366: goto 323
325 tok$ = "": toktype$ = ""
326 return
327 ' get the next token
328 tok$ = "": toktype$ = ""
329 if thech$ = "" then return
330 if thech$ <= " " then gosub 366: goto 327
331 tok$ = thech$
332 if (thech$ >= "a" and thech$ <= "z") or (thech$ >= "A" and thech$ <= "Z") then gosub 360: return
333 if thech$ >= "0" and thech$ <= "9" then gosub 354: return
334 if thech$ = chr$(34) then gosub 347: return
335 if thech$ = chr$(39) then gosub 323: return
336 toktype$ = "punct"
337 tok$ = thech$ + mid$(thelin$, textp, 1)
338 if tok$ = ">=" then gosub 366: gosub 366: return
339 if tok$ = "<=" then gosub 366: gosub 366: return
340 if tok$ = "<>" then gosub 366: gosub 366: return
341 tok$ = thech$
342 if instr("#()*+,-/:;<=>?@\^", thech$) > 0 then gosub 366: return
343 toktype$ = "": print "("; curline; ") "; "What->"; thech$: errors = true:
344 return
345 ' leave the " as the beginning of the string, so it won't get confused with other tokens
346 ' especially in the print routines
347 ' read a string
348 toktype$ = "string"
349 gosub 366
350 if thech$ = chr$(34) then gosub 366: return
351 if thech$ = "" then print "("; curline; ") "; "String not terminated": errors = true: return
352 tok$ = tok$ + thech$
353 goto 349
354 ' read a number
355 toktype$ = "number"
356 gosub 366
357 if thech$ < "0" or thech$ > "9" then num = val(tok$): return
358 tok$ = tok$ + thech$
359 goto 356
360 ' read an identifier
361 tok$ = "": toktype$ = "ident"
362 if thech$ >= "A" and thech$ <= "Z" then thech$ = chr$(asc(thech$) + 32)
363 if thech$ >= "a" and thech$ <= "z" then tok$ = tok$ + thech$: gosub 366: goto 362
364 if tok$ = "rem" then gosub 323
365 return
366 ' get the next char from the current line
367 if textp > len(thelin$) then thech$ = "": return
368 thech$ = mid$(thelin$, textp, 1)
369 textp = textp + 1
370 return
