/*
'Ed Davis. Tiny Basic that can play Star Trek
'Supports: end, list, load, new, run, save
'gosub/return, goto, if, input, print, multi-statement lines (:)
'a single numeric array: @(n), and rnd(n)

On Linux: gcc int-stc2.c.c -lm -o int-stc2
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

#define NELEMS(arr) (sizeof(arr) / sizeof(arr[0]))

#define streql(s1, s2) (strcmp(s1, s2) == 0)
#define strneq(s1, s2) (strcmp(s1, s2))

enum {c_maxlines = 7000, c_at_max = 1000, c_maxvars = 26, c_g_stack = 100};
typedef enum {tNONE,
    tPOUND='#',
    tLP='(',
    tRP=')',
    tMUL='*',
    tPLUS='+',
    tCOMMA=',',
    tMINUS='-',
    tDIV='/',
    tCOLON=':',
    tSEMICOLOR=';',
    tLT='<',
    tEQUAL='=',
    tGT='>',
    tQUESTION='?',
    tAMPERSAND='@',
    tBACKSLASH='\\',
    tHAT='^',
    tNEQ=256, tLEQ, tGEQ,
    tABS, tBYE, tAND, tASC, tCLEAR, tCLS, tEND, tFOR, tGOSUB, tGOTO, tHELP, tIDENT, tIF,
    tINPUT, tIRND, tLET, tLIST, tLOAD, tMOD, tNEW, tNEXT, tNOT, tNUMBER, tOR, tPRINT,
    tQUIT, tREM, tRETURN, tRND, tRUN, tSAVE, tSGN, tSTOP, tSTRING, tTHEN, tTO, tTROFF,
    tTRON,
} tok_t;

tok_t tok;
int num;
unsigned textp;
char texttok[1024];
char *thelin, thech;
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

bool  accept(tok_t s);
void  arrassn(void);
void  assign(void);
void  clearvars(void);
void  docmd(void);
bool  expect(tok_t s);
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
        tok = tSTRING;
        sprintf(texttok, "\"%s", argv[1]);
        loadstmt();
        tok = tRUN;
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
            if (tok == tNUMBER) {
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
        if (tracing && tok != tCOLON && thelin && textp < strlen(thelin))
            printf("[%d] %s\n", curline, &thelin[textp - 1]);
        if        (tok == tBYE || tok == tQUIT) { nexttok(); exit(0);
        } else if (tok == tEND || tok == tSTOP) { nexttok(); showtime(running); return;
        } else if (tok == tCLEAR)     { nexttok(); clearvars(); return;
        } else if (tok == tHELP)      { nexttok(); help(); return;
        } else if (tok == tLIST)      { nexttok(); liststmt(); return;
        } else if (tok == tLOAD)      { nexttok(); loadstmt(); return;
        } else if (tok == tNEW)       { nexttok(); newstmt(); return;
        } else if (tok == tRUN)       { nexttok(); runstmt(); running = true; need_colon = false;
        } else if (tok == tSAVE)      { nexttok(); savestmt(); return;
        } else if (tok == tTRON)      { nexttok(); tracing = true;
        } else if (tok == tTROFF)     { nexttok(); tracing = false;
        } else if (tok == tCLS)       { nexttok(); ;
        } else if (tok == tFOR)       { nexttok(); forstmt();
        } else if (tok == tGOSUB)     { nexttok(); gosubstmt();
        } else if (tok == tGOTO)      { nexttok(); gotostmt();
        } else if (tok == tIF)        { nexttok(); ifstmt();
        } else if (tok == tINPUT)     { nexttok(); inputstmt();
        } else if (tok == tNEXT)      { nexttok(); nextstmt();
        } else if (tok == tLET)       { nexttok(); assign();
        } else if (tok == tPRINT || tok == tQUESTION) { nexttok(); printstmt();
        } else if (tok == tRETURN)    { nexttok(); returnstmt();
        } else if (tok == tAMPERSAND) { nexttok(); arrassn();
        } else if (tok == tIDENT)     { assign();
        } else if (tok == tCOLON || tok == tNONE) { /* handled below */
        } else {
            printf("(%d, %d) Unknown token: line: %s\n", curline, textp, pgm[curline]);
            errors = true;
        }

        if (errors) return;
        if (tok == tNONE) {
          while (tok == tNONE) {
              if (curline == 0 || curline >= c_maxlines) { showtime(running); return;}
              initlex(curline + 1);
          }
        } else if (tok == tCOLON) { nexttok();
        } else if (need_colon && !expect(tCOLON)) { return;
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
  expect(tEQUAL);
  vars[var] = expression(0);
  if (tracing) printf("*** %c = %d\n", var + 'a', vars[var]);
}

