// Ed Davis. Tiny Basic that can play Star Trek
// Supports: end, list, load, new, run, save
// gosub/return, goto, if, input, print, multi-statement lines (:)
// a single numeric array: @(n), and rnd(n)

using System;
using System.IO;
using System.Linq;
using System.Text;
using System.Collections;
using System.Collections.Generic;
using System.Timers;
using Microsoft.VisualBasic;

class Program {

const int c_maxlines = 7000, c_maxvars = 26, c_at_max = 1000;

static string[] pgm = new string[c_maxlines + 1]; // program stored here
static int[] vars = new int[c_maxvars + 1];       // variable store
static int[] atarry = new int[c_at_max];          // the @ array

static Stack<int> gstackln = new Stack<int>();
static Stack<int> gstacktp = new Stack<int>();

static int[] forvar = new int[c_maxvars];
static int[] forlimit = new int[c_maxvars];
static int[] forline = new int[c_maxvars];
static int[] forpos = new int[c_maxvars];

static string tok, toktype;                       // current token, and it's type
static string thelin, thech;                      // current program line, current character
static int curline, textp;                        // position in current line
static int num;                                   // last number read by scanner
static bool errors;
static bool tracing;

static TimeSpan timestart;
static Random random = new Random();

static void Main(string[] args) {
  newstmt();
  help();
  while (true) {
    errors = false;
    Console.Write("c#> ");
    pgm[0] = Console.ReadLine();
    if (pgm[0] != "") {
      initlex(0);
      if (toktype == "number") {
        validlinenum();
        pgm[num] = pgm[0].Substring(textp - 1);
      } else {
        docmd();
      }
    }
  }
}

static void docmd() {
  bool running = false;
  while (true) {
    if (tracing && tok[0] != ':') Console.WriteLine("[" + curline + "] " + tok + " " + thech + " " + thelin.Substring(textp - 1));
    switch (tok) {
      case "bye": case "quit": nexttok(); Environment.Exit(1); break;
      case "end": case "stop": nexttok();          return;
      case "clear"       : nexttok(); clearvars(); return;
      case "help"        : nexttok(); help();      return;
      case "list"        : nexttok(); liststmt();  return;
      case "load"        : nexttok(); loadstmt();  return;
      case "new"         : nexttok(); newstmt();   return;
      case "run"         : nexttok(); runstmt(); running = true; break;
      case "save"        : nexttok(); savestmt();  return;
      case "tron"        : nexttok(); tracing = true; break;
      case "troff"       : nexttok(); tracing = false; break;
      case "cls"         : nexttok(); Console.Clear(); break;
      case "for"         : nexttok(); forstmt();   break;
      case "gosub"       : nexttok(); gosubstmt(); break;
      case "goto"        : nexttok(); gotostmt();  break;
      case "if"          : nexttok(); ifstmt();    break;
      case "input"       : nexttok(); inputstmt(); break;
      case "next"        : nexttok(); nextstmt();  break;
      case "print": case "?":nexttok(); printstmt(); break;
      case "return"      : nexttok(); returnstmt();break;
      case "@"           : nexttok(); arrassn();   break;
      case ":"           : nexttok();              break;
      case ""            :                         break;
      default:
        if (tok == "let") nexttok();
        if (toktype == "ident") {
          assign();
        } else {
          Console.WriteLine("Unknown token " + tok + " at line " + curline); errors = true;
        }
        break;
    }

    if (errors) return;
    if (curline + 1 >= pgm.Length) {
      showtime(running);
      return;
    }
    while (tok == "") {
      if (curline == 0 || curline + 1 >= pgm.Length) {
        showtime(running);
        return;
      }
      initlex(curline + 1);
    }
  }
}

static void showtime(bool running) {
  TimeSpan timenow = (DateTime.UtcNow - new DateTime(1970, 1, 1));
  if (running)
    Console.WriteLine("Took : " + (timenow.TotalSeconds - timestart.TotalSeconds) + " seconds");
}

static void help() {
   Console.WriteLine("+---------------------- Tiny Basic Help (C#)--------------------------+" );
   Console.WriteLine("| bye, clear, end, help, list, load, new, run, save, stop             |");
   Console.WriteLine("| goto <expr>                                                         |");
   Console.WriteLine("| gosub <expr> ... return                                             |");
   Console.WriteLine("| if <expr> then <statement>                                          |");
   Console.WriteLine("| input [prompt,] <var>                                               |");
   Console.WriteLine("| <var>=<expr>                                                        |");
   Console.WriteLine("| print <expr|string>[,<expr|string>][;]                              |");
   Console.WriteLine("| rem <anystring>                                                     |");
   Console.WriteLine("| Operators: + - * / < <= > >= <> =                                   |");
   Console.WriteLine("| Integer variables a..z, and array @(expr)                           |");
   Console.WriteLine("| Functions: rnd(expr)                                                |");
   Console.WriteLine("+---------------------- Tiny Basic Help ------------------------------+" );
}

static void gosubstmt() {   // for gosub: save the line and column
  gstackln.Push(curline);
  gstacktp.Push(textp);

  gotostmt();
}

static void assign() {
  int var;
  var = getvarindex();
  nexttok();
  expect("=");
  vars[var] = expression(0);
  if (tracing) Console.WriteLine("*** " + (char)(var + 'a') + " = " + vars[var]);
}

static void arrassn() {   // array assignment: @(expr) = expr
  int n, atndx;

  atndx = parenexpr();
  if (tok != "=") {
    Console.WriteLine("Array Assign: Expecting '=', found: " + tok);
    errors = true;
  } else {
    nexttok();     // skip the "="
    n = expression(0);
    atarry[atndx] = n;
    if (tracing) Console.WriteLine("*** @(" + atndx + ") = " + n);
  }
}

static void forstmt() { // for i = expr to expr
  int var, forndx, n;

  var = getvarindex();
  assign();
  // vars(var) has the value; var has the number value of the variable in 0..25
  forndx = var;
  forvar[forndx] = vars[var];
  if (tok != "to") {
    Console.WriteLine("For: Expecting 'to', found:" + tok); errors = true;
  } else {
    nexttok();
    n = expression(0);
    forlimit[forndx] = n;
    // need to store iter, limit, line, and col
    forline[forndx] = curline;
    if (tok == "") forpos[forndx] = textp; else forpos[forndx] = textp - 2;
    //forpos[forndx] textp; if (tok != "") forpos[forndx] -=2;
  }
}

static void ifstmt() {
  if (expression(0) == 0) {
    skiptoeol();
    return;
  }
  if (tok == "then") nexttok();      // "then" is optional
  if (toktype == "number") gotostmt();
}

static void inputstmt() {   // "input" [string ","] var
  int var;
  string st;
  if (toktype == "string") {
    Console.Write(tok.Substring(1));
    nexttok();
    expect(",");
  } else {
    Console.Write("? ");
  }
  var = getvarindex();
  nexttok();
  st = Console.ReadLine();
  if (st == "") st = "0";
  if (Char.IsDigit(st[0])) {
    vars[var] = Int32.Parse(st);
  } else {
    vars[var] = (int)(st[0]); // turn characters into their ascii value
  }
}

static void liststmt() {
  int i;
  for (i = 1; i < pgm.Length; i++) {
    if (pgm[i] != "") Console.WriteLine(i + " " + pgm[i]);
  }
  Console.WriteLine("");
}

static void loadstmt() {
  int n;
  string filename;
  StreamReader f;

  newstmt();
  filename = getfilename("Load");
  if (filename == "") return;

  f = new StreamReader(filename);
  n = 0;
  while (f.Peek() > 0) {
    pgm[0] = f.ReadLine();
    initlex(0);
    if (toktype == "number" && num > 0 && num <= pgm.Length) {
      pgm[num] = pgm[0].Substring(textp - 1);
      n = num;
    } else {
      n++;
      pgm[n] = pgm[0];
    }
  }
  f.Close();
  curline = 0;
}

static void newstmt() {
  int i;
  clearvars();
  for (i = 1; i < pgm.Length; i++) {
    pgm[i] = "";
  }
}

static void nextstmt() {
  int forndx;

  // tok needs to have the variable
  forndx = getvarindex();
  forvar[forndx] = forvar[forndx] + 1;
  vars[forndx] = forvar[forndx];
  if (tracing) Console.WriteLine("*** " + (forndx + 'a') + " = " + vars[forndx]);
  if (forvar[forndx] <= forlimit[forndx]) {
    curline = forline[forndx];
    textp   = forpos[forndx];
    //print "nextstmt tok>"; tok; " textp>"; textp; " >"; mid$(thelin, textp)
    initlex2();
  } else {
    nexttok(); //' skip the ident for now
  }
}

// "print" expr { "," expr }] [","] {":" stmt} eol
// expr can also be a literal string
static void printstmt() {
  int printwidth;
  string junk;
  bool printnl = true;

  while (tok != ":" && tok != "") {
    printnl = true;
    printwidth = 0;
    if (accept("#")) {
      if (num <= 0) { Console.WriteLine("Expecting a print width, found:" + tok); return; }
      printwidth = num;
      nexttok();
      if (!accept(",")) { Console.WriteLine("Print: Expecting a ',', found:" + tok); return; }
    }

    if (toktype == "string") {
      junk = tok.Substring(1);
      nexttok();
    } else {
      junk = expression(0).ToString();
    }

    printwidth = printwidth - junk.Length;
    if (printwidth <= 0) { Console.Write(junk);} else {Console.Write(" ".PadRight(printwidth) + junk); }

    if (accept(",") || accept(";")) {printnl = false;} else {break; }
  }

  if (printnl) Console.WriteLine("");
}

static void returnstmt() {    // return from a subroutine
  curline = gstackln.Pop();
  textp   = gstacktp.Pop();
  initlex2();
}

static void runstmt() {
  timestart = (DateTime.UtcNow - new DateTime(1970, 1, 1));
  clearvars();
  initlex(1);
}

static void gotostmt() {
  num = expression(0);
  validlinenum();
  initlex(num);
}

static void savestmt() {
  int i;
  string filename;
  StreamWriter f;

  filename = getfilename("Save");
  if (filename == "") return;
  f = new StreamWriter(filename, false);
  for (i = 1; i < pgm.Length; i++) {
    if (pgm[i] != "") f.WriteLine(i + " " + pgm[i]);
  }
  f.Close();
}

static string getfilename(string action) {
  string filename;
  if (toktype == "string") {
    filename = tok.Substring(1);
  } else {
    Console.Write(action + ": ");
    filename = Console.ReadLine();
  }
  if (filename == "") return "";
  if (filename.IndexOf(".") == -1) filename += ".bas";
  return filename;
}

static void validlinenum() {
  if (num <= 0 || num >= pgm.Length) {
    Console.WriteLine("Line number out of range");
    errors = true;
  }
}

static void clearvars() {
  int i;
  for(i = 0; i < c_maxvars; i++) {
    vars[i] = 0;
  }
  gstackln.Clear();
  gstacktp.Clear();
}

static int parenexpr() {
  int n;

  expect("(");
  if (errors) return 0;
  n = expression(0);
  expect(")");
  return n;
}

static int expression(int minprec) {
  int n;

  // handle numeric operands - numbers and unary operators
  if (toktype == "number") { n = num; nexttok();
  } else if (tok == "-")   { nexttok(); n = -expression(7);
  } else if (tok == "+")   { nexttok(); n =  expression(7);
  } else if (tok == "not") { nexttok(); n = expression(3); if (n != 0) n = 1;
  } else if (tok == "abs") { nexttok(); n = Math.Abs(parenexpr());
  } else if (tok == "asc") { nexttok(); expect("("); n = tok[1]; nexttok(); expect(")");
  } else if (tok == "rnd" || tok == "irnd") { nexttok(); n = random.Next(1, parenexpr());
  } else if (tok == "sgn") { nexttok(); n = Math.Sign(parenexpr());
  } else if (toktype == "ident") { n = vars[getvarindex()]; nexttok();
  } else if (tok == "@") { nexttok(); n = atarry[parenexpr()];
  } else if (tok == "(") { n =  parenexpr();
  } else {
    Console.WriteLine("syntax error: expecting an operand, found: " + tok);
    errors = true;
    return 0;
  }

  while (true) { // while binary operator and precedence of tok >= minprec
    if (minprec <= 1 && tok == "or") { nexttok(); n = n | expression(2);
    } else if (minprec <= 2 && tok == "and") { nexttok(); n = n & expression(3);
    } else if (minprec <= 4 && tok == "=" )  { nexttok(); n = Convert.ToInt32(n == expression(5));
    } else if (minprec <= 4 && tok == "<" )  { nexttok(); n = Convert.ToInt32(n <  expression(5));
    } else if (minprec <= 4 && tok == ">" )  { nexttok(); n = Convert.ToInt32(n >  expression(5));
    } else if (minprec <= 4 && tok == "<>")  { nexttok(); n = Convert.ToInt32(n != expression(5));
    } else if (minprec <= 4 && tok == "<=")  { nexttok(); n = Convert.ToInt32(n <= expression(5));
    } else if (minprec <= 4 && tok == ">=")  { nexttok(); n = Convert.ToInt32(n >= expression(5));
    } else if (minprec <= 5 && tok == "+" )  { nexttok(); n = n + expression(6);
    } else if (minprec <= 5 && tok == "-" )  { nexttok(); n = n - expression(6);
    } else if (minprec <= 6 && tok == "*" )  { nexttok(); n = n * expression(7);
    } else if (minprec <= 6 && (tok == "/" || tok == "\\")) { nexttok(); n = n / expression(7);
    } else if (minprec <= 6 && tok == "mod") { nexttok(); n = n % expression(7);
    } else if (minprec <= 8 && tok == "^") { nexttok(); n = (int)Math.Pow(n, expression(9));
    } else { break; }
  }
  return n;
}

static int getvarindex() {
  if (toktype != "ident") {
    Console.WriteLine("Not a variable:" + tok);
    errors = true;
    return 0;
  }
  return tok[0] - 'a';
}

static void expect(string s) {
  if (accept(s)) return;
  Console.WriteLine("(" + curline + ") expecting " + s + " but found " + tok + " =>" + pgm[curline]);
  errors = true;
}

static bool accept(string s) {
  if (tok == s) {
    nexttok();
    return true;
  }
  return false;
}

static void initlex(int n) {
  curline = n;
  textp = 1;
  initlex2();
}

static void initlex2() {
  thelin = pgm[curline];
  thech = " ";
  nexttok();
}

static void skiptoeol() {
  tok = ""; toktype = "";
  textp = thelin.Length + 1;
}

static void nexttok() {
  tok = ""; toktype = "";
  for (;;) {
    if (thech == "") return;
    if (thech[0] > ' ') break;
    getch();
  }

  tok = thech;
  if (Char.IsLetter(tok[0])) {
    readident();
    if (tok == "rem") skiptoeol();
  } else if (Char.IsDigit(tok[0])) {
    readint();
  } else if (tok == "'") {
    skiptoeol();
  } else if (tok == "\"") {    // double quote - sstring
    readstr();
  } else {
    if ("#()*+,-/:;<=>?@\\^".IndexOf(tok) >= 0) {
      toktype = "punct";
      getch();
      if (tok == "<" || tok == ">") {
        if (thech == "=" || thech == ">") {
          tok = tok + thech;
          getch();
        }
      }
    } else {
      Console.WriteLine("What?" + thech + thelin);
      getch();
      errors = true;
    }
  }
}

// leave the " as the beginning of the string, so it won't get confused with other tokens
// especially in the print routines
static void readstr() {
  toktype = "string";
  getch();
  while (thech != "\"") {  // while not a double quote
    if (thech == "") {
      Console.WriteLine("String not terminated");
      errors = true;
      return;
    }
    tok = tok + thech;
    getch();
  }
  getch();
}

static void readint() {
  tok = ""; toktype = "number";
  while (thech != "" && Char.IsDigit(thech[0])) {
    tok += thech;
    getch();
  }
  num = Int32.Parse(tok);
}

static void readident() {
  tok = ""; toktype = "ident";
  while (thech != "" && Char.IsLetter(thech[0])) {
    tok = tok + thech.ToLower();
    getch();
  }
}

static void getch() {  // Any more text on this line?
  if (textp > thelin.Length) {
    thech = "";
    return;
  }
  thech = thelin[textp - 1].ToString();
  textp++;
}

}
