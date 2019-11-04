/*文法符号属性设计*/
#ifndef _PROPERTY_H_
#define _PROPERTY_H_

#include <map>

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

typedef struct list_struct list_struct;

//链表结点非终结符
typedef struct list_node
{
	int type;	//链表内内容类型，0:number, 2:string literal, 3:list （为了和type_struct保持一致）
	union
	{
		num_struct* num;
		char* str;
		list_struct* list;
	};
	list_struct* next;
}list_node;

//链表非终结符
typedef struct list_struct
{
    list_node* list_head;
    list_node* list_tail;
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
		list_struct* list;   //list
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
				printf("\"%s\""，obj->str);///////////////
				break;
			}
			case 3:{
				//print list
				vector<*type_struct>::iterator iter;
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

void len(type_struct* list){
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

/*
文法符号类型声明
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
*/
#endif