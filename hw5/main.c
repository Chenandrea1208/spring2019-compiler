#include <stdio.h>
#include <stdlib.h>
#include "header.h"
#include "symtab.h"

extern int yyparse();
extern FILE* yyin;

extern struct SymTable *symbolTable;
extern struct PType *funcReturn;
extern char fileName[256];
extern FILE *fpout;

extern __BOOLEAN semError; 

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
	fpout = fopen("output.j", "w");
	if( fpout == NULL )  {
	    fprintf( stdout, "Open  file  error\n" );
	    exit(-1);
	}
	symbolTable = (struct SymTable *)malloc(sizeof(struct SymTable));
	initSymTab( symbolTable );

	
	// initial function return recoder
	fprintf(fpout,".class public test1\n.super java/lang/Object\n.field public static _sc Ljava/util/Scanner;\n" );
	yyparse();	/* primary procedure of parser */

	if(semError == __TRUE){	
		fprintf( stdout, "\n|--------------------------------|\n" );
		fprintf( stdout, "|  There is no syntactic error!  |\n" );
		fprintf( stdout, "|--------------------------------|\n" );
	}
	else{
		fprintf( stdout, "\n|-------------------------------------------|\n" );
		fprintf( stdout, "| There is no syntactic and semantic error! |\n" );
		fprintf( stdout, "|-------------------------------------------|\n" );
	}

	exit(0);
}

