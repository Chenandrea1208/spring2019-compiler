%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "Table.h"

extern int linenum;
extern FILE *yyin;
extern char *yytext;
extern char buf[256];
extern int Opt_Symbol;
extern int yylex(void);
int sem_error = 0;
int yyparse();
int yyerror( char *msg );

Dimension* cur_dim;
Idlist* cur_idlist;
SymbolTable* root_table;
SymbolTable* cur_table;

Typelist* cur_typelist;

%}
%token <str> ID
%token <str> INT_CONST
%token <str> FLOAT_CONST
%token <str> SCIENTIFIC
%token <str> STR_CONST

%token <str> LE_OP
%token <str> NE_OP
%token <str> GE_OP
%token <str> EQ_OP
%token <str> AND_OP
%token <str> OR_OP

%token <str> READ
%token <str> BOOLEAN
%token <str> WHILE
%token <str> DO
%token <str> IF
%token <str> ELSE
%token <str> TRUE
%token <str> FALSE
%token <str> FOR
%token <str> INT
%token <str> PRINT
%token <str> BOOL
%token <str> VOID
%token <str> FLOAT
%token <str> DOUBLE
%token <str> STRING
%token <str> CONTINUE
%token <str> BREAK
%token <str> RETURN
%token <str> CONST

%token <str> L_PAREN
%token <str> R_PAREN
%token <str> COMMA
%token <str> SEMICOLON
%token <str> ML_BRACE
%token <str> MR_BRACE
%token <str> L_BRACE
%token <str> R_BRACE
%token <str> ADD_OP
%token <str> SUB_OP
%token <str> MUL_OP
%token <str> DIV_OP
%token <str> MOD_OP
%token <str> ASSIGN_OP
%token <str> LT_OP
%token <str> GT_OP
%token <str> NOT_OP

%type <str> scalar_type
%type <Id> array_decl
%type <str> literal_const
//%type <Idlist> parameter_list
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
%union  {
  int num;
  double dnum;
  char* str;
  struct Id* Id;
  struct Idlist* Idlist;
  /*
  struct Value* value;
  struct Attribute* attribute;
  struct TypeList* typelist;
  struct Expr* expr;
  struct ExprList* exprlist;*/
}

%start program
%%

program :decl_list funct_def decl_and_def_list 
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
            { insert_func_to_table($2, "function", $1, NULL, cur_table);}
            compound_statement                 
          | scalar_type ID L_PAREN parameter_list R_PAREN  
            { insert_func_to_table($2, "function", $1, cur_typelist, cur_table);}
            compound_statement 
          | VOID ID L_PAREN R_PAREN 
            { insert_func_to_table($2, "function", $1, NULL, cur_table);}
            compound_statement                        
          | VOID ID L_PAREN parameter_list R_PAREN 
            { insert_func_to_table($2, "function", $1, cur_typelist, cur_table); }
            compound_statement         
          ;

funct_decl : scalar_type ID L_PAREN R_PAREN SEMICOLON                   { insert_func_to_table($2, "function", $1, NULL, cur_table); }
           | scalar_type ID L_PAREN parameter_list R_PAREN SEMICOLON    { insert_func_to_table($2, "function", $1, cur_typelist, cur_table); cur_typelist= create_typelist();}
           | VOID ID L_PAREN R_PAREN SEMICOLON                          { insert_func_to_table($2, "function", $1, NULL, cur_table); }
           | VOID ID L_PAREN parameter_list R_PAREN SEMICOLON           { insert_func_to_table($2, "function", $1, cur_typelist, cur_table); cur_typelist= create_typelist(); }
           ;

