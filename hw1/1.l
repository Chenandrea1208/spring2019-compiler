%{
#define LIST                { strncat(buf, yytext, sizeof(buf) - strlen(buf) - 1); }
#define token(t)            { LIST; if (Opt_Token) printf("<\"%s\">\n", t); }
#define tokenString(t, s)   { LIST; if (Opt_Token) printf("<%s:%s>\n", t, s); }
#define MAX_LINE_LENGTH 257
#define MAX_ID_LENGTH 257
int Opt_Source = 1;
int Opt_Token = 1;
int Opt_Statistic = 1;
int linenum = 1;
char buf[MAX_LINE_LENGTH];
char str[MAX_LINE_LENGTH];

struct id{
  char name[MAX_ID_LENGTH];
  int  times;
  struct id* next;
};
struct id* first = NULL;
struct id* current = NULL;

void id_create(char*);
void id_find(char*);

%}

digit      [0-9]
letter     [a-zA-Z_]
keyword    ("while"|"do"|"if"|"else"|"true"|"false"|"for"|"int"|"print"|"const"|"read"|"boolean"|"bool"|"void"|"float"|"double"|"string"|"continue"|"break"|"return")
id         {letter}({letter}|{digit})*
delimiter  [\(\)\[\]\{\},;]
integer    (0|([1-9]{digit}*)) 
float      {digit}+\.{digit}+
scientific ({float}|{integer})[Ee][\+\-]?{digit}+
OP         ("+"|"-"|"*"|"/"|"%"|"="|"<"|"<="|"!="|">="|">"|"=="|"&&"|"||"|"!")
space      [ \t]+
zspace     [ \t]*

%x COMMENT 
%x PRAGMA
%x SOURCE 
%x TOKEN 
%x STATISTIC
%x STRING 

%%

{delimiter}  { tokenString("delim", yytext); }
{keyword}    { tokenString("KW", yytext); }
{id}         { tokenString("id",yytext);id_find(yytext);}
{float}      { tokenString("float",yytext); }
{integer}    { tokenString("integer",yytext); }
{scientific} { tokenString("scientific",yytext); }
{OP}         { token(yytext); }
{space}      { LIST;}

    /***string***/

\" {
  LIST;
  str[0]='\0'; 
  BEGIN STRING;
}
<STRING>\" {
  tokenString("string", str); 
  BEGIN 0;
}
<STRING>\\\" { LIST;strncat(str, "\"", sizeof(buf) - strlen(buf) - 1); }
<STRING>\\\\ { LIST;strncat(str, "\\", sizeof(buf) - strlen(buf) - 1); }
<STRING>. {
  LIST;
  strncat(str, yytext, sizeof(buf) - strlen(buf) - 1); 
}
<STRING>\n { 
    fprintf(stderr, "Error at line %d: %s\n", linenum, yytext);
    exit(1);
}
    /***comment***/

"//"(.)*$ {LIST;}

"/*" {
  LIST; 
  BEGIN COMMENT;
}
<COMMENT>"*/" { LIST; BEGIN 0;}
<COMMENT>"\n" {
  LIST;
  if (Opt_Source)
    printf("%d:%s\n", linenum, buf);
  ++linenum;
  buf[0] = '\0';
}
<COMMENT>.    { LIST;}
    /***programa***/
^"#pragma"{space} {
  LIST;
  BEGIN PRAGMA;
}
<PRAGMA>"source"{space} {
  LIST;
  BEGIN SOURCE;
}
<PRAGMA>"token"{space} {
  LIST;
  BEGIN TOKEN;
}
<PRAGMA>"statistic"{space} {
  LIST;
  BEGIN STATISTIC;
}
    /***source***/
<SOURCE>"on"{zspace}"/*" {
  LIST;
  Opt_Source = 1;
  BEGIN COMMENT;
}
<SOURCE>"off"{zspace}"/*" {
  LIST;
  Opt_Source = 0;
  BEGIN COMMENT;
}
<SOURCE>"on"{zspace}"//"(.)*$ {
  LIST;
  Opt_Source = 1;
  BEGIN 0;
}
<SOURCE>"off"{zspace}"//"(.)*$ {
  LIST;
  Opt_Source = 0;
  BEGIN 0;
}
<SOURCE>"on"{zspace}\n {
  LIST;
  Opt_Source = 1;
      if (Opt_Source)
        printf("%d:%s\n", linenum, buf);
    ++linenum;
    buf[0] = '\0';
  BEGIN 0;
}
<SOURCE>"off"{zspace}\n {
  LIST;
  Opt_Source = 0;
      if (Opt_Source)
        printf("%d:%s\n", linenum, buf);
    ++linenum;
    buf[0] = '\0';
  BEGIN 0;
}
<SOURCE>. {
  fprintf(stderr, "Error at line %d: %s\n", linenum, yytext);
  exit(1);
}
    /***token***/
