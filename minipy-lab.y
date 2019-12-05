%{
/* definition */
#include <stdio.h>
#include <ctype.h>
using namespace std;
#include <iostream>
#include <string>

#include "lex.yy.c"
#include "property.h"

int yyparse(void);
void yyerror(char *s){cout << "error: " << s << endl<<"miniPy> ";}
int yywrap(void){return 1;}

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
%type <list_symbol> List List_items arglist
%type <type_symbol> atom atom_expr add_expr mul_expr factor assignExpr sub_expr stat slice_op 

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
	{
		if($1->error){
			printobj($1);
			$$ = $1;
		}
	}
      ;
assignExpr:
        atom_expr '=' assignExpr
		{
			if($3->error)
				$$ = $3;
			else if($3->type == 5){
				$$ = $3;
			}			
			else if($1->type == 1)	/*ID，存储变量到变量表*/
			{	
				map<char*, type_struct*>::iterator iter;
				for(iter = var_map.begin(); iter != var_map.end();)
				{
					if(strcmp(iter->first, $1->id) == 0)	//判断相等，把之前的去掉再insert新的
					{
						iter = var_map.erase(iter);
						break;
					}
					else{
						iter++;
					}
				}
				var_map.insert(map<char*, type_struct*>::value_type($1->id, $3));  //存储原来的，上交浅拷贝的
				shallowcopy($3,$1);
				$$ = $1;
			}
			else if($1->type == 4)
			{
				$1->List_Index->list_vec->at($1->List_Index->index) = $3;    //存储原来的，上交浅拷贝的
				shallowcopy($3,$1);
				$$ = $1;
			}
			else
			{
				$$=(type_struct*)malloc(sizeof(type_struct));
				$$->error = true;
				yyerror("can't assign to literal");
			}
		}
      | add_expr 
	  {
		$$ = $1;  //挪到上面
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
			if($2->type != 0)
			{
				$$=(type_struct*)malloc(sizeof(type_struct));
				$$->error = true;
				yyerror("'+ factor' must use number type!");
			}
			else	
				$$ = $2;			
		}
       | '-' factor	%prec unimus
	   {
			if($2->type != 0)
			{
				$$=(type_struct*)malloc(sizeof(type_struct));
				$$->error = true;
				yyerror("'- factor' must use number type!");
			}
			else{
				if($2->num->type == 0)
					$2->num->int_value = -$2->num->int_value;
				else
					$2->num->f_value = -$2->num->f_value;
				$$ = $2;
			}
		   	
	   }
       | atom_expr
	   {
			if($1->type == 1)
			{
				map<char*, type_struct*>::iterator iter;
				for(iter = var_map.begin(); iter != var_map.end(); iter++)
				{
					if(strcmp(iter->first, $1->id) == 0)	
					{
						break;
					}
				}
				if(iter != var_map.end())
				{
					$$=(type_struct*)malloc(sizeof(type_struct));
					shallowcopy(iter->second,$$);
				}
				else
				{
					$$=(type_struct*)malloc(sizeof(type_struct));
					$$->error = true;
					yyerror("name is not defined");
				}
			}
			else if($1->type == 4)
			{
				$$=(type_struct*)malloc(sizeof(type_struct));
				shallowcopy($1->List_Index->list_vec->at($1->List_Index->index),$$);
			}
			else{
				$$ = $1;
			}
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
		  $$->error = false;
		  $$->id = yylval.name;
		}
      | STRING_LITERAL
	  {
		$$ = (type_struct*)malloc(sizeof(type_struct));
		$$->type = 2;
		$$->error = false;
		$$->str = yylval.name;
	  }
      | List 
	  {
		if($1->error)
		{
			$$ = (type_struct*)malloc(sizeof(type_struct));
			$$->error = true;
		}
		else
		{
			$$ = (type_struct*)malloc(sizeof(type_struct));
			$$->type = 3;
			$$->error = false;
			$$->list_head = $1;
		}
	  }
      | number
	  {
		  $$ = (type_struct*)malloc(sizeof(type_struct));
		  $$->type = 0;
		  $$->error = false;
		  $$->num = $1;
	  }
      ;
slice_op :  /*  empty production */
		{
			$$=NULL;
		}
        | ':' add_expr 
		{
			if($2->type != 0 || $2->num->type != 0)
			{
				$$=(type_struct*)malloc(sizeof(type_struct));
				$$->error = true;
				yyerror("index must be int type!");
			}
				 
			else if($2->num->int_value == 0)
			{
				$$=(type_struct*)malloc(sizeof(type_struct));
				$$->error = true;
				yyerror("slice step cannot be zero");
			}
			else				 
				$$ = $2;
		}
        ;
sub_expr:  /*  empty production */
		{
			$$=NULL;
		}
        | add_expr
		{
			if($1->type != 0 || $1->num->type != 0)
			{
				$$=(type_struct*)malloc(sizeof(type_struct));
				$$->error = true;
				yyerror("index must be int type!");
			}
			else	 
				$$ = $1;
		}
        ;        
atom_expr : atom
		{
			$$ = $1;
		}
        | atom_expr  '[' sub_expr  ':' sub_expr  slice_op ']' 	/*列表取元素区间*/
		{
			//$1           $3             $5         $6
			type_struct* var;
			int firstindex,lastindex,indexstep;

			if($1->type == 0 || $1->type == 5)
			{
				$$=(type_struct*)malloc(sizeof(type_struct));
				$$->error = true;
				yyerror("TypeError, object is not subscriptable");
			}
			else if($1->type == 2 || $1->type == 3)
			{
				var = $1;
			}
			else if($1->type == 4)
			{
				var = $1->List_Index->list_vec->at($1->List_Index->index);
			}
			else	/*ID，取变量*/
			{
				map<char*, type_struct*>::iterator iter;
				for(iter = var_map.begin(); iter != var_map.end(); iter++)
				{
					if(strcmp(iter->first, $1->id) == 0)	
					{
						break;
					}
				}
				if(iter != var_map.end())  
       			{
					// cout<<"Find, the type of the variable is "<<iter->second->type<<endl;  
					var = iter->second;
				}
				else
				{
					$$=(type_struct*)malloc(sizeof(type_struct));
					$$->error = true;
					yyerror("name is not defined");
				}  
			}

			if($1->error || $3->error ||$5->error ||$6->error)
			{
				$$=(type_struct*)malloc(sizeof(type_struct));
				$$->error = true;
			}
			else if(var->type == 0 || var->type == 1)
			{
				$$=(type_struct*)malloc(sizeof(type_struct));
				$$->error = true;
				yyerror("the object must be a list or string");
			}
				
			else if(var->type == 2)
			{
				$$=(type_struct*)malloc(sizeof(type_struct));
				$$->error = true;
				yyerror("string complex slice not support yet"); //not support yet
			}
			else if(var->type == 5)
			{
				$$=(type_struct*)malloc(sizeof(type_struct));
				$$->error = true;
				yyerror("void type, cannot support");
			}
			else
			{
				int size = var->list_head->list_vec->size();
				indexstep = $6 == NULL?1:$6->num->int_value;
				firstindex = $3 == NULL?(indexstep>0?0:size-1)
				:($3->num->int_value>=0?$3->num->int_value:$3->num->int_value+size);
				lastindex = $5 == NULL?(indexstep>0?size:-1)
				:($5->num->int_value>=0?$5->num->int_value:$5->num->int_value+size); //-1是为了取完list

				vector<type_struct*> newvec;
				int i;
				if((firstindex-lastindex)*indexstep<0) //只有步长与目标同向才非空表
					for(i=firstindex;i<lastindex && i<size && i>-1;i+=indexstep)
					{
						printobj(var->list_head->list_vec->at(i));
						newvec.push_back(var->list_head->list_vec->at(i));
					}
				$$=(type_struct*)malloc(sizeof(type_struct));
				$$->type=3;
				$$->list_head=(list_struct*)malloc(sizeof(list_struct));
				$$->list_head->list_vec = (vector<type_struct*>*)&newvec;
			}
		}
        | atom_expr '[' add_expr ']'							/*列表取元素*/
		{
			type_struct* var;
			int index;

			if($1->type != 1 && $1->type != 4)
			{
				var = $1;
			}
			else if($1->type == 4)
			{
				var = $1->List_Index->list_vec->at($1->List_Index->index);
			}
			else	/*ID，取变量*/
			{
				map<char*, type_struct*>::iterator iter;
				for(iter = var_map.begin(); iter != var_map.end(); iter++)
				{
					if(strcmp(iter->first, $1->id) == 0)	
					{
						break;
					}
				}
				if(iter != var_map.end())  
       			{
					// cout<<"Find, the type of the variable is "<<iter->second->type<<endl;  
					var = iter->second;
				}
				else
				{
					$$=(type_struct*)malloc(sizeof(type_struct));
					$$->error = true;
					yyerror("name is not defined");////////////////
				}  
			}

			if($1->error || $3->error)
			{
				$$=(type_struct*)malloc(sizeof(type_struct));
				$$->error = true;
			}
			else if($3->type != 0 || $3->num->type != 0)
			{
				
				yyerror("index must be int type!");
			}
				
			else if(var->type == 0 || var->type == 1 || var->type == 5){
				$$=(type_struct*)malloc(sizeof(type_struct));
				$$->error = true;
				yyerror("the object must be a list or string");//////////
			}
				
			else if(var->type == 2)
			{
				index=$3->num->int_value>=0?$3->num->int_value:$3->num->int_value+strlen(var->str);
				if(index >=strlen(var->str) || index < 0 ){
					$$=(type_struct*)malloc(sizeof(type_struct));
					$$->error = true;
					yyerror("string index out of range");
				}
				else{
					$$ = (type_struct*)malloc(sizeof(type_struct));
					$$->type=2;
					$$->str=(char*)malloc(2);
					strncpy($$->str,var->str+index,1);
					$$->str[1]='\0';
				}	
				
			}
			else //var->type == 3
			{
				index=$3->num->int_value>=0?$3->num->int_value:$3->num->int_value+var->list_head->list_vec->size();
				if(index >=var->list_head->list_vec->size() || index < 0 )
				{
					$$=(type_struct*)malloc(sizeof(type_struct));
					$$->error = true;
					yyerror("string index out of range");
				}
				$$ = (type_struct*)malloc(sizeof(type_struct));
				$$->type=4;
				$$->List_Index = (list_index*)malloc(sizeof(list_index));
				$$->List_Index->index = index;
				$$->List_Index->list_vec = var->list_head->list_vec;

			}
		}
        | atom_expr  '.' atom '(' arglist opt_comma ')'			/*调用类方法*/
		{
			void *func;
			type_struct *arg = (type_struct*)malloc(sizeof(type_struct));
			type_struct *var;
			if($1->error || $3->error || $5->error)
			{
				$$=(type_struct*)malloc(sizeof(type_struct));
				$$->error = true;
			}
			else
			{
				//取ID
				if($1->type == 1)
				{
					map<char*, type_struct*>::iterator iter;
					for(iter = var_map.begin(); iter != var_map.end(); iter++)
					{
						if(strcmp(iter->first, $1->id) == 0)	
						{
							break;
						}
					}
					if(iter != var_map.end())  
       				{
						// cout<<"Find, the type of the variable is "<<iter->second->type<<endl;  
						var = iter->second;
					}
					else
					{
						$$=(type_struct*)malloc(sizeof(type_struct));
						$$->error = true;
						yyerror("name is not defined");
					}
				}
				else
				{
				//不是列表的ID
					$$=(type_struct*)malloc(sizeof(type_struct));
					$$->error = true;
					yyerror("syntax error");////////////////
				}
				//取参数
				arg->type = 3;
				arg->error = false;
				arg->list_head = $5;
				//取方法
				if($1->type == 1) // id type//////////////
				{
					map<char*, void*>::iterator iter;
					for(iter = func_map.begin(); iter != func_map.end(); iter++)
					{
						if(strcmp(iter->first, $1->id) == 0)	
						{
							break;
						}
					}
					if(iter != func_map.end())  
       				{
						// cout<<"Find, the type of the variable is "<<iter->second->type<<endl;  
						func = iter->second;
					}
					else
					{
						$$=(type_struct*)malloc(sizeof(type_struct));
						$$->error = true;
						yyerror("function is not declared");////////////////
					}
					
					
				}
				else
				{
					$$=(type_struct*)malloc(sizeof(type_struct));
					$$->error = true;
					yyerror("syntax error");////////////////
				}
				(*func)(var, arg);
				$$=(type_struct*)malloc(sizeof(type_struct));
				$$->error = false; 
				$$->type = 5;    
			}
		}
        | atom_expr  '(' arglist opt_comma ')'					/*函数（含参）*/
		{
			void *func;
			if($1->error || $3->error)
			{
				$$=(type_struct*)malloc(sizeof(type_struct));
				$$->error = true;
			}
			else
			{
				if($1->type == 1) // id type//////////////
				{
					map<char*, void*>::iterator iter;
					for(iter = func_map.begin(); iter != func_map.end(); iter++)
					{
						if(strcmp(iter->first, $1->id) == 0)	
						{
							break;
						}
					}
					if(iter != func_map.end())  
       				{
						// cout<<"Find, the type of the variable is "<<iter->second->type<<endl;  
						func = iter->second;
						$$=(type_struct*)malloc(sizeof(type_struct));
						$$->error = false; 
						(*func)($3);      //不确定这样是否可以
						$$->type = 5;     // void
					}
					else
					{
						$$=(type_struct*)malloc(sizeof(type_struct));
						$$->error = true;
						yyerror("function is not declared");////////////////
					}
					
				}
				else
				{
					$$=(type_struct*)malloc(sizeof(type_struct));
					$$->error = true;
					yyerror("syntax error");////////////////
				}
			}
		}
        | atom_expr  '('  ')'									/*函数（不含参）*/
		{
			void *func;
			if($1->error)
			{
				$$ = $1;
			}
			else
			{
				if($1->type == 1) // id type//////////////
				{
					map<char*, void*>::iterator iter;
					for(iter = func_map.begin(); iter != func_map.end(); iter++)
					{
						if(strcmp(iter->first, $1->id) == 0)	
						{
							break;
						}
					}
					if(iter != func_map.end())  
       				{
						// cout<<"Find, the type of the variable is "<<iter->second->type<<endl;  
						func = iter->second;
						$$=(type_struct*)malloc(sizeof(type_struct));
						$$->error = false; 
						(*func)();      //不确定这样是否可以
						$$->type = 5;     // void
					}
					else
					{
						$$=(type_struct*)malloc(sizeof(type_struct));
						$$->error = true;
						yyerror("function is not declared");////////////////
					}
					
				}
				else
				{
					$$=(type_struct*)malloc(sizeof(type_struct));
					$$->error = true;
					yyerror("syntax error");////////////////
				}
			}
		}
        ;
arglist: add_expr
	  {
		if($1->error)
		{
			$$ = (list_struct*)malloc(sizeof(list_struct));
			$$->error = true;
		}
		else
		{
			$$ = (list_struct*)malloc(sizeof(list_struct));
			$$->error = false;
			$$->list_vec=new vector<type_struct*>;
			$$->list_vec->push_back($1);
		}
		
	  }
      | arglist ',' add_expr 
	  {
		if($3->error)
		{
			$$=(list_struct*)malloc(sizeof(list_struct));
			$$->error = true; 
		}
		else
		{
			$1->list_vec->push_back($3);
			$$ = $1;
		}
		
	  }
      ;
   
List  : '[' ']'
		{
			$$ = (list_struct*)malloc(sizeof(list_struct));
			$$->error = false;
			$$->list_vec=new vector<type_struct*> ();
		}
      | '[' List_items opt_comma ']' 
	  {
		  if($2->error)
		  {
			$$ = (list_struct*)malloc(sizeof(list_struct));
			$$->error = true;
		  }
		  else
		  	$$ = $2;
	  }
      ;
opt_comma : /*  empty production */
          | ','
          ;
List_items  
      : add_expr
	  {
		if($1->error)
		{
			$$ = (list_struct*)malloc(sizeof(list_struct));
			$$->error = true;
		}
		else
		{
			$$ = (list_struct*)malloc(sizeof(list_struct));
			$$->error = false;
			$$->list_vec=new vector<type_struct*>;
			$$->list_vec->push_back($1);
		}
		
	  }
      | List_items ',' add_expr 
	  {
		if($3->error)
		{
			$$=(list_struct*)malloc(sizeof(list_struct));
			$$->error = true; 
		}
		else
		{
			$1->list_vec->push_back($3);
			$$ = $1;
		}
		
	  }
      ;
add_expr : add_expr '+' mul_expr
		{
			if($1->error || $3->error)
			{
				$$=(type_struct*)malloc(sizeof(type_struct));
				$$->error = true;
			}
			else
			{
			switch($1->type){
				case 0:{	/*number*/
					switch($3->type){
						case 0:{
							num_struct* num1 = $1->num;
							num_struct* num3 = $3->num;
							if(num1->type == 1 && num3->type == 1)
							{
								num1->f_value = num1->f_value + num3->f_value;
							}
							else if(num1->type == 0 && num3->type == 1)
							{
								//全都变成float
								num1->f_value = (float)num1->int_value + num3->f_value;
								num1->type = 1;
							}
							else if(num1->type == 1 && num3->type == 0)
							{
								num1->f_value = num1->f_value + (float)num3->int_value;
							}
							else
							{
								num1->int_value = num1->int_value + num3->int_value;
							}
							$$ = $1;
							break;
						}			
						default:{
							$$=(type_struct*)malloc(sizeof(type_struct));
							$$->error = true;
							yyerror("type error");
							break;
						}
					}
					break;
				}
				case 3:{
					if($3->type != 3){
						$$=(type_struct*)malloc(sizeof(type_struct));
						$$->error = true;
						yyerror("TypeError, unsupported operand type(s) for +: 'int' and 'list'"); //"uncompleted
					}
					else
					{
						$$ = (type_struct*)malloc(sizeof(type_struct));
						$$->type = 3;
						$$->list_head = (list_struct*)malloc(sizeof(list_struct));
						vector<type_struct*> newvec;
						newvec.insert(newvec.end(),$1->list_head->list_vec->begin(),$1->list_head->list_vec->end());
						newvec.insert(newvec.end(),$3->list_head->list_vec->begin(),$3->list_head->list_vec->end());
						$$->list_head->list_vec = (vector<type_struct*>*)&newvec;
					}
					break;
				}
				default:{
					$$=(type_struct*)malloc(sizeof(type_struct));
					$$->error = true;
					yyerror("type error");
				}
			}
			}
		}
	      |  add_expr '-' mul_expr
		{	
			if($1->error || $3->error)
			{
				$$=(type_struct*)malloc(sizeof(type_struct));
				$$->error = true;
			}
			else
			{
			switch($1->type){
				case 0:{	/*number*/
					switch($3->type){
						case 0:{
							num_struct* num1 = $1->num;
							num_struct* num3 = $3->num;
							if(num1->type == 1 && num3->type == 1)
							{
								num1->f_value = num1->f_value - num3->f_value;
							}
							else if(num1->type == 0 && num3->type == 1)
							{
								//全都变成float
								num1->f_value = (float)num1->int_value - num3->f_value;
								num1->type = 1;
							}
							else if(num1->type == 1 && num3->type == 0)
							{
								num1->f_value = num1->f_value - (float)num3->int_value;
							}
							else
							{
								num1->int_value = num1->int_value - num3->int_value;
							}
							$$ = $1;
							break;
						}
						default:{
							$$=(type_struct*)malloc(sizeof(type_struct));
							$$->error = true;
							yyerror("type error");
						}
					}
					break;
				}
				default:{
					$$=(type_struct*)malloc(sizeof(type_struct));
					$$->error = true;
					yyerror("type error");
				}
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
			if($1->error || $3->error)
			{
				$$=(type_struct*)malloc(sizeof(type_struct));
				$$->error = true;
			}
			else
			{
			switch($1->type){
				case 0:{	/*number*/
					switch($3->type){
						case 0:{
							num_struct* num1 = $1->num;
							num_struct* num3 = $3->num;
							if(num1->type == 1 && num3->type == 1)
							{
								num1->f_value = num1->f_value * num3->f_value;
							}
							else if(num1->type == 0 && num3->type == 1)
							{
								//全都变成float
								num1->f_value = (float)num1->int_value * num3->f_value;
								num1->type = 1;
							}
							else if(num1->type == 1 && num3->type == 0)
							{
								num1->f_value = num1->f_value * (float)num3->int_value;
							}
							else
							{
								num1->int_value = num1->int_value * num3->int_value;
							}
							$$ = $1;
							break;
						}
						default:{
							$$=(type_struct*)malloc(sizeof(type_struct));
							$$->error = true;
							yyerror("type error");
						}
					}
					break;
				}
				case 3:{
					if($3->type != 0 || $3->num->type != 0)
					{
						$$=(type_struct*)malloc(sizeof(type_struct));
						$$->error = true;
						yyerror("can't multiply sequence by non-int of type 'list'");
					}
					else
					{
						int i,mul=$3->num->int_value;
						$$ = (type_struct*)malloc(sizeof(type_struct));
						$$->type = 3;
						$$->list_head = (list_struct*)malloc(sizeof(list_struct));
						vector<type_struct*> newvec;
						for(i=0;i<mul;i++)
						{
							newvec.insert(newvec.end(),$1->list_head->list_vec->begin(),$1->list_head->list_vec->end());
						}
						$$->list_head->list_vec = (vector<type_struct*>*)&newvec;
						break;
					}	
					
				}
				default:{
					$$=(type_struct*)malloc(sizeof(type_struct));
					$$->error = true;
					yyerror("type error");
				}
			}
			}
		}
        |  mul_expr '/' factor
		{
			if($1->error || $3->error)
			{
				$$=(type_struct*)malloc(sizeof(type_struct));
				$$->error = true;
			}
			else
			{
			switch($1->type){
				case 0:{	/*number*/
					switch($3->type){
						case 0:{
							num_struct* num1 = $1->num;
							num_struct* num3 = $3->num;
							if(num1->type == 1 && num3->type == 1)
							{
								if(num3->f_value == 0)
								{
									$$=(type_struct*)malloc(sizeof(type_struct));
									$$->error = true;
									yyerror("can't divide by 0.0");
								}
									
								num1->f_value = num1->f_value / num3->f_value;
							}
							else if(num1->type == 0 && num3->type == 1)
							{
								//全都变成float
								if(num3->f_value == 0)
								{
									$$=(type_struct*)malloc(sizeof(type_struct));
									$$->error = true;
									yyerror("can't divide by 0.0");
								}
									
								num1->f_value = (float)num1->int_value / num3->f_value;
								num1->type = 1;
							}
							else if(num1->type == 1 && num3->type == 0)
							{
								if(num3->int_value == 0)
								{
									$$=(type_struct*)malloc(sizeof(type_struct));
									$$->error = true;
									yyerror("can't divide by 0");
								}
									
								num1->f_value = num1->f_value / (float)num3->int_value;
							}
							else
							{
								if(num3->int_value == 0)
								{
									$$=(type_struct*)malloc(sizeof(type_struct));
									$$->error = true;
									yyerror("can't divide by 0");
								}
									
								num1->int_value = num1->int_value / num3->int_value;
							}
							$$ = $1;
							break;
						}
						default:{
							$$=(type_struct*)malloc(sizeof(type_struct));
							$$->error = true;
							yyerror("type error");
						}
					}
					break;
				}
				default:{
					$$=(type_struct*)malloc(sizeof(type_struct));
					$$->error = true;
					yyerror("type error");
				}
			}
			}
		}
		|  mul_expr '%' factor
		{
			if($1->error || $3->error)
			{
				$$=(type_struct*)malloc(sizeof(type_struct));
				$$->error = true;
			}
			else
			{
			switch($1->type){
				case 0:{	/*number*/
					switch($3->type){
						case 0:{
							num_struct* num1 = $1->num;
							num_struct* num3 = $3->num;
							if(num1->type == 0 && num3->type == 0)
							{
								if(num3->int_value == 0)
								{
									$$=(type_struct*)malloc(sizeof(type_struct));
									$$->error = true;
									yyerror("can't mod by 0");
								}
									
								num1->int_value = num1->int_value % num3->int_value;
							}
							else{
								$$=(type_struct*)malloc(sizeof(type_struct));
								$$->error = true;
								yyerror("please input 'int' '%' 'int'");
							}
							$$ = $1;
							break;
						}
						default:{
							$$=(type_struct*)malloc(sizeof(type_struct));
							$$->error = true;
							yyerror("type error");
						}
					}
					break;
				}
				default:{
					$$=(type_struct*)malloc(sizeof(type_struct));
					$$->error = true;
					yyerror("type error");
				}
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