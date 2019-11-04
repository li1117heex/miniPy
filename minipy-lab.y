%{
/* definition */
#include <stdio.h>
#include <ctype.h>
using namespace std;
#include <iostream>
#include <string>
#include <map>
#include <vector>

#include "lex.yy.c"

extern "C" {
int yyparse(void);
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
struct type_struct;
typedef struct list_struct
{
	//int type;	//链表内内容类型，0:number, 2:string literal, 3:list （为了和type_struct保持一致）
	/*union
	{
		num_struct* num;
		char* str;
		list_struct* list_head;
	};
	list_struct* next;*/
	vector<type_struct*> list_vec; //在链表赋值的时候，变量的值直接取出
}list_struct;
//链表带索引
typedef struct list_index
{
	//int type;	//链表内内容类型，0:number, 2:string literal, 3:list （为了和type_struct保持一致）
	/*union
	{
		num_struct* num;
		char* str;
		list_struct* list_head;
	};
	list_struct* next;*/
	int index;
	vector<type_struct*> list_vec; //在链表赋值的时候，变量的值直接取出
}list_index;
//类型非终结符
typedef struct type_struct
{
	int type;	//0:number, 1:ID, 2:string literal, 3:list, 4:list_index
	union
	{
		num_struct* num;	//number
		char* id;			//id
		char* str;			//string literal
		list_struct* list_head;	//list
		list_index* List_Index;
	};
}type_struct;

//变量表
map<char*, type_struct*> var_map;

//list打印
void printobj(type_struct* obj){
	switch(obj->type){
			case 0:{
				if(obj->num->type == 0)
					printf("%d\n", obj->num->int_value);//w
				else
					printf("%.3f\n", obj->num->f_value);
				break;
			}
			case 1:{
				/*查找该ID*/
				//不可能，列表里无ID
				break;
			}
			case 2:{
				//print string
				printf("\"%s\"",obj->str);///////////////
				break;
			}
			case 3:{
				//print list
				vector<type_struct*>::iterator iter;
				iter=obj->list_head->list_vec.begin();
				printf("[");
				printobj(*iter);
				for(iter++;iter!=obj->list_head->list_vec.end();iter++)
				{
					printf(",");
					printobj(*iter);
				}
				printf("]");
				break;
			}
		}
}

char* type(type_struct* obj){//////////////////uncompleted
	switch(obj->type){
			case 0:{
				
				break;
			}
			case 1:{
				
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

void shallowcopy(type_struct* src,type_struct* dest){
	switch(src->type){
		case 0:{
			dest->num=(num_struct*)malloc(sizeof(num_struct));
			if(src->num->type == 0)
				dest->num->int_value = src->num->int_value;
			else
				dest->num->f_value = src->num->f_value;
			break;
		}
		case 1:{
			//impossible
			break;
		}
		case 2:{
			dest->str=(char*)malloc(strlen(src->str)+1);
			strcpy(dest->str,src->str);
			break;
		}
		case 3:{
			dest->list_head = src->list_head;
			break;
		}
	}
	dest->type = src->type;
}

void append(type_struct* list,type_struct* item){
	if(list->type != 3 || item->type == 1)
	{
		yyerror("append error");
	}
	else
	{
		list->list_head->list_vec.push_back(item);
	}
}

void extend(type_struct* list1,type_struct* list2){
	if(list1->type != 3 || list2->type != 3)
	{
		yyerror("append error");
	}
	else
	{
		list1->list_head->list_vec.insert(list1->list_head->list_vec.end(),list2->list_head->list_vec.begin(),list2->list_head->list_vec.end());
	}
}

int len(type_struct* list){
	if(list->type == 0 || list->type == 1)
		yyerror("object of this type has no len()");
	else if(list->type == 2)
	{
		return strlen(list->str);
	}
	else
	{
		return list->list_head->list_vec.size();
	}
}

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
		$$ = $1;
		switch($$->type){
			case 0:{
				if($$->num->type == 0)
					printf("%d\n", $$->num->int_value);//w
				else
					printf("%.3f\n", $$->num->f_value);
				break;
			}
			case 1:{
				/*查找该ID*/////////////////////////////////////////////////
				map<char*, type_struct*>::iterator iter;
				iter = var_map.find($1->id);
				if(iter != var_map.end())
					printobj(iter->second);
				else
				{
					yyerror("name is not defined");
				}
				break;
			}
			case 2:{
				//print string
				printf("\"%s\"",$$->str);
				break;
			}
			case 3:{
				//print list
				vector<type_struct*>::iterator iter;
				for(iter=$$->list_head->list_vec.begin();iter!=$$->list_head->list_vec.end();iter++)
				break;
			}
		}
	  }
      ;
assignExpr:
        atom_expr '=' assignExpr
		{			
			if($1->type == 1)	/*ID，存储变量到变量表*/
			{	
				map<char*, type_struct*>::iterator iter;//可以用count来写
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
				var_map.insert(map<char*, type_struct*>::value_type($1->id, $3));  //存储原来的，上交浅拷贝的
				shallowcopy($3,$1);
				$$ = $1;
			}
			else if($1->type == 4)
			{
				/*while(($1->list_head->list_vec[$1->list_head->index])->list_head->flag==1)
				{
					$1=$1->list_head->list_vec[$1->list_head->index];
				}
				shallowcopy($3,$1->list_head->list_vec[$1->list_head->index]);
				$$ = $1->list_head->list_vec[$1->list_head->index];*/
				$1->List_Index->list_vec[$1->List_Index->index] = $3;    //存储原来的，上交浅拷贝的
				shallowcopy($3,$1);
				$$ = $1;
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
		    $$ = $1;//设计理念：所有高于atom_expr的ID都已经把值取出        //应该讨论：要不要设计新数据结构，type不能为ID////////////
			if($$->type == 1)
			{
				map<char*, type_struct*>::iterator iter;
				iter = var_map.find($1->id);
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
				/*while(($1->list_head->list_vec[$1->list_head->index])->list_head->flag==1)
				{
					$1=$1->list_head->list_vec[$1->list_head->index];
				}
				$$=(type_struct*)malloc(sizeof(type_struct));
				shallowcopy($1->list_head->list_vec[$1->list_head->index],$$);*/

				$$=(type_struct*)malloc(sizeof(type_struct));
				shallowcopy($1->List_Index->list_vec[$1->List_Index->index],$$);
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
		{
			$$=NULL;
		}
        | ':' add_expr 
		{
			$$ = $2;
			if($$->type != 0 || $$->num->type != 0)
				yyerror("index must be int type!"); 
			else if($$->num->int_value == 0)
				yyerror("slice step cannot be zero"); 
		}
        ;
sub_expr:  /*  empty production */
		{
			$$=NULL;
		}
        | add_expr
		{
			$$ = $1;
			if($$->type != 0 || $$->num->type != 0)
				yyerror("index must be int type!"); 
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

			if($1->type == 0)
			{
				yyerror("TypeError: 'int' object is not subscriptable");   ////////////////////////////"
			}
			else if($1->type == 2 || $1->type == 3)
			{
				var = $1;
			}
			else if($1->type == 4)
			{
				var = $1->List_Index->list_vec[$1->List_Index->index];
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
					yyerror("name is not defined");
				}  
			}

			if(var->type == 0 || var->type == 1)
				yyerror("the object must be a list or string");
			else if(var->type == 2)
				yyerror("string complex slice not support yet"); //not support yet
			else
			{
				int size = var->list_head->list_vec.size();
				indexstep = $6 == NULL?1:$6->num->int_value;
				firstindex = $3 == NULL?(indexstep>0?0:size-1)
				:($3->num->int_value>=0?$3->num->int_value:$3->num->int_value+size);
				lastindex = $5 == NULL?(indexstep>0?size:-1)
				:($5->num->int_value>=0?$5->num->int_value:$5->num->int_value+size); //-1是为了取完list

				vector<type_struct*> newvec;
				int i;
				if((firstindex-lastindex)*indexstep<0) //只有步长与目标同向才非空表
					for(i=firstindex;i<lastindex && i<size && i>-1;i+=indexstep)
						newvec.push_back(var->list_head->list_vec[i]);
				$$=(type_struct*)malloc(sizeof(type_struct));
				$$->type=3;
				$$->list_head=(list_struct*)malloc(sizeof(list_struct));
				$$->list_head->list_vec=newvec;
			}
		}
        | atom_expr  '[' add_expr ']'							/*列表取元素*/
		{
			type_struct* var;
			int index;

			if($1->type != 1 && $1->type != 4)
			{
				var = $1;
			}
			else if($1->type == 4)
			{
				var = $1->List_Index->list_vec[$1->List_Index->index];
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
					yyerror("name is not defined");////////////////
				}  
			}

			if($3->type != 0 || $3->num->type != 0)
				yyerror("index must be int type!");
			/*else if($3->num->int_value < 0)
				yyerror("index must >0 !");*/ /////////////////////
			else if(var->type == 0 || var->type == 1)
				yyerror("the object must be a list or string");//////////
			else if(var->type == 2)
			{
				index=$3->num->int_value>=0?$3->num->int_value:$3->num->int_value+strlen(var->str);
				if(index >=strlen(var->str) || index < 0 )
					yyerror("string index out of range");
				$$ = (type_struct*)malloc(sizeof(type_struct));
				$$->type=2;
				$$->str=(char*)malloc(2);
				strncpy(var->str+index,$$->str,1);
				$$->str[1]='\0';
			}
			else //var->type == 3
			{
				index=$3->num->int_value>=0?$3->num->int_value:$3->num->int_value+var->list_head->list_vec.size();
				if(index >=var->list_head->list_vec.size() || index < 0 )
					yyerror("string index out of range");
				//$$ = var->list_head->list_vec[index];  //vec存的是指针，直接赋值
				//var->flag =1;
				//var->index = index;
				$$ = (type_struct*)malloc(sizeof(type_struct));
				$$->type=4;
				$$->List_Index = (list_index*)malloc(sizeof(list_index));
				$$->List_Index->index = index;
				$$->List_Index->list_vec = var->list_head->list_vec;

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
			$$->list_vec=vector<type_struct*> ();
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
		$$->list_vec=vector<type_struct*> (1);
		/*if($1->type == 1) //impossible
		{
			map<char*, type_struct*>::iterator iter;
			iter = var_map.find($1->id);
			if(iter != var_map.end())
				$$=(type_struct*)malloc(sizeof(type_struct));
				shallowcopy(iter->second,$$);
			else
			{
				yyerror(sprintf("name '%s' is not defined",$1->id));
			}
		}*/
		$$->list_vec.push_back($1);
	  }
      | List_items ',' add_expr 
	  {
		$$ = $1;
		/*if($3->type == 1)         //impossible
			map<char*, type_struct*>::iterator iter;
			iter = var_map.find($1->id);
			if(iter != var_map.end())
				$$=(type_struct*)malloc(sizeof(type_struct));
				shallowcopy(iter->second,$$);
			else
			{
				yyerror(sprintf("name '%s' is not defined",$1->id));
			}*/	
		$$->list_vec.push_back($3);
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
				case 3:{
					if(3!=$3->type)
						yyerror("TypeError: unsupported operand type(s) for +: 'int' and 'list'"); //"uncompleted
					else
					{
						$$ = (type_struct*)malloc(sizeof(type_struct));
						$$->type = 3;
						$$->list_head = (list_struct*)malloc(sizeof(list_struct));
						vector<type_struct*> newvec($1->list_head->list_vec.size()+$3->list_head->list_vec.size());
						newvec.insert(newvec.end(),$1->list_head->list_vec.begin(),$1->list_head->list_vec.end());
						newvec.insert(newvec.end(),$3->list_head->list_vec.begin(),$3->list_head->list_vec.end());
						$$->list_head->list_vec = newvec;
					}
					break;
				}
			}
			/*if($1->type!=$3->type)
				yyerror("TypeError: unsupported operand type(s) for +: 'int' and 'list'") //uncompleted
			else
			{
				switch($1->type){
					case 0:{
						//uncompleted//可以传指针
						break;
					}
					case 1:{
						//impossible
						break;
					}
					case 2:{
						//uncompleted
						break;
					}
					case 3:{
						$$ = (type_struct*)malloc(sizeof(type_struct));
						$$->type = 3;
						$$->list_head = (list_struct*)malloc(sizeof(list_struct));
						vector<type_struct*> newvec($1->list_head->list_vec.size()+$3->list_head->list_vec.size());
						newvec.insert(newvec.end(),$1->list_head->list_vec.begin(),$1->list_head->list_vec.end());
						newvec.insert(newvec.end(),$3->list_head->list_vec.begin(),$3->list_head->list_vec.end());
						$$->list_head->list_vec = newvec;
						break;
					}
				}
			}*/
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
				case 3:{
					if($3->type != 0 || $3->num->type != 0)
						yyerror("can't multiply sequence by non-int of type 'list'");
					int i,mul=$3->num->int_value;
					$$ = (type_struct*)malloc(sizeof(type_struct));
					$$->type = 3;
					$$->list_head = (list_struct*)malloc(sizeof(list_struct));
					vector<type_struct*> newvec($1->list_head->list_vec.size()*mul);
					for(i=0;i<mul;i++)
					{
						newvec.insert(newvec.end(),$1->list_head->list_vec.begin(),$1->list_head->list_vec.end());
					}
					$$->list_head->list_vec = newvec;
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
