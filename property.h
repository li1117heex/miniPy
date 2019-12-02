#ifndef _PROPERTY_H_
#define _PROPERTY_H_

#include <iostream>
#include <map>
#include <string.h>
#include <vector>
using namespace std;

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
	vector<type_struct*>* list_vec; //在链表赋值的时候，变量的值直接取出
}list_struct;
//链表带索引
typedef struct list_index
{
	int index;
	vector<type_struct*>* list_vec; //在链表赋值的时候，变量的值直接取出
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
static map<char*, type_struct*> var_map;

//functions

//打印type_struct可能包含的类型的对象
void printobj(type_struct* obj);

//TODO: 这个函数是干什么的？
//uncompleted
char* type(type_struct* obj);

/*
 * 对列表进行浅拷贝
 * 对不可更改对象(数值,字符串)重新创建内存空间(深拷贝)
 */
void shallowcopy(type_struct* src,type_struct* dest);

void append(type_struct* list,type_struct* item);

void extend(type_struct* list1,type_struct* list2);

int len(type_struct* list);

#endif
