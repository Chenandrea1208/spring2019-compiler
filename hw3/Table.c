#include "Table.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

Dimension* create_dim() {
	Dimension* tmp = (Dimension*) malloc(sizeof(Dimension));
	tmp->length = -1;
	tmp->next = NULL;
	//for debug
	//printf("create_dim\n");
	return tmp;
}

Idlist* create_idlist() {
	Idlist* tmp= (Idlist*) malloc(sizeof(Idlist));
    tmp->now = NULL;
    tmp->attribute =NULL;
    tmp->next = NULL;
	return tmp;
}

void insert_dim(Dimension* dim, int size) {
	//printf("%d\n", size);
	//printf("%d\n", *op_first);
	if(dim->next == NULL && dim->length == -1){
		dim->length = size;
		dim->next = NULL;
		//printf("insert_dim-1,%d\n", dim->length);
	}
	else{
		Dimension* tmp = dim;
		while(tmp->next != NULL){
			tmp = tmp->next;
		}
		tmp->next = (Dimension*) malloc(sizeof(Dimension));
		tmp->next->length = size;
		tmp->next->next = NULL;
		//printf("insert_dim-2,%d\n", tmp->next->length);
	}
	//for debug
	//printf("insert_dim,%d\n", size);
}

Id* insert_create_id(char* n,Dimension* dim) {	
	Id* temp = (Id*) malloc(sizeof(Id));
 	strcpy(temp->idname,n);
 	if(dim->length == -1)
 	    temp->dimension = NULL;
 	else
 		temp->dimension = dim;
 	return temp;
}

Idlist* insert_chartoidlist(char* name, Idlist* current_list, char* a) {	
	if(current_list->now==NULL){
		//Idlist* tmp = (Idlist*) malloc(sizeof(Idlist));
		current_list->now = (Id*) malloc(sizeof(Id));
		strcpy(current_list->now->idname,name);
		current_list->now->dimension = NULL;
		//create attribute
		if(a!=NULL){
			current_list->attribute = (Attribute*) malloc(sizeof(Attribute));
			strcpy(current_list->attribute->char_value, a);
			current_list->attribute->fun_par = NULL;
			//printf("create_attribute-1 : %s %s \n", a,current_list->attribute->char_value);
		}
		else current_list->attribute = NULL;

		current_list->next = NULL;
		//printf("enter insert_idlist-1, %s\n",current_list->now->idname);
		return current_list;
	}
	else{
		Idlist* head = current_list;
		while(head->next!=NULL)
			head = head->next;
		Idlist* tmp = (Idlist*) malloc(sizeof(Idlist));
		tmp->now = (Id*) malloc(sizeof(Id));
		strcpy(tmp->now->idname,name);
		//create attribute
		if(a!=NULL){
			tmp->attribute = (Attribute*) malloc(sizeof(Attribute));
			strcpy(tmp->attribute->char_value, a);
			tmp->attribute->fun_par = NULL;
			//printf("create_attribute-2 : %s %s \n", a,tmp->attribute->char_value);
		}
		else tmp->attribute = NULL;
		tmp->next = NULL;
		head->next =tmp;
		//printf("enter insert_idlist-2, %s\n",head->next->now->idname);
		return tmp;
	}
}

Idlist* insert_idlist(Id* id, Idlist* current_list) {	
	if(current_list->now==NULL){
		//Idlist* tmp = (Idlist*) malloc(sizeof(Idlist));
		current_list->now = id;
		current_list->attribute = NULL;
		current_list->next = NULL;
		//printf("enter insert_idlist-1, %s\n",current_list->now->idname);
		return current_list;
	}
	else{
		Idlist* head = current_list;
		while(head->next!=NULL)
			head = head->next;
		head->next = (Idlist*) malloc(sizeof(Idlist));
		head->next->now = id;
		head->next->attribute = NULL;
		head->next->next = NULL;
		//printf("enter insert_idlist-2, %s\n",head->next->now->idname);
		return head->next;
	}
}

SymbolTable* create_root_table() {
	SymbolTable *temp = (SymbolTable *)malloc(sizeof(SymbolTable));
	temp->parent = NULL;
	temp->level = 0;
	temp->first = NULL;
	//printf("create root_table\n");
	return temp;
}

SymbolTable* create_table( SymbolTable* current ) {
	SymbolTable *temp = (SymbolTable *)malloc(sizeof(SymbolTable));
	temp->parent = current;
	temp->level = current->level+1;
	temp->first = NULL;
	//printf("create table\n");
	return temp;
}

