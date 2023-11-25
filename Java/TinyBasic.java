// Ed Davis. Tiny Basic that can play Star Trek
// Supports: end, list, load, new, run, save
// gosub/return, goto, if, input, print, multi-statement lines (:)
// a single numeric array: @(n), and rnd(n)

import java.io.Console;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.FileWriter;
import java.io.PrintWriter;
import java.lang.Math;
import java.util.*;
import java.util.Random;
import java.util.Scanner;

public class TinyBasic {

  private static final int c_maxlines = 7000;
  private static final int c_maxvars = 26;
  private static final int c_at_max = 1000;

  private static String[] pgm = new String[c_maxlines + 1]; // program stored here
  private static int[] vars = new int[c_maxvars + 1];     // variable store
  private static int[] atarry = new int[c_at_max];      // the @ array
  private static Stack<Integer> gstackln = new Stack<>();
  private static Stack<Integer> gstacktp = new Stack<>();
  private static int[] forvar = new int[c_maxvars];
  private static int[] forlimit = new int[c_maxvars];
  private static int[] forline = new int[c_maxvars];
  private static int[] forpos = new int[c_maxvars];

  private static String tok;
  private static String toktype;
  private static String thelin;
  private static String thech;
  private static int curline;
  private static int textp;
  private static int num;
  private static boolean errors;
  private static boolean tracing;
  private static Random random = new Random();

  public static void main(String[] args) {
    Console console = System.console();
    newstmt();
    if (args.length > 0) {
        toktype = "string"; tok = "\"" + args[0];
        loadstmt();
        tok = "run"; docmd();
    } else
        help();
    while (true) {
      errors = false;
      pgm[0] = console.readLine("Java> ");
      if (pgm[0] != null && !pgm[0].isEmpty()) {
        initlex(0);
        if (toktype.equals("number")) {
          validlinenum();
          pgm[num] = pgm[0].substring(textp - 1);
        } else {
          docmd();
        }
      }
    }
  }

  public static void docmd() {
    while (true) {
      if (tracing && !tok.equals(":")) System.out.println("[" + curline + "] " + tok + " " + thelin.substring(textp - 1));
      switch (tok) {
        case "bye": case "quit": nexttok(); System.exit(1); break;
        case "end": case "stop": nexttok();          return;
        case "clear"       : nexttok(); clearstmt(); return;
        case "help"        : nexttok(); help();      return;
        case "list"        : nexttok(); liststmt();  return;
        case "load"        : nexttok(); loadstmt();  return;
        case "new"         : nexttok(); newstmt();   return;
        case "run"         : nexttok(); runstmt(); break;
        case "save"        : nexttok(); savestmt();  return;
        case "tron"        : nexttok(); tracing = true; break;
        case "troff"       : nexttok(); tracing = false; break;
        case "cls"         : nexttok(); /* java can't do this portably */ break;
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
          if (tok.equals("let")) nexttok();
          if (toktype.equals("ident")) {
            assign();
          } else {
            System.out.println("Unknown token " + tok + " at line " + curline); errors = true;
          }
          break;
      }

      if (errors) return;
      if (curline + 1 >= pgm.length) {
        return;
      }
      while (tok.isEmpty()) {
        if (curline == 0 || curline + 1 >= pgm.length) {
          return;
        }
        initlex(curline + 1);
      }
    }
  }

  public static void help() {
    System.out.println("+---------------------- Tiny Basic Help (Java)------------------------+" );
    System.out.println("| bye, clear, end, help, list, load, new, run, save, stop             |");
    System.out.println("| goto <expr>                                                         |");
    System.out.println("| gosub <expr> ... return                                             |");
    System.out.println("| if <expr> then <statement>                                          |");
    System.out.println("| input [prompt,] <var>                                               |");
    System.out.println("| <var>=<expr>                                                        |");
    System.out.println("| print <expr|string>[,<expr|string>][;]                              |");
    System.out.println("| rem <anystring>                                                     |");
    System.out.println("| Operators: + - * / < <= > >= <> =                                   |");
    System.out.println("| Integer variables a..z, and array @(expr)                           |");
    System.out.println("| Functions: rnd(expr)                                                |");
    System.out.println("+---------------------- Tiny Basic Help ------------------------------+" );
  }

