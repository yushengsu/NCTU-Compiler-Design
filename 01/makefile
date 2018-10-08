all: scanner

scanner: lex.yy.c
	gcc -o scanner lex.yy.c -lfl
lex.yy.c: 0516041.l
	lex 0516041.l
clean:
	rm lex.yy.c scanner
