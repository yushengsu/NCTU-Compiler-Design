%{
#include <map>
#include <stack>
#include <string>
#include <vector>
#include <utility>
#include <sstream>
#include <stdio.h>
#include <fstream>
#include <stdlib.h>
#include <string.h>
#include <iostream>
#include "header.h"
#include "symtab.h"
#include "semcheck.h"
using namespace std;
extern "C" int yylex();

extern int linenum;
extern FILE	*yyin;
extern char	*yytext;
extern char buf[256];
extern int Opt_Symbol;		/* declared in lex.l */
extern string fname;
extern ofstream fout;
extern "C" int yylex();

int yyerror(const char*);

int scope = 0;
char fileName[256];
struct SymTable *symbolTable;
__BOOLEAN paramError;
struct PType *funcReturn;
__BOOLEAN semError = __FALSE;
int inloop = 0;
vector<string> localVar;
map<string,string> globalVar;
SEMTYPE var_decl_type;
bool insidemain = false;
int relationL = 0;
const int MAXSIZE = 100;
int Lstk[256];
int Lstksize = 0;
int Label = 0;
bool isconst_decl = false;
int Jstk[256];
int Jstksize = 0;
int param_count = 0;
bool have_return = false;
bool invoke = false;
string invokename = "";
vector<pair<string, float> > double_decl;

struct constVal {
	int iVal;
	float fVal;
	double dVal;
	bool bVal;
} constval;
%}

%union {
	int intVal;
	float floatVal;	
	char *lexeme;
	struct idNode_sem *id;
	struct ConstAttr *constVal;
	struct PType *ptype;
	struct param_sem *par;
	struct expr_sem *exprs;
	struct expr_sem_node *exprNode;
	struct constParam *constNode;
	struct varDeclParam* varDeclNode;
};

%token	LE_OP NE_OP GE_OP EQ_OP AND_OP OR_OP
%token	READ BOOLEAN WHILE DO IF ELSE TRUE FALSE FOR INT PRINT BOOL VOID FLOAT DOUBLE STRING CONTINUE BREAK RETURN CONST
%token	L_PAREN R_PAREN COMMA SEMICOLON ML_BRACE MR_BRACE L_BRACE R_BRACE ADD_OP SUB_OP MUL_OP DIV_OP MOD_OP ASSIGN_OP LT_OP GT_OP NOT_OP

%token <lexeme>ID
%token <intVal>INT_CONST 
%token <floatVal>FLOAT_CONST
%token <floatVal>SCIENTIFIC
%token <lexeme>STR_CONST

%type<ptype> scalar_type dim
%type<par> array_decl parameter_list
%type<constVal> literal_const
%type<constNode> const_list 
%type<exprs> variable_reference logical_expression logical_term logical_factor relation_expression arithmetic_expression term factor logical_expression_list literal_list initial_array
%type<intVal> relation_operator add_op mul_op dimension
%type<varDeclNode> identifier_list


%start program
%%

program :		decl_list 
			    funct_def
				decl_and_def_list 
				{
					if(Opt_Symbol == 1)
					printSymTable( symbolTable, scope );	
				
				}
		;

decl_list : decl_list var_decl
		  | decl_list const_decl
		  | decl_list funct_decl
		  |
		  ;


decl_and_def_list : decl_and_def_list var_decl
				  | decl_and_def_list const_decl
				  | decl_and_def_list funct_decl
				  | decl_and_def_list funct_def
				  | 
				  ;

		  
