%{
/* definition */
#include <stdio.h>
#include <ctype.h>
using namespace std;
#include <iostream>
#include <string>
#include <cstring>
#include "lex.yy.c"
#include "property.h"

//变量表
map<char*, type_struct*> var_map;
//输出使能(true为可以输出)
bool output = true;
//错误标志
bool error_flag = false;

int yyparse(void);
void yyerror(char *s)
{
	if(!error_flag)
 	{
		cout << "error: " << s << endl;
		error_flag = true;
	}
}
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
	{
	}
      | Lines  '\n' prompt
      |
      | error '\n' {yyerrok;}
      ;
prompt : {cout << "miniPy> ";}
       ;
stat  : assignExpr
	{
		if(output && !error_flag)
			print_($1);
		output = true;
		error_flag = false;
		$$ = $1;
	}
      ;
assignExpr:
        atom_expr '=' assignExpr
		{			
			if($1->type == 1)	/*ID，存储变量到变量表*/
			{	
				map<char*, type_struct*>::iterator iter;
				if(!error_flag)
				{
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
				}
				
				if(!error_flag)
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
			else if($1->type == 6)
			{
				if($3->type!=3)
				{
					yyerror("can only assign an iterable");
				}
				else
				{
					int i,newsize=0;
					int firstindex=$1->List_Slice->firstindex;
					int lastindex=$1->List_Slice->lastindex;
					int indexstep=$1->List_Slice->indexstep;
					int size = $1->List_Slice->list_vec->size();
					bool steppn=indexstep>0;
					if((firstindex-lastindex)*indexstep<0) //只有步长与目标同向才非空表
						for(i=firstindex;(steppn && i<lastindex && i<size)||(!steppn && i>lastindex && i>-1);i+=indexstep)
						{
							newsize++;
						}
					if($3->list_head->list_vec->size()!=newsize)
						yyerror("attempt to assign sequence to extended slice of different size");
					else
					{
						$$=$3;
						int j=0;
						if((firstindex-lastindex)*indexstep<0) //只有步长与目标同向才非空表
							for(i=firstindex;(steppn && i<lastindex && i<size)||(!steppn && i>lastindex && i>-1);i+=indexstep)
							{
								$1->List_Slice->list_vec->at(i)=($3->list_head->list_vec->at(j++));
							}
					}
				}
			}
			else
			{
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
				yyerror("'+ factor' must use number type!");
			$$ = $2;			
		}
       | '-' factor	%prec unimus
	   {
			if($2->type != 0)
				yyerror("'- factor' must use number type!");
			else{
				if($2->num->type == 0)
					$2->num->int_value = -$2->num->int_value;
				else
					$2->num->f_value = -$2->num->f_value;
			}
		   	$$ = $2;
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
					yyerror("name is not defined");
				}
			}
			else if($1->type == 4)
			{
				$$=(type_struct*)malloc(sizeof(type_struct));
				shallowcopy($1->List_Index->list_vec->at($1->List_Index->index),$$);
			}
			else if($1->type == 6)
			{
				$$=new type_struct;
				$$->type=3;
				$$->list_head=new list_struct;
				$$->list_head->list_vec = new vector<type_struct*>;
				int i;
				int firstindex=$1->List_Slice->firstindex;
				int lastindex=$1->List_Slice->lastindex;
				int indexstep=$1->List_Slice->indexstep;
				int size = $1->List_Slice->list_vec->size();
				bool steppn=indexstep>0;
				if((firstindex-lastindex)*indexstep<0) //只有步长与目标同向才非空表
					for(i=firstindex;(steppn && i<lastindex && i<size)||(!steppn && i>lastindex && i>-1);i+=indexstep)
					{
						$$->list_head->list_vec->push_back($1->List_Slice->list_vec->at(i));
					}
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
		  $$->id = yylval.name;
		}
      | STRING_LITERAL
	  {
		$$ = (type_struct*)malloc(sizeof(type_struct));
		$$->type = 2;
		$$->str = yylval.name;
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
		{
			$$=NULL;
		}
        | ':' add_expr 
		{
			if($2->type != 0 || $2->num->type != 0)
				yyerror("index must be int type!"); 
			else if($2->num->int_value == 0)
				yyerror("slice step cannot be zero"); 
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
				yyerror("index must be int type!"); 
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

			if($1->type != 1 && $1->type != 4 && $1->type != 6)
			{
				var = $1;
			}
			else if($1->type == 4)
			{
				var = $1->List_Index->list_vec->at($1->List_Index->index);
			}
			else if($1->type == 6)
			{
				var=new type_struct;
				var->type=3;
				var->list_head=new list_struct;
				var->list_head->list_vec = new vector<type_struct*>;
				int i;
				int firstindex=$1->List_Slice->firstindex;
				int lastindex=$1->List_Slice->lastindex;
				int indexstep=$1->List_Slice->indexstep;
				int size = $1->List_Slice->list_vec->size();
				bool steppn=indexstep>0;
				if((firstindex-lastindex)*indexstep<0) //只有步长与目标同向才非空表
					for(i=firstindex;(steppn && i<lastindex && i<size)||(!steppn && i>lastindex && i>-1);i+=indexstep)
					{
						var->list_head->list_vec->push_back($1->List_Slice->list_vec->at(i));
					}
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
					yyerror("name is not defined");
				}  
			}

			if(var->type == 0 || var->type == 1 || var->type == 5)
				yyerror("the object must be a list or string");
			else if(var->type == 2)
			{
				int size = strlen(var->str);
				indexstep = $6 == NULL?1:$6->num->int_value;
				firstindex = $3 == NULL?(indexstep>0?0:size-1)
				:($3->num->int_value>=0?$3->num->int_value:$3->num->int_value+size);
				lastindex = $5 == NULL?(indexstep>0?size:-1)
				:($5->num->int_value>=0?$5->num->int_value:$5->num->int_value+size); //-1是为了取完list
				$$ = (type_struct*)malloc(sizeof(type_struct));
				$$->type=2;
				$$->str=(char*)malloc(size+1);
				int i,j=0;
				char* place=$$->str;
				bool steppn=indexstep>0;
				if((firstindex-lastindex)*indexstep<0) //只有步长与目标同向才非空表
					for(i=firstindex;(steppn && i<lastindex && i<size)||(!steppn && i>lastindex && i>-1);i+=indexstep)
					{
						strncpy(place,var->str+i,1);
						place++;
					}
				*place='\0';
			}
			else if($3 != NULL && ($3->type != 0 || $3->num->type != 0))
			{
				yyerror("firstindex must be int type!");
			}
			else if($5 != NULL && ($5->type != 0 || $5->num->type != 0))
			{
				yyerror("lastindex must be int type!");
			}
			else if($6 != NULL && ($6->type != 0 || $6->num->type != 0))
			{
				yyerror("indexstep must be int type!");
			}
			else
			{
				int size = var->list_head->list_vec->size();
				indexstep = $6 == NULL?1:$6->num->int_value;
				firstindex = $3 == NULL?(indexstep>0?0:size-1)
				:($3->num->int_value>=0?$3->num->int_value:$3->num->int_value+size);
				lastindex = $5 == NULL?(indexstep>0?size:-1)
				:($5->num->int_value>=0?$5->num->int_value:$5->num->int_value+size); //-1是为了取完list

				/*$$=(type_struct*)malloc(sizeof(type_struct));
				$$->type=3;
				$$->list_head=(list_struct*)malloc(sizeof(list_struct));
				$$->list_head->list_vec = new vector<type_struct*>;
				int i;
				bool steppn=indexstep>0;
				if((firstindex-lastindex)*indexstep<0) //只有步长与目标同向才非空表
					for(i=firstindex;(steppn && i<lastindex && i<size)||(!steppn && i>lastindex && i>-1);i+=indexstep)
					{
						$$->list_head->list_vec->push_back(var->list_head->list_vec->at(i));
					}
				*/
				$$=new type_struct;;
				$$->type=6;
				$$->List_Slice = new list_slice;
				$$->List_Slice->firstindex = firstindex;
				$$->List_Slice->lastindex = lastindex;
				$$->List_Slice->indexstep = indexstep;
				$$->List_Slice->list_vec = var->list_head->list_vec;
			}
		}
        | atom_expr '[' add_expr ']'							/*列表取元素*/
		{
			type_struct* var;
			int index;

			if($1->type != 1 && $1->type != 4 && $1->type != 6)
			{
				var = $1;
			}
			else if($1->type == 4)
			{
				var = $1->List_Index->list_vec->at($1->List_Index->index);
			}
			else if($1->type == 6)
			{
				var=new type_struct;
				var->type=3;
				var->list_head=new list_struct;
				var->list_head->list_vec = new vector<type_struct*>;
				int i;
				int firstindex=$1->List_Slice->firstindex;
				int lastindex=$1->List_Slice->lastindex;
				int indexstep=$1->List_Slice->indexstep;
				int size = $1->List_Slice->list_vec->size();
				bool steppn=indexstep>0;
				if((firstindex-lastindex)*indexstep<0) //只有步长与目标同向才非空表
					for(i=firstindex;(steppn && i<lastindex && i<size)||(!steppn && i>lastindex && i>-1);i+=indexstep)
					{
						var->list_head->list_vec->push_back($1->List_Slice->list_vec->at(i));
					}
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
					yyerror("name is not defined");////////////////
				}  
			}

			if($3->type != 0 || $3->num->type != 0)
				yyerror("index must be int type!");
			else if(var->type == 0 || var->type == 1 || var->type == 5)
				yyerror("the object must be a list or string");//////////
			else if(var->type == 2)
			{
				index=$3->num->int_value>=0?$3->num->int_value:$3->num->int_value+strlen(var->str);
				if(index >=strlen(var->str) || index < 0 )
					yyerror("string index out of range");
				$$ = (type_struct*)malloc(sizeof(type_struct));
				$$->type=2;
				$$->str=(char*)malloc(2);
				strncpy($$->str,var->str+index,1);
				$$->str[1]='\0';
			}
			else //var->type == 3
			{
				index=$3->num->int_value>=0?$3->num->int_value:$3->num->int_value+var->list_head->list_vec->size();
				if(index >=var->list_head->list_vec->size() || index < 0 )
					yyerror("list index out of range");
				$$ = (type_struct*)malloc(sizeof(type_struct));
				$$->type=4;
				$$->List_Index = (list_index*)malloc(sizeof(list_index));
				$$->List_Index->index = index;
				$$->List_Index->list_vec = var->list_head->list_vec;
			}
		}
        | atom_expr  '.' atom '(' arglist opt_comma ')'			/*调用类方法*/
		{
			type_struct* (*pf)(list_struct*);
			type_struct *var;

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
					yyerror("name is not defined");
				}
			}
			else if($1->type == 0)
			{
				yyerror("number type has no attribute append");
			}
			else if($1->type == 2)
			{
				yyerror("string type has no attribute append");
			}
			else if($1->type == 5)
			{
				yyerror("void type has no attribute append");
			}
			else if($1->type == 3)
			{
				var = $1;
			}
			else if($1->type == 6)
			{
				var=new type_struct;
				var->type=3;
				var->list_head=new list_struct;
				var->list_head->list_vec = new vector<type_struct*>;
				int i;
				int firstindex=$1->List_Slice->firstindex;
				int lastindex=$1->List_Slice->lastindex;
				int indexstep=$1->List_Slice->indexstep;
				int size = $1->List_Slice->list_vec->size();
				bool steppn=indexstep>0;
				if((firstindex-lastindex)*indexstep<0) //只有步长与目标同向才非空表
					for(i=firstindex;(steppn && i<lastindex && i<size)||(!steppn && i>lastindex && i>-1);i+=indexstep)
					{
						var->list_head->list_vec->push_back($1->List_Slice->list_vec->at(i));
					}
			}
			else//$1->type == 4
			{
				var = $1->List_Index->list_vec->at($1->List_Index->index);
			}
			//取方法
			if($3->type == 1) // id type//////////////
			{
				map<char*, type_struct* (*)(list_struct*)>::iterator iter;
				for(iter = func_map.begin(); iter != func_map.end(); iter++)
				{
					if(strcmp(iter->first, $3->id) == 0)	
					{
						break;
					}
				}
				if(iter != func_map.end())  
				{
					// cout<<"Find, the type of the variable is "<<iter->second->type<<endl;  
					pf = iter->second;
					//取参数
					$5->list_vec->insert($5->list_vec->begin(), var);
					//调用
					$$ = pf($5);
				}
				else
				{
					yyerror("function is not declared");////////////////
				}
			}
			else
			{
				yyerror("function must have a name");////////////////
			}			
		}
        | atom_expr  '(' arglist opt_comma ')'					/*函数（含参）*/
		{
			type_struct* (*pf)(list_struct*);

			if($1->type == 1) // id type//////////////
			{
				map<char*, type_struct* (*)(list_struct*)>::iterator iter;
				for(iter = func_map.begin(); iter != func_map.end(); iter++)
				{
					if(strcmp(iter->first, $1->id) == 0)	
					{
						break;
					}
				}
				if(iter != func_map.end())  
				{
					pf = iter->second;
					$$ = pf($3);
				}
				else
				{
					yyerror("function is not declared");////////////////
				}
			}
			else
			{
				yyerror("function must have a name");////////////////
			}
		}
        | atom_expr  '('  ')'									/*函数（不含参）*/
		{
			type_struct* (*pf)(list_struct*);
			list_struct* args = new list_struct;
			args->list_vec = new vector<type_struct*>;	//empty list

			if($1->type == 1) // id type//////////////
			{
				map<char*, type_struct* (*)(list_struct*)>::iterator iter;
				for(iter = func_map.begin(); iter != func_map.end(); iter++)
				{
					if(strcmp(iter->first, $1->id) == 0)	
					{
						break;
					}
				}
				if(iter != func_map.end())  
				{
					pf = iter->second;
					$$ = pf(args);
				}
				else
				{
					yyerror("function is not declared");////////////////
				}
			}
			else
			{
				yyerror("function must have a name");////////////////
			}
		}
        ;
