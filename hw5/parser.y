%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "header.h"
#include "symtab.h"
#include "semcheck.h"

extern int linenum;
extern FILE	*yyin;
extern char	*yytext;
extern char buf[256];
extern int Opt_Symbol;		/* declared in lex.l */

int loop=0;
int deep=0;
int cur =0;

FILE *fpout;
int stack = 0;
int scope = 0;
int comm = 0;
char fileName[256];
struct SymTable *symbolTable;
__BOOLEAN paramError;
struct PType *funcReturn;
__BOOLEAN semError = __FALSE;
int inloop = 0;
int OPT_main = 0;
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
					checkUndefinedFunc(symbolTable);
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
					insertFuncIntoSymTable( symbolTable, $2, 0, $1, scope, __TRUE );
				}

			 
			}
			compound_statement { funcReturn = 0; fprintf(fpout, ".end method\n" );}	
		  | scalar_type ID L_PAREN parameter_list R_PAREN  
			{				
				funcReturn = $1;
				struct SymNode *node;
				paramError = checkFuncParam( $4 );
				if( paramError == __TRUE ){
					fprintf( stdout, "########## Error at Line#%d: param(s) with several fault!! ##########\n", linenum );
					semError = __TRUE;
				}
				// check and insert function into symbol table
				else{
					
					node = findFuncDeclaration( symbolTable, $2 );

					if( node != 0 ){
						if(verifyFuncDeclaration( symbolTable, $4, $1, node ) == __TRUE){	
							insertParamIntoSymTable( symbolTable, $4, scope+1 );
						}				
					}
					else{
						insertParamIntoSymTable( symbolTable, $4, scope+1 );				
						insertFuncIntoSymTable( symbolTable, $2, $4, $1, scope, __TRUE );
					}
				}
			 
			} 	
			compound_statement { funcReturn = 0;fprintf(fpout, ".end method\n" ); }
		  | VOID ID L_PAREN R_PAREN 
			{
				funcReturn = createPType(VOID_t); 
				struct SymNode *node;
				node = findFuncDeclaration( symbolTable, $2 );

				if( node != 0 ){
					verifyFuncDeclaration( symbolTable, 0, createPType( VOID_t ), node );					
				}
				else{
					insertFuncIntoSymTable( symbolTable, $2, 0, createPType( VOID_t ), scope, __TRUE );	
				}
			 
			}
			compound_statement { funcReturn = 0; fprintf(fpout, "\treturn\n.end method\n" ); }	
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
						insertFuncIntoSymTable( symbolTable, $2, $4, createPType( VOID_t ), scope, __TRUE );
					}
				}
			 
			} 
			compound_statement { funcReturn = 0; fprintf(fpout, "\treturn\n.end method\n" );}		  
		  ;

funct_decl : scalar_type ID L_PAREN R_PAREN SEMICOLON
			{
				insertFuncIntoSymTable( symbolTable, $2, 0, $1, scope, __FALSE );	
			}
		   | scalar_type ID L_PAREN parameter_list R_PAREN SEMICOLON
		    {
				paramError = checkFuncParam( $4 );
				if( paramError == __TRUE ){
					fprintf( stdout, "########## Error at Line#%d: param(s) with several fault!! ##########\n", linenum );
					semError = __TRUE;
				}
				else {
					insertFuncIntoSymTable( symbolTable, $2, $4, $1, scope, __FALSE );
				}
			}
		   | VOID ID L_PAREN R_PAREN SEMICOLON
			{				
				insertFuncIntoSymTable( symbolTable, $2, 0, createPType( VOID_t ), scope, __FALSE );
			}
		   | VOID ID L_PAREN parameter_list R_PAREN SEMICOLON
			{
				paramError = checkFuncParam( $4 );
				if( paramError == __TRUE ){
					fprintf( stdout, "########## Error at Line#%d: param(s) with several fault!! ##########\n", linenum );
					semError = __TRUE;	
				}
				else {
					insertFuncIntoSymTable( symbolTable, $2, $4, createPType( VOID_t ), scope, __FALSE );
				}
			}
		   ;

