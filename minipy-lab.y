%{
/* definition */
#include <stdio.h>
#include <ctype.h>
using namespace std;
#include <iostream>
#include <string>
#include <map>

#include "lex.yy.c"

extern "C" {
int yyparse();
void yyerror(char *s){cout << s << endl<<"miniPy> ";}
int yywrap(void){return 1;}
}

//数值非终结符
typedef struct num_struct
{
	int type;	//0:integer, 1:float
	union 
	{
		int int_value;
		float f_value;
	};
}num_struct;
//链表非终结符
typedef struct list_struct
{
	int type;	//链表内内容类型，0:number, 2:string literal, 3:list （为了和type_struct保持一致）
	union
	{
		num_struct* num;
		char* str;
		list_struct* list_head;
	};
	list_struct* next;
}list_struct;
//类型非终结符
typedef struct type_struct
{
	int type;	//0:number, 1:ID, 2:string literal, 3:list
	union
	{
		num_struct* num;	//number
		char* id;			//id
		char* str;			//string literal
		list_struct* list_head;	//list
	};
}type_struct;

//变量表
map<char*, type_struct*> var_map;

//内置函数

%}
%union{
	char c_value;
	int integer;
	float real;
	char* name;
	struct num_struct* num_symbol;
	struct list_struct* list_symbol;
	struct type_struct* type_symbol;
}
%token <name> ID
%token <integral> INT
%token <real> REAL
%token <name> STRING_LITERAL
%type <num_symbol> number
%type <list_symbol> List List_items
%type <type_symbol> atom atom_expr add_expr mul_expr factor assignExpr sub_expr

%left '+' '-'
%left '*' '/' '%'
%right unimus
%left '(' ')'

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
		{			
			if($1->type == 1)	/*ID，存储变量到变量表*/
			{	
				map<char*, type_struct*>::iterator iter;
				for(iter = var_map.begin(); iter != var_map.end();)
				{
					if(strcmp(iter->first, $1->id) == 0)	/*判断相等，把之前的去掉再insert新的*/
					{
						iter = var_map.erase(iter);
						printf("variable %s deleted\n", $1->id);
					}
					else{
						iter++;
					}
				}
				var_map.insert(map<char*, type_struct*>::value_type($1->id, $3));
			}

			switch($3->type){
				case 0:{
					if($3->num->type == 0)
						$1->num->int_value = $3->num->int_value;
					else
						$1->num->f_value = $3->num->f_value;
					$$ = $1;
					break;
				}
				case 1:{
					yyerror("ID cannot be a right value!");
					break;
				}
				case 2:{
					$1->str = $3->str;
					break;
				}
				case 3:{
					$1->list_head = $3->list_head;
					break;
				}
			}
			$1->type = $3->type;
			$$ = $1;
		}
      | add_expr 
	  {
		$$ = $1;
		switch($$->type){
			case 0:{
				if($$->num->type == 0)
					printf("%d\n", $$->num->int_value);
				else
					printf("%.3f\n", $$->num->f_value);
				break;
			}
			case 1:{
				/*查找该ID*/
				break;
			}
			case 2:{
				break;
			}
			case 3:{
				break;
			}
		}
	  }
      ;
number : INT
		{
			$$ = (num_struct*)malloc(sizeof(num_struct));
			$$->type = 0;
			$$->int_value = yylval.integer;
		}
       | REAL
	   {
		   $$ = (num_struct*)malloc(sizeof(num_struct));
		   $$->type = 1;
		   $$->f_value = yylval.real;
	   }

       ;
factor : '+' factor %prec unimus
		{
			$$ = $2;			
			if($$->type != 0)
				yyerror("'+ factor' must use number type!");
		}
       | '-' factor	%prec unimus
	   {
		   	$$ = $2;
			if($$->type != 0)
				yyerror("'- factor' must use number type!");
			else{
				if($$->num->type == 0)		/*int*/
					$$->num->int_value = -$$->num->int_value;
				else
					$$->num->f_value = -$$->num->f_value;
			}
	   }
       | atom_expr
	   {
		   $$ = $1;
	   }
	   | '(' add_expr ')'
	   {
		   $$ = $2;
	   }
       ; 
atom  : ID
		{
		  $$ = (type_struct*)malloc(sizeof(type_struct));
		  $$->type = 1;
		  $$->id = $1;
		}
      | STRING_LITERAL
	  {
		$$ = (type_struct*)malloc(sizeof(type_struct));
		$$->type = 2;
		$$->str = $1;
	  }
      | List 
	  {
		$$ = (type_struct*)malloc(sizeof(type_struct));
		$$->type = 3;
		$$->list_head = $1;
	  }
      | number
	  {
		  $$ = (type_struct*)malloc(sizeof(type_struct));
		  $$->type = 0;
		  $$->num = $1;
	  }
      ;
slice_op :  /*  empty production */
        | ':' add_expr 
        ;
sub_expr:  /*  empty production */
        | add_expr
        ;        
