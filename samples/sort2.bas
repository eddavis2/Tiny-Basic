10 PRINT "Enter 10 numbers:"
20 FOR I = 1 TO 10
30 PRINT "Number ", I, "? ",
40 INPUT x: @(I) = x
50 NEXT I
100 N = 10
110 FOR I = 1 TO N-1
120 FOR J = 1 TO N-1
130 IF @(J) < @(J+1) THEN 170
140 X = @(J)
150 @(J) = @(J+1)
160 @(J+1) =X
170 NEXT J
180 NEXT I
200 FOR I = 1 TO 10
210 PRINT @(I),
220 NEXT I
225 PRINT
230 END
