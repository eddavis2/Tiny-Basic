{Tiny Basic interpreter in Free Pascal}
uses character, crt, math, strutils, sysutils;

const c_maxlines = 7000; c_maxvars = 26; c_at_max = 500; c_g_stack = 100;

var tok, toktype, thelin: string;
var thech: char;
var num, curline, textp: longint;
var pgm: array[0..c_maxlines] of string;
var need_colon, tracing, errors:boolean;
var vars: array[0..c_maxvars] of longint;
var atarry: array[0..c_at_max] of longint;
var gsp: longint;
var forvar, forlimit, forline, forpos: array[0..c_maxvars] of longint;
var gstackln, gstacktp: array[0..c_g_stack] of longint;

function  accept(s: string): boolean; forward;
procedure arrassn; forward;
procedure clearvars; forward;
procedure docmd; forward;
procedure expect(s: string); forward;
function  expression(minprec: longint): longint; forward;
procedure forstmt; forward;
procedure getch; forward;
function  getfilename(action: string): string; forward;
function  getvarindex: longint; forward;
procedure gosubstmt; forward;
procedure gotostmt; forward;
procedure help; forward;
procedure ifstmt; forward;
procedure initlex(n: longint); forward;
procedure initlex2; forward;
procedure inputstmt; forward;
procedure liststmt; forward;
procedure loadstmt; forward;
procedure newstmt; forward;
procedure nextstmt; forward;
procedure nexttok; forward;
function  parenexpr: longint; forward;
procedure printstmt; forward;
procedure readident; forward;
procedure readint forward;
procedure readstr; forward;
procedure returnstmt; forward;
procedure runstmt; forward;
procedure savestmt; forward;
procedure skiptoeol; forward;
function  validlinenum: boolean; forward;
procedure varassign; forward;

procedure main;
begin
  newstmt;
  if paramcount > 0 then begin
      toktype := 'string'; tok := chr(34) + paramStr(1);
      loadstmt;
      tok := 'run'; docmd;
  end else begin
      help;
  end;
  while true do begin
    errors := false;
    write('FP TB> '); readLn(pgm[0]);
    if pgm[0] <> '' then begin
      initlex(0);
      if toktype = 'number' then begin
        if validlinenum then pgm[num] := Copy(pgm[0], textp);
      end else begin
        docmd;
      end;
    end;
  end;
end;

procedure docmd;
begin
  while true do begin
    if (tracing) and (tok[1] <> ':') then
      writeln(curline, tok, thech, Copy(thelin, textp));
    need_colon := true;
    case tok of
      'bye', 'quit': begin nexttok; halt;             end;
      'end', 'stop': begin nexttok; exit;             end;
      'clear'      : begin nexttok; clearvars; exit;  end;
      'help'       : begin nexttok; help;      exit;  end;
      'list'       : begin nexttok; liststmt;  exit;  end;
      'load', 'old': begin nexttok; loadstmt;  exit;  end;
      'new'        : begin nexttok; newstmt;   exit;  end;
      'run'        : begin nexttok; runstmt;          end;
      'save'       : begin nexttok; savestmt;  exit;  end;
      'tron'       : begin nexttok; tracing := true;  end;
      'troff'      : begin nexttok; tracing := false; end;
      'cls'        : begin nexttok; clrscr;           end;
      'for'        : begin nexttok; forstmt;          end;
      'gosub'      : begin nexttok; gosubstmt;        end;
      'goto'       : begin nexttok; gotostmt;         end;
      'if'         : begin nexttok; ifstmt;           end;
      'input'      : begin nexttok; inputstmt;        end;
      'next'       : begin nexttok; nextstmt;         end;
      'print', '?' : begin nexttok; printstmt;        end;
      'return'     : begin nexttok; returnstmt;       end;
      '@'          : begin nexttok; arrassn;          end;
      ':', ''      : { handled below }
      else
        if tok = 'let' then nexttok;
        if toktype = 'ident' then begin
          varassign;
        end else begin
          writeln('Unknown token "', tok, '" at line:', curline, ' Col:', textp, ' : ', thelin);
          errors := true;
        end;
    end;
    if errors then exit;
    if tok = '' then begin
      while tok = '' do begin
        if (curline = 0) or (curline >= c_maxlines) then exit;
        initlex(curline + 1);
      end;
    end else if tok = ':' then begin nexttok;
    end else if need_colon and not accept(':') then begin
      writeln(': expected but found: ', tok);
      exit;
    end;
  end;
