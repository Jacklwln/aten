/*
	*** Real Variable
	*** src/parser/real.h
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

#ifndef ATEN_NUREALVARIABLE_H
#define ATEN_NUREALVARIABLE_H

#include "parser/variable.h"
#include "parser/accessor.h"

// Real Variable
class NuRealVariable : public NuVariable
{
	public:
	// Constructor / Destructor
	NuRealVariable(double d = 0.0, bool constant = FALSE);
	~NuRealVariable();

	/*
	// Set / Get
	*/
	public:
	// Return value of node
	bool execute(NuReturnValue &rv);
	// Set from returnvalue node
	bool set(NuReturnValue &rv);
	// Reset node
	void reset();

	/*
	// Variable Data
	*/
	private:
	// Real data
	double realData_;
	// Print node contents
	void nodePrint(int offset, const char *prefix = "");
};

#endif