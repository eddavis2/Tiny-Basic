10 print "Unsorted:"
20 for i = 0 to 9 : @(i) = rnd(100) : print @(i) : next i
30 d = 1
40 for i = 1 to 9
50  if @(i) < @(i - 1) then gosub 90
60 next i
70 if d = 0 then goto 30
80 goto 100
90 s = @(i) : @(i) = @(i - 1) : @(i - 1) = s : d = 0 : return
100 print
110 print "Sorted:"
120 for i = 0 to 9 : print @(i) : next i
