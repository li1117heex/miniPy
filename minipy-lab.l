%{
#include <stdlib.h>
#include <stdio.h>

#include "minipy-lab.tab.h"

extern int yylval;

/*  any C declaration  */
%}

letter    [a-zA-Z]

digit     [0-9]

number   {digit}+

id       {letter}({letter}|{digit})*

real     {number}'.'{number}?|{number}?'.'{number}

%%
[ \t]+      {/*do nothing , just skip */}
{number}    { 
              yylval.integer = atoi(yytext);
              return INT;
            }
{real}      {
              yylval.real = atof(yytext);
              return REAL;
            }
{id}        {
              yylval.name = yytext;
              return ID; 
            }
\"(\\.|[^\\"])*\"	{
              yylval.name = yytext;
             return(STRING_LITERAL); 
                  }
.|\n        { return yylval = yytext[0];}
%%
