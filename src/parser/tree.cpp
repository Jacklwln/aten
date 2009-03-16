/*
	*** Tree
	*** src/parser/tree.cpp
	Copyright T. Youngs 2007-2009

	This file is part of Aten.

	Aten is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	Aten is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with Aten.  If not, see <http://www.gnu.org/licenses/>.
*/

#include "parser/treenode.h"
#include "parser/scopenode.h"
#include "parser/commandnode.h"
#include "parser/variablenode.h"
#include "parser/stepnode.h"
#include "parser/grammar.h"
#include "parser/tree.h"
#include "parser/vector.h"
#include "parser/character.h"
#include "parser/integer.h"
#include "parser/real.h"
#include <stdarg.h>

// YYParse forward
int yyparse();

// Constructor
Tree::Tree()
{
	// Private variables
	inputFile_ = NULL;
	outputFile_ = NULL;
	declaredType_ = NuVTypes::NoData;
	declarationAssignment_ = FALSE;
	filterType_ = Tree::nFilterTypes;
	hasExtension_ = FALSE;
	hasZmapping_ = FALSE;
	zmapping_ = ElementMap::AlphaZmap;
	name_.set("unnamed");
	glob_.set("*");
	id_ = -1;
	partner_ = NULL;
	isFilter_ = FALSE;

	// Public variables
	prev = NULL;
	next = NULL;

	// Initialise
	initialise();
}

// Destructor
Tree::~Tree()
{
	clear();
}

/*
// Create / Execute
*/

// Add read option
void CommandList::addReadOption(Parser::ParseOption po)
{
	if (!(readOptions_&po)) readOptions_ += po;
}

// Remove read option
void CommandList::removeReadOption(Parser::ParseOption po)
{
	if (readOptions_&po) readOptions_ -= po;
}

// Return read options
int CommandList::readOptions()
{
	return readOptions_;
}

// Clear contents of tree
void Tree::clear()
{
	nodes_.clear();
	statements_.clear();
}

// (Re)Initialise Tree
void Tree::initialise()
{
	msg.enter("Tree::initialise");
	clear();
	// Store this as the current Tree (for Bison) and add a dummy ScopeNode to contain the main variable list
	ScopeNode *root = new ScopeNode(NuCommand::NoFunction);
	root->createGlobalVariables();
	nodes_.own(root);
	scopeStack_.add(root);
	statements_.add(root);
	msg.exit("Tree::initialise");
}

// Execute tree
bool Tree::execute(NuReturnValue &rv)
{
	msg.enter("Tree::execute");
	bool result;
	for (Refitem<TreeNode,int> *ri = statements_.first(); ri != NULL; ri = ri->next)
	{
		printf("Executing tree statement %li...\n", ri->item);
		result = ri->item->execute(rv);
		if (!result) break;
	}
	printf("Final result of tree execution:\n");
	rv.info();
	msg.exit("Tree::execute");
	return result;
}

// Execute tree after opening corresponding input stream
bool Tree::executeRead(const char *filename)
{
	msg.enter("Tree::executeRead[filename]");
	// Open file in LineParser
	if (!parser.openFile(filename))
	{
		msg.exit("Tree::executeRead[filename]");
		return FALSE;
	}
	// Execute the commands
	NuReturnValue rv;
	bool result = execute(rv);
	// Close the file
	parser.closeFile();
	msg.exit("Tree::executeRead[filename]");
	return result;
}

// Execute tree with corresponding input stream
bool Tree::executeRead(ifstream *file)
{
	msg.enter("Tree::executeRead[ifstream]");
	inputFile_ = file;
	if (!inputFile_->good())
	{
		inputFile_ = NULL;
		msg.print("Bad file pointer passed for execution of commands.\n");
		msg.exit("Tree::executeRead[ifstream]");
		return FALSE;
	}
	// Execute the commands
	NuReturnValue rv;
	bool result = execute(rv);
	inputFile_ = NULL;
	msg.exit("Tree::executeRead[ifstream]");
	return result;
}

