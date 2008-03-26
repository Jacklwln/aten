/*
	*** Glyph command functions
	*** src/command/glyph.cpp
	Copyright T. Youngs 2007,2008

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

#include "command/commandlist.h"
#include "base/master.h"
#include "model/model.h"
#include "classes/glyph.h"

// Local variables
Atom *atomdata[MAXGLYPHDATA];
Vec3<double> vecdata[MAXGLYPHDATA];
bool wasatomdata[MAXGLYPHDATA];


// Add glyph to current model
int CommandData::function_CA_NEWGLYPH(Command *&c, Bundle &obj)
{
	if (obj.notifyNull(BP_MODEL)) return CR_FAIL;
	// Get glyph style
	GlyphStyle gs = GS_from_text(c->argc(0));
	master.current.gl = obj.m->addGlyph();
	if (gs == GS_NITEMS) msg(Debug::None,"Warning: Unrecognised glyph style '%s' - not set.\n",c->argc(0));
	master.current.gl->setType(gs);
	return CR_SUCCESS;
}

// Associate atom with current glyph
int CommandData::function_CA_SETGLYPHATOMF(Command *&c, Bundle &obj)
{
	if (obj.notifyNull(BP_MODEL+BP_GLYPH)) return CR_FAIL;
	// Check range of supplied data item
	int d = c->argi(0) - 1;
	if ((d < 0) || (d >= MAXGLYPHDATA))
	{
		msg(Debug::None,"Data index given to 'setglyphatom' (%i) is out of range.\n", d);
		return CR_FAIL;
	}
	// If second argument was given, it refers to either an atom by pointer or by id
	Atom *target = obj.i;
	if (c->hasArg(1))
	{
		if (c->argt(1) == VT_ATOM) target = c->arga(1);
		else target = obj.m->atom(c->argi(1) - 1);
	}
	// Finally, check pointer currently in target and store it
	obj.gl->data[d].setAtom(target, AV_F);
	if (target == NULL) msg(Debug::None,"Warning - NULL atom stored in glyph data %i.\n",d);
	return CR_SUCCESS;
}

// Associate atom with current glyph
int CommandData::function_CA_SETGLYPHATOMR(Command *&c, Bundle &obj)
{
	if (obj.notifyNull(BP_MODEL+BP_GLYPH)) return CR_FAIL;
	// Check range of supplied data item
	int d = c->argi(0) - 1;
	if ((d < 0) || (d >= MAXGLYPHDATA))
	{
		msg(Debug::None,"Data index given to 'setglyphatom' (%i) is out of range.\n", d);
		return CR_FAIL;
	}
	// If second argument was given, it refers to either an atom by pointer or by id
	Atom *target = obj.i;
	if (c->hasArg(1))
	{
		if (c->argt(1) == VT_ATOM) target = c->arga(1);
		else target = obj.m->atom(c->argi(1) - 1);
	}
	// Finally, check pointer currently in target and store it
	obj.gl->data[d].setAtom(target, AV_R);
	if (target == NULL) msg(Debug::None,"Warning - NULL atom stored in glyph data %i.\n",d);
	return CR_SUCCESS;
}

// Associate atom with current glyph
int CommandData::function_CA_SETGLYPHATOMV(Command *&c, Bundle &obj)
{
	if (obj.notifyNull(BP_MODEL+BP_GLYPH)) return CR_FAIL;
	// Check range of supplied data item
	int d = c->argi(0) - 1;
	if ((d < 0) || (d >= MAXGLYPHDATA))
	{
		msg(Debug::None,"Data index given to 'setglyphatom' (%i) is out of range.\n", d);
		return CR_FAIL;
	}
	// If second argument was given, it refers to either an atom by pointer or by id
	Atom *target = obj.i;
	if (c->hasArg(1))
	{
		if (c->argt(1) == VT_ATOM) target = c->arga(1);
		else target = obj.m->atom(c->argi(1) - 1);
	}
	// Finally, check pointer currently in target and store it
	obj.gl->data[d].setAtom(target, AV_V);
	if (target == NULL) msg(Debug::None,"Warning - NULL atom stored in glyph data %i.\n",d);
	return CR_SUCCESS;
}

// Associate atoms with current glyph
int CommandData::function_CA_SETGLYPHATOMSF(Command *&c, Bundle &obj)
{
	if (obj.notifyNull(BP_MODEL+BP_GLYPH)) return CR_FAIL;
	// If second argument was given, it refers to either an atom by pointer or by id
	Atom *target;
	for (int d=0; d<MAXGLYPHDATA; d++)
	{
		target = NULL;
		if (c->hasArg(d))
		{
			if (c->argt(d) == VT_ATOM) target = c->arga(d);
			else target = obj.m->atom(c->argi(d) - 1);
		}
		else break;
		// Finally, check pointer currently in target and store it
		obj.gl->data[d].setAtom(target, AV_F);
		if (target == NULL) msg(Debug::None,"Warning - NULL atom stored in glyph data %i.\n",d);
	}
	return CR_SUCCESS;
}

// Associate atoms with current glyph
int CommandData::function_CA_SETGLYPHATOMSR(Command *&c, Bundle &obj)
{
	if (obj.notifyNull(BP_MODEL+BP_GLYPH)) return CR_FAIL;
	// If second argument was given, it refers to either an atom by pointer or by id
	Atom *target;
	for (int d=0; d<MAXGLYPHDATA; d++)
	{
		target = NULL;
		if (c->hasArg(d))
		{
			if (c->argt(d) == VT_ATOM) target = c->arga(d);
			else target = obj.m->atom(c->argi(d) - 1);
		}
		else break;
		// Finally, check pointer currently in target and store it
		obj.gl->data[d].setAtom(target, AV_R);
		if (target == NULL) msg(Debug::None,"Warning - NULL atom stored in glyph data %i.\n",d);
	}
	return CR_SUCCESS;
}
// Associate atoms with current glyph
int CommandData::function_CA_SETGLYPHATOMSV(Command *&c, Bundle &obj)
{
	if (obj.notifyNull(BP_MODEL+BP_GLYPH)) return CR_FAIL;
	// If second argument was given, it refers to either an atom by pointer or by id
	Atom *target;
	for (int d=0; d<MAXGLYPHDATA; d++)
	{
		target = NULL;
		if (c->hasArg(d))
		{
			if (c->argt(d) == VT_ATOM) target = c->arga(d);
			else target = obj.m->atom(c->argi(d) - 1);
		}
		else break;
		// Finally, check pointer currently in target and store it
		obj.gl->data[d].setAtom(target, AV_V);
		if (target == NULL) msg(Debug::None,"Warning - NULL atom stored in glyph data %i.\n",d);
	}
	return CR_SUCCESS;
}

// Store vector data in current glyph
int CommandData::function_CA_SETGLYPHDATA(Command *&c, Bundle &obj)
{
	if (obj.notifyNull(BP_MODEL+BP_GLYPH)) return CR_FAIL;
	// Check range of supplied data item
	int d = c->argi(0) - 1;
	if ((d < 0) || (d >= MAXGLYPHDATA))
	{
		msg(Debug::None,"Data index given to 'setglyphatom' (%i) is out of range.\n", d);
		return CR_FAIL;
	}
	obj.gl->data[d].setVector(c->argd(1), c->argd(2), c->argd(3));
	return CR_SUCCESS;
}

// Set 'solid' property of current glyph
int CommandData::function_CA_SETGLYPHSOLID(Command *&c, Bundle &obj)
{
	if (obj.notifyNull(BP_MODEL+BP_GLYPH)) return CR_FAIL;
	// Check range of supplied data item
	obj.gl->setSolid(c->argb(0));
	return CR_SUCCESS;
}
