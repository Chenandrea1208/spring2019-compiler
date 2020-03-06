#include <stdio.h>
#include <stdlib.h>
#include"datatype.h"
#include"symtable.h"

extern int ERROR_t;
extern int yyparse();
extern FILE* yyin;
extern struct SymTableList *symbolTableList;
extern struct ExpressList *expressList;

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

	symbolTableList = (struct SymTableList*)malloc(sizeof(struct SymTableList));
	expressList = (struct ExpressList*)malloc(sizeof(struct ExpressList));
	expressList->len = 0;
	initSymTableList(symbolTableList);
	AddSymTable(symbolTableList);//global
	yyparse();	/* primary procedure of parser */

	destroySymTableList(symbolTableList);
	if(ERROR_t==1){
	fprintf( stdout, "\n|--------------------------------|\n" );
	fprintf( stdout, "|  There is no syntactic error!  |\n" );
	fprintf( stdout, "|--------------------------------|\n" );}
	else {
		fprintf( stdout, "\n|---------------------------------------------|\n" );
		fprintf( stdout, "|  There is no syntactic and semantic error!  |\n" );
		fprintf( stdout, "|---------------------------------------------|\n" );
	}
	exit(0);
}

