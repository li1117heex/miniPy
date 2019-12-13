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
//链表带区间索引
typedef struct list_slice
{
	int firstindex,lastindex,indexstep;
	vector<type_struct*>* list_vec; //在链表赋值的时候，变量的值直接取出
}list_slice;
//类型非终结符
typedef struct type_struct
{
	int type;	//0:number, 1:ID, 2:string literal, 3:list, 4:list_index, 5:void, 6:list_slice
	union
	{
		num_struct* num;	//number
		char* id;			//id
		char* str;			//string literal
		list_struct* list_head;	//list
		list_index* List_Index;
		list_slice* List_Slice;
	};
}type_struct;

//变量表
extern map<char*, type_struct*> var_map;

//函数表
extern map<char*, type_struct* (*)(list_struct*)> func_map;

//functions

//protected
/*
 * 对列表进行浅拷贝
 * 对不可更改对象(数值,字符串)重新创建内存空间(深拷贝)
 */ 
void shallowcopy(type_struct* src,type_struct* dest);

//初始化func_map
void func_map_init();

//public
//打印type_struct可能包含的类型的对象
//type_struct* -> void
void print_(type_struct* obj);
type_struct* print(list_struct* args);

//TODO: 这个函数是干什么的？
//uncompleted
//void type(type_struct* obj)
type_struct* type(list_struct* args);

//void append(type_struct* list,type_struct* item);
type_struct* append(list_struct* args);

//void extend(type_struct* list1,type_struct* list2);
type_struct* extend(list_struct* args);

//int len(type_struct* list);
type_struct* len(list_struct* args);

type_struct* quit(list_struct* args);

type_struct* list(list_struct* args);

type_struct* range(list_struct* args);
#endif