  public static void assign() {
    int var;
    var = getvarindex();
    nexttok();
    expect("=");
    vars[var] = expression(0);
    if (tracing) System.out.println("*** " + (char)(var + 'a') + " = " + vars[var]);
  }

  public static void arrassn() {
    int n, atndx;

    atndx = parenexpr();
    if (!tok.equals("=")) {
      System.out.println("Array Assign: Expecting '=', found: " + tok);
      errors = true;
    } else {
      nexttok();     // skip the "="
      n = expression(0);
      atarry[atndx] = n;
      if (tracing) System.out.println("*** @(" + atndx + ") = " + n);
    }
  }

  public static void clearstmt() {
    for(int i = 0; i < c_maxvars; i++) {
      vars[i] = 0;
    }
    gstackln.clear();
    gstacktp.clear();
  }

  public static void forstmt() {
    int var, forndx, n;

    var = getvarindex();
    assign();
    // vars(var) has the value; var has the number value of the variable in 0..25
    forndx = var;
    forvar[forndx] = vars[var];
    if (!tok.equals("to")) {
      System.out.println("For: Expecting 'to', found:" + tok); errors = true;
    } else {
      nexttok();
      n = expression(0);
      forlimit[forndx] = n;
      // need to store iter, limit, line, and col
      forline[forndx] = curline;
      if (tok.isEmpty()) forpos[forndx] = textp; else forpos[forndx] = textp - 2;
    }
  }

  public static void gosubstmt() {
    num = expression(0);
    gstackln.push(curline);
    if (tok.isEmpty()) gstacktp.push(textp); else gstacktp.push(textp - 2);
    validlinenum();
    initlex(num);
  }

  public static void gotostmt() {
    num = expression(0);
    validlinenum();
    initlex(num);
  }

  public static void ifstmt() {
    if (expression(0) == 0) {
      skiptoeol();
    } else {
      if (tok.equals("then")) nexttok();      // "then" is optional
      if (toktype.equals("number")) gotostmt();
    }
  }

  public static void inputstmt() {
    int var;
    String st = "? ";
    Console console = System.console();
    if (toktype.equals("string")) {
      st = tok.substring(1);
      nexttok();
      expect(",");
    }
    var = getvarindex();
    nexttok();
    st = console.readLine(st);
    if (st == null || st.isEmpty()) st = "0";
    if (Character.isDigit(st.charAt(0))) {
      vars[var] = Integer.parseInt(st);
    } else {
      vars[var] = (int)(st.charAt(0)); // turn characters into their ascii value
    }
  }

  public static void liststmt() {
    for (int i = 1; i < pgm.length; i++) {
      if (!pgm[i].isEmpty()) System.out.println(i + " " + pgm[i]);
    }
    System.out.println("");
  }

  public static void loadstmt() {
    int n;
    String filename;

    filename = getfilename("Load");
    if (filename.isEmpty()) return;
    newstmt();

    try {
      Scanner scanner = new Scanner(new File(filename));
      n = 0;
      while (scanner.hasNextLine()) {
        pgm[0] = scanner.nextLine();
        if (pgm[0] == null) break;
        initlex(0);
        if (toktype.equals("number") && num > 0 && num <= pgm.length) {
          pgm[num] = pgm[0].substring(textp - 1);
          n = num;
        } else {
          n++;
          pgm[n] = pgm[0];
        }
      }
      scanner.close();
    } catch (FileNotFoundException ex) {
      System.out.println(filename + " not found");
    }
    curline = 0;
  }

  public static void newstmt() {
    clearstmt();
    for (int i = 1; i < pgm.length; i++) {
      pgm[i] = "";
    }
  }

  public static void nextstmt() {
    int forndx;

    // tok needs to have the variable
    forndx = getvarindex();
    forvar[forndx] = forvar[forndx] + 1;
    vars[forndx] = forvar[forndx];
    if (tracing) System.out.println("*** " + (forndx + 'a') + " = " + vars[forndx]);
    if (forvar[forndx] <= forlimit[forndx]) {
      curline = forline[forndx];
      textp   = forpos[forndx];
      //print "nextstmt tok>"; tok; " textp>"; textp; " >"; mid$(thelin, textp)
      initlex2();
    } else {
      nexttok(); // skip the ident for now
      if (!tok.isEmpty() && !tok.equals(":")) {
        System.out.println("Next: expected ':' before statement, but found:" + tok);
        errors = true;
      }
    }
  }

