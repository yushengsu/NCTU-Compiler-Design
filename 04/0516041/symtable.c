#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <vector>
#include "symtable.h"
using namespace std;
extern int linenum;
extern int error;

int initSymTableList(struct SymTableList *list)
{
	list->head = NULL;
	list->tail = NULL;
	list->global = NULL;
	list->reference = 1;
	return 0;
}
int destroySymTableList(struct SymTableList *list)
{
	list->reference -= 1;//derefence
	if(list->reference>0)return -1;
	while(list->head!=NULL)
	{
		//kill head node
		list->head = deleteSymTable(list->head);//return new head
	}
	return 0;
}
struct SymTable* deleteSymTable(struct SymTable* target)
{
	struct SymTable *next;
	if(target==NULL)
		next = NULL;
	else
	{
		target->reference -= 1;//dereference
		if(target->reference>0)
			return NULL;
		next = target->next;
		while(target->head!=NULL)
		{
			target->head = deleteTableNode(target->head);
		}
	}
	if(next!=NULL)next->prev = NULL;
	return next;
}
int AddSymTable(struct SymTableList* list)//enter a new scope
{
	if(list->head == NULL)
	{
		struct SymTable *newTable = (struct SymTable*)malloc(sizeof(struct SymTable));
		newTable->head = NULL;
		newTable->tail = NULL;
		newTable->next = NULL;
		newTable->prev = NULL;
		list->head = newTable;
		list->tail = list->head;
		list->global = list->head;
		newTable->reference = 1;
	}
	else
	{
		struct SymTable *newTable = (struct SymTable*)malloc(sizeof(struct SymTable));
		newTable->head = NULL;
		newTable->tail = NULL;
		newTable->next = NULL;
		newTable->prev = list->tail;
		list->tail->next = newTable;
		list->tail = newTable;
		newTable->reference = 1;
	}
	return 0;
}
int deleteLastSymTable(struct SymTableList* list)//leave scope
{
	struct SymTable *temp = list->tail;
	if(temp==NULL)
		return -1;
	temp->reference -= 1;//derefence
	if(temp->reference>0)
		return -1;
	if(list->head!=list->tail)
	{
		temp->prev->next = NULL;
		list->tail = temp->prev;
	}
	else
	{
		list->tail = NULL;
		list->head = NULL;
	}
	deleteSymTable(temp);
	return 0;
}
int insertTableNode(struct SymTable *table,struct SymTableNode* newNode)
{
	if(table->tail==NULL)
	{
		table->head = newNode;
		table->tail = newNode;
	}
	else
	{
		table->tail->next = newNode;
		table->tail = newNode;
	}
	newNode->reference += 1;
	return 0;
}
struct SymTableNode* deleteTableNode(struct SymTableNode* target)//return next node
{
	struct SymTableNode *next;
	if(target==NULL)
		next = NULL;
	else
	{
		target->reference -= 1;//defreference
		if(target->reference>0)
			return NULL;
		next = target->next;
		killExtType(target->type);
		if(target->attr!=NULL)
			killAttribute(target->attr);
		free(target);
	}
	return next;
}