end;

procedure help;
begin
   writeln('+---------------------- Tiny Basic (QBASIC) --------------------------+');
   writeln('| bye, clear, cls, end/stop, help, list, load/save, new, run, tron/off|');
   writeln('| for <var> = <expr1> to <expr2> ... next <var>                       |');
   writeln('| gosub <expr> ... return                                             |');
   writeln('| goto <expr>                                                         |');
   writeln('| if <expr> then <statement>                                          |');
   writeln('| input [prompt,] <var>                                               |');
   writeln('| <var>=<expr>                                                        |');
   writeln('| print(<expr|string>[,<expr|string>][;]                              |');
   writeln('| rem <anystring>  or ''<anystring>                                    |');
   writeln('| Operators: ^, * / \ mod + - < <= > >= = <>, not, and, or            |');
   writeln('| integer variables a..z, and array @(expr)                           |');
   writeln('| Functions: abs(expr), asc(ch), rnd(expr), sgn(expr)                 |');
   writeln('+---------------------------------------------------------------------+');
end;

procedure varassign;
  var ivar:longint;
begin
  ivar := getvarindex; nexttok;
  expect('=');
  vars[ivar] := expression(0);
  if tracing then writeln('*** ', chr(ivar + ord('a')), ' = ', vars[ivar]);
end;

procedure arrassn;   { array assignment: @(expr) = expr }
  var n, atndx: longint;
begin
  atndx := parenexpr;
  if tok <> '=' then begin
    writeln('Array Assign: Expecting "=", found:', tok);
    errors := true;
  end else begin
    nexttok;     { skip the "=" }
    n := expression(0);
    atarry[atndx] := n;
    if tracing then writeln('*** @(', atndx, ') = ', n);
  end;
end;

procedure forstmt;   { for i = expr to expr }
  var ivar, n, forndx: longint;
begin
  ivar := getvarindex;
  varassign;
  { vars(ivar) has the value; ivar has the number value of the variable in 0..25 }
  forndx := ivar;
  forvar[forndx] := vars[ivar];
  if tok <> 'to' then begin
    writeln('For: Expecting "to", found:', tok);
    errors := true;
  end else begin
    nexttok;
    n := expression(0);
    forlimit[forndx] := n;
    { need to store iter, limit, line, and col }
    forline[forndx] := curline;
    if tok = '' then forpos[forndx] := textp else forpos[forndx] := textp - 2;
  end;
end;

procedure gosubstmt;   { for gosub: save the line and column }
begin
  inc(gsp);
  gstackln[gsp] := curline;
  gstacktp[gsp] := textp;

  gotostmt;
end;

procedure gotostmt;
begin
  num := expression(0);
  if validlinenum then initlex(num);
end;

procedure ifstmt;
begin
  need_colon := false;
  if expression(0) = 0 then begin
    skiptoeol;
  end else begin
    if tok = 'then' then nexttok;
    if toktype = 'number' then gotostmt;
  end;
end;

procedure inputstmt;   { "input" [string ","] ivar }
  var ivar: longint;
      st: string;
begin
  if toktype = 'string' then begin
    write(Copy(tok, 2));
    nexttok;
    expect(',');
  end else begin
    write('? ');
  end;
  ivar := getvarindex; nexttok;
  readLn(st);
  if st = '' then st := '0';
  if isDigit(st[1]) then begin
    vars[ivar] := strToInt(st);
  end else begin
    vars[ivar] := ord(st[1]);
  end;
end;

procedure liststmt;
  var i: longint;
begin
  for i := 1 to c_maxlines do begin
    if pgm[i] <> '' then writeln(i, ' ', pgm[i]);
  end;
  writeln();
end;

procedure loadstmt;
  var f: text;
      filename: string;
      n: longint;
begin
  newstmt;
  filename := getfilename('Load');
  if filename = '' then exit;
  if not FileExists(filename) then begin
    writeln('File: ', filename, ' not found.');
    exit;
  end;

  assign(f, filename);
  reset(f);
  while not eof(f) do begin
    readln(f, pgm[0]);
    initlex(0);
    if (toktype = 'number') and validlinenum then begin
      n := num;
    end else begin
      inc(n); textp := 1;
    end;
    pgm[n] := copy(pgm[0], textp);
  end;
  close(f);
  curline := 0;
