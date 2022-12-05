goyacc examples
------

help you to understand how to use goyacc to write your own parser.

- [if/then/else](./if)
- [calculator](./calculator)
- [json](./json)

## Install

```shell
go install golang.org/x/tools/cmd/goyacc@latest
```

## Usage

```shell
goyacc -h

Usage of goyacc:
  -l	disable line directives
  -o string
        parser output (default "y.go")
  -p string
        name prefix to use in generated code (default "yy")
  -v string
        create parsing tables (default "y.output")
```

## Steps

- write your lexer

```go
// The parser uses the type <prefix>Lex as a lexer. It must provide
// the methods Lex(*<prefix>SymType) int and Error(string).

type <prefix>Lex struct {
    line []byte
    peek rune
}

// The parser calls this method to get each new token. This
// implementation returns operators and NUM.
func (x *yyLex) Lex(yylval *yySymType) int {
...
}

// The parser calls this method on a parse error.
func (x *yyLex) Error(s string) {
    ....
}
```

- write your parser (*.y file)
- generate parser (*.go file) by goyacc

## parser Grammer (*.y file)

use Backus Naur Form (BNF)

- `%token`

- `%type`

the name in %type MUST be defined in %union, and %type connects the type defined in %union with symbols

- `%union`

- `func (x *yyLex) Lex(yylval *yySymType) int {}`

  - return. the type of the token. integer.
  - real value. stored in yylval

- rule

`$$`: symbol on the left side of colon
`$1` `$2` ...: symbol on the right side of colon
`{ ... }` : action invoked

```
...
expr:
    NUM
|   expr '+' NUM {
        $$ = $1 + $3
    }
...

$$ : expr (outer)
$1 : expr (inner)
$3 : NUM
```

- final call

```
func yyParse(yylex yyLexer) int {
    return yyNewParser().Parse(yylex)
}
```

yylex is your lex struct which implemented the yyLexer interface


## parser Example

```
%union{
    num int                // union will be a yySymType struct, and all fields in union will be copied into struct
}

%type   <num> top expr     // indicate parser to use num field (which is (yylval *yySymType) in goyacc)
%token  '+' '-' '*' '/'    // will not use yylval. Only indicate parser to use the token as ASCII code
%token  <num> NUM          // indicate parser to use yylval.num

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
```

## Resources

  * https://zh.wikipedia.org/wiki/LALR%E8%AF%AD%E6%B3%95%E5%88%86%E6%9E%90%E5%99%A8
  * https://cloud.tencent.com/developer/article/1744609
  * https://mp.weixin.qq.com/s/qSbftFcRfigqEl_2-bfw3A
  * https://about.sourcegraph.com/blog/go/gophercon-2018-how-to-write-a-parser-in-go
  * https://silcnitc.github.io/yacc.html
  * https://github.com/sougou/parser_tutorial
  * https://github.com/u2takey/learn-yacc
  * https://github.com/golang/tools/tree/master/cmd/goyacc/testdata/expr
