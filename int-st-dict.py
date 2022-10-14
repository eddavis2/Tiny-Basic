#Ed Davis. Tiny Basic that can play Star Trek
#Supports: end, list, load, new, run, save
#gosub/return, goto, if, input, print, multi-statement lines (:)
#a single numeric array: @(n), and rnd(n)

from __future__ import print_function
import sys, time, random
try: input = raw_input
except NameError: raw_input = input

C_MAXLINES = 7000

pgm = {}         # program stored here
vars = {}        # variable store
gstackln = []    # gosub line stack
gstacktp = []    # gosub textp stack
atarry = {}      # the @ array

forvar   = {}
forlimit = {}
forline  = {}
forpos   = {}

tok = ""; toktype = ""  # current token, and it's type
thelin = ""; thech = "" # current program line, current character
curline = 0; textp = 0  # position in current line
num = 0                 # last number read by scanner
errors = False
tracing = False
timestart = 0.0

def main():
  global errors, pgm, toktype, tok, textp

  if len(sys.argv) > 1 and sys.argv[1] != "":
    toktype = "string"
    tok = '"' + sys.argv[1]
    loadstmt()
    tok = "run"
    docmd()
  else:
    newstmt()
    help()

  while True:
    errors = False
    pgm[0] = raw_input("py> ").strip()
    if pgm[0] != "":
      initlex(0)
      if toktype == "number":
        validlinenum()
        pgm[num] = pgm[0][textp:]
      else:
        docmd()

def docmd():
  global errors, curline, C_MAXLINES, tok, toktype, tracing
  running = False

  while True:
    if tracing and tok[0] != ":": print("[", curline, "] ", tok, " ", thech, " ", thelin[textp:])
    if tok == "bye" or tok == "quit":    nexttok(); exit()
    elif tok == "end" or tok == "stop":  nexttok(); return
    elif tok == "clear":                 nexttok(); clearvars(); return
    elif tok == "help":                  nexttok(); help(); return
    elif tok == "list":                  nexttok(); liststmt(); return
    elif tok == "load":                  nexttok(); loadstmt(); return
    elif tok == "new":                   nexttok(); newstmt();  return
    elif tok == "run":                   nexttok(); runstmt();  running = True
    elif tok == "save":                  nexttok(); savestmt(); return
    elif tok == "tron":                  nexttok(); tracing = True
    elif tok == "troff":                 nexttok(); tracing = False
    elif tok == "cls":                   nexttok()
    elif tok == "for":                   nexttok(); forstmt()
    elif tok == "gosub":                 nexttok(); gosubstmt()
    elif tok == "goto":                  nexttok(); gotostmt()
    elif tok == "if":                    nexttok(); ifstmt()
    elif tok == "input":                 nexttok(); inputstmt()
    elif tok == "next":                  nexttok(); nextstmt()
    elif tok == "print" or tok == "?":   nexttok(); printstmt()
    elif tok == "return":                nexttok(); returnstmt()
    elif tok == "@":                     nexttok(); arrassn()
    elif tok == ":":                     nexttok(); pass # just continue
    elif tok == "":                      pass  # handled below
    else:
      if tok == "let": nexttok()
      if toktype == "ident":
        assign()
      else:
        print("Unknown token ", tok, " at line ", curline); return

    if errors: return
    if curline > C_MAXLINES: showtime(running); return

    while tok == "":
      if curline == 0 or curline >= C_MAXLINES: showtime(running); return
      initlex(curline + 1)

def showtime(running):
  global timestart

  if running: print("Took : ", time.time() - timestart, " seconds")

def help():
   print("+---------------------- Tiny Basic (Python) --------------------------+")
   print("| bye, clear, cls, end/stop, help, list, load/save, new, run, tron/off|")
   print("| for <var> = <expr1> to <expr2> ... next <var>                       |")
   print("| gosub <expr> ... return                                             |")
   print("| goto <expr>                                                         |")
   print("| if <expr> then <statement>                                          |")
   print("| input [prompt,] <var>                                               |")
   print("| <var>=<expr>                                                        |")
   print("| print <expr|string>[,<expr|string>][;]                              |")
   print("| rem <anystring>                                                     |")
   print("| Operators: ^, * / \ mod + - < <= > >= = <>, not, and, or            |")
   print("| Integer variables a..z, and array @(expr)                           |")
   print("| Functions: abs(expr), asc(ch), rnd(expr), sgn(expr)                 |")
   print("+---------------------- Tiny Basic Help ------------------------------+")

def gosubstmt():   # for gosub: save the line and column
  global gstackln, gstacktp

  gstackln.append(curline)
  gstacktp.append(textp)

  gotostmt()

def assign():
  global vars

  var = getvarindex(); nexttok()
  expect("=")
  vars[var] = expression(0)
  if tracing: print("*** ", chr(var + ord("a")), " = ", vars[var])

