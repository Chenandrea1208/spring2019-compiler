
typedef struct Symbol Symbol;
typedef struct SymbolTable SymbolTable;
typedef struct Attribute Attribute;
typedef struct Id Id;
typedef struct Typelist Typelist;
typedef struct Dimension Dimension;
typedef struct ArrayConst ArrayConst;
typedef struct Idlist Idlist;

struct Idlist
{
	Id* now;
	Attribute* attribute;
	Idlist* next;
};

struct Symbol{
	char name[64];
	char kind[16];// variable function constant parameter
	int level;
	char typename[16];
	Dimension* dimension; 
	Attribute* attribute;
	Symbol* next;
};

struct SymbolTable
{
	SymbolTable* parent;
	int level;
	Symbol* first;
};

struct Attribute
{
	Typelist* fun_par;
	int int_value;
	double d_value;
	char char_value[32];
};

struct Id
{
	char idname[64];
	Dimension* dimension;
};

struct Typelist
{
	char idname[64];
	char typename[16];
	Dimension* dimension;
	Typelist* next;
};

struct Dimension
{
	int length;
	Dimension* next;
};

Idlist* create_idlist();
Dimension* create_dim();
void insert_dim(Dimension* dim, int size);
Id* insert_create_id(char* n,Dimension* dim);
Idlist* insert_idlist(Id* id, Idlist* current_list);
Idlist* insert_chartoidlist(char* name, Idlist* current_list, char* a);
void insert_idlist_to_table( char* k, char* t,Idlist* cur_list, SymbolTable* cur_table);
SymbolTable* create_root_table();
SymbolTable* create_table( SymbolTable* current );
Symbol* create_symbol_withIdlist(Idlist* id, char* k, char* t,int l);
Typelist* create_typelist();
void insert_typelist(char* n, char* t, Dimension* d,Typelist* cur_typelist);
void insert_typelist_to_table( char* k, Typelist* cur_list, SymbolTable* cur_table);
Symbol* create_symbol_withtypelist(Typelist* typelist, char* k,int l);
void insert_func_to_table( char* n, char* k, char* t,Typelist* par_list, SymbolTable* cur_table);
int detect_error(char* n,SymbolTable* cur_table);
/*t*/
char* Str_type(	char* t, Dimension* dim);
char* Str_attribute(Attribute* temp);
char* Str_level(int n);
void test_table(SymbolTable* cur_table);
void test_typelist(Typelist* cur_list);
void test_dim(Dimension* dim);
void test_idlist(Idlist* cur_list);
int parameter_detect_error(char* n,Typelist* cur_list);