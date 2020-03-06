%{
#include <stdio.h>
#include <stdlib.h>
	
extern int linenum;             /* declared in lex.l */
extern FILE *yyin;              /* declared by lex */
extern char *yytext;            /* declared by lex */
extern char buf[256];           /* declared in lex.l */
int yyerror(char* msg);
%}

%token SEMICOLON    /* ; */
%token COMMA        /* , */

%token ID           /* identifier */

%token INT          /* keyword */
%token DOUBLE
%token FLOAT
%token STRING
%token BOOL


%token IF
%token WHILE
%token DO
/*lite_const*/
%token CONST
%token INT_LIT
%token STRING_LIT
%token FLOAT_LIT
%token SCIENTIFIC
%token TRUE
%token FALSE
/*statement*/
%token READ 
%token PRINT
%token RETURN
%token BREAK
%token CONTINUE
%token IF
%token ELSE
%token WHILE
%token DO
%token FOR
%token VOID

%right '='
%right '!'
%left EQ NE GE '<' '>' LT LE OR AND 
%left '+' '-'
%left '*' '/' '%'

%nonassoc UMINUS

%%

program : decl_and_def_list
		;

decl_and_def_list	: decl_and_def_list decl_list
					|
					;
/*decl_list*/
decl_list : const_decl
          | var_decl
          | funct_decl
          | funct_defi
		  ;
/*const*/ 
const_decl : CONST type const_list SEMICOLON
		   ;
const_list : const_list COMMA identifier '=' lite_const
		   | identifier '=' lite_const
		   ;

lite_const : INT_LIT
           | STRING_LIT
           | FLOAT_LIT
           | SCIENTIFIC
           | TRUE
           | FALSE
           ;
/*var*/       
var_decl : type var_list SEMICOLON
         ;
var_list : var_list COMMA var
		 | var 
		 ;
var : arry 
	| arry '=' '{' expression_list '}' 
	| identifier
	| identifier '=' expression
	;
		 
/*funct_decl*/
funct_decl : type identifier '(' funct_argu ')' SEMICOLON
		   | VOID identifier '(' funct_argu ')' SEMICOLON
		   ;
/*funct_defi*/
funct_defi : type identifier '(' funct_argu ')' compound
	       | VOID identifier '(' funct_argu ')' compound
		   ;
/*funct_argu*/
funct_argu : funct_Nempty_argu
	   |
	   ; 

funct_Nempty_argu : funct_Nempty_argu COMMA argu 
		   | argu
		   ;
argu : type identifier
     | type arry
     ;
/*arry*/
arry : identifier arry_c
	 ;

arry_c : arry_c '[' INT_LIT ']'
	   | '[' INT_LIT ']'
	   ;
/* expression */
expression : '-' expression %prec UMINUS
	   	   | expression '*' expression
	       | expression '/' expression
	       | expression '%' expression
	       | expression '+' expression
	       | expression '-' expression
	       | expression '<' expression
	       | expression LE expression
	       | expression EQ expression
	       | expression GE expression
	       | expression '>' expression
	       | expression NE expression
	       | '!' expression
	       | expression AND expression
	       | expression OR expression
	       | funct_invoc
	       | '(' expression ')'
	       | lite_const
	       | var_refer 
	       ; 
/*function invocation*/
funct_invoc : identifier '(' expression_list ')' 
			;
expression_list : Nempty_expression_list
				|
				;
Nempty_expression_list : Nempty_expression_list COMMA expression
					   | expression
					   ;	       
/*TYPE*/
type : INT
	 | DOUBLE
	 | FLOAT
	 | STRING
	 | BOOL 
     ; 

identifier : ID
	   	   ;	
/**statements**/
statements : compound
		   | simple
		   | conditional 
		   | while 
		   | for 
		   | jump
	   	   | procedure_call
	   	   ;

compound : '{' compound_content '}'
		 ;

compound_content : compound_content statements
				 | compound_content var_decl
				 | compound_content const_decl
				 |
				 ;

simple : var_refer '=' expression SEMICOLON
	   | PRINT expression SEMICOLON
	   | READ var_refer SEMICOLON
	   ;

var_refer : identifier 
		  | identifier array_refer
		  ;
array_refer : array_refer '[' expression ']'
			| '[' expression ']'
			;

conditional : IF '(' bool_expression ')' compound ELSE compound
			| IF '(' bool_expression ')' compound
			;

while : WHILE '(' bool_expression ')' compound
	  | DO compound WHILE '(' bool_expression ')' SEMICOLON
	  ;

for : FOR '(' initial_expression SEMICOLON control_expression SEMICOLON increment_expression ')' compound
	;

jump : RETURN expression SEMICOLON
	 | BREAK SEMICOLON
	 | CONTINUE SEMICOLON
	 ;

procedure_call : funct_invoc SEMICOLON
			   ;

bool_expression : expression 
				;

initial_expression : identifier '=' expression
				   | expression
				   ;

control_expression : expression 
				   ;

increment_expression : identifier '=' expression
				   | expression
				   ;

/*********************************************************/
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
