/*
	*** Matrix Variable and Array
	*** src/parser/matrix.cpp
	Copyright T. Youngs 2007-2015

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

#include "parser/matrix.h"
#include "parser/stepnode.h"

ATEN_USING_NAMESPACE

// Constructors
MatrixVariable::MatrixVariable(bool constant)
{
	// Private variables
	returnType_ = VTypes::MatrixData;
	readOnly_ = constant;
}
MatrixVariable::MatrixVariable(Matrix m, bool constant) : matrixData_(m)
{
	// Private variables
	returnType_ = VTypes::MatrixData;
	readOnly_ = constant;
}
MatrixVariable::MatrixVariable(TreeNode* xx, TreeNode* xy, TreeNode* xz, TreeNode* yx, TreeNode* yy, TreeNode* yz, TreeNode* zx, TreeNode* zy, TreeNode* zz)
{
	// Private variables
	constXX_ = xx;
	constXY_ = xy;
	constXZ_ = xz;
	constYX_ = yx;
	constYY_ = yy;
	constYZ_ = yz;
	constZX_ = zx;
	constZY_ = zy;
	constZZ_ = zz;
	readOnly_ = true;
	returnType_ = VTypes::MatrixData;
}

// Destructor
MatrixVariable::~MatrixVariable()
{
}

/*
// Set / Get
*/

// Set value of variable
bool MatrixVariable::set(ReturnValue& rv)
{
	if (readOnly_)
	{
		Messenger::print("A constant value (in this case a matrix) cannot be assigned to.");
		return false;
	}
	bool success = false;
	if (rv.arraySize() == -1) matrixData_ = rv.asMatrix(success);
	else if (rv.arraySize() == 9)
	{
		for (int n=0; n<9; ++n)
		{
			matrixData_[n/3*4+n%3] = rv.asDouble(n, success);
			if (!success) break;
		}
	}
	else
	{
		Messenger::print("Error: Array assigned to matrix variable must contain nine elements.");
		success = false;
	}
	return success;
}

// Reset variable
bool MatrixVariable::reCreate()
{
	ReturnValue rv[9];
	if (!constXX_->execute(rv[0])) return false;
	if (!constXY_->execute(rv[1])) return false;
	if (!constXZ_->execute(rv[2])) return false;
	if (!constYX_->execute(rv[3])) return false;
	if (!constYY_->execute(rv[4])) return false;
	if (!constYZ_->execute(rv[5])) return false;
	if (!constZX_->execute(rv[6])) return false;
	if (!constZY_->execute(rv[7])) return false;
	if (!constZZ_->execute(rv[8])) return false;
	bool success;
	for (int n=0; n<9; ++n)
	{
		matrixData_[n/3*4+n%3] = rv[n].asDouble(success);
		if (!success) return false;
	}
	return true;
}

// Reset variable
void MatrixVariable::reset()
{
	matrixData_.zero();
}

// Return value of node
bool MatrixVariable::execute(ReturnValue& rv)
{
	// If this matrix is a constant, read the nine stored expressions to recreate it
	if (readOnly_) reCreate();
	rv.set(matrixData_);
	return true;
}

// Print node contents
void MatrixVariable::nodePrint(int offset, const char* prefix)
{
	// Construct tabbed offset
	QString tab;
	for (int n=0; n<offset-1; n++) tab += '\t';
	if (offset > 1) tab += "   |--> ";
	tab += prefix;

	// Output node data
	if (readOnly_)
	{
		reCreate();
		printf("[C]%s{%f,%f,%f,%f,%f,%f,%f,%f,%f} (constant value)\n", qPrintable(tab), matrixData_[0], matrixData_[1], matrixData_[2], matrixData_[4], matrixData_[5], matrixData_[6], matrixData_[8], matrixData_[9], matrixData_[10]);
	}
	else printf("[V]%s{%f,%f,%f,%f,%f,%f,%f,%f,%f} (variable, name=%s)\n", qPrintable(tab), matrixData_[0], matrixData_[1], matrixData_[2], matrixData_[4], matrixData_[5], matrixData_[6], matrixData_[8], matrixData_[9], matrixData_[10], qPrintable(name_));
}

/*
 * Accessors
 */