struct SymTableNode* createVariableNode(const char* name,int level,struct ExtType* type)
{
	struct SymTableNode *newNode = (struct SymTableNode*)malloc(sizeof(struct SymTableNode));
	//set node
	strncpy(newNode->name,name,32);
	newNode->kind = VARIABLE_t;
	newNode->level = level;
	/**/
	newNode->type = type;
	newNode->type->reference += 1;
	/**/
	newNode->attr = NULL;
	newNode->next = NULL;
	newNode->reference = 0;
	return newNode;
}
struct SymTableNode* createFunctionNode(const char* name,int level,struct ExtType* type,struct Attribute* attr)
{
	struct SymTableNode *newNode = (struct SymTableNode*)malloc(sizeof(struct SymTableNode));
	//set node
	strncpy(newNode->name,name,32);
	newNode->kind = FUNCTION_t;
	newNode->level = level;
	/**/
	newNode->type = type;
	newNode->type->reference += 1;
	/**/
	newNode->attr = attr;
	if(attr!=NULL)
		newNode->attr->reference += 1;
	/**/
	newNode->next = NULL;
	newNode->reference = 0;
	return newNode;

}
struct SymTableNode* createConstNode(const char* name,int level,struct ExtType* type,struct Attribute* attr)
{
	struct SymTableNode *newNode = (struct SymTableNode*)malloc(sizeof(struct SymTableNode));
	//set node
	strncpy(newNode->name,name,32);
	newNode->kind = CONSTANT_t;
	newNode->level = level;
	/**/
	newNode->type = type;
	newNode->type->reference += 1;
	/**/
	newNode->attr = attr;
	if(attr!=NULL)
		newNode->attr->reference += 1;
	/**/
	newNode->next = NULL;
	newNode->reference = 0;
	return newNode;
}
struct SymTableNode* createParameterNode(const char* name,int level,struct ExtType* type)
{
	struct SymTableNode *newNode = (struct SymTableNode*)malloc(sizeof(struct SymTableNode));
	//set node
	strncpy(newNode->name,name,32);
	newNode->kind = PARAMETER_t;
	newNode->level = level;
	/**/
	newNode->type = type;
	newNode->type->reference+=1;
	/**/
	newNode->attr = NULL;
	newNode->next = NULL;
	newNode->reference = 0;
	return newNode;
}
struct Attribute* createFunctionAttribute(struct FuncAttrNode* list)
{
	int num = 0;
	struct Attribute *newAttr = (struct Attribute*)malloc(sizeof(struct Attribute));
	newAttr->constVal = NULL;
	newAttr->funcParam = (struct FuncAttr*)malloc(sizeof(struct FuncAttr));
	newAttr->funcParam->reference = 1;
	/**/
	newAttr->funcParam->head = list;
	newAttr->funcParam->head->reference += 1;
	/**/
	while(list!=NULL)
	{
		list = list->next;
		++num;
	}
	newAttr->funcParam->paramNum = num;
	newAttr->reference = 0;
	return newAttr;
}
struct Attribute* createConstantAttribute(BTYPE type,void* value)
{
	struct Attribute *newAttr = (struct Attribute*)malloc(sizeof(struct Attribute));
	struct ConstAttr *newConstAttr = (struct ConstAttr*)malloc(sizeof(struct ConstAttr));
	newAttr->funcParam = NULL;
	newAttr->constVal = newConstAttr;
	newConstAttr->reference = 1;
	newConstAttr->hasMinus = false;
	newConstAttr->type = type;
	switch(type)
	{
		case INT_t:
			newConstAttr->value.integerVal = *(int*)value;
			if(*(int*)value < 0)
				newConstAttr->hasMinus = true;
			break;
		case FLOAT_t:
			newConstAttr->value.floatVal = *(float*)value;
			if(*(float*)value < 0.0)
				newConstAttr->hasMinus = true;
			break;
		case DOUBLE_t:
			newConstAttr->value.doubleVal = *(double*)value;
			if(*(double*)value < 0.0)
				newConstAttr->hasMinus = true;
			break;
		case BOOL_t:
			newConstAttr->value.boolVal = *(bool*)value;
			break;
		case STRING_t:
			newConstAttr->value.stringVal = strdup((char*)value);
			break;
		default:
			break;
	}
	newAttr->reference = 0;
	return newAttr;
}
struct FuncAttrNode* deleteFuncAttrNode(struct FuncAttrNode* target)
{
	struct FuncAttrNode *next;
	if(target==NULL)
		next=NULL;
	else
	{
		target->reference -= 1;
		if(target->reference>0)
			return NULL;
		next = target->next;
		killExtType(target->value);
		free(target->name);
		free(target);
	}
	return next;
}
int killAttribute(struct Attribute* target)
{
	target->reference -= 1;
	if(target->reference>0)
		return -1;
	if(target->constVal!=NULL)
	{
		target->constVal->reference -= 1;
		if(target->constVal->reference>0)
			return -1;
		if(target->constVal->type==STRING_t)
			free(target->constVal->value.stringVal);
		free(target->constVal);
	}
	if(target->funcParam!=NULL)
	{
		target->funcParam->reference -= 1;
		if(target->funcParam->reference>0)
			return -1;
		target->funcParam->head = deleteFuncAttrNode(target->funcParam->head);
		free(target->funcParam);
	}
	free(target);
	return 0;
}
struct FuncAttrNode* createFuncAttrNode(struct ExtType* type,const char* name)
{
	struct FuncAttrNode *newNode = (struct FuncAttrNode*)malloc(sizeof(struct FuncAttrNode));
	/*reference*/
	newNode->value = type;
	type->reference += 1;
	/*         */
	newNode->name = strdup(name);
	newNode->next = NULL;
	newNode->reference = 0;
	return newNode;
}
int connectFuncAttrNode(struct FuncAttrNode* head, struct FuncAttrNode* newNode)//connect node to tail of function attribute list
{
	if(head==NULL || newNode==NULL || head==newNode)
		return -1;
	struct FuncAttrNode *temp = head;
	while(temp->next!=NULL)
	{
		temp = temp->next;
	}
	temp->next = newNode;
	newNode->reference += 1;
	return 0;
}
struct ExtType* createExtType(BTYPE baseType,bool isArray,struct ArrayDimNode* dimArray)
{
	int dimNum = 0;
	struct ArrayDimNode *temp = dimArray;
	struct ExtType *newExtType = (struct ExtType*)malloc(sizeof(struct ExtType));
	newExtType->baseType = baseType;
	newExtType->isArray = isArray;
	/**/
	newExtType->dimArray = dimArray;
	if(dimArray!=NULL)
		dimArray->reference += 1;
	/**/
	newExtType->reference = 0;
	while(temp!=NULL)
	{
		temp = temp->next;
		++dimNum;
	}
	newExtType->dim = dimNum;
	return newExtType;
}
int killExtType(struct ExtType* target)
{
	if(target==NULL)
		return -1;
	target->reference -= 1;
	if(target->reference>0)
		return -1;
	if(target->isArray)
	{
		while(target->dimArray!=NULL)
		{
			target->dimArray = deleteArrayDimNode(target->dimArray);
		}
	}
	return 0;
}
struct ArrayDimNode* createArrayDimNode(int size)
{
	struct ArrayDimNode *newNode = (struct ArrayDimNode*)malloc(sizeof(struct ArrayDimNode));
	newNode->size = size;
	newNode->next = NULL;
	newNode->reference = 0;
	return newNode;
}
int connectArrayDimNode(struct ArrayDimNode* head,struct ArrayDimNode* newNode)//connect dimension node to tail of list
{
	if(head==NULL || newNode==NULL || head==newNode)
		return -1;
	struct ArrayDimNode *temp = head;
	while(temp->next!=NULL)
	{
		temp = temp->next;
	}
	/**/
	temp->next = newNode;
	newNode->reference += 1;
	/**/
	return 0;
}
struct ArrayDimNode* deleteArrayDimNode(struct ArrayDimNode* target)
{
	struct ArrayDimNode *next;
	if(target==NULL)
		next = NULL;
	else
	{
		target->reference -= 1;
		if(target->reference>0)
			return NULL;
		next = target->next;
		free(target);
	}
	return next;
}


