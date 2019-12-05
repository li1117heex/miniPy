#include <stdio.h>
#include <ctype.h>
using namespace std;

#include "property.h"

extern void yyerror(char *s);

void printobj_1line(type_struct* obj)
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
			printf("[");
			for(iter=obj->list_head->list_vec->begin();iter!=obj->list_head->list_vec->end();iter++)
			{
				printobj_1line(*iter);
                printf(",");
			}
			printf("\b]");
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

void printobj(type_struct* obj){
	if(obj->error == false){
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
					printobj_1line(*iter);
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
	printf("\n");
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
		default:
			break;
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
		list->list_head->list_vec->push_back(item);
	}
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

int len(type_struct* list){
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