void insert_idlist_to_table( char* k, char* t,Idlist* cur_list, SymbolTable* cur_table) {
	
	if(cur_list->now==NULL)
		return;
	Symbol* tmp_symbol = cur_table->first;
	int l = cur_table->level;
	Idlist* tmp = cur_list;
	
	if(tmp_symbol==NULL) {//first
		cur_table->first = create_symbol_withIdlist(tmp, k, t, l);
		tmp_symbol = cur_table->first;
		//printf("%-10s attribute-1: %s\n", cur_table->first->name, Str_attribute(cur_table->first->attribute));
		tmp = tmp->next;
	}
	while(tmp_symbol->next!= NULL)
		tmp_symbol = tmp_symbol->next;
		
	while(tmp!=NULL){
		tmp_symbol->next = create_symbol_withIdlist(tmp, k, t, l);
		//printf("%-10s attribute-2: %s\n", tmp_symbol->next->name, Str_attribute(tmp_symbol->next->attribute));
		tmp_symbol = tmp_symbol->next;
		tmp = tmp->next;
	}
	
}

Symbol* create_symbol_withIdlist(Idlist* id, char* k, char* t,int l) {
	Symbol* tmp = (Symbol*) malloc(sizeof(Symbol));
	
	strcpy( tmp->name, id->now->idname);
	strcpy(tmp->kind, k);// variable function constant parameter
	tmp->level = l;
	strcpy(tmp->typename, t);
	tmp->dimension = id->now->dimension;
	tmp->attribute = id->attribute;
	//printf("%s\n", Str_attribute( tmp->attribute));
	tmp->next = NULL;
}

Typelist* create_typelist() {
	Typelist* tmp = (Typelist*) malloc(sizeof(Typelist));	
	tmp->idname[0]='\0';
	tmp->next = NULL;
	return tmp;
}

void insert_typelist(char* n, char* t, Dimension* d,Typelist* cur_typelist) {
	if(cur_typelist->idname[0]=='\0'){
		strcpy(cur_typelist->idname, n);
		strcpy(cur_typelist->typename, t);
		cur_typelist->dimension = d;
		cur_typelist->next = NULL;
	}
	else {
		Typelist* head = cur_typelist;
		while(head->next!=NULL)
			head = head->next;
		head->next = (Typelist*) malloc(sizeof(Typelist));
		strcpy(head->next->idname, n);
		strcpy(head->next->typename, t);
		head->next->dimension = d;
		head->next->next = NULL;
	}
}

void insert_typelist_to_table( char* k, Typelist* cur_list, SymbolTable* cur_table) {
	Symbol* tmp_symbol = cur_table->first;
	int l = cur_table->level;
	if(tmp_symbol!=NULL){
		while(tmp_symbol->next!= NULL){
				tmp_symbol = tmp_symbol->next;
			}
	}
	if(cur_list->idname[0]=='\0')
		return;
	else{
		Typelist* tmp = cur_list;
		//first symbol
		if(tmp_symbol==NULL) {
			cur_table->first = create_symbol_withtypelist(tmp, k, l);
			tmp_symbol = cur_table->first;
			tmp = tmp->next;
		}
		//
		while(tmp!=NULL){
			tmp_symbol->next = create_symbol_withtypelist(tmp, k, l);
			tmp_symbol = tmp_symbol->next;
			tmp = tmp->next;
		}
	}
}

Symbol* create_symbol_withtypelist(Typelist* typelist, char* k,int l) {
	Symbol* tmp = (Symbol*) malloc(sizeof(Symbol));
	strcpy( tmp->name, typelist->idname);
	strcpy( tmp->kind, k);// variable function constant parameter
	tmp->level = l;
	tmp->dimension = typelist->dimension;
	//for debug
 	//printf("%s:", tmp->name);
 	//Dimension* temp = tmp->dimension;
 	//while(temp!=NULL){
 	//	printf(" %d", temp->length);
 	//	temp=temp->next;
 	//}printf("\n");
 	//
	strcpy(tmp->typename, typelist->typename);
	tmp->next = NULL;
}

void insert_func_to_table( char* n, char* k, char* t,Typelist* par_list, SymbolTable* cur_table) {
	Symbol* tmp_symbol = cur_table->first;
	int l = cur_table->level;
	if(tmp_symbol!=NULL){
		while(tmp_symbol->next!= NULL){
				tmp_symbol = tmp_symbol->next;
			}
	}
	//first symbol
	if(tmp_symbol==NULL) {
		cur_table->first = (Symbol*) malloc(sizeof(Symbol));
		strcpy(cur_table->first->name, n);
		strcpy(cur_table->first->kind, k);
		cur_table->first->level = l;
		strcpy(cur_table->first->typename, t);
		if(par_list==NULL) cur_table->first->attribute = NULL;
		else {
			cur_table->first->attribute = (Attribute*) malloc(sizeof(Attribute));
			cur_table->first->attribute->fun_par = par_list;
		}	
	}
	//tmp_symbol->next
	else{
		tmp_symbol->next = (Symbol*) malloc(sizeof(Symbol));
		strcpy(tmp_symbol->next->name, n);
		strcpy(tmp_symbol->next->kind, k);
		tmp_symbol->next->level = l;
		strcpy(tmp_symbol->next->typename, t);
		if(par_list==NULL) tmp_symbol->next->attribute = NULL;
		else {
			tmp_symbol->next->attribute = (Attribute*) malloc(sizeof(Attribute));
			tmp_symbol->next->attribute->fun_par = par_list;
		}	
	}
}