def arrassn():   # array assignment: @(expr) = expr
  global tok, errors, atarry

  atndx = parenexpr()
  if tok != "=":
    print("Array Assign: Expecting '=', found: ", tok); errors = True
  else:
    nexttok()     # skip the "="
    n = expression(0)
    atarry[atndx] = n
    if tracing: print("*** @(", atndx, ") = ", n)

def forstmt(): # for i = expr to expr
  global forvar, vars, tok, forlimit, forline, curline, texp, forpos

  var = getvarindex()
  assign()
  # vars(var) has the value; var has the number value of the variable in 0..25
  forndx = var
  forvar[forndx] = vars[var]
  if tok != "to":
    print("For: Expecting 'to', found:", tok); errors = True
  else:
    nexttok()
    n = expression(0)
    forlimit[forndx] = n
    # need to store iter, limit, line, and col
    forline[forndx] = curline
    if tok == "":
      forpos[forndx] = textp
    else:
      forpos[forndx] = textp - 2

def ifstmt():
  global toktype

  if expression(0) == 0: skiptoeol(); return
  if tok == "then": nexttok()           # "then" is optional
  if toktype == "number": gotostmt()

def inputstmt():   # "input" [string ","] var
  global toktype, tok, vars

  if toktype == "string":
    print(tok[1:], end='')
    nexttok()
    expect(",")
  else:
    print("? ", end='')
  var = getvarindex(); nexttok()
  st = raw_input("").strip(); print

  if st.isdigit():
    vars[var] = int(st)
  else:
    vars[var] = ord(st) # turn characters into their ascii value

def liststmt():
  global C_MAXLINES, pgm

  for i in range(1, C_MAXLINES + 1):
    if i in pgm: print(i, " ", pgm[i])
  print("")

def loadstmt():
  global toktype, tok, pgm, num, C_MAXLINES, textp, curline

  newstmt()
  filename = getfilename("Load: ")
  if filename == "": return
  f = open(filename, 'r')
  n = 0
  while True:
    pgm[0] = f.readline().rstrip()
    if not pgm[0]: break

    initlex(0)
    if toktype == "number" and num > 0 and num <= C_MAXLINES:
      pgm[num] = pgm[0][textp:]
      n = num
    else:
      n += 1
      pgm[n] = pgm[0]

  f.close()
  curline = 0

def nextstmt(): # next ident
  global tracing, forvar, vars, forlimit, curline, forline, textp, forpos

  # tok needs to have the variable
  forndx = getvarindex()
  forvar[forndx] = forvar[forndx] + 1
  vars[forndx] = forvar[forndx]
  if tracing: print("*** ", chr(forndx + ord("a")), " = ", vars[forndx])
  if forvar[forndx] <= forlimit[forndx]:
    curline = forline[forndx]
    textp   = forpos[forndx]
    # print "nextstmt tok>"; tok; " textp>"; textp; " >"; mid$(thelin, textp)
    initlex2()
  else:
    nexttok() # skip the ident for now

def newstmt():
  global pgm

  clearvars()
  pgm = {}

# "print" [[#num "," ] expr { "," [#num ","] expr }] [","] {":" stmt} eol
# expr can also be a literal string
def printstmt():
  global tok, toktype

  printnl = True
  while tok != ":" and tok != "" and tok != "else":
    printnl = True
    printwidth = 0
    if accept("#"):
      if num <= 0: print("Expecting a print width, found:", tok); return
      printwidth = num
      nexttok()
      if not accept(","): print("Print: Expecting a ',', found:", tok); return

    if toktype == "string":
      junk = tok[1:]
      nexttok()
    else:
      junk = str(expression(0))

    printwidth = printwidth - len(junk)
    if printwidth <= 0:
      print(junk, end='')
    else:
      print(" " * printwidth, junk, end='')

    if accept(",") or accept(";"):
      printnl = False
    else:
      break

  if printnl: print()

def returnstmt():    # return from a subroutine
  global curline, textp, gstackln, gstacktp

  curline = gstackln.pop()
  textp   = gstacktp.pop()
  initlex2()

def runstmt():
  global timestart

  timestart = time.time()
  clearvars()
  initlex(1)

def gotostmt():
  global num

  num = expression(0)
  validlinenum()
  initlex(num)

def savestmt():
  global toktype, tok, pgm, C_MAXLINES

  filename = getfilename("Save: ")
  if filename == "": return
  if filename.find(".") == -1:  filename += ".bas"

  f = open(filename, 'w')
  for i in range(1, C_MAXLINES + 1):
    if i in pgm: f.write(i, " ", pgm[i], "\n")

  f.close()

def getfilename(action):
  global toktype

  if toktype == "string":
    filename = tok[1:]
  else:
    filename = raw_input(action).strip(); print

  if filename == "": return ""
  if filename.find(".") == -1:  filename += ".bas"
  return filename

def validlinenum():
  global num, C_MAXLINES, errors

  if num <= 0 or num > C_MAXLINES: print("Line number out of range"); errors = True

def clearvars():
  global vars

  vars = {}