funct_def : scalar_type ID L_PAREN R_PAREN 
			{
				funcReturn = $1; 
				struct SymNode *node;
				node = findFuncDeclaration( symbolTable, $2 );
				
				if( node != 0 ){
					verifyFuncDeclaration( symbolTable, 0, $1, node );
				}
				else{
					insertFuncIntoSymTable( symbolTable, $2, 0, $1, scope, __TRUE, globalVar);
				}
				//gen
				fout << ".method public static " ;
				if (string($2) == "main") {
					fout << "main([Ljava/lang/String;)V" << endl;
					insidemain = true;
					localVar.emplace(localVar.begin(),"THIS");
					for (int i = 0; i < double_decl.size(); ++i) {
						fout << "ldc2_w " << double_decl[i].second << endl; 
						fout << "putstatic "  << fname << "/" << double_decl[i].first << " " << globalVar[double_decl[i].first] << endl;
					}
				}
				else {
					fout << string($2) << globalVar[string($2)]<< endl;
				} 
				fout << ".limit stack " << MAXSIZE << endl;
				fout << ".limit locals " << MAXSIZE << endl;
				fout << "new java/util/Scanner" << endl;
				fout << "dup" << endl;
				fout << "getstatic java/lang/System/in Ljava/io/InputStream;" << endl;
				fout << "invokespecial java/util/Scanner/<init>(Ljava/io/InputStream;)V" << endl;
				fout << "putstatic " << fname << "/_sc Ljava/util/Scanner;" << endl;
			}
			compound_statement { 
				funcReturn = 0;
				if(!have_return) fout << "return" << endl; 
				fout << ".end method" << endl;	
				insidemain = false;
				have_return = false;
				localVar.clear();
			}	
		  | scalar_type ID L_PAREN parameter_list R_PAREN  
			{				
				//gen

				funcReturn = $1;
				
				paramError = checkFuncParam( $4 );
				if( paramError == __TRUE ){
					fprintf( stdout, "########## Error at Line#%d: param(s) with several fault!! ##########\n", linenum );
					semError = __TRUE;
				}
				// check and insert function into symbol table
				else{
					struct SymNode *node;
					node = findFuncDeclaration( symbolTable, $2 );

					if( node != 0 ){
						if(verifyFuncDeclaration( symbolTable, $4, $1, node ) == __TRUE){	
							insertParamIntoSymTable( symbolTable, $4, scope+1);
						}				
					}
					else{
						insertParamIntoSymTable( symbolTable, $4, scope+1 );				
						insertFuncIntoSymTable( symbolTable, $2, $4, $1, scope, __TRUE, globalVar);
					}
				}

				fout << ".method public static " ;
				if (string($2) == "main") {
					fout << "main([Ljava/lang/String;)V" << endl;
					insidemain = true;
					localVar.emplace(localVar.begin(),"THIS");
					for (int i = 0; i < double_decl.size(); ++i) {
						fout << "ldc2_w " << double_decl[i].second << endl; 
						fout << "putstatic "  << fname << "/" << double_decl[i].first << " " << globalVar[double_decl[i].first] << endl;
					}
				} else 
					fout << string($2) << globalVar[string($2)]<< endl;
				fout << ".limit stack " << MAXSIZE << endl;
				fout << ".limit locals " << MAXSIZE << endl;
				fout << "new java/util/Scanner" << endl;
				fout << "dup" << endl;
				fout << "getstatic java/lang/System/in Ljava/io/InputStream;" << endl;
				fout << "invokespecial java/util/Scanner/<init>(Ljava/io/InputStream;)V" << endl;
				fout << "putstatic " << fname << "/_sc Ljava/util/Scanner;" << endl;
				
			} 	
			compound_statement { 
				funcReturn = 0;
				if(!have_return) fout << "return" << endl;
				fout << ".end method" << endl;
				localVar.clear();
				insidemain = false;
				have_return = false;
			}
		  | VOID ID L_PAREN R_PAREN 
			{
				funcReturn = createPType(VOID_t); 
				struct SymNode *node;
				node = findFuncDeclaration( symbolTable, $2 );

				if( node != 0 ){
					verifyFuncDeclaration( symbolTable, 0, createPType( VOID_t ), node );					
				}
				else{
					insertFuncIntoSymTable( symbolTable, $2, 0, createPType( VOID_t ), scope, __TRUE, globalVar);	
				}
				fout << ".method public static " ;
				if (string($2) == "main") {
					fout << "main([Ljava/lang/String;)V" << endl;
					insidemain = true;
					localVar.emplace(localVar.begin(),"THIS");
					for (int i = 0; i < double_decl.size(); ++i) {
						fout << "ldc2_w " << double_decl[i].second << endl; 
						fout << "putstatic "  << fname << "/" << double_decl[i].first << " " << globalVar[double_decl[i].first] << endl;
					}
				} else 
					fout << string($2) << globalVar[string($2)]<< endl;
				fout << ".limit stack " << MAXSIZE << endl;
				fout << ".limit locals " << MAXSIZE << endl;
				fout << "new java/util/Scanner" << endl;
				fout << "dup" << endl;
				fout << "getstatic java/lang/System/in Ljava/io/InputStream;" << endl;
				fout << "invokespecial java/util/Scanner/<init>(Ljava/io/InputStream;)V" << endl;
				fout << "putstatic " << fname << "/_sc Ljava/util/Scanner;" << endl;
			}
			compound_statement { 
				funcReturn = 0; 
				fout << "return" << endl;
				fout << ".end method" << endl;
				localVar.clear();
				insidemain = false;
				have_return = false;
			}	
		  | VOID ID L_PAREN parameter_list R_PAREN
			{									
				funcReturn = createPType(VOID_t);
				
				paramError = checkFuncParam( $4 );
				if( paramError == __TRUE ){
					fprintf( stdout, "########## Error at Line#%d: param(s) with several fault!! ##########\n", linenum );
					semError = __TRUE;
				}
				// check and insert function into symbol table
				else{
					struct SymNode *node;
					node = findFuncDeclaration( symbolTable, $2 );

					if( node != 0 ){
						if(verifyFuncDeclaration( symbolTable, $4, createPType( VOID_t ), node ) == __TRUE){	
							insertParamIntoSymTable( symbolTable, $4, scope+1 );				
						}
					}
					else{
						insertParamIntoSymTable( symbolTable, $4, scope+1 );				
						insertFuncIntoSymTable( symbolTable, $2, $4, createPType( VOID_t ), scope, __TRUE, globalVar);
					}
				}
				fout << ".method public static " ;
				if (string($2) == "main") {
					fout << "main([Ljava/lang/String;)V" << endl;
					insidemain = true;
					localVar.emplace(localVar.begin(),"THIS");
					for (int i = 0; i < double_decl.size(); ++i) {
						fout << "ldc2_w " << double_decl[i].second << endl; 
						fout << "putstatic "  << fname << "/" << double_decl[i].first << " " << globalVar[double_decl[i].first] << endl;
					}
				} else 
					fout << string($2) << globalVar[string($2)]<< endl;
				fout << ".limit stack " << MAXSIZE << endl;
				fout << ".limit locals " << MAXSIZE << endl;
				fout << "new java/util/Scanner" << endl;
				fout << "dup" << endl;
				fout << "getstatic java/lang/System/in Ljava/io/InputStream;" << endl;
				fout << "invokespecial java/util/Scanner/<init>(Ljava/io/InputStream;)V" << endl;
				fout << "putstatic " << fname << "/_sc Ljava/util/Scanner;" << endl;
			} 
			compound_statement { 
				funcReturn = 0; 
				fout << "return" << endl;
				fout << ".end method" << endl;
				localVar.clear();
				insidemain = false;
				have_return = false;
			}		  
		  ;

