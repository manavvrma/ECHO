%{
#include <stdlib.h>
#include <stdio.h>

#include "symboltable.h"
#include "lex.yy.c"

int yyerror(char *msg);
extern table_entry** constant_table;

int cur_dtype;

table_t symbol_table_list[MAX_SCOPE];

int is_declaration = 0, is_loop = 0, is_func = 0, func_type, p_idx = 0, p=0, rhs = 0;
extern int yylinno;
int param_list[10];

void type_check(int,int,int);

%}

%union
{
	int data_type;
	table_entry* entry;
}

%type <entry> identifier
%type <entry> constant
%type <entry> array_index
%type <data_type> sub_expr
%type <data_type> unary_expr
%type <data_type> arithmetic_expr
%type <data_type> assignment_expr
%type <data_type> function_call
%type <data_type> array_access
%type <data_type> lhs

%token <entry> IDENTIFIER
%token <entry> DEC_CONSTANT HEX_CONSTANT CHAR_CONSTANT FLOAT_CONSTANT
%token STRING
%token LOGICAL_AND LOGICAL_OR LS_EQ GR_EQ EQ NOT_EQ
%token MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN ADD_ASSIGN SUB_ASSIGN
%token INCREMENT DECREMENT
%token SHORT NUMBER LENGTHY VERY_LENGTHY NEGATIVE POSITIVE CONST ECHO CHARACTER DECIMAL PRECISION
%token CONDITION LOOP WHILST RESUME INTERRUPT RESULT

%left ','
%right '='
%left LOGICAL_OR
%left LOGICAL_AND
%left EQ NOT_EQ
%left '<' '>' LS_EQ GR_EQ
%left '+' '-'
%left '*' '/' '%'
%right '!'

%nonassoc UMINUS
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

starter: starter builder
	| builder
	;

builder: function
	| declaration
	;


function: type
	  identifier 		{	func_type = cur_dtype;		is_declaration = 0;	current_scope = create_new_scope();	}
	'(' argument_list ')' 	{	is_declaration = 0;	fill_parameter_list($2,param_list,p_idx);	p_idx = 0;	is_func = 1;	p=1;	}
	compound_stmt		{	is_func = 0;	}
        ;

type : data_type pointer     {is_declaration = 1; }
     | data_type     {is_declaration = 1; }
     ;

pointer: '*' pointer
       | '*'
       ;

data_type : sign_specifier type_specifier
	  | type_specifier
    	  ;

sign_specifier : NEGATIVE
    	  | POSITIVE
    	  ;

type_specifier :NUMBER                    {cur_dtype = NUMBER;}
		|SHORT NUMBER              {cur_dtype = SHORT;}
		|SHORT                 {cur_dtype = SHORT;}
		|LENGTHY                 {cur_dtype = LENGTHY;}
		|LENGTHY NUMBER 	       {cur_dtype = LENGTHY;}
		|VERY_LENGTHY             {cur_dtype = VERY_LENGTHY;}
		|VERY_LENGTHY NUMBER          {cur_dtype = VERY_LENGTHY;}
		|CHARACTER			{cur_dtype = CHARACTER;}
		|DECIMAL 			{cur_dtype = DECIMAL;}
		|PRECISION		{cur_dtype = PRECISION;}
		|ECHO			{cur_dtype = ECHO;}
		;

argument_list : arguments
    	      |
    	      ;

arguments : arguments ',' arg
    	  | arg
    	  ;


arg : type identifier			{	param_list[p_idx++] = $2->data_type;	}
    ;

stmt:compound_stmt
    |single_stmt
    ;

compound_stmt :
		'{' 			{	if(!p)current_scope = create_new_scope();	else p = 0;	}
		statements
		'}' 			{	current_scope = exit_scope();	}
    ;

statements:statements stmt
    |
    ;

single_stmt :if_block
    |for_block
    |while_block
    |declaration
    |function_call ';'
    |RESULT ';'				{	if(is_func){
							if(func_type != ECHO)
								yyerror("RESULT type (ECHO) does not match function type");
						}
						else yyerror("RESULT statement not inside function definition");
					}

	|RESUME ';'							 {if(!is_loop) {yyerror("Illegal use of RESUME");}}
	|INTERRUPT ';'                 {if(!is_loop) {yyerror("Illegal use of INTERRUPT");}}
	|RESULT sub_expr ';'			 {	if(is_func){
								if(func_type != $2)
									yyerror("RESULT type does not match function type");
							}
							else yyerror("RESULT statement not in function definition");
						 }
	;

