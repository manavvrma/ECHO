%{

#include <stdlib.h>
#include <stdio.h>
#include <limits.h>

#include "y.tab.h"
table_entry** constant_table;

int yylineno =1;

%}

alpha [a-zA-Z]
digit [0-9]
extra  [ \t\r\f\v]+
identifier (_|{alpha})({alpha}|{digit}|_){0,31}
hex [0-9a-f]
space [ ]

%%
\n                              {yylineno++;}
"/*"				{ multicomment(); }
"//"				{ singlecomment(); }

"#include<"({alpha})*".h>"	{	printf("\nLine %d : Found header file\n", yylineno);	}
"#include"({space})"<"({alpha})*".h>"	{	printf("\nLine %d : Found header file\n", yylineno);	}
"#define"({space})""({alpha})""({alpha}|{digit})*""({space})""({digit})+"" 			{ printf("\nLine %d : Found macro definition\n", yylineno);  }
"#define"({space})""({alpha}({alpha}|{digit})*)""({space})""(({digit}+)\.({digit}+))"" 		{ printf("\nLine %d : Found macro definition\n", yylineno);  }
"#define"({space})""({alpha}({alpha}|{digit})*)""({space})""({alpha}({alpha}|{digit})*)"" 	{ printf("\nLine %d : Found macro definition\n", yylineno); }
"#"({alpha})	{	yyerror("Invalid headerfile declaration!");	}

"loop"                          {return LOOP;}
"whilst"                        {return WHILST;}
"interrupt"                     {return INTERRUPT;}
"resume"                        {return RESUME;}
"condition"                     {return CONDITION;}
"else"                          {return ELSE;}
"result"                        {return RESULT;}
"number"                        {return NUMBER;}
"character"                     {return CHARACTER;}
"decimal"                       {return DECIMAL;}
"precision"                     {return PRECISION;}
"echo"                          {return ECHO;}
"lengthy"                       {return LENGTHY;}
"very lengthy"                  {return VERY_LENGTHY;}
"short"                         {return SHORT;}
"negative"                      {return NEGATIVE;}
"positive"                      {return POSITIVE;}

{identifier}                      {return  IDENTIFIER;}
{extra}                              ;
[+\-]?[0][x|X]{hex}+[lLuU]?       { yylval.entry = insert(constant_table,yytext,(int)strtol(yytext, NULL, 16),NUMBER); return  HEX_CONSTANT;}
'({alpha}|{digit})'               { yylval.entry = insert(constant_table,yytext,yytext[1],CHARACTER); return CHAR_CONSTANT;}
[+\-]?{digit}+[lLuU]?             { yylval.entry = insert(constant_table,yytext,atoi(yytext),NUMBER); return  DEC_CONSTANT;}
[+\-]?{digit}*\.{digit}+          { yylval.entry = insert(constant_table,yytext,atof(yytext),DECIMAL); return FLOAT_CONSTANT;}

\"[^\"\n]*\"                      { printf("%s",yytext);	insert(constant_table,yytext,INT_MAX,STRING);	return STRING;	}

\"[^\"\n]*$                       {printf("Line %3d: Unterminated string %s\n",yylineno,yytext);}
{digit}+({alpha}|_)+	          {printf("Line %3d: Illegal identifier name %s\n",yylineno,yytext);}

"--"			          {return DECREMENT;}
"++"			          {return INCREMENT;}
"+="				  {return ADD_ASSIGN;}
"-="				  {return SUB_ASSIGN;}
"*="				  {return MUL_ASSIGN;}
"/="				  {return DIV_ASSIGN;}
"%="				  {return MOD_ASSIGN;}


"&&"			          {return LOGICAL_AND;}
"||"			          {return LOGICAL_OR;}
"<="			          {return LS_EQ;}
">="			          {return GR_EQ;}
"=="			          {return EQ;}
"!="		                  {return NOT_EQ;}

.				  {return yytext[0];}

%%


yywrap()
{
	return(1);
}

multicomment()
{
	int count = 1;
	char star = 'a', comment_end=EOF;
	while(star!=EOF && count>0){
		if(star == '\n'){
			yylineno++;
			star = input();
		}
		else if(star == '/'){
			comment_end = input();
			if(comment_end == EOF){
				printf("Reached EOF, but multiline comment isn't ended!");
				break;
			}
			else if(comment_end == '*'){
				count++;
				star = input();
			}
			else{
				star = comment_end;
			}				
	
		}
		else if(star == '*'){
			comment_end = input();
			if(comment_end == EOF){
				printf("Reached EOF, but multiline comment isn't ended!");
				break;
			}
			else if(comment_end == '/'){
				printf("\nLine %d : Detected multiline line comment with nesting level = %d\n", yylineno, count);
				count--;
				if(count>0)	star = input();
			}
			else{
				star = comment_end;
			}
		}
		else{
			star = input();	
		}
	}
	if(star == EOF){
		printf("Reached EOF, but multiline comment isn't ended!");
	}
}

singlecomment()
{
	char comment_end = '/';
	while(comment_end != EOF && comment_end != '\n'){
		comment_end = input();
	}
	printf("\nLine %d : Detected single line comment\n", yylineno);
	if(comment_end == '\n'){
		yylineno++;
	}
}