funct_decl : scalar_type ID L_PAREN R_PAREN SEMICOLON
			{
				//map<string, string> fakemap;
				insertFuncIntoSymTable( symbolTable, $2, 0, $1, scope, __FALSE, globalVar);	
			}
		   | scalar_type ID L_PAREN parameter_list R_PAREN SEMICOLON
		    {
				paramError = checkFuncParam( $4 );
				if( paramError == __TRUE ){
					fprintf( stdout, "########## Error at Line#%d: param(s) with several fault!! ##########\n", linenum );
					semError = __TRUE;
				}
				else {
					//map<string, string> fakemap;
					insertFuncIntoSymTable( symbolTable, $2, $4, $1, scope, __FALSE, globalVar);
				}
			}
		   | VOID ID L_PAREN R_PAREN SEMICOLON
			{				
				//map<string, string> fakemap;
				insertFuncIntoSymTable( symbolTable, $2, 0, createPType( VOID_t ), scope, __FALSE, globalVar);
			}
		   | VOID ID L_PAREN parameter_list R_PAREN SEMICOLON
			{
				paramError = checkFuncParam( $4 );
				if( paramError == __TRUE ){
					fprintf( stdout, "########## Error at Line#%d: param(s) with several fault!! ##########\n", linenum );
					semError = __TRUE;	
				}
				else {
					//map<string, string> fakemap;
					insertFuncIntoSymTable( symbolTable, $2, $4, createPType( VOID_t ), scope, __FALSE, globalVar);
				}
			}
		   ;

parameter_list : parameter_list COMMA scalar_type ID
			   {
				struct param_sem *ptr;
				ptr = createParam( createIdList( $4 ), $3 );
				param_sem_addParam( $1, ptr );
				$$ = $1;
				localVar.emplace_back(string($4));
			   }
			   | parameter_list COMMA scalar_type array_decl
			   {
				$4->pType->type= $3->type;
				param_sem_addParam( $1, $4 );
				$$ = $1;
			   }
			   | scalar_type array_decl 
			   { 
				$2->pType->type = $1->type;  
				$$ = $2;
			   }
			   | scalar_type ID { $$ = createParam( createIdList( $2 ), $1 );
				localVar.emplace_back(string($2));
			   }
			   ;

var_decl :  scalar_type identifier_list SEMICOLON
			{
				struct varDeclParam *ptr;
				struct SymNode *newNode;
				int i = 0;	
				for( ptr=$2 ; ptr!=0 ; ptr=(ptr->next) ) {						
					if( verifyRedeclaration( symbolTable, ptr->para->idlist->value, scope ) == __FALSE ) { }
					else {
						if( verifyVarInitValue( $1, ptr, symbolTable, scope ) ==  __TRUE ){	
							newNode = createVarNode( ptr->para->idlist->value, scope, ptr->para->pType );
							insertTab( symbolTable, newNode );											
							/*
							if (scope == 0) {
								fout << ".field public static " << ptr->para->idlist->value << " " << typestr($1->type) << endl;
								globalVar.emplace(ptr->para->idlist->value, typestr($1->type));
							} else {
								localVar.emplace_back(ptr->para->idlist->value);
							}
							*/
						}
					}
				}
			}
			;

identifier_list : identifier_list COMMA ID
				{					
					struct param_sem *ptr;	
					struct varDeclParam *vptr;				
					ptr = createParam( createIdList( $3 ), createPType( VOID_t ) );
					vptr = createVarDeclParam( ptr, 0 );	
					addVarDeclParam( $1, vptr );
					$$ = $1; 					
					if (scope == 0) {
						fout << ".field public static " << string($3) << " " << typestr(var_decl_type) << endl;
						globalVar.emplace(string($3), typestr(var_decl_type));
					} else {
						if (var_decl_type == DOUBLE_t) {
							localVar.emplace_back(string($3));
							localVar.emplace_back(" ");
						}
						else {
							localVar.emplace_back(string($3));
						}
					}
				}
                | identifier_list COMMA ID ASSIGN_OP logical_expression
				{
					struct param_sem *ptr;	
					struct varDeclParam *vptr;				
					ptr = createParam( createIdList( $3 ), createPType( VOID_t ) );
					vptr = createVarDeclParam( ptr, $5 );
					vptr->isArray = __TRUE;
					vptr->isInit = __TRUE;	
					addVarDeclParam( $1, vptr );	
					$$ = $1;
					if (scope == 0) {
						fout << ".field public static " << string($3) << " " << typestr(var_decl_type);
						if (typestr(var_decl_type) == "I") 
							fout << " = " << constval.iVal << endl; 
						else if (typestr(var_decl_type) == "F")
							fout << " = " << constval.fVal << endl;
						else if (typestr(var_decl_type) == "Z")
							fout << " = " << constval.bVal << endl;
						else if (typestr(var_decl_type) == "D") {
							double_decl.emplace_back(pair<string, float> ($3,constval.fVal));
							fout << endl;
							//fout << " = " << constval.fVal << endl;
						}
						globalVar.emplace(string($3), typestr(var_decl_type));
					} else {
						if (var_decl_type == DOUBLE_t) {
							localVar.emplace_back(string($3));
							localVar.emplace_back(" ");
						}
						else {
							localVar.emplace_back(string($3));
						}
						fout << convertType2(var_decl_type, $5->pType->type) << endl;
						fout << instructType(var_decl_type) << "store " << localindex(string($3), localVar) << endl;
					}
					
				}
                | identifier_list COMMA array_decl ASSIGN_OP initial_array
				{
					struct varDeclParam *ptr;
					ptr = createVarDeclParam( $3, $5 );
					ptr->isArray = __TRUE;
					ptr->isInit = __TRUE;
					addVarDeclParam( $1, ptr );
					$$ = $1;	
				}
                | identifier_list COMMA array_decl
				{
					struct varDeclParam *ptr;
					ptr = createVarDeclParam( $3, 0 );
					ptr->isArray = __TRUE;
					addVarDeclParam( $1, ptr );
					$$ = $1;
				}
                | array_decl ASSIGN_OP initial_array
				{	
					$$ = createVarDeclParam( $1 , $3 );
					$$->isArray = __TRUE;
					$$->isInit = __TRUE;	
				}
                | array_decl 
				{ 
					$$ = createVarDeclParam( $1 , 0 ); 
					$$->isArray = __TRUE;
				}
                | ID ASSIGN_OP logical_expression
				{
					struct param_sem *ptr;					
					ptr = createParam( createIdList( $1 ), createPType( VOID_t ) );
					$$ = createVarDeclParam( ptr, $3 );		
					$$->isInit = __TRUE;
					if (scope == 0) {
						fout << ".field public static " << string($1) << " " << typestr(var_decl_type);
						if (typestr(var_decl_type) == "I") 
							fout << " = " << constval.iVal << endl; 
						else if (typestr(var_decl_type) == "F")
							fout << " = " << constval.fVal << endl;
						else if (typestr(var_decl_type) == "Z")
							fout << " = " << constval.bVal << endl;
						else if (typestr(var_decl_type) == "D") {
							double_decl.emplace_back(pair <string, float> ($1, constval.fVal));
							fout << endl;
							//fout << " = " << constval.fVal << endl;
						}
						globalVar.emplace($1, typestr(var_decl_type));
					} else {
						if (var_decl_type == DOUBLE_t) {
							localVar.emplace_back(string($1));
							localVar.emplace_back(" ");
						}
						else {
							localVar.emplace_back(string($1));
						}
						fout << convertType2(var_decl_type, $3->pType->type) << endl;
						fout << instructType(var_decl_type) << "store " << localindex(string($1), localVar) << endl;
					}
				}
                | ID 
				{
					struct param_sem *ptr;					
					ptr = createParam( createIdList( $1 ), createPType( VOID_t ) );
					$$ = createVarDeclParam( ptr, 0 );				
					if (scope == 0) {
						fout << ".field public static " << string($1) << " " << typestr(var_decl_type) << endl;
						globalVar.emplace(string($1), typestr(var_decl_type));
					} else {
						if (var_decl_type == DOUBLE_t) {
							localVar.emplace_back(string($1));
							localVar.emplace_back(" ");
						}
						else {
							localVar.emplace_back(string($1));
						}
					}
				}
                ;
		 
