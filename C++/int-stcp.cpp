/*
 Ed Davis. Tiny Basic that can play Star Trek
 Supports: end, list, load, new, run, save
 gosub/return, goto, if, input, print, multi-statement lines (:)
 a single numeric array: @(n), and rnd(n)

 Supports an interactive mode.

 Note that this is a pure interpreter, e.g., no pre token stream or intermediate form.

 g++ -Wall -Wextra -Wpedantic -s -Os int-stcp.cpp -o int-stcp
*/
#include <cmath>
#include <ctime>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <stack>

using namespace std;

#ifndef CLK_TCK
    #define CLK_TCK CLOCKS_PER_SEC
#endif

enum {c_maxlines = 7000, c_at_max = 1000, c_maxvars = 26};
typedef enum {kNONE, kPUNCT, kIDENT, kNUMBER, kSTRING} toktype_t;

toktype_t toktype;  // type of current token
string tok;         // current token
int num;            // if toktype is number
unsigned textp;     // pointer in current line, 0 based
string thelin;      // current line copied here
char  thech;        // current character
string pgm[c_maxlines+1];
int curline;
bool errors, tracing, need_colon;

stack<int> gln_stack;
stack<int> gtp_stack;

clock_t timestart;

int vars[c_maxvars+1];
int atarry[c_at_max];

int forvar[c_maxvars];
int forlimit[c_maxvars];
int forline[c_maxvars];
int forpos[c_maxvars];

bool   accept(const string s);
void   arrassn(void);
void   assign(void);
void   clearvars(void);
void   docmd(void);
bool   expect(const string s);
int    expression(int minprec);
void   forstmt(void);
void   getch(void);
string getfilename(const string action);
int    getvarindex(void);
void   gosubstmt(void);
void   gotostmt(void);
void   help(void);
void   ifstmt(void);
void   initlex(int n);
void   initlex2(void);
void   inputstmt(void);
void   liststmt(void);
void   loadstmt(void);
void   newstmt(void);
void   nextstmt(void);
void   nexttok(void);
int    parenexpr(void);
void   printstmt(void);
void   readident(void);
void   readint(void);
void   readstr(void);
void   returnstmt(void);
int    rnd(int range);
void   runstmt(void);
void   savestmt(void);
void   showtime(bool running);
void   skiptoeol(void);
int    validlinenum(int n);

int main(int argc, char *argv[]) {
    if (argc > 1) {
        toktype = kSTRING;
        tok = "\"";
        tok += argv[1];
        loadstmt();
        toktype = kIDENT;
        tok = "run";
        docmd();
    } else {
        newstmt();
        help();
    }
    for (;;) {
        errors = false;
        printf("cpp> ");
        getline(cin, pgm[0]);
        if (!pgm[0].empty()) {
            initlex(0);
            if (toktype == kNUMBER) {
                if (validlinenum(num))
                    pgm[num] = pgm[0].substr(textp - 1);
            } else
                docmd();
        }
    }
}

void docmd(void) {
    bool running = false;
    for (;;) {
        need_colon = true;
        if (tracing && tok != ":" && !tok.empty() && textp <= thelin.length())
            printf("[%d] %s %s\n", curline, tok.c_str(), thelin.substr(textp - 1).c_str());
        if        (tok == "bye" || tok == "quit") { nexttok(); exit(0);
        } else if (tok == "end" || tok == "stop") { nexttok(); showtime(running); return;
        } else if (tok == "clear")     { nexttok(); clearvars(); return;
        } else if (tok == "help")      { nexttok(); help(); return;
        } else if (tok == "list")      { nexttok(); liststmt(); return;
        } else if (tok == "load")      { nexttok(); loadstmt(); return;
        } else if (tok == "new")       { nexttok(); newstmt(); return;
        } else if (tok == "run")       { nexttok(); runstmt(); running = true;
        } else if (tok == "save")      { nexttok(); savestmt(); return;
        } else if (tok == "tron")      { nexttok(); tracing = true;
        } else if (tok == "troff")     { nexttok(); tracing = false;
        } else if (tok == "cls")       { nexttok();
        } else if (tok == "for")       { nexttok(); forstmt();
        } else if (tok == "gosub")     { nexttok(); gosubstmt();
        } else if (tok == "goto")      { nexttok(); gotostmt();
        } else if (tok == "if")        { nexttok(); ifstmt();
        } else if (tok == "input")     { nexttok(); inputstmt();
        } else if (tok == "next")      { nexttok(); nextstmt();
        } else if (tok == "let")       { nexttok(); assign();
        } else if (tok == "print" || tok == "?") { nexttok(); printstmt();
        } else if (tok == "return")    { nexttok(); returnstmt();
        } else if (tok == "@")         { nexttok(); arrassn();
        } else if (toktype == kIDENT)  { assign();
        } else if (tok == ":" || tok.empty()) { /* handled below */
        } else {
            printf("(%d, %d) Unknown token %s: %s\n", curline, textp, tok.c_str(), pgm[curline].c_str());
            errors = true;
        }

        if (errors) return;
        if (tok.empty()) {
          while (tok.empty()) {
              if (curline == 0 || curline >= c_maxlines) { showtime(running); return;}
              initlex(curline + 1);
          }
        } else if (tok == ":") { nexttok();
        } else if (need_colon && !expect(":")) { return;
        }
    }
}

