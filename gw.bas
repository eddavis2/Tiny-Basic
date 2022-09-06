1 'Tiny Basic interpreter.  Plays Star Trek
2 'By Ed Davis
6 maxlines = 1000: atmax = 500: maxvar = 26: true = -1: false = 0
7 dim pgm$(maxlines) ' (0) used for work line; programs stored here
8 dim vars(maxvar)   ' variables a-z
9 dim atarry(atmax)  ' the @ array
10 dim nstack(30)     ' stack for results in expressions
11 dim pstack(30)     ' stack for results in expressions
12 dim gstackln(200)  ' gosub return line stack
13 dim gstacktp(200)  ' gosub return textp stack
14 dim forvar(maxvar)
15 dim forlimit(maxvar)
16 dim forline(maxvar)
17 dim forpos(maxvar)
18 'dim atndx      'index into @ array
19 'dim curline    'number of the current line
20 'dim forndx     'temp, used in forstmt and nextstmt
21 'dim gsp        'gosub stack(s) index
22 'dim i          '
23 'dim n          'used in expression parser and a few other places
24 'dim nsp        'stack pointer for nstack, opstack
25 'dim num        'set to current number by scanner
26 'dim printnl    'used by printstmt
27 'dim printwidth 'used by printstmt
28 'dim retval     'only used by expression parser
29 'dim textp      'column pointer in current line
30 'dim tracing
31 'dim var        'used in inputstmt and assign
32 '
33 'dim thech$     'only used in scanner
34 'dim filename$  'used in load
35 'dim tmp$       'used in inputstmt and printstmt
36 'dim thelin$    'text of the current line
37 'dim tok$       'returned by scanner
38 'dim toktype$   '"number", "ident", "punct", "string"
39 gsp = 0
40 gosub 85
41 ' main loop
42 errors = false
43 line input "$ ", pgm$(0)
44 if pgm$(0) = "" then goto 41
45 num = 0: gosub 318
46 ' if line starts with a number, store it, otherwise run it
47 if toktype$ <> "number" then gosub 51: goto 41
48 gosub 242
49 if not errors then pgm$(num) = mid$(pgm$(0), textp)
50 goto 41
51 ' main command processor
52 if errors or curline > maxlines then return
53 if tok$ <> "" then goto 57
54 if curline = 0 or curline >= maxlines then return
55 num = curline + 1: gosub 318
56 goto 51
57 if tracing and left$(tok$, 1) <> ":" then print curline; tok$; thech$; mid$(thelin$, textp)
58 if tok$ = "bye" or tok$ = "quit" then end
59 if tok$ = "end" or tok$ = "stop" then return
60 if tok$ = "clear"   then gosub 101: return
61 if tok$ = "help"    then gosub 85:  return
62 if tok$ = "list"    then gosub 142: return
63 if tok$ = "load" or tok$ = "old" then gosub 330: gosub 165: return
64 if tok$ = "new"     then gosub 148: return
65 if tok$ = "run"     then gosub 214: goto 51
66 if tok$ = "tron"    then gosub 330: tracing = true: goto 51
67 if tok$ = "troff"   then gosub 330: tracing = false: goto 51
68 if tok$ = "cls"     then gosub 330: cls: goto 51
69 if tok$ = "for"     then gosub 330: gosub 110: goto 51
70 if tok$ = "gosub"   then gosub 330: gosub 122: goto 51
71 if tok$ = "goto"    then gosub 330: gosub 237: goto 51
72 if tok$ = "if"      then gosub 330: gosub 126: goto 51
73 if tok$ = "input"   then gosub 330: gosub 132: goto 51
74 if tok$ = "next"    then gosub 330: gosub 154: goto 51
75 if tok$ = "print" or tok$ = "?" then gosub 330: gosub 187: goto 51
76 if tok$ = "return"  then gosub 330: gosub 208: goto 51
77 if tok$ = ":"       then gosub 330: goto 51
78 if tok$ = "let"     then gosub 330 ' fall-through
79 if tok$ = "@"       then gosub 330: gosub 218: goto 51
80 if toktype$ = "ident" then gosub 227:  goto 51
81 if tok$ = ""        then                  goto 51
82 print "Unknown token '"; tok$; "' at line:"; curline; " Col:"; textp; " : "; thelin$
83 return
84 ' statements
85 ' show the help screen
86 print "+---------------------- Tiny Basic Help (GWBASIC)---------------------+"
87 print "| bye, clear, cls, end, help, list, load, new, run, tron, troff, stop |"
88 print "| for <var> = <expr1> to <expr2> ... next <var>                       |"
89 print "| gosub <expr> ... return                                             |"
90 print "| goto <expr>                                                         |"
91 print "| if <expr> then <statement>                                          |"
92 print "| input [prompt,] <var>                                               |"
93 print "| [let] <var>=<expr>                                                  |"
94 print "| print <expr|string>[,<expr|string>][;]                              |"
95 print "| rem <anystring> or '<anystring>                                     |"
96 print "| Operators: + - * / < <= > >= <> =                                   |"
97 print "| Integer variables a..z, and array @(expr)                           |"
98 print "| Functions: abs(expr), asc(ch), rnd(expr), sgn(expr)                 |"
99 print "+---------------------------------------------------------------------+"
100 return
101 ' clear statement
102 for i = 1 to maxvar
103 vars(i) = 0
104 next i
105 for i = 0 to atmax
106 atarry(i) = 0
107 next i
108 gsp = 0
109 return
110 ' for i = expr to expr
111 gosub 227
112 ' vars(var) has the value; var has the number value of the variable in 0..25
113 forndx = var
114 forvar(forndx) = vars(var)
115 if tok$ = "to" then gosub 330 else print "("; curline; ") "; "For: Expecting 'to', found:"; tok$: errors = true: return
116 gosub 254 ' result in retval
117 forlimit(forndx) = retval
118 ' need to store iter, limit, line, and col
119 forline(forndx) = curline
120 if tok$ = "" then forpos(forndx) = textp else forpos(forndx) = textp - 2
121 return
122 ' gosub expr
123 gosub 313
124 gosub 237
125 return
126 ' if expr [then] statment
127 gosub 254
128 if retval = 0 then gosub 326: return
129 if tok$ = "then" then gosub 330
130 if toktype$ = "number" then gosub 237
131 return
132 ' "input" [string ","] var
133 if toktype$ <> "string" then print "? ": goto 138
134 print mid$(tok$, 2);
135 gosub 330
136 if tok$ <> "," then print "("; curline; ") "; "Input: Expecting ',', found:"; tok$: errors = true: return
137 gosub 330
138 gosub 300: var = n: gosub 330
139 line input tmp$: if tmp$ = "" then tmp$ = "0"
140 if left$(tmp$, 1) >= "0" and left$(tmp$, 1) <= "9" then vars(var) = val(tmp$) else vars(var) = asc(tmp$)
141 return
142 ' list the code
143 for i = 1 to maxlines
144 if pgm$(i) <> "" then print i; " "; pgm$(i)
145 next i
146 print
147 return
148 ' new statement
149 gosub 101
150 for i = 1 to maxlines
151 pgm$(i) = ""
152 next i
153 return
154 ' next ident
155 ' tok$ needs to have the variable
156 gosub 300
157 forndx = n
158 forvar(forndx) = forvar(forndx) + 1
159 vars(forndx) = forvar(forndx)
160 if forvar(forndx) > forlimit(forndx) then gosub 330: return
161 curline = forline(forndx)
162 textp   = forpos(forndx)
163 gosub 321
164 return
165 ' load statement
166 gosub 148
167 if toktype$ <> "string" then goto 170
168 filename$ = mid$(tok$, 2)
169 goto 172
170 line input "Program?", filename$
171 if filename$ = "" then return
172 if instr(filename$, ".") = 0 then filename$ = filename$ + ".bas"
173 open filename$ for input as #1
174 n = 0
175 if eof(1) then goto 182
176 line input #1, pgm$(0)
177 num = 0: gosub 318
178 if toktype$ = "number" and num > 0 and num <= maxlines then n = num: goto 180
179 n = n + 1: textp = 1
180 pgm$(n) = mid$(pgm$(0), textp)
181 goto 175
182 close #1
183 filename$ = ""
184 curline = 0
185 tok$ = ""
186 return
187 ' "print" [[#num "," ] expr { "," [#num ","] expr }] [","] {":" stmt} eol: expr can also be a literal string
188 printnl = true
189 if tok$ = ":" or tok$ = "" or tok$ = "else" then goto 206
190 printnl = true
191 printwidth = 0
192 if tok$ <> "#" then goto 199
193 num = 0: gosub 330
194 if num <= 0 then print "("; curline; ") "; "Expecting a print width, found:"; tok$: errors = true: return
195 printwidth = num
196 gosub 330
197 if tok$ <> "," then print "("; curline; ") "; "Print: Expecting a ',', found:"; tok$: errors = true: return
198 gosub 330
199 if toktype$ = "string" then junk$ = mid$(tok$, 2): gosub 330: else gosub 254: junk$ = str$(retval)
200 printwidth = printwidth - len(junk$)
201 if printwidth <= 0 then print junk$; else print space$(printwidth); junk$;
202 if tok$ <> "," and tok$ <> ";" then goto 206
203 gosub 330
204 printnl = false
205 goto 189
206 if printnl then print
207 return
208 ' return from a subroutine
209 curline = gstackln(gsp)
210 textp   = gstacktp(gsp)
211 gsp = gsp - 1
212 gosub 321
213 return
214 ' run statement
215 gosub 101
216 num = 1: gosub 318
217 return
218 ' array assignment: @(expr) = expr
219 gosub 245
220 atndx = retval
221 if tok$ <> "=" then print "("; curline; ") "; "Array Assign: Expecting '=', found:"; tok$: errors = true: return
222 gosub 330     ' skip the "="
223 gosub 254
224 atarry(atndx) = retval
225 if tracing then print "*** @("; atndx; ") = "; retval
226 return
227 ' assignment: ident = expression - side effect: var has variable index
228 gosub 300
229 var = n
230 gosub 330
231 if tok$ <> "=" then print "("; curline; ") "; "Assign: Expecting '=', found:"; tok$: errors = true: return
232 gosub 330
233 gosub 254
234 vars(var) = retval
235 if tracing then print "*** "; chr$(var + asc("a")); " = "; retval
236 return
237 ' goto expr
238 gosub 254: num = retval
239 gosub 242
240 gosub 318
241 return
242 ' is it a valid line number?
243 if num < 1 or num > maxlines then print "Line "; num; " out of range": errors = true
244 return
245 ' paren expression: external entry point
246 nsp = 0: retval = 0: prec = 0
247 ' paren expression: internal entry point
248 if tok$ <> "(" then print "("; curline; ") "; "Paren Expr: Expecting '(', found:"; tok$: errors = true: return
249 gosub 330     ' skip the "("
250 prec = 0: gosub 256  ' get the expression
251 if tok$ <> ")" then print "("; curline; ") "; "Paren Expr: Expecting ')', found:"; tok$: errors = true: return
252 gosub 330     ' skip closing ")"
253 return
254 ' expression processing - external entry point
255 nsp = 0: retval = 0: prec = 0
256 ' expression processing - internal entry point
257 gosub 303
258 n = 0: minprec = prec
259 ' handle numeric operands - numbers and unary operators
260 if tok$ = "-"   then gosub 330: prec = 7: gosub 256: n = -retval:    goto 275
261 if tok$ = "+"   then gosub 330: prec = 7: gosub 256: n =  retval:    goto 275
262 if tok$ = "not" then gosub 330: prec = 3: gosub 256: n = not retval: goto 275
263 if tok$ = "("   then gosub 247:                     n =  retval:    goto 275
264 ' built-in functions: rnd(e), abs(e), sgn(e), asc(var)
265 if tok$ = "rnd" then gosub 330:  gosub 247: n = int(rnd * retval) + 1: goto 275
266 if tok$ = "irnd" then gosub 330: gosub 247: n = int(rnd * retval) + 1: goto 275
267 if tok$ = "abs" then gosub 330:  gosub 247: n = abs(retval):           goto 275
268 if tok$ = "sgn" then gosub 330:  gosub 247: n = sgn(retval):           goto 275
269 if tok$ = "asc" then gosub 330:  gosub 293: n = retval:                goto 275
270 ' array: @(expr), variable, or number
271 if tok$ = "@" then gosub 330: gosub 247: n = atarry(retval):   goto 275
272 if toktype$ = "ident" then gosub 300: n = vars(n): gosub 330: goto 275
273 if toktype$ = "number" then n = num: gosub 330:                       goto 275
274 print "("; curline; ") "; "syntax error: expecting an operand, found: ", tok$: errors = true: goto 291
275 ' while binary operator and precedence of tok$ >= minprec
276 if errors then goto 291
277 if minprec <= 1 and tok$ = "or"  then gosub 330: prec = 2: gosub 256: n = n or retval:      goto 275
278 if minprec <= 2 and tok$ = "and" then gosub 330: prec = 3: gosub 256: n = n and retval:     goto 275
279 if minprec <= 4 and tok$ = "="   then gosub 330: prec = 5: gosub 256: n = abs(n =  retval): goto 275
280 if minprec <= 4 and tok$ = "<"   then gosub 330: prec = 5: gosub 256: n = abs(n <  retval): goto 275
281 if minprec <= 4 and tok$ = ">"   then gosub 330: prec = 5: gosub 256: n = abs(n >  retval): goto 275
282 if minprec <= 4 and tok$ = "<>"  then gosub 330: prec = 5: gosub 256: n = abs(n <> retval): goto 275
283 if minprec <= 4 and tok$ = "<="  then gosub 330: prec = 5: gosub 256: n = abs(n <= retval): goto 275
284 if minprec <= 4 and tok$ = ">="  then gosub 330: prec = 5: gosub 256: n = abs(n >= retval): goto 275
285 if minprec <= 5 and tok$ = "+"   then gosub 330: prec = 6: gosub 256: n = n + retval:       goto 275
286 if minprec <= 5 and tok$ = "-"   then gosub 330: prec = 6: gosub 256: n = n - retval:       goto 275
287 if minprec <= 6 and tok$ = "*"   then gosub 330: prec = 7: gosub 256: n = n * retval:       goto 275
288 if minprec <= 6 and tok$ = "/"   then gosub 330: prec = 7: gosub 256: n = n \ retval:       goto 275
289 if minprec <= 6 and tok$ = "\"   then gosub 330: prec = 7: gosub 256: n = n \ retval:       goto 275
290 if minprec <= 8 and tok$ = "^"   then gosub 330: prec = 9: gosub 256: n = n ^ retval:       goto 275
291 retval = n: gosub 308
292 return
293 ' asc("x")
294 if tok$ <> "(" then print "("; curline; ") "; "Asc: Expecting '(', found:"; tok$: errors = true: return
295 gosub 330
296 retval = asc(mid$(tok$, 2, 1)): gosub 330
297 if tok$ <> ")" then print "("; curline; ") "; "Asc: Expecting ')', found:"; tok$: errors = true: return
298 gosub 330
299 return
300 ' get index into vars store for variable
301 if toktype$ = "ident" then n = asc(left$(tok$, 1)) - asc("a"): return
302 print "("; curline; ") "; "Expecting a variable": errors = true: return
303 ' for expressions: save the current context
304 nsp = nsp + 1
305 nstack(nsp) = n
306 pstack(nsp) = minprec
307 return
308 ' for expressions: restore the current context
309 n       = nstack(nsp)
310 minprec = pstack(nsp)
311 nsp = nsp - 1
312 return
313 ' for gosub: save the line and column
314 gsp = gsp + 1
315 gstackln(gsp) = curline
316 gstacktp(gsp) = textp
317 return
318 ' lexical analyzer
319 curline = num
320 textp = 1
321 ' called with preset line and column
322 thelin$ = pgm$(curline)
323 thech$ = " "
324 gosub 330
325 return
326 ' skip to the end of the line
327 if thech$ <> "" then gosub 369: goto 326
328 tok$ = "": toktype$ = ""
329 return
330 ' get the next token
331 tok$ = "": toktype$ = ""
332 if thech$ = "" then return
333 if thech$ <= " " then gosub 369: goto 330
334 tok$ = thech$
335 if (thech$ >= "a" and thech$ <= "z") or (thech$ >= "A" and thech$ <= "Z") then gosub 363: return
336 if thech$ >= "0" and thech$ <= "9" then gosub 357: return
337 if thech$ = chr$(34) then gosub 350: return
338 if thech$ = chr$(39) then gosub 326: return
339 toktype$ = "punct"
340 tok$ = thech$ + mid$(thelin$, textp, 1)
341 if tok$ = ">=" then gosub 369: gosub 369: return
342 if tok$ = "<=" then gosub 369: gosub 369: return
343 if tok$ = "<>" then gosub 369: gosub 369: return
344 tok$ = thech$
345 if instr("#()*+,-/:;<=>?@\^", thech$) > 0 then gosub 369: return
346 toktype$ = "": print "("; curline; ") "; "What->"; thech$: errors = true:
347 return
348 ' leave the " as the beginning of the string, so it won't get confused with other tokens
349 ' especially in the print routines
350 ' read a string
351 toktype$ = "string"
352 gosub 369
353 if thech$ = chr$(34) then gosub 369: return
354 if thech$ = "" then print "("; curline; ") "; "String not terminated": errors = true: return
355 tok$ = tok$ + thech$
356 goto 352
357 ' read a number
358 toktype$ = "number"
359 gosub 369
360 if thech$ < "0" or thech$ > "9" then num = val(tok$): return
361 tok$ = tok$ + thech$
362 goto 359
363 ' read an identifier
364 tok$ = "": toktype$ = "ident"
365 if thech$ >= "A" and thech$ <= "Z" then thech$ = chr$(asc(thech$) + 32)
366 if thech$ >= "a" and thech$ <= "z" then tok$ = tok$ + thech$: gosub 369: goto 365
367 if tok$ = "rem" then gosub 326
368 return
369 ' get the next char from the current line
370 if textp > len(thelin$) then thech$ = "": return
371 thech$ = mid$(thelin$, textp, 1)
372 textp = textp + 1
373 return
