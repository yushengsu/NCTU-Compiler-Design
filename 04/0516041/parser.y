%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <string>
#include <vector>
#include <set>
#include"datatype.h"
#include"symtable.h"
using namespace std;
extern "C"
{
	int yyerror(char *msg);
	extern int yylex(void);
}
extern int linenum;
extern int error;
extern FILE	*yyin;
extern char	*yytext;
extern char buf[256];
extern int Opt_SymTable;//declared in lex.l
int scope = 0;//default is 0(global)
vector< int > logical_expression_num;
int loop = 0;

int return_linenum[1000];
BTYPE returnType[1000];
int return_count = 0;

vector< vector<BTYPE> > arrayVector;
vector<BTYPE> arrayTmp;
vector<BTYPE> arrayCheck;

struct SymTableList *symbolTableList;//create and initialize in main.c
struct ExtType *funcReturnType;
vector<BTYPE> functParam;
set< string > functVector;

%}
%union{
	int 				intVal;
	float 				floatVal;
	double 				doubleVal;
	char				*stringVal;
	char				*idName;
	//struct ExtType 	*extType;
	struct Variable		*variable;
	struct VariableList	*variableList;
	struct ArrayDimNode	*arrayDimNode;
	//struct ConstAttr	*constAttr;
	struct FuncAttrNode	*funcAttrNode;
	//struct FuncAttr	*funcAttr;
	struct Attribute	*attribute;
	struct SymTableNode	*symTableNode;
	//struct SymTable	*symTable;
	BTYPE				bType;
};

%token <idName> 	ID
%token <intVal> 	INT_CONST
%token <floatVal> 	FLOAT_CONST
%token <doubleVal> 	SCIENTIFIC
%token <stringVal> 	STR_CONST

%type <variable> 		array_decl
%type <variableList> 	identifier_list
%type <arrayDimNode> 	dim
%type <funcAttrNode> 	parameter_list
%type <attribute> 		literal_const 
%type <symTableNode> 	const_list
%type <bType> 	scalar_type
%type <bType> 	factor 
%type <bType> 	term 
%type <bType> 	arithmetic_expression 
%type <bType> 	relation_expression 
%type <bType> 	logical_factor
%type <bType> 	logical_term
%type <bType> 	logical_expression
%type <bType> 	variable_reference
%type <bType> 	control_expression
%type <bType> 	array_list

%token	LE_OP
%token	NE_OP
%token	GE_OP
%token	EQ_OP
%token	AND_OP
%token	OR_OP

%token	READ
%token	BOOLEAN
%token	WHILE
%token	DO
%token	IF
%token	ELSE
%token	TRUE
%token	FALSE
%token	FOR
%token	INT
%token	PRINT
%token	BOOL
%token	VOID
%token	FLOAT
%token	DOUBLE
%token	STRING
%token	CONTINUE
%token	BREAK
%token	RETURN
%token  CONST

%token	L_PAREN
%token	R_PAREN
%token	COMMA
%token	SEMICOLON
%token	ML_BRACE
%token	MR_BRACE
%token	L_BRACE
%token	R_BRACE
%token	ADD_OP
%token	SUB_OP
%token	MUL_OP
%token	DIV_OP
%token	MOD_OP
%token	ASSIGN_OP
%token	LT_OP
%token	GT_OP
%token	NOT_OP

/*	Program 
	Function 
	Array 
	Const 
	IF 
	ELSE 
	RETURN 
	FOR 
	WHILE
*/
%start program
%%

