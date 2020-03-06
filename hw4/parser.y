%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include"datatype.h"
#include"symtable.h"

int loop_t = 0;
int return_t = 0;
int parameter_t = 0;
int isFunction = 0;
BTYPE BType;
int array_dim=1;
int ERROR_t = 0;

extern int linenum;
extern FILE	*yyin;
extern char	*yytext;
extern char buf[256];
extern int Opt_SymTable;//declared in lex.l
int scope = 0;//default is 0(global)
struct SymTableList *symbolTableList;//create and initialize in main.c
struct ExtType *funcReturnType;
struct ExpressList *expressList;
%}
%union{
	int 			intVal;
	float 			floatVal;
	double 			doubleVal;
	char			*stringVal;
	char			*idName;
	//struct ExtType 		*extType;
	struct Variable		*variable;
	struct VariableList	*variableList;
	struct ArrayDimNode	*arrayDimNode;
	//struct ConstAttr	*constAttr;
	struct FuncAttrNode	*funcAttrNode;
	//struct FuncAttr		*funcAttr;
	struct Attribute	*attribute;
	struct SymTableNode	*symTableNode;
	//struct SymTable		*symTable;
	struct Express *express;
	struct ExpressList *expresslist;
	BTYPE			bType;
};

%token <idName> ID
%token <intVal> INT_CONST
%token <floatVal> FLOAT_CONST
%token <doubleVal> SCIENTIFIC
%token <stringVal> STR_CONST

%type <variable> array_decl
%type <variableList> identifier_list
%type <arrayDimNode> dim
%type <funcAttrNode> parameter_list
%type <attribute> literal_const 
%type <symTableNode> const_list
%type <bType> scalar_type
%type <intVal> dimension 
%type <express> arithmetic_expression
%type <express> term 
%type <express> factor
%type <express> array_list
%type <express> variable_reference
%type <express> logical_expression
%type <express> relation_expression
%type <express> logical_factor
%type <express> logical_term 


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

	fprintf(stderr, "##########Error at Line %d: %s undeclared.##########\n", linenum,name);
*/
%start program
%%

