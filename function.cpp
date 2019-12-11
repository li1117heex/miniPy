#include <stdio.h>
#include <ctype.h>
using namespace std;

#include "property.h"

extern void yyerror(char *s);
extern bool output;

//函数表
map<char*, type_struct* (*)(list_struct*)> func_map;

void func_map_init()
{
	cout << "initializing function map..." << endl;
	func_map.insert(map<char*, type_struct*(*)(list_struct*)>::value_type("print", print));
	func_map.insert(map<char*, type_struct*(*)(list_struct*)>::value_type("append", append));
	func_map.insert(map<char*, type_struct*(*)(list_struct*)>::value_type("len", len));
	func_map.insert(map<char*, type_struct*(*)(list_struct*)>::value_type("quit", quit));
	func_map.insert(map<char*, type_struct*(*)(list_struct*)>::value_type("list", list));
	func_map.insert(map<char*, type_struct*(*)(list_struct*)>::value_type("range", range));
	map<char*, type_struct* (*)(list_struct*)>::iterator iter;

	cout << "function completed:" << endl;
	for(iter = func_map.begin(); iter != func_map.end(); iter++)
	{
		cout << iter->first << endl;
	}
}

void printobj_1line_(type_struct* obj)
{
	switch(obj->type){
		case 0:{
			if(obj->num->type == 0)
				printf("%d", obj->num->int_value);//w
			else
				printf("%.3f", obj->num->f_value);
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
			iter=obj->list_head->list_vec->begin();
			if(obj->list_head->list_vec->empty())
			{
				printf("[]");
			}
			else
			{
				printf("[");
				for(iter=obj->list_head->list_vec->begin();iter!=obj->list_head->list_vec->end();iter++)
				{
					printobj_1line_(*iter);
					printf(",");
				}
				printf("\b]");
			}
			break;
		}
		case 4:{
			//impossible, List_Index只是一个临时类型，不会出现在add_expr中
			break;
		}
		default:
			break;
	}
}

void print_(type_struct* obj){
	switch(obj->type){
		case 0:{
			if(obj->num->type == 0)
				printf("%d", obj->num->int_value);//w
			else
				printf("%.3f", obj->num->f_value);
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
			iter=obj->list_head->list_vec->begin();
			if(obj->list_head->list_vec->empty())
			{
				printf("[]");
			}
			else
			{
				printf("[");
				for(iter=obj->list_head->list_vec->begin();iter!=obj->list_head->list_vec->end();iter++)
				{
					printobj_1line_(*iter);
					printf(",");
				}
				printf("\b]");
			}
			break;
		}
		case 4:{
			//impossible, List_Index只是一个临时类型，不会出现在add_expr中
			break;
		}
		default:
			break;
	}
	printf("\n");
}

type_struct* print(list_struct* args)
{
	int size = args->list_vec->size();
	for (int i = 0; i < size; i++)
	{
		print_(args->list_vec->at(i));
	}
	output = false;

	type_struct* ret = new type_struct;
	ret->type = 0;
	ret->num = new num_struct;
	ret->num->type = 0;
	ret->num->int_value = size;
	return ret;
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
            {
                dest->num->type = 0;
				dest->num->int_value = src->num->int_value;
            }
			else
            {
                dest->num->type = 1;
				dest->num->f_value = src->num->f_value;
            }
			break;
		}
		case 1:{
			//impossible
			break;
		}
		case 2:{
			dest->str=(char*)malloc(strlen(src->str)+1);
			strcpy(dest->str,src->str);	//strcpy会拷贝'\0',没问题
			break;
		}
		case 3:{
			dest->list_head = src->list_head;
			break;
		}
	}
	dest->type = src->type;
}

void append_(type_struct* list,type_struct* item){
	if(list->type != 3 || item->type == 1)
	{
		yyerror("append: argment type error");
	}
	else
	{
		list->list_head->list_vec->push_back(item);
	}
}

type_struct* append(list_struct* args)
{
	if(args->list_vec->size() != 2)
		yyerror("append: please append one element once");
	type_struct* list = args->list_vec->at(0);
	type_struct* item = args->list_vec->at(1);
	append_(list, item);
	
	type_struct* ret = new type_struct;
	ret->type = 5;
	return ret;
}


void extend(type_struct* list1,type_struct* list2){
	if(list1->type != 3 || list2->type != 3)
	{
		yyerror("append error");
	}
	else
	{
		list1->list_head->list_vec->insert(list1->list_head->list_vec->end(),list2->list_head->list_vec->begin(),list2->list_head->list_vec->end());
	}
}

int len_(type_struct* list){
	if(list->type == 0 || list->type == 1)
		yyerror("object of this type has no len()");
	else if(list->type == 2)
	{
		return strlen(list->str);
	}
	else
	{
		return list->list_head->list_vec->size();
	}
}