void arrassn(void) {        // array assignment: @(expr) {} = expr
    int n, atndx;

    atndx = parenexpr();
    if (!accept(tEQUAL)) {
        printf("(%d, %d) Array Assign: Expecting '=', found: %s", curline, textp, thelin);
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
    if (!accept(tTO)) {
        printf("(%d, %d) For: Expecting 'to', found: %d\n", curline, textp, tok); errors = true;
    } else {
        n = expression(0);
        forlimit[forndx] = n;
        // need to store iter, limit, line, and col
        forline[forndx] = curline;
        if (tok == tNONE) forpos[forndx] = textp; else forpos[forndx] = textp - 2;
        //forpos[forndx] textp; if (tok != "") forpos[forndx] -=2;
    }
}

void ifstmt(void) {
    need_colon = false;
    if (expression(0) == 0)
        skiptoeol();
    else {
        accept(tTHEN);      // "then" is optional
        if (tok == tNUMBER) gotostmt();
    }
}

void inputstmt(void) {      // "input" [string ","] var
    int var;
    char *st, *endp;

    if (tok == tSTRING) {
        printf("%s", &texttok[1]);
        nexttok();
        expect(tCOMMA);
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
        if (tok == tNUMBER && validlinenum()) {
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

    while (tok != tCOLON && tok != tNONE) {
        printnl = true;
        printwidth = 0;

        if (accept(tPOUND)) {
            if (num <= 0) {printf("Expecting a print width, found: %s\n", pgm[curline]); return;}
            printwidth = num;
            nexttok();
            if (!accept(tCOMMA)) {printf("Print: Expecting a ',', found: %s\n", pgm[curline]); return;}
        }

        if (tok == tSTRING) {
            printf("%*s", printwidth, &texttok[1]);
            nexttok();
        } else {
            printf("%*d", printwidth, expression(0));
        }

        if (accept(tCOMMA) || accept(tSEMICOLOR)) {printnl = false;} else {break; }
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

    if (tok == tSTRING)
        filename = strdup(&texttok[1]);
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
    if (tok != tIDENT) {
        printf("(%d, %d) Not a variable: %s\n", curline, textp, thelin);
        errors = true;
        return 0;
    }
    return texttok[0] - 'a';
}

bool expect(tok_t s) {
    if (!accept(s)) {
        printf("(%d, %d) Expecting %d, but found %d, %s\n", curline, textp, s, tok, thelin);
        return errors = true;
    }
    return false;
}

bool accept(tok_t s) {
    if (s == tok) {nexttok(); return true;}
    return false;
}

int expression(int minprec) {
    int n = 0;

    // handle numeric operands, unary operators, functions, variables
    if        (tok == tNUMBER)     { n = num; nexttok();
    } else if (tok == tMINUS)      { nexttok(); n = -expression(7);
    } else if (tok == tPLUS)       { nexttok(); n =  expression(7);
    } else if (tok == tNOT)        { nexttok(); n = !expression(3);
    } else if (tok == tABS)        { nexttok(); n = abs(parenexpr());
    } else if (tok == tASC)        { nexttok(); expect(tLP); n = texttok[1]; nexttok(); expect(tRP);
    } else if (tok == tRND || tok == tIRND) { nexttok(); n = rnd(parenexpr());
    } else if (tok == tSGN)        { nexttok(); n = parenexpr(); n = (n > 0) - (n < 0);
    } else if (tok == tIDENT)      { n = vars[getvarindex()]; nexttok();
    } else if (tok == tAMPERSAND)  { nexttok(); n = atarry[parenexpr()];
    } else if (tok == tLP)         { n = parenexpr();
    } else {
        printf("(%d, %d) Syntax error: expecting an operand, found: %d tok: %d\n", curline, textp, tok, tok);
        return n;
    }

    for (;;) {  // while binary operator and precedence of tok >= minprec
        if        (minprec <= 1 && tok == tOR)        { nexttok(); n = n | expression(2);
        } else if (minprec <= 2 && tok == tAND)       { nexttok(); n = n & expression(3);
        } else if (minprec <= 4 && tok == tEQUAL)     { nexttok(); n = n == expression(5);
        } else if (minprec <= 4 && tok == tLT)        { nexttok(); n = n <  expression(5);
        } else if (minprec <= 4 && tok == tGT)        { nexttok(); n = n >  expression(5);
        } else if (minprec <= 4 && tok == tNEQ)       { nexttok(); n = n != expression(5);
        } else if (minprec <= 4 && tok == tLEQ)       { nexttok(); n = n <= expression(5);
        } else if (minprec <= 4 && tok == tGEQ)       { nexttok(); n = n >= expression(5);
        } else if (minprec <= 5 && tok == tPLUS)      { nexttok(); n += expression(6);
        } else if (minprec <= 5 && tok == tMINUS)     { nexttok(); n -= expression(6);
        } else if (minprec <= 6 && tok == tMUL)       { nexttok(); n *= expression(7);
        } else if (minprec <= 6 && tok == tDIV)       { nexttok(); n /= expression(7);
        } else if (minprec <= 6 && tok == tBACKSLASH) { nexttok(); n /= expression(7);
        } else if (minprec <= 6 && tok == tMOD)       { nexttok(); n %= expression(7);
        } else if (minprec <= 8 && tok == tHAT)       { nexttok(); n = pow(n, expression(9));
        } else { break; }
    }
    return n;
}

int parenexpr(void) {
    int n = 0;

    if (!accept(tLP)) {
        printf("(%d, %d) Paren Expr: Expecting '(', found: %d\n", curline, textp, tok);
    } else {
        n = expression(0);
        if (!accept(tRP)) {
            printf("(%d, %d) Paren Expr: Expecting ')', found: %d\n", curline, textp, tok);
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
    tok = tNONE;
    begin: texttok[0] = thech; getch();
    if (texttok[0] == '\0') { ;
    } else if (isspace(texttok[0])) { goto begin;
    } else if (isalpha(texttok[0])) { readident(); if (streql(texttok, "rem")) skiptoeol();
    } else if (isdigit(texttok[0])) { readint();
    } else if (texttok[0] == '"')   { readstr();
    } else if (texttok[0] == '\'')  { skiptoeol();
    } else if (strchr("#()*+,-/:;<=>?@\\^", texttok[0]) != NULL) {
        tok = texttok[0]; texttok[1] = texttok[2] = '\0';
        if (texttok[0] == '<' && thech == '>') {
            tok = tNEQ; texttok[1] = thech; getch();
        } else if (texttok[0] == '<' && thech == '=') {
            tok = tLEQ; texttok[1] = thech; getch();
        } else if (texttok[0] == '>' && thech == '=') {
            tok = tGEQ; texttok[1] = thech; getch();
        }
    } else {
        printf("(%d, %d) What? %c (%d) %s\n", curline, textp, texttok[0], texttok[0], thelin);
        getch();
        errors = true;
    }
}

void skiptoeol(void) {
    tok = tNONE;
    textp = strlen(thelin) + 1;
}

// store double quote as first char of string, to distinguish from idents
void readstr(void) {
    char *p = &texttok[1];
    tok = tSTRING;
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
    char *p = &texttok[1], *endp;
    tok = tNUMBER;
    while (isdigit(thech)) {
        *p++ = thech;
        getch();
    }
    *p = '\0';
    num = strtol(texttok, &endp, 10);
}

typedef struct {
    const char *s;
    tok_t tok;
} KWT;

void readident(void) {
    KWT kwds[] = {
        {"abs",     tABS},
        {"and",     tAND},
        {"asc",     tASC},
        {"bye",     tBYE},
        {"clear",   tCLEAR},
        {"cls",     tCLS},
        {"end",     tEND},
        {"for",     tFOR},
        {"gosub",   tGOSUB},
        {"goto",    tGOTO},
        {"help",    tHELP},
        {"if",      tIF},
        {"input",   tINPUT},
        {"irnd",    tIRND},
        {"let",     tLET},
        {"list",    tLIST},
        {"load",    tLOAD},
        {"mod",     tMOD},
        {"new",     tNEW},
        {"next",    tNEXT},
        {"not",     tNOT},
        {"or",      tOR},
        {"print",   tPRINT},
        {"quit",    tQUIT},
        {"rem",     tREM},
        {"return",  tRETURN},
        {"rnd",     tRND},
        {"run",     tRUN},
        {"save",    tSAVE},
        {"sgn",     tSGN},
        {"stop",    tSTOP},
        {"then",    tTHEN},
        {"to",      tTO},
        {"troff",   tTROFF},
        {"tron",    tTRON},
    };
    unsigned i;
    char *p = &texttok[1];
    texttok[0] = tolower(texttok[0]); tok = tIDENT;
    while (isalnum(thech)) {
        *p++ = tolower((char)thech);
        getch();
    }
    *p = '\0';
    for (i = 0; i < NELEMS(kwds); ++i) {
        if (streql(texttok, kwds[i].s)) {
            tok = kwds[i].tok;
            break;
        }
    }
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
