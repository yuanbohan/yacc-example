goyacc sample
------

help you to understand how to use goyacc to write your own parser.
this is just a sample to write a very simple and limited calculator, forked from [goyacc expr](https://github.com/golang/tools/tree/master/cmd/goyacc/testdata/expr)

```
./expr
> 1 + 2
3
> 3 * 4 / 2
6
> 5
5
```

# Install

```shell
go install golang.org/x/tools/cmd/goyacc@latest
goyacc expr.y
go build -o expr y.go
./expr
```

# Usage

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

# Steps

* write your lexer

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

* write your parser (*.y file)
* generate parser (*.go file) by goyacc

## Resources

  * https://cloud.tencent.com/developer/article/1744609
  * https://about.sourcegraph.com/blog/go/gophercon-2018-how-to-write-a-parser-in-go
  * https://github.com/golang/tools/tree/master/cmd/goyacc/testdata/expr
