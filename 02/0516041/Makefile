TARGET = parser
OBJECT = lex.yy.c y.tab.h y.tab.c y.output
CC = gcc -g
LEX = flex
LIBS = -ly -ll
YACC = yacc -d -v

all: lex.yy.c y.tab.c
	$(CC) lex.yy.c y.tab.c -o $(TARGET) $(LIBS)

y.tab.c: 0516041.y
	$(YACC) 0516041.y

lex.yy.c: 0516041.l
	$(LEX) 0516041.l

clean:
	rm -f $(TARGET) $(OBJECT)
