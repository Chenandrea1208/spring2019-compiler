#ifndef _SYMTAB_H_
#define _SYMTAB_H_
#include <stdio.h>
#include <stdlib.h>
#include "header.h"
extern FILE* fpout;
extern int OPT_main;
void initSymTab( struct SymTable *table );
void insertTab( struct SymTable *table, struct SymNode *newNode );
void pushLoopVar( struct SymTable *table, struct SymNode *newNode );
void popLoopVar( struct SymTable *table );
struct SymNode *createLoopVarNode( const char *name );
struct SymNode* createVarNode( const char *name, int scope, struct PType *type );
struct SymNode* createParamNode( const char *name, int scope, struct PType *type );
//struct SymNode* createVarNode( const char *name, int scope, struct PType *type ); 
struct SymNode * createConstNode( const char *name, int scope, struct PType *pType, struct ConstAttr *constAttr );
struct SymNode *createFuncNode( const char *name, int scope, struct PType *pType, struct FuncAttr *params );
//struct SymNode *createProgramNode( const char *name, int scope );
struct SymNode *createProgramNode( const char *name, int scope, struct PType *pType );

struct SymNode *lookupSymbol( struct SymTable *table, const char *id, int scope, __BOOLEAN currentScope );


void deleteSymbol( struct SymNode *symbol );
void deleteScope( struct SymTable *table, int scope );



void printType( struct PType *type, int flag ); 
void dumpSymTable( struct SymTable *table );
void printSymTable( struct SymTable *table, int __scope );

void insertFuncDeclTab( struct SymTable *table, struct SymNode *newNode );

/*new*/
int lookupStack( struct SymTable *table, struct SymNode *node );
void print_fun(struct SymNode *node);
void print_type(struct SymNode * node);
void genload(struct SymNode * node,int stack_);
void genstore(struct SymNode * node);
void genlitconst(struct ConstAttr* a);
void gencompare (OPERATOR op,int num);
void print_type_s(SEMTYPE s);
#endif