// Return whether a current input file is defined
bool Tree::hasFileSource()
{
	return (inputFile_ != NULL);
}

// Print tree
void Tree::print()
{
	printf("Leaf Structure (%i statements):\n", statements_.nItems());
	int n=1;
	for (Refitem<TreeNode,int> *ri = statements_.first(); ri != NULL; ri = ri->next)
	{
		printf("-------------------------------------------------------------\n");
		printf("Statement %i:\n", n);
		printf("item pointer is %li\n", ri->item);
		ri->item->nodePrint(1);
		n ++;
	}
	printf("-------------------------------------------------------------\n");
}

/*
// Statements / Commands / Operators
*/

// Check operator type compatibility
NuVTypes::DataType Tree::checkOperatorTypes(NuCommand::Function func, NuVTypes::DataType type1, NuVTypes::DataType type2)
{
	// Check for no data type
	if ((type1 == NuVTypes::NoData) || (type2 == NuVTypes::NoData))
	{
		printf("Internal Error: One or both operands have no defined type.\n");
		return NuVTypes::NoData;
	}
	// Put types in 'precedence' order
	if (type2 > type1)
	{
		NuVTypes::DataType temp = type1;
		type1 = type2;
		type2 = temp;
	}
	// Like types first... (make int equivalent to real if both types are numeric)
	if ((type1 <= NuVTypes::RealData) && (type2 <= NuVTypes::RealData) && (type1 != type2)) type1 = type2 = NuVTypes::RealData;
	NuVTypes::DataType result = NuVTypes::NoData;
	if (type1 == type2)
	{
		switch (func)
		{
			// Arithmetic
			case (NuCommand::OperatorAdd):
				// Any pair of the same type except pointers can be added together
				if (type1 < NuVTypes::AtenData) result = type1;
				break;
			case (NuCommand::OperatorSubtract):
			case (NuCommand::OperatorMultiply):
			case (NuCommand::OperatorDivide):
				if ((type1 == NuVTypes::CharacterData) || (type1 >= NuVTypes::AtenData)) result = NuVTypes::NoData;
				else result = type1;
				break;
			case (NuCommand::OperatorPower):
				// Only numerical types
				if (type1 > NuVTypes::RealData) result = NuVTypes::NoData;
				else result = type1;
				break;
			// Tests
			case (NuCommand::OperatorEqualTo):
			case (NuCommand::OperatorNotEqualTo):
			case (NuCommand::OperatorGreaterThan):
			case (NuCommand::OperatorGreaterThanEqualTo):
			case (NuCommand::OperatorLessThan):
			case (NuCommand::OperatorLessThanEqualTo):
				// All other test operators are fine, unless its a vector
				if (type1 != NuVTypes::VectorData) result = NuVTypes::IntegerData;
				break;
			// Assignment
			case (NuCommand::OperatorAssignment):
				// Any value of the same type can be assigned
				result = type1;
				break;
			case (NuCommand::OperatorAssignmentDivide):
			case (NuCommand::OperatorAssignmentMinus):
			case (NuCommand::OperatorAssignmentMultiply):
			case (NuCommand::OperatorAssignmentPlus):
				// Nonsensical for character types and pointer types
				if ((type1 == NuVTypes::CharacterData) || (type1 >= NuVTypes::AtenData)) result = NuVTypes::NoData;
				else result = type1;
				break;
			default:
				printf("Operator '%s' not in table for checkOperatorTypes.\n", NuCommand::data[func].keyword);
				result = NuVTypes::NoData;
				break;
		}
	}
	else
	{
		// Dissimilar types
		// First, there are no operations that we allow involving a pointer*except* for and also (in)equality with an integer
		if (type1 >= NuVTypes::AtenData)
		{
			if (type2 != NuVTypes::IntegerData) result = NuVTypes::NoData;
			else if ((func == NuCommand::OperatorEqualTo) || (func == NuCommand::OperatorNotEqualTo)) result = NuVTypes::IntegerData;
			else result = NuVTypes::NoData;
		}
		else if (type1 == NuVTypes::VectorData)
		{
			// We can do arithmetic and in-place assignments with simple numbers, but no test comparisons
			switch (func)
			{
				case (NuCommand::OperatorAdd):
				case (NuCommand::OperatorSubtract):
				case (NuCommand::OperatorMultiply):
				case (NuCommand::OperatorDivide):
				case (NuCommand::OperatorAssignment):
				case (NuCommand::OperatorAssignmentDivide):
				case (NuCommand::OperatorAssignmentMinus):
				case (NuCommand::OperatorAssignmentMultiply):
				case (NuCommand::OperatorAssignmentPlus):
					if ((type2 == NuVTypes::RealData) || (type2 == NuVTypes::IntegerData)) result = NuVTypes::VectorData;
					else result = NuVTypes::NoData;
					break;
				default:
					result = NuVTypes::NoData;
					break;
			}
		}
		else if (type1 == NuVTypes::CharacterData)
		{
			// We allow multiplication of a string by a number...
			if ((type2 == NuVTypes::RealData) || (type2 == NuVTypes::IntegerData))
			{
				switch (func)
				{
					case (NuCommand::OperatorMultiply):
					case (NuCommand::OperatorAssignment):
					case (NuCommand::OperatorAssignmentMultiply):
						result = NuVTypes::CharacterData;
						break;
					default:
						result = NuVTypes::NoData;
						break;
				}
			}
			else result = NuVTypes::NoData;
		}
	}
	// Print error message
	if (result == NuVTypes::NoData) msg.print("Error: Operator %s cannot act between types %s and %s.\n", NuCommand::data[func].keyword, NuVTypes::dataType(type1), NuVTypes::dataType(type2));
	return result;
}

