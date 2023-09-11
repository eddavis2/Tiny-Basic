/*
  Ed Davis, 2022
  Loosely based (but greatly expanded) on Zserge's 166 line toy basic -
  https://zserge.com/posts/transpilers/ - which in turn was
  apparently loosely based on the IOCC Basic interpreter entry -
  https://github.com/ioccc-src/winner/blob/master/1991/dds.ansi.c
  To compile: gcc.exe -Wall -Wextra -pedantic -s -Os basic.c -o basic
  Implements enough Basic to play tiny star trek.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <ctype.h>
#include <math.h>

#define MIN(X, Y) (((X) < (Y)) ? (X) : (Y))

#define LINE_MAX    1024
int vars[27];             /* global variables, 'a'..'z' */
char line[LINE_MAX + 1];  /* current input line */
char code[64000];         /* complete program code */
char *ip;                 /* current pointer */
int at[30000];            /* the @() array */
int gsp, gosub_line[999], for_line[27], for_limit[27];
char *gosub_off[999], *for_off[27];

static int expr(int minprec);

/* reads a number from a stream */
static int num(void) { return strtol(ip, &ip, 10); }

/* returns the end of the current line */
static char *eol(void) { return strchr(ip, '\n'); }

/* skips while cond(c) is true */
#define eat(cond) for (int c; ((c = *ip) != 0) && (cond); ip++)

/* skips whitespace */
#define space() eat(c == ' ' || c == '\t')

/* skips until whitespace */
#define token() eat(c != ' ' && c != '\t')

static int var(void) {  /* return index of the variable at current position */
  int c;
  space();
  c = *ip | 0x20;           /* lowercase the character */
  if (isalpha(c)) {
    ip++;
    return c - 'a' + 1;
  }
  return 0;
}

static int accept(const char *s) {
  size_t n;
  space();
  n = strlen(s);
  if (eol() - ip < (int)n) { return false; }
  if (memicmp(s, ip, n) == 0) {
    // if last char of s is alpha, make sure next char of ip is not alnum
    if (isalpha(s[0]) && isalpha(ip[n])) { return false; }
    ip += n;
    return true;
  }
  return false;
}

static int expect(const char *s) {
  if (accept(s)) { return true; }
  printf("expecting %s, but found %.*s\n", s, (int)MIN(strlen(ip), 40), ip);
  return false;
}

static int pexpr(void) {
  int n;
  space();
  expect("(");
  n = expr(0);
  expect(")");
  return n;
}

static int expr(int minprec) {
  int n;
  space();
  if (accept("-"))          { n = -expr(7);
  } else if(accept("+"))    { n = expr(7);
  } else if (isdigit(*ip))  { n = num();
  } else if (accept("(")) {
    n = expr(0);
    expect(")");
  } else if (accept("not")) { n = !expr(3);
  } else if (accept("@"))   { n = at[pexpr()];
  } else if (accept("abs")) { n = abs(pexpr());
  } else if (accept("asc")) { // asc("x")
    expect("(");
    expect("\"");
    n = *ip++;
    expect("\"");
    expect(")");
  } else if (accept("rnd") || accept("irnd")) { n = rand() % pexpr() + 1;
  } else if (accept("sgn"))  { n = pexpr(); n = (n > 0) - (n < 0);
  } else if (isalpha(ip[0])) { n = vars[var()];
  } else {
    printf("expecting a variable, but found %.*s\n", (int)MIN(strlen(ip), 20), ip);
    return 0;
  }

  for (;;) {
    if        (minprec <= 1 && accept("or"))  {n = n | expr(2);
    } else if (minprec <= 2 && accept("and")) {n = n & expr(3);

    } else if (minprec <= 4 && accept("="))  {n = n == expr(5);
    } else if (minprec <= 4 && accept("<>")) {n = n != expr(5);
    } else if (minprec <= 4 && accept("<=")) {n = n <= expr(5);
    } else if (minprec <= 4 && accept(">=")) {n = n >= expr(5);
    } else if (minprec <= 4 && accept("<"))  {n = n <  expr(5);
    } else if (minprec <= 4 && accept(">"))  {n = n >  expr(5);

    } else if (minprec <= 5 && accept("+"))  {n = n +  expr(6);
    } else if (minprec <= 5 && accept("-"))  {n = n -  expr(6);

    } else if (minprec <= 6 && accept("*"))  {n = n *  expr(7);
    } else if (minprec <= 6 && accept("/"))  {n = n /  expr(7);
    } else if (minprec <= 6 && accept("\\")) {n = n /  expr(7);
    } else if (minprec <= 6 && accept("mod")){n = n %  expr(7);

    } else if (minprec <= 8 && accept("^"))  {n = pow(n, expr(9));

    } else break;
  }
  return n;
}

static char *find(int n) {  /* find line number 'n' in the code buffer */
  ip = code;
  while (*ip) {
    char *line = ip;
    int i = num();
    ip = eol() + 1;
    if (i >= n) { return ip = line; }
  }
  return ip = (code + strlen(code));
}

