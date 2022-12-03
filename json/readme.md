json
------

a simple and limited json parser

# Install

```
goyacc expr.y
go build -o expr y.go
./expr
> {}
map[]
> {"hello": 1}
map[hello:1]
```
