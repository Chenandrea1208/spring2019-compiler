
#include "header.h"
#include "symtab.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>


void initSymTab( struct SymTable *table )
{	int i;
	for( i=0 ; i<HASHBUNCH ; ++i ){
		table->entry[i] = NULL;		
	}
}


void insertTab( struct SymTable *table, struct SymNode *newNode )
{
	int location = 0;

	if( table->entry[location] == 0 ) {	// the first
		table->entry[location] = newNode;
	} 
	else {
		struct SymNode *nodePtr;
		for( nodePtr=table->entry[location] ; (nodePtr->next)!=0 ; nodePtr=nodePtr->next );
		nodePtr->next = newNode;
		newNode->prev = nodePtr;
	}
}

struct SymNode* createVarNode( const char *name, int scope, struct PType *type ) 
{
	struct SymNode *newNode = (struct SymNode *)malloc( sizeof(struct SymNode) );
	/* setup name */
	newNode->name = (char *)malloc(sizeof(char)*(strlen(name)+1));
	strcpy( newNode->name, name );
	/* setup scope */
	newNode->scope = scope;
	/* setup type */
	newNode->type = type;
	/* Category: variable */
	newNode->category = VARIABLE_t;
	/* without attribute */
	newNode->attribute = 0;

	newNode->next = 0;
	newNode->prev = 0;

	return newNode;
}

struct SymNode* createParamNode( const char *name, int scope, struct PType *type )
{
	struct SymNode *newNode = (struct SymNode *)malloc( sizeof(struct SymNode) );
	/* setup name */
	newNode->name = (char *)malloc(sizeof(char)*(strlen(name)+1));
	strcpy( newNode->name, name );
	/* setup scope */
	newNode->scope = scope;
	/* setup type */
	newNode->type = type;
	/* Category: parameter */
	newNode->category = PARAMETER_t;
	/* without attribute */
	newNode->attribute = 0;

	newNode->next = 0;
	newNode->prev = 0;

	return newNode;	
}

struct SymNode * createConstNode( const char *name, int scope, struct PType *pType, struct ConstAttr *constAttr )
{
	struct SymNode *newNode = (struct SymNode *)malloc( sizeof(struct SymNode) );
	// setup name /
	newNode->name = (char *)malloc(sizeof(char)*(strlen(name)+1));
	strcpy( newNode->name, name );
	//* setup scope /
	newNode->scope = scope;
	//* setup type /
	newNode->type = pType;
	//* Category: constant /
	newNode->category = CONSTANT_t;
	//* setup attribute /
	newNode->attribute = (union SymAttr*)malloc(sizeof(union SymAttr));
	newNode->attribute->constVal = constAttr;

	newNode->next = 0;
	newNode->prev = 0;

	return newNode;
}

struct SymNode *createFuncNode( const char *name, int scope, struct PType *pType, struct FuncAttr *params )
{
	struct SymNode *newNode = (struct SymNode *)malloc( sizeof(struct SymNode) );
	// setup name /
	newNode->name = (char *)malloc(sizeof(char)*(strlen(name)+1));
	strcpy( newNode->name, name );
	//* setup scope /
	newNode->scope = scope;
	//* setup type /
	newNode->type = pType;
	//* Category: constant /
	newNode->category = FUNCTION_t;
	//* setup attribute /
	newNode->attribute = (union SymAttr*)malloc(sizeof(union SymAttr));
	newNode->attribute->formalParam = params;

	newNode->next = 0;
	newNode->prev = 0;

	return newNode;
}

/**
 * __BOOLEAN currentScope: true: only search current scope
 */

struct SymNode *lookupSymbol( struct SymTable *table, const char *id, int scope, __BOOLEAN currentScope )
{
	int index = 0;
	int num = 0;
	struct SymNode *nodePtr, *result=0;
	nodePtr=table->entry[0];
	for( nodePtr=(table->entry[index]) ; nodePtr!=0 ; nodePtr=(nodePtr->next) ) {
		num++;
		if( !strcmp(nodePtr->name,id) && ((nodePtr->scope)==scope) ) { 
			return nodePtr;
		}
	}
	// not found...
	if( scope == 0 )	return 0;	// null
	else {
		if( currentScope == __TRUE ) {
			return 0;
		}
		else {
			return lookupSymbol( table, id, scope-1, __FALSE );
		}
	}
}
/*new*/
int lookupStack( struct SymTable *table, struct SymNode *node ) {
	int index = 0;
	int num = -1;
	struct SymNode *nodePtr, *result=0;
	nodePtr=table->entry[0];
	for( nodePtr=(table->entry[index]) ; nodePtr!=0 ; nodePtr=(nodePtr->next) ) {
		if(nodePtr->scope!=0 && nodePtr->category!=CONSTANT_t) num++;
		if( !strcmp(nodePtr->name,node->name) && ((nodePtr->scope)==node->scope) ) { 
			return num;
		}
	}
	if(1) return -1;
}