// Accessor data
Accessor MatrixVariable::accessorData[MatrixVariable::nAccessors] = {
	{ "determinant", VTypes::DoubleData, false, true },
	{ "xx", VTypes::DoubleData, false, false },
	{ "xy", VTypes::DoubleData, false, false },
	{ "xz", VTypes::DoubleData, false, false },
	{ "yx", VTypes::DoubleData, false, false },
	{ "yy", VTypes::DoubleData, false, false },
	{ "yz", VTypes::DoubleData, false, false },
	{ "zx", VTypes::DoubleData, false, false },
	{ "zy", VTypes::DoubleData, false, false },
	{ "zz", VTypes::DoubleData, false, false }
};

// Function data
FunctionAccessor MatrixVariable::functionData[MatrixVariable::nFunctions] = {
	{ ".dummy",	VTypes::IntegerData,	"",	"" }
};

// Search variable access list for provided accessor (call private static function)
StepNode* MatrixVariable::findAccessor(QString name, TreeNode* arrayIndex, TreeNode* argList)
{
	return MatrixVariable::accessorSearch(name, arrayIndex, argList);
}

// Private static function to search accessors
StepNode* MatrixVariable::accessorSearch(QString name, TreeNode* arrayIndex, TreeNode* argList)
{
	Messenger::enter("MatrixVariable::accessorSearch");
	StepNode* result = NULL;
	int i = 0;
	i = Variable::searchAccessor(name, nAccessors, accessorData);
	if (i == -1)
	{
		// No accessor found - is it a function definition?
		// for (i = 0; i < nFunctions; i++) if (strcmp(qPrintable(functionData[i].name),s) == 0) break;
		i = Variable::searchAccessor(name, nFunctions, functionData);
		if (i == -1)
		{
			Messenger::print("Error: Type 'Matrix' has no member or function named '%s'.", qPrintable(name));
			Messenger::exit("MatrixVariable::accessorSearch");
			return NULL;
		}
		Messenger::print(Messenger::Parse, "FunctionAccessor match = %i (%s)", i, qPrintable(functionData[i].name));
		if (arrayIndex != NULL)
		{
			Messenger::print("Error: Array index given to 'Matrix' function named '%s'.", qPrintable(name));
			Messenger::exit("MatrixVariable::accessorSearch");
			return NULL;
		}
		// Add and check supplied arguments...
		result = new StepNode(i, VTypes::MatrixData, functionData[i].returnType);
		result->addJoinedArguments(argList);
		if (!result->checkArguments(functionData[i].arguments, qPrintable(functionData[i].name)))
		{
			Messenger::print("Error: Syntax for 'Matrix' function '%s' is '%s(%s)'.", qPrintable(functionData[i].name), qPrintable(functionData[i].name), qPrintable(functionData[i].argText) );
			delete result;
			result = NULL;
		}
	}
	else
	{
		Messenger::print(Messenger::Parse, "Accessor match = %i (%s)", i, qPrintable(accessorData[i].name));
		// Were we given an array index when we didn't want one?
		if ((accessorData[i].arraySize == 0) && (arrayIndex != NULL))
		{
			Messenger::print("Error: Irrelevant array index provided for member '%s'.", qPrintable(accessorData[i].name));
			result = NULL;
		}
		// Were we given an argument list when we didn't want one?
		if (argList != NULL)
		{
			Messenger::print("Error: Argument list given to 'Matrix&' array member '%s'.", qPrintable(name));
			Messenger::exit("MatrixVariable::accessorSearch");
			return NULL;
		}
		else result = new StepNode(i, VTypes::MatrixData, arrayIndex, accessorData[i].returnType, accessorData[i].isReadOnly, accessorData[i].arraySize);
	}
	Messenger::exit("MatrixVariable::accessorSearch");
	return result;
}