program :  decl_list funct_def decl_and_def_list {
			for(auto i:functVector){
				error = 1;
				printf("##########Error at Line %d: function ", linenum);
				printf("%s", i);
				printf(" is declared but not defined.##########\n");
			}
			if(Opt_SymTable == 1) printSymTable(symbolTableList->global);
			deleteLastSymTable(symbolTableList);
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

funct_def : scalar_type ID L_PAREN R_PAREN {
				funcReturnType = createExtType($1,0,NULL);
				struct SymTableNode *node;
				node = findFuncDeclaration(symbolTableList->global,$2);
				if(node==NULL) { //no declaration yet
					struct SymTableNode *newNode = createFunctionNode($2,scope,funcReturnType,NULL);
					insertTableNode(symbolTableList->global,newNode);
				}
				else if(node->attr != NULL) FunctDeclDefNoParamError($2);

				if(functVector.find($2) != functVector.end()) functVector.erase($2);
				free($2);

			} compound_statement{
				ReturnTypeCheck($1, returnType, return_linenum, return_count);
				int i = 0;				
				for(i=0;i<1000;i++){
					returnType[i] = UNCERTAIN_t;
					return_linenum[i] = 0;
				}
				return_count = 0;
			}

		  | scalar_type ID L_PAREN parameter_list R_PAREN {
				funcReturnType = createExtType($1,0,NULL);	
				struct SymTableNode *node;
				node = findFuncDeclaration(symbolTableList->global,$2);
				struct Attribute *attr = createFunctionAttribute($4);
				if(node==NULL) { //no declaration yet
					struct SymTableNode *newNode = createFunctionNode($2,scope,funcReturnType,attr);
					insertTableNode(symbolTableList->global,newNode);
				}
				else{
					if(node->attr == NULL) FunctDeclDefParamError($2);
					else FunctDeclDefParamCheck(node->attr->funcParam->head, attr->funcParam->head);
				}
				if(functVector.find($2) != functVector.end()) functVector.erase($2);
		  }

		    L_BRACE { //enter a new scope
				++scope;
				AddSymTable(symbolTableList);
				//add parameters
				struct FuncAttrNode *attrNode = $4;
				while(attrNode!=NULL) {
					struct SymTableNode *newNode = createParameterNode(attrNode->name,scope,attrNode->value);
					insertTableNode(symbolTableList->tail,newNode);
					attrNode = attrNode->next;
				}
		  }

			var_const_stmt_list{
				ReturnTypeCheck($1, returnType, return_linenum, return_count);
				int i = 0;				
				for(i=0;i<1000;i++){
					returnType[i] = UNCERTAIN_t;
					return_linenum[i] = 0;
				}
				return_count = 0;
		  } 

			R_BRACE {	
				if(Opt_SymTable == 1) printSymTable(symbolTableList->tail);
				deleteLastSymTable(symbolTableList);
				--scope;
				free($2);
		  }
		  | VOID ID L_PAREN R_PAREN {
				funcReturnType = createExtType(VOID_t,0,NULL);
				struct SymTableNode *node;
				node = findFuncDeclaration(symbolTableList->global,$2);
				if(node==NULL) { //no declaration yet
					struct SymTableNode *newNode = createFunctionNode($2,scope,funcReturnType,NULL);
					insertTableNode(symbolTableList->global,newNode);
				}	
				else if(node->attr != NULL) FunctDeclDefNoParamError($2);
				if(functVector.find($2) != functVector.end()) functVector.erase($2);	
				free($2);
		  }
		  	compound_statement{
				ReturnTypeCheck(VOID_t, returnType, return_linenum, return_count);
				int i = 0;				
				for(i=0; i<1000; ++i){
					returnType[i] = UNCERTAIN_t;
					return_linenum[i] = 0;
				}
				return_count = 0;
		  }
		  | VOID ID L_PAREN parameter_list R_PAREN {

				funcReturnType = createExtType(VOID_t,0,NULL);
				struct SymTableNode *node;
				node = findFuncDeclaration(symbolTableList->global,$2);
				struct Attribute *attr = createFunctionAttribute($4);	
				if(node==NULL) { //no declaration yet
					struct SymTableNode *newNode = createFunctionNode($2,scope,funcReturnType,attr);
					insertTableNode(symbolTableList->global,newNode);
				}
				else{
					if(node->attr == NULL){FunctDeclDefParamError($2);}
					else FunctDeclDefParamCheck(node->attr->funcParam->head, attr->funcParam->head);
				}
				if(functVector.find($2) != functVector.end()) functVector.erase($2);
		  }

			L_BRACE { //enter a new scope
				++scope;
				AddSymTable(symbolTableList);
				//add parameters
				struct FuncAttrNode *attrNode = $4;
				while(attrNode!=NULL) {
					struct SymTableNode *newNode = createParameterNode(attrNode->name,scope,attrNode->value);
					insertTableNode(symbolTableList->tail,newNode);
					attrNode = attrNode->next;
				}
		  }
			var_const_stmt_list R_BRACE {	
				ReturnTypeCheck(VOID_t, returnType, return_linenum, return_count);
				int i = 0;				
				for(i=0;i<1000;i++){
					returnType[i] = UNCERTAIN_t;
					return_linenum[i] = 0;
				}
				return_count = 0;
				if(Opt_SymTable == 1)
					printSymTable(symbolTableList->tail);
				deleteLastSymTable(symbolTableList);
				--scope;
				free($2);
		  }
		  ;

funct_decl : scalar_type ID L_PAREN R_PAREN SEMICOLON {
				int tmp = 0;
				funcReturnType = createExtType($1,0,NULL);
				struct SymTableNode *newNode = createFunctionNode($2,scope,funcReturnType,NULL);
				tmp = DeclareCheck(symbolTableList->tail, newNode->name);
				insertTableNode(symbolTableList->global,newNode);
				if(functVector.find($2) == functVector.end() && !tmp) functVector.insert($2);
				free($2);
		   }

	 	   | scalar_type ID L_PAREN parameter_list R_PAREN SEMICOLON {
				int tmp = 0;
				funcReturnType = createExtType($1,0,NULL);
				struct Attribute *attr = createFunctionAttribute($4);
				struct SymTableNode *newNode = createFunctionNode($2,scope,funcReturnType,attr);
				tmp = DeclareCheck(symbolTableList->tail, newNode->name);
				insertTableNode(symbolTableList->global,newNode);
				if(functVector.find($2) == functVector.end() && !tmp) functVector.insert($2); 
				free($2);
		   }

		   | VOID ID L_PAREN R_PAREN SEMICOLON {
		   		int tmp = 0;
				funcReturnType = createExtType(VOID_t,0,NULL);
				struct SymTableNode *newNode = createFunctionNode($2,scope,funcReturnType,NULL);
				tmp = DeclareCheck(symbolTableList->tail, newNode->name);	
				insertTableNode(symbolTableList->global,newNode);
				if(functVector.find($2) == functVector.end() && !tmp) functVector.insert($2);
				free($2);
		   }

		   | VOID ID L_PAREN parameter_list R_PAREN SEMICOLON {
		   		int tmp = 0;
				funcReturnType = createExtType(VOID_t,0,NULL);
				struct Attribute *attr = createFunctionAttribute($4);
				struct SymTableNode *newNode = createFunctionNode($2,scope,funcReturnType,attr);
				tmp = DeclareCheck(symbolTableList->tail, newNode->name);
				insertTableNode(symbolTableList->global,newNode);
				if(functVector.find($2) == functVector.end() && !tmp) functVector.insert($2);
				free($2);
		   }
		   ;

parameter_list : parameter_list COMMA scalar_type ID {

					struct FuncAttrNode *newNode = (struct FuncAttrNode*)malloc(sizeof(struct FuncAttrNode));
					newNode->value = createExtType($3,0,NULL);
					newNode->name = strdup($4);
					free($4);
					newNode->next = NULL;
					connectFuncAttrNode($1,newNode);
					$$ = $1;
		       }
			   | parameter_list COMMA scalar_type array_decl {

					struct FuncAttrNode *newNode = (struct FuncAttrNode*)malloc(sizeof(struct FuncAttrNode));
					newNode->value = $4->type;//use pre-built ExtType(type is unknown)
					newNode->value->baseType = $3;//set correct type
					newNode->name = strdup($4->name);
					newNode->next = NULL;
					free($4->name);
					free($4);
					connectFuncAttrNode($1,newNode);
					$$ = $1;
			   }

			   | scalar_type array_decl {

					struct FuncAttrNode *newNode = (struct FuncAttrNode*)malloc(sizeof(struct FuncAttrNode));
					newNode->value = $2->type;//use pre-built ExtType(type is unknown)
					newNode->value->baseType = $1;//set correct type
					newNode->name = strdup($2->name);
					newNode->next = NULL;
					free($2->name);
					free($2);
					$$ = newNode;
			   }
			   | scalar_type ID {

					struct FuncAttrNode *newNode = (struct FuncAttrNode*)malloc(sizeof(struct FuncAttrNode));
					newNode->value = createExtType($1,0,NULL);
					newNode->name = strdup($2);
					free($2);
					newNode->next = NULL;
					$$ = newNode;
			   }
	 		   ;

var_decl : scalar_type identifier_list SEMICOLON{
			
			struct Variable* listNode = $2->head;
			struct SymTableNode *newNode;
			while(listNode!=NULL){

				newNode = createVariableNode(listNode->name,scope,listNode->type);
				AssignTypeCheck($1,listNode->type->baseType);
				DeclareCheck(symbolTableList->tail, listNode->name);
				if(listNode->type->isArray){
					ArrayDeclareCheck(arrayVector[0], listNode->type->dimArray, $1);
					arrayVector.erase(arrayVector.begin());
				}
				newNode->type->baseType = $1;
				insertTableNode(symbolTableList->tail,newNode);
				listNode = listNode->next;
			}
			deleteVariableList($2);
		 }
		 ;

identifier_list : identifier_list COMMA ID {

					struct ExtType *type = createExtType(UNCERTAIN_t,false,NULL);//type unknown here
					struct Variable *newVariable = createVariable($3,type);
					free($3);
					connectVariableList($1,newVariable);
					$$ = $1;
				}

				| identifier_list COMMA ID ASSIGN_OP logical_expression{
					struct ExtType *type = createExtType($5,false,NULL);//type unknown here
					struct Variable *newVariable = createVariable($3,type);
					free($3);
					connectVariableList($1,newVariable);
					$$ = $1;
				}

				| identifier_list COMMA array_decl ASSIGN_OP initial_array {
					arrayVector.push_back(arrayTmp);
					arrayTmp.clear();
					connectVariableList($1,$3);
					$$ = $1;
				}

				| identifier_list COMMA array_decl {
					arrayTmp.clear();
					arrayVector.push_back(arrayTmp);
					connectVariableList($1,$3);
					$$ = $1;
				}

				| array_decl ASSIGN_OP initial_array {
					arrayVector.push_back(arrayTmp);
					arrayTmp.clear();
					$$ = createVariableList($1);
				}

				| array_decl {
					arrayTmp.clear();
					arrayVector.push_back(arrayTmp);
					$$ = createVariableList($1);
				}

				| ID ASSIGN_OP logical_expression {
					struct ExtType *type = createExtType($3,false,NULL);//type unknown here
					struct Variable *newVariable = createVariable($1,type);
					$$ = createVariableList(newVariable);
					free($1);
				}

				| ID {
					struct ExtType *type = createExtType(UNCERTAIN_t,false,NULL);//type unknown here
					struct Variable *newVariable = createVariable($1,type);
					$$ = createVariableList(newVariable);
					free($1);
				}
				;

initial_array : L_BRACE literal_list R_BRACE
			  ;

literal_list : literal_list COMMA logical_expression { arrayTmp.push_back($3);}
			 | logical_expression { arrayTmp.push_back($1);}
             | 
			 ;

const_decl : CONST scalar_type const_list SEMICOLON{
				struct SymTableNode *list = $3;//symTableNode base on initailized data type, scalar_type is not used
				while(list!=NULL){
					DeclareCheck(symbolTableList->tail, list->name);
					insertTableNode(symbolTableList->tail,list);
					list = list->next;
				}
			}
			;

const_list : const_list COMMA ID ASSIGN_OP literal_const
		   {
				struct ExtType *type = createExtType($5->constVal->type,false,NULL);
				struct SymTableNode *temp = $1;
				while(temp->next!=NULL){
					temp = temp->next;
				}
				temp->next = createConstNode($3,scope,type,$5);	
				free($3);
		   }
		   | ID ASSIGN_OP literal_const{
				struct ExtType *type = createExtType($3->constVal->type,false,NULL);
				$$ = createConstNode($1,scope,type,$3);	
				free($1);
		   }    
		   ;

array_decl : ID dim {
				struct ExtType *type = createExtType(UNCERTAIN_t,true,$2);//type unknown here
				struct Variable *newVariable = createVariable($1,type);
				free($1);
				$$ = newVariable;
		   	}
		   ;

dim : dim ML_BRACE INT_CONST MR_BRACE{
	  	connectArrayDimNode($1,createArrayDimNode($3));
		$$ = $1;
	}
	| ML_BRACE INT_CONST MR_BRACE{
		$$ = createArrayDimNode($2);
	}
	;

compound_statement : L_BRACE {//enter a new scope
						++scope;
						AddSymTable(symbolTableList);
				   }
					 var_const_stmt_list R_BRACE {	
						if(Opt_SymTable == 1) printSymTable(symbolTableList->tail);
						deleteLastSymTable(symbolTableList);
				        --scope;
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

simple_statement : variable_reference ASSIGN_OP logical_expression SEMICOLON { AssignTypeCheck($1, $3);}
				 | PRINT logical_expression SEMICOLON { ScalarTypeCheck($2);}
				 | READ variable_reference SEMICOLON { ScalarTypeCheck($2);}
				 ;

conditional_statement : IF L_PAREN logical_expression R_PAREN compound_statement { 
							Bool_ExpressionCheck($3, logical_expression_num[int(logical_expression_num.size()-1)]);
							logical_expression_num.pop_back();
					  }
					  | IF L_PAREN logical_expression R_PAREN 
						compound_statement	
						ELSE
						compound_statement { 
							Bool_ExpressionCheck($3, logical_expression_num[int(logical_expression_num.size()-1)]);
							logical_expression_num.pop_back();
					  }	
					  ;
while_statement : WHILE{ //enter a new scope
					++scope;
					AddSymTable(symbolTableList);
					++loop;
				}

				  L_PAREN logical_expression R_PAREN{
				  	Bool_ExpressionCheck($4, logical_expression_num[int(logical_expression_num.size()-1)]);
				  	logical_expression_num.pop_back();
				}

				  L_BRACE var_const_stmt_list R_BRACE{	
					if(Opt_SymTable == 1) printSymTable(symbolTableList->tail);
					deleteLastSymTable(symbolTableList);
			        --scope;
					--loop;
				}

				| DO L_BRACE{ //enter a new scope
					++scope;
					AddSymTable(symbolTableList);
					++loop;
				}

				var_const_stmt_list
		 		R_BRACE WHILE L_PAREN logical_expression R_PAREN SEMICOLON{
					Bool_ExpressionCheck($8, logical_expression_num[int(logical_expression_num.size()-1)]);
					if(Opt_SymTable == 1) printSymTable(symbolTableList->tail);
					deleteLastSymTable(symbolTableList);
			        --scope;
					--loop;
				}
				;

for_statement : FOR
				L_PAREN initial_expression_list SEMICOLON control_expression_list SEMICOLON increment_expression_list R_PAREN 
				L_BRACE {//enter a new scope
					++loop;
					++scope;
					AddSymTable(symbolTableList);
			  } 
				var_const_stmt_list R_BRACE{
					--loop;
					if(Opt_SymTable == 1) printSymTable(symbolTableList->tail);
					deleteLastSymTable(symbolTableList);
			        --scope;
			  }
		      ;

initial_expression_list : initial_expression
				  	    |
				        ;

initial_expression : initial_expression COMMA variable_reference ASSIGN_OP logical_expression { AssignTypeCheck($3, $5);}
				   | initial_expression COMMA logical_expression
				   | logical_expression
				   | variable_reference ASSIGN_OP logical_expression { AssignTypeCheck($1, $3);}

control_expression_list : control_expression
				  		|
				  		;

control_expression : control_expression COMMA variable_reference ASSIGN_OP logical_expression { AssignTypeCheck($1, $3);}
				   | control_expression COMMA logical_expression
				   | logical_expression
				   | variable_reference ASSIGN_OP logical_expression { AssignTypeCheck($1, $3);}
				   ;

increment_expression_list : increment_expression 
						  |
						  ;

increment_expression : increment_expression COMMA variable_reference ASSIGN_OP logical_expression { AssignTypeCheck($3, $5);}
					 | increment_expression COMMA logical_expression
					 | logical_expression
					 | variable_reference ASSIGN_OP logical_expression { AssignTypeCheck($1, $3);}
					 ;

function_invoke_statement : ID L_PAREN logical_expression_list R_PAREN SEMICOLON{ 
								FunctParamInvokeCheck(symbolTableList->tail, $1, functParam);
								functParam.clear(); 
								free($1); 
						  }
						  | ID L_PAREN R_PAREN SEMICOLON{
								BTYPE tmp = FunctNoParamInvokeCheck(symbolTableList->tail, $1); 
								return_linenum[return_count] = linenum;
								returnType[return_count] = tmp;
								return_count++;
								free($1);
						  }
						  ;

jump_statement : CONTINUE SEMICOLON { Loop_Check(loop);}
			   | BREAK SEMICOLON { Loop_Check(loop);}
			   | RETURN logical_expression SEMICOLON {
			   		return_linenum[return_count] = linenum;
			   		returnType[return_count] = $2;
			   		return_count++;
			   }
			   ;

variable_reference : array_list { $$ = $1;}
				   | ID{
				   		$$ = checkIDdect(symbolTableList->tail, $1);
				   		free($1);
				   }
				   ;


logical_expression : logical_expression OR_OP logical_term{ 
						logical_expression_num.push_back(linenum);					
						$$ = Bool_TypeCheck($1, $3);
				   }
				   | logical_term{ 
						logical_expression_num.push_back(linenum);
						$$ = $1;
				   }
				   ;

logical_term : logical_term AND_OP logical_factor { $$ = Bool_TypeCheck($1, $3);}
			 | logical_factor { $$ = $1;}
			 ;

logical_factor : NOT_OP logical_factor { $$ = $2;}
			   | relation_expression { $$ = $1;}
			   ;

relation_expression : arithmetic_expression relation_operator arithmetic_expression { $$ = BOOL_t;}
					| arithmetic_expression { $$ = $1;}
					;

relation_operator : LT_OP
				  | LE_OP
				  | EQ_OP
				  | GE_OP
				  | GT_OP
				  | NE_OP
				  ;

arithmetic_expression : arithmetic_expression ADD_OP term { $$ = OP_TypeCheck($1, $3);}
		   			  | arithmetic_expression SUB_OP term { $$ = OP_TypeCheck($1, $3);}
                   	  | relation_expression { $$ = $1;}
		   			  | term { $$ = $1;}
		   			  ;

term : term MUL_OP factor { $$ = OP_TypeCheck($1, $3);}
     | term DIV_OP factor { $$ = OP_TypeCheck($1, $3);}
	 | term MOD_OP factor { $$ = MOD_TypeCheck($1, $3);}
	 | factor { $$ = $1;}
	 ;

factor : variable_reference { $$ = $1;}
	   | SUB_OP factor { $$ = $2;}
	   | L_PAREN logical_expression R_PAREN { $$ = $2;}
	   | ID L_PAREN logical_expression_list R_PAREN{
	   		$$ = FunctParamInvokeCheck(symbolTableList->tail, $1, functParam); 
			functParam.clear();
	   		free($1);
	   }
	   | ID L_PAREN R_PAREN{
	   		$$ = FunctNoParamInvokeCheck(symbolTableList->tail, $1);
			free($1);
	   }
	   | literal_const {
			$$ = $1->constVal->type;
			killAttribute($1);
	   }
	   ;

logical_expression_list : logical_expression_list COMMA logical_expression { functParam.push_back($3);}
						| logical_expression { functParam.push_back($1);}
						;

array_list : ID dimension { 
				$$ = ArrayNameCheck(symbolTableList->tail, $1, arrayCheck);
				arrayCheck.clear();
		   }
		   ;

dimension : dimension ML_BRACE logical_expression MR_BRACE { if(ArrayIndexCheck($3)) { arrayCheck.push_back($3);}}		   
		  | ML_BRACE logical_expression MR_BRACE { if(ArrayIndexCheck($2)) { arrayCheck.push_back($2);}}
		  ;



scalar_type : INT {
				$$ = INT_t;
			}
			| DOUBLE {
				$$ = DOUBLE_t;
			}
			| STRING {
				$$ = STRING_t;
			}
			| BOOL{
				$$ = BOOL_t;
			}
			| FLOAT{
				$$ = FLOAT_t;
			}
			;
 
literal_const : INT_CONST{
					int val = $1;
					$$ = createConstantAttribute(INT_t,&val);		
			  }
			  | SUB_OP INT_CONST{
					int val = -$2;
					$$ = createConstantAttribute(INT_t,&val);
			  }
			  | FLOAT_CONST{
					float val = $1;
					$$ = createConstantAttribute(FLOAT_t,&val);
			  }
			  | SUB_OP FLOAT_CONST{
					float val = -$2;
					$$ = createConstantAttribute(FLOAT_t,&val);
			  }
			  | SCIENTIFIC{
					double val = $1;
					$$ = createConstantAttribute(DOUBLE_t,&val);
			  }
			  | SUB_OP SCIENTIFIC{
					double val = -$2;
					$$ = createConstantAttribute(DOUBLE_t,&val);
			  }
			  | STR_CONST{
					$$ = createConstantAttribute(STRING_t,$1);
					free($1);
			  }
			  | TRUE{
					bool val = true;
					$$ = createConstantAttribute(BOOL_t,&val);
			  }
			  | FALSE{
					bool val = false;
					$$ = createConstantAttribute(BOOL_t,&val);
			  }
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
	//  fprintf( stderr, "%s\t%d\t%s\t%s\n", "Error found in Line ", linenum, "next token: ", yytext );
}