void print_fun(struct SymNode *node) { /*not done*/
	
	if(strcmp(node->name,"main")!=0) {
		OPT_main = 0;
		fprintf(fpout, ".method public static %s(",node->name);
		int i = node->attribute->formalParam->paramNum;
		struct PTypeList* list =  node->attribute->formalParam->params;
		for(int ii = 0; ii<i; ii++){
			print_type_s(list->value->type);
			list = list ->next;
		}
		if(i==0) fprintf(fpout, "V");
	}
	else {
		OPT_main = 1;
		fprintf(fpout, ".method public static main([Ljava/lang/String;");
	}
	fprintf(fpout,")");
	print_type_s(node->type->type);
	fprintf(fpout,"\n");
	////////////////////////////////////////////

	//fprintf(fpout, ".limit stack 100\n.limit locals 100%s\n" );
/*.method public static main([Ljava/lang/String;)V*/
	fprintf(fpout,".limit stack 100\n.limit locals 100\n\tnew java/util/Scanner\n");
	fprintf(fpout,"\tdup\n\tgetstatic java/lang/System/in Ljava/io/InputStream;\n");
	fprintf(fpout,"\tinvokespecial java/util/Scanner/<init>(Ljava/io/InputStream;)V\n");
	fprintf(fpout, "\tputstatic test1/_sc Ljava/util/Scanner;\n" );
}
void print_type_s(SEMTYPE s) {
	switch(s) {
		case INTEGER_t:
			fprintf(fpout,"I");
			break;
		case BOOLEAN_t:
			fprintf(fpout,"Z");
			break;
		case FLOAT_t:
			fprintf(fpout,"F");
			break;
		case DOUBLE_t:
			fprintf(fpout,"D");
			break;
		case STRING_t:
			fprintf(fpout,"Ljava/lang/String;");	
			break;
		case VOID_t:
			fprintf(fpout,"V");
			break;	
	}
}