// Add a node representing a whole statement to the execution list
void Tree::addStatement(TreeNode *leaf)
{
	if (leaf == NULL)
	{
		printf("Internal Error: NULL TreeNode passed to Tree::addStatement().\n");
		return;
	}
	printf("Added statement leaf node %li\n", leaf);
	leaf->setParent(this);
	statements_.add(leaf);
}

// Add an operator to the Tree
TreeNode *Tree::addOperator(NuCommand::Function func, int typearg, TreeNode *arg1, TreeNode *arg2)
{
	// Check compatibility between supplied nodes and the operator, since we didn't check the types in the lexer
	NuVTypes::DataType rtype = checkOperatorTypes(func, arg1->returnType(), arg2->returnType());
	if (rtype == NuVTypes::NoData) return NULL;
	// Create new command node
	NuCommandNode *leaf = new NuCommandNode(func);
	nodes_.own(leaf);
	// Add arguments and set parent
	leaf->addArguments(1,arg1);
	leaf->setParent(this);
	if (arg2 != NULL) leaf->addArguments(1,arg2);
	leaf->setReturnType(rtype);
	return leaf;
}

// Add 'if' statement
TreeNode *Tree::addIf(TreeNode *condition, TreeNode *expr1, TreeNode *expr2)
{
	msg.enter("Tree::addIf");
	// Create new command node
	NuCommandNode *leaf = new NuCommandNode(NuCommand::If);
	nodes_.own(leaf);
	leaf->addArguments(2, condition, expr1);
	if (expr2 != NULL) leaf->addArgument(expr2);
	leaf->setParent(this);
	msg.print(Messenger::Parse, "'If' statement added (%li).\n", leaf);
	msg.exit("Tree::addIf");
	return leaf;
}

// Add 'for' statement
TreeNode *Tree::addFor(TreeNode *init, TreeNode *condition, TreeNode *action, TreeNode *statements)
{
	msg.enter("Tree::addFor");
	// Create new command node
	NuCommandNode *leaf = new NuCommandNode(NuCommand::For);
	nodes_.own(leaf);
	leaf->addArguments(4, init, condition, action, statements);
	leaf->setParent(this);
	msg.print(Messenger::Parse, "'For' statement added (%li).\n", leaf);
	msg.exit("Tree::addFor");
	return leaf;
}

