/* very simple */
%{
package main

import (
    "bufio"
    "fmt"
    "io"
    "log"
    "os"
    "unicode"
    "unicode/utf8"
)
%}

%union{}

%left 't'
%left 'e' // this will let parser know that e has higher precedence than t.
          // the purpose is to resolve the shift/reduce conflict.

%%

top:
     expr
     {
         fmt.Println("accepted.")
     }

expr:
     'a'
|    'i' expr 't' expr 'e' expr
|    'i' expr 't' expr

%%

const eof = 0

type yyLex struct {
    line []byte
}

func (x *yyLex) Lex(yylval *yySymType) int {
    for b := x.next(); b != eof; b = x.next() {
        switch {
        case unicode.IsSpace(b):
            continue
        default:
            return int(b)
        }
    }
    return eof
}

func (x *yyLex) next() rune {
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