  public static String spaces(int n) {
    String s = "";
    for (int i = 0; i < n; ++i) {
      s += " ";
    }
    return s;
  }

  public static void printstmt() {
    int printwidth;
    String junk;
    boolean printnl = true;

    while (!tok.equals(":") && !tok.isEmpty()) {
      printnl = true;
      printwidth = 0;
      if (accept("#")) {
        if (num <= 0) { System.out.println("Expecting a print width, found:" + tok); return; }
        printwidth = num;
        nexttok();
        if (!accept(",")) { System.out.println("Print: Expecting a ',', found:" + tok); return; }
      }

      if (toktype.equals("string")) {
        junk = tok.substring(1);
        nexttok();
      } else {
        junk = Integer.toString(expression(0));
      }

      printwidth = printwidth - junk.length();
      if (printwidth <= 0) { System.out.print(junk);} else {System.out.print(spaces(printwidth) + junk); }

      if (accept(",") || accept(";")) {printnl = false;} else {break; }
    }

    if (printnl) System.out.println("");
  }

  public static void returnstmt() {
    curline = gstackln.pop();
    textp   = gstacktp.pop();
    initlex2();
    if (!tok.isEmpty() && !tok.equals(":")) {
      System.out.println("Return: expected ':' before statement, but found:" + tok);
      errors = true;
    }
  }

  public static void runstmt() {
    if (toktype.equals("string")) loadstmt();
    clearstmt();
    initlex(1);
  }

  public static void savestmt() {
    String filename;

    filename = getfilename("Save");
    if (filename.isEmpty()) return;

    try {
      PrintWriter pw = new PrintWriter(new FileWriter(filename));
      for (int i = 1; i < pgm.length; i++) {
        if (!pgm[i].isEmpty()) pw.println(i + " " + pgm[i]);
      }
      pw.close();
    }  catch (IOException e) {
      System.out.println("Error writing file");
    }
  }

  public static String getfilename(String action) {
    String filename;
    Console console = System.console();
    if (toktype.equals("string")) {
      filename = tok.substring(1);
    } else {
      filename = console.readLine(action + ": ");
    }
    if (filename == null || filename.isEmpty()) return "";
    if (!filename.contains(".")) filename += ".bas";
    return filename;
  }

  public static void validlinenum() {
    if (num <= 0 || num >= pgm.length) {
      System.out.println("Line number out of range");
      errors = true;
    }
  }

  public static int parenexpr() {
    int n;

    expect("(");
    if (errors) return 0;
    n = expression(0);
    expect(")");
    return n;
  }

  public static int expression(int minprec) {
    int n;

    // handle numeric operands - numbers and unary operators
    if (toktype.equals("number")) { n = num; nexttok();
    } else if (tok.equals("-"))   { nexttok(); n = -expression(7);
    } else if (tok.equals("+"))   { nexttok(); n =  expression(7);
    } else if (tok.equals("not")) { nexttok(); n = expression(3); if (n != 0) n = 1;
    } else if (tok.equals("abs")) { nexttok(); n = Math.abs(parenexpr());
    } else if (tok.equals("asc")) { nexttok(); expect("("); n = tok.charAt(1); nexttok(); expect(")");
    } else if (tok.equals("rnd") || tok.equals("irnd")) { nexttok(); n = random.nextInt(parenexpr()) + 1;
    } else if (tok.equals("sgn")) { nexttok(); n = (int)Math.signum(parenexpr());
    } else if (toktype.equals("ident")) { n = vars[getvarindex()]; nexttok();
    } else if (tok.equals("@")) { nexttok(); n = atarry[parenexpr()];
    } else if (tok.equals("(")) { n =  parenexpr();
    } else {
      System.out.println("syntax error: expecting an operand, found: " + tok);
      errors = true;
      return 0;
    }

    while (true) { // while binary operator and precedence of tok >= minprec
      if (minprec <= 1 && tok.equals("or")) { nexttok(); n = n | expression(2);
      } else if (minprec <= 2 && tok.equals("and")) { nexttok(); n = n & expression(3);
      } else if (minprec <= 4 && tok.equals("=") )  { nexttok(); n = (n == expression(5)) ? 1: 0;
      } else if (minprec <= 4 && tok.equals("<") )  { nexttok(); n = (n <  expression(5)) ? 1: 0;
      } else if (minprec <= 4 && tok.equals(">") )  { nexttok(); n = (n >  expression(5)) ? 1: 0;
      } else if (minprec <= 4 && tok.equals("<>"))  { nexttok(); n = (n != expression(5)) ? 1: 0;
      } else if (minprec <= 4 && tok.equals("<="))  { nexttok(); n = (n <= expression(5)) ? 1: 0;
      } else if (minprec <= 4 && tok.equals(">="))  { nexttok(); n = (n >= expression(5)) ? 1: 0;
      } else if (minprec <= 5 && tok.equals("+") )  { nexttok(); n = n + expression(6);
      } else if (minprec <= 5 && tok.equals("-") )  { nexttok(); n = n - expression(6);
      } else if (minprec <= 6 && tok.equals("*") )  { nexttok(); n = n * expression(7);
      } else if (minprec <= 6 && (tok.equals("/") || tok.equals("\\"))) { nexttok(); n = n / expression(7);
      } else if (minprec <= 6 && tok.equals("mod")) { nexttok(); n = n % expression(7);
      } else if (minprec <= 8 && tok.equals("^")) { nexttok(); n = (int)Math.pow(n, expression(9));
      } else { break; }
    }
    return n;
  }

