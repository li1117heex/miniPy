%{
   extern "C" {
    int yyparse();
    int yylex();
    void yyerror(char *s){cout << s << endl<<"miniPy> ";}
    int yywrap(void){return 1;}
   }
   /* definition */
   #include <stdio.h>
   #include <ctype.h>
   using namespace std;
   #include <iostream>
   #include <string>
   #include <map>
  
   #include "lex.yy.c"
%}
%token <name>ID
%token <integral>INT
%token <real>REAL
%token <name>STRING_LITERAL
%union{
	int integer;
	float real;
	char* name;
}

%left '+' '-'
%left '*' '/' '%'
%right unimus

%%
Start : prompt Lines  {cout << "a line has been generated" << endl;}
      ;
Lines : Lines  stat '\n' prompt
      | Lines  '\n' prompt
      |
      | error '\n' {yyerrok;}
      ;
prompt : {cout << "miniPy> ";}
       ;
stat  : assignExpr
      ;
assignExpr:
        atom_expr '=' assignExpr
      | add_expr 
      ;
number : INT
       | REAL
       ;
factor : '+' factor %prec unimus
		{$$ = $2;}
       | '-' factor	%prec unimus
	   {$$ = -$2;}
       | atom_expr
       ; 
atom  : ID
      | STRING_LITERAL 
      | List 
      | number 
      ;
slice_op :  /*  empty production */
        | ':' add_expr 
        ;
sub_expr:  /*  empty production */
        | add_expr
        ;        
atom_expr : atom 
        | atom_expr  '[' sub_expr  ':' sub_expr  slice_op ']' 	/*词典*/
        | atom_expr  '[' add_expr ']'							/*列表*/
        | atom_expr  '.' ID										/*属性*/
        | atom_expr  '(' arglist opt_comma ')'					/*函数（含参）*/
        | atom_expr  '('  ')'									/*函数（不含参）*/
        ;
arglist : add_expr
        | arglist ',' add_expr 
        ;
        ;      
List  : '[' ']'
      | '[' List_items opt_comma ']' 
      ;
opt_comma : /*  empty production */
          | ','
          ;
List_items  
      : add_expr
      | List_items ',' add_expr 
      ;
add_expr : add_expr '+' mul_expr
		{$$ = $1 + $3;}
	      |  add_expr '-' mul_expr
		{$$ = $1 - $3;}
	      |  mul_expr 
        ;
mul_expr : mul_expr '*' factor
		{$$ = $1 * $3;}
        |  mul_expr '/' factor
		{$$ = $1 / $3;}
		|  mul_expr '%' factor
		{$$ = $1 % $3;}
        |  factor
        ;

%%

int main()
{
   return yyparse();
}

/*
void yyerror(char *s)
{
   cout << s << endl<<"miniPy> "; 
}

int yywrap()
{ return 1; }        		    
*/