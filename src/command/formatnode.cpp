/*
	*** Format node
	*** src/command/formatnode.cpp
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

#include "command/formatnode.h"
#include "variables/variablelist.h"
#include "base/messenger.h"
#include "base/parser.h"
#include "base/sysfunc.h"
#include <cstring>

// Constructor
FormatNode::FormatNode()
{
	// Private variables
	variable_ = NULL;
	length_ = 0;
	precision_ = 0;
	zeroPadInteger_ = FALSE;

	// Public variables
	next = NULL;
	prev = NULL;
}

// Get format node variable
Variable *FormatNode::variable()
{
	return variable_;
}

// Get field length
int FormatNode::length()
{
	return length_;
}

// Get field precision
int FormatNode::precision()
{
	return precision_;
}

// Return whether to pad integers with zeros
bool FormatNode::zeroPadInteger()
{
	return zeroPadInteger_;
}

// Set format node
bool FormatNode::set(const char *s, VariableList &vlist, bool astext)
{
	msg.enter("FormatNode::set");
	// Format of formatters is 'F%n.m': F = format quantity/variable, n.m = length,precision
	int pos1, pos2;
	static char specifier[512], len[32], pre[32];
	// 'Reset' strings
	specifier[0] = '\0';
	len[0] = '\0';
	pre[0] = '\0';
	// If we are adding as test, just add the string as a constant value
	if (astext)
	{
		variable_ = vlist.addConstant(s);
		msg.exit("FormatNote::set");
		return TRUE;
	}
	// Everything up to the '@' character is the quantity / variable
	for (pos1 = 0; s[pos1] != '\0'; pos1++)
	{
		if (s[pos1] == '@') break;
		specifier[pos1] = s[pos1];
	}
	specifier[pos1] = '\0';
	if (s[pos1] == '@')
	{
		// Everything past the '@' character (and up to a '.') is the length...
		pos1 ++;
		for (pos2 = pos1; s[pos2] != '\0'; pos2++)
		{
			if (s[pos2] == '.') break;
			len[pos2-pos1] = s[pos2];
		}
		len[pos2-pos1] = '\0';
		// Lastly, if a decimal point exists then the last part is the precision
		if (s[pos2] == '.')
		{
			for (pos1=pos2+1; s[pos1] != '\0'; pos1++) pre[pos1-(pos2+1)] = s[pos1];
			pre[pos1-(pos2+1)] = '\0';
		}
	}
	msg.print(Messenger::Parse,"FormatNode::set : Parsed specifier[%s] length[%s] precision[%s]\n", specifier, len, pre);
	// If we're given a variable, create a path to it
	if (specifier[0] == '$')
	{
		variable_ = vlist.addPath(&specifier[0]);
		if (variable_ == NULL)
		{
			msg.exit("FormatNode::set");
			return FALSE;
		}
	}
	else if (specifier[0] == '*')
	{
		// Check that this was the only character in the variable name....
		if (specifier[1] == '\0') variable_ = vlist.dummy();
		else
		{
			msg.print("Mangled dummy variable specifier '%s' found in format string.\n", specifier);
			msg.exit("FormatNode::set");
			return FALSE;
		}
	}
	else variable_ = vlist.addConstant(specifier);
	// Store the data
	length_ = (len[0] == '\0' ? 0 : atoi(len));
	precision_ = (pre[0] == '\0' ? 0 : atoi(pre));
	// If the first character of len[0] is zero (or the first is '-' and the second is zero) set padding for integers to true
	if (len[0] == '0' || ((len[0] == '-') && (len[1] == '0'))) zeroPadInteger_ = TRUE;
	msg.exit("FormatNode::set");
	return TRUE;
}