initial_array : L_BRACE literal_list R_BRACE { $$ = $2; }
			  ;

literal_list : literal_list COMMA logical_expression
				{
					struct expr_sem *ptr;
					for( ptr=$1; (ptr->next)!=0; ptr=(ptr->next) );				
					ptr->next = $3;
					$$ = $1;
				}
             | logical_expression
				{
					$$ = $1;
				}
             |
             ;

const_decl 	: CONST  scalar_type {isconst_decl = true;} const_list SEMICOLON
			{
				isconst_decl = false;
				struct SymNode *newNode;				
				struct constParam *ptr;
				for( ptr=$4; ptr!=0; ptr=(ptr->next) ){
					if( verifyRedeclaration( symbolTable, ptr->name, scope ) == __TRUE ){//no redeclare
						if( ptr->value->category != $2->type ){//type different
							if( !(($2->type==FLOAT_t || $2->type == DOUBLE_t ) && ptr->value->category==INTEGER_t) ) {
								if(!($2->type==DOUBLE_t && ptr->value->category==FLOAT_t)){	
									fprintf( stdout, "########## Error at Line#%d: const type different!! ##########\n", linenum );
									semError = __TRUE;	
								}
								else{
									newNode = createConstNode( ptr->name, scope, $2, ptr->value );
									insertTab( symbolTable, newNode );
								}
							}							
							else{
								newNode = createConstNode( ptr->name, scope, $2, ptr->value );
								insertTab( symbolTable, newNode );
							}
						}
						else{
							newNode = createConstNode( ptr->name, scope, $2, ptr->value );
							insertTab( symbolTable, newNode );
						}
					}
				}
			}
			;

const_list : const_list COMMA ID ASSIGN_OP literal_const
			{				
				addConstParam( $1, createConstParam( $5, $3 ) );
				$$ = $1;
			}
		   | ID ASSIGN_OP literal_const
			{
				$$ = createConstParam( $3, $1 );	
			}
		   ;

array_decl : ID dim 
			{
				$$ = createParam( createIdList( $1 ), $2 );
			}
		   ;

dim : dim ML_BRACE INT_CONST MR_BRACE
		{
			if( $3 == 0 ){
				fprintf( stdout, "########## Error at Line#%d: array size error!! ##########\n", linenum );
				semError = __TRUE;
			}
			else
				increaseArrayDim( $1, 0, $3 );			
		}
	| ML_BRACE INT_CONST MR_BRACE	
		{
			if( $2 == 0 ){
				fprintf( stdout, "########## Error at Line#%d: array size error!! ##########\n", linenum );
				semError = __TRUE;
			}			
			else{		
				$$ = createPType( VOID_t ); 			
				increaseArrayDim( $$, 0, $2 );
			}		
		}
	;
	
compound_statement : {scope++;}L_BRACE var_const_stmt_list R_BRACE
					{ 
						// print contents of current scope
						if( Opt_Symbol == 1 )
							printSymTable( symbolTable, scope );
							
						deleteScope( symbolTable, scope );	// leave this scope, delete...
						scope--; 
					}
				   ;

var_const_stmt_list : var_const_stmt_list statement
				    | var_const_stmt_list var_decl
					| var_const_stmt_list const_decl
				    |
				    ;

statement : compound_statement
		  | simple_statement
		  | conditional_statement
		  | while_statement
		  | for_statement
		  | function_invoke_statement
		  | jump_statement
		  ;		

