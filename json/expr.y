%{
package main

import (
    "bufio"
    "bytes"
    "errors"
    "fmt"
    "io"
    "log"
    "os"
    "strconv"
    "strings"
    "unicode"
)

type pair struct {
  key string
  val any
}

func setResult(l yyLexer, v map[string]any) {
  l.(*lex).result = v
}
%}

%union{
  obj map[string]any
  list []any
  pair pair
  val any
}

%token LexError
%token <val> String Number Literal

%type <obj> object members
%type <pair> pair
%type <val> array
%type <list> elements
%type <val> value

%start object

%%

object: '{' members '}'
  {
    $$ = $2
    setResult(yylex, $$)
  }

members:
  {
    $$ = map[string]any{}
  }
| pair
  {
    $$ = map[string]any{
      $1.key: $1.val,
    }
  }
| members ',' pair
  {
    $1[$3.key] = $3.val
    $$ = $1
  }

pair: String ':' value
  {
    $$ = pair{key: $1.(string), val: $3}
  }

array: '[' elements ']'
  {
    $$ = $2
  }

elements:
  {
    $$ = []any{}
  }
| value
  {
    $$ = []any{$1}
  }
| elements ',' value
  {
    $$ = append($1, $3)
  }

value:
  String
| Number
| Literal
| object
  {
    $$ = $1
  }
| array

%%

type lex struct {
    input  []byte
    pos    int
    result map[string]any
    err    error
}

func Parse(input []byte) (map[string]any, error) {
    l := &lex{input: input}
    _ = yyParse(l)
    return l.result, l.err
}

// Lex satisfies yyLexer.
func (l *lex) Lex(lval *yySymType) int {
    return l.scanNormal(lval)
}

func (l *lex) scanNormal(lval *yySymType) int {
    for b := l.next(); b != 0; b = l.next() {
        switch {
        case unicode.IsSpace(rune(b)):
            continue
        case b == '"':
            return l.scanString(lval)
        case unicode.IsDigit(rune(b)) || b == '+' || b == '-':
            l.backup()
            return l.scanNum(lval)
        case unicode.IsLetter(rune(b)):
            l.backup()
            return l.scanLiteral(lval)
        default:
            return int(b)
        }
    }
    return 0
}

var escape = map[byte]byte{
    '"':  '"',
    '\\': '\\',
    '/':  '/',
    'b':  '\b',
    'f':  '\f',
    'n':  '\n',
    'r':  '\r',
    't':  '\t',
}

func (l *lex) scanString(lval *yySymType) int {
    buf := bytes.NewBuffer(nil)
    for b := l.next(); b != 0; b = l.next() {
        switch b {
        case '\\':
            // TODO(sougou): handle \uxxxx construct.
            b2 := escape[l.next()]
            if b2 == 0 {
                return LexError
            }
            buf.WriteByte(b2)
        case '"':
            lval.val = buf.String()
            return String
        default:
            buf.WriteByte(b)
        }
    }
    return LexError
}

func (l *lex) scanNum(lval *yySymType) int {
    buf := bytes.NewBuffer(nil)
    for {
        b := l.next()
        switch {
        case unicode.IsDigit(rune(b)):
            buf.WriteByte(b)
        case strings.IndexByte(".+-eE", b) != -1:
            buf.WriteByte(b)
        default:
            l.backup()
            val, err := strconv.ParseFloat(buf.String(), 64)
            if err != nil {
                return LexError
            }
            lval.val = val
            return Number
        }
    }
}

var literal = map[string]any{
    "true":  true,
    "false": false,
    "null":  nil,
}

func (l *lex) scanLiteral(lval *yySymType) int {
    buf := bytes.NewBuffer(nil)
    for {
        b := l.next()
        switch {
        case unicode.IsLetter(rune(b)):
            buf.WriteByte(b)
        default:
            l.backup()
            val, ok := literal[buf.String()]
            if !ok {
                return LexError
            }
            lval.val = val
            return Literal
        }
    }
}

func (l *lex) backup() {
    if l.pos == -1 {
        return
    }
    l.pos--
}

func (l *lex) next() byte {
    if l.pos >= len(l.input) || l.pos == -1 {
        l.pos = -1
        return 0
    }
    l.pos++
    return l.input[l.pos-1]
}

// Error satisfies yyLexer.
func (l *lex) Error(s string) {
    l.err = errors.New(s)
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

        out, err := Parse(line)
        if err != nil {
            log.Fatalf("parse err: %s", err)
        }
        fmt.Printf("%v\n", out)
    }
}