/*t*/

char* Str_type(	char* t, Dimension* dim)
{
	char* str_type = (char*) malloc(sizeof(char)*32);
	strcpy(str_type, t);
	Dimension* temp = dim;
	while(temp!=NULL){
		char buf[10];
		sprintf(buf, "[%d]", temp->length);
		//printf("Str_type : [%d]", temp->length);
		strcat(str_type, buf);
		temp=temp->next;
	}
	return str_type;
}

char* Str_level(int n)
{
	char* str_level = (char*) malloc(sizeof(char)*12);
	if(n == 0)
		sprintf(str_level, "%d(global)", n);
	else
		sprintf(str_level, "%d(local)", n);
	return str_level;
}
/**********************************************/

char* Str_attribute(Attribute* temp)
{	
	//char* str_attribute = (char*) malloc(sizeof(char)*32);
	if (temp==NULL) {
		//printf("attribute t1\n");
		char* str = strdup("");
		return str;
	}
	else if(temp->fun_par==NULL){
		char* str = strdup(temp->char_value);
		return str;
	}
	else {
		char* str_attribute = (char*) malloc(sizeof(char)*32);
		Typelist* tmp_typelist = temp->fun_par;
		strcpy(str_attribute, Str_type(tmp_typelist->typename,tmp_typelist->dimension));
		tmp_typelist=tmp_typelist->next;
		//strcpy(str_attribute, tmp_typelist->typename);
		while(tmp_typelist!=NULL){
			char str_temp[32];
			strcpy(str_temp , Str_type(tmp_typelist->typename,tmp_typelist->dimension));
			strcat(str_attribute, ",");
			strcat(str_attribute, str_temp);
			tmp_typelist=tmp_typelist->next;
		}
		return str_attribute;
	}
	
}
/**********************************************/
void test_table(SymbolTable* cur_table){
	if(cur_table->first==NULL);// printf("faill\n");
	else{
		//printf("level : %d\n", cur_table->level);
		printf("=======================================================================================\n");
		//printf("%-33s%-11s%-12s%-19s%-24s\n", "Name", "Kind", "Level", "Type", "Attribute");
		printf("%-10s%-11s%-12s%-19s%-24s\n", "Name", "Kind", "Level", "Type", "Attribute");
		printf("---------------------------------------------------------------------------------------\n");	
		Symbol* head = cur_table->first;
		while(head!=NULL){
			printf("%-10s%-11s%-12s",head->name, head->kind,Str_level(head->level));
			printf("%-19s%-24s\n",Str_type(head->typename,head->dimension), Str_attribute(head->attribute));
			head = head->next;
		}
		printf("=======================================================================================\n");
	}
}

void test_typelist(Typelist* cur_list){

	if(cur_list->idname[0]=='\0') printf("faill\n");
	else{
		printf("/**newlist**/\n");
		Typelist* head = cur_list;
		while(head!=NULL){
			printf("parameter : %-10s %-10s\n",head->idname, head->typename);
			head = head->next;
		}
	}
}

void test_idlist(Idlist* cur_list){
	if(cur_list->now == NULL) printf("faill\n");
	else{
		printf("/**newidlist**/\n");
		Idlist* head = cur_list;
		while(head!=NULL){
			printf("Idlist : %-10s %-10s\n",head->now->idname, Str_attribute(head->attribute));
			head = head->next;
		}
	}
}

void test_dim(Dimension* dim){
	//for debug
 	//printf("%s:", temp->idname);
 	Dimension* tmp = dim;
 	while(tmp!=NULL){
 		printf("[%d]", tmp->length);
 		tmp=tmp->next;
 	}printf("\n");
 	//
}

/**/
/*##########Error at Line #N: ERROR MESSAGE.##########*/
int detect_error(char* n,SymbolTable* cur_table){
	//SymbolTable* temp = cur_table;
	if(cur_table==NULL) return 0;
	Symbol* tmp = cur_table->first;
	if(tmp == NULL) return 0;
	else{
		while(tmp->next!=NULL) {
			if(!strcmp(n,tmp->name)) return 1;
			tmp = tmp->next;
		}
		if(!strcmp(n,tmp->name)) return 1;
		return 0;
		//return detect_error(n,cur_table->parent);
	}
}

int parameter_detect_error(char* n,Typelist* cur_list){
	//SymbolTable* temp = cur_table;
	Typelist* tmp = cur_list;
	if(cur_list==NULL) return 0;
	else{
		while(tmp->next!=NULL) {
			if(!strcmp(n,tmp->idname)) return 1;
			tmp = tmp->next;
		}
		if(!strcmp(n,tmp->idname)) return 1;
		return 0;
		//return detect_error(n,cur_table->parent);
	}
}