end;

procedure newstmt;
  var i: longint;
begin
  clearvars;
  for i := 1 to c_maxlines do
    pgm[i] := '';
end;

procedure nextstmt;
  var forndx: longint;
begin
  { tok needs to have the variable }
  forndx := getvarindex;
  inc(forvar[forndx]);
  vars[forndx] := forvar[forndx];
  if forvar[forndx] <= forlimit[forndx] then begin
    curline := forline[forndx];
    textp   := forpos[forndx];
    initlex2;
  end else
    nexttok { skip the ident for now }
end;

procedure printstmt;
  var printnl: boolean;
      printwidth, n: longint;
      junk: string;
begin
  printnl := true;
  while (tok <> ':') and (tok <> '') and (tok <> 'else') do begin
    printnl := true;
    printwidth := 0;
    if accept('#') then begin
      if num <= 0 then begin
        writeln('Expecting a print width, found:', tok);
        exit;
      end;
      printwidth := num;
      nexttok;
      if not accept(',') then begin
        writeln('Print: Expecting a ",", found:', tok);
        exit;
      end;
    end;

    if toktype = 'string' then begin
      junk := Copy(tok, 2);
      nexttok;
    end else begin
      n := expression(0);
      junk := trim(inttostr(n));
    end;
    printwidth := printwidth - length(junk);
    if printwidth <= 0 then write(junk) else write(space(printwidth), junk);

    if accept(',') or accept(';') then printnl := false else break;
  end;

  if printnl then writeln();
end;

procedure returnstmt; { exit sub from a subroutine }
begin
  curline := gstackln[gsp];
  textp   := gstacktp[gsp];
  dec(gsp);
  initlex2;
end;

procedure runstmt;
begin
  clearvars;
  initlex(1);
end;

procedure savestmt;
  var i: longint;
      filename: string;
      f: text;
begin
  filename := getfilename('Save');
  if filename = '' then exit;
  assign(f, filename);
  rewrite(f);
  for i := 1 to c_maxlines do
    if pgm[i] <> '' then writeln(f, inttostr(i) + ' ' + pgm[i]);

  close(f);
end;

function getfilename(action: string): string;
  var filename: string;
begin
  if toktype = 'string' then begin
    filename := copy(tok, 2);
  end else begin
    write(action, ': ');
    readln(filename);
  end;
  if filename <> '' then
    if pos('.', filename) = 0 then
      filename := filename + '.bas';
  getfilename := filename;
end;

function validlinenum: boolean;
begin
  validlinenum := true;
  if (num <= 0) or (num > c_maxlines) then begin
    writeln('Line number out of range');
    errors := true;
    validlinenum := false;
  end;
end;

procedure clearvars;
  var i: longint;
begin
  gsp := 0;
  for i := 1 to c_maxvars do
    vars[i] := 0;
end;

function parenexpr: longint;
begin
  expect('(');
  parenexpr := expression(0);
  expect(')');
end;

function expression(minprec: longint): longint;
  var n: longint;
      s: string;