void print_type(struct SymNode * node) {
	switch(node->type->type) {
		case INTEGER_t:
			fprintf(fpout,"I");
			break;
		case BOOLEAN_t:
			fprintf(fpout,"Z");
			break;
		case FLOAT_t:
			fprintf(fpout,"F");
			break;
		case DOUBLE_t:
			fprintf(fpout,"D");
			break;
		case STRING_t:
			fprintf(fpout,"Ljava/lang/String;");	
			break;
	}
}
void genload(struct SymNode * node,int stack_) {
	if(node->category==VARIABLE_t||node->category==PARAMETER_t) {
		if(node->scope == 0) {
			fprintf(fpout, "\tgetstatic test1/%s ", node->name);
			print_type(node);
			fprintf(fpout, "\n" );
		}
		else{
			
			switch(node->type->type) {
				case INTEGER_t:
					fprintf(fpout,"\tiload ");
					break;
				case BOOLEAN_t:
					fprintf(fpout,"\tiload ");
					break;
				case FLOAT_t:
					fprintf(fpout,"\tfload ");
					break;
				case DOUBLE_t:
					fprintf(fpout,"\tfload ");
					break;
			}
			if(OPT_main == 1) stack_++;
			fprintf(fpout, "%d\n", stack_);
		}
	}
	else if(node->category==CONSTANT_t){
		switch(node->type->type) {
				case INTEGER_t:
					fprintf(fpout,"\tldc ");
					break;
				case BOOLEAN_t:
					fprintf(fpout,"\ticonst_");
					break;
				case FLOAT_t:
					fprintf(fpout,"\tldc ");
					break;
				case DOUBLE_t:
					fprintf(fpout,"\tldc ");
					break;
		}
		struct ConstAttr* p = node->attribute->constVal;
		switch(p->category) {
			case INTEGER_t:
				fprintf(fpout,"%d\n",p->value.integerVal);
				break;
			case BOOLEAN_t:
				if(p->value.booleanVal == __TRUE)
					fprintf(fpout,"1\n");
				else
					fprintf(fpout,"0\n");
				break;
			case FLOAT_t:
				fprintf(fpout,"%f\n",p->value.floatVal);
				break;
			case DOUBLE_t:
				fprintf(fpout,"%f\n",p->value.doubleVal);
				break;
		}
	}
	
}
void genstore(struct SymNode * node) {
	switch(node->type->type) {
		case INTEGER_t:
			fprintf(fpout,"\tistore ");
			break;
		case BOOLEAN_t:
			fprintf(fpout,"\tistore ");
			break;
		case FLOAT_t:
			fprintf(fpout,"\tfstore ");
			break;
		case DOUBLE_t:
			fprintf(fpout,"\tfstore ");
			break;
	}
}
void genlitconst(struct ConstAttr* a)
{
	switch(a->category) {
		case INTEGER_t:
			if(a->hasMinus == __TRUE)fprintf(fpout,"\tldc -%d",a->value.integerVal);
			else fprintf(fpout,"\tldc %d",a->value.integerVal);
			break;
		case BOOLEAN_t:
			if(a->value.booleanVal == __TRUE)
				fprintf(fpout,"\ticonst_1");
			else
				fprintf(fpout,"\ticonst_0");
			break;
		case FLOAT_t:
			if(a->hasMinus == __TRUE)fprintf(fpout,"ldc -%f",a->value.floatVal);
			else fprintf(fpout,"\tldc %f",a->value.floatVal);
			break;
		case DOUBLE_t:
			if(a->hasMinus == __TRUE)fprintf(fpout,"ldc -%f",a->value.doubleVal);
			else fprintf(fpout,"\tldc %f",a->value.doubleVal);
			break;
		case STRING_t:
			fprintf(fpout,"\tldc \"%s\"",a->value.stringVal);
			break;	
	}
	fprintf(fpout,"\n");
}
void gencompare (OPERATOR op,int num)
{
	switch(op){
		case LT_t:
			fprintf(fpout,"\tiflt ");
			break;
		case LE_t:
			fprintf(fpout,"\tifle ");
			break;
		case EQ_t:
			fprintf(fpout,"\tifeq ");
			break;
		case GE_t:
			fprintf(fpout,"\tifge ");
			break;
		case GT_t:
			fprintf(fpout,"\tifgt ");
			break;	
		case NE_t:
			fprintf(fpout,"\tifne ");
			break;												
	}
	fprintf(fpout,"L%d\n",num+1);
	fprintf(fpout,"\ticonst_0\n");
	fprintf(fpout,"\tgoto L%d\n",num+2);
	fprintf(fpout,"L%d:\n",num+1);
	fprintf(fpout,"\ticonst_1\n");
	fprintf(fpout,"L%d:\n",num+2);
}
void invokfun (struct SymNode * node) {
	fprintf(fpout, "invokestatic test1/%s(",node->name);
		int i = node->attribute->formalParam->paramNum;
		struct PTypeList* list =  node->attribute->formalParam->params;
		for(int ii = 0; ii<i; ii++){
			print_type_s(list->value->type);
			list = list ->next;
		}
		if(i==0) fprintf(fpout, "V");
	fprintf(fpout,")");
	print_type_s(node->type->type);
	fprintf(fpout,"\n");
}
/*end*/
void deleteSymbol( struct SymNode *symbol )
{
	// delete name
	if( symbol->name != 0 )
		free( symbol->name );
	// delete PType
	deletePType( symbol->type );
	// delete SymAttr, according to category
	deleteSymAttr( symbol->attribute, symbol->category );
	//
	symbol->next = 0;
	symbol->prev = 0;

	free( symbol );
}

void deleteScope( struct SymTable *table, int scope )
{
	int i;

	//struct SymNode *collectList = 0;

	struct SymNode *current, *previous;
	for( i=0 ; i<HASHBUNCH ; ++i ) {
		if( table->entry[i] == 0 ) {	// no element in this list
			continue;
		}
		else if( table->entry[i]->next == 0 ) {	// only one element in this list
			if( table->entry[i]->scope == scope ) {
				//deleteSymbol( table->entry[i] );
				table->entry[i] = 0;
			}
		}
		else {
			for( previous=(table->entry[i]), current=(table->entry[i]->next) ; current!=0 ; previous=current, current=(current->next) ) {
				if( previous->scope == scope ) {
					if( previous->prev == 0 ) {
						previous->next->prev = 0;
						table->entry[i] = current;
						//deleteSymbol( previous );
					}
					else {
						previous->prev->next = current;
						current->prev = previous->prev;
						//deleteSymbol( previous );
					}
				}
			}
			if( previous->scope == scope ) {
				//previous->prev->next = 0;
				if( previous->prev == 0 ) {
					table->entry[0] = 0;
					//deleteSymbol( previous );
				}
				else {
					previous->prev->next = 0;
					//deleteSymbol( previous );

				}
			}

		}
	}
}
/**
 * if flag == 1, invoked at symbol table dump
 */ 
