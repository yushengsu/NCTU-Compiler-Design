%{
#define LIST                { strncat(buf, yytext, sizeof(buf) - strlen(buf) - 1); }
#define token(t)            { LIST; if (Opt_Token) printf("<%s>\n", #t); }
#define tokenString(t, s)   { LIST; if (Opt_Token) printf("<%s:%s>\n", t, s); }
#define MAX_LINE_LENGTH 257
#define MAX_ID_LENGTH 257
int Opt_Source = 1;
int Opt_Token = 1;
int Opt_Statistic = 1;
int linenum = 1;
char buf[MAX_LINE_LENGTH];
char string_buf[MAX_LINE_LENGTH];

int id_num = 0, i = 0;
int first_time = 0;
int id_freq[100000] = {0};
char id_name[100000][MAX_ID_LENGTH];

%}

digit [0-9]
letter [_a-zA-Z]
id {letter}({letter}|{digit})*
integer (0|([1-9]{digit}*)) 
float {digit}+\.{digit}+
scientific ({float}|{integer})[eE][\+\-]?{digit}+
space [ \t]+


%x STR_PROCESS

%x COMMENT_C
%x COMMENT_CPP

%x PRAGMA
%x PRAG_SOURCE
%x PRAG_TOKEN
%x PRAG_STATISTIC


%%

{integer} { tokenString("integer",yytext);}
{float} { tokenString("float",yytext);}
{scientific} { tokenString("scientific",yytext);}
{space} { LIST;}

("(")   {tokenString("delim", "(");}
(")")   {tokenString("delim", ")");}
(",")   {tokenString("delim", ",");}
(";")   {tokenString("delim", ";");}
("[")   {tokenString("delim", "[");}
("]")   {tokenString("delim", "]");}
("{")   {tokenString("delim", "{");}
("}")   {tokenString("delim", "}");}

("+")   {token("+");}
("-")   {token("-");}
("*")   {token("*");}
("/")   {token("/");}
("%")   {token("%");}
("=")   {token("=");}
("<")   {token("<");}
("<=")  {token("<=");}
("!=")  {token("!=");}
(">=")  {token(">=");}
(">")   {token(">");}
("==")  {token("==");}
("&&")  {token("&&");}
("||")  {token("||");}
("!")   {token("!");}

("while")       {tokenString("KW", "while");}
("do")          {tokenString("KW", "do");}
("if")          {tokenString("KW", "if");}
("else")        {tokenString("KW", "else");}
("true")        {tokenString("KW", "true");}
("false")       {tokenString("KW", "false");} 
("for")         {tokenString("KW", "for");}
("int")         {tokenString("KW", "int");}
("print")       {tokenString("KW", "print");}
("const")       {tokenString("KW", "const");}
("read")        {tokenString("KW", "read");}
("boolean")     {tokenString("KW", "boolean");}
("bool")        {tokenString("KW", "bool");}
("void")        {tokenString("KW", "void");}
("float")       {tokenString("KW", "float");}
("double")      {tokenString("KW", "double");}
("string")      {tokenString("KW", "string");}
("continue")    {tokenString("KW", "continue");}
("break")       {tokenString("KW", "break");}
("return")      {tokenString("KW", "return");}

{id} { 
    tokenString("id",yytext);
    
    if(Opt_Statistic){

        for(i=0; i<=id_num; i++){
            if(!strcmp(yytext, id_name[i])){
                id_freq[i]++;
                first_time++;
                break;
            }
        }

        if(!first_time){
            id_num++;
            strcpy(id_name[id_num], yytext);
            id_freq[id_num]++;
        
            break;
        }

        first_time = 0;

    }
}

("\"") {
    //string process
    
    string_buf[0] = '\0' ;
    LIST;
    BEGIN(STR_PROCESS);
}

<STR_PROCESS>("\\")("\"") { 
    LIST;
    strncat(string_buf, "\"", sizeof(buf) - strlen(buf) - 1);  
}

<STR_PROCESS>("\\")("\\") { 
    LIST;  
    strncat(string_buf, "\\", sizeof(buf) - strlen(buf) - 1);  
}

<STR_PROCESS>("\\") { 
    LIST;  
    strncat(string_buf, "\\", sizeof(buf) - strlen(buf) - 1);  
} 

<STR_PROCESS>("\"") {
    tokenString("string", string_buf);
    string_buf[0] = '\0';
    BEGIN 0;
}

<STR_PROCESS>("\n") { 
    fprintf(stderr, "Error at line %d: %s\n", linenum, yytext);
    exit(1);
}

<STR_PROCESS>(.) {
    LIST;
    strncat(string_buf, yytext, sizeof(buf) - strlen(buf) - 1); 
}


("/*") {
    // C-style comment
    LIST;
    BEGIN(COMMENT_C);
}

<COMMENT_C>(.) {
  LIST;
}

