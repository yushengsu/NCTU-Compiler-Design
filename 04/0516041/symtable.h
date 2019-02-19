#include <vector>
#include <string>
#include "datatype.h"
using namespace std;

int initSymTableList(struct SymTableList *list);
int destroySymTableList(struct SymTableList *list);
//

int AddSymTable(struct SymTableList* list);
struct SymTable* deleteSymTable(struct SymTable* target);
int deleteLastSymTable(struct SymTableList* list);
int insertTableNode(struct SymTable *table,struct SymTableNode* newNode);
//
struct SymTableNode* deleteTableNode(struct SymTableNode* target);
struct SymTableNode* createVariableNode(const char* name,int level,struct ExtType* type);
struct SymTableNode* createFunctionNode(const char* name,int level,struct ExtType* type,struct Attribute* attr);
struct SymTableNode* createConstNode(const char* name,int level,struct ExtType* type,struct Attribute* attr);
struct SymTableNode* createParameterNode(const char* name,int level,struct ExtType* type);
//
struct Attribute* createFunctionAttribute(struct FuncAttrNode* list);
struct Attribute* createConstantAttribute(BTYPE type,void* value);
struct FuncAttrNode* deleteFuncAttrNode(struct FuncAttrNode* target);
int killAttribute(struct Attribute* target);
struct FuncAttrNode* createFuncAttrNode(struct ExtType* type,const char* name);
int connectFuncAttrNode(struct FuncAttrNode* head, struct FuncAttrNode* newNode);
//
struct ExtType* createExtType(BTYPE baseType,bool isArray,struct ArrayDimNode* dimArray);
int killExtType(struct ExtType* target);
//
struct ArrayDimNode* createArrayDimNode(int size);
int connectArrayDimNode(struct ArrayDimNode* head,struct ArrayDimNode* newNode);
struct ArrayDimNode* deleteArrayDimNode(struct ArrayDimNode* target);
//
struct SymTableNode* findFuncDeclaration(struct SymTable* table,const char* name);
int printSymTable(struct SymTable* table);
int printType(struct ExtType* extType);
int printConstAttribute(struct ConstAttr* constAttr);
int printParamAttribute(struct FuncAttr* funcAttr);

//
struct VariableList* createVariableList(struct Variable* head);
int deleteVariableList(struct VariableList* list);
int connectVariableList(struct VariableList* list,struct Variable* node);
struct Variable* createVariable(const char* name,struct ExtType* type);
struct Variable* deleteVariable(struct Variable* target);

BTYPE OP_TypeCheck(BTYPE type1, BTYPE type2);
BTYPE MOD_TypeCheck(BTYPE type1, BTYPE type2);
BTYPE Bool_TypeCheck(BTYPE type1, BTYPE type2);
void ScalarTypeCheck(BTYPE type1);
void AssignTypeCheck(BTYPE type1, BTYPE type2);
void ReturnTypeCheck(BTYPE t1, BTYPE returnType[1000], int return_linenum[1000], int return_count);
void Loop_Check(bool loop);
void Bool_ExpressionCheck(BTYPE type1, int logical_expression_num);
BTYPE checkIDdect(struct SymTable* table, const char* name);
bool DeclareCheck(struct SymTable* table, const char* name);
void ArrayDeclareCheck(vector<BTYPE> vector1, struct ArrayDimNode* dimNode, BTYPE type1);
bool ArrayIndexCheck(BTYPE type1);
BTYPE ArrayNameCheck(struct SymTable* table, const char* name, vector<BTYPE> arrayCheck);
void FunctDeclDefNoParamError(const char* name);
void FunctDeclDefParamCheck(struct FuncAttrNode *attr1, struct FuncAttrNode *attr2);
BTYPE FunctParamInvokeCheck(struct SymTable* table, const char* name, vector<BTYPE> v);
BTYPE FunctNoParamInvokeCheck(struct SymTable* table, const char* name);
void FunctDeclDefParamError(const char* name);