program :  decl_list funct_def decl_and_def_list
	{
		if(Opt_SymTable == 1)
			printSymTable(symbolTableList->global);
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

funct_def : scalar_type ID L_PAREN R_PAREN 
				{
					funcReturnType = createExtType($1,0,NULL);
					struct SymTableNode *node;
					node = findFuncDeclaration(symbolTableList->global,$2);
					if(node==NULL)//no declaration yet
					{
						struct SymTableNode *newNode = createFunctionNode($2,scope,funcReturnType,NULL);
						insertTableNode(symbolTableList->global,newNode);
					}
					free($2);
					BType = $1;
					isFunction = 1;
					return_t = 1;
				} compound_statement {isFunction = 0;return_t = 0;}
		  | scalar_type ID L_PAREN parameter_list R_PAREN 
			{
					funcReturnType = createExtType($1,0,NULL);
					struct SymTableNode *node;
					node = findFuncDeclaration(symbolTableList->global,$2);
					struct Attribute *attr = createFunctionAttribute($4);
					if(node==NULL)//no declaration yet
					{
						struct SymTableNode *newNode = createFunctionNode($2,scope,funcReturnType,attr);
						insertTableNode(symbolTableList->global,newNode);
					}
					BType = $1;
					isFunction = 1;
					return_t = 1;
			}
			L_BRACE 
			{//enter a new scope
				++scope;
				AddSymTable(symbolTableList);
				//add parameters
				struct FuncAttrNode *attrNode = $4;
				while(attrNode!=NULL)
				{
					struct SymTableNode *newNode = createParameterNode(attrNode->name,scope,attrNode->value);
					insertTableNode(symbolTableList->tail,newNode);
					attrNode = attrNode->next;
				}
			}
			var_const_stmt_list R_BRACE
			{	
				if(Opt_SymTable == 1)
					printSymTable(symbolTableList->tail);
				deleteLastSymTable(symbolTableList);
				--scope;
				free($2);
				isFunction = 0;
				return_t = 0;
			}
		  | VOID ID L_PAREN R_PAREN
		 {
				funcReturnType = createExtType(VOID_t,0,NULL);
				struct SymTableNode *node;
				node = findFuncDeclaration(symbolTableList->global,$2);
				if(node==NULL)//no declaration yet
				{
					struct SymTableNode *newNode = createFunctionNode($2,scope,funcReturnType,NULL);
					insertTableNode(symbolTableList->global,newNode);
				}		
				free($2);
				isFunction = 1;
		}
		  compound_statement  {isFunction = 0;}
		  | VOID ID L_PAREN parameter_list R_PAREN
		{
				funcReturnType = createExtType(VOID_t,0,NULL);
				struct SymTableNode *node;
				node = findFuncDeclaration(symbolTableList->global,$2);
				if(node==NULL)//no declaration yet
				{
					struct Attribute *attr = createFunctionAttribute($4);
					struct SymTableNode *newNode = createFunctionNode($2,scope,funcReturnType,attr);
					insertTableNode(symbolTableList->global,newNode);
				}
				isFunction = 1;
		}
		L_BRACE 
			{//enter a new scope
				++scope;
				AddSymTable(symbolTableList);
			//add parameters
				struct FuncAttrNode *attrNode = $4;
				while(attrNode!=NULL)
				{
					struct SymTableNode *newNode = createParameterNode(attrNode->name,scope,attrNode->value);
					insertTableNode(symbolTableList->tail,newNode);
					attrNode = attrNode->next;
				}
			}
			var_const_stmt_list R_BRACE
			{	
				if(Opt_SymTable == 1)
					printSymTable(symbolTableList->tail);
				deleteLastSymTable(symbolTableList);
				--scope;
				free($2);
				isFunction = 0;
			}
		  ;

funct_decl : scalar_type ID L_PAREN R_PAREN SEMICOLON
		{
			funcReturnType = createExtType($1,0,NULL);
			struct SymTableNode *newNode = createFunctionNode($2,scope,funcReturnType,NULL);
			insertTableNode(symbolTableList->global,newNode);
			free($2);
		}
	 	   | scalar_type ID L_PAREN parameter_list R_PAREN SEMICOLON
		{
			funcReturnType = createExtType($1,0,NULL);
			struct Attribute *attr = createFunctionAttribute($4);
			struct SymTableNode *newNode = createFunctionNode($2,scope,funcReturnType,attr);
			insertTableNode(symbolTableList->global,newNode);
			free($2);
			parameter_t = 0;
		}
		   | VOID ID L_PAREN R_PAREN SEMICOLON
		{
			funcReturnType = createExtType(VOID_t,0,NULL);
			struct SymTableNode *newNode = createFunctionNode($2,scope,funcReturnType,NULL);
			insertTableNode(symbolTableList->global,newNode);
			free($2);
		}
		   | VOID ID L_PAREN parameter_list R_PAREN SEMICOLON
		{
			funcReturnType = createExtType(VOID_t,0,NULL);
			struct Attribute *attr = createFunctionAttribute($4);
			struct SymTableNode *newNode = createFunctionNode($2,scope,funcReturnType,attr);
			insertTableNode(symbolTableList->global,newNode);
			free($2);
			parameter_t = 0;
		}
		   ;

parameter_list : parameter_list COMMA scalar_type ID
		{
			struct FuncAttrNode *newNode = (struct FuncAttrNode*)malloc(sizeof(struct FuncAttrNode));
			newNode->value = createExtType($3,0,NULL);
			newNode->name = strdup($4);
			free($4);
			newNode->next = NULL;
			connectFuncAttrNode($1,newNode);
			parameter_t++;
			$$ = $1;
		}
			   | parameter_list COMMA scalar_type array_decl
		{
			struct FuncAttrNode *newNode = (struct FuncAttrNode*)malloc(sizeof(struct FuncAttrNode));
			newNode->value = $4->type;//use pre-built ExtType(type is unknown)
			newNode->value->baseType = $3;//set correct type
			newNode->name = strdup($4->name);
			newNode->next = NULL;
			free($4->name);
			free($4);
			connectFuncAttrNode($1,newNode);
			parameter_t++;
			$$ = $1;

		}
			   | scalar_type array_decl
		{
			struct FuncAttrNode *newNode = (struct FuncAttrNode*)malloc(sizeof(struct FuncAttrNode));
			newNode->value = $2->type;//use pre-built ExtType(type is unknown)
			newNode->value->baseType = $1;//set correct type
			newNode->name = strdup($2->name);
			newNode->next = NULL;
			free($2->name);
			free($2);
			parameter_t++;
			$$ = newNode;
		}
			   | scalar_type ID
		{
			struct FuncAttrNode *newNode = (struct FuncAttrNode*)malloc(sizeof(struct FuncAttrNode));
			newNode->value = createExtType($1,0,NULL);
			newNode->name = strdup($2);
			free($2);
			newNode->next = NULL;
			$$ = newNode;
			parameter_t++;
		}
		;

var_decl : scalar_type {BType=$1;} identifier_list SEMICOLON
		{
			struct Variable* listNode = $3->head;
			struct SymTableNode *newNode;
			while(listNode!=NULL)
			{
				newNode = createVariableNode(listNode->name,scope,listNode->type);
				newNode->type->baseType = $1;
				insertTableNode(symbolTableList->tail,newNode);
				//printf("wtf");
				listNode = listNode->next;
			}
			deleteVariableList($3);
		}
		 ;

identifier_list : identifier_list COMMA ID
		{
			struct ExtType *type = createExtType(VOID,false,NULL);//type unknown here
			struct Variable *newVariable = createVariable($3,type);
			free($3);
			connectVariableList($1,newVariable);
			$$ = $1;
		}
		| identifier_list COMMA ID ASSIGN_OP logical_expression
		{
			
			struct ExtType *type = createExtType(VOID,false,NULL);//type unknown here
			struct Variable *newVariable = createVariable($3,type);
			free($3);
			connectVariableList($1,newVariable);
			$$ = $1;
			if($5!=NULL){BTYPE type2 = $5->baseType;
						switch(BType)
										{
											case INT_t:
												if(type2!=INT_t){
													ERROR_t=1;
													fprintf(stderr, "##########Error at Line %d: type error.##########\n", linenum);
												}
												break;
											case FLOAT_t:
												if(type2==BOOL_t||type2==STRING_t||type2==DOUBLE_t){
													ERROR_t=1;
													fprintf(stderr, "##########Error at Line %d: type error.##########\n", linenum);
												}
												break;
											case DOUBLE_t:
												if(type2==BOOL_t||type2==STRING_t){
													ERROR_t=1;
													fprintf(stderr, "##########Error at Line %d: type error.##########\n", linenum);
												}
												break;
											case BOOL_t:
												if(type2!=BOOL_t){
													ERROR_t=1;
													fprintf(stderr, "##########Error at Line %d: type error.##########\n", linenum);
												}
												break;
											case STRING_t:
												if(type2!=STRING_t){
													ERROR_t=1;
													fprintf(stderr, "##########Error at Line %d: type error.##########\n", linenum);
												}
												break;
											default:
												break;
										}
			}
		}
		| identifier_list COMMA array_decl ASSIGN_OP initial_array
		{
			connectVariableList($1,$3);
			$$ = $1;
			if(array_dim>=expressList->len) {
				struct Express* exp = expressList->head;
				for(int i=0;i<expressList->len;i++) {
						BTYPE type2 = exp->baseType;
						switch(BType)
							{
								case INT_t:
									if(type2!=INT_t){
										ERROR_t = 1;
										fprintf(stderr, "##########Error at Line %d: type error.##########\n", linenum);
									}
									break;
								case FLOAT_t:
									if(type2==BOOL_t||type2==STRING_t||type2==DOUBLE_t){
										ERROR_t = 1;
										fprintf(stderr, "##########Error at Line %d: type error.##########\n", linenum);
									}
									break;
								case DOUBLE_t:
									if(type2==BOOL_t||type2==STRING_t){
										ERROR_t = 1;
										fprintf(stderr, "##########Error at Line %d: type error.##########\n", linenum);
									}
									break;
								case BOOL_t:
									if(type2!=BOOL_t){
										ERROR_t = 1;
										fprintf(stderr, "##########Error at Line %d: type error.##########\n", linenum);
									}
									break;
								case STRING_t:
									if(type2!=STRING_t){
										ERROR_t = 1;
										fprintf(stderr, "##########Error at Line %d: type error.##########\n", linenum);
									}
									break;
								default:
									break;
							}
					exp=exp->next;
				}
			}
			else {
				ERROR_t = 1;
				fprintf(stderr, "##########Error at Line %d: array size doesn't match.##########\n", linenum);
			}
		}
		| identifier_list COMMA array_decl
		{
			connectVariableList($1,$3);
			$$ = $1;
		}
		| array_decl ASSIGN_OP initial_array
		{
			$$ = createVariableList($1);
			if(array_dim>=expressList->len) {
				struct Express* exp = expressList->head;
				for(int i=0;i<expressList->len;i++) {
						BTYPE type2 = exp->baseType;
						switch(BType)
							{
								case INT_t:
									if(type2!=INT_t){
										ERROR_t = 1;
										fprintf(stderr, "##########Error at Line %d: type error.##########\n", linenum);
									}
									break;
								case FLOAT_t:
									if(type2==BOOL_t||type2==STRING_t||type2==DOUBLE_t){
										ERROR_t = 1;
										fprintf(stderr, "##########Error at Line %d: type error.##########\n", linenum);
									}
									break;
								case DOUBLE_t:
									if(type2==BOOL_t||type2==STRING_t){
										ERROR_t = 1;
										fprintf(stderr, "##########Error at Line %d: type error.##########\n", linenum);
									}
									break;
								case BOOL_t:
									if(type2!=BOOL_t){
										ERROR_t = 1;
										fprintf(stderr, "##########Error at Line %d: type error.##########\n", linenum);
									}
									break;
								case STRING_t:
									if(type2!=STRING_t){
										ERROR_t = 1;
										fprintf(stderr, "##########Error at Line %d: type error.##########\n", linenum);
									}
									break;
								default:
									break;
							}
					exp=exp->next;
				}
			}
			else {
				ERROR_t = 1;
				fprintf(stderr, "##########Error at Line %d: array size doesn't match.##########\n", linenum);
			}
		}
		| array_decl
		{
			$$ = createVariableList($1);
		}
		| ID ASSIGN_OP logical_expression
		{
			
			struct ExtType *type = createExtType(VOID,false,NULL);//type unknown here
			struct Variable *newVariable = createVariable($1,type);
			$$ = createVariableList(newVariable);
			free($1);
			BTYPE type2 = $3->baseType;
			switch(BType)
							{
								case INT_t:
									if(type2!=INT_t){
										ERROR_t = 1;
										fprintf(stderr, "##########Error at Line %d: type error.##########\n", linenum);
									}
									break;
								case FLOAT_t:
									if(type2==BOOL_t||type2==STRING_t||type2==DOUBLE_t){
										ERROR_t = 1;
										fprintf(stderr, "##########Error at Line %d: type error.##########\n", linenum);
									}
									break;
								case DOUBLE_t:
									if(type2==BOOL_t||type2==STRING_t){
										ERROR_t = 1;
										fprintf(stderr, "##########Error at Line %d: type error.##########\n", linenum);
									}
									break;
								case BOOL_t:
									if(type2!=BOOL_t){
										ERROR_t = 1;
										fprintf(stderr, "##########Error at Line %d: type error.##########\n", linenum);
									}
									break;
								case STRING_t:
									if(type2!=STRING_t){
										ERROR_t = 1;
										fprintf(stderr, "##########Error at Line %d: type error.##########\n", linenum);
									}
									break;
								default:
									break;
							}
		}
		| ID
		{
			struct ExtType *type = createExtType(VOID,false,NULL);//type unknown here
			struct Variable *newVariable = createVariable($1,type);
			$$ = createVariableList(newVariable);
			free($1);
		}
		;

initial_array : {	expressList = (struct ExpressList*)malloc(sizeof(struct ExpressList));
					expressList->len = 0;}
				L_BRACE literal_list R_BRACE
			  ;

literal_list : literal_list COMMA logical_expression {insert_expresslist($3,expressList);}
			 | logical_expression{ insert_expresslist($1,expressList); }
             | 
			 ;

const_decl : CONST scalar_type const_list SEMICOLON
	{
		struct SymTableNode *list = $3;//symTableNode base on initailized data type, scalar_type is not used
		while(list!=NULL)
		{    
			if ($2==list->type->baseType
				||(($2==FLOAT_t||$2==DOUBLE_t)&&list->type->baseType==INT_t)
				||($2==FLOAT_t&&list->type->baseType==DOUBLE_t)) {
				list->type->baseType=$2;
				insertTableNode(symbolTableList->tail,list);
			}
			else{
				fprintf( stderr, "##########Error at Line %d: CONST type error.##########\n", linenum);
			}
			list = list->next;
		}
	}
;

const_list : const_list COMMA ID ASSIGN_OP literal_const
		{
			struct ExtType *type = createExtType($5->constVal->type,false,NULL);
			struct SymTableNode *temp = $1;
			while(temp->next!=NULL)
			{
				temp = temp->next;
			}
			temp->next = createConstNode($3,scope,type,$5);	
			free($3);
		}
		   | ID ASSIGN_OP literal_const
                {
			struct ExtType *type = createExtType($3->constVal->type,false,NULL);
			$$ = createConstNode($1,scope,type,$3);	
			free($1);
		}    
		   ;

array_decl : ID {array_dim=1;} dim
	{
		struct ExtType *type = createExtType(VOID,true,$3);//type unknown here
		struct Variable *newVariable = createVariable($1,type);
		free($1);
		$$ = newVariable;
	}
		   ;

dim : dim ML_BRACE INT_CONST MR_BRACE
	{
	  	connectArrayDimNode($1,createArrayDimNode($3));
		$$ = $1;
		array_dim *= $3;
	}
	| ML_BRACE INT_CONST MR_BRACE
	{
		array_dim *= $2;
		$$ = createArrayDimNode($2);
	}
	;

compound_statement : L_BRACE 
			{//enter a new scope
				++scope;
				AddSymTable(symbolTableList);
			}
			var_const_stmt_list R_BRACE
			{	
				if(Opt_SymTable == 1)
					printSymTable(symbolTableList->tail);
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

simple_statement :variable_reference ASSIGN_OP logical_expression SEMICOLON
				{	if($1!=NULL&&$3!=NULL)
					{
						if($1->kind==CONSTANT_t) {
											ERROR_t = 1;
											fprintf(stderr, "##########Error at Line %d: const can't assign.##########\n", linenum);
						}
						else {
											BTYPE type = $1->baseType;
											BTYPE type2 = $3->baseType;
											if($1->isArray){
												ERROR_t = 1;
												fprintf(stderr, "##########Error at Line %d: array can't assign.##########\n", linenum);
											}
											else {
												switch(type)
												{
													case INT_t:
														if(type2!=INT_t){
															ERROR_t = 1;
															fprintf(stderr, "##########Error at Line %d: type error.##########\n", linenum);
														}
														break;
													case FLOAT_t:
														if(type2==BOOL_t||type2==STRING_t||type2==DOUBLE_t){
															ERROR_t = 1;
															fprintf(stderr, "##########Error at Line %d: type error.##########\n", linenum);
														}
														break;
													case DOUBLE_t:
														if(type2==BOOL_t||type2==STRING_t){
															ERROR_t = 1;
															fprintf(stderr, "##########Error at Line %d: type error.##########\n", linenum);
														}
														break;
													case BOOL_t:
														if(type2!=BOOL_t){
															ERROR_t = 1;
															fprintf(stderr, "##########Error at Line %d: type error.##########\n", linenum);
														}
														break;
													case STRING_t:
														ERROR_t = 1;
														fprintf(stderr, "##########Error at Line %d: string value can't assign.##########\n", linenum);
														break;
													default:
														break;
												}
											}
						}
					}
				} 
				 | PRINT logical_expression SEMICOLON 
				 { 
				 	if($2!=NULL&&$2->baseType==OTHER_t){
				 		ERROR_t = 1;
				 		fprintf(stderr, "##########Error at Line %d: print and read statements must be scalar type.##########\n", linenum);
				 	}
				 }
				 | READ variable_reference SEMICOLON
				 { 
				 	if($2!=NULL&&$2->baseType==OTHER_t){
				 		ERROR_t = 1;
				 		fprintf(stderr, "##########Error at Line %d: print and read statements must be scalar type.##########\n", linenum);
				 	}
				 }
				 ;

conditional_statement : IF L_PAREN logical_expression 
			{ 
				if($3!=NULL && $3->baseType!=BOOL_t) {
					ERROR_t = 1;
						fprintf(stderr, "##########Error at Line %d: The conditional expression part of if and while statements must be Boolean types.##########\n", linenum);
					}
			} 
			R_PAREN compound_statement/*logical_expression shouldbebooltype*/
			| IF L_PAREN logical_expression
			{ 
				if($3!=NULL && $3->baseType!=BOOL_t) {
					ERROR_t = 1;
						fprintf(stderr, "##########Error at Line %d: The conditional expression part of if and while statements must be Boolean types.##########\n", linenum);
					}
			}  
			R_PAREN compound_statement ELSE compound_statement
			;
while_statement : WHILE
		{//enter a new scope
			++scope;
			AddSymTable(symbolTableList);
			loop_t = 1;
		}
		L_PAREN logical_expression 			{ 
				if($4!=NULL && $4->baseType!=BOOL_t) {
					ERROR_t = 1;
						fprintf(stderr, "##########Error at Line %d: The conditional expression part of if and while statements must be Boolean types.##########\n", linenum);
					}
			} R_PAREN 
		L_BRACE var_const_stmt_list R_BRACE
		{	
			if(Opt_SymTable == 1)
				printSymTable(symbolTableList->tail);
			deleteLastSymTable(symbolTableList);
			--scope;
			loop_t = 0;
		}
		| DO L_BRACE
		{//enter a new scope
			++scope;
			AddSymTable(symbolTableList);
			loop_t = 1;
		}
		var_const_stmt_list
		 R_BRACE WHILE L_PAREN logical_expression 
		 { 
				if($8!=NULL && $8->baseType!=BOOL_t) {
					ERROR_t = 1;
						fprintf(stderr, "##########Error at Line %d: The conditional expression part of if and while statements must be Boolean types.##########\n", linenum);
					}
		}
			R_PAREN SEMICOLON 
		{
			if(Opt_SymTable == 1)
				printSymTable(symbolTableList->tail);
			deleteLastSymTable(symbolTableList);
			--scope;
			loop_t = 0;
		}
		;

for_statement : FOR
		{//enter a new scope
			++scope;
			AddSymTable(symbolTableList);
			loop_t = 1;
		}
		L_PAREN expression_list SEMICOLON logical_expression 
		{ 
			if($6!=NULL&&$6->baseType!=BOOL_t) {
				ERROR_t = 1;
				fprintf(stderr, "##########Error at Line %d: The conditional expression part of for statements must be Boolean types.##########\n", linenum);
			}
		}
		SEMICOLON expression_list R_PAREN L_BRACE var_const_stmt_list R_BRACE
		{
			if(Opt_SymTable == 1)
				printSymTable(symbolTableList->tail);
			deleteLastSymTable(symbolTableList);
			--scope;
			loop_t = 0;
		}
		;

expression_list :{	expressList = (struct ExpressList*)malloc(sizeof(struct ExpressList));
					expressList->len = 0;
				} expression 
				
				|
				;

expression : expression COMMA variable_reference ASSIGN_OP logical_expression 
				{
					if($3->kind==CONSTANT_t) {
						ERROR_t = 1;
						fprintf(stderr, "##########Error at Line %d: const can't assign.##########\n", linenum);
					}
					else {
						BTYPE type = $3->baseType;
						BTYPE type2 = $5->baseType;
						if($3->isArray){
							ERROR_t = 1;
							fprintf(stderr, "##########Error at Line %d: array can't assign.##########\n", linenum);
						}
						else
							switch(type)
							{
								case INT_t:
									if(type2!=INT_t){
										ERROR_t = 1;
										fprintf(stderr, "##########Error at Line %d: type error.##########\n", linenum);
									}
									break;
								case FLOAT_t:
									if(type2==BOOL_t||type2==STRING_t||type2==DOUBLE_t){
										ERROR_t = 1;
										fprintf(stderr, "##########Error at Line %d: type error.##########\n", linenum);
									}
									break;
								case DOUBLE_t:
									if(type2==BOOL_t||type2==STRING_t){
										ERROR_t = 1;
										fprintf(stderr, "##########Error at Line %d: type error.##########\n", linenum);
									}
									break;
								case BOOL_t:
									if(type2!=BOOL_t){
										ERROR_t = 1;
										fprintf(stderr, "##########Error at Line %d: type error.##########\n", linenum);
									}
									break;
								case STRING_t:
									ERROR_t = 1;
									fprintf(stderr, "##########Error at Line %d: string value can't assign.##########\n", linenum);
									break;
								default:
									break;
							}
					}
					insert_expresslist($3,expressList);

				} 
			| expression COMMA logical_expression { insert_expresslist($3,expressList); }
			| logical_expression { insert_expresslist($1,expressList); }
			| variable_reference ASSIGN_OP logical_expression 
				{
					if($1->kind==CONSTANT_t) {
						ERROR_t = 1;
						fprintf(stderr, "##########Error at Line %d: const can't assign.##########\n", linenum);
					}
					else {
						BTYPE type = $1->baseType;
						BTYPE type2 = $3->baseType;
						if($1->isArray){
							ERROR_t = 1;
							fprintf(stderr, "##########Error at Line %d: array can't assign.##########\n", linenum);
						}
						else
							switch(type)
							{
								case INT_t:
									if(type2!=INT_t){
										ERROR_t = 1;
										fprintf(stderr, "##########Error at Line %d: type error.##########\n", linenum);
									}
									break;
								case FLOAT_t:
									if(type2==BOOL_t||type2==STRING_t||type2==DOUBLE_t){
										ERROR_t = 1;
										fprintf(stderr, "##########Error at Line %d: type error.##########\n", linenum);
									}
									break;
								case DOUBLE_t:
									if(type2==BOOL_t||type2==STRING_t){
										ERROR_t = 1;
										fprintf(stderr, "##########Error at Line %d: type error.##########\n", linenum);
									}
									break;
								case BOOL_t:
									if(type2!=BOOL_t){
										ERROR_t = 1;
										fprintf(stderr, "##########Error at Line %d: type error.##########\n", linenum);
									}
									break;
								case STRING_t:
									ERROR_t = 1;
									fprintf(stderr, "##########Error at Line %d: string value can't assign.##########\n", linenum);
									break;
								default:
									break;
							}
					}
					insert_expresslist($1,expressList);
				} 


function_invoke_statement : ID L_PAREN 
							{	expressList = (struct ExpressList*)malloc(sizeof(struct ExpressList));
								expressList->len = 0;}
							logical_expression_list R_PAREN SEMICOLON
							{
								struct SymTableNode* node;
								node = searchTable_Whenrefer(symbolTableList->tail,$1);
								if(node!=NULL){
									parameter_check(expressList,node);/*not done*/
								}
								free($1);
							}
						  | ID L_PAREN R_PAREN SEMICOLON 
						  	{
						  		struct SymTableNode* node;
								node = searchTable_Whenrefer(symbolTableList->tail,$1);
								if(node!=NULL){
									parameter_check(NULL,node);/*not done*/
								}

						  		free($1);
						  	}
						  ;

jump_statement : CONTINUE SEMICOLON{ 	if(loop_t==0) {
											ERROR_t = 1;
											fprintf(stderr, "##########Error at Line %d: CONTINUE used in loop.##########\n", linenum);
										}
							}
			   | BREAK SEMICOLON { if(loop_t==0){ERROR_t = 1;fprintf(stderr, "##########Error at Line %d: BREAK used in loop.##########\n", linenum);}}
			   | RETURN logical_expression SEMICOLON {
			   	 if(return_t==1) {
			   	 	if($2->isArray) {ERROR_t = 1;fprintf(stderr, "##########Error at Line %d: return type error.##########\n", linenum);}
			   	 	else {
			   	 		BTYPE type2 = $2->baseType;
			   	 		switch(BType)
						{
							case INT_t:
								if(type2!=INT_t){
									ERROR_t = 1;
									fprintf(stderr, "##########Error at Line %d: return type error.##########\n", linenum);
								}
								break;
							case FLOAT_t:
								if(type2==BOOL_t||type2==STRING_t||type2==DOUBLE_t){
									ERROR_t = 1;
									fprintf(stderr, "##########Error at Line %d:return type error.##########\n", linenum);
								}
								break;
							case DOUBLE_t:
								if(type2==BOOL_t||type2==STRING_t){
									ERROR_t = 1;
									fprintf(stderr, "##########Error at Line %d: return type error.##########\n", linenum);
								}
								break;
							case BOOL_t:
								if(type2!=BOOL_t){
									ERROR_t = 1;
									fprintf(stderr, "##########Error at Line %d: return type error.##########\n", linenum);
								}
								break;
							case STRING_t:
								if(type2!=STRING_t){
									ERROR_t = 1;
									fprintf(stderr, "##########Error at Line %d: return type error.##########\n", linenum);
								}
								break;
							default:
								break;
						}
			   	    }
			   	 }
			   	 else {
			   	 	ERROR_t = 1;
			   	 	fprintf(stderr, "##########Error at Line %d: VOID doesn't need return.##########\n", linenum);
			   	 }
			   }
			   ;

variable_reference : array_list {$$ = $1;}
				   | ID
				{
				   	struct SymTableNode* node;
					node = searchTable_Whenrefer(symbolTableList->tail,$1);
					if(node!=NULL){
						struct Express *express = (struct Express*)malloc(sizeof(struct Express));
						express->kind = node->kind;
						express->baseType = node->type->baseType;
						if(node->type->isArray) {
							express->isArray = node->type->isArray;
							express->dim = node->type->dim;
							express->dimArray = node->type->dimArray;
							$$ = express;
						}
						else{
							express->isArray = node->type->isArray;
							express->dim = 0;
							express->dimArray = NULL;
							$$ = express;
						}
					}
					else {	$$ = NULL;
						//fprintf(stderr, "##########Error at Line %d: %s undeclared.##########\n", linenum,$1);
					}
					free($1);
				} 
			   ;

logical_term : logical_term AND_OP logical_factor {
						if($1==NULL||$3==NULL) {$$ = NULL;}
						else if($3->baseType==BOOL_t && $1->baseType==BOOL_t) {
							if($1->isArray||$3->isArray) {
								ERROR_t = 1;
								fprintf(stderr, "##########Error at Line %d: array arithmetic and assignment are not allowed.##########\n", linenum);
								$$ = NULL;
							}
							else {
								//fprintf(stderr, "##########Line %d: correct.##########\n", linenum);
								struct Express *express = (struct Express*)malloc(sizeof(struct Express));
								express->kind = OTHER_t;
								express->baseType = BOOL_t;									
								express->isArray = false;
								express->dim = 0;
								express->dimArray = NULL;
								$$ = express;
							}
						}
						else {
							ERROR_t = 1;
							fprintf(stderr, "##########Error at Line %d: values have not operator [!,||,&&].##########\n", linenum);
							$$ = NULL;
						}	
					}
			 | logical_factor {$$ = $1;}
			 ;

logical_expression : logical_expression OR_OP logical_term
					{
						if($1==NULL||$3==NULL) {$$ = NULL;}
						else if($3->baseType==BOOL_t && $1->baseType==BOOL_t) {
							if($1->isArray||$3->isArray) {
								ERROR_t = 1;
								fprintf(stderr, "##########Error at Line %d: array arithmetic and assignment are not allowed.##########\n", linenum);
								$$ = NULL;
							}
							else {
								//fprintf(stderr, "##########Line %d: correct.##########\n", linenum);
								struct Express *express = (struct Express*)malloc(sizeof(struct Express));
								express->kind = OTHER_t;
								express->baseType = BOOL_t;									
								express->isArray = false;
								express->dim = 0;
								express->dimArray = NULL;
								$$ = express;
							}
						}
						else {
							ERROR_t = 1;
							fprintf(stderr, "##########Error at Line %d: values have not operator [!,||,&&].##########\n", linenum);
							$$ = NULL;
						}	
					}
				   | logical_term {$$ = $1;}
				   ;



logical_factor : NOT_OP logical_factor 
					{
						if($2==NULL) {$$ = NULL;}
						else if($2->baseType==BOOL_t) {
							if($2->isArray) {
								ERROR_t = 1;
								fprintf(stderr, "##########Error at Line %d: array arithmetic and assignment are not allowed.##########\n", linenum);
								$$ = NULL;
							}
							else {
								//fprintf(stderr, "##########Line %d: correct.##########\n", linenum);
								struct Express *express = (struct Express*)malloc(sizeof(struct Express));
								express->kind = OTHER_t;
								express->baseType = BOOL_t;									
								express->isArray = false;
								express->dim = 0;
								express->dimArray = NULL;
								$$ = express;
							}
						}
						else {
							ERROR_t = 1;
							fprintf(stderr, "##########Error at Line %d: values have not operator [!,||,&&].##########\n", linenum);
							$$ = NULL;
						}	
					}
			   | relation_expression {$$ = $1;}
			   ;

relation_expression : arithmetic_expression relation_operator_1 arithmetic_expression 
					{
							if($1==NULL||$3==NULL) {$$ = NULL;}
							else if(($3->baseType==FLOAT_t||$3->baseType==DOUBLE_t||$3->baseType==INT_t)&&($1->baseType==FLOAT_t||$1->baseType==DOUBLE_t||$1->baseType==INT_t)) {
								if($1->isArray||$3->isArray) {
									ERROR_t = 1;
									fprintf(stderr, "##########Error at Line %d: array arithmetic and assignment are not allowed.##########\n", linenum);
									$$ = NULL;
								}
								else {
									//fprintf(stderr, "##########Line %d: correct.##########\n", linenum);
									struct Express *express = (struct Express*)malloc(sizeof(struct Express));
									express->kind = OTHER_t;
									express->baseType = BOOL_t;									
									express->isArray = false;
									express->dim = 0;
									express->dimArray = NULL;
									$$ = express;
								}
							}
							else {
								ERROR_t = 1;
								fprintf(stderr, "##########Error at Line %d: String values,bool values have not operator [>,<,>=,<=].##########\n", linenum);
								$$ = NULL;
							}
						
					}
					| arithmetic_expression relation_operator_2 arithmetic_expression
					{
							if($1==NULL||$3==NULL) {$$ = NULL;}
							else if((($3->baseType==FLOAT_t||$3->baseType==DOUBLE_t||$3->baseType==INT_t)&&($1->baseType==FLOAT_t||$1->baseType==DOUBLE_t||$1->baseType==INT_t))||($3->baseType==BOOL_t && $1->baseType==BOOL_t)) {
								if($1->isArray||$3->isArray) {
									ERROR_t = 1;
									fprintf(stderr, "##########Error at Line %d: array arithmetic and assignment are not allowed.##########\n", linenum);
									$$ = NULL;
								}
								else {
									//fprintf(stderr, "##########Line %d: correct.##########\n", linenum);
									struct Express *express = (struct Express*)malloc(sizeof(struct Express));
									express->kind = OTHER_t;
									express->baseType = BOOL_t;									
									express->isArray = false;
									express->dim = 0;
									express->dimArray = NULL;
									$$ = express;
								}
							}
							else {
								ERROR_t = 1;
								fprintf(stderr, "##########Error at Line %d: String values have not operator [==,!=].##########\n", linenum);
								$$ = NULL;
							}
						
					} 
					| arithmetic_expression {$$ = $1;}
					;

relation_operator_1 : LT_OP //<
				    | LE_OP //<=
				    | GE_OP //>=
				    | GT_OP //>
				    ;
relation_operator_2 :NE_OP //!=
					| EQ_OP //==
				    ;
/*int,float,str...*/
arithmetic_expression : arithmetic_expression ADD_OP term 
		{	if($1==NULL||$3==NULL) {$$ = NULL;}
			else if(($3->baseType==FLOAT_t||$3->baseType==DOUBLE_t||$3->baseType==INT_t)&&($1->baseType==FLOAT_t||$1->baseType==DOUBLE_t||$1->baseType==INT_t)) {
				if($1->isArray||$3->isArray) {
					ERROR_t = 1;
					fprintf(stderr, "##########Error at Line %d: array arithmetic and assignment are not allowed.##########\n", linenum);
					$$ = NULL;
				}
				else {
					//fprintf(stderr, "##########Error at Line %d: correct.##########\n", linenum);
					struct Express *express = (struct Express*)malloc(sizeof(struct Express));
					express->kind = OTHER_t;
					if($3->baseType==DOUBLE_t||$1->baseType==DOUBLE_t)
						express->baseType = DOUBLE_t;
					else if($3->baseType==FLOAT_t||$1->baseType==FLOAT_t)
						express->baseType = FLOAT_t;
					else express->baseType = INT_t;
					express->isArray = false;
					express->dim = 0;
					express->dimArray = NULL;
					$$ = express;
				}
			}
			else {
				ERROR_t = 1;
				fprintf(stderr, "##########Error at Line %d: String values,bool values have not operator [%,*,\\,+,-].##########\n", linenum);
				$$ = NULL;
			}
		}
		   | arithmetic_expression SUB_OP term
		{	if($1==NULL||$3==NULL) {$$ = NULL;}
			else if(($3->baseType==FLOAT_t||$3->baseType==DOUBLE_t||$3->baseType==INT_t)&&($1->baseType==FLOAT_t||$1->baseType==DOUBLE_t||$1->baseType==INT_t)) {
				if($1->isArray||$3->isArray) {
					ERROR_t = 1;
					fprintf(stderr, "##########Error at Line %d: array arithmetic and assignment are not allowed.##########\n", linenum);
					$$ = NULL;
				}
				else {
					//fprintf(stderr, "##########Error at Line %d: correct.##########\n", linenum);
					struct Express *express = (struct Express*)malloc(sizeof(struct Express));
					express->kind = OTHER_t;
					if($3->baseType==DOUBLE_t||$1->baseType==DOUBLE_t)
						express->baseType = DOUBLE_t;
					else if($3->baseType==FLOAT_t||$1->baseType==FLOAT_t)
						express->baseType = FLOAT_t;
					else express->baseType = INT_t;
					express->isArray = false;
					express->dim = 0;
					express->dimArray = NULL;
					$$ = express;
				}
			}
			else {
				ERROR_t = 1;
				fprintf(stderr, "##########Error at Line %d: String values,bool values have not operator [%,*,\\,+,-].##########\n", linenum);
				$$ = NULL;
			}
		}
           | relation_expression {$$ = $1;}
		   | term {$$ = $1;}
		   ;
/*int,float,str...*/
term : term MUL_OP factor 
		{	if($1==NULL||$3==NULL) {$$ = NULL;}
			else if(($3->baseType==FLOAT_t||$3->baseType==DOUBLE_t||$3->baseType==INT_t)&&($1->baseType==FLOAT_t||$1->baseType==DOUBLE_t||$1->baseType==INT_t)) {
				if($1->isArray||$3->isArray) {
					ERROR_t = 1;
					fprintf(stderr, "##########Error at Line %d: array arithmetic and assignment are not allowed.##########\n", linenum);
					$$ = NULL;
				}
				else {
					struct Express *express = (struct Express*)malloc(sizeof(struct Express));
					express->kind = OTHER_t;
					if($3->baseType==DOUBLE_t||$1->baseType==DOUBLE_t)
						express->baseType = DOUBLE_t;
					else if($3->baseType==FLOAT_t||$1->baseType==FLOAT_t)
						express->baseType = FLOAT_t;
					else express->baseType = INT_t;
					express->isArray = false;
					express->dim = 0;
					express->dimArray = NULL;
					$$ = express;
				}
			}
			else {
				ERROR_t = 1;
				fprintf(stderr, "##########Error at Line %d: String values,bool values have not operator [%,*,\\,+,-].##########\n", linenum);
				$$ = NULL;
			}
		}
     | term DIV_OP factor 
     	{	if($1==NULL||$3==NULL) {$$ = NULL;}
			else if(($3->baseType==FLOAT_t||$3->baseType==DOUBLE_t||$3->baseType==INT_t)&&($1->baseType==FLOAT_t||$1->baseType==DOUBLE_t||$1->baseType==INT_t)) {
				if($1->isArray||$3->isArray) {
					ERROR_t = 1;
					fprintf(stderr, "##########Error at Line %d: array arithmetic and assignment are not allowed.##########\n", linenum);
					$$ = NULL;
				}
				else {
					struct Express *express = (struct Express*)malloc(sizeof(struct Express));
					express->kind = OTHER_t;
					if($3->baseType==DOUBLE_t||$1->baseType==DOUBLE_t)
						express->baseType = DOUBLE_t;
					else if($3->baseType==FLOAT_t||$1->baseType==FLOAT_t)
						express->baseType = FLOAT_t;
					else express->baseType = INT_t;
					express->isArray = false;
					express->dim = 0;
					express->dimArray = NULL;
					$$ = express;
				}
			}
			else {
				ERROR_t = 1;
				fprintf(stderr, "##########Error at Line %d: String values,bool values have not operator [%,*,\\,+,-].##########\n", linenum);
				$$ = NULL;
			}
		}
	 | term MOD_OP factor 
		{	if($1==NULL||$3==NULL) {$$ = NULL;}
			else if(($3->baseType==FLOAT_t||$3->baseType==DOUBLE_t||$3->baseType==INT_t)&&($1->baseType==FLOAT_t||$1->baseType==DOUBLE_t||$1->baseType==INT_t)) {
				if($1->isArray||$3->isArray) {
					ERROR_t = 1;
					fprintf(stderr, "##########Error at Line %d: array arithmetic and assignment are not allowed.##########\n", linenum);
					$$ = NULL;
				}
				else {
					struct Express *express = (struct Express*)malloc(sizeof(struct Express));
					express->kind = OTHER_t;
					if($3->baseType==DOUBLE_t||$1->baseType==DOUBLE_t)
						express->baseType = DOUBLE_t;
					else if($3->baseType==FLOAT_t||$1->baseType==FLOAT_t)
						express->baseType = FLOAT_t;
					else express->baseType = INT_t;
					express->isArray = false;
					express->dim = 0;
					express->dimArray = NULL;
					$$ = express;
				}
			}
			else {
				ERROR_t = 1;
				fprintf(stderr, "##########Error at Line %d: String values,bool values have not operator [%,*,\\,+,-].##########\n", linenum);
				$$ = NULL;
			}
		}
	 | factor {$$ = $1;}
	 ;
/*int,float,str...*/
factor : variable_reference {$$ = $1;}
	   | SUB_OP factor 
	    {
			if ($2 == NULL) $$ = $2;
	   		else if($2->baseType==INT_t||$2->baseType==FLOAT_t||$2->baseType==DOUBLE_t) $$ = $2;
	   		else {
	   			ERROR_t = 1;
	   			fprintf(stderr, "##########Error at Line %d: can't use -.##########\n", linenum);
	   			$$ = NULL;
	   		}
	   	}
	   | L_PAREN logical_expression R_PAREN {$$ = $2;}
	   | ID L_PAREN 
	   {expressList = (struct ExpressList*)malloc(sizeof(struct ExpressList));
		expressList->len = 0;}
		logical_expression_list R_PAREN
	{
		struct SymTableNode* node;
		node = searchTable_Whenrefer(symbolTableList->tail,$1);
		if (node == NULL) $$ = NULL;
		else if(node->kind!=FUNCTION_t){
			ERROR_t = 1;
			fprintf(stderr, "##########Error at Line %d: %s is not function.##########\n", linenum,node->name);
			$$= NULL;
		}
		else{//if atrtr correct
			struct Express *express = (struct Express*)malloc(sizeof(struct Express));
			express->kind = OTHER_t;
			express->baseType = node->type->baseType;
			express->isArray = false;
			express->dim = 0;
			express->dimArray = NULL;
			$$ = express;
		}
		free($1);
	}//function
	   | ID L_PAREN R_PAREN
	{
		struct SymTableNode* node;
		node = searchTable_Whenrefer(symbolTableList->tail,$1);
		if (node == NULL) $$ = NULL;
		else if(node->kind!=FUNCTION_t){
			ERROR_t = 1;
			fprintf(stderr, "##########Error at Line %d: %s is not function.##########\n", linenum,node->name);
			$$ = NULL;
		}
		else{//if atrtr correct
			struct Express *express = (struct Express*)malloc(sizeof(struct Express));
			express->kind = OTHER_t;
			express->baseType = node->type->baseType;
			express->isArray = false;
			express->dim = 0;
			express->dimArray = NULL;
			$$ = express;
		}
		free($1);
	}	   //function
	   | literal_const /*int,float,str...*/
	    {
			struct Express *express = (struct Express*)malloc(sizeof(struct Express));
			express->kind = OTHER_t;
			express->baseType = $1->constVal->type;
			express->isArray = false;
			express->dim = 0;//Array type dimension
			express->dimArray = NULL;
			$$ = express;
			killAttribute($1);
	    }
	   ;

logical_expression_list : logical_expression_list COMMA logical_expression {insert_expresslist($3,expressList);}
						| logical_expression {insert_expresslist($1,expressList);}
						;

array_list : ID dimension	
			{
				struct SymTableNode* node;
				node = searchTable_Whenrefer(symbolTableList->tail,$1);
				if(node!=NULL){
					if(node->type->isArray){
					struct Express *express = (struct Express*)malloc(sizeof(struct Express));
					express->kind = node->kind;
					express->baseType = node->type->baseType;
					if($2 == node->type->dim) {
						express->isArray = false;
						express->dim = 0;
						express->dimArray = NULL;
						$$ = express;
					}
					else if($2 > node->type->dim) {
						ERROR_t = 1;
						$$ = NULL;
						fprintf(stderr, "##########Error at Line %d: dimension error.##########\n", linenum);
					}
					else {
						express->isArray = TRUE;
						express->dim = node->type->dim - $2;
						express->dimArray = node->type->dimArray;
						for(int i = 0; i < $2; i++) {
							express->dimArray = express->dimArray->next;
						}
						$$ = express;
					}
					}
					else{
						ERROR_t = 1;
						fprintf(stderr, "##########Error at Line %d: %s is not array.##########\n", linenum,node->name);
						$$ = NULL;
					}
				}
				free($1);
			}
		   ;

dimension : dimension ML_BRACE logical_expression MR_BRACE {$$ = $1+1;}		   
		  | ML_BRACE logical_expression MR_BRACE {$$ = 1;}
		  ;



scalar_type : INT
		{
			$$ = INT_t;
		}
		| DOUBLE
		{
			$$ = DOUBLE_t;
		}
		| STRING
		{
			$$ = STRING_t;
		}
		| BOOL
		{
			$$ = BOOL_t;
		}
		| FLOAT
		{
			$$ = FLOAT_t;
		}
		;
 
literal_const : INT_CONST
		{
			int val = $1;
			$$ = createConstantAttribute(INT_t,&val);		
		}
			  | SUB_OP INT_CONST
		{
			int val = -$2;
			$$ = createConstantAttribute(INT_t,&val);
		}
			  | FLOAT_CONST
		{
			float val = $1;
			$$ = createConstantAttribute(FLOAT_t,&val);
		}
			  | SUB_OP FLOAT_CONST
		{
			float val = -$2;
			$$ = createConstantAttribute(FLOAT_t,&val);
		}
			  | SCIENTIFIC
		{
			double val = $1;
			$$ = createConstantAttribute(DOUBLE_t,&val);
		}
			  | SUB_OP SCIENTIFIC
		{
			double val = -$2;
			$$ = createConstantAttribute(DOUBLE_t,&val);
		}
			  | STR_CONST
		{
			$$ = createConstantAttribute(STRING_t,$1);
			free($1);
		}
			  | TRUE
		{
			bool val = true;
			$$ = createConstantAttribute(BOOL_t,&val);
		}
			  | FALSE
		{
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