void showtime(bool running) {
    if (running) {
        clock_t tt = clock() - timestart;
        printf("Took %.2f seconds\n", (float)(tt)/(float)CLK_TCK);
    }
}

void help(void) {
   puts("+----------------------------------------------------------------------+");
   puts("| bye, clear, cls, end/stop, help, list, load/save, new, run, tron/off |");
   puts("| for <var> = <expr1> to <expr2> ... next <var>                        |");
   puts("| gosub <expr> ... return                                              |");
   puts("| goto <expr>                                                          |");
   puts("| if <expr> then <statement>                                           |");
   puts("| input [prompt,] <var>                                                |");
   puts("| <var>=<expr>                                                         |");
   puts("| print <expr|string>[,<expr|string>][;]                               |");
   puts("| rem <anystring>  or ' <anystring>                                    |");
   puts("| Operators: ^, * / \\ mod + - < <= > >= = <>, not, and, or             |");
   puts("| Integer variables a..z, and array @(expr)                            |");
   puts("| Functions: abs(expr), asc(ch), rnd(expr), sgn(expr)                  |");
   puts("+----------------------------------------------------------------------+");
}

void gosubstmt(void) {      // for gosub: save the line and column
    gln_stack.push(curline);
    gtp_stack.push(textp);

    gotostmt();
}

void assign(void) {
  int var;

  var = getvarindex();
  nexttok();
  expect("=");
  vars[var] = expression(0);
  if (tracing) printf("*** %c = %d\n", var + 'a', vars[var]);
}

void arrassn(void) {        // array assignment: @(expr) {} = expr
    int n, atndx;

    atndx = parenexpr();
    if (!accept("=")) {
        printf("(%d, %d) Array Assign: Expecting '=', found: %s", curline, textp, tok.c_str());
        errors = true;
    } else {
        n = expression(0);
        atarry[atndx] = n;
        if (tracing) printf("*** @(%d) = %d\n", atndx, n);
    }
}

void forstmt(void) {    // for i = expr to expr
    int var, forndx, n;

    var = getvarindex();
    assign();
    // vars(var) has the value; var has the number value of the variable in 0..25
    forndx = var;
    forvar[forndx] = vars[var];
    if (!accept("to")) {
        printf("(%d, %d) For: Expecting 'to', found: %s\n", curline, textp, tok.c_str()); errors = true;
    } else {
        n = expression(0);
        forlimit[forndx] = n;
        // need to store iter, limit, line, and col
        forline[forndx] = curline;
        if (tok.empty()) forpos[forndx] = textp; else forpos[forndx] = textp - 2;
        //forpos[forndx] textp; if (tok != "") forpos[forndx] -=2;
    }
}

void ifstmt(void) {
    need_colon = false;
    if (expression(0) == 0)
        skiptoeol();
    else {
        accept("then");      // "then" is optional
        if (toktype == kNUMBER) gotostmt();
    }
}

void inputstmt(void) {      // "input" [string ","] var
    int var;
    string st;
    char *endp;

    if (toktype == kSTRING) {
        printf("%s", tok.substr(1).c_str());
        nexttok();
        expect(",");
    } else
        printf("? ");
    var = getvarindex();
    nexttok();
    getline(cin, st);
    if (st.empty())
        vars[var] = 0;
    else if (isdigit(st[0]))
        vars[var] = strtol(st.c_str(), &endp, 10);
    else
        vars[var] = st[0]; // turn characters into their ascii value
}

void liststmt(void) {
    for (int i = 1; i < c_maxlines; ++i) {
        if (!pgm[i].empty())
            printf("%d %s\n", i, pgm[i].c_str());
    }
    printf("\n");
}

