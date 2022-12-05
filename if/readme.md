if/then/else
------

a simple and limited if/then/else expression

# Install

```
goyacc expr.y
go build -o expr y.go
./expr
> a
accepted.
> i a t a
accepted.
> i a t a e a
accepted.
> b
2022/12/05 11:42:57 parse error: syntax error
> i a t b
2022/12/05 11:43:04 parse error: syntax error
> i a t a e b
2022/12/05 11:43:08 parse error: syntax error
> i
2022/12/05 11:43:10 parse error: syntax error
>
2022/12/05 11:43:11 parse error: syntax error
>
```
