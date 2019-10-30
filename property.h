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