struct SymTableNode* findFuncDeclaration(struct SymTable* table,const char* name)
{
	struct SymTableNode *temp = table->head;
	while(temp!=NULL)
	{
		if(temp->kind == FUNCTION_t)
		{
			if(strncmp(temp->name,name,32)==0)
				return temp;
		}
		temp = temp->next;
	}
	return NULL;
}
int printSymTable(struct SymTable* table)
{
	struct SymTableNode *entry;
	struct ArrayDimNode *dimNode;
	struct Attribute *attr;
	struct FuncAttrNode *funcAttrNode;
	char strBuffer[32];
	if(table==NULL)return -1;
	if(table->head==NULL)return 1;//no entry to output
	printf("=======================================================================================\n");
	// Name [29 blanks] Kind [7 blanks] Level [7 blank] Type [15 blanks] Attribute [15 blanks]
	printf("Name                             Kind       Level       Type               Attribute               \n");
	printf("---------------------------------------------------------------------------------------\n");
	entry = table->head;
	while(entry!=NULL)
	{
		//name
		printf("%-32s ",entry->name);
		//kind
		switch(entry->kind)
		{
			case VARIABLE_t:
				printf("%-11s","variable");
				break;
			case CONSTANT_t:
				printf("%-11s","constant");
				break;
			case FUNCTION_t:
				printf("%-11s","function");
				break;
			case PARAMETER_t:
				printf("%-11s","parameter");
				break;
			default:
				printf("%-11s","unknown");
				break;
		}
		//level
		if(entry->level==0)
			printf("%-12s","0(global) ");
		else
		{
			sprintf(strBuffer,"%d(local)  ",entry->level);
			printf("%-12s",strBuffer);
		}
		//type
		printType(entry->type);
		//attribute
		attr = entry->attr;
		if(attr!=NULL)
		{
			if(attr->constVal!=NULL)
			{
				printConstAttribute(attr->constVal);
			}
			if(attr->funcParam!=NULL)
			{
				printParamAttribute(attr->funcParam);
			}
		}
		entry = entry->next;
		printf("\n");
	}
	printf("======================================================================================\n");
}
int printType(struct ExtType* extType)
{
	struct ArrayDimNode *dimNode;
	char strBuffer[20];
	char strTemp[20];
	if(extType == NULL)
		return -1;
	memset(strBuffer,0,20*sizeof(char));
	switch(extType->baseType)
	{
		case INT_t:
			strncpy(strBuffer,"int",3);
			break;
		case FLOAT_t:
			strncpy(strBuffer,"float",5);
			break;
		case DOUBLE_t:
			strncpy(strBuffer,"double",6);
			break;
		case BOOL_t:
			strncpy(strBuffer,"bool",4);
			break;
		case STRING_t:
			strncpy(strBuffer,"string",6);
			break;
		case VOID_t:
			strncpy(strBuffer,"void",4);
			break;
		default:
			strncpy(strBuffer,"unknown",7);
			break;
	}
	if(extType->isArray)
	{
		dimNode = extType->dimArray;
		while(dimNode!=NULL)
		{
			memset(strTemp,0,20*sizeof(char));
			sprintf(strTemp,"[%d]",dimNode->size);
			if(strlen(strBuffer)+strlen(strTemp)<20)
				strcat(strBuffer,strTemp);
			else
			{
				strBuffer[16]='.';
				strBuffer[17]='.';
				strBuffer[18]='.';
			}
			dimNode = dimNode->next;
		}
	}
	printf("%-19s",strBuffer);
	return 0;
}
int printConstAttribute(struct ConstAttr* constAttr)
{
	switch(constAttr->type)
	{
		case INT_t:
			printf("%d",constAttr->value.integerVal);
			break;
		case FLOAT_t:
			printf("%f",constAttr->value.floatVal);
			break;
		case DOUBLE_t:
			printf("%lf",constAttr->value.doubleVal);
			break;
		case BOOL_t:
			if(constAttr->value.boolVal)
				printf("true");
			else
				printf("false");
			break;
		case STRING_t:
			printf("%s",constAttr->value.stringVal);
			break;
		default:
			printf("__ERROR__");
			break;
	}
	return 0;
}
int printParamAttribute(struct FuncAttr* funcAttr)
{
	struct FuncAttrNode* attrNode = funcAttr->head;
	struct ArrayDimNode* dimNode;
	if(attrNode!=NULL)
	{
		switch(attrNode->value->baseType)
		{
			case INT_t:
				printf("int");
				break;
			case FLOAT_t:
				printf("float");
				break;
			case DOUBLE_t:
				printf("double");
				break;
			case BOOL_t:
				printf("bool");
				break;
			case STRING_t:
				printf("string");
				break;
			case VOID_t:
				printf("void");
				break;
			default:
				printf("unknown");
				break;
		}
		if(attrNode->value->isArray)
		{
			dimNode = attrNode->value->dimArray;
			while(dimNode!=NULL)
			{
				printf("[%d]",dimNode->size);
				dimNode = dimNode->next;
			}
		}
		attrNode = attrNode->next;
		while(attrNode!=NULL)
		{
			switch(attrNode->value->baseType)
			{
				case INT_t:
					printf(",int");
					break;
				case FLOAT_t:
					printf(",float");
					break;
				case DOUBLE_t:
					printf(",double");
					break;
				case BOOL_t:
					printf(",bool");
					break;
				case STRING_t:
					printf(",string");
					break;
				case VOID_t:
					printf(",void");
					break;
				default:
					printf(",unknown");
					break;
			}
			if(attrNode->value->isArray)
			{
				dimNode = attrNode->value->dimArray;
				while(dimNode!=NULL)
				{
					printf("[%d]",dimNode->size);
					dimNode = dimNode->next;
				}
			}
			attrNode = attrNode->next;
		}
	}
	return 0;
}
struct VariableList* createVariableList(struct Variable* head)
{	
	struct VariableList *list;
	if(head==NULL)
		list = NULL;
	else
	{
		list = (struct VariableList*)malloc(sizeof(struct VariableList));
		struct Variable* temp = head;
		while(temp->next!=NULL)
		{
			temp = temp->next;
		}
		/**/
		list->head = head;
		head->reference += 1;
		/**/
		list->tail = temp;
		if(head!=temp)
			temp->reference += 1;
		/**/
		list->reference = 0;
	}
	return list;
}
int deleteVariableList(struct VariableList* list)
{
	list->reference -= 1;
	if(list->reference>0)
		return -1;
	if(list->head!=NULL)
	{
		/**/
		//list->head = NULL
		list->head->reference -= 1;
		/**/
		if(list->head!=list->tail)
		{
			//list->tail = NULL
			list->tail->reference -= 1;
		}
		/**/
		while(list->head!=NULL)
		{
			list->head=deleteVariable(list->head);
		}
	}
	return 0;
}
int connectVariableList(struct VariableList* list,struct Variable* node)
{
	if(list==NULL||node==NULL)
		return -1;
	if(node->next!=NULL)
		return -2;
	if(list->tail!=list->head)
		list->tail->reference -= 1;
	/**/
	list->tail->next = node;
	list->tail->next->reference += 1;
	list->tail = node;
	list->tail->reference += 1;
	/**/
	return 0;
}
struct Variable* createVariable(const char* name,struct ExtType* type)
{
	struct Variable* variable = (struct Variable*)malloc(sizeof(struct Variable));
	variable->name = strdup(name);
	/**/
	variable->type = type;
	type->reference += 1;
	/**/
	variable->next = NULL;
	variable->reference = 0;
	return variable;
}
struct Variable* deleteVariable(struct Variable* target)
{
	struct Variable* next;
	if(target == NULL)
		next = NULL;
	else
	{
		target->reference -= 1;
		if(target->reference>0)
			return NULL;
		free(target->name);
		killExtType(target->type);
		next = target->next;
		free(target);
	}
	return next;
}