// Add function-based leaf node to topmost branch on stack
TreeNode *Tree::addFunctionLeaf(NuCommand::Function func, TreeNode *arglist)
{
	msg.enter("Tree::addFunctionLeaf");
	// Create new command node
	NuCommandNode *leaf = new NuCommandNode(func);
	nodes_.own(leaf);
	// Add argument list to node and set parent
	leaf->addArgumentList(arglist);
	leaf->setParent(this);
	// Store the function's return type
	leaf->setReturnType(NuCommand::data[func].returnType);
	// Check that the correct arguments were given to the command
	if (!leaf->checkArguments()) leaf = NULL;
	msg.exit("Tree::addFunctionLeaf");
	return leaf;
}

// Add ascoped command to the Tree
TreeNode *Tree::addScopedLeaf(NuCommand::Function func, int nargs, ...)
{
	// Create new scoped node and push it onto the stack
	ScopeNode *leaf = new ScopeNode(func);
	nodes_.own(leaf);
	scopeStack_.add(leaf);
	leaf->setParent(this);
	// Create variable argument parser
	va_list vars;
	va_start(vars,nargs);
	// Add arguments in the order they were provided
	for (int n=0; n<nargs; n++) leaf->addArguments(1, va_arg(vars, TreeNode*));
	va_end(vars);
	// Store the function's return type
	leaf->setReturnType(NuCommand::data[func].returnType);
	return leaf;
}

// Link two arguments together with their member pointers
TreeNode *Tree::joinArguments(TreeNode *arg1, TreeNode *arg2)
{
	arg1->prevArgument = arg2;
	arg2->nextArgument = arg1;
	printf("Joining arguments %li and %li\n", arg1, arg2);
	return arg1;
}

// Join two commands together
TreeNode *Tree::joinCommands(TreeNode *node1, TreeNode *node2)
{
	printf("Adding a statement joiner for %li and %li\n", node1, node2);
	NuCommandNode *leaf = new NuCommandNode(NuCommand::Joiner);
	nodes_.own(leaf);
	leaf->setParent(this);
	if (node1 != NULL) leaf->addArgument(node1);
	if (node2 != NULL) leaf->addArgument(node2);
	return leaf;
}

// Add on a new scope to the stack
TreeNode *Tree::pushScope()
{
	ScopeNode *node = new ScopeNode();
	scopeStack_.add(node);
	printf("ScopeNode is pushed.\n");
	return node;
}

// Pop the topmost scope node
void Tree::popScope()
{
	Refitem<ScopeNode,int> *ri = scopeStack_.last();
	if (ri == NULL) printf("Internal Error: No scoped node to pop from stack.\n");
	else scopeStack_.remove(ri);
	printf("ScopeNode is popped.\n");
}

/*
// Variables / Constants
*/

// Add constant value to tompost scope
TreeNode *Tree::addConstant(NuVTypes::DataType type, Dnchar *token)
{
	NuVariable *result = NULL;
	if (type == NuVTypes::IntegerData)
	{
		NuIntegerVariable *var = new NuIntegerVariable(atoi(token->get()), TRUE);
		nodes_.own(var);
		return var;
	}
	else if (type == NuVTypes::RealData)
	{
		NuRealVariable *var = new NuRealVariable(atof(token->get()), TRUE);
		nodes_.own(var);
		return var;
	}
	else if (type == NuVTypes::CharacterData)
	{
		NuCharacterVariable *var = new NuCharacterVariable(token->get(), TRUE);
		nodes_.own(var);
		return var;
	}
	else printf("Internal Error: Don't know how to create a constant of type '%s' for Tree.\n", NuVTypes::dataType(type));
	return NULL;
}

// Set current declared variable type
void Tree::setDeclaredVariableType(NuVTypes::DataType type)
{
	declaredType_ = type;
}

// Set declarations assignment flag
void Tree::setDeclarationAssignment(bool b)
{
	declarationAssignment_ = b;
}