void loadstmt(void) {
    int n;
    string filename;

    newstmt();
    filename = getfilename("Load");
    if (filename.empty()) return;

    ifstream infile(filename.c_str());
    if (!infile) return;

    n = 0;
    while (getline(infile, pgm[0])) {
        initlex(0);
        if (toktype == kNUMBER && validlinenum(num)) {
            pgm[num] = pgm[0].substr(textp - 1);
            n = num;
        } else {
            n++;
            pgm[n] = pgm[0];
        }
    }
    infile.close();
    curline = 0;
}

void newstmt(void) {
    clearvars();
    for (int i = 0; i < c_maxlines; ++i) pgm[i].clear();
}

void nextstmt(void) {
    int forndx;

    // tok needs to have the variable
    forndx = getvarindex();
    forvar[forndx] = forvar[forndx] + 1;
    vars[forndx] = forvar[forndx];
    if (tracing) printf("*** %c = %d\n", forndx + 'a', vars[forndx]);
    if (forvar[forndx] <= forlimit[forndx]) {
        curline = forline[forndx];
        textp   = forpos[forndx];
        initlex2();
    } else
        nexttok(); //' skip the ident for now
}

void printstmt(void) {
    int printwidth, printnl = true;

    while (tok != ":" && !tok.empty()) {
        printnl = true;
        printwidth = 0;

        if (accept("#")) {
            if (num <= 0) {printf("Expecting a print width, found: %s\n", pgm[curline].c_str()); return;}
            printwidth = num;
            nexttok();
            if (!accept(",")) {printf("Print: Expecting a ',', found: %s\n", pgm[curline].c_str()); return;}
        }

        if (toktype == kSTRING) {
            printf("%*s", printwidth, tok.substr(1).c_str());
            nexttok();
        } else {
            printf("%*d", printwidth, expression(0));
        }

        if (accept(",") || accept(";")) {printnl = false;} else {break; }
    }
    if (printnl) printf("\n");
}

void returnstmt(void) {     // return from a subroutine
    curline = gln_stack.top(); gln_stack.pop();
    textp   = gtp_stack.top(); gtp_stack.pop();
    initlex2();
}

void runstmt(void) {
    timestart = clock();
    clearvars();
    initlex(1);
}

void gotostmt(void) {
    int n = expression(0);
    if (validlinenum(n)) initlex(n);
}

void savestmt(void) {
    string filename;

    filename = getfilename("Load");
    if (filename.empty()) return;

    ofstream outfile(filename.c_str());
    if (!outfile) return;

    for (int i = 1; i < c_maxlines; ++i) {
        if (!pgm[i].empty()) {
            outfile << i << " " << pgm[i] << endl;
        }
    }
    outfile.close();
}

string getfilename(const string action) {
    string filename;

    if (toktype == kSTRING)
        filename = tok.substr(1);
    else {
        printf("%s: ", action.c_str());
        getline(cin, filename);
    }
    if (filename.empty()) return filename;

    if (filename.find(".") == string::npos)
        filename += ".bas";

    return filename;
}

int validlinenum(int n) {
    if (n <= 0 || n > c_maxlines) {
        printf("(%d, %d) Line number out of range", curline, textp);
        errors = true; return false;
    }
    return true;
}

void clearvars(void) {
    for (int i = 0; i < c_maxvars; ++i) vars[i] = 0;
    while (!gln_stack.empty()) gln_stack.pop();
    while (!gtp_stack.empty()) gtp_stack.pop();
}

int getvarindex(void) {
    if (toktype != kIDENT) {
        printf("(%d, %d) Not a variable: %s\n", curline, textp, thelin.c_str());
        errors = true;
        return 0;
    }
    return tok[0] - 'a';
}

bool expect(const string s) {
    if (!accept(s)) {
        printf("(%d, %d) Expecting %s, but found %s, %s\n", curline, textp, s.c_str(), tok.c_str(), thelin.c_str());
        return errors = true;
    }
    return false;
}

bool accept(const string s) {
    if (tok == s) { nexttok(); return true;}
    return false;
}