parameter_list : parameter_list COMMA scalar_type ID           { if(parameter_detect_error($4,cur_typelist)==0)insert_typelist($4, $3, NULL, cur_typelist); 
                                                                 else {sem_error = 1;fprintf( stderr, "##########Error at Line %d: %s redeclared.##########\n", linenum,$4);}}             
               | parameter_list COMMA scalar_type array_decl   { if(parameter_detect_error($4->idname,cur_typelist)==0)insert_typelist($4->idname, $3, $4->dimension, cur_typelist); 
                                                                else{
                                                                  sem_error = 1; 
                                                                  fprintf( stderr, "##########Error at Line %d: %s redeclared.##########\n", linenum,$4->idname);
                                                                }
                                                              }             
               | scalar_type array_decl                        { if(parameter_detect_error($2->idname,cur_typelist)==0)insert_typelist($2->idname, $1, $2->dimension, cur_typelist); 
                                                                 else{
                                                                  sem_error = 1; 
                                                                  fprintf( stderr, "##########Error at Line %d: %s redeclared.##########\n", linenum,$2->idname);
                                                                 }
                                                               }             
               | scalar_type ID                                { if(parameter_detect_error($2,cur_typelist)==0)insert_typelist($2, $1, NULL, cur_typelist); 
                                                                 else {
                                                                  sem_error = 1;fprintf( stderr, "##########Error at Line %d: %s redeclared.##########\n", linenum,$2);
                                                                 }
                                                               }             
               ;

var_decl : scalar_type identifier_list SEMICOLON   { //test_idlist(cur_idlist);
                                                     insert_idlist_to_table("variable",$1,cur_idlist,cur_table); cur_idlist = create_idlist(); }                  
         ;

identifier_list : identifier_list COMMA ID                                  { if(detect_error($3,cur_table)==0)
                                                                                insert_chartoidlist($3, cur_idlist,NULL);
                                                                              else{
                                                                                sem_error = 1;
                                                                               fprintf( stderr, "##########Error at Line %d: %s redeclared.##########\n", linenum,$3);
                                                                              }
                                                                            }
                | identifier_list COMMA ID ASSIGN_OP logical_expression     { if(detect_error($3,cur_table)==0)
                                                                                insert_chartoidlist($3, cur_idlist,NULL);
                                                                              else{
                                                                                sem_error = 1;
                                                                               fprintf( stderr, "##########Error at Line %d: %s redeclared.##########\n", linenum,$3);  
                                                                              }
                                                                            }
                | identifier_list COMMA array_decl ASSIGN_OP initial_array  { if(detect_error($3->idname,cur_table)==0)
                                                                                insert_idlist($3, cur_idlist);
                                                                              else{
                                                                                sem_error = 1;
                                                                               fprintf( stderr, "##########Error at Line %d: %s redeclared.##########\n", linenum,$3->idname);  
                                                                              }
                                                                            }
                | identifier_list COMMA array_decl                          { if(detect_error($3->idname,cur_table)==0)
                                                                                insert_idlist($3, cur_idlist);
                                                                             else{
                                                                               sem_error = 1;
                                                                               fprintf( stderr, "##########Error at Line %d: %s redeclared.##########\n", linenum,$3->idname);
                                                                             }
                                                                            }
                | array_decl ASSIGN_OP initial_array                        { if(detect_error($1->idname,cur_table)==0)
                                                                                insert_idlist($1, cur_idlist);
                                                                              else{
                                                                                sem_error = 1;
                                                                               fprintf( stderr, "##########Error at Line %d: %s redeclared.##########\n", linenum,$1->idname);  
                                                                              }
                                                                            }
                | array_decl                                                { if(detect_error($1->idname,cur_table)==0)
                                                                                insert_idlist($1, cur_idlist);
                                                                              else{
                                                                                sem_error = 1;
                                                                               fprintf( stderr, "##########Error at Line %d: %s redeclared.##########\n", linenum,$1->idname);  
                                                                              }
                                                                            }
                | ID ASSIGN_OP logical_expression                           { if(detect_error($1,cur_table)==0)
                                                                                insert_chartoidlist($1, cur_idlist,NULL);
                                                                              else{
                                                                                sem_error = 1;
                                                                               fprintf( stderr, "##########Error at Line %d: %s redeclared.##########\n", linenum,$1);  
                                                                              }
                                                                            }                       
                | ID                                                        { if(detect_error($1,cur_table)==0)
                                                                                insert_chartoidlist($1, cur_idlist,NULL);
                                                                              else{
                                                                                sem_error = 1;
                                                                                fprintf( stderr, "##########Error at Line %d: %s redeclared.##########\n", linenum,$1);  
                                                                              }
                                                                            }                      
                ;