// Add variable to topmost scope
TreeNode *Tree::addVariable(NuVTypes::DataType type, Dnchar *name, TreeNode *initialValue)
{
	msg.print(Messenger::Parse, "A new variable '%s' is being created with type %s.\n", name->get(), NuVTypes::dataType(type));
	// Get topmost scopenode
// 	printf("nscope = %i, %li  %li\n", scopeStack_.nItems(), scopeStack_.first(), scopeStack_.last());
	Refitem<ScopeNode,int> *ri = scopeStack_.last();
	if (ri == NULL)
	{
		printf("Internal Error: No current scope in which to define variable '%s'.\n", name->get());
		return NULL;
	}
	// Create the supplied variable in the list of the topmost scope
	NuVariable *var = ri->item->variables.create(type, name->get(), initialValue);
	if (!var)
	{
		printf("Internal Error: Failed to create variable '%s' in local scope.\n", name->get());
		return NULL;
	}
	printf("Created variable '%s' in scopenode %li   %i\n", name->get(), ri->item, scopeStack_.nItems());
	return var;
}

// Add variable to topmost scope using most recently set declared variable type
TreeNode *Tree::addVariable(Dnchar *name, TreeNode *initialValue)
{
	return addVariable(declaredType_, name, initialValue);
}

// Add array variable to topmost ScopeNode using the most recently declared type
TreeNode *Tree::addArrayVariable(Dnchar *name, TreeNode *sizeexpr, TreeNode *initialvalue)
{
	msg.print(Messenger::Parse, "A new array variable '%s' is being created with type %s.\n", name->get(), NuVTypes::dataType(declaredType_));
	// Get topmost scopenode
// 	printf("nscope = %i, %li  %li\n", scopeStack_.nItems(), scopeStack_.first(), scopeStack_.last());
	Refitem<ScopeNode,int> *ri = scopeStack_.last();
	if (ri == NULL)
	{
		printf("Internal Error: No current scope in which to define array variable '%s'.\n", name->get());
		return NULL;
	}
	// Create the supplied variable in the list of the topmost scope
	NuVariable *var = ri->item->variables.createArray(declaredType_, name->get(), sizeexpr, initialvalue);
	if (!var)
	{
		printf("Internal Error: Failed to create array variable '%s' in local scope.\n", name->get());
		return NULL;
	}
	printf("Created array variable '%s' in scopenode %li   %i\n", name->get(), ri->item, scopeStack_.nItems());
	return var;
}

// // Add constant value
// TreeNode *Tree::addVecConstant(NuVTypes::DataType type, TreeNode *value1, TreeNode *value2, TreeNode *value3)
// {
// 	NuVectorVariable *leaf = new NuVectorVariable(value1, value2, value3);
// 	scopeStack_.last()->item->variables.take(leaf);
// 	return leaf;
// }

// Search for variable in current scope
bool Tree::isVariableInScope(const char *name, NuVariable *&result)
{

	// If the declaredVariableType is set then this token has been found in a declaration statement.
	// ---> it must not exist in the local scope
	// In addition, if this is a declaration assignment, then we search as normal
	msg.print(Messenger::Parse, "Searching scope for variable '%s'...\n", name);
	if (declarationAssignment_ || (declaredType_ == NuVTypes::NoData))
	{
		printf("kljlk\n");
		// Search the current ScopeNode list for the variable name requested
		result = NULL;
		for (Refitem<ScopeNode,int> *ri = scopeStack_.last(); ri != NULL; ri =ri->prev)
		{
			ri->item->nodePrint(1, "SCOPENODE DATA");
			result = ri->item->variables.find(name);
			if (result != NULL) break;
		}
		// If result is NULL then we must return FALSE since the variable is not in a declaration
		// If the current declared variable type is NuVTypes::NoData then this is not a variable declaration and we must find the variable...
// 		if (result == NULL)
// 		{
// 			msg.print("Error: Variable '%s' has not been declared in the current scope.\n", name);
// 			return FALSE;
// 		}
		return TRUE;
	}
	else
	{
	printf("kljlk23423432\n");
		// So, we are declaring a variable in the local scope, which may shadow another in the global scope.
		// We are only concerned with whether this variable currently exists in the local scope...
	printf("searching scopenode %li...\n", scopeStack_.last());
		result = scopeStack_.last()->item->variables.find(name);
		if (result)
		{
			msg.print("Error: Repeat declaration of variable '%s' in the local scope.\n", name);
			return FALSE;
		}
		return TRUE;
	}
	return FALSE;
}