BTYPE Bool_TypeCheck(BTYPE type1, BTYPE type2){
	if(type1 == 3 && type2 == 3) return BOOL_t;
	error = 1;
	printf("##########Error at Line %d: ", linenum);
	printf("It's not a bool type.##########\n");
	return 	UNCERTAIN_t;

}

BTYPE OP_TypeCheck(BTYPE type1, BTYPE type2){
	if(type1 > 2 || type2 > 2){
		error = 1;
		printf("##########Error at Line %d: ", linenum);
		printf("Operation type error.##########\n");
		return UNCERTAIN_t;
	}
	if(type1 >= type2) return type1;
	else return type2;
}

BTYPE MOD_TypeCheck(BTYPE type1, BTYPE type2){
	if(!type1 && !type2){
		return INT_t;
	}
	else{
		error = 1;
		printf("##########Error at Line %d: ", linenum);
		printf("Mod type error.##########\n");
		return UNCERTAIN_t;
	}		
}

void AssignTypeCheck(BTYPE type1, BTYPE type2){
	
	int flag = 0;
	if(type1 == type2 || type2 == 6){
		if(type1 == 7 && type2 == 7) flag = 1;
	}
	else if(type1 < 3){
		if(type1 < type2) flag = 1;
	}
	if(flag){
		error = 1;
		printf("##########Error at Line %d: ", linenum);
		printf("Assign type error.##########\n");
	}

}

