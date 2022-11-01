/*
'Ed Davis. Tiny Basic that can play Star Trek
'Supports: end, list, load, new, run, save
'gosub/return, goto, if, input, print, multi-statement lines (:)
'a single numeric array: @(n), and rnd(n)

gcc -Wall -Wextra -Wpedantic -s -Os int-stc.c -o int-stc
*/
#include <ctype.h>
#include <math.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#ifndef CLK_TCK
    #define CLK_TCK CLOCKS_PER_SEC
#endif

#define streql(s1, s2) (strcmp(s1, s2) == 0)
#define strneq(s1, s2) (strcmp(s1, s2))

enum {c_maxlines = 7000, c_at_max = 1000, c_maxvars = 26, c_g_stack = 100};
typedef enum {kNONE, kPUNCT, kIDENT, kNUMBER, kSTRING} toktype_t;

char tok[1024];
toktype_t toktype;
int num;
unsigned textp;
char *thelin;
char  thech;
char *pgm[c_maxlines+1];
int curline;
bool errors, tracing, need_colon;
int gsp;
int gstackln[c_g_stack];    // gosub line stack
int gstacktp[c_g_stack];    // gosub textp stack
clock_t timestart;

int vars[c_maxvars+1];
int atarry[c_at_max];

int forvar[c_maxvars];
int forlimit[c_maxvars];
int forline[c_maxvars];
int forpos[c_maxvars];

bool  accept(const char *s);
void  arrassn(void);
void  assign(void);
void  clearvars(void);
void  docmd(void);
bool  expect(const char *s);
int   expression(int minprec);
void  forstmt(void);
void  getch(void);
char *getfilename(char action[]);
int   getvarindex(void);
void  gosubstmt(void);
void  gotostmt(void);
void  help(void);
void  ifstmt(void);
void  initlex(int n);
void  initlex2(void);
void  inputstmt(void);
void  liststmt(void);
void  loadstmt(void);
char *mygetline(FILE *fp);
void  newstmt(void);
void  nextstmt(void);
void  nexttok(void);
int   parenexpr(void);
void  printstmt(void);
void  readident(void);
void  readint(void);
void  readstr(void);
void  returnstmt(void);
int   rnd(int range);
void  runstmt(void);
void  savestmt(void);
void  showtime(bool running);
void  skiptoeol(void);
bool  validlinenum(void);

int main(int argc, char *argv[]) {
    if (argc > 1) {
        toktype = kSTRING;
        sprintf(tok, "\"%s", argv[1]);
        loadstmt();
        toktype = kIDENT;
        strcpy(tok, "run");
        docmd();
    } else {
        newstmt();
        help();
    }
    for (;;) {
        errors = false;
        printf("c> ");
        if (pgm[0]) free(pgm[0]);
        pgm[0] = mygetline(stdin);
        if (pgm[0] && pgm[0][0] != '\0') {
            initlex(0);
            if (toktype == kNUMBER) {
                if (validlinenum())
                    pgm[num] = strdup(pgm[0] + textp);
            } else
                docmd();
        }
    }
}