type_struct* len(list_struct* args)
{
	int size = args->list_vec->size();
	if(size != 1)
	{
		yyerror("len() can only have one element");
	}
	int length = len_(args->list_vec->at(0));
	type_struct* ret = new type_struct;
	ret->type = 0;
	ret->num = new num_struct;
	ret->num->type = 0;
	ret->num->int_value = length;
	return ret;
}

type_struct* quit(list_struct* args)
{
	exit(0);
	type_struct* ret = new type_struct;
	return ret;
}

list_struct* list_(type_struct *list)
{
	list_struct* ret = new list_struct;
	type_struct* item;
	ret->list_vec=new vector<type_struct*> ();
	if(list->type != 2 && list->type != 3)
	{
		yyerror("TypeError: object is not iterable");
	}
	else if(list->type == 2)
	{
		
		for (int i = 0; i < strlen(list->str); i++)
		{
			//创建元素
			item = new type_struct;
			item->type = 2;
			item->str = (char *)malloc(2 * sizeof(char));
			item->str[0] = list->str[i];
			item->str[1] = '\0';
			//插入列表
			ret->list_vec->push_back(item);
		}
	}
	else
	{
		vector<type_struct*>::iterator iter;
		ret = list->list_head;
	}
	return ret;
}

type_struct* list(list_struct* args)
{
	type_struct* ret = new type_struct;
	int size = args->list_vec->size();
	if(size == 0)
	{
		ret->type = 3;
		ret->list_head = new list_struct;
		ret->list_head->list_vec=new vector<type_struct*> ();
	}
	else if(size == 1)
	{
		type_struct* list = args->list_vec->at(0);
		ret->list_head = list_(list);
		ret->type = 3;
	}	
	else
	{
		yyerror("TypeError: list() expected at most 1 arguments");
	}
	
	return ret;
}

list_struct* range_(int start, int stop, int step)
{
	list_struct* ret = new list_struct;
	type_struct* item;
	ret->list_vec=new vector<type_struct*> ();
	if(start==stop)
	{
		return ret;
	}
	else if(start < stop)
	{
		if(step > 0)
		{
			int i;
			for ( i = start; i < stop; i += step)
			{
				item = new type_struct;
				item->type = 0;
				item->num = new num_struct;
				item->num->type = 0;
				item->num->int_value = i;
				ret->list_vec->push_back(item);
			}
		}
	}
	else
	{
		if(step < 0)
		{
			int i;
			for ( i = start; i > stop; i += step)
			{
				item = new type_struct;
				item->type = 0;
				item->num = new num_struct;
				item->num->type = 0;
				item->num->int_value = i;
				ret->list_vec->push_back(item);
			}
		}
	}
	return ret;
}

type_struct* range(list_struct* args)
{
	type_struct* ret = new type_struct;
	int size = args->list_vec->size();
	switch (size)
	{
	case 0:
		{
			yyerror("TypeError: range expected 1 arguments");
			break;
		}	
	case 1:
		{
			if(args->list_vec->at(0)->type != 0 || args->list_vec->at(0)->num->type != 0)
			{
				yyerror("TypeError: object cannot be interpreted as an integer");
				break;
			}	
			else
			{
				ret->list_head = range_(0, args->list_vec->at(0)->num->int_value , 1);
				ret->type = 3;
				break;
			}
			
		}
	case 2:
		{
			if(args->list_vec->at(0)->type != 0 || args->list_vec->at(0)->num->type != 0 || args->list_vec->at(1)->type != 0 || args->list_vec->at(1)->num->type != 0)
			{
				yyerror("TypeError: object cannot be interpreted as an integer");
				break;
			}
			else
			{
				ret->list_head = range_(args->list_vec->at(0)->num->int_value, args->list_vec->at(1)->num->int_value , 1);
				ret->type = 3;
				break;
			}
			
		}
	case 3:
		{
			if(args->list_vec->at(0)->type != 0 || args->list_vec->at(0)->num->type != 0 || args->list_vec->at(1)->type != 0 || args->list_vec->at(1)->num->type != 0 || args->list_vec->at(2)->type != 0 || args->list_vec->at(2)->num->type != 0)
			{
				yyerror("TypeError: object cannot be interpreted as an integer");
				break;
			} 
			else if(args->list_vec->at(2)->num->int_value == 0)
			{
				yyerror("ValueError: range() arg 3 must not be zero");
				break;
			}
			else
			{
				ret->list_head = range_(args->list_vec->at(0)->num->int_value, args->list_vec->at(1)->num->int_value , args->list_vec->at(2)->num->int_value);
				ret->type = 3;
				break;
			}
		}
			

	default:
		yyerror("TypeError: range expected at most 3 arguments");
		break;
	}
}