simple_statement : variable_reference ASSIGN_OP logical_expression SEMICOLON
					{

						// check if LHS exists
						__BOOLEAN flagLHS = verifyExistence( symbolTable, $1, scope, __TRUE );
						// id RHS is not dereferenced, check and deference
						__BOOLEAN flagRHS = __TRUE;
						if( $3->isDeref == __FALSE ) {
							flagRHS = verifyExistence( symbolTable, $3, scope, __FALSE );
						}
						// if both LHS and RHS are exists, verify their type
						if( flagLHS==__TRUE && flagRHS==__TRUE )
							verifyAssignmentTypeMatch( $1, $3 );
						int index = localindex(string($1->varRef->id), localVar);
						string id($1->varRef->id);
						if (index >= 0)  {
							fout << convertType2($1->pType->type, $3->pType->type) << endl;
							fout << instructType($1->pType->type) << "store " << index << endl;
						} else  {
							fout << convertType2($1->pType->type, $3->pType->type) << endl;
							fout << "putstatic " << fname << "/" << id << " " << globalVar[id] << endl;
						}
						//fout << instructType($1->pType->type) << "store " << localindex(string($1->varRef->id), localVar) << endl;
					}
				
				 | PRINT {
						fout << "getstatic java/lang/System/out Ljava/io/PrintStream;" << endl;
				 } logical_expression SEMICOLON { 
						verifyScalarExpr( $3, "print" );
						//fout << instructType($2->pType->type) << "store " << MAXSIZE-2 << endl;
						//fout << "getstatic java/lang/System/out Ljava/io/PrintStream;" << endl;
						//fout << instructType($2->pType->type) << "load " << MAXSIZE-2 << endl;
						fout << "invokevirtual java/io/PrintStream/print(" + typestr($3->pType->type) + ")V" << endl;
					}
				 | READ variable_reference SEMICOLON 
					{ 
						if( verifyExistence( symbolTable, $2, scope, __TRUE ) == __TRUE )						
							verifyScalarExpr( $2, "read" ); 
						fout << "getstatic " << fname << "/_sc Ljava/util/Scanner;" << endl;
						fout << "invokevirtual java/util/Scanner/next" << readType($2->pType->type) << "()" << typestr($2->pType->type) << endl;
						string id($2->varRef->id);
						int index = localindex(id, localVar);
						if (index >= 0) 
							fout << instructType($2->pType->type) << "store " << index << endl;
						else 
							fout << "putstatic " << fname << "/" << id << " " << globalVar[id] << endl;
									
					}
				 ;

conditional_statement : IF L_PAREN conditional_if  R_PAREN  compound_statement {fout << "FalseL" << Lstk[--Lstksize] << ":" << endl;}
					  | IF L_PAREN conditional_if  R_PAREN  compound_statement {fout << "goto " << "EndL" << Lstk[Lstksize-1] << endl;}
						ELSE {
							fout << "FalseL" << Lstk[Lstksize-1] << ":" << endl;
						} 
						compound_statement {
							fout << "EndL" << Lstk[--Lstksize] << ":" << endl;
						}
					  ;
conditional_if : logical_expression { verifyBooleanExpr( $1, "if" ); fout << "ifeq FalseL" << Label << endl; Lstk[Lstksize++] = Label++;};;					  

				
while_statement : WHILE L_PAREN  {
						fout << "ContinueL" << Label << ":" << endl;
						Lstk[Lstksize++] = Label++;
						Jstk[Jstksize++] = Label-1;
					} 
					logical_expression { 
						verifyBooleanExpr( $4, "while" ); 
						fout << "ifeq BreakL" << Label-1 << endl; 
					} 
					R_PAREN { inloop++;}
					compound_statement { 
						inloop--; 
						fout << "goto ContinueL" << Lstk[Lstksize-1] << endl; 
						fout << "BreakL" << Lstk[--Lstksize] << ":" << endl;
						Jstksize--;
					}
				| { inloop++; } DO {
						fout << "BeginL" << Label << ":" << endl;
						Lstk[Lstksize++] = Label++;
						Jstk[Jstksize++] = Label-1;
					} 
					compound_statement WHILE L_PAREN {
						fout << "ContinueL" << Lstk[Lstksize-1] << ":" << endl;	
					}
					logical_expression R_PAREN SEMICOLON  
					{ 
						 verifyBooleanExpr( $8, "while" );
						 inloop--; 
						 fout << "ifgt BeginL" << Lstk[Lstksize-1] << endl;
						 fout << "BreakL" << Lstk[--Lstksize] << ":" << endl;
						 Jstksize--;
					}
				;


				
for_statement : FOR L_PAREN initial_expression SEMICOLON {
			  			fout << "BeginL" << Label << ":" << endl; 
			  			Lstk[Lstksize++] = Label++;
						Jstk[Jstksize++] = Label-1;
					} 
					control_expression SEMICOLON {
						fout << "ifeq BreakL" << Lstk[Lstksize-1] << endl;
						fout << "goto CompoundL" << Lstk[Lstksize-1] << endl;
						fout << "ContinueL" << Lstk[Lstksize-1] << ":" << endl;
					} 
					increment_expression R_PAREN  { 
						inloop++; 
						fout << "goto BeginL" << Lstk[Lstksize-1] << endl;
						fout << "CompoundL" << Lstk[Lstksize-1] << ":" << endl;
					}
					compound_statement  { 
						inloop--;
						fout << "goto ContinueL" << Lstk[Lstksize-1] << endl;
						fout << "BreakL" << Lstk[--Lstksize] << ":" << endl;
						Jstksize--;
					}
			  ;

initial_expression : initial_expression COMMA statement_for
				   | initial_expression COMMA logical_expression
				   | logical_expression	
				   | statement_for
				   |
				   ;

control_expression : control_expression COMMA statement_for
				   {
						fprintf( stdout, "########## Error at Line#%d: control_expression is not boolean type ##########\n", linenum );
						semError = __TRUE;	
				   }
				   | control_expression COMMA logical_expression
				   {
						if( $3->pType->type != BOOLEAN_t ){
							fprintf( stdout, "########## Error at Line#%d: control_expression is not boolean type ##########\n", linenum );
							semError = __TRUE;	
						}
				   }
				   | logical_expression 
					{ 
						if( $1->pType->type != BOOLEAN_t ){
							fprintf( stdout, "########## Error at Line#%d: control_expression is not boolean type ##########\n", linenum );
							semError = __TRUE;	
						}
					}
				   | statement_for
				   {
						fprintf( stdout, "########## Error at Line#%d: control_expression is not boolean type ##########\n", linenum );
						semError = __TRUE;	
				   }
				   |
				   ;

