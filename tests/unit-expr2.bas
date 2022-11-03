t = 0: e = 0
rem sanity tests
rem or
t = t + 1: if (0 or 0) <> 0                                                                                      then print "expr test   1 failed": e = e + 1
t = t + 1: if (1 < 0 or 3 < 2) <> 0                                                                              then print "expr test   2 failed": e = e + 1
t = t + 1: if (1 < 0 or 1 > 0) = 0                                                                               then print "expr test   3 failed": e = e + 1
t = t + 1: if (1 > 0 or 1 < 0) = 0                                                                               then print "expr test   4 failed": e = e + 1
rem and
t = t + 1: if (0 and 0) <> 0                                                                                     then print "expr test   5 failed": e = e + 1
t = t + 1: if (1 < 0 and 2 < 3) <> 0                                                                             then print "expr test   6 failed": e = e + 1
t = t + 1: if (1 < 0 and 1 > 0) <> 0                                                                             then print "expr test   7 failed": e = e + 1
t = t + 1: if (1 > 0 and 1 < 0) <> 0                                                                             then print "expr test   8 failed": e = e + 1
t = t + 1: if (1 > 0 and 2 > 0) = 0                                                                              then print "expr test   9 failed": e = e + 1
rem =
t = t + 1: if (1 = 0) <> 0                                                                                       then print "expr test  10 failed": e = e + 1
t = t + 1: if (1 = 1) = 00                                                                                       then print "expr test  11 failed": e = e + 1
rem <
t = t + 1: if (1 < 0) <> 0                                                                                       then print "expr test  12 failed": e = e + 1
t = t + 1: if (1 < 2) = 0                                                                                        then print "expr test  13 failed": e = e + 1
rem >
t = t + 1: if (0 > 1) <> 0                                                                                       then print "expr test  14 failed": e = e + 1
t = t + 1: if (1 > 0) = 0                                                                                        then print "expr test  15 failed": e = e + 1
rem <>
t = t + 1: if (0 <> 0) <> 0                                                                                      then print "expr test  16 failed": e = e + 1
t = t + 1: if (1 <> 0) = 0                                                                                       then print "expr test  17 failed": e = e + 1
rem <=
t = t + 1: if (1 <= 0) <> 0                                                                                      then print "expr test  18 failed": e = e + 1
t = t + 1: if (1 <= 1) = 0                                                                                       then print "expr test  19 failed": e = e + 1
rem >=
t = t + 1: if (0 >= 1) <> 0                                                                                      then print "expr test  20 failed": e = e + 1
t = t + 1: if (1 >= 1) = 0                                                                                       then print "expr test  21 failed": e = e + 1
rem +
t = t + 1: if (4 + 5) <> 9                                                                                       then print "expr test  22 failed": e = e + 1
rem -
t = t + 1: if (9 - 4) <> 5                                                                                       then print "expr test  23 failed": e = e + 1
rem *
t = t + 1: if (2 * 3) <> 6                                                                                       then print "expr test  24 failed": e = e + 1
rem  \
t = t + 1: if (8 \ 4) <> 2                                                                                       then print "expr test  25 failed": e = e + 1
rem mod
t = t + 1: if (9 mod 3) <> 0                                                                                     then print "expr test  26 failed": e = e + 1
t = t + 1: if (9 mod 5) <> 4                                                                                     then print "expr test  27 failed": e = e + 1
rem ^
t = t + 1: if (2 ^ 3) <> 8                                                                                       then print "expr test  28 failed": e = e + 1
rem rest of tests
t = t + 1: if (((((2)) + 4))*((5))) <> 30                                                                        then print "expr test  29 failed": e = e + 1
t = t + 1: if (((((((((3 + 2) * ((((((2)))))))))))))) <> 10                                                      then print "expr test  30 failed": e = e + 1
t = t + 1: if (((((((-99))))))-1) <> -100                                                                        then print "expr test  31 failed": e = e + 1
t = t + 1: if ((((((1)))))) <> 1                                                                                 then print "expr test  32 failed": e = e + 1
t = t + 1: if (((((2))))+3*5) <> 17                                                                              then print "expr test  33 failed": e = e + 1
t = t + 1: if ((((286)))) <> 286                                                                                 then print "expr test  34 failed": e = e + 1
t = t + 1: if (((1+2)\3-4)*5) <> -15                                                                             then print "expr test  35 failed": e = e + 1
t = t + 1: if (((11+15)*15)* 2 + (3) * -4 *1) <> 768                                                             then print "expr test  36 failed": e = e + 1
t = t + 1: if (((11+15)*15)*2+(3)*-4*1) <> 768                                                                   then print "expr test  37 failed": e = e + 1
t = t + 1: if (((11+15)*15)*2-(3)*4*1) <> 768                                                                    then print "expr test  38 failed": e = e + 1
t = t + 1: if (((2 + 3) * (1 + 2)) * 4 ^ 2) <> 240                                                               then print "expr test  39 failed": e = e + 1
t = t + 1: if (((286))) <> 286                                                                                   then print "expr test  40 failed": e = e + 1
t = t + 1: if ((-1 * ((-1 * (5 * 15)) \ 10))) <> 7                                                               then print "expr test  41 failed": e = e + 1
t = t + 1: if ((-1--2)+(-3--4)) <> 2                                                                             then print "expr test  42 failed": e = e + 1
t = t + 1: if ((-15\2)) <> -7                                                                                    then print "expr test  43 failed": e = e + 1
t = t + 1: if ((-5--7)*2) <> 4                                                                                   then print "expr test  44 failed": e = e + 1
t = t + 1: if ((1 + 2 \ 2) * (5 + 5)) <> 20                                                                      then print "expr test  45 failed": e = e + 1
t = t + 1: if ((1 + 2) * 10 \ 100) <> 0                                                                          then print "expr test  46 failed": e = e + 1
t = t + 1: if ((1 + 2) * 3) <> 9                                                                                 then print "expr test  47 failed": e = e + 1
t = t + 1: if ((1 + 2^(19 mod 4))\2) <> 4                                                                        then print "expr test  48 failed": e = e + 1
t = t + 1: if ((1 - 1 + 4) * 2) <> 8                                                                             then print "expr test  49 failed": e = e + 1
t = t + 1: if ((1 - 5) * 2 \ (20 + 1)) <> 0                                                                      then print "expr test  50 failed": e = e + 1
t = t + 1: if ((1)+2) <> 3                                                                                       then print "expr test  51 failed": e = e + 1
t = t + 1: if ((1+(2-5)*3+8\(5+3)^2)\(4^2+3^2)) <> 0                                                             then print "expr test  52 failed": e = e + 1
t = t + 1: if ((1+(2-5)*3+8\(5+3)^2)\(5^2+3^2)) <> 0                                                             then print "expr test  53 failed": e = e + 1
t = t + 1: if ((1+2)) <> 3                                                                                       then print "expr test  54 failed": e = e + 1
t = t + 1: if ((1+2)\3-4*5) <> -19                                                                               then print "expr test  55 failed": e = e + 1
t = t + 1: if ((1+3)*2-2*(4-7)) <> 14                                                                            then print "expr test  56 failed": e = e + 1
t = t + 1: if ((1+3)*7) <> 28                                                                                    then print "expr test  57 failed": e = e + 1
t = t + 1: if ((10+20) \ 15) <> 2                                                                                then print "expr test  58 failed": e = e + 1
t = t + 1: if ((155 + 2 + 3 - 155 - 2 - 3 + 4) * 2) <> 8                                                         then print "expr test  59 failed": e = e + 1
t = t + 1: if ((2 + 3) * 4) <> 20                                                                                then print "expr test  60 failed": e = e + 1
t = t + 1: if ((2 + 3) \ (10 - 5)) <> 1                                                                          then print "expr test  61 failed": e = e + 1
t = t + 1: if ((2) + (17*2-30) * (5)+2 - (8\2)*4) <> 8                                                           then print "expr test  62 failed": e = e + 1
t = t + 1: if ((286)) <> 286                                                                                     then print "expr test  63 failed": e = e + 1
t = t + 1: if ((3 \ 2) * -2) <> -2                                                                               then print "expr test  64 failed": e = e + 1
t = t + 1: if ((32 \ 2) * 2) <> 32                                                                               then print "expr test  65 failed": e = e + 1
t = t + 1: if ((34+32)-44\(8+9*(3+2))-22) <> 44                                                                  then print "expr test  66 failed": e = e + 1
t = t + 1: if ((4^2+3^2)) <> 25                                                                                  then print "expr test  67 failed": e = e + 1
t = t + 1: if ((5 + 2*3 - 1 + 7 * 8)) <> 66                                                                      then print "expr test  68 failed": e = e + 1
t = t + 1: if ((5-4)*(12-11)\((((5-4)*(12-11))))) <> 1                                                           then print "expr test  69 failed": e = e + 1
t = t + 1: if ((5-7)* 2) <> -4                                                                                   then print "expr test  70 failed": e = e + 1
t = t + 1: if ((67 + 2 * 3 - 67 + 2\1 - 7)) <> 1                                                                 then print "expr test  71 failed": e = e + 1
t = t + 1: if ((78 + 34 * 9 * (45 * (23 - 15 * 4) - 8))) <> -511860                                              then print "expr test  72 failed": e = e + 1
t = t + 1: if ((8 - 6 \ 2) \ (8-6\2)) <> 1                                                                       then print "expr test  73 failed": e = e + 1
t = t + 1: if (- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - + + +5) <> -5                   then print "expr test  74 failed": e = e + 1
t = t + 1: if (-(-2 * -6)) <> -12                                                                                then print "expr test  75 failed": e = e + 1
t = t + 1: if (-(-3)^2) <> -9                                                                                    then print "expr test  76 failed": e = e + 1
t = t + 1: if (-(1 + 2)) <> -3                                                                                   then print "expr test  77 failed": e = e + 1
t = t + 1: if (-(15\2)) <> -7                                                                                    then print "expr test  78 failed": e = e + 1
t = t + 1: if (-(2)) <> -2                                                                                       then print "expr test  79 failed": e = e + 1
t = t + 1: if (-1 * -2) <> 2                                                                                     then print "expr test  80 failed": e = e + 1
t = t + 1: if (-1 + 3) <> 2                                                                                      then print "expr test  81 failed": e = e + 1
t = t + 1: if (-1) <> -1                                                                                         then print "expr test  82 failed": e = e + 1
t = t + 1: if (-1*(15\2)) <> -7                                                                                  then print "expr test  83 failed": e = e + 1
t = t + 1: if (-10+13-12\(16\2^2)) <> 0                                                                          then print "expr test  84 failed": e = e + 1
t = t + 1: if (-11 - (16 - 32)) <> 5                                                                             then print "expr test  85 failed": e = e + 1
t = t + 1: if (-1^ 2 * - -1) <> -1                                                                               then print "expr test  86 failed": e = e + 1
t = t + 1: if (-2 * -1\2 - 3) <> -2                                                                              then print "expr test  87 failed": e = e + 1
t = t + 1: if (-2 * -5) <> 10                                                                                    then print "expr test  88 failed": e = e + 1
t = t + 1: if (-2 * 6) <> -12                                                                                    then print "expr test  89 failed": e = e + 1
t = t + 1: if (-2 + -1) <> -3                                                                                    then print "expr test  90 failed": e = e + 1
t = t + 1: if (-2 - -1) <> -1                                                                                    then print "expr test  91 failed": e = e + 1
t = t + 1: if (-2 - -3) <> 1                                                                                     then print "expr test  92 failed": e = e + 1
t = t + 1: if (-2^4) <> -16                                                                                      then print "expr test  93 failed": e = e + 1
t = t + 1: if (-3*(5)^2 + 2*(4 - 18) + 33) <> -70                                                                then print "expr test  94 failed": e = e + 1
t = t + 1: if (-35) <> -35                                                                                       then print "expr test  95 failed": e = e + 1
t = t + 1: if (-5 * 3 + 2) <> -13                                                                                then print "expr test  96 failed": e = e + 1
t = t + 1: if (-5 ^ 2) <> -25                                                                                    then print "expr test  97 failed": e = e + 1
t = t + 1: if (-5) <> -5                                                                                         then print "expr test  98 failed": e = e + 1
t = t + 1: if (-5\5) <> -1                                                                                       then print "expr test  99 failed": e = e + 1
t = t + 1: if (0 and 0 or 1) <> 1                                                                                then print "expr test 100 failed": e = e + 1
t = t + 1: if (0 and 1 or 1) <> 1                                                                                then print "expr test 101 failed": e = e + 1
t = t + 1: if (0 and 1) <> 0                                                                                     then print "expr test 102 failed": e = e + 1
t = t + 1: if (0 or 0 and 1) <> 0                                                                                then print "expr test 103 failed": e = e + 1
t = t + 1: if (0 or 1 and 1) <> 1                                                                                then print "expr test 104 failed": e = e + 1
t = t + 1: if (0 or 1) = 0                                                                                       then print "expr test 105 failed": e = e + 1
t = t + 1: if (1 + -3) <> -2                                                                                     then print "expr test 106 failed": e = e + 1
t = t + 1: if (1 + 2 * (-3 + 2^ 3 ^ 2)) <> 123                                                                   then print "expr test 107 failed": e = e + 1
t = t + 1: if (1 + 2 * (3 + (4 * 5 + 6 * 7 * 8) - 9) \ 10) <> 71                                                 then print "expr test 108 failed": e = e + 1
t = t + 1: if (1 + 2*(3 - 2*(3 - 2)*((2 - 4)*5 - 22\(7 + 2*(3 - 1)) - 1)) + 1) <> 60                             then print "expr test 109 failed": e = e + 1
t = t + 1: if (1 - 5 * 20 \ 20 + 1) <> -3                                                                        then print "expr test 110 failed": e = e + 1
t = t + 1: if (1 -1 + 2 - 2 + 4 - 4 + 6) <> 6                                                                    then print "expr test 111 failed": e = e + 1
t = t + 1: if (1 and 0) <> 0                                                                                     then print "expr test 112 failed": e = e + 1
t = t + 1: if (1 and 1) = 0                                                                                      then print "expr test 113 failed": e = e + 1
t = t + 1: if (1 or 0) = 0                                                                                       then print "expr test 114 failed": e = e + 1
t = t + 1: if (1 or 1) = 0                                                                                       then print "expr test 115 failed": e = e + 1
t = t + 1: if (1) <> 1                                                                                           then print "expr test 116 failed": e = e + 1
t = t + 1: if (1+(2)) <> 3                                                                                       then print "expr test 117 failed": e = e + 1
t = t + 1: if (1+(2-5)*3+8\(5+3)^2) <> -8                                                                        then print "expr test 118 failed": e = e + 1
t = t + 1: if (1+1+(1+(1+(1+(1+(1+(1+(1+(1+(1+(1+(1+(1+(1+1\15)\14)\13)\12)\11)\10)\9)\8)\7)\6)\5)\4)\3)\2) <> 2 then print "expr test 119 failed": e = e + 1
t = t + 1: if (1+2*(3+((4*5)+(6*7*8))-9)\10) <> 71                                                               then print "expr test 120 failed": e = e + 1
t = t + 1: if (1+2*(3-2*(3-2)*((2-4)*5-22\(7+2*(3-1))-1))+1) <> 60                                               then print "expr test 121 failed": e = e + 1
t = t + 1: if (1+2+3 + (4 + 5) + 7) <> 22                                                                        then print "expr test 122 failed": e = e + 1
t = t + 1: if (1+2+3+4) <> 10                                                                                    then print "expr test 123 failed": e = e + 1
t = t + 1: if (1+3*7) <> 22                                                                                      then print "expr test 124 failed": e = e + 1
t = t + 1: if (1-2) <> -1                                                                                        then print "expr test 125 failed": e = e + 1
t = t + 1: if (100-65*7+23) <> -332                                                                              then print "expr test 126 failed": e = e + 1
t = t + 1: if (12 + 34 * 56 \ 1) <> 1916                                                                         then print "expr test 127 failed": e = e + 1
t = t + 1: if (12 <> 34 and 56 <> 78) = 0                                                                        then print "expr test 128 failed": e = e + 1
t = t + 1: if (12 and 1 or 1) <> 1                                                                               then print "expr test 129 failed": e = e + 1
t = t + 1: if (12 or 34 and 56 and 78) <> 12                                                                     then print "expr test 130 failed": e = e + 1
t = t + 1: if (12 or 34 or 56 and 78) <> 46                                                                      then print "expr test 131 failed": e = e + 1
t = t + 1: if (12\(1+3)-9*6) <> -51                                                                              then print "expr test 132 failed": e = e + 1
t = t + 1: if (15-13*2^3) <> -89                                                                                 then print "expr test 133 failed": e = e + 1
t = t + 1: if (1\-2) <> 0                                                                                        then print "expr test 134 failed": e = e + 1
t = t + 1: if (2 * (3 + ((50) \ (7 - 11)))) <> -18                                                               then print "expr test 135 failed": e = e + 1
t = t + 1: if (2 * (3 + (4 * 5 + (6 * 7) * 8) - 9) * 10) <> 7000                                                 then print "expr test 136 failed": e = e + 1
t = t + 1: if (2 * -1\2 - 3) <> -4                                                                               then print "expr test 137 failed": e = e + 1
t = t + 1: if (2 * -3 - -4 + -1) <> -3                                                                           then print "expr test 138 failed": e = e + 1
t = t + 1: if (2 * 3 + 2 ^ 2 * 4) <> 22                                                                          then print "expr test 139 failed": e = e + 1
t = t + 1: if (2 * 3 + 4) <> 10                                                                                  then print "expr test 140 failed": e = e + 1
t = t + 1: if (2 * 3\2 - 3) <> 0                                                                                 then print "expr test 141 failed": e = e + 1
t = t + 1: if (2 *- 5 + 3) <> -7                                                                                 then print "expr test 142 failed": e = e + 1
t = t + 1: if (2 + -5 * 3) <> -13                                                                                then print "expr test 143 failed": e = e + 1
t = t + 1: if (2 + 3 * 4) <> 14                                                                                  then print "expr test 144 failed": e = e + 1
t = t + 1: if (2 -4 +6 -1 -1- 0 +8) <> 10                                                                        then print "expr test 145 failed": e = e + 1
t = t + 1: if (2*(-3)-(-4)+(-2)) <> -4                                                                           then print "expr test 146 failed": e = e + 1
t = t + 1: if (2*(-5-7)) <> -24                                                                                  then print "expr test 147 failed": e = e + 1
t = t + 1: if (2*(3+4)+5\6) <> 14                                                                                then print "expr test 148 failed": e = e + 1
t = t + 1: if (2*(7 + 8)^2 - 12*(6*(2))) <> 306                                                                  then print "expr test 149 failed": e = e + 1
t = t + 1: if (2*-3 - -4+-2) <> -4                                                                               then print "expr test 150 failed": e = e + 1
t = t + 1: if (2*-3--4+-25) <> -27                                                                               then print "expr test 151 failed": e = e + 1
t = t + 1: if (2*3 - 4*5 + 6\3) <> -12                                                                           then print "expr test 152 failed": e = e + 1
t = t + 1: if (2*3*4\80 - 5\20*4 + 6 + 0\3) <> 6                                                                 then print "expr test 153 failed": e = e + 1
t = t + 1: if (2*3-4) <> 2                                                                                       then print "expr test 154 failed": e = e + 1
t = t + 1: if (2+(3-4)*6\5^2^3 mod 3) <> 2                                                                       then print "expr test 155 failed": e = e + 1
t = t + 1: if (2+3) <> 5                                                                                         then print "expr test 156 failed": e = e + 1
t = t + 1: if (2+3\4) <> 2                                                                                       then print "expr test 157 failed": e = e + 1
t = t + 1: if (2^2^4) <> 256                                                                                     then print "expr test 158 failed": e = e + 1
t = t + 1: if (3 * (2 + -4) ^ 4) <> 48                                                                           then print "expr test 159 failed": e = e + 1
t = t + 1: if (3 * -2) <> -6                                                                                     then print "expr test 160 failed": e = e + 1
t = t + 1: if (3 - -2) <> 5                                                                                      then print "expr test 161 failed": e = e + 1
t = t + 1: if (3*(4)^2*10 + 10\2 - 6*(4)) <> 461                                                                 then print "expr test 162 failed": e = e + 1
t = t + 1: if (32 \ 2) <> 16                                                                                     then print "expr test 163 failed": e = e + 1
t = t + 1: if (32 \ 2 \ 2) <> 8                                                                                  then print "expr test 164 failed": e = e + 1
t = t + 1: if (36+10*5-18\6) <> 83                                                                               then print "expr test 165 failed": e = e + 1
t = t + 1: if (39*(3^2)+3^3*(3)) <> 432                                                                          then print "expr test 166 failed": e = e + 1
t = t + 1: if (4 * (3) ^ 2 - (-2)) <> 38                                                                         then print "expr test 167 failed": e = e + 1
t = t + 1: if (4*(1\1-1\3+1\5-1\7+1\9-1\11+1\13-1\15+1\17-1\19+10\401)) <> 4                                     then print "expr test 168 failed": e = e + 1
t = t + 1: if (4*-6 *(3 * 7 + 5) + 2 * 7) <> -610                                                                then print "expr test 169 failed": e = e + 1
t = t + 1: if (4*25 + 85+15 \ 3) <> 190                                                                          then print "expr test 170 failed": e = e + 1
t = t + 1: if (4^3^2) <> 4096                                                                                    then print "expr test 171 failed": e = e + 1
t = t + 1: if (6 * 5 - (1 * 2 + 3 * 4)) <> 16                                                                    then print "expr test 172 failed": e = e + 1
t = t + 1: if (8*7^2 - 12*(7) + (47 - 5) + 6) <> 356                                                             then print "expr test 173 failed": e = e + 1
t = t + 1: if (9*7-(2+6)\8) <> 62                                                                                then print "expr test 174 failed": e = e + 1
t = t + 1: if (9*8+4-2\(4-2)) <> 75                                                                              then print "expr test 175 failed": e = e + 1
t = t + 1: if -10 <> -10                                                                                         then print "expr test 176 failed": e = e + 1
t = t + 1: if 10 * 10 <> 100                                                                                     then print "expr test 177 failed": e = e + 1
t = t + 1: if 10 - 15 <> -5                                                                                      then print "expr test 178 failed": e = e + 1
t = t + 1: if 10 > 11                                                                                            then print "expr test 179 failed": e = e + 1
t = t + 1: if 10 >= 11                                                                                           then print "expr test 180 failed": e = e + 1
t = t + 1: if 10 mod 3 <> 1                                                                                      then print "expr test 181 failed": e = e + 1
t = t + 1: if 10 \ 2 <> 5                                                                                        then print "expr test 182 failed": e = e + 1
t = t + 1: if 10 \ 3 <> 3                                                                                        then print "expr test 183 failed": e = e + 1
t = t + 1: if 100 \ 10 \ 2 <> 5                                                                                  then print "expr test 184 failed": e = e + 1
t = t + 1: if 11 < 10                                                                                            then print "expr test 185 failed": e = e + 1
t = t + 1: if 11 <= 10                                                                                           then print "expr test 186 failed": e = e + 1
t = t + 1: if 15 + 15 <> 30                                                                                      then print "expr test 187 failed": e = e + 1
t = t + 1: if 15 - 10 <> 5                                                                                       then print "expr test 188 failed": e = e + 1
t = t + 1: if 2 * -1 <> -2                                                                                       then print "expr test 189 failed": e = e + 1
t = t + 1: if 20 - 10 - 2 <> 8                                                                                   then print "expr test 190 failed": e = e + 1
t = t + 1: if 21 = 42                                                                                            then print "expr test 191 failed": e = e + 1
t = t + 1: if 42 <> 42                                                                                           then print "expr test 192 failed": e = e + 1
if e = 0 then print "All "; t; " tests passed"
if e <> 0 then print e; " tests out of "; t; " failed"
