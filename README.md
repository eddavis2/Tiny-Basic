# TinyBasic
Interpreters for Tiny Basic written in GW-Basic, C, C#, Java, Python, Pascal, VB.Net and others. 
These are Pure interpreters, e.g., no byte code, no AST, not even pre-tokenized - although the lexical analyzer is separate from the parser.

For instance, [gw.bas](GW-Basic/gw.bas) is an interpreter for Tiny Basic written in GWBasic.

It supports:
- bye/quit, clear, cls, end/stop, help, list, load, new, run, tron, troff
- for <var> = <expr1> to <expr2> ... next <var>
- gosub <expr> ... return
- goto <expr>
- if <expr> then <statement>
- input [prompt,] <var>
- [let] <var>=<expr>
- print <expr|string>[,<expr|string>][;]
- rem <anystring> or '<anystring>
- Operators: + - * / < <= > >= <> =
- Integer variables a..z, and single integer array: @(expr)
- Functions: abs(expr), asc(ch), rnd(expr), sgn(expr)
- ":" to allow multiple statements per line.
- Line numbers are required for programs, but has an interactive mode too.

Has enough features that it can run a Tiny Basic version of Star Trek, and a Tiny Basic version of MineSweeper.

The GW-Basic version was tested in [DoxBox](https://www.dosbox.com) running GWBASIC version 3.23, and with [PC-Basic](https://robhagemans.github.io/pcbasic/) .

- [Star Trek](samples/strek-tb.bas) is a version of the Star Trek game, that most interpreters can run.
- [MineSweeper](samples/minesweeper.bas) is a version of the Mine Sweeper game, that most interpreters can run.

![Tiny Basic](images/TinyBasicRunningStarTrek.png)

If you just enter a statement without a line number, it is run interactively:

![image](images/1liner.png)

