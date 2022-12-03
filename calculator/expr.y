%{
package main

import (
    "bufio"
    "bytes"
    "fmt"
    "io"
    "log"
    "os"
    "strconv"
    "unicode/utf8"
)
%}

%union{
    num int
}

%type   <num> top expr
%token  '+' '-' '*' '/'
%token  <num> NUM

%%

top:
    expr {
        fmt.Println($$)
    }
expr:
    NUM
|   expr '+' NUM {
        $$ = $1 + $3
    }
|   expr '-' NUM {
        $$ = $1 - $3
    }
|   expr '*' NUM {
        $$ = $1 * $3
    }
|   expr '/' NUM {
        $$ = $1 / $3
    }

%%

const eof = 0

type yyLex struct {
    line []byte
    peek rune
}

// The parser calls this method to get each new token. This
// implementation returns operators and NUM.
func (x *yyLex) Lex(yylval *yySymType) int {
    for {
        c := x.next()
        switch c {
        case eof:
            return eof
        case '0', '1', '2', '3', '4', '5', '6', '7', '8', '9':
            return x.num(c, yylval)
        case '+', '-', '*', '/':
            return int(c)

        // Recognize Unicode multiplication and division
        // symbols, returning what the parser expects.
        case '×':
            return '*'
        case '÷':
            return '/'

        case ' ', '\t', '\n', '\r':
        default:
            log.Printf("unrecognized character %q", c)
        }
    }
}

// Lex a number.
func (x *yyLex) num(c rune, yylval *yySymType) int {
    add := func(b *bytes.Buffer, c rune) {
        if _, err := b.WriteRune(c); err != nil {
            log.Fatalf("WriteRune: %s", err)
        }
    }
    var b bytes.Buffer
    add(&b, c)
L:
    for {
        c = x.next()
        switch c {
        case '0', '1', '2', '3', '4', '5', '6', '7', '8', '9':
            add(&b, c)
        default:
            break L
        }
    }
    if c != eof {
        x.peek = c
    }
    digit, err := strconv.Atoi(b.String())
    if err != nil {
        log.Printf("bad number %q", b.String())
        return eof
    }
    yylval.num = digit
    return NUM
}

// Return the next rune for the lexer.
func (x *yyLex) next() rune {
    if x.peek != eof {
        r := x.peek
        x.peek = eof
        return r
    }
    if len(x.line) == 0 {
        return eof
    }
    c, size := utf8.DecodeRune(x.line)
    x.line = x.line[size:]
    if c == utf8.RuneError && size == 1 {
        log.Print("invalid utf8")
        return x.next()
    }
    return c
}

// The parser calls this method on a parse error.
func (x *yyLex) Error(s string) {
    log.Printf("parse error: %s", s)
}

func main() {
    in := bufio.NewReader(os.Stdin)
    for {
        if _, err := os.Stdout.WriteString("> "); err != nil {
            log.Fatalf("WriteString: %s", err)
        }
        line, err := in.ReadBytes('\n')
        if err == io.EOF {
            return
        }
        if err != nil {
            log.Fatalf("ReadBytes: %s", err)
        }

        yyParse(&yyLex{line: line})
    }
}