increment_expression : increment_expression COMMA statement_for
					 | increment_expression COMMA logical_expression
					 | logical_expression
					 | statement_for
					 |
					 ;

statement_for 	: variable_reference ASSIGN_OP logical_expression
					{
						// check if LHS exists
						__BOOLEAN flagLHS = verifyExistence( symbolTable, $1, scope, __TRUE );
						// id RHS is not dereferenced, check and deference
						__BOOLEAN flagRHS = __TRUE;
						if( $3->isDeref == __FALSE ) {
							flagRHS = verifyExistence( symbolTable, $3, scope, __FALSE );
						}
						// if both LHS and RHS are exists, verify their type
						if( flagLHS==__TRUE && flagRHS==__TRUE )
							verifyAssignmentTypeMatch( $1, $3 );
						//gen
						int index = localindex(string($1->varRef->id), localVar);
						string id($1->varRef->id);
						if (index >= 0) 
							fout << instructType($1->pType->type) << "store " << index << endl;
						else 
							fout << "putstatic " << fname << "/" << id << " " << globalVar[id] << endl;
					}
					;
					 
					 
function_invoke_statement : ID L_PAREN {invoke = true; invokename = string($1);param_count = 1;} logical_expression_list R_PAREN SEMICOLON
							{
								verifyFuncInvoke( $1, $4, symbolTable, scope );
								string name($1);
								fout << "invokestatic " << fname << "/" << string(name) << globalVar[name] << endl;
								invoke = false;
								param_count = 1;
							}
						  | ID L_PAREN R_PAREN SEMICOLON
							{
								verifyFuncInvoke( $1, 0, symbolTable, scope );
								string name($1);
								fout << "invokestatic " << fname << "/" << string(name) << globalVar[name] << endl;
							}
						  ;

jump_statement : CONTINUE SEMICOLON
				{
					if( inloop <= 0){
						fprintf( stdout, "########## Error at Line#%d: continue can't appear outside of loop ##########\n", linenum ); semError = __TRUE;
					}
					fout << "goto  ContinueL" << Jstk[Jstksize-1] << endl;
				}
			   | BREAK SEMICOLON 
				{
					if( inloop <= 0){
						fprintf( stdout, "########## Error at Line#%d: break can't appear outside of loop ##########\n", linenum ); semError = __TRUE;
					}
					fout << "goto BreakL" << Jstk[Jstksize-1] << endl;
				}
			   | RETURN logical_expression SEMICOLON
				{
					verifyReturnStatement( $2, funcReturn );
					if (!insidemain) {
						fout << instructType(funcReturn->type) << "return" << endl;
					} 
					else fout << "return" << endl;
					have_return = true;
				}
			   ;

variable_reference : ID
					{
						$$ = createExprSem( $1 );
					}
				   | variable_reference dimension
					{	
						increaseDim( $1, SEMTYPE($2) );
						$$ = $1;
					}
				   ;

dimension : ML_BRACE arithmetic_expression MR_BRACE
			{
				$$ = verifyArrayIndex( $2 );
			}
		  ;
		  
logical_expression : logical_expression OR_OP logical_term
					{
						verifyAndOrOp( $1, OR_t, $3 );
						$$ = $1;
						fout << "ior" << endl;
							
					}
				   | logical_term { $$ = $1;}
				   ;

logical_term : logical_term AND_OP logical_factor
				{
					verifyAndOrOp( $1, AND_t, $3 );
					$$ = $1;
					fout << "iand" << endl;	
				}
			 | logical_factor { $$ = $1;}
			 ;

logical_factor : NOT_OP logical_factor
				{
					verifyUnaryNot( $2 );
					$$ = $2;
					fout << "iconst_1" << endl;
					fout << "ixor" << endl;
				}
			   | relation_expression { $$ = $1;}
			   ;

relation_expression : arithmetic_expression relation_operator arithmetic_expression
					{
						SEMTYPE type1 = $1->pType->type, type2 = $3->pType->type;
						verifyRelOp( $1, $2, $3 );
						$$ = $1;
						string conv = convertType1(type1, type2);
						if (conv != "") {
							fout << instructType(type2) << "store " << MAXSIZE-2 << endl;
							fout << conv << endl;
							fout << instructType(type2) << "load " << MAXSIZE-2 << endl;
						}
						conv = convertType2(type1, type2);
						if (conv != "") fout << conv << endl;
						char after = afterType(type1, type2);
						if (after == 'D') {
							fout << "dcmpl" << endl;
						} else if (after == 'F') {
							fout << "fcmpl" << endl;
						} else if  (after == 'I') {
							fout << "isub" << endl;
						}
						switch($2) {
							case(LT_t): fout << "iflt"; break;
							case(LE_t): fout << "ifle"; break;
							case(EQ_t): fout << "ifeq"; break;
							case(GE_t): fout << "ifge"; break;
							case(GT_t): fout << "ifgt"; break;
							case(NE_t): fout << "ifne"; break;
						}
						fout << " relationL" << relationL++ << endl;
						fout << "iconst_0\n" << "goto relationL" << relationL++ << endl;
						fout << "relationL" << relationL-2 << ":\n" << "iconst_1\n" << "relationL" << relationL-1 << ":" << endl;
					}
					| arithmetic_expression { $$ = $1;
					}
					;