parameter_list : parameter_list COMMA scalar_type ID
			   {
				struct param_sem *ptr;
				ptr = createParam( createIdList( $4 ), $3 );
				param_sem_addParam( $1, ptr );
				$$ = $1;
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
			   | scalar_type ID { $$ = createParam( createIdList( $2 ), $1 ); }
			   ;
 
var_decl : scalar_type identifier_list SEMICOLON
			{
				struct varDeclParam *ptr;
				struct SymNode *newNode;
				for( ptr=$2 ; ptr!=0 ; ptr=(ptr->next) ) {						
					if( verifyRedeclaration( symbolTable, ptr->para->idlist->value, scope ) == __FALSE ) { }
					else {
						if( verifyVarInitValue( $1, ptr, symbolTable, scope ) ==  __TRUE ){	
							newNode = createVarNode( ptr->para->idlist->value, scope, ptr->para->pType );
							if(scope==0) {
								switch(ptr->para->pType->type) {
									case INTEGER_t:
										fprintf(fpout,".field public static %s I\n",ptr->para->idlist->value);
										break;
									case BOOLEAN_t:
										fprintf(fpout,".field public static %s Z\n",ptr->para->idlist->value);
										break;
									case FLOAT_t:
										fprintf(fpout,".field public static %s F\n",ptr->para->idlist->value);
										break;
									case DOUBLE_t:
										fprintf(fpout,".field public static %s D\n",ptr->para->idlist->value);
										break;
								}
							}
							insertTab( symbolTable, newNode );											
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
				}
                | ID 
				{
					struct param_sem *ptr;					
					ptr = createParam( createIdList( $1 ), createPType( VOID_t ) );
					$$ = createVarDeclParam( ptr, 0 );				
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

const_decl 	: CONST scalar_type const_list SEMICOLON
			{
				struct SymNode *newNode;				
				struct constParam *ptr;
				for( ptr=$3; ptr!=0; ptr=(ptr->next) ){
					if( verifyRedeclaration( symbolTable, ptr->name, scope ) == __TRUE ){//no redeclare
						if( ptr->value->category != $2->type ){//type different
							
							newNode = createConstNode( ptr->name, scope, $2, ptr->value );
							insertTab( symbolTable, newNode );
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
					////////////
						struct SymNode * node_ = lookupSymbol( symbolTable, $1->varRef->id, scope, __FALSE );
						if(node_->scope == 0) {
							fprintf(fpout, "\tputstatic test1/%s ", node_->name);
							print_type(node_);
							fprintf(fpout, "\n" );
						}
						else{
							int stack_ = lookupStack( symbolTable, node_ );
							if(OPT_main == 1) stack_++;
							genstore(node_); 
							fprintf(fpout, "%d\n", stack_);
						}
					///////////
					}
				 | PRINT 
				 	{fprintf(fpout, "\tgetstatic java/lang/System/out Ljava/io/PrintStream;\n" ); }
				 	logical_expression SEMICOLON 
				 	{ verifyScalarExpr( $3, "print" ); 
						fprintf(fpout, "\tinvokevirtual java/io/PrintStream/print(" );
						print_type_s($3->pType->type);
						fprintf(fpout, ")V\n");
				 	}
				 | READ variable_reference SEMICOLON 
					{ 
						if( verifyExistence( symbolTable, $2, scope, __TRUE ) == __TRUE )						
							verifyScalarExpr( $2, "read" );
						fprintf(fpout, "\tgetstatic test1/_sc Ljava/util/Scanner;\n");
						fprintf(fpout, "\tinvokevirtual java/util/Scanner/next");
						//Int()I Boolean()Z Float()F Double()D
						////////////
							struct SymNode * node_ = lookupSymbol( symbolTable, $2->varRef->id, scope, __FALSE );
							switch(node_->type->type) {
								case INTEGER_t:
									fprintf(fpout,"Int()I\n");
									break;
								case BOOLEAN_t:
									fprintf(fpout,"Boolean()Z\n");
									break;
								case FLOAT_t:
									fprintf(fpout,"Float()F\n");
									break;
								case DOUBLE_t:
									fprintf(fpout,"Double()D\n");
									break;
							}
							
							if(node_->scope == 0) {
								fprintf(fpout, "\tputstatic test1/%s ", node_->name);
								print_type(node_);
								fprintf(fpout, "\n" );
							}
							else{
								int stack_ = lookupStack( symbolTable, node_ );
								if(OPT_main == 1) stack_++;
								genstore(node_); 
								fprintf(fpout, "%d\n", stack_);
							}
						///////////	 
					}
				 ;

conditional_statement : IF L_PAREN conditional_if  R_PAREN 
						M1
						compound_statement{
							fprintf(fpout, "Lelse_%d:\n", loop-cur);cur++;
							if(cur==deep) {
								cur=0;
								deep=0;
							}
						}
					  | IF L_PAREN conditional_if  R_PAREN 
					  	M1
					  	compound_statement
						ELSE M2
						compound_statement
						{
							fprintf(fpout, "Lexit_%d:\n",loop-cur );
							cur++;
							if(cur==deep) {
								cur=0;
								deep=0;
							}
						}
					  ;
M1	:	{ deep++;loop++; fprintf(fpout, "\tifeq Lelse_%d\n", loop);	}
	;
M2  :	{	fprintf(fpout, "\tgoto Lexit_%d\n", loop);
			fprintf(fpout, "Lelse_%d:\n", loop-cur);}
	;
conditional_if : logical_expression { verifyBooleanExpr( $1, "if" ); };;					  

				
while_statement : WHILE L_PAREN {
						loop++;deep++;
						fprintf(fpout, "Lbegin_%d:\n", loop);
					}
					logical_expression 
					{ verifyBooleanExpr( $4, "while" ); 
						fprintf(fpout, "\tifeq Lexit_%d\n", loop);
					} 
					R_PAREN { inloop++; }
					compound_statement { 
						fprintf(fpout, "\tgoto Lbegin_%d\n", loop - cur);
						inloop--; 
						fprintf(fpout, "Lexit_%d:\n", loop - cur);
						if(++cur==deep){
							cur  = 0;
							deep =0;
						}  
					}
				| { inloop++; loop++;deep++;
						fprintf(fpout, "Lbegin_%d:\n", loop);} DO compound_statement 
						WHILE L_PAREN logical_expression R_PAREN SEMICOLON  
					{ 
						 fprintf(fpout, "\tifeq Lexit_%d\n", loop);
						 fprintf(fpout, "\tgoto Lbegin_%d\n", loop - cur);
						 verifyBooleanExpr( $6, "while" );
						 inloop--; 
						fprintf(fpout, "Lexit_%d:\n", loop - cur);
						if(++cur==deep){
							cur  = 0;
							deep =0;
						}
					}
				;


				
for_statement : FOR L_PAREN initial_expression SEMICOLON 
					{loop++;deep++;
						fprintf(fpout, "Lbegin_%d:\n", loop);}
					control_expression SEMICOLON 
					{fprintf(fpout, "\tifeq Lexit_%d\n", loop);
					fprintf(fpout, "\tgoto L2_%d\n", loop );
					fprintf(fpout, "L1_%d:\n", loop);}
					increment_expression R_PAREN  
					{ fprintf(fpout, "\tgoto Lbegin_%d\n", loop );inloop++;
					 fprintf(fpout, "L2_%d:\n", loop);}
					compound_statement  
					{
						fprintf(fpout, "\tgoto L1_%d\n", loop - cur);
						inloop--; 
						fprintf(fpout, "Lexit_%d:\n", loop - cur);
						if(++cur==deep){
							cur  = 0;
							deep =0;
						} 
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
						
					////////////
						struct SymNode * node_ = lookupSymbol( symbolTable, $1->varRef->id, scope, __FALSE );
						if((node_->type->type==DOUBLE_t||node_->type->type==FLOAT_t)&&$3->pType->type==INTEGER_t)
							fprintf(fpout, "\ti2f\n");
						if(node_->scope == 0) {
							fprintf(fpout, "\tputstatic test1/%s ", node_->name);
							print_type(node_);
							fprintf(fpout, "\n" );
						}
						else{
							int stack_ = lookupStack( symbolTable, node_ );
							if(OPT_main == 1) stack_++;
							genstore(node_); 
							fprintf(fpout, "%d\n", stack_);
						}
					///////////
					}
					;
					 
					 
function_invoke_statement : ID L_PAREN logical_expression_list R_PAREN SEMICOLON
							{
								verifyFuncInvoke( $1, $3, symbolTable, scope );
							}
						  | ID L_PAREN R_PAREN SEMICOLON
							{
								verifyFuncInvoke( $1, 0, symbolTable, scope );
							}
						  ;

jump_statement : CONTINUE SEMICOLON
				{
					if( inloop <= 0){
						fprintf( stdout, "########## Error at Line#%d: continue can't appear outside of loop ##########\n", linenum ); semError = __TRUE;
					}
				}
			   | BREAK SEMICOLON 
				{
					if( inloop <= 0){
						fprintf( stdout, "########## Error at Line#%d: break can't appear outside of loop ##########\n", linenum ); semError = __TRUE;
					}
				}
			   | RETURN logical_expression SEMICOLON
				{
					verifyReturnStatement( $2, funcReturn );
				}
			   ;

variable_reference : ID
					{
						
						$$ = createExprSem( $1 );
					}
				   | variable_reference dimension
					{	
						increaseDim( $1, $2 );
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
						fprintf(fpout, "\tior\n");
					}
				   | logical_term { $$ = $1; }
				   ;

logical_term : logical_term AND_OP logical_factor
				{
					verifyAndOrOp( $1, AND_t, $3 );
					$$ = $1;
					fprintf(fpout, "\tiand\n");
				}
			 | logical_factor { $$ = $1; }
			 ;

logical_factor : NOT_OP logical_factor
				{
					verifyUnaryNOT( $2 );
					$$ = $2;
					fprintf(fpout, "\tixor\n");
				}
			   | relation_expression { $$ = $1; }
			   ;

relation_expression : arithmetic_expression relation_operator arithmetic_expression
					{
						SEMTYPE t;
						if( $3->pType->type == INTEGER_t&&($1->pType->type == FLOAT_t||$1->pType->type ==DOUBLE_t))	
							fprintf(fpout, "\ti2f\n");
						t = $1->pType->type;
						verifyRelOp( $1, $2, $3 );
						$$ = $1;
						switch(t){
							case INTEGER_t:
								fprintf(fpout, "\tisub\n");
								break;
							case FLOAT_t:
								fprintf(fpout, "\tfcmpl\n");
								break;
							case DOUBLE_t:
								fprintf(fpout, "\tfcmpl\n");
								break;	
						}
						gencompare ($2,comm);
						comm+=2;
					}
					| arithmetic_expression { $$ = $1; }
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
				if( $3->pType->type == INTEGER_t&&($1->pType->type == FLOAT_t||$1->pType->type ==DOUBLE_t))
					fprintf(fpout, "\ti2f\n");
				verifyArithmeticOp( $1, $2, $3 );
				$$ = $1;
				switch($2){
					case ADD_t:
						if($1->pType->type == INTEGER_t)
							fprintf(fpout, "\tiadd\n");
						else fprintf(fpout, "\tfadd\n");
						break;
					case SUB_t:
						if($1->pType->type == INTEGER_t)
							fprintf(fpout, "\tisub\n");
						else fprintf(fpout, "\tfsub\n");
						break;
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
			if( $3->pType->type == INTEGER_t&&($1->pType->type == FLOAT_t||$1->pType->type ==DOUBLE_t))
				fprintf(fpout, "\ti2f\n");
			if( $2 == MOD_t ) {
				verifyModOp( $1, $3 );
			}
			else {
				verifyArithmeticOp( $1, $2, $3 );
			}
			$$ = $1;

			//imul fmul idiv fdiv
			switch($2){
				case MUL_t:
					if($1->pType->type == INTEGER_t)
						fprintf(fpout, "\timul\n");
					else fprintf(fpout, "\tfmul\n");
					break;
				case DIV_t:
					if($1->pType->type == INTEGER_t)
						fprintf(fpout, "\tidiv\n");
					else fprintf(fpout, "\tfdiv\n");
					break;
				case MOD_t:
					fprintf(fpout, "\tirem\n");
					break;
			}
			
		}
     | factor { $$ = $1; }
	 ;

mul_op 	: MUL_OP { $$ = MUL_t; }
		| DIV_OP { $$ = DIV_t; }
		| MOD_OP { $$ = MOD_t; }
		;
		
factor : variable_reference
		{
			struct SymNode *node_1 = lookupSymbol( symbolTable, $1->varRef->id, scope, __FALSE );
			int stack_ = lookupStack( symbolTable, node_1 );
			genload(node_1,stack_);
			verifyExistence( symbolTable, $1, scope, __FALSE );
			$$ = $1;
			$$->beginningOp = NONE_t;
		}
	   | SUB_OP variable_reference
		{
			if( verifyExistence( symbolTable, $2, scope, __FALSE ) == __TRUE )
			verifyUnaryMinus( $2 );
			$$ = $2;
			$$->beginningOp = SUB_t;

				struct SymNode *node_1 = lookupSymbol( symbolTable, $2->varRef->id, scope, __FALSE );
				int stack_ = lookupStack( symbolTable, node_1 );
				genload(node_1,stack_); 
				switch(node_1->type->type) {
							case INTEGER_t:
								fprintf(fpout,"\tineg\n");
								break;
							case FLOAT_t:
								fprintf(fpout,"\tfneg\n");
								break;
							case DOUBLE_t:
								fprintf(fpout,"\tfneg\n");
								break;
				}
					
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
			switch($3->pType->type) {
							case INTEGER_t:
								fprintf(fpout,"\tineg\n");
								break;
							case FLOAT_t:
								fprintf(fpout,"\tfneg\n");
								break;
							case DOUBLE_t:
								fprintf(fpout,"\tfneg\n");
								break;
				}

		}
	   | ID L_PAREN logical_expression_list R_PAREN
		{
			$$ = verifyFuncInvoke( $1, $3, symbolTable, scope );
			$$->beginningOp = NONE_t;
			struct SymNode * node = lookupSymbol( symbolTable, $1, scope, __FALSE );
			invokfun (node);
		}
	   | SUB_OP ID L_PAREN logical_expression_list R_PAREN
	    {
			$$ = verifyFuncInvoke( $2, $4, symbolTable, scope );
			$$->beginningOp = SUB_t;
			struct SymNode * node = lookupSymbol( symbolTable, $2, scope, __FALSE );
			invokfun (node);

				switch($$->pType->type) {
							case INTEGER_t:
								fprintf(fpout,"\tineg\n");
								break;
							case FLOAT_t:
								fprintf(fpout,"\tfneg\n");
								break;
							case DOUBLE_t:
								fprintf(fpout,"\tfneg\n");
								break;
				}

		}
	   | ID L_PAREN R_PAREN
		{
			$$ = verifyFuncInvoke( $1, 0, symbolTable, scope );
			$$->beginningOp = NONE_t;
			struct SymNode * node = lookupSymbol( symbolTable, $1, scope, __FALSE );
			invokfun (node);
		}
	   | SUB_OP ID L_PAREN R_PAREN
		{
			$$ = verifyFuncInvoke( $2, 0, symbolTable, scope );
			$$->beginningOp = SUB_OP;
			struct SymNode * node = lookupSymbol( symbolTable, $2, scope, __FALSE );
			invokfun (node);
			switch($$->pType->type) {
							case INTEGER_t:
								fprintf(fpout,"\tineg\n");
								break;
							case FLOAT_t:
								fprintf(fpout,"\tfneg\n");
								break;
							case DOUBLE_t:
								fprintf(fpout,"\tfneg\n");
								break;
				}
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
			genlitconst($1); 
		}
	   ;


logical_expression_list : logical_expression_list COMMA logical_expression
						{
			  				struct expr_sem *exprPtr;
			  				for( exprPtr=$1 ; (exprPtr->next)!=0 ; exprPtr=(exprPtr->next) );
			  				exprPtr->next = $3;
			  				$$ = $1;
						}
						| logical_expression { $$ = $1; }
						;

		  


scalar_type : INT { $$ = createPType( INTEGER_t ); }
			| DOUBLE { $$ = createPType( DOUBLE_t ); }
			| STRING { $$ = createPType( STRING_t ); }
			| BOOL { $$ = createPType( BOOLEAN_t ); }
			| FLOAT { $$ = createPType( FLOAT_t ); }
			;
 
literal_const : INT_CONST
				{
					int tmp = $1;
					$$ = createConstAttr( INTEGER_t, &tmp );
				}
			  | SUB_OP INT_CONST
				{
					int tmp = -$2;
					$$ = createConstAttr( INTEGER_t, &tmp );
				}
			  | FLOAT_CONST
				{
					float tmp = $1;
					$$ = createConstAttr( FLOAT_t, &tmp );
				}
			  | SUB_OP FLOAT_CONST
			    {
					float tmp = -$2;
					$$ = createConstAttr( FLOAT_t, &tmp );
				}
			  | SCIENTIFIC
				{
					double tmp = $1;
					$$ = createConstAttr( DOUBLE_t, &tmp );
				}
			  | SUB_OP SCIENTIFIC
				{
					double tmp = -$2;
					$$ = createConstAttr( DOUBLE_t, &tmp );
				}
			  | STR_CONST
				{
					$$ = createConstAttr( STRING_t, $1 );
				}
			  | TRUE
				{
					SEMTYPE tmp = __TRUE;
					$$ = createConstAttr( BOOLEAN_t, &tmp );
				}
			  | FALSE
				{
					SEMTYPE tmp = __FALSE;
					$$ = createConstAttr( BOOLEAN_t, &tmp );
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
}