def parenexpr():
  global errors

  expect("(")
  if errors: return 0
  n = expression(0)
  expect(")")
  return n

def expression(minprec):
  global tok, toktype, num, vars, atarray

  # handle numeric operands - numbers and unary operators
  if toktype == "number": n = num; nexttok()
  elif tok == "-": nexttok();   n = -expression(7)
  elif tok == "+": nexttok();   n =  expression(7)
  elif tok == "not": nexttok(); n = not expression(3);
  elif tok == "abs": nexttok(); n =  abs(parenexpr())
  elif tok == "asc": nexttok(); expect("("); n = ord(tok[1]); nexttok(); expect(")")
  elif tok == "rnd": nexttok(); n =  random.randint(1, parenexpr())
  elif tok == "sgn": nexttok(); n =  n = parenexpr(); n = bool(n > 0) - bool(n < 0)
  elif toktype == "ident":  n = vars[getvarindex()]; nexttok()
  elif tok == "@": nexttok();   n = atarry[parenexpr()]
  elif tok == "(":              n =  parenexpr()
  else: print("syntax error: expecting an operand, found: ", tok); errors = True; return 0

  while True: # while binary operator and precedence of tok >= minprec
    if   minprec <= 1 and tok == "or":  nexttok(); n = n |   expression(2)
    if   minprec <= 2 and tok == "and": nexttok(); n = n &   expression(3)
    elif minprec <= 4 and tok == "=":   nexttok(); n = n ==  expression(5)
    elif minprec <= 4 and tok == "<":   nexttok(); n = n <   expression(5)
    elif minprec <= 4 and tok == ">":   nexttok(); n = n >   expression(5)
    elif minprec <= 4 and tok == "<>":  nexttok(); n = n !=  expression(5)
    elif minprec <= 4 and tok == "<=":  nexttok(); n = n <=  expression(5)
    elif minprec <= 4 and tok == ">=":  nexttok(); n = n >=  expression(5)
    elif minprec <= 5 and tok == "+":   nexttok(); n = n +   expression(6)
    elif minprec <= 5 and tok == "-":   nexttok(); n = n -   expression(6)
    elif minprec <= 6 and tok == "*":   nexttok(); n = n *   expression(7)
    elif minprec <= 6 and tok == "/":   nexttok(); n = int(float(n) / expression(7))
    elif minprec <= 6 and tok == "\\":  nexttok(); n = int(float(n) / expression(7))
    elif minprec <= 6 and tok == "mod": nexttok(); n = int(float(n) % expression(7))
    elif minprec <= 8 and tok == "^":   nexttok(); n = n **  expression(9)
    else: break

  return n

def getvarindex():
  global toktype, tok, errors

  if toktype != "ident": print("Not a variable:", tok); errors = True; return 0
  return tok

def expect(s):
  global curline, tok, thelin, errors

  if tok == s: nexttok(); return
  print("(", curline , ") expecting " , s, " but found ", tok, " =>", thelin); errors = True

def accept(s):
  if tok == s: nexttok(); return True
  return False

def initlex(n):
  global curline, textp

  curline = n
  textp = 0
  initlex2()

def initlex2():
  global thelin, pgm, curline, thech

  thelin = ""
  if curline in pgm: thelin = pgm[curline]
  thech = " "
  nexttok()

def skiptoeol():
  global tok, toktype, textp, thelin

  tok = ""; toktype = ""
  textp = len(thelin) + 1

def nexttok():
  global tok, toktype, thech, thelin

  tok = ""; toktype = ""
  while thech.isspace():
    if thech == "": return
    getch()

  tok = thech
  if tok.isalpha():
    readident()
    if tok == "rem": skiptoeol()
  elif tok.isdigit():
    readint()
  elif tok == "'":
    skiptoeol()
  elif tok == '"':    # double quote - sstring
    readstr()
  else:
    if "()*+,-/:;<=>?@\\^#".find(tok) != -1:
      toktype = "punct";
      getch();
      if tok == "<" or tok == ">":
        if thech == "=" or thech == ">":
          tok = tok + thech
          getch()
    else:
        print("What?", thech, thelin); getch(); errors = True

# leave the " as the beginning of the string, so it won#t get confused with other tokens
# especially in the print routines
def readstr():
  global tok, toktype, thech

  toktype = "string"
  getch()
  while thech != '"':  # while not a double quote
    if thech == "": print("String not terminated"); errors = True; return
    tok += thech
    getch()
  getch()

def readint():
  global tok, toktype, thech, num

  tok = ""; toktype = "number"
  while thech.isdigit():
    tok += thech
    getch()
  num = int(tok)

def readident():
  global tok, toktype, thech

  tok = ""; toktype = "ident"
  while thech.isalnum():
    tok += thech.lower()
    getch()

def getch():
  global textp, thelin, thech

  # Any more text on this line?
  if textp + 1 > len(thelin): thech = ""; return
  thech = thelin[textp]
  textp += 1

main()