void Loop_Check(bool loop){
	if(!loop){
		error = 1;
		printf("##########Error at Line %d: ", linenum);
		printf("Break and continue can only appear in loop statements.");
		printf("##########\n");
	}
}

void Bool_ExpressionCheck(BTYPE type1, int logical_expression_num){
	if( type1 != 3){
		error = 1;
		printf("##########Error at Line %d: ", logical_expression_num);
		printf("This expression is not a bool type.");
		printf("##########\n");
	}
}

void ScalarTypeCheck(BTYPE type1){
	if(type1 > 4){
		error = 1;
		printf("##########Error at Line %d: ", linenum);
		printf("It's not a scalar type.##########\n");	
	}
}

void ReturnTypeCheck(BTYPE t1, BTYPE returnType[1000], int return_linenum[1000], int return_count){
	for(int i=0; i<return_count; ++i){
		if(t1 != returnType[i]){
			if(t1 == DOUBLE_t && (returnType[i] == INT_t || returnType[i] == FLOAT_t)){}
			else if(t1 == FLOAT_t && returnType[i] == INT_t){}
			else{
				error = 1;
				printf("##########Error at Line %d: ", return_linenum[i]);
				printf("Return type doesn't match.##########\n");
			}
		}
	}
	if(return_count == 0 && t1 != VOID_t){
		error = 1;
		printf("##########Error at Line %d: ", linenum);
		printf("Return type isn't void.##########\n");
	}

}