relation_operator : LT_OP { $$ = LT_t; }
				  | LE_OP { $$ = LE_t; }
				  | EQ_OP { $$ = EQ_t; }
				  | GE_OP { $$ = GE_t; }
				  | GT_OP { $$ = GT_t; }
				  | NE_OP { $$ = NE_t; }
				  ;

arithmetic_expression : arithmetic_expression add_op term
			{
				SEMTYPE type1 = $1->pType->type, type2 = $3->pType->type;
				verifyArithmeticOp( $1, $2, $3 );
				$$ = $1;
				string conv = convertType1(type1, type2);
				if (conv != "") {
					fout << instructType(type2) << "store " << MAXSIZE-2 << endl;
					fout << conv << endl;
					fout << instructType(type2) << "load " << MAXSIZE-2 << endl;
				}
				conv = convertType2(type1, type2);
				if (conv != "") fout << conv << endl;
				if ($2 == ADD_t) {
					fout << instructType($$->pType->type) << "add" << endl;
				} else {
					fout << instructType($$->pType->type) << "sub" << endl;
				}
			}
           | relation_expression { $$ = $1; }
		   | term { $$ = $1; }
		   ;

add_op	: ADD_OP { $$ = ADD_t; }
		| SUB_OP { $$ = SUB_t; }
		;
		   
term : term mul_op factor
		{
			SEMTYPE type1 = $1->pType->type, type2 = $3->pType->type;
			if( $2 == MOD_t ) {
				verifyModOp( $1, $3 );
			}
			else {
				verifyArithmeticOp( $1, $2, $3 );
			}
			$$ = $1;
			string conv = convertType1(type1, type2);
			if (conv != "") {
				fout << instructType(type2) << "store " << MAXSIZE-2 << endl;
				fout << conv << endl;
				fout << instructType(type2) << "load " << MAXSIZE-2 << endl;
			}
			conv = convertType2(type1, type2);
			if (conv != "") fout << conv << endl;
			if ($2 == MOD_t) fout << "irem" << endl;
			else if ($2 == MUL_t) {
				fout << instructType($$->pType->type) << "mul" << endl;
			} else {
				fout << instructType($$->pType->type) << "div" << endl;
			}
		}
     | factor { $$ = $1;}
	 ;

mul_op 	: MUL_OP { $$ = MUL_t; }
		| DIV_OP { $$ = DIV_t; }
		| MOD_OP { $$ = MOD_t; }
		;
		
factor : variable_reference
		{
			verifyExistence( symbolTable, $1, scope, __FALSE );
			$$ = $1;
			$$->beginningOp = NONE_t;
			int index = localindex(string($1->varRef->id), localVar);
			string id($1->varRef->id);
			struct SymNode* node = lookupSymbol (symbolTable, id.c_str(), scope, __FALSE);
			
			if (node != 0 && node->category == CONSTANT_t) {
				switch( node->attribute->constVal->category) {
				 case INTEGER_t:
				 	{
					//fout << "sipush " << node->attribute->constVal->value.integerVal << endl;
					fout << "ldc " << node->attribute->constVal->value.integerVal << endl;
					fout << convertType2(node->type->type, node->attribute->constVal->category) << endl;
					break;
					}
				 case FLOAT_t:
				 	{
					fout << "ldc " << fixed <<  node->attribute->constVal->value.floatVal << endl;
					fout << convertType2(node->type->type, node->attribute->constVal->category) << endl;
					break;
					}
				 case DOUBLE_t:
				 	{
					fout << "ldc2_w " << fixed << node->attribute->constVal->value.doubleVal << endl;
					fout << convertType2(node->type->type, node->attribute->constVal->category) << endl;
					break;
					}
				 case BOOLEAN_t:
				 	{
					if( node->attribute->constVal->value.booleanVal == __TRUE )
						fout << "iconst_1" << endl;
					else
						fout << "iconst_0" << endl;
					break;
					}
				 case STRING_t:
				 	{
					fout << "ldc \"" << getstring(node->attribute->constVal->value.stringVal) << "\" "<< endl;
					break;
					}
				}

			} else if (index >= 0) 
				fout << instructType($1->pType->type) << "load " << index << endl;
			else { 
				fout << "getstatic " << fname << "/" << id << " " << globalVar[id] << endl;
			}
		}
	   | SUB_OP variable_reference
		{
			if( verifyExistence( symbolTable, $2, scope, __FALSE ) == __TRUE )
			verifyUnaryMinus( $2 );
			$$ = $2;
			$$->beginningOp = SUB_t;
			int index = localindex(string($2->varRef->id), localVar);
			string id($2->varRef->id);
			if (index >= 0) 
				fout << instructType($2->pType->type) << "load " << index << endl;
			else 
				fout << "getstatic " << fname << "/" << id << " " << globalVar[id] << endl;

			fout << instructType($2->pType->type) << "neg" << endl;

		}		
	   | L_PAREN logical_expression R_PAREN
		{
			$2->beginningOp = NONE_t;
			$$ = $2; 
		}
	   | SUB_OP L_PAREN logical_expression R_PAREN
		{
			verifyUnaryMinus( $3 );
			$$ = $3;
			$$->beginningOp = SUB_t;
			fout << instructType($3->pType->type) << "neg" << endl;
		}
	   | ID L_PAREN {invoke = true; invokename = string($1); param_count = 1;} logical_expression_list R_PAREN
		{
			$$ = verifyFuncInvoke( $1, $4, symbolTable, scope );
			$$->beginningOp = NONE_t;
			string name($1);
			fout << "invokestatic " << fname << "/" << string(name) << globalVar[name] << endl;
			param_count = 1;
			invoke = false;
		}
	   | SUB_OP ID L_PAREN {invoke = true; invokename = string($2); param_count = 1;} logical_expression_list R_PAREN
	    {
			$$ = verifyFuncInvoke( $2, $5, symbolTable, scope );
			$$->beginningOp = SUB_t;
			param_count = 1;
			invoke = false;
		}
	   | ID L_PAREN R_PAREN
		{
			$$ = verifyFuncInvoke( $1, 0, symbolTable, scope );
			$$->beginningOp = NONE_t;
			string name($1);
			fout << "invokestatic " << fname << "/" << name << globalVar[name] << endl;
		}
	   | SUB_OP ID L_PAREN R_PAREN
		{
			$$ = verifyFuncInvoke( $2, 0, symbolTable, scope );
			$$->beginningOp = SUB_OP;
			string name($2);
			fout <<  "invokestatic " << fname << "/" << name << globalVar[name] << endl;
			fout << instructType_char(char(globalVar[name][globalVar[name].size()-1])) <<  "neg" << endl;
		}
	   | literal_const
	    {
			  $$ = (struct expr_sem *)malloc(sizeof(struct expr_sem));
			  $$->isDeref = __TRUE;
			  $$->varRef = 0;
			  $$->pType = createPType( $1->category );
			  $$->next = 0;
			  if( $1->hasMinus == __TRUE ) {
			  	$$->beginningOp = SUB_t;
			  }
			  else {
				$$->beginningOp = NONE_t;
			  }
		}
	   ;

