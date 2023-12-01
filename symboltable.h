#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <limits.h>
#include <string.h>

#define HASH_TABLE_SIZE 100
#define MAX_SCOPE 8

int table_index = 0;
int current_scope = 0;
extern int yylineno; 

struct table_skeleton
{
	char* token;
	double value;
	int data_type;
	int* parameter_list; 
	int array_dimension;
	int is_constant;
	int num_params;
	int line_no;
	struct table_skeleton* next;
};

typedef struct table_skeleton table_entry;

struct table_s
{
	table_entry** symbol_table;
	int parent;
};

typedef struct table_s table_t;

extern table_t symbol_table_list[MAX_SCOPE];

table_entry** create_table()
{
	table_entry** hash_table_ptr = NULL; 

	if((hash_table_ptr = malloc(sizeof(table_entry*)*HASH_TABLE_SIZE)) == NULL)
    	return NULL;

	int i;
    for(i = 0; i < HASH_TABLE_SIZE; i++){
    	hash_table_ptr[i] = NULL;
    }
	return hash_table_ptr;
}

int create_new_scope()
{
	table_index++;
	symbol_table_list[table_index].symbol_table = create_table();
	symbol_table_list[table_index].parent = current_scope;

	return table_index;
}

int exit_scope()
{
	return symbol_table_list[current_scope].parent;
}

uint32_t hash(char *token){
	size_t i = 0;
	uint32_t hash;
	for (hash = 0; i < strlen(token); ++i){
        hash += token[i];
        hash += (hash << 10);
        hash ^= (hash >> 6);
    }
	hash += (hash << 3);
	hash ^= (hash >> 11);
    hash += (hash << 15);
	return hash % HASH_TABLE_SIZE; 
}

table_entry *create_entry( char *token, int value, int data_type){
	table_entry *new_entry;
	if((new_entry = malloc( sizeof( table_entry ) ) ) == NULL ) {
		return NULL;
	}
	if((new_entry->token = strdup(token)) == NULL){
		return NULL;
	}

	new_entry->value = value;
	new_entry->next = NULL;
	new_entry->parameter_list = NULL;
	new_entry->array_dimension = -1;
	new_entry->is_constant = 0;
	new_entry->num_params = 0;
	new_entry->data_type = data_type;
	new_entry->line_no = yylineno;
	return new_entry;
}

table_entry* search(table_entry** hash_table_ptr, char* token)
{
	uint32_t idx = 0;
	table_entry* myentry;

	idx = hash(token);

	myentry = hash_table_ptr[idx];

	while( myentry != NULL && strcmp( token, myentry->token) != 0)
		myentry = myentry->next;

	return myentry;

}

table_entry* rec_search(char* token)
{
	int idx = current_scope;
	table_entry* finder = NULL;

	while(idx != -1)
	{
		finder = search(symbol_table_list[idx].symbol_table, token);
		if(finder != NULL)
			return finder;

		idx = symbol_table_list[idx].parent;
	}
	return finder;
}

table_entry* insert( table_entry** hash_table_ptr, char* token, int value, int data_type)
{

	table_entry* finder = search( hash_table_ptr, token );
	if( finder != NULL)
	{
		if(finder->is_constant)
			return finder;
		return NULL;
	}

	uint32_t idx;
	table_entry* new_entry = NULL;
	table_entry* head = NULL;

	idx = hash( token ); 
	new_entry = create_entry( token, value, data_type ); 

	if(new_entry == NULL) 
	{
		printf("Insert failed. New entry could not be created.");
		exit(1);
	}

	head = hash_table_ptr[idx];

	if(head == NULL) 
	{
		hash_table_ptr[idx] = new_entry;
	}
	else 
	{
		new_entry->next = hash_table_ptr[idx];
		hash_table_ptr[idx] = new_entry;
	}
	return hash_table_ptr[idx];
}

int check_parameter_list(table_entry* entry, int* list, int m)
{
	int* parameter_list = entry->parameter_list;

	if(m != entry->num_params)
	{
		yyerror("Number of parameters and arguments do not match");
	}

	int i;
	for(i=0; i<m; i++)
	{
		if(list[i] != parameter_list[i])
		yyerror("Parameter and argument types do not match");
	}

	return 1;
}

void fill_parameter_list(table_entry* entry, int* list, int n)
{
	entry->parameter_list = (int *)malloc(n*sizeof(int));

	int i;
	for(i=0; i<n; i++)
	{
		entry->parameter_list[i] = list[i];
	}
	entry->num_params = n;
}


void print_dashes(int n)
{
  printf("\n");

	int i;
	for(i=0; i<n; i++)
		printf("-");                         
	printf("\n");
}


char *display_datatype(int data_type){
	switch(data_type){
		case 277 : return "short";
		case 278 : return "int";
		case 279 : return "long";
		case 280 : return "long long";
		case 284 : return "void";
		case 285 : return "char";
		case 286 : return "float";
		case 287 : return "double";
	}
	return "Unknown";
}

void display_symbol_table()
{

	int scope,i;
	print_dashes(140);	
	printf(" %-20s %-20s %-20s %-20s %-20s %-20s %-20s \n","Line Number","Token name","Data Type","Scope Level","Array Dimension","Num of params","Param List");  
	print_dashes(140);

	for(scope=0; scope<=table_index; scope++){
		table_entry** hash_table_ptr = symbol_table_list[scope].symbol_table;

	table_entry* node;

		for(i=0; i < HASH_TABLE_SIZE; i++)
		{
			node = hash_table_ptr[i];
			while( node != NULL)
			{
				printf(" %-20d", node->line_no);
				
				printf(" %-20s %-20s %-20d", node->token, display_datatype(node->data_type), scope);
				if(node->array_dimension==-1)
				printf(" %-20s","N/A");
				else
				printf(" %-20d",node->array_dimension);

				printf(" %-20d", node->num_params);
				if(node->num_params == 0){
					printf("      - \n");
				}
				else{
					int j;
					for(j=0; j < node->num_params; j++)
					printf(" %s",display_datatype(node->parameter_list[j]));
					printf("\n");
				}
				node = node->next;
			}
		}

	}
	print_dashes(140);


}

void display_constant_table(table_entry** hash_table_ptr)
{

	int i;
	table_entry* node;
	print_dashes(55);
	printf(" %-20s %-20s %-20s \n","Line No","Constant","Data Type");
	print_dashes(55);

	for( i=0; i < HASH_TABLE_SIZE; i++)
	{
		node = hash_table_ptr[i];
		while( node != NULL)
		{
			printf(" %-20d %-20s %-20s \n", node->line_no, node->token, display_datatype(node->data_type));
			node = node->next;
		}
	}
	print_dashes(55);
}