BTYPE checkIDdect(struct SymTable* table, const char* name)
{
	int flag = 0;
	do{
		struct SymTableNode *entry;
		entry = table->head;	
		while(entry!=NULL){
			if(strcmp(entry->name, name) == 0){			
				flag = 1;
				
				if(!entry->type->isArray) { return entry->type->baseType;}
				else return ARRAY_t;					
			}
			entry = entry->next;
		}
		table = table -> prev;

	}while(table != NULL);
	
	if(!flag){
		error = 1;
		printf("##########Error at Line %d: ", linenum);
		printf("ID is not declared.##########\n");
		return UNCERTAIN_t;
	}
}

bool DeclareCheck(struct SymTable* table, const char* name){
	struct SymTableNode *entry;
	entry = table->head;
	while(entry!=NULL){
		if(strcmp(entry->name, name) == 0){		
			error = 1;	
			printf("##########Error at Line %d: ", linenum);
			printf("%s ", name);
			printf("is redeclared in this scope.##########\n");
			return true;
			break;							
		}
		entry = entry->next;
	}
	return false;

}

void ArrayDeclareCheck(vector<BTYPE> vector1, struct ArrayDimNode* dimNode, BTYPE type1){
	int count = 1;
	while(dimNode!=NULL){
		count *= dimNode->size;
		dimNode = dimNode->next;
	}
	if(vector1.size() > count){
		error = 1;
		printf("##########Error at Line %d: ", linenum);
		printf("Array size does't match.##########\n");
	}

	for(int i=0; i<vector1.size(); ++i){

		BTYPE type2 = vector1[i];
		int flag = 0;
		if(type1 > 2 && type1 < 6) if(type1 != type2) flag = 1;
		
		if(type1 == type2){}
		else if(type1 < type2) flag = 1;
		if(flag){
			error = 1;
			printf("##########Error at Line %d: ", linenum);
			printf("Array type doesn't match.##########\n");
		}
	}

}

