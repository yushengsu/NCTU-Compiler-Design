%{
#include <bits/stdc++.h>
#include <iomanip>
#include <vector>
using namespace std;
struct type{
    string string_val;
};
#define YYSTYPE type


extern "C"{
    extern int yylex(void);
    int yyerror(char *msg);
}

extern int linenum;
extern FILE *yyin;
extern char *yytext;
extern char buf[256];
extern int yylex();
extern int level;
extern int Opt_Symbol;
extern int is_else;
int yyerror(char *msg);

struct line{
    string name;
    string kind;
    int level;
    string type;
    string attribute;
};

line row;
line argu;
vector<line> row_table;
vector<line> argument;
vector<vector<line>> symboltable;

void print(vector<line> table);
void condition_print();
bool check(line row, vector<line> table);
void insert(line row, int level, int if_arg = 0);

%}

%token  ID
%token  INT_CONST
%token  FLOAT_CONST
%token  SCIENTIFIC
%token  STR_CONST

%token  LE_OP
%token  NE_OP
%token  GE_OP
%token  EQ_OP
%token  AND_OP
%token  OR_OP

%token  READ
%token  BOOLEAN
%token  WHILE
%token  DO
%token  IF
%token  ELSE
%token  TRUE
%token  FALSE
%token  FOR
%token  INT
%token  PRINT
%token  BOOL
%token  VOID
%token  FLOAT
%token  DOUBLE
%token  STRING
%token  CONTINUE
%token  BREAK
%token  RETURN
%token  CONST

%token  L_PAREN
%token  R_PAREN
%token  COMMA
%token  SEMICOLON
%token  ML_BRACE
%token  MR_BRACE
%token  L_BRACE
%token  R_BRACE
%token  ADD_OP
%token  SUB_OP
%token  MUL_OP
%token  DIV_OP
%token  MOD_OP
%token  ASSIGN_OP
%token  LT_OP
%token  GT_OP
%token  NOT_OP

/*  Program 
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


program : decl_list funct_def decl_and_def_list{
          for(int i=int(symboltable.size())-1; i>=0; --i)
            if(Opt_Symbol)
                print(symboltable[i]);
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

RESET : {row = (line){"", "", 0, "", ""};}

funct_def : scalar_type ID L_PAREN R_PAREN compound_statement{
            row.name = $2.string_val;
            row.type = $1.string_val;
            row.kind = "function";
            row.level = level;
            if(check(row, symboltable[level])) insert(row, level);
            } RESET

          | scalar_type ID L_PAREN parameter_list R_PAREN compound_statement{
            for(int i=int(argument.size())-1; i>=0; --i) insert(argument[i], level+1, 1);
            argument.clear();
            row.name = $2.string_val;
            row.type = $1.string_val;
            row.kind = "function";
            row.level = level;
            row.attribute = $4.string_val;
            if(check(row, symboltable[level])) insert(row, level);
            } RESET

          | VOID ID L_PAREN R_PAREN compound_statement{
            row.name = $2.string_val;
            row.type = "void";
            row.kind = "function";
            row.level = level;
            if(check(row, symboltable[level])) insert(row, level);
            } RESET

          | VOID ID L_PAREN parameter_list R_PAREN compound_statement{
            for(int i=int(argument.size())-1; i>=0; --i) insert(argument[i], level+1, 1);
            argument.clear();
            row.name = $2.string_val;
            row.type = "void";
            row.kind = "function";
            row.level = level;
            row.attribute = $4.string_val;
            if(check(row, symboltable[level])) insert(row, level);
            } RESET
          ;

funct_decl : scalar_type ID L_PAREN R_PAREN SEMICOLON{
            row.name = $2.string_val;
            row.type = $1.string_val;
            row.kind = "function";
            insert(row, level);
            } RESET

           | scalar_type ID L_PAREN parameter_list R_PAREN SEMICOLON{
            row.name = $2.string_val;
            row.type = $1.string_val;
            row.kind = "function";
            row.attribute = $4.string_val;
            insert(row, level);
            argument.clear();
            } RESET

           | VOID ID L_PAREN R_PAREN SEMICOLON{
            row.name = $2.string_val;
            row.type = "void";
            row.kind = "function";
            insert(row, level);
            } RESET
            
           | VOID ID L_PAREN parameter_list R_PAREN SEMICOLON{
            row.name = $2.string_val;
            row.type = "void";
            row.kind = "function";
            row.attribute = $4.string_val;
            insert(row, level);
            argument.clear();
            } RESET
           ;

ARG_PUSH : { argument.push_back(argu);}
ARG_RESET : { argu = (line){"", "", 0, "", ""};}

parameter_list : parameter_list COMMA scalar_type ID{
                 string str1 = "," + $3.string_val;
                 $$.string_val = str1;

                 argu.type = str1;
                 argu.name = $4.string_val;
                 argu.level = level + 1;
                 argu.kind = "parameter";
                 } ARG_PUSH ARG_RESET

               | parameter_list COMMA scalar_type array_decl{
                 string str1 = "," + $3.string_val + row.type;
                 $$.string_val = str1;

                 argu.type = str1;
                 argu.name = row.name;
                 argu.level = level + 1;
                 argu.kind = "parameter";
                 } ARG_PUSH ARG_RESET

               | scalar_type array_decl{
                 $$.string_val = $1.string_val + row.type;

                 argu.type = $$.string_val;
                 argu.name = row.name;
                 argu.level = level + 1;
                 argu.kind = "parameter";
                 } ARG_PUSH ARG_RESET

               | scalar_type ID{
                 $$.string_val = $1.string_val;

                 argu.type = $$.string_val;
                 argu.name = $2.string_val;
                 argu.level = level + 1;
                 argu.kind = "parameter";
                 } ARG_PUSH ARG_RESET
               ;

var_decl : scalar_type identifier_list SEMICOLON{
           for(int i=0; i<row_table.size(); ++i){
                row_table[i].kind = "variable";
                row_table[i].level = level;
                row_table[i].type = $1.string_val + row_table[i].type;
                insert(row_table[i], level);
                /*cout << endl;
                cout << "***=================================================================================***";
                cout << endl;
                print(row_table);
                cout << endl;
                cout << "***=================================================================================***";
                cout << endl;*/

           }
           row_table.clear();
           } RESET
         ;

