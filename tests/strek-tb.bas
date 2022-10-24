   1 ' StarTrek for TinyBasic
   5 y = 2999: input "Do you want a difficult game? (y or n):", a
  10 print "Stardate 3200:  your mission is ";: if a = asc("y") then y = 999
  15 k = 0: b = 0: d = 30: for i = 0 to 63: j = abs(rnd(99) < 5): b = b + j
  20 m = rnd(y): m = abs((m < 209) + (m < 99) + (m < 49) + (m < 24) + (m < 9) + (m < 2)): k = k + m
  25 @(i) = -100 * m - 10 * j - rnd(8): next i: if (b < 2) + (k < 4) goto 15
  30 print "to destroy "; k; " Klingons in 30 stardates."
  35 print "there are "; b; " starbases.": gosub 160: c = 0: h = k
  40 u = rnd(8): v = rnd(8): x = rnd(8): y = rnd(8)
  45 for i = 71 to 152: @(i) = 0: next i: @(8 * x + y + 62) = 4: m = abs(@(8 * u + v - 9)): n = m / 100
  50 i = 1: if n then for j = 1 to n: gosub 165: @(j + 134) = 300: @(j + 140) = s: @(j + 146) = t: next j
  55 gosub 175: m = m - 100 * n: i = 2: if m / 10 gosub 165
  60 m = m - m / 10 * 10: i = 3: if m then for j = 1 to m: gosub 165: next j
  65 gosub 145: gosub 325: if k goto 95
  70 print : print "Mission accomplished.": if d < 3 then print "Boy, you barely made it."
  75 if d > 5 then print "Good work...": if d > 9 then print "Fantastic!": if d > 13 then print "Unbelievable!"
  80 d = 30 - d: i = h * 100 / d * 10: print h; " Klingons in "; d; " stardates. ("; i; ")"
  85 j = 100 * abs(c = 0) - 5 * c: print c; " casualties incurred. ("; j; ")"
  90 print "your score:",i + j: goto 110
  95 if d < 0 then print "It's too late, the Federation has been conquered.": goto 110
 100 if e >= 0 goto 120
 105 print "Enterprise destroyed": if h - k > 9 then print "But you were a good man"
 110 y = 987: print : input "Another game? (y or n):", a: if a = asc("y") goto 5
 115 print "Good bye.": end
 120 input "Captain:", a
 122 if a = asc("g") then goto 180 'Galaxy map
 123 if a = asc("l") then goto 200 'LR. sensor
 121 if a = asc("s") then goto 220 'SR. sensor
 124 if a = asc("p") then goto 260 'Phaser
 125 if a = asc("r") then goto 420 'Report
 126 if a = asc("w") then goto 465 'Warp engine
 127 if a = asc("t") then goto 555 'Torpedo
 128 if a = asc("q") then goto 110 'Quit
 130 print "r=Report       s=SR. Sensor   l=LR. Sensor"
 135 print "g=Galaxy Map   p=Phaser       t=Torpedo"
 140 print "w=Warp Engine  q=Quit     ***Please use one of these commands***": goto 120
 145 for i = x - abs(x > 1) to x + abs(x < 8): for j = y - abs(y > 1) to y + abs(y < 8)
 150 if @(8 * i + j + 62) <> 2 then next j: next i: o = 0: return
 155 if o = 0 then print "Sulu: 'Captain, we are docked at starbase."
 160 e = 4000: f = 10: o = 1: for i = 64 to 70: @(i) = 0: next i: return
 165 s = rnd(8): t = rnd(8): a = 8 * s + t + 62: if @(a) goto 165
 170 @(a) = i: return
 175 print "Enterprise in q-",#1,u,v," s-",x,y: return
 180 gosub 175: j = 2: gosub 375: if i goto 120
 185 print " of galaxy map": for i = 0 to 7: print : print #1,i + 1,":",: for j = 0 to 7: m = @(8 * i + j)
 190 print #4,abs(m > 0) * m,: next j: print : next i: print "  ",: for i = 0 to 7: print "  ..",: next i: print
 195 print " ";: for i = 1 to 8: print "   "; i;: next i: print : print : goto 120
 200 gosub 175: j = 3: gosub 375: if i goto 120
 205 print : for i = u - 1 to u + 1: for j = v - 1 to v + 1: m = 8 * i + j - 9: a = 0
 210 if (i > 0) * (i < 9) * (j > 0) * (j < 9) then a = abs(@(m)): @(m) = a
 215 print #4,a,: next j: print : next i: goto 120
 220 gosub 175: j = 1: gosub 375: if i goto 120
 225 m = 8 * u + v - 9: @(m) = abs(@(m))
 230 print : for i = 1 to 8: print i;: for j = 1 to 8: m = @(8 * i + j + 62): if m = 0 then print " .",
 235 if m = 1 then print " K",
 240 if m = 2 then print " B",
 245 if m = 3 then print " *",
 250 if m = 4 then print " E",
 255 next j: print : next i: print " ",: for i = 1 to 8: print #2,i,: next i: print : goto 120
 260 j = 4: gosub 375: if i goto 120
 265 input " energized. units to fire:", a: if a < 1 goto 120
 270 if a > e then print "Spock: 'we have only "; e; " units.'": goto 120
 275 e = e - a: if n < 1 then print "phaser fired at empty space.": goto 65
 280 a = a / n: for m = 135 to 140: if @(m) = 0 goto 290
 285 gosub 295: print #3,s," units hit ",: gosub 305
 290 next m: goto 65
 295 if a > 1090 then print "...overloaded..": j = 4: @(67) = 1: a = 9: gosub 375
 300 i = @(m + 6) - x: j= @(m + 12) - y: s = a * 30 / (30 + i * i + j * j) + 1: return
 305 print "Klingon at s-",#1,@(m + 6),@(m + 12),: @(m) = @(m) - s
 310 if @(m) > 0 then print " **damaged**": return
 315 @(m) = 0: i = 8 * u + v - 9: j = @(i) / abs(@(i)): @(i) = @(i) - 100 * j: k = k - 1
 320 i = 8 * @(m + 6) + @(m + 12) + 62: @(i) = 0: n = n - 1: print " ***destroyed***": return
 325 if n = 0 return
 330 print "Klingon attack": if o then print "starbase print tects Enterprise": return
 335 t = 0: for m = 135 to 140: if @(m) = 0 goto 350
 340 a = (@(m) + rnd(@(m))) / 2: gosub 295: t = t + s: i = @(m + 6): j = @(m + 12)
 345 print #3,s," units hit from Klingon at s-",#1,i,j
 350 next m: e = e - t: if e <= 0 then print "*** bang ***": return
 355 print e; " units of energy left.": if rnd(e / 4) > t return
 360 if @(70) = 0 then @(70) = rnd(t / 50 + 1): j = 7: goto 375
 365 j = rnd(6): @(j + 63) = rnd(t / 99 + 1)+@(j + 63): i = rnd(8) + 1: c = c + i
 370 print "Mc coy: 'sickbay to bridge, we suffered"; i; " casualties."
 375 i = @(j + 63): if j = 1 then print "short range sensor",
 380 if j = 2 then print "Computer display",
 385 if j = 3 then print "Long range sensor",
 390 if j = 4 then print "Phaser",
 395 if j = 5 then print "Warp engine",
 400 if j = 6 then print "Photon torpedo tubes",
 405 if j = 7 then print "Shield",
 410 if i = 0 then return
 415 print " damaged, "; i; " stardates estimated for repair": return
 420 print "status report:": print "stardate",#10,3230 - d: print "time left",#7,d
 425 print "condition     ",: if o then print "docked": goto 445
 430 if n then print "red": goto 445
 435 if e < 999 then print "yellow": goto 445
 440 print "green"
 445 print "position      q-",#1,u,v," s-",x,y: print "energy",#12,e
 450 print "torpedoes",#7,f: print "Klingons left",#3,k: print "starbases",#6,b
 455 for j = 1 to 7: if @(j + 63) gosub 375
 460 next j: goto 120
 465 j = 5: gosub 375: if i = 0 then print
 470 input "sector distance:", w: if w < 1 goto 120
 475 if i * (w > 2) then print "Chekov: 'we can try 2 at most, sir.'": goto 470
 480 if w > 91 then w = 91: print "Spock: 'are you sure, Captain?'"
 485 if e < w * w / 2 then print "Scotty: 'sir, we do not have the energy.'": goto 120
 490 gosub 615: if r = 0 goto 120
 495 d = d - 1: e = e - w * w / 2: @(8 * x + y + 62) = 0
 500 for m = 64 to 70: @(m) = (@(m) - 1) * abs(@(m) > 0): next m
 505 p = 45 * x + 22: g = 45 * y + 22: w = 45 * w: for m = 1 to 8: w = w - r: if w < -22 goto 525
 510 p = p + s: g = g + t: i = p / 45: j = g / 45: if (i < 1) + (i > 8) + (j < 1) + (j > 8) goto 530
 515 if @(8 * i + j + 62) = 0 then x = i: y = j: next m
 520 print "**Emergency stop**": print "Spock: 'to err is human.'"
 525 @(8 * x + y + 62) = 4: gosub 175: goto 65
 530 p = u * 72 + p / 5 + w / 5 * s / r - 9: u = p / 72: g = v * 72 + g / 5 + w / 5 * t / r - 9: v = g / 72
 535 if rnd(9) < 2 then print "***Space storm***": t = 100: gosub 360
 540 if (u > 0) * (u < 9) * (v > 0) * (v < 9) then x = (p + 9 - 72 * u) / 9: y = (g + 9 - 72 * v) / 9: goto 45
 545 print "**You wandered outside the galaxy**"
 550 print "On board computer takes over, and saved your life": goto 40
 555 j = 6: gosub 375: if i goto 120
 560 if f = 0 then print " empty": goto 120
 565 print " loaded": gosub 615: if r = 0 goto 120
 570 print "torpedo track ",: f = f - 1: p = 45 * x + 22: g = 45 * y + 22: for m = 1 to 8
 575 p = p + s: g = g + t: i = p / 45: j = g / 45: if (i < 1) + (i > 8) + (j < 1) + (j > 8) goto 585
 580 l = 8 * i + j + 62: w = 8 * u + v - 9: r = @(w) / abs(@(w)): print #1,i,j," ",: goto 585 + 5 * @(l)
 585 next m: print "...missed": goto 65
 590 s = rnd(99) + 280: for m = 135 to 140: if (@(m + 6) = i) * (@(m + 12) = j) gosub 305
 592 next m: goto 65
 595 b = b - 1: @(l) = 0: @(w) = @(w) - 10 * r: print "starbase destroyed"
 597 print "Spock: 'I often find human behaviour fascinating.'": goto 65
 600 print "hit a star": if rnd(9) < 3 then print "torpedo absorbed": goto 65
 605 @(l) = 0: @(w) = @(w) - r: if rnd(9) < 6 then print "star destroyed": goto 65
 610 t = 300: print "it novas    ***radiation alarm***": gosub 360: goto 65
 615 input "course (0-360):", i: if (i > 360) + (i < 0) then r = 0: return
 620 s = (i + 45) / 90: i = i - s * 90: r = (45 + i * i) / 110 + 45: goto 625 + 5 * abs(s < 4) * s
 625 s = -45: t = i: return
 630 s = i: t = 45: return
 635 s = 45: t = -i: return
 640 s = -i: t = -45: return