// Wrap named variable (and array index)
TreeNode *Tree::wrapVariable(NuVariable *var, TreeNode *arrayindex)
{
	// If an array index was given, check that the target variable is actually an array....
	if (arrayindex && (var->nodeType() != TreeNode::ArrayVarNode))
	{
		msg.print("Error: Array index given to variable '%s', but it is not an array.\n", var->name());
		return NULL;
	}
	VariableNode *vnode = new VariableNode(var);
	nodes_.own(vnode);
	vnode->setArrayIndex(arrayindex);
	vnode->setParent(this);
	return vnode;
}

/*
// Paths
*/

// Create a new path on the stack
TreeNode *Tree::createPath(TreeNode *node)
{
	msg.enter("Tree::createPath");
 	VariableNode *vnode = (VariableNode*) node;
	pathStack_.add(vnode, vnode);
	msg.print(Messenger::Parse, "A new path has been started, beginning from variable '%s'.\n", vnode->name());
	msg.exit("Tree::createPath");
	return vnode;
}

// Pop topmost path from stack
TreeNode *Tree::finalisePath()
{
	msg.enter("Tree::finalisePath");
	// Finalise the path before we remove it
	Refitem<VariableNode,TreeNode*> *ri = pathStack_.last();
	if (ri == NULL)
	{
		msg.print("Internal Error: No path on stack to finalise.\n");
		return NULL;
	}
	ri->item->finalisePath();
	TreeNode *result = ri->item;
	pathStack_.remove(ri);
	msg.exit("Tree::finalisePath");
	return result;
}

// Expand the topmost path on the stack
bool Tree::expandPath(Dnchar *name, TreeNode *arrayindex)
{
	msg.enter("Tree::expandPath");
	// Get last item on path stack
	Refitem<VariableNode,TreeNode*> *ri = pathStack_.last();
	if (ri == NULL)
	{
		printf("Internal Error: No path on stack to expand with accessor '%s'.\n", name->get());
		return NULL;
	}
	TreeNode *laststep = ri->data;
	msg.print(Messenger::Parse,"Tree is evaluating accessor '%s' as step %i from the basenode '%s'...\n", name->get(), ri->item->nArgs()+1, ri->item->name());
	// Find next step accessor
	StepNode *result = laststep->findAccessor(name->get(), arrayindex != NULL);
	// If we found a valid accessor, update the pathstack entry
	if (result)
	{
		msg.print(Messenger::Parse,"...OK - matching accessor found: return type is %s\n", NuVTypes::dataType(result->returnType()));
		ri->data = (TreeNode*) result;

		// Finalise the path before we remove it
		Refitem<VariableNode,TreeNode*> *ri = pathStack_.last();
		if (ri == NULL)
		{
			msg.print("Internal Error: No path on stack to expand!\n");
			msg.exit("Tree::expandPath");
			return FALSE;
		}
		ri->item->addArgument(result);
	}
	else msg.print("Error: Object of type '%s' has no matching accessor for '%s'.\n", NuVTypes::dataType(laststep->returnType()), name->get());
	msg.exit("Tree::expandPath");
	return result;
}


/*
// Forest
*/

Forest::Forest()
{
	// Public variables
	prev = NULL;
	next = NULL;
}

// Set name of forest
void Forest::setName(const char *s)
{
	name_ = s;
}

// Return name of forest
const char *Forest::name()
{
	return name_.get();
}

// Return number of trees in forest
int Forest::nTrees()
{
}

// Create a new tree
Tree *Forest::createTree()
{
}