  public static int getvarindex() {
    if (!toktype.equals("ident")) {
      System.out.println("Not a variable:" + tok);
      errors = true;
      return 0;
    }
    return tok.charAt(0) - 'a';
  }

  public static void expect(String s) {
  if (accept(s)) return;
  System.out.println("(" + curline + ") expecting " + s + " but found " + tok + " =>" + pgm[curline]);
  errors = true;
  }

  public static boolean accept(String s) {
    if (tok.equals(s)) {
      nexttok();
      return true;
    }
    return false;
  }

  public static void initlex(int n) {
    curline = n; textp = 1;
    initlex2();
  }

  public static void initlex2() {
    thelin = pgm[curline];
    thech = " ";
    nexttok();
  }

  public static void nexttok() {
    tok = ""; toktype = "";
    for (;;) {
      if (thech.isEmpty()) return;
      if (thech.charAt(0) > ' ') break;
      getch();
    }

    tok = thech;
    if (Character.isLetter(tok.charAt(0))) {
      readident();
      if (tok.equals("rem")) skiptoeol();
    } else if (Character.isDigit(tok.charAt(0))) {
      readint();
    } else if (tok.equals("'")) {
      skiptoeol();
    } else if (tok.equals("\"")) {    // double quote - sstring
      readstr();
    } else {
      if ("#()*+,-/:;<=>?@\\^".contains(tok.substring(0, 1))) {
        toktype = "punct";
        getch();
        if (tok.equals("<") || tok.equals(">")) {
          if (thech.equals("=") || thech.equals(">")) {
            tok = tok + thech;
            getch();
          }
        }
      } else {
        System.out.println("What?" + thech + thelin);
        getch();
        errors = true;
      }
    }
  }

  public static void skiptoeol() {
    tok = ""; toktype = "";
    textp = thelin.length() + 1;
  }

  public static void readint() {
    tok = ""; toktype = "number";
    while (!thech.isEmpty() && Character.isDigit(thech.charAt(0))) {
      tok += thech;
      getch();
    }
    num = Integer.parseInt(tok);
  }

  public static void readident() {
    tok = ""; toktype = "ident";
    while (!thech.isEmpty() && Character.isLetterOrDigit(thech.charAt(0))) {
      tok = tok + thech.toLowerCase();
      getch();
    }
  }

  public static void readstr() {
    toktype = "string";
    getch();
    while (!thech.equals("\"")) {  // while not a double quote
      if (thech.isEmpty()) {
        System.out.println("String not terminated");
        errors = true;
        return;
      }
      tok = tok + thech;
      getch();
    }
    getch();
  }

  public static void getch() {
    if (textp > thelin.length()) {
      thech = "";
    } else {
      thech = thelin.substring(textp - 1, textp);
      textp++;
    }
  }
}