bool ArrayIndexCheck(BTYPE type1){
	if(type1 > 0){
		error = 1;
		printf("##########Error at Line %d: ", linenum);
		printf("Array index type should be int.##########\n");
		return false;	
	}
	return true;
}

BTYPE ArrayNameCheck(struct SymTable* table, const char* name, vector<BTYPE> arrayCheck){	
	bool flag = false;
	int count = 0;
	struct SymTableNode *entry;
	struct ArrayDimNode* dimNode;
	do{
		entry = table->head;	
		while(entry!=NULL){
			
			if(strcmp(entry->name, name) == 0 && entry->type->isArray){			
				
				flag = true;
				dimNode = entry->type->dimArray;
				
				if(arrayCheck.size() == entry->type->dim) return entry->type->baseType;
				else if(arrayCheck.size() > entry->type->dim){
					error = 1;
					printf("##########Error at Line %d: ", linenum);
					printf("%s ", name);
					printf("dimension doesn't match.##########\n");	
					return UNCERTAIN_t;	
				}
				else return ARRAY_t;
				break;
			}
			else if(strcmp(entry->name, name) == 0 && !entry->type->isArray){
				error = 1;
				printf("##########Error at Line %d: ", linenum);
				printf("%s is not array.", name);
				printf("##########\n");
				return UNCERTAIN_t;	
			}
			entry = entry->next;
		}
		table = table -> prev;
	}while(table != NULL);
	if(!flag){
		error = 1;
		printf("##########Error at Line %d: ", linenum);
		printf("%s ", name);
		printf("is not declared in this scope.##########\n"); 	
		return UNCERTAIN_t;				
	}
	return UNCERTAIN_t;
}

void FunctDeclDefNoParamError(const char* name){
	error = 1;
	printf("##########Error at Line %d: ", linenum);
	printf("function need some parameter.", name);
	printf("##########\n");

}

void FunctDeclDefParamCheck(struct FuncAttrNode *attr1, struct FuncAttrNode *attr2){
	bool flag = true;
	struct ArrayDimNode* dim1;
	struct ArrayDimNode* dim2;
	if(attr1 != NULL && attr2 != NULL){
		do{
			if(attr1->value->baseType == attr2->value->baseType){}
			else{
				flag = false;
				break;			
			}
			
			if(attr1->value->isArray && attr2->value->isArray){
				dim1 = attr1->value->dimArray;
				dim2 = attr2->value->dimArray;
				while(dim1 != NULL && dim2 != NULL){
					if(dim1->size == dim2->size){}
					else{
						flag = false;
						break;					
					}
					dim1 = dim1->next;
					dim2 = dim2->next;
				}
				if(dim1 != NULL || dim2 != NULL) flag = false;
			}
			else if(attr1->value->isArray != attr2->value->isArray) flag = false;
			if(!flag) break;		
			attr1 = attr1->next;
			attr2 = attr2->next;
		}while(attr1 != NULL && attr2 != NULL);
		if(attr1 != NULL || attr2 != NULL) flag = false;
	}
	else if(attr1 == NULL && attr2 == NULL){}
	else flag = false;	
	if(!flag){
		error = 1;
		printf("##########Error at Line %d: ", linenum);
		printf("Declaration and definition's parameter are not matched.##########\n");
	}
}

