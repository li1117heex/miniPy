%{
#include <stdlib.h>
#include <stdio.h>
#include<string.h>
#include "minipy-lab.tab.h"

/*  any C declaration  */
%}

letter    [a-zA-Z]

digit     [0-9]

number   {digit}+

id       {letter}({letter}|{digit})*

real     {number}\.{number}?|{number}?\.{number}

%%
[ \t]+      {/*do nothing , just skip */}
{number}    { 
              yylval.integer = atoi(yytext);
              return INT;
            }
{real}      {
              yylval.real = (float)atof(yytext);
              return REAL;
            }
{id}        {
              int len = strlen(yytext);
              yylval.name = (char*)malloc(len + 1);
              strcpy(yylval.name, yytext);
              yylval.name[len] = '\0';
              return ID; 
            }
\"(\\.|[^\\"])*\"	{
                int len = strlen(yytext);
                yylval.name = (char*)malloc(len - 1);
                strcpy(yylval.name, yytext + 1);
                yylval.name[len-2] = '\0';
                return(STRING_LITERAL); 
                  }
.|\n        { return yylval.c_value = yytext[0];}
%%