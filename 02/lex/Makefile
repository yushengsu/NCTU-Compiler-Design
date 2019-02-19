#makefile for scanner
LEX = lex
LEXFN = lex.l
CC = gcc
CFLAGS = -O2
LIBS = -lfl -lbsd
RM = rm -f
SCANNERN = scanner
SCANNERSN = scanner.c
TESTFN = whole.cm
all: scanner

scanner: lex
	$(CC) -o $(SCANNERN) $(SCANNERSN) $(LIBS)
lex:
	$(LEX) -o $(SCANNERSN) $(LEXFN) 
test:
	./$(SCANNERN) $(TESTFN) 
clean:
	$(RM) $(SCANNERN)
	$(RM) $(SCANNERSN)
	