initial_array : L_BRACE literal_list R_BRACE
              ;

literal_list : literal_list COMMA logical_expression
             | logical_expression
             | 
             ;

const_decl : CONST scalar_type const_list SEMICOLON       { /*test_idlist(cur_idlist);*/ insert_idlist_to_table("constant", $2, cur_idlist, cur_table); cur_idlist = create_idlist();} 
           ;

const_list : const_list COMMA ID ASSIGN_OP literal_const  { if(detect_error($3,cur_table)==0)
                                                              insert_chartoidlist($3, cur_idlist, $5);
                                                            else {
                                                              sem_error = 1;
                                                              fprintf( stderr, "##########Error at Line %d: %s redeclared.##########\n", linenum,$3);  
                                                            }  
                                                          }
           | ID ASSIGN_OP literal_const                   {   if(detect_error($1,cur_table)==0)
                                                                insert_chartoidlist($1, cur_idlist, $3);
                                                              else {
                                                                fprintf( stderr, "##########Error at Line %d: %s redeclared.##########\n", linenum,$1);
                                                                sem_error = 1;  
                                                              } 
                                                          }
           ;

array_decl : ID dim   { $$= insert_create_id($1,cur_dim); cur_dim = create_dim(); }
           ;

dim : dim ML_BRACE INT_CONST MR_BRACE { insert_dim(cur_dim, atoi($3)); }
    | ML_BRACE INT_CONST MR_BRACE     { insert_dim(cur_dim, atoi($2));}
    ;

compound_statement : L_BRACE                      { cur_table = create_table( cur_table );
                                                    insert_typelist_to_table( "parameter", cur_typelist, cur_table); 
                                                    cur_typelist= create_typelist();}
                     var_const_stmt_list R_BRACE  { if(Opt_Symbol)test_table(cur_table); cur_table = cur_table->parent;}
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
                 | PRINT logical_expression SEMICOLON
                 | READ variable_reference SEMICOLON
                 ;

conditional_statement : IF L_PAREN logical_expression R_PAREN compound_statement
                      | IF L_PAREN logical_expression R_PAREN compound_statement ELSE compound_statement
                      ;

while_statement : WHILE L_PAREN logical_expression R_PAREN compound_statement
                | DO compound_statement WHILE L_PAREN logical_expression R_PAREN SEMICOLON
                ;

for_statement : FOR L_PAREN initial_expression_list SEMICOLON control_expression_list SEMICOLON increment_expression_list R_PAREN 
                    compound_statement
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



scalar_type : INT     
            | DOUBLE  
            | STRING  
            | BOOL    
            | FLOAT   
            ;
 
literal_const : INT_CONST   
              | FLOAT_CONST 
              | SCIENTIFIC
              | SUB_OP INT_CONST   
              | SUB_OP FLOAT_CONST 
              | SUB_OP SCIENTIFIC  
              | STR_CONST   
              | TRUE        
              | FALSE       
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

int  main( int argc, char **argv )
{

  if( argc == 1 )
  {
    yyin = stdin;
  }
  else if( argc == 2 )
  {
    FILE *fp = fopen( argv[1], "r" );
    if( fp == NULL ) {
        fprintf( stderr, "Open file error\n" );
        exit(-1);
    }
    yyin = fp;
  }
  else
  {
      fprintf( stderr, "Usage: ./parser [filename]\n" );
      exit(0);
  } 
  cur_dim = create_dim();
  //cur_idlist = NULL;
  cur_idlist = create_idlist();
  root_table = create_root_table();
  cur_table = root_table;
  cur_typelist= create_typelist();

  yyparse();  /* primary procedure of parser */
  if(Opt_Symbol)test_table(cur_table);
  if(sem_error == 1){
    fprintf( stdout, "\n|--------------------------------|\n" );
    fprintf( stdout, "|  There is no syntactic error!  |\n" );
    fprintf( stdout, "|--------------------------------|\n" );
  }
  else{
    fprintf( stdout, "\n|---------------------------------------------|\n" );
    fprintf( stdout, "|  There is no syntactic and semantic error!  |\n" );
    fprintf( stdout, "|---------------------------------------------|\n" );
  }
  exit(0);
}