int expression(int minprec) {
    int n = 0;

    // handle numeric operands, unary operators, functions, variables
    if        (toktype == kNUMBER) { n = num; nexttok();
    } else if (tok == "-")         { nexttok(); n = -expression(7);
    } else if (tok == "+")         { nexttok(); n =  expression(7);
    } else if (tok == "not")       { nexttok(); n = !expression(3);
    } else if (tok == "abs")       { nexttok(); n = abs(parenexpr());
    } else if (tok == "asc")       { nexttok(); expect("("); n = tok[1]; nexttok(); expect(")");
    } else if (tok == "rnd" || tok == "irnd" ) { nexttok(); n = rnd(parenexpr());
    } else if (tok == "sgn")       { nexttok(); n = parenexpr(); n = (n > 0) - (n < 0);
    } else if (toktype == kIDENT)  { n = vars[getvarindex()]; nexttok();
    } else if (tok == "@")         { nexttok(); n = atarry[parenexpr()];
    } else if (tok == "(")         { n = parenexpr();
    } else {
        printf("(%d, %d) Syntax error: expecting an operand, found: %s toktype: %d\n", curline, textp, tok.c_str(), toktype);
        return n;
    }

    for (;;) {  // while binary operator and precedence of tok >= minprec
        if        (minprec <= 1 && tok == "or")  { nexttok(); n = n | expression(2);
        } else if (minprec <= 2 && tok == "and") { nexttok(); n = n & expression(3);
        } else if (minprec <= 4 && tok == "=")   { nexttok(); n = n == expression(5);
        } else if (minprec <= 4 && tok == "<")   { nexttok(); n = n <  expression(5);
        } else if (minprec <= 4 && tok == ">")   { nexttok(); n = n >  expression(5);
        } else if (minprec <= 4 && tok == "<>")  { nexttok(); n = n != expression(5);
        } else if (minprec <= 4 && tok == "<=")  { nexttok(); n = n <= expression(5);
        } else if (minprec <= 4 && tok == ">=")  { nexttok(); n = n >= expression(5);
        } else if (minprec <= 5 && tok == "+")   { nexttok(); n += expression(6);
        } else if (minprec <= 5 && tok == "-")   { nexttok(); n -= expression(6);
        } else if (minprec <= 6 && tok == "*")   { nexttok(); n *= expression(7);
        } else if (minprec <= 6 && tok == "/")   { nexttok(); n /= expression(7);
        } else if (minprec <= 6 && tok == "\\")  { nexttok(); n /= expression(7);
        } else if (minprec <= 6 && tok == "mod") { nexttok(); n %= expression(7);
        } else if (minprec <= 8 && tok == "^")   { nexttok(); n = pow(n, expression(9));
        } else { break; }
    }
    return n;
}

int parenexpr(void) {
    int n = 0;

    if (!accept("(")) {
        printf("(%d, %d) Paren Expr: Expecting '(', found: %s\n", curline, textp, tok.c_str());
    } else {
        n = expression(0);
        if (!accept(")")) {
            printf("(%d, %d) Paren Expr: Expecting ')', found: %s\n", curline, textp, tok.c_str());
        }
    }
    return n;
}

int rnd(int range) {
    return rand() % range + 1;
}

void initlex(int n) {
    curline = n;
    textp = 1;
    initlex2();
}

void initlex2(void) {
    need_colon = false;
    thelin = pgm[curline];
    thech = ' ';
    nexttok();
}

void nexttok(void) {
    static string punct = "#()*+,-/:;<=>?@\\^";
    toktype = kNONE;
    begin: tok = thech; getch();
    if (tok[0] == '\0') { tok.clear();
    } else if (isspace(tok[0])) { goto begin;
    } else if (isalpha(tok[0])) { readident(); if (tok == "rem") skiptoeol();
    } else if (isdigit(tok[0])) { readint();
    } else if (tok[0] == '"')   { readstr();
    } else if (tok[0] == '\'')  { skiptoeol();
    } else if (punct.find(tok[0]) != string::npos) {
        toktype = kPUNCT;
        if ((tok[0] == '<' && (thech == '>' || thech == '=')) || (tok[0] == '>' && thech == '=')) {
            tok += thech;
            getch();
        }
    } else {
        printf("(%d, %d) What? %c (%d) %s\n", curline, textp, tok[0], tok[0], thelin.c_str());
        getch();
        errors = true;
    }
}

void skiptoeol(void) {
    tok.clear(); toktype = kNONE;
    textp = thelin.length() + 1;
}

// store double quote as first char of string, to distinguish from idents
void readstr(void) {
    toktype = kSTRING;
    while (thech != '"') {
        if (thech == '\0') {
            printf("(%d, %d) String not terminated\n", curline, textp);
            errors = true;
            return;
        }
        tok += thech;
        getch();
    }
    getch();
}

void readint(void) {
    char *endp;
    toktype = kNUMBER;
    while (isdigit(thech)) {
        tok += thech;
        getch();
    }
    num = strtol(tok.c_str(), &endp, 10);
}

void readident(void) {
    tok[0] = tolower(tok[0]); toktype = kIDENT;
    while (isalnum(thech)) {
        tok += tolower(thech);
        getch();
    }
}

void getch(void) {
    if (thelin.empty() || textp > thelin.length()) {
        thech = '\0';
    } else {
        thech = thelin[textp - 1];
        textp++;
    }
}