PUSH : { row_table.push_back(row);}

identifier_list : identifier_list COMMA ID{
                  row.name = $3.string_val;    
                  } PUSH RESET

                | identifier_list COMMA ID ASSIGN_OP logical_expression{
                  row.name = $3.string_val;
                  } PUSH RESET

                | identifier_list COMMA array_decl ASSIGN_OP initial_array PUSH RESET

                | identifier_list COMMA array_decl PUSH RESET

                | array_decl ASSIGN_OP initial_array PUSH RESET

                | array_decl PUSH RESET

                | ID ASSIGN_OP logical_expression{
                  row.name = $1.string_val;
                  } PUSH RESET

                | ID{
                  row.name = $1.string_val;
                  } PUSH RESET
                ;

initial_array : L_BRACE literal_list R_BRACE
              ;

literal_list : literal_list COMMA logical_expression
             | logical_expression
             | 
             ;

const_decl : CONST scalar_type const_list SEMICOLON{
             for(int i=0; i<row_table.size(); ++i){
                row_table[i].type = $2.string_val;
                insert(row_table[i], level);
             }
             row_table.clear();
             } RESET
           ;

const_list : const_list COMMA ID ASSIGN_OP literal_const{
             row.name = $3.string_val;
             row.kind = "constant";
             row.level = level;
             row.attribute = $5.string_val;
             } PUSH
           | ID ASSIGN_OP literal_const{
             row.name = $1.string_val;
             row.kind = "constant";
             row.level = level;
             row.attribute = $3.string_val;
             } PUSH
           ;

array_decl : ID dim{
             row.name= $1.string_val;
             row.type = $2.string_val;
             }
           ;

dim : dim ML_BRACE INT_CONST MR_BRACE{
      $$.string_val = $1.string_val + $2.string_val + $3.string_val + $4.string_val;
      }
    | ML_BRACE INT_CONST MR_BRACE{
      $$.string_val = $1.string_val + $2.string_val + $3.string_val;
      }
    ;

compound_statement : L_BRACE var_const_stmt_list R_BRACE
                   ;

LEVEL_COUT : {/*cout << level << endl;*/}

var_const_stmt_list : var_const_stmt_list statement LEVEL_COUT
                    | var_const_stmt_list var_decl LEVEL_COUT
                    | var_const_stmt_list const_decl LEVEL_COUT
                    |
                    ;

statement : compound_statement
          | simple_statement{ condition_print();}
          | conditional_statement
          | while_statement
          | for_statement{ condition_print();}
          | function_invoke_statement{ condition_print();}
          | jump_statement{ condition_print();}
          ;     

simple_statement : variable_reference ASSIGN_OP logical_expression SEMICOLON
                 | PRINT logical_expression SEMICOLON
                 | READ variable_reference SEMICOLON
                 ;

conditional_statement : IF L_PAREN logical_expression R_PAREN L_BRACE var_const_stmt_list R_BRACE{
                        condition_print();
                        print(symboltable[int(symboltable.size())-1]);
                        symboltable.pop_back();
                      }
                      | IF L_PAREN logical_expression R_PAREN 
                        L_BRACE var_const_stmt_list R_BRACE
                        ELSE
                        L_BRACE var_const_stmt_list R_BRACE{
                        print(symboltable[int(symboltable.size())-1]);
                        symboltable.pop_back();
                      }
                      ;
while_statement : WHILE L_PAREN logical_expression R_PAREN
                  L_BRACE var_const_stmt_list R_BRACE{
                  condition_print();
                  print(symboltable[int(symboltable.size())-1]);
                  symboltable.pop_back();
                }
                | DO L_BRACE
                  var_const_stmt_list
                  R_BRACE WHILE L_PAREN logical_expression R_PAREN SEMICOLON{
                  condition_print();
                  print(symboltable[int(symboltable.size())-1]);
                  symboltable.pop_back();
                }
                ;