atom_expr : atom
		{
			$$ = $1;
		}
        | atom_expr  '[' sub_expr  ':' sub_expr  slice_op ']' 	/*列表取元素区间*/
        | atom_expr  '[' add_expr ']'							/*列表取元素*/
		{
			type_struct* var;

			if($1->type != 1)
			{
				yyerror("object must be indicated with a variable!");
			}
			else	/*ID，取变量*/
			{
				map<char*, type_struct*>::iterator iter;
				iter = var_map.find($1->id);
				if(iter != var_map.end())  
       			{
					cout<<"Find, the type of the variable is "<<iter->second->type<<endl;  
					var = iter->second;
				}
				else
				{
					cout<<"Do not Find"<<endl;  
				}  
			}

			if($3->type != 0 || $3->num->type != 0)
				yyerror("index must be int type!");
			else if($3->num->int_value < 0)
				yyerror("index must >0 !");
			else if(var->type != 3)
				yyerror("the object must be a list!");
			else
			{
				int index = $3->num->int_value;
				list_struct* node = var->list_head;
				while(index > 0)
				{
					node = node->next;
					index--;
				}
				$$ = (type_struct*)malloc(sizeof(type_struct));
				$$->type = node->type;
				switch($$->type){
					case 0:{		/*number*/
						$$->num = node->num;
						break;
					}
					case 2:{		/*string_literal*/
						$$->str = node->str;
						break;
					}
					case 3:{		/*list*/
						$$->list_head = node->list_head;
						break;
					}
				}
			}
		}
        | atom_expr  '.' atom '(' arglist opt_comma ')'			/*取属性*/

        | atom_expr  '(' arglist opt_comma ')'					/*函数（含参）*/
		{

		}
        | atom_expr  '('  ')'									/*函数（不含参）*/
        ;
arglist : add_expr
        | arglist ',' add_expr 
        ;
        ;      
List  : '[' ']'
		{
			$$ = (list_struct*)malloc(sizeof(list_struct));
			$$->type = 0;		//暂时赋为number类型
			$$->next = NULL;	//空链表
		}
      | '[' List_items opt_comma ']' 
	  {
		  $$ = $2;
	  }
      ;
opt_comma : /*  empty production */
          | ','
          ;
List_items  
      : add_expr
	  {
		$$ = (list_struct*)malloc(sizeof(list_struct));
		$$->type = $1->type;
		switch($$->type){
			case 0:{
				$$->num = $1->num;
				break;
			}
			case 1:{
				yyerror("ID cannot be a member of a list!");
				break;
			}
			case 2:{
				$$->str = $1->str;
				break;
			}
			case 3:{
				$$->list_head = $1->list_head;
				break;
			}
		}
		$$->next = NULL;	//尾端
	  }
      | List_items ',' add_expr 
	  {
		$$ = $1;
		list_struct* tempp = (list_struct*)malloc(sizeof(list_struct));
		tempp->type = $3->type;
		switch($3->type){
			case 0:{
				tempp->num = $3->num;
				break;
			}
			case 1:{
				yyerror("ID cannot be a member of a list!");
				break;
			}
			case 2:{
				tempp->str = $3->str;
				break;
			}
			case 3:{
				tempp->list_head = $3->list_head;
				break;
			}
		}
		tempp->next = NULL;
		$$->next = tempp;
	  }
      ;
add_expr : add_expr '+' mul_expr
		{
			$$ = $1;
			switch($$->type){
				case 0:{	/*number*/
					switch($3->type){
						case 0:{
							num_struct* num1 = $$->num;
							num_struct* num2 = $3->num;
							if(num1->type != num2->type)
							{
								yyerror("int cannot add float!");
							}
							else
							{
								if(num1->type == 0) 
									num1->int_value = num1->int_value + num2->int_value;
								else
									num1->f_value = num1->f_value + num2->f_value;
							}
							break;
						}
					}
					break;
				}
			}
		}
	      |  add_expr '-' mul_expr
		{
			$$ = $1;
			switch($$->type){
				case 0:{	/*number*/
					switch($3->type){
						case 0:{
							num_struct* num1 = $$->num;
							num_struct* num2 = $3->num;
							if(num1->type != num2->type)
							{
								yyerror("int cannot minus with float!");
							}
							else
							{
								if(num1->type == 0) 
									num1->int_value = num1->int_value - num2->int_value;
								else
									num1->f_value = num1->int_value - num2->f_value;
							}
							break;
						}
					}
					break;
				}
			}
		}
	      |  mul_expr 
		{
			$$ = $1;
		}
        ;
mul_expr : mul_expr '*' factor
		{
			$$ = $1;
			switch($$->type){
				case 0:{	/*number*/
					switch($3->type){
						case 0:{
							num_struct* num1 = $$->num;
							num_struct* num2 = $3->num;
							if(num1->type != num2->type)
							{
								yyerror("int cannot multiple float!");
							}
							else
							{
								if(num1->type == 0) 
									num1->int_value = num1->int_value * num2->int_value;
								else
									num1->f_value = num1->int_value * num2->f_value;
							}
							break;
						}
					}
					break;
				}
			}
		}
        |  mul_expr '/' factor
		{
			$$ = $1;
			switch($$->type){
				case 0:{	/*number*/
					switch($3->type){
						case 0:{
							num_struct* num1 = $$->num;
							num_struct* num2 = $3->num;
							if(num1->type != num2->type)
							{
								yyerror("int cannot divide with float!");
							}
							else
							{
								if(num1->type == 0)
								{
									if(num2->int_value == 0)
										yyerror("divided by zero!");
									else
										num1->int_value = num1->int_value / num2->int_value;
								}
								else
								{
									if(num2->f_value == 0)
										yyerror("divided by zero!");
									else
										num1->f_value = num1->int_value / num2->f_value;
								}
							}
							break;
						}
					}
					break;
				}
			}
		}
		|  mul_expr '%' factor
		{
			$$ = $1;
			switch($$->type){
				case 0:{	/*number*/
					switch($3->type){
						case 0:{
							num_struct* num1 = $$->num;
							num_struct* num2 = $3->num;
							if(num1->type != 0 || num2->type != 0)
							{
								yyerror("only int can compute remainders!");
							}
							else
							{
								if(num2->int_value == 0)
									yyerror("divided by zero!");
								else
									num1->int_value = num1->int_value % num2->int_value;
							}
							break;
						}
					}
					break;
				}
			}
		}
        |  factor
		{
			$$ = $1;
		}
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