BTYPE FunctParamInvokeCheck(struct SymTable* table, const char* name, vector<BTYPE> v)
{
	int flag = 0;
	do{
		struct SymTableNode *entry;
		entry = table->head;	
		while(entry!=NULL)
		{
			if(strcmp(entry->name, name) == 0 && entry->kind == FUNCTION_t && entry->attr == NULL){
				flag = 1; 
				break;
			}
			else if(strcmp(entry->name, name) == 0 && entry->kind == FUNCTION_t){
				if(int(v.size()) != entry->attr->funcParam->paramNum){
					flag = 3; 
					break;
				}
				else{
					struct FuncAttrNode* attrNode = entry->attr->funcParam->head;
					int i=0;					
					for(i=0; i<int(v.size()); ++i){
						if(v[i] == attrNode->value->baseType && !attrNode-> value->isArray){}
						else if(v[i] == ARRAY_t && attrNode-> value->isArray){}
						else{
							flag = 4; 
							break;
						}
					}
					if(i == v.size()) return entry->type->baseType;
					break;
				}
				
			}
			else if(strcmp(entry->name, name) == 0){
				flag = 2; 
				break;
			}
			entry = entry->next;
		}
		table = table -> prev;
	}while(table != NULL);
	if(!flag){
		error = 1;
		printf("##########Error at Line %d: ", linenum);
		printf("function: %s ", name);
		printf("doesn't declared.##########\n");	
	}
	else if(flag == 1){
		error = 1;
		printf("##########Error at Line %d: ", linenum);
		printf("function: %s ", name);
		printf("should be no parameter.##########\n");	
	}
	else if(flag == 2){
		error = 1;
		printf("##########Error at Line %d: ", linenum);
		printf("%s ", name);
		printf("is not a function.##########\n");	
	}
	else if(flag == 3){
		error = 1;
		printf("##########Error at Line %d: ", linenum);
		printf("function: %s's ", name);
		printf("parameter number does not match.##########\n");
	}
	else if(flag == 4){
		error = 1;
		printf("##########Error at Line %d: ", linenum);
		printf("function: %s's ", name);
		printf("parameter type does not match.##########\n");
	}
	return UNCERTAIN_t;
}

BTYPE FunctNoParamInvokeCheck(struct SymTable* table, const char* name){
	int flag = 0;
	do{
		struct SymTableNode *entry;
		entry = table->head;	
		while(entry!=NULL){
			if(strcmp(entry->name, name) == 0 && entry->kind == FUNCTION_t && entry->attr == NULL) return entry->type->baseType;
			else if(strcmp(entry->name, name) == 0 && entry->kind == FUNCTION_t){
				flag = 1; 
				break;
			}
			else if(strcmp(entry->name, name) == 0){
				flag = 2;
				break;
			}
			entry = entry->next;
		}
		table = table -> prev;
	}while(table != NULL);
	if(flag == 0){
		error = 1;
		printf("##########Error at Line %d: ", linenum);
		printf("function: %s ", name);
		printf("doesn't declared.##########\n");	
	}
	else if(flag == 1){
		error = 1;
		printf("##########Error at Line %d: ", linenum);
		printf("function: %s ", name);
		printf("must need parameter.##########\n");	
	}
	else if(flag == 2){
		error = 1;
		printf("##########Error at Line %d: ", linenum);
		printf("%s ", name);
		printf("is not a function.##########\n");	
	}	
	return UNCERTAIN_t;
}

void FunctDeclDefParamError(const char* name)
{
	error = 1;
	printf("##########Error at Line %d: ", linenum);
	printf("function %s shouldn't have any parameter.", name);
	printf("##########\n");

}

void FunctNotDef(string name){
	error = 1;
	printf("##########Error at Line %d: function ", linenum);
	printf("%s", name);
	printf(" is declared but not defined.##########\n");	
}