for_block:LOOP '(' expression_stmt  expression_stmt ')' {is_loop = 1;} stmt {is_loop = 0;}
    	|LOOP '(' expression_stmt expression_stmt expression ')' {is_loop = 1;} stmt {is_loop = 0;}
    	;

if_block: CONDITION '(' expression ')' stmt 				%prec LOWER_THAN_ELSE
	| CONDITION '(' expression ')' stmt ELSE stmt
	; 

while_block: WHILST '(' expression	')' {is_loop = 1;} stmt {is_loop = 0;}
		;

declaration: type  declaration_list ';'
		   {is_declaration = 0; }
	| declaration_list ';'
	| unary_expr ';'


declaration_list: declaration_list ',' sub_decl
		|sub_decl
		;

sub_decl: assignment_expr
    		|identifier
    		|array_access
				;

expression_stmt: expression ';'
    					 | ';'
    			 		 ;

expression: expression ',' sub_expr
    			| sub_expr
					;

sub_expr:
    sub_expr '>' sub_expr				{	type_check(2,$1,$3);	$$ = $1;	}
    |sub_expr '<' sub_expr				{	type_check(2,$1,$3);	$$ = $1;	}
    |sub_expr EQ sub_expr				{	type_check(2,$1,$3);	$$ = $1;	}
    |sub_expr NOT_EQ sub_expr				{	type_check($1,$3,2);	$$ = $1;	}
    |sub_expr LS_EQ sub_expr				{	type_check($1,$3,2);	$$ = $1;	}
    |sub_expr GR_EQ sub_expr				{	type_check($1,$3,2);	$$ = $1;	}
    |sub_expr LOGICAL_AND sub_expr			{	type_check(2,$1,$3);	$$ = $1;	}
    |sub_expr LOGICAL_OR sub_expr			{	type_check(2,$1,$3);	$$ = $1;	}
    |'!' sub_expr					{	$$ = $2; }
    |arithmetic_expr					{	$$ = $1; }
    |assignment_expr					{	$$ = $1; }
    |unary_expr						{	$$ = $1; }
    ;


assignment_expr :
    lhs assign_op  arithmetic_expr			{	type_check(1,$1,$3);	$$ = $3;	rhs=0; }
    |lhs assign_op  array_access			{	type_check(1,$1,$3);	$$ = $3;	rhs=0; }
    |lhs assign_op  function_call			{       type_check(1,$1,$3);    $$ = $3;        rhs=0;}
	|lhs assign_op  unary_expr                      {       type_check($1,$3,1);    $$ = $3;        rhs=0;}
		|unary_expr assign_op  unary_expr	{       type_check(1,$1,$3);    $$ = $3;        rhs=0;}
    ;

unary_expr:	identifier INCREMENT						{$$ = $1->data_type;}
					| identifier DECREMENT			{$$ = $1->data_type;}
					| DECREMENT identifier			{$$ = $2->data_type;}
					| INCREMENT identifier			{$$ = $2->data_type;}

lhs: identifier									{$$ = $1->data_type;}
   | array_access								{$$ = $1;}
	 ;

identifier:IDENTIFIER                                    {
                                                                    if(is_declaration && !rhs) 
                                                                    {
									$1 = insert(symbol_table_list[current_scope].symbol_table,yytext,INT_MAX,cur_dtype);
                                                                        if($1 == NULL) yyerror("Redeclaration of variable");
                                                                    }
                                                                    else
                                                                    {
								        $1 = rec_search(yytext);
                                                                        if($1 == NULL) yyerror("Variable not declared");
                                                                    }
                                                                    $$ = $1;
                                                          }
    			 ;

assign_op:'='                                     {  rhs=1;  }
    |ADD_ASSIGN                                   {  rhs=1;  } 
    |SUB_ASSIGN                                   {  rhs=1;  }
    |MUL_ASSIGN                                   {  rhs=1;  }
    |DIV_ASSIGN                                   {  rhs=1;  }
    |MOD_ASSIGN                                   {  rhs=1;  }
    ;

arithmetic_expr: arithmetic_expr '+' arithmetic_expr				{  type_check(0,$1,$3);   }
    |arithmetic_expr '-' arithmetic_expr					{  type_check(0,$1,$3);   }
    |arithmetic_expr '*' arithmetic_expr					{  type_check(0,$1,$3);   }
    |arithmetic_expr '/' arithmetic_expr					{  type_check(0,$1,$3);   }
		|arithmetic_expr '%' arithmetic_expr				{  type_check(0,$1,$3);   }
		|'(' arithmetic_expr ')'					{       $$ = $2;          }
    |'-' arithmetic_expr %prec UMINUS						{       $$ = $2;          }
    |identifier									{    $$ = $1->data_type;  }
    |constant								        {    $$ = $1->data_type;  }
    ;

constant: DEC_CONSTANT 						              {  $1->is_constant=1;   $$ = $1; }
    | HEX_CONSTANT							      {  $1->is_constant=1;   $$ = $1; }
		| CHAR_CONSTANT						      {  $1->is_constant=1;   $$ = $1; }
		| FLOAT_CONSTANT					      {  $1->is_constant=1;   $$ = $1; }
    ;

array_access: identifier '[' array_index ']'					{
										    if(is_declaration)
										      {
											if($3->value <= 0)
											  yyerror("size of array is not positive");
											if($3->is_constant && !rhs)
											   $1->array_dimension = $3->value;
										        else if(rhs){
											 {
											 if($3->value > $1->array_dimension)
											    yyerror("Array index out of bound");
											 if($3->value < 0)
											    yyerror("Array index cannot be negative");
											 }
									                }
										      }

									              else if($3->is_constant)
									              {
									              if($3->value > $1->array_dimension)
									                yyerror("Array index out of bound");
									              if($3->value < 0)
									                yyerror("Array index cannot be negative");
									              }
								                      $$ = $1->data_type;
								              }

array_index: constant					         { $$ = $1; }
					 | identifier	         { $$ = $1; }
					 ;

function_call: identifier '(' parameter_list ')'	{
						        $$ = $1->data_type;
						        check_parameter_list($1,param_list,p_idx);
						        p_idx = 0;
							}

             | identifier '(' ')'			{
							$$ = $1->data_type;
							check_parameter_list($1,param_list,p_idx);
							p_idx = 0;
							}
					;

parameter_list:
              parameter_list ','  parameter
	      |parameter
              ;

parameter: sub_expr		{	param_list[p_idx++] = $1;	}
	| STRING		{	param_list[p_idx++] = STRING;	}
	;
%%

#define ANSI_COLOR_RED		"\x1b[31m"
#define ANSI_COLOR_GREEN	"\x1b[32m"
#define ANSI_COLOR_YELLOW	"\x1b[33m"
#define ANSI_COLOR_CYAN		"\x1b[36m"
#define ANSI_COLOR_RESET	"\x1b[0m"

void type_check(int type, int left, int right)
{
	if(left != right)
	{
		switch(type)
		{
			case 0: yyerror("Type mismatch in arithmetic expression"); break;
			case 1: yyerror("Type mismatch in assignment expression"); break;
			case 2: yyerror("Type mismatch in logical expression"); break;
		}
	}
}

int main(int argc, char *argv[])
{

	yyin = fopen(argv[1], "r");
	int itr;
	for(itr = 0; itr <MAX_SCOPE; itr++){
		symbol_table_list[itr].symbol_table = NULL;
		symbol_table_list[itr].parent = -1;
	}

	constant_table = create_table();
	symbol_table_list[0].symbol_table = create_table();

	if(!yyparse())
	{
		printf(ANSI_COLOR_GREEN "\nStatus: PARSING COMPLETE\n" ANSI_COLOR_RESET "\n");
	}
	else
	{
		printf(ANSI_COLOR_RED "\nStatus: PARSING FAILED!\n" ANSI_COLOR_RESET "\n");
	}

	printf( ANSI_COLOR_CYAN "\n\n\n*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-* STRUCTURE TABLE *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*\n\n" ANSI_COLOR_RESET);
	display_symbol_table();

	printf( ANSI_COLOR_CYAN "\n\n\n*-*-*-*-*-*-*-*-*-*-* CONSTANT TABLE *-*-*-*-*-*-*-*-*-*-*\n\n" ANSI_COLOR_RESET);
	display_constant_table(constant_table);


	fclose(yyin);
	return 0;
}

int yyerror(char *msg)
{
	printf(ANSI_COLOR_YELLOW "\nLine %d : %s Token: %s\n" ANSI_COLOR_RESET, yylineno, msg, yytext);
	printf(ANSI_COLOR_RED "\nStatus: PARSING FAILED!" ANSI_COLOR_RESET "\n");

	printf( ANSI_COLOR_CYAN "\n\n\n*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-* STRUCTURE TABLE *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*\n\n" ANSI_COLOR_RESET);
	display_symbol_table();

	printf( ANSI_COLOR_CYAN "\n\n\n*-*-*-*-*-*-*-*-*-*-* CONSTANT TABLE *-*-*-*-*-*-*-*-*-*-*\n\n" ANSI_COLOR_RESET);
	display_constant_table(constant_table);

	exit(0);
}
