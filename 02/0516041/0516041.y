%{
#include <stdio.h>
#include <stdlib.h>

extern int linenum;             /* declared in lex.l */
extern FILE *yyin;              /* declared by lex */
extern char *yytext;            /* declared by lex */
extern char buf[256];           /* declared in lex.l */
%}

%token SEMICOLON    /* ; */
%token COMMA		/* , */

%token ID           /* identifier */

%token L_PAREN R_PAREN /* (, ) */
%token L_BRACKET R_BRACKET /* [, ] */
%token L_PARAN R_PARAN /* {, } */
    
/* keyword */
%token READ WHILE DO IF TRUE FALSE FOR CONST PRINT CONTINUE BREAK RETURN

%token INT BOOL VOID FLOAT DOUBLE STRING /* type */
%nonassoc ELSE

%token INT_VAL FLOAT_VAL SCI STRING_VAL

%right ASSIGN
%left OR 
%left AND
%right NOT
%left EQ NE GT GE LT LE
%left ADD SUB
%left MUL DIV MOD

%%

program : declaration_list funct_def decl_and_def_list
		;

decl_and_def_list	: decl_and_def_list const_decl
					| decl_and_def_list var_decl
					| decl_and_def_list funct_decl
					| decl_and_def_list funct_def
					| /*epsilon*/
					;

declaration_list : declaration_list const_decl
                 | declaration_list var_decl
                 | declaration_list funct_decl
                 | /*epsilon*/
				 ;

const_decl : CONST type const_list SEMICOLON
           ;

const_list : const_list COMMA const
           | const
           ;

const : ID ASSIGN constant
      ;

var_decl : type ident_list SEMICOLON
		 ;      				 

ident_list : ident_list COMMA ident
		   | ident
		   ;

ident : ident_init
	  | ident_no_init
	  ;

ident_init : ID ASSIGN expression
		   | ID array ASSIGN array_init
		   ;

ident_no_init : ID
			  | ID array
			  ;

array_init : L_PARAN expression_list R_PARAN
		   ;

array : array L_BRACKET INT_VAL R_BRACKET
      | L_BRACKET INT_VAL R_BRACKET
      ;

funct_decl : type ID L_PAREN arg_list R_PAREN SEMICOLON
		   | funct_decl_void
		   ;

funct_decl_void : VOID ID L_PAREN arg_list R_PAREN SEMICOLON
				;		   

funct_def : type ID L_PAREN arg_list R_PAREN compound
		  | funct_def_void
		  ;

funct_def_void : VOID ID L_PAREN arg_list R_PAREN compound
		   	   ;

arg_list : sub_arg_list
         | /* epsilon */
         ;
sub_arg_list : sub_arg_list COMMA argument
             | argument
             ;
argument : type ident_no_init
         ;

expression : expression ADD expression
		   | expression SUB expression
		   | expression MUL expression
		   | expression DIV expression
		   | expression MOD expression
		   | expression LT expression
		   | expression LE expression
		   | expression NE expression
		   | expression GE expression
		   | expression GT expression
		   | expression EQ expression
		   | expression AND expression
		   | expression OR expression
		   | NOT expression
		   | SUB expression %prec MUL
		   | L_PAREN expression R_PAREN %prec MUL
		   | constant
		   | variable_ref
		   | function_head
		   ;

variable_ref : ID
			 | array_ref
			 ;

array_ref : ID sub_array_ref
		  ;

sub_array_ref : sub_array_ref sub_expression
			  | sub_expression
			  ;

sub_expression : L_BRACKET expression R_BRACKET
			   ;

function_head : ID L_PAREN expression_list R_PAREN
			  ;

expression_list : non_epsilon_expression_list
				| /*epsilon*/
				;

non_epsilon_expression_list : non_epsilon_expression_list COMMA expression
							| expression
							;	   

constant : INT_VAL
		 | FLOAT_VAL
		 | SCI
		 | STRING_VAL
		 | TRUE
		 | FALSE
		 ;

type : INT
	 | BOOL
	 | FLOAT
	 | DOUBLE
	 | STRING
     ; 

statement : compound 
          | simple
          | conditional
          | while
          | for
          | jump
          ;

compound : L_PARAN compound_content R_PARAN
         ;	   	   	

compound_content : compound_content const_decl
                 | compound_content var_decl
                 | compound_content statement
                 | /* epsilon */
                 ;

simple : simple_content SEMICOLON
       ;

simple_content : variable_ref ASSIGN expression
               | PRINT expression
               | READ variable_ref
               | expression
               ;

conditional : IF L_PAREN expression R_PAREN compound ELSE compound 
            | IF L_PAREN expression R_PAREN compound
            ;

while : WHILE L_PAREN expression R_PAREN compound
      | DO compound WHILE L_PAREN expression R_PAREN SEMICOLON
      ;

for : FOR L_PAREN for_expression SEMICOLON for_expression SEMICOLON for_expression R_PAREN compound
    ;

for_expression : ID ASSIGN expression
			   | expression   
			   ;

jump : RETURN expression SEMICOLON
     | BREAK SEMICOLON
     | CONTINUE SEMICOLON
     ;

%%

int yyerror( char *msg )
{
  fprintf( stderr, "\n|--------------------------------------------------------------------------\n" );
	fprintf( stderr, "| Error found in Line #%d: %s\n", linenum, buf );
	fprintf( stderr, "|\n" );
	fprintf( stderr, "| Unmatched token: %s\n", yytext );
  fprintf( stderr, "|--------------------------------------------------------------------------\n" );
  exit(-1);
}

int  main( int argc, char **argv )
{
	if( argc != 2 ) {
		fprintf(  stdout,  "Usage:  ./parser  [filename]\n"  );
		exit(0);
	}

	FILE *fp = fopen( argv[1], "r" );
	
	if( fp == NULL )  {
		fprintf( stdout, "Open  file  error\n" );
		exit(-1);
	}
	
	yyin = fp;
	yyparse();

	fprintf( stdout, "\n" );
	fprintf( stdout, "|--------------------------------|\n" );
	fprintf( stdout, "|  There is no syntactic error!  |\n" );
	fprintf( stdout, "|--------------------------------|\n" );
	exit(0);
}