<COMMENT_C>("\n") {
  LIST;
  if (Opt_Source)
    printf("%d:%s\n", linenum, buf);
  linenum++;
  buf[0] = '\0';
}

<COMMENT_C>("*/") {
  LIST;
  BEGIN 0;
}


("//") {
    // C++-style comment
    LIST;
    BEGIN(COMMENT_CPP);
}

<COMMENT_CPP>(.) {
    LIST;
}

<COMMENT_CPP>("\n") {
    LIST;
    if (Opt_Source) printf("%d:%s\n", linenum, buf);
    linenum++;
    buf[0] = '\0';
    BEGIN 0;
}

^("#pragma")  {
    LIST;
    BEGIN(PRAGMA);
}

<PRAGMA>(" ") {
    LIST;
}

<PRAGMA>("\n") {
    fprintf(stderr, "Error at line %d: %s\n", linenum, yytext);
    exit(1);
}

<PRAGMA>("source") {
    LIST;
    BEGIN(PRAG_SOURCE);
}

<PRAGMA>("token") {
    LIST;
    BEGIN(PRAG_TOKEN);
}

<PRAGMA>("statistic") {
    LIST;
    BEGIN(PRAG_STATISTIC);
}


<PRAG_SOURCE>(" ") {
    LIST;
}

<PRAG_SOURCE>("\n") {
    fprintf(stderr, "Error at line %d: %s\n", linenum, yytext);
    exit(1);
}

<PRAG_SOURCE>("on") {
    LIST;
    Opt_Source = 1;
    BEGIN 0;
}

<PRAG_SOURCE>("off") {
    LIST;
    Opt_Source = 0;
    BEGIN 0;
}

<PRAG_SOURCE>("/*") {
    LIST; 
    BEGIN(COMMENT_C); 
}

<PRAG_SOURCE>("//") {
    LIST;
    BEGIN(COMMENT_CPP);
}


<PRAG_SOURCE>(.) { // Unrecognized character
    fprintf(stderr, "Error at line %d: %s\n", linenum, yytext);
    exit(1);
}


<PRAG_TOKEN>(" ") {
    LIST;
}

<PRAG_TOKEN>("on") {
    LIST;
    Opt_Token = 1;
    BEGIN 0;
}

<PRAG_TOKEN>("off") {
    LIST;
    Opt_Token = 0;
    BEGIN 0;
}

<PRAG_TOKEN>("/*")  {
    LIST; 
    BEGIN(COMMENT_C); 
}

<PRAG_TOKEN>("//")  {
    LIST;
    BEGIN(COMMENT_CPP);
}

<PRAG_TOKEN>("\n")  { 
    fprintf(stderr, "Error at line %d: %s\n", linenum, yytext);
    exit(1);
}

<PRAG_TOKEN>(.) { // Unrecognized character
    fprintf(stderr, "Error at line %d: %s\n", linenum, yytext);
    exit(1);
}


<PRAG_STATISTIC>(" ") {
    LIST;
}

<PRAG_STATISTIC>("on") {
    LIST;
    Opt_Statistic = 1;
    BEGIN 0;
}

<PRAG_STATISTIC>("off") {
    LIST;
    Opt_Statistic = 0;
    BEGIN 0;
}

<PRAG_STATISTIC>("/*")  {
    LIST; 
    BEGIN(COMMENT_C); 
}

<PRAG_STATISTIC>("//")  {
    LIST;
    BEGIN(COMMENT_CPP);
}

<PRAG_STATISTIC>("\n")  { 
    fprintf(stderr, "Error at line %d: %s\n", linenum, yytext);
    exit(1);
}
<PRAG_STATISTIC>(.) { // Unrecognized character
    fprintf(stderr, "Error at line %d: %s\n", linenum, yytext);
    exit(1);
}


\n {
    LIST;
    //printf("\nOpt_Source : %d\n", Opt_Source);
    if (Opt_Source) printf("%d:%s\n", linenum, buf);
    ++linenum;
    buf[0] = '\0';
}

. { // Unrecognized character
    fprintf(stderr, "Error at line %d: %s\n", linenum, yytext);
    exit(1);                        
}

%%

int main( int argc, char **argv )
{
    if (argc >= 2){
        yyin = fopen( argv[1], "r" );
        if ( NULL == yyin ) {
            fprintf( stderr, "Cannot open: %s\n", argv[1] );
            exit(-1);
        }
    }
    else{
        yyin = stdin;
    }

    yylex();

    // Process last line without newline
    strncat(buf, "\n", sizeof(buf) - strlen(buf) - 1); 
    if (Opt_Source) printf("%d:%s\n", linenum, buf);
    ++linenum;


    if (Opt_Statistic){
        // Print frequency table
        printf("frequencies of identifiers:\n");
        for(i=1; i<=id_num; i++){
            printf("%s\t%d\n", id_name[i], id_freq[i]);
        }
    }

    exit(0);
}