arglist: add_expr
	  {
		$$ = (list_struct*)malloc(sizeof(list_struct));
		$$->list_vec=new vector<type_struct*>;
		$$->list_vec->push_back($1);		
	  }
      | arglist ',' add_expr 
	  {
			$1->list_vec->push_back($3);
			$$ = $1;
	  }
      ;      
List  : '[' ']'
		{
			$$ = (list_struct*)malloc(sizeof(list_struct));
			$$->list_vec=new vector<type_struct*> ();
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
		$$->list_vec=new vector<type_struct*>;
		$$->list_vec->push_back($1);
	  }
      | List_items ',' add_expr 
	  {
		$1->list_vec->push_back($3);
		$$ = $1;
	  }
      ;
add_expr : add_expr '+' mul_expr
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
							yyerror("type error");
						}
					}
					break;
				}
				case 3:{
					if($3->type != 3)
						yyerror("TypeError, unsupported operand type(s) for +: 'int' and 'list'"); //"uncompleted
					else
					{
						$$ = (type_struct*)malloc(sizeof(type_struct));
						$$->type = 3;
						$$->list_head = (list_struct*)malloc(sizeof(list_struct));
						$$->list_head->list_vec = new vector<type_struct*>;
						$$->list_head->list_vec->insert(
							$$->list_head->list_vec->end(),$1->list_head->list_vec->begin(),$1->list_head->list_vec->end());
						$$->list_head->list_vec->insert(
							$$->list_head->list_vec->end(),$3->list_head->list_vec->begin(),$3->list_head->list_vec->end());
					}
					break;
				}
				case 2:{
					if($3->type != 2)
						yyerror("TypeError, unsupported operand type(s) for +: 'int' and 'str'");
					else
					{
						$$ = new type_struct;
						$$->type = 2;
						$$->str = (char*) malloc(strlen($1->str)+strlen($3->str)+1);
						strcpy($$->str,$1->str);
						strcpy($$->str+strlen($3->str),$3->str);
						$$->str[strlen($1->str)+strlen($3->str)] = '\0';
					}
					break;
				}
				default:{
					yyerror("type error");
				}
			}
		}
	      |  add_expr '-' mul_expr
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
							yyerror("type error");
						}
					}
					break;
				}
				default:{
					yyerror("type error");
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
							yyerror("type error");
						}
					}
					break;
				}
				case 3:{
					if($3->type != 0 || $3->num->type != 0)
						yyerror("can't multiply sequence by non-int of type 'list'");
					int i,mul=$3->num->int_value;
					$$ = (type_struct*)malloc(sizeof(type_struct));
					$$->type = 3;
					$$->list_head = (list_struct*)malloc(sizeof(list_struct));
					$$->list_head->list_vec = new vector<type_struct*>;
					for(i=0;i<mul;i++)
					{
						$$->list_head->list_vec->insert(
							$$->list_head->list_vec->end(),$1->list_head->list_vec->begin(),$1->list_head->list_vec->end());
					}
					break;
				}
				case 2:{
					if($3->type != 0 || $3->num->type != 0)
						yyerror("can't multiply sequence by non-int of type 'str'");
					$$ = new type_struct;
					$$->type = 2;
					$$->str = (char*) malloc($3->num->int_value*strlen($1->str)+1);
					int i;
					char* place = $$->str;
					for(i=0;i<$3->num->int_value;i++)
					{
						strcpy(place,$1->str);
						place+=strlen($1->str);
					}
					*place = '\0';
					break;
				}
				default:{
					yyerror("type error");
				}
			}
		}
        |  mul_expr '/' factor
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
									yyerror("can't divide by 0.0");
								num1->f_value = num1->f_value / num3->f_value;
							}
							else if(num1->type == 0 && num3->type == 1)
							{
								//全都变成float
								if(num3->f_value == 0)
									yyerror("can't divide by 0.0");
								num1->f_value = (float)num1->int_value / num3->f_value;
								num1->type = 1;
							}
							else if(num1->type == 1 && num3->type == 0)
							{
								if(num3->int_value == 0)
									yyerror("can't divide by 0");
								num1->f_value = num1->f_value / (float)num3->int_value;
							}
							else
							{
								if(num3->int_value == 0)
									yyerror("can't divide by 0");
								num1->int_value = num1->int_value / num3->int_value;
							}
							$$ = $1;
							break;
						}
						default:{
							yyerror("type error");
						}
					}
					break;
				}
				default:{
					yyerror("type error");
				}
			}
		}
		|  mul_expr '%' factor
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
									yyerror("can't divide by 0");
								num1->int_value = num1->int_value % num3->int_value;
							}
							else{
								yyerror("please input 'int' '%' 'int'");
							}
							$$ = $1;
							break;
						}
						default:{
							yyerror("type error");
						}
					}
					break;
				}
				default:{
					yyerror("type error");
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
	func_map_init();	
    return yyparse();
}