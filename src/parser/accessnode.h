/*
	*** Access Node
	*** src/parser/accessnode.h
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

#ifndef ATEN_ACCESSNODE_H
#define ATEN_ACCESSNODE_H

#include "parser/treenode.h"
#include "parser/vtypes.h"

// Access Node
class AccessNode : public TreeNode
{
	public:
	// Constructor / Destructor
	AccessNode(int id, NuVTypes::DataType prevtype, NuVTypes::DataType returntype);
	~AccessNode();

	/*
	// Accessor Data
	*/
	private:
	// Expected type of preceding return value
	NuVTypes::DataType previousType_;
	// Accessor that this node attempts to access
	int accessor_;

	/*
	// Inherited Virtuals
	*/
	public:
	// Execute node
	bool execute(NuReturnValue &rv);
	// Print node contents
	void nodePrint(int offset, const char *prefix = "");
	// Set from returnvalue node
	bool set(NuReturnValue &rv);
	// Reset node
	void reset();
};

#endif