void docmd(void) {
    bool running = false;
    for (;;) {
        need_colon = true;
        if (tracing && tok[0] != ':' && thelin && textp < strlen(thelin))
            printf("[%d] %s\n", curline, &thelin[textp - 1]);
        if (accept("bye") || accept("quit")) { exit(0);
        } else if (accept("end") || accept("stop")) { showtime(running); return;
        } else if (accept("clear"))     { clearvars(); return;
        } else if (accept("help"))      { help(); return;
        } else if (accept("list"))      { liststmt(); return;
        } else if (accept("load"))      { loadstmt(); return;
        } else if (accept("new"))       { newstmt(); return;
        } else if (accept("run"))       { runstmt(); running = true; need_colon = false;
        } else if (accept("save"))      { savestmt(); return;
        } else if (accept("tron"))      { tracing = true;
        } else if (accept("troff"))     { tracing = false;
        } else if (accept("cls"))       { ;
        } else if (accept("for"))       { forstmt();
        } else if (accept("gosub"))     { gosubstmt();
        } else if (accept("goto"))      { gotostmt();
        } else if (accept("if"))        { ifstmt();
        } else if (accept("input"))     { inputstmt();
        } else if (accept("next"))      { nextstmt();
        } else if (accept("let"))       { assign();
        } else if (accept("print") || accept("?")) { printstmt();
        } else if (accept("return"))    { returnstmt();
        } else if (accept("@"))         { arrassn();
        } else if (toktype == kIDENT)   { assign();
        } else if (tok[0] == ':' || tok[0] == '\0') { /* handled below */
        } else {
            printf("(%d, %d) Unknown token %s: %s\n", curline, textp, tok, pgm[curline]);
            errors = true;
        }

        if (errors) return;
        if (tok[0] == '\0') {
          while (tok[0] == '\0') {
              if (curline == 0 || curline >= c_maxlines) { showtime(running); return;}
              initlex(curline + 1);
          }
        } else if (tok[0] == ':') { nexttok();
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
    gsp++;
    gstackln[gsp] = curline;
    gstacktp[gsp] = textp;
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
        printf("(%d, %d) Array Assign: Expecting '=', found: %s", curline, textp, tok);
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
        printf("(%d, %d) For: Expecting 'to', found: %s\n", curline, textp, tok); errors = true;
    } else {
        n = expression(0);
        forlimit[forndx] = n;
        // need to store iter, limit, line, and col
        forline[forndx] = curline;
        if (tok[0] == '\0') forpos[forndx] = textp; else forpos[forndx] = textp - 2;
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
    char *st, *endp;

    if (toktype == kSTRING) {
        printf("%s", &tok[1]);
        nexttok();
        expect(",");
    } else
        printf("? ");
    var = getvarindex();
    nexttok();
    st = mygetline(stdin);
    if (!st || st[0] == '\0')
        vars[var] = 0;
    else if (isdigit(st[0]))
        vars[var] = strtol(st, &endp, 10);
    else
        vars[var] = st[0]; // turn characters into their ascii value
    free(st);
}

void liststmt(void) {
    int i;

    for (i = 1; i < c_maxlines; ++i) {
        if (pgm[i])
            printf("%d %s\n", i, pgm[i]);
    }
    printf("\n");
}

void loadstmt(void) {
    int n;
    char *filename;
    FILE *fp;

    newstmt();
    if ((filename = getfilename("Load")) == NULL) goto load_free;

    fp = fopen(filename, "r");
    if (fp == NULL) {
        printf("File %s not found\n", filename);
        goto load_free;
    }

    n = 0;
    while ((pgm[0] = mygetline(fp)) != NULL) {
        initlex(0);
        if (toktype == kNUMBER && validlinenum()) {
            pgm[num] = strdup(pgm[0] + textp);
            n = num;
        } else {
            n++;
            pgm[n] = strdup(pgm[0]);
        }
        free(pgm[0]);
    }
    fclose(fp);
load_free:
    free(filename);
    curline = 0;
}

void newstmt(void) {
    int i;

    clearvars();
    for (i = 0; i < c_maxlines; ++i) {
        if (pgm[i]) {free(pgm[i]); pgm[i] = NULL;}
    }
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

    while (strneq(tok, ":") && tok[0] != '\0') {
        printnl = true;
        printwidth = 0;

        if (accept("#")) {
            if (num <= 0) {printf("Expecting a print width, found: %s\n", pgm[curline]); return;}
            printwidth = num;
            nexttok();
            if (!accept(",")) {printf("Print: Expecting a ',', found: %s\n", pgm[curline]); return;}
        }

        if (toktype == kSTRING) {
            printf("%*s", printwidth, &tok[1]);
            nexttok();
        } else {
            printf("%*d", printwidth, expression(0));
        }

        if (accept(",") || accept(";")) {printnl = false;} else {break; }
    }
    if (printnl) printf("\n");
}

void returnstmt(void) {     // return from a subroutine
    curline = gstackln[gsp];
    textp   = gstacktp[gsp];
    --gsp;
    initlex2();
}

void runstmt(void) {
    timestart = clock();
    clearvars();
    initlex(1);
}

void gotostmt(void) {
    num = expression(0);
    if (validlinenum()) initlex(num);
}

void savestmt(void) {
    int i;
    char *filename;
    FILE *fp;

    if ((filename = getfilename("Save")) == NULL) goto save_free;

    fp = fopen(filename, "w");
    if (fp == NULL) {
        printf("File %s could not be opend for wriring\n", filename);
        goto save_free;
    }

    for (i = 1; i < c_maxlines; ++i) {
        if (pgm[i])
            printf("%d %s\n", i, pgm[i]);
    }
    fclose(fp);
save_free:
    free(filename);
}

char *getfilename(char action[]) {
    char *filename;

    if (toktype == kSTRING)
        filename = strdup(&tok[1]);
    else {
        printf("%s: ", action);
        filename = mygetline(stdin);
    }
    if (!filename) return NULL;
    if (filename[0] == '\0') {
        free(filename);
        return NULL;
    }
    if (strchr(filename, '.') == NULL) {
        filename = realloc(filename, strlen(filename) + 5);
        strcat(filename, ".bas");
    }
    return filename;
}

bool validlinenum(void) {
    if (num <= 0 || num > c_maxlines) {
        printf("(%d, %d) Line number out of range", curline, textp);
        errors = true; return false;
    }
    return true;
}

void clearvars(void) {
    int i;

    for (i = 0; i < c_maxvars; ++i) {
        vars[i] = 0;
    }
    gsp = 0;
}

int getvarindex(void) {
    if (toktype != kIDENT) {
        printf("(%d, %d) Not a variable: %s\n", curline, textp, thelin);
        errors = true;
        return 0;
    }
    return tok[0] - 'a';
}

bool expect(const char *s) {
    if (!accept(s)) {
        printf("(%d, %d) Expecting %s, but found %s, %s\n", curline, textp, s, tok, thelin);
        return errors = true;
    }
    return false;
}

bool accept(const char *s) {
    if (streql(tok, s)) {nexttok(); return true;}
    return false;
}

int expression(int minprec) {
    int n = 0;

    // handle numeric operands, unary operators, functions, variables
    if        (toktype == kNUMBER) { n = num; nexttok();
    } else if (accept("-"))        { n = -expression(7);
    } else if (accept("+"))        { n =  expression(7);
    } else if (accept("not"))      { n = !expression(3);
    } else if (accept("abs"))      { n = abs(parenexpr());
    } else if (accept("asc"))      { expect("("); n = tok[1]; nexttok(); expect(")");
    } else if (accept("rnd") || accept("irnd")) { n = rnd(parenexpr());
    } else if (accept("sgn"))      { n = parenexpr(); n = (n > 0) - (n < 0);
    } else if (toktype == kIDENT)  { n = vars[getvarindex()]; nexttok();
    } else if (accept("@"))        { n = atarry[parenexpr()];
    } else if (tok[0] == '(')      { n = parenexpr();
    } else {
        printf("(%d, %d) Syntax error: expecting an operand, found: %s toktype: %d\n", curline, textp, tok, toktype);
        return n;
    }

    for (;;) {  // while binary operator and precedence of tok >= minprec
        if        (minprec <= 1 && accept("or"))  { n = n | expression(2);
        } else if (minprec <= 2 && accept("and")) { n = n & expression(3);
        } else if (minprec <= 4 && accept("="))   { n = n == expression(5);
        } else if (minprec <= 4 && accept("<"))   { n = n <  expression(5);
        } else if (minprec <= 4 && accept(">"))   { n = n >  expression(5);
        } else if (minprec <= 4 && accept("<>"))  { n = n != expression(5);
        } else if (minprec <= 4 && accept("<="))  { n = n <= expression(5);
        } else if (minprec <= 4 && accept(">="))  { n = n >= expression(5);
        } else if (minprec <= 5 && accept("+"))   { n += expression(6);
        } else if (minprec <= 5 && accept("-"))   { n -= expression(6);
        } else if (minprec <= 6 && accept("*"))   { n *= expression(7);
        } else if (minprec <= 6 && accept("/"))   { n /= expression(7);
        } else if (minprec <= 6 && accept("\\"))  { n /= expression(7);
        } else if (minprec <= 6 && accept("mod")) { n %= expression(7);
        } else if (minprec <= 8 && accept("^"))   { n = pow(n, expression(9));
        } else { break; }
    }
    return n;
}

int parenexpr(void) {
    int n = 0;

    if (!accept("(")) {
        printf("(%d, %d) Paren Expr: Expecting '(', found: %s\n", curline, textp, tok);
    } else {
        n = expression(0);
        if (!accept(")")) {
            printf("(%d, %d) Paren Expr: Expecting ')', found: %s\n", curline, textp, tok);
        }
    }
    return n;
}

int rnd(int range) {
    return rand() % range + 1;
}

/* return null if nothing read */
char *mygetline(FILE *fp) {
    char *buf, *p;
    int size = BUFSIZ;

    p = buf = malloc(size);
    for (;;) {
        int c = fgetc(fp);
        if (c == EOF || c == '\n' || c == '\r') {   //@review: this isn't right - need to check for cr and lf
            if (c == EOF && p == buf) {
                free(buf);
                return NULL;
            }
            *p = '\0';
            return buf;
        }
        if (p - buf >= size) {
            size += BUFSIZ;
            buf = realloc(buf, size);
        }
        *p++ = (char)c;
    }
}

void initlex(int n) {
    curline = n;
    textp = 0;
    initlex2();
}

void initlex2(void) {
    need_colon = false;
    thelin = pgm[curline];
    thech = ' ';
    nexttok();
}

void nexttok(void) {
    toktype = kNONE;
    begin: tok[0] = thech; getch();
    if (tok[0] == '\0') { ;
    } else if (isspace(tok[0])) { goto begin;
    } else if (isalpha(tok[0])) { readident(); if (streql(tok, "rem")) skiptoeol();
    } else if (isdigit(tok[0])) { readint();
    } else if (tok[0] == '"')   { readstr();
    } else if (tok[0] == '\'')  { skiptoeol();
    } else if (strchr("#()*+,-/:;<=>?@\\^", tok[0]) != NULL) {
        tok[1] = '\0'; toktype = kPUNCT;
        if ((tok[0] == '<' && (thech == '>' || thech == '=')) || (tok[0] == '>' && thech == '=')) {
            tok[1] = thech; tok[2] = '\0';
            getch();
        }
    } else {
        printf("(%d, %d) What? %c (%d) %s\n", curline, textp, tok[0], tok[0], thelin);
        getch();
        errors = true;
    }
}

void skiptoeol(void) {
    tok[0] = '\0'; toktype = kNONE;
    textp = strlen(thelin) + 1;
}

// store double quote as first char of string, to distinguish from idents
void readstr(void) {
    char *p = &tok[1];
    toktype = kSTRING;
    while (thech != '"') {
        if (thech == '\0') {
            printf("(%d, %d) String not terminated\n", curline, textp);
            errors = true;
            return;
        }
        *p++ = thech;
        getch();
    }
    *p = '\0';
    getch();
}

void readint(void) {
    char *p = &tok[1], *endp;
    toktype = kNUMBER;
    while (isdigit(thech)) {
        *p++ = thech;
        getch();
    }
    *p = '\0';
    num = strtol(tok, &endp, 10);
}

void readident(void) {
    char *p = &tok[1];
    tok[0] = tolower(tok[0]); toktype = kIDENT;
    while (isalnum(thech)) {
        *p++ = tolower((char)thech);
        getch();
    }
    *p = '\0';
}

void getch(void) {
    if (!thelin) {
        thech = '\0';
    } else {
        thech = thelin[textp];
        if (thech != '\0')
            ++textp;
    }
}