for_statement : FOR L_PAREN initial_expression_list SEMICOLON control_expression_list SEMICOLON increment_expression_list R_PAREN 
                    L_BRACE var_const_stmt_list R_BRACE
              ;

initial_expression_list : initial_expression
                        |
                        ;

initial_expression : initial_expression COMMA variable_reference ASSIGN_OP logical_expression
                   | initial_expression COMMA logical_expression
                   | logical_expression
                   | variable_reference ASSIGN_OP logical_expression

control_expression_list : control_expression
                        |
                        ;

control_expression : control_expression COMMA variable_reference ASSIGN_OP logical_expression
                   | control_expression COMMA logical_expression
                   | logical_expression
                   | variable_reference ASSIGN_OP logical_expression
                   ;

increment_expression_list : increment_expression 
                          |
                          ;

increment_expression : increment_expression COMMA variable_reference ASSIGN_OP logical_expression
                     | increment_expression COMMA logical_expression
                     | logical_expression
                     | variable_reference ASSIGN_OP logical_expression
                     ;

function_invoke_statement : ID L_PAREN logical_expression_list R_PAREN SEMICOLON
                          | ID L_PAREN R_PAREN SEMICOLON
                          ;

jump_statement : CONTINUE SEMICOLON
               | BREAK SEMICOLON
               | RETURN logical_expression SEMICOLON
               ;

variable_reference : array_list
                   | ID
                   ;


logical_expression : logical_expression OR_OP logical_term
                   | logical_term
                   ;

logical_term : logical_term AND_OP logical_factor
             | logical_factor
             ;

logical_factor : NOT_OP logical_factor
               | relation_expression
               ;

relation_expression : relation_expression relation_operator arithmetic_expression
                    | arithmetic_expression
                    ;

relation_operator : LT_OP
                  | LE_OP
                  | EQ_OP
                  | GE_OP
                  | GT_OP
                  | NE_OP
                  ;

arithmetic_expression : arithmetic_expression ADD_OP term
                      | arithmetic_expression SUB_OP term
                      | term
                      ;

term : term MUL_OP factor
     | term DIV_OP factor
     | term MOD_OP factor
     | factor
     ;

factor : SUB_OP factor
       | literal_const
       | variable_reference
       | L_PAREN logical_expression R_PAREN
       | ID L_PAREN logical_expression_list R_PAREN
       | ID L_PAREN R_PAREN
       ;

logical_expression_list : logical_expression_list COMMA logical_expression
                        | logical_expression
                        ;

array_list : ID dimension
           ;

dimension : dimension ML_BRACE logical_expression MR_BRACE         
          | ML_BRACE logical_expression MR_BRACE
          ;

scalar_type : INT { condition_print(); $$ = $1;}
            | DOUBLE { condition_print(); $$ = $1;}
            | STRING { condition_print(); $$ = $1;}
            | BOOL { condition_print(); $$ = $1;}
            | FLOAT { condition_print(); $$ = $1;}
            ;
 
literal_const : INT_CONST {$$ = $1;}
              | FLOAT_CONST {$$ = $1;}
              | SCIENTIFIC {$$ = $1;}
              | STR_CONST {$$ = $1;}
              | TRUE {$$ = $1;}
              | FALSE {$$ = $1;}
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

void print(vector<line> table){
    printf("=======================================================================================\n"); 
    printf("Name%*c", 29, ' ');
    printf("Kind%*c", 7, ' ');
    printf("Level%*c", 7, ' ');
    printf("Type%*c", 15, ' ');
    printf("Attribute%*c\n", 15, ' ');
    printf("---------------------------------------------------------------------------------------\n");
    for(int i=0;i<table.size();i++){        
        cout << setiosflags( ios::left ) 
        << setw(33) << table[i].name 
        << setw(11) << table[i].kind;

        if(!table[i].level) cout << setw(12) << to_string(table[i].level) + "(global)";
        else cout << setw(12) << to_string(table[i].level) + "(local)";

        cout << setw(19) << table[i].type 
        << setw(15) << table[i].attribute
        << endl;
        
    }
    printf("=======================================================================================\n");
}

void condition_print(){
    if(is_else){
        print(symboltable[int(symboltable.size())-1]);
        symboltable.pop_back();
        is_else = 0;
    }
}

bool check(line row, vector<line> table){
    for(int i=0;i<table.size(); ++i){
        if(row.name == table[i].name && row.kind == table[i].kind &&\
           row.level == table[i].level && row.type == table[i].type &&\
           row.attribute == table[i].attribute)
            return false;
    }
    return true;
}

void insert(line row, int level, int if_arg){
    vector<line> new_table;
    if(level > int(symboltable.size())-1) symboltable.push_back(new_table);
    else if(level < int(symboltable.size())-1){
        if(Opt_Symbol) print(symboltable[level+1]);
        symboltable.pop_back();
    }
    if(!if_arg) symboltable[level].push_back(row);
    else symboltable[level].insert(symboltable[level].begin(), row);
    
}