static int stmt(int curline) { // return 0 on error, 1 for continue, -1 to exit
  int line_num;
  char *s;
  int v;
  again:
  s = ip;
  v = var();

  //----------[assign]-----------------------------------------------------
  if (accept("=")) {
    vars[v] = expr(0);
  //----------[@assign]-----------------------------------------------------
  } else if (accept("@")) {       // @(expr) = expr
    int ndx = pexpr();
    if (!expect("=")) { return 0; }  //********* return 0 *********************
    at[ndx] = expr(0);
  } else {
      int gosub;
      ip = s;
  //----------[end]-----------------------------------------------------
      if (accept("end") || accept("stop")) {
        return -1;                  //********* return -1 ********************
  //----------[for]-----------------------------------------------------
      } else if (accept("for")) {          // for i=expr to expr
          int v = var();
          expect("=");        // skip '='
          vars[v] = expr(0);
          expect("to");       // skip "to"
          for_limit[v] = expr(0);
          for_off[v]   = ip;
          for_line[v]  = curline;
  //----------[gosub/goto]-----------------------------------------------------
      } else if ((gosub = accept("gosub")) != 0 || accept("goto")) { // goto/gosub
          line_num = expr(0);
          if (gosub) {
            gsp++;
            gosub_line[gsp] = curline;
            gosub_off[gsp]  = ip;
          }
          gotoline:

          find(line_num);
          if (num() == line_num) {
            curline = line_num;
            goto again;               //********* goto again *******************
          } else {
            printf("goto/gosub: line %d not found\n", line_num);
            return 0;                 //********* return 0 *********************
          }
  //----------[if]-----------------------------------------------------
      } else if (accept("if")) {
          if (expr(0)) {
            accept("then");
            line_num = num();
            if (line_num > 0) {
              goto gotoline;          //********* goto gotoline
            } else {
              goto again;             //********* goto again
            }
          } else {
            ip = eol(); return 1;      //********* return 1
          }
  //----------[input]-----------------------------------------------------
      } else if (accept("input")) { // input [string,] var
          if (accept("\"")) {
            eat(c != '"') { putchar(c); }
            expect("\"");
            expect(",");
          }
          int v = var();
          char *s = ip;
          ip = fgets(line, LINE_MAX, stdin);
          vars[v] = isdigit(*ip) ? expr(0) : *ip;
          ip = s;
  //----------[next]-----------------------------------------------------
      } else if (accept("next")) {    // next i
          int v = var();
          vars[v]++;
          if (vars[v] <= for_limit[v]) {
            curline = for_line[v];
            ip       = for_off[v];
            goto again;               //********* goto again
          }
  //----------[print]-----------------------------------------------------
      } else if (accept("print") || accept("?")) { // 'print' [[#num ',' ] expr { ',' [#num ','] expr }] [','] {':' stmt} eol
          int print_nl = 1;

          for (;;) {
              int width = 0;
              space();
              if (*ip == ':' || *ip == '\n' || *ip == '\'') { break; }
              print_nl = 1;
              if (accept("#")) {
                  width = expr(0);
                  expect(",");
              }

              if (accept("\"")) {
                eat(c != '"') { putchar(c); }
                expect("\"");
              } else
                  printf("%*d", width, expr(0));

              if (accept(",") || accept(";")) {
                  print_nl = false;
              } else
                  break;
          }
          if (print_nl) { printf("\n"); }
  //----------[return]-----------------------------------------------------
      } else if (accept("return")) {
          curline = gosub_line[gsp];
          ip       = gosub_off[gsp];
          gsp--;
          goto again;               //********* goto again
      }
  }

  if (accept(":")) { goto again; }//********* goto again
  if (accept("'") || accept("rem")) {
    ip = eol(); return 1;          //********* return 1
  }
  space();
  if (ip[0] == '\n') { return 1; }

  printf("unknown statment: %.*s\n", (int)MIN(strlen(ip), 40), ip);
  return 0;
}

static void run(void) {
  ip = code;
  for (;;) {
    int n = num();
    if (n == 0) { break; }
    if ((n = stmt(n)) == -1) { break; }
    if (n == 0) {
      char *s = ip;
      while (s > code && *s != '\n') {
        --s;
      }
      printf("Unknown char starting at: %.*s in line: %.*s", (int)MIN(strlen(ip), 40), ip, (int)MIN(strlen(ip), 40), s);
      break;
    }
  }
}

static void load(void) {
  FILE *fp;
  char *p;

  space();
  if (ip[0] == '\n') {
    printf("File to load:");
    ip = line;
    if (fgets(line, LINE_MAX, stdin) == NULL) return;
  }
  if (ip[0] == '\n') { return; }
  if (ip[0] == '"') { ip++; }
  p = eol();
  p[0] = '\0';
  if (*--p == '"') { *p = '\0'; }
  if ((fp = fopen(ip, "r")) == NULL) {
    printf("File not found: %s\n", ip);
    return;
  }
  code[0] = '\0';
  while (fgets(line, LINE_MAX, fp) != NULL) { strcat(code, line); }
  ip = code;
}

int main() {
  for (;;) {
    int n;
    printf("> ");
    if (fgets(line, LINE_MAX, stdin) == NULL) { break; }
    ip = line;
    if ((n = num()) != 0) {
      char *start = find(n);
      char *end = eol();
      int an = num();
      if (an == n) {  // found our line - replace it
        memmove(start, end + 1, strlen(end)); // remove the existing line
      }
      if (an >= n) {  // insert at this position
        memmove(start + strlen(line), start, strlen(start)); // make a hole
      }
      memmove(start, line, strlen(line));
    } else {
      if      (accept("new"))  { code[0] = '\0'; }
      else if (accept("run"))  { run(); }
      else if (accept("list")) { puts(code); }
      else if (accept("load")) { load(); }
      else if (accept("bye") || accept("quit")) { break; }
      else { stmt(0); }  // try to run it
    }
  }
  return 0;
}