logical_expression_list : logical_expression_list COMMA logical_expression
						{
			  				struct expr_sem *exprPtr;
			  				for( exprPtr=$1 ; (exprPtr->next)!=0 ; exprPtr=(exprPtr->next) );
			  				exprPtr->next = $3;
			  				$$ = $1;
							if (invoke) {
								fout << convertType2(char2type(globalVar[invokename][param_count]), $3->pType->type) << endl;
								param_count++;
							}
						}
						| logical_expression { 
							$$ = $1; 
							if (invoke) {
								fout << convertType2(char2type(globalVar[invokename][param_count]), $1->pType->type) << endl;
								param_count++;
							}
						
						}
						;

		  


scalar_type : INT { $$ = createPType( INTEGER_t ); var_decl_type = $$->type;}
			| DOUBLE { $$ = createPType( DOUBLE_t ); var_decl_type = $$->type;}
			| STRING { $$ = createPType( STRING_t ); var_decl_type = $$->type;}
			| BOOL { $$ = createPType( BOOLEAN_t ); var_decl_type = $$->type;}
			| FLOAT { $$ = createPType( FLOAT_t ); var_decl_type = $$->type;}
			;
 
literal_const : INT_CONST
				{
					int tmp = $1;
					$$ = createConstAttr( INTEGER_t, &tmp );
					if (isconst_decl) {
						//do nothing
					} else if (scope != 0) {
						//fout << string("sipush ") << to_string(yylval.intVal) << endl;
						fout << string("ldc ") << to_string(yylval.intVal) << endl;
					} else {
						constval.iVal = yylval.intVal;
					}
				}
			  | SUB_OP INT_CONST
				{
					int tmp = -$2;
					$$ = createConstAttr( INTEGER_t, &tmp );
					if (isconst_decl) {
					
					} else if (scope != 0) {
						//fout << "sipush -" << yylval.intVal << endl;
						fout << "ldc -" << yylval.intVal << endl;
					}
					else
						constval.iVal = -yylval.intVal;
				}
			  | FLOAT_CONST
				{
					float tmp = $1;
					$$ = createConstAttr( FLOAT_t, &tmp );
					if (isconst_decl) {

					} else if (scope != 0)
						fout << "ldc " << yylval.floatVal << endl;
					else
						constval.fVal = yylval.floatVal;
				}
			  | SUB_OP FLOAT_CONST
			    {
					float tmp = -$2;
					$$ = createConstAttr( FLOAT_t, &tmp );
					if (isconst_decl) {
						//do nothing
					} else if (scope != 0)
						fout << "ldc -" << yylval.floatVal << endl;
					else
						constval.fVal = -yylval.floatVal;
				}
			  | SCIENTIFIC
				{
					double tmp = $1;
					$$ = createConstAttr( DOUBLE_t, &tmp );
					if (isconst_decl) {
						//do nothing
					} else if (scope != 0)
						fout << "ldc " <<  to_string(yylval.floatVal) << endl;
					else
						constval.fVal = yylval.floatVal;
				}
			  | SUB_OP SCIENTIFIC
				{
					double tmp = -$2;
					$$ = createConstAttr( DOUBLE_t, &tmp );
					if (isconst_decl) {
					} else if (scope != 0)
						fout << "ldc -" << yylval.floatVal << endl;
					else
						constval.fVal = -yylval.floatVal;
				}
			  | STR_CONST
				{
					$$ = createConstAttr( STRING_t, $1 );
					if (isconst_decl) {
						//do nothing
					} else if (scope != 0)
						fout << "ldc \"" << getstring(yylval.lexeme) << "\"" << endl;
				}
			  | TRUE
				{
					SEMTYPE tmp = (int)__TRUE;
					$$ = createConstAttr( BOOLEAN_t, &tmp );
					if (isconst_decl) {
					//do nothing
					} else if (scope != 0)
						fout << "iconst_1" << endl;
					else
						constval.iVal = 1;

				}
			  | FALSE
				{
					SEMTYPE tmp = (int)__FALSE;
					$$ = createConstAttr( BOOLEAN_t, &tmp );
					if (isconst_decl) {
					} else if (scope != 0)
						fout << "iconst_0" << endl;
					else
						constval.iVal = 0;
				}
			  ;
%%

int yyerror( const char *msg )
{
    fprintf( stderr, "\n|--------------------------------------------------------------------------\n" );
	fprintf( stderr, "| Error found in Line #%d: %s\n", linenum, buf );
	fprintf( stderr, "|\n" );
	fprintf( stderr, "| Unmatched token: %s\n", yytext );
	fprintf( stderr, "|--------------------------------------------------------------------------\n" );
	exit(-1);
}