void printType( struct PType *type, int flag )
{
	char buffer[50];
	memset( buffer, 0, sizeof(buffer) );
	struct PType *pType = type;

	switch( pType->type ) {
	 case INTEGER_t:
	 	sprintf(buffer, "int");
		break;
	 case FLOAT_t:
	 	sprintf(buffer, "float");
		break;
	case DOUBLE_t:
	 	sprintf(buffer, "double");
		break;
	 case BOOLEAN_t:
	 	sprintf(buffer, "bool");
		break;
	 case STRING_t:
	 	sprintf(buffer, "string");
		break;
	 case VOID_t:
	 	sprintf(buffer, "void");
		break;
	}

	int i;
	struct ArrayDimNode *ptrr;
	for( i=0, ptrr=pType->dim ; i<(pType->dimNum) ; i++,ptrr=(ptrr->next) ) {
		char buf[15];
		memset( buf, 0, sizeof(buf) );
		sprintf( buf, "[%d]", ptrr->size );
		strcat( buffer, buf  );
	}
	if( flag == 1 )
		printf("%-19s", buffer);
	else
		printf("%s",buffer );
}

void printSymTable( struct SymTable *table, int __scope )
{
	printf("=======================================================================================\n");
	// Name [29 blanks] Kind [7 blanks] Level [7 blank] Type [15 blanks] Attribute [15 blanks]
	printf("Name                             Kind       Level       Type               Attribute               \n");
	printf("---------------------------------------------------------------------------------------\n");
	int i;
	struct SymNode *ptr;
	for( i=0 ; i<HASHBUNCH ; i++ ) {
		for( ptr=(table->entry[i]) ; ptr!=0 ; ptr=(ptr->next) ) {
			if( ptr->scope == __scope ) {
				printf("%-32s ", ptr->name);

				switch( ptr->category ) {
				 case VARIABLE_t:
					printf("variable  ");
					break;
			 	 case CONSTANT_t:
			 		printf("constant  ");
					break;				 
				 case FUNCTION_t:
				 	printf("function  ");
					break;
				 case PARAMETER_t:
				 	printf("parameter ");
					break;
				}

				if( ptr->scope == 0 ) {
					printf("%2d(global)   ", ptr->scope);
				}
				else {
					printf("%2d(local)    ", ptr->scope);
				}

				printType( ptr->type, 1 );
			
				if( ptr->category == FUNCTION_t ) {
					int i;
					struct PTypeList *pTypePtr;
					for( i=0, pTypePtr=(ptr->attribute->formalParam->params) ; i<(ptr->attribute->formalParam->paramNum) ; i++, pTypePtr=(pTypePtr->next) ) {
						printType( pTypePtr->value, 0 );
						if(i < ptr->attribute->formalParam->paramNum-1)
							printf(",");
					}
				}
				else if( ptr->category == CONSTANT_t ) {
					switch( ptr->attribute->constVal->category ) {
					 case INTEGER_t:
						printf("%d",ptr->attribute->constVal->value.integerVal);
						break;
					 case FLOAT_t:
					 	printf("%lf",ptr->attribute->constVal->value.floatVal);
						break;
					case DOUBLE_t:
					 	printf("%lf",ptr->attribute->constVal->value.doubleVal);
						break;
					 case BOOLEAN_t:
					 	if( ptr->attribute->constVal->value.booleanVal == __TRUE ) 
							printf("true");
						else
							printf("false");
						break;
					 case STRING_t:
					 	printf("%s",ptr->attribute->constVal->value.stringVal);
						break;
					}
				}

				printf("\n");
			}	// if( ptr->scope == __scope )
		}	// for( ptr=(table->entry[i]) ; ptr!=0 ; ptr=(ptr->next) )
	}	// for( i=0 ; i<HASHBUNCH ; i++ )
	printf("======================================================================================\n");

}

