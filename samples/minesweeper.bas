1 ' PROGRAM: Minesweeper for Tiny Basic, by Marcus
2 ' ===========================================================================
3 m = 15 ' Number of mines (difficulty).
4 for i = 0 to 99 : @(i) = 10 : @(100 + i) = 0 : next i ' Clear map.
5 gosub 110: print "Dig at" : gosub 30 ' Display map, input initial dig.
6 gosub 80 ' Generate map with m mines, make pos x, y safe.
7 s = 0 : f = m ' Set game state s to 0 and unused flags f to number of mines.
8 gosub 140 ' Dig at x, y.
10 ' Game loop =================================================================
11 gosub 110 ' Display map.
12 print "Flags left: "; : print f
13 input "Action (d = dig, f = add/remove flag, q = quit, c = cheat): ", a
14 if a = asc("d") then gosub 40
15 if a = asc("f") then gosub 50
16 if a = asc("c") then gosub 70
17 if a = asc("q") then s = -1
18 if s = 0 then goto 10 ' Loop.
20 gosub 100
21 if s < 0 then print "Bye bye!"
22 if s = 1 then print "ALL MINES MARKED, YOU SUCCEEDED!"
23 if s = 2 then print "BOOM, YOU FAILED!"
24 print
25 end
30 ' SUB: Input valid coordinates to x, y =====================================
31 input "  X (0-9): ", x : if x < 0 or x > 9 then goto 31
32 input "  Y (0-9): ", y : if y < 0 or y > 9 then goto 32
33 return
40 ' SUB: Dig action ==========================================================
41 print "Dig at" : gosub 30 : gosub 180 ' Get coords and convert to index p.
42 if @(100 + p) then print : print : print "You can't dig there!" : return
43 if @(p) = 11 then s = 2 : return
44 gosub 140 : return
50 ' SUB: Add remove flag action ==============================================
51 print "Add or remove flag at" : gosub 30 : gosub 180
52 if @(100 + p) = 3 then @(100 + p) = 0 : f = f + 1 : return
53 if f = 0 then print : print "You're out of flags!" : return
54 if @(100 + p) > 0 then print : print "You can't place a flag there!" : return
55 f = f - 1 : @(100 + p) = 3
56 ' Change game state to completed but restore if any mine is not flagged.
57 s = 1 : for y = 0 to 9: for x = 0 to 9
58  if @(y*10 + x) = 11 and not @(100 + y*10 + x) = 3 then s = 0
59 next x : next y
60 return
70 ' SUB: Cheat action ========================================================
71 gosub 100 : return
80 ' SUB: Init map with m mines, make position x, y "a zero" ==================
81 a = x : b  = y : c = 0
82 for y = 0 to 9 : for x = 0 to 9
83  if x < a - 1 or x > a + 1 or y < b - 1 or y > b + 1 then @(100 + c) = y*10 + x : c = c + 1
84 next x : next y
85 for i = 1 to m
86  j = rnd(c) : p = @(100 + j) : gosub 190 : @(y*10 + x) = 11 : c = c - 1
87  for k = j to c - 1 : @(100 + k) = @(100 + k + 1) : next k
88 next i
89 for i = 100 to 199 : @(i) = 0 : next i
90 x = a : y = b : return
100 ' SUB: Display actual map ==================================================
101 print : print " | 0 1 2 3 4 5 6 7 8 9" : print "-+--------------------"
102 for y = 0 to 9 : print y, "| "; : for x = 0 to 9
103  if @(y*10 + x) = 11 then print "* "; : goto 105 ' Mine
104  print "  "; ' Nothing.
105 next x : print : next y : print
106 return
110 ' SUB: Display user view ==================================================
111 print : print " | 0 1 2 3 4 5 6 7 8 9" : print "-+--------------------"
112 for y = 0 to 9 : print y, "| "; : for x = 0 to 9
113  p = y*10 + x : gosub 130
114 next x : print : next y : print
115 return
130 ' SUB: Print map character for position p ==================================
131 if @(100 + p) = 3 then print "F "; : return ' Flag.
132 if @(p) > 9 then print "? "; : return      ' Unexplored.
133 if @(p) = 0 then print "  "; : return      ' Empty.
134 print @(p), " "; : return                  ' Close to a mine.
140 ' SUB: Update visibility at x, y ===========================================
141 gosub 180 : if p < 0 then return
142 if @(100 + p) > 0 then return
143 @(100 + p) = 1
144 d = 1 : for i = 0 to 99
145  if @(100 + i) = 1 then d = 0 : p = i : gosub 150
146 next i
147 if d = 0 goto 144
148 return
150 ' SUB: Reveal position p and possibly mark more positions to be checked ====
151 @(100 + p) = 2 : z = p
152 gosub 200
153 @(z) = r
154 if r > 0 then return
155 p = z : gosub 190 : g = x : h = y
156 for v = h - 1 to h + 1 : for u = g - 1 to g + 1
157  x = u : y = v : gosub 180 : if p >= 0 and @(100 + p) = 0 then @(100 + p) = 1
158 next u : next v
159 return
180 ' SUB: Convert coordinates x, y to position p, -1 if invalid ===============
181 if x < 0 or x > 9 or y < 0 or y > 9 then p = -1 : return
182 p = y*10 + x
183 return
190 ' SUB: Convert position p to coordinates x, y, no error checking ===========
191 x = p mod 10 : y = p/10 : return
200 ' SUB: Calculate number of mines nearby p ==================================
201 r = 0 : q = p : gosub 190 : g = x : h = y
202 for v = h - 1 to h + 1 : for u = g - 1 to g + 1
203  x = u : y = v : gosub 180 : if p >= 0 then r = r + (@(p) = 11)
204 next u : next v
205 return