begin
  { handle numeric operands - numbers and unary operators }
  if toktype = 'number' then begin n := num; nexttok;
  end else if tok = '('   then begin n := parenexpr;
  end else if tok = 'not' then begin nexttok; n := not expression(3);
  end else if tok = 'abs' then begin nexttok; n := abs(parenexpr);
  end else if tok = 'asc' then begin
    nexttok;
    expect('(');
    s := Copy(tok, 2, 1);
    n := Ord(s[1]);
    nexttok;
    expect(')');
  end else if (tok = 'rnd') or (tok = 'irnd') then begin nexttok; n := random(parenexpr) + 1;
  end else if tok = 'sgn' then begin nexttok; n := sign(parenexpr);
  end else if toktype = 'ident' then begin n := vars[getvarindex]; nexttok;
  end else if tok = '@'   then begin nexttok; n := atarry[parenexpr];
  end else if tok = '-'   then begin nexttok; n := -expression(7);
  end else if tok = '+'   then begin nexttok; n :=  expression(7);
  end else begin
    writeln('syntax error: expecting an operand, found: ', tok);
    errors := true;
    exit;
  end;

  while true do begin  { while binary operator and precedence of tok >= minprec };
    if          (minprec <= 1) and (tok = 'or' ) then begin nexttok; n := ord(n) or  ord(expression(2));
    end else if (minprec <= 2) and (tok = 'and') then begin nexttok; n := ord(n) and ord(expression(3));
    end else if (minprec <= 4) and (tok = '='  ) then begin nexttok; n := ord(n = expression(5));
    end else if (minprec <= 4) and (tok = '<'  ) then begin nexttok; n := ord(n < expression(5));
    end else if (minprec <= 4) and (tok = '>'  ) then begin nexttok; n := ord(n > expression(5));
    end else if (minprec <= 4) and (tok = '<>' ) then begin nexttok; n := ord(n <> expression(5));
    end else if (minprec <= 4) and (tok = '<=' ) then begin nexttok; n := ord(n <= expression(5));
    end else if (minprec <= 4) and (tok = '>=' ) then begin nexttok; n := ord(n >= expression(5));
    end else if (minprec <= 5) and (tok = '+'  ) then begin nexttok; n := n + expression(6);
    end else if (minprec <= 5) and (tok = '-'  ) then begin nexttok; n := n - expression(6);
    end else if (minprec <= 6) and (tok = '*'  ) then begin nexttok; n := n * expression(7);
    end else if (minprec <= 6) and ((tok = '/') or (tok = '\')) then begin nexttok; n := n div expression(7);
    end else if (minprec <= 6) and (tok = 'mod') then begin nexttok; n := n mod expression(7);
    end else if (minprec <= 8) and (tok = '^'  ) then begin nexttok; n := n ** expression(9);
    end else break;
  end;
  expression := n;
end;

function getvarindex: longint;
  var s: string;
begin
  if toktype <> 'ident' then begin
    writeln('Not a variable:', tok);
    errors := true;
    getvarindex := 0;
  end else begin
    s := tok[1];
    getvarindex := ord(s[1]) - ord('a');
  end;
end;

procedure expect(s: string);
begin
  if not accept(s) then begin
    writeln('(', curline, ') expecting ', s, ' but found ', tok, ' =>', pgm[curline]);
    errors := true;
  end;
end;

function accept(s: string): boolean;
begin
  accept := false;
  if tok = s then begin
    accept := true;
    nexttok;
  end;
end;

procedure initlex(n: longint);
begin
  curline := n; textp := 1;
  initlex2();
end;

procedure initlex2;
begin
  need_colon := false;
  thelin := pgm[curline];
  thech := ' ';
  nexttok;
end;

procedure nexttok;
begin
  tok := ''; toktype := '';
  while thech <= ' ' do begin
    if thech = #0 then exit;
    getch;
  end;
  tok := thech; getch;
  case tok of
    'a'..'z', 'A'.. 'Z':
      begin readident; if tok = 'rem' then skiptoeol; end;
    '0'..'9': readint;
    '''': skiptoeol;
    '"': readstr;
    '#','(',')','*','+',',','-','/',':',';','<','=','>','?','@','\','^':
      begin
        toktype := 'punct';
        if ((tok = '<') and ((thech = '>') or (thech = '='))) or ((tok = '>') and (thech = '=')) then begin
          tok := tok + thech;
          getch;
        end;
      end;
    else
      writeln('(', curline, ') ', 'What?', tok, ' : ', thelin);
      errors := true;
  end;
end;

procedure skiptoeol;
begin
  tok := ''; toktype := '';
  textp := length(thelin) + 1;
end;

procedure readint;
begin
  toktype := 'number';
  while isDigit(thech) do begin
    tok := tok + thech;
    getch;
  end;
  num := strToInt(tok);
end;

procedure readident;
begin
  toktype := 'ident';
  while isLetter(thech) do begin
    tok := tok + thech;
    getch;
  end;
  tok := Lowercase(tok);
end;

procedure readstr; { store double quote as first char of string, to distinguish from idents}
begin
  toktype := 'string';
  while thech <> '"' do begin { while not a double quote }
    if thech = #0 then begin
      writeln('String not terminated'); errors := true;
      exit;
    end;
    tok := tok + thech;
    getch;
  end;
  getch;  { skip closing double quote }
end;

procedure getch;
var s: string;
begin
  if textp > length(thelin) then begin
    thech := #0;
  end else begin
    s := Copy(thelin, textp, 1);
    thech := s[1];
    inc(textp);
  end;
end;

begin
  main;
end.