// Retrieve desired value
bool MatrixVariable::retrieveAccessor(int i, ReturnValue& rv, bool hasArrayIndex, int arrayIndex)
{
	Messenger::enter("MatrixVariable::retrieveAccessor");
	// Cast 'i' into Accessors enum value
	if ((i < 0) || (i >= nAccessors))
	{
		printf("Internal Error: Accessor id %i is out of range for Matrix type.\n", i);
		Messenger::exit("MatrixVariable::retrieveAccessor");
		return false;
	}
	Accessors acc = (Accessors) i;
	// Check for correct lack/presence of array index given
	if (hasArrayIndex)
	{
		Messenger::print("Error: Unnecessary array index provided for member '%s'.", qPrintable(accessorData[i].name));
		Messenger::exit("MatrixVariable::retrieveAccessor");
		return false;
	}
	// Get current data from ReturnValue
	bool result = true;
	Matrix m = rv.asMatrix(result);
	if (result) switch (acc)
	{
		case (MatrixVariable::Determinant):
			rv.set(m.determinant());
			break;
		case (MatrixVariable::XX):
		case (MatrixVariable::XY):
		case (MatrixVariable::XZ):
		case (MatrixVariable::YX):
		case (MatrixVariable::YY):
		case (MatrixVariable::YZ):
		case (MatrixVariable::ZX):
		case (MatrixVariable::ZY):
		case (MatrixVariable::ZZ):
			rv.set(m[(acc-MatrixVariable::XX)/3*4+(acc-MatrixVariable::XX)%3]);
			break;
		default:
			printf("Internal Error: Access to member '%s' has not been defined in MatrixVariable.\n", qPrintable(accessorData[i].name));
			result = false;
			break;
	}
	Messenger::exit("MatrixVariable::retrieveAccessor");
	return result;
}

// Set desired value
bool MatrixVariable::setAccessor(int i, ReturnValue& sourcerv, ReturnValue& newValue, bool hasArrayIndex, int arrayIndex)
{
	Messenger::enter("MatrixVariable::setAccessor");
	// Cast 'i' into Accessors enum value
	if ((i < 0) || (i >= nAccessors))
	{
		printf("Internal Error: Accessor id %i is out of range for Matrix type.\n", i);
		Messenger::exit("MatrixVariable::setAccessor");
		return false;
	}
	Accessors acc = (Accessors) i;

	// Check for correct lack/presence of array index given to original accessor, and nature of new value
	bool result = checkAccessorArrays(accessorData[acc], newValue, hasArrayIndex, arrayIndex);
	if (!result)
	{
		Messenger::exit("MatrixVariable::setAccessor");
		return false;
	}

	// Get current data from ReturnValue
	Matrix& m = sourcerv.matrix();
	if (result) switch (acc)
	{
		case (MatrixVariable::XX):
		case (MatrixVariable::XY):
		case (MatrixVariable::XZ):
		case (MatrixVariable::YX):
		case (MatrixVariable::YY):
		case (MatrixVariable::YZ):
		case (MatrixVariable::ZX):
		case (MatrixVariable::ZY):
		case (MatrixVariable::ZZ):
			m[(acc-MatrixVariable::XX)/3*4+(acc-MatrixVariable::XX)%3] = newValue.asDouble(result);
			break;
		default:
			printf("MatrixVariable::setAccessor doesn't know how to use member '%s'.\n", qPrintable(accessorData[acc].name));
			result = false;
			break;
	}
	Messenger::exit("MatrixVariable::setAccessor");
	return result;
}

// Perform desired function
bool MatrixVariable::performFunction(int i, ReturnValue& rv, TreeNode* node)
{
	Messenger::enter("MatrixVariable::performFunction");
	// Cast 'i' into Accessors enum value
	if ((i < 0) || (i >= nFunctions))
	{
		printf("Internal Error: FunctionAccessor id %i is out of range for Matrix type.\n", i);
		Messenger::exit("MatrixVariable::performFunction");
		return false;
	}

	// Get current data from ReturnValue
	bool result = true;
	Matrix m = rv.asMatrix();
	if (result) switch (i)
	{
		default:
			printf("Internal Error: Access to function '%s' has not been defined in MatrixVariable.\n", qPrintable(functionData[i].name));
			result = false;
			break;
	}
	Messenger::exit("MatrixVariable::performFunction");
	return result;
}

/*
 * Variable Array
 */

// Constructor
MatrixArrayVariable::MatrixArrayVariable(TreeNode* sizeexpr, bool constant) : arraySizeExpression_(sizeexpr)
{
	// Private variables
	returnType_ = VTypes::MatrixData;
	matrixArrayData_ = NULL;
	arraySize_ = 0;
	nodeType_ = TreeNode::ArrayVarNode;
	readOnly_ = constant;
}