<TOKEN>"on"{zspace}"/*" {
  LIST;
  Opt_Token = 1;
  BEGIN COMMENT;
}
<TOKEN>"off"{zspace}"/*" {
  LIST;
  Opt_Token = 0;
  BEGIN COMMENT;
}
<TOKEN>"on"{zspace}"//"(.)*$ {
  LIST;
  Opt_Token = 1;
  BEGIN 0;
}
<TOKEN>"off"{zspace}"//"(.)*$ {
  LIST;
  Opt_Token = 0;
  BEGIN 0;
}
<TOKEN>"on"{zspace}\n {
  LIST;
  Opt_Token = 1;
      if (Opt_Source)
        printf("%d:%s\n", linenum, buf);
    ++linenum;
    buf[0] = '\0';
  BEGIN 0;
}
<TOKEN>"off"{zspace}\n {
  LIST;
  Opt_Token = 0;
      if (Opt_Source)
        printf("%d:%s\n", linenum, buf);
    ++linenum;
    buf[0] = '\0';
  BEGIN 0;
}
<TOKEN>. {
  fprintf(stderr, "Error at line %d: %s\n", linenum, yytext);
  exit(1);
}
    /***statistic***/
<STATISTIC>"on"{zspace}"/*" {
  LIST;
  Opt_Statistic = 1;
  BEGIN COMMENT;
}
<STATISTIC>"off"{zspace}"/*" {
  LIST;
  Opt_Statistic = 0;
  BEGIN COMMENT;
}
<STATISTIC>"on"{zspace}"//"(.)*$ {
  LIST;
  Opt_Statistic = 1;
  BEGIN 0;
}
<STATISTIC>"off"{zspace}"//"(.)*$ {
  LIST;
  Opt_Statistic = 0;
  BEGIN 0;
}
<STATISTIC>"on"{zspace}\n {
  LIST;
  Opt_Statistic = 1;
      if (Opt_Source)
        printf("%d:%s\n", linenum, buf);
    ++linenum;
    buf[0] = '\0';
  BEGIN 0;
}
<STATISTIC>"off"{zspace}\n {
  LIST;
  Opt_Statistic = 0;
      if (Opt_Source)
        printf("%d:%s\n", linenum, buf);
    ++linenum;
    buf[0] = '\0';
  BEGIN 0;
}
<STATISTIC>. {
  fprintf(stderr, "Error at line %d: %s\n", linenum, yytext);
  exit(1);
}
    /***\n&.***/
"\n" {
    LIST;
    if (Opt_Source)
        printf("%d:%s\n", linenum, buf);
    ++linenum;
    buf[0] = '\0';
}

. { // Unrecognized character
    fprintf(stderr, "Error at line %d: %s\n", linenum, yytext);
    exit(1);
}

%%

void id_create(char* name){
    struct id* i = malloc(sizeof(struct id));
    strcpy(i->name,name);
    i->times = 1;
    i->next = NULL;
    if(current != NULL){
        current->next = i;
        current = i;
    }
    else{
        current = i;
        first = i;
    }
    return;
}

void id_find(char*name){
    if(Opt_Statistic==1){
      struct id* i=first;
      for(;i!=NULL;i=i->next){
        if(strcmp(i->name, name)==0){
            i->times++;
            return;
        }
      }
      id_create(name);
    }
    return;
}


int main( int argc, char **argv )
{
    if (argc >= 2)
    {
        yyin = fopen( argv[1], "r" );
        if ( NULL == yyin ) {
            fprintf( stderr, "Cannot open: %s\n", argv[1] );
            exit(-1);
        }
    }
    else
    {
        yyin = stdin;
    }

    yylex();

    if (Opt_Statistic)
    {
        printf("frequencies of identifiers:\n");
        struct id* i=first;
 	    for(;i!=NULL;i=i->next){
        	printf("%-s     %d\n",i->name,i->times);        
    	}
    }

    exit(0);
}