// Destructor
MatrixArrayVariable::~MatrixArrayVariable()
{
	if (matrixArrayData_ != NULL) delete[] matrixArrayData_;
}

/*
// Set / Get
*/

// Set from returnvalue node
bool MatrixArrayVariable::set(ReturnValue& rv)
{
	if (readOnly_)
	{
		Messenger::print("A constant value (in this case a matrix array) cannot be assigned to.");
		return false;
	}
	if (matrixArrayData_ == NULL)
	{
		printf("Internal Error: Array '%s' has not been initialised.\n", qPrintable(name_));
		return false;
	}
	// Loop over array elements and set them
	for (int i=0; i<arraySize_; i++) matrixArrayData_[i] = rv.asMatrix();
	return true;
}

// Set array element from returnvalue node
bool MatrixArrayVariable::setAsArray(ReturnValue& rv, int arrayIndex)
{
	if (readOnly_)
	{
		Messenger::print("A constant value (in this case a matrix array?) cannot be assigned to.");
		return false;
	}
	if (matrixArrayData_ == NULL)
	{
		printf("Internal Error: Array '%s' has not been initialised.\n", qPrintable(name_));
		return false;
	}
	// Check index
	if ((arrayIndex < 0) || (arrayIndex >= arraySize_))
	{
		Messenger::print("Index %i out of bounds for array '%s'.", arrayIndex+1, qPrintable(name_));
		return false;
	}
	// Set individual element
	matrixArrayData_[arrayIndex] = rv.asMatrix();
	return true;
}

// Reset variable
void MatrixArrayVariable::reset()
{
	if (matrixArrayData_ == NULL)
	{
		printf("Internal Error: Array '%s' has not been initialised.\n", qPrintable(name_));
		return;
	}
	// Loop over array elements and set them
	for (int i=0; i<arraySize_; i++) matrixArrayData_[i].zero();
}

// Return value of node
bool MatrixArrayVariable::execute(ReturnValue& rv)
{
	Messenger::print("A whole matrix array ('%s') cannot be passed as a value.", qPrintable(name_));
	return false;
}

// Return value of node as array
bool MatrixArrayVariable::executeAsArray(ReturnValue& rv, int arrayIndex)
{
	// Check bounds
	if ((arrayIndex < 0) || (arrayIndex >= arraySize_))
	{
		Messenger::print("Error: Array index %i is out of bounds for array '%s'.", arrayIndex+1, qPrintable(name_));
		return false;
	}
	rv.set( matrixArrayData_[arrayIndex] );
	return true;
}

// Print node contents
void MatrixArrayVariable::nodePrint(int offset, const char* prefix)
{
	// Construct tabbed offset
	QString tab;
	for (int n=0; n<offset-1; n++) tab += '\t';
	if (offset > 1) tab += "   |--> ";
	tab += prefix;

	// Output node data
	printf("[V]%s (integer array, name=%s, current size=%i)\n", qPrintable(tab), qPrintable(name_), arraySize_);
}

// Initialise array
bool MatrixArrayVariable::initialise()
{
	// We define our own initialise() function to take over from the inherited default from Variable
	// Get size of array to create
	ReturnValue newsize;
	if (!arraySizeExpression_->execute(newsize))
	{
		Messenger::print("Failed to find size for matrix array '%s'.", qPrintable(name_));
		return false;
	}
	// If the array is already allocated, free it only if the size is different
	if ((arraySize_ != newsize.asInteger()) && (matrixArrayData_ != NULL)) { delete[] matrixArrayData_; matrixArrayData_ = NULL; }
	// Store new array size
	arraySize_ = newsize.asInteger();
	if ((arraySize_ > 0) && (matrixArrayData_ == NULL)) matrixArrayData_ = new Matrix[arraySize_];
	if (initialValue_ == NULL) reset();
	else
	{
		ReturnValue rv;
		if (initialValue_->execute(rv))
		{
			if (!set(rv)) return false;
		}
		else return false;
	}
	return true;
}

// Search variable access list for provided accessor
StepNode* MatrixArrayVariable::findAccessor(QString name, TreeNode* arrayIndex, TreeNode* argList)
{
	return MatrixVariable::accessorSearch(name, arrayIndex, argList);
}
