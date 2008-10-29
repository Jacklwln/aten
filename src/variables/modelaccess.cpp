/*
	*** Model Access
	*** src/variables/modelaccess.cpp
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

#include "variables/modelaccess.h"
#include "variables/accessstep.h"
#include "variables/vaccess.h"
#include "model/model.h"
#include "base/messenger.h"

ModelAccessors modelAccessors;

// Constructor
ModelAccessors::ModelAccessors()
{
 	accessorPointers[ModelAccessors::Atoms] = addListAccessor("atoms",		VTypes::AtomData);
 	accessorPointers[ModelAccessors::Atomtypes] = addListAccessor("atomtypes",	VTypes::ForcefieldAtomData);
 	accessorPointers[ModelAccessors::Bonds] = addListAccessor("bonds",		VTypes::BondData);
 	accessorPointers[ModelAccessors::Cell] = addAccessor("cell",			VTypes::CellData, TRUE);
 	accessorPointers[ModelAccessors::Frame] = addAccessor("frame",			VTypes::ModelData, TRUE);
//  	accessorPointers[ModelAccessors::Frames] = addListAccessor("frames",		VTypes::ModelData);
 	accessorPointers[ModelAccessors::Name] = addAccessor("name",			VTypes::CharacterData,	FALSE);
 	accessorPointers[ModelAccessors::NAngleTerms] = addAccessor("nangleterms",	VTypes::IntegerData,	TRUE);
 	accessorPointers[ModelAccessors::NAtoms] = addAccessor("natoms",		VTypes::IntegerData,	TRUE);
 	accessorPointers[ModelAccessors::NAtomtypes] = addAccessor("natomtypes",	VTypes::IntegerData,	TRUE);
 	accessorPointers[ModelAccessors::NBonds] = addAccessor("nbonds",		VTypes::IntegerData,	TRUE);
 	accessorPointers[ModelAccessors::NBondTerms] = addAccessor("nbondterms",	VTypes::IntegerData,	TRUE);
 	accessorPointers[ModelAccessors::NPatterns] = addAccessor("npatterns",		VTypes::IntegerData,	TRUE);
 	accessorPointers[ModelAccessors::NTorsionTerms] = addAccessor("ntorsionterms",	VTypes::IntegerData,	TRUE);
 	accessorPointers[ModelAccessors::Patterns] = addListAccessor("patterns",	VTypes::PatternData);
};

// Retrieve specified data
bool ModelAccessors::retrieve(void *classptr, AccessStep *step, ReturnValue &rv)
{
	msg.enter("ModelAccessors::retrieve");
	bool result = TRUE;
	// Cast pointer into Model*
	Model *m = (Model*) classptr;
	if (m == NULL) printf("Warning - NULL Model pointer passed to ModelAccessors::retrieve.\n");
// 	printf("Enumerated ID supplied to ModelAccessors is %i.\n", vid);
	// Check range of supplied vid
	int vid = step->variableId();
	if ((vid < 0) || (vid > ModelAccessors::nAccessors))
	{
		printf("Unknown enumeration %i given to ModelAccessors::retrieve.\n", vid);
		msg.exit("ModelAccessors::retrieve");
		return FALSE;
	}
	// Get arrayindex (if there is one) and check that we needed it in the first place
	int index;
	if (!checkIndex(index, step, accessorPointers[vid]))
	{
		msg.exit("ModelAccessors::retrieve");
		return FALSE;
	}
	// Retrieve value based on enumerated id
	switch (vid)
	{
		case (ModelAccessors::Atoms):
			if (index > m->nAtoms())
			{
				msg.print("Atom array index is out of bounds for model '%s'\n", m->name());
				result = FALSE;
			}
			else rv.set(m->atom(index-1), VTypes::AtomData);
			break;
		case (ModelAccessors::Atomtypes):
			rv.set(m->uniqueType(index-1), VTypes::ForcefieldAtomData);
			break;
		case (ModelAccessors::Bonds):
			if (index > m->nBonds())
			{
				msg.print("Bond array index is out of bounds for model '%s'\n", m->name());
				result = FALSE;
			}
			else rv.set(m->bond(index-1), VTypes::BondData);
			break;
		case (ModelAccessors::Cell):
			rv.set(m->cell(), VTypes::CellData);
			break;
		case (ModelAccessors::Frame):
			rv.set(m->currentFrame(), VTypes::ModelData);
			break;
// 		case (ModelAccessors::Frames):
// 			if (index > m->nTrajectoryFrames())
// 			{
// 				msg.print("Frame array index is out of bounds for model '%s'\n", m->name());
// 				result = FALSE;
// 			}
// 			else rv.set(m->atom(index-1), VTypes::AtomData);
		case (ModelAccessors::Name):
			rv.set(m->name());
			break;
 		case (ModelAccessors::NAngleTerms):
			rv.set(m->nUniqueAngleTerms());
			break;
		case (ModelAccessors::NAtoms):
			rv.set(m->nAtoms());
			break;
		case (ModelAccessors::NAtomtypes):
			rv.set(m->nUniqueTypes());
			break;
		case (ModelAccessors::NBonds):
			rv.set(m->nBonds());
			break;
		case (ModelAccessors::NBondTerms):
			rv.set(m->nUniqueBondTerms());
			break;
		case (ModelAccessors::NPatterns):
			rv.set(m->nPatterns());
			break;
		case (ModelAccessors::NTorsionTerms):
			rv.set(m->nUniqueTorsionTerms());
			break;
		case (ModelAccessors::Patterns):
			if (index > m->nPatterns())
			{
				msg.print("Pattern array index is out of bounds for model '%s'\n", m->name());
				result = FALSE;
			}
			else rv.set(m->pattern(index-1), VTypes::PatternData);
			break;
		default:
			printf("ModelAccessors::retrieve doesn't know how to use member '%s'.\n", accessorPointers[vid]->name());
			result = FALSE;
			break;
	}
	msg.exit("ModelAccessors::retrieve");
	return result;
}

// Set specified data
bool ModelAccessors::set(void *classptr, AccessStep *step, Variable *srcvar)
{
	msg.enter("ModelAccessors::set");
	bool result = TRUE;
	// Cast pointer into Model*
	Model *m = (Model*) classptr;
	if (m == NULL) printf("Warning - NULL Model pointer passed to ModelAccessors::set.\n");
// 	printf("Enumerated ID supplied to ModelAccessors is %i.\n", vid);
	// Check range of supplied vid
	int vid = step->variableId();
	if ((vid < 0) || (vid > ModelAccessors::nAccessors))
	{
		printf("Unknown enumeration %i given to ModelAccessors::set.\n", vid);
		msg.exit("ModelAccessors::set");
		return FALSE;
	} 
	// Get arrayindex (if there is one) and check that we needed it in the first place
	int index;
	if (!checkIndex(index, step, accessorPointers[vid]))
	{
		msg.exit("ModelAccessors::set");
		return FALSE;
	}
	// Set value based on enumerated id
	switch (vid)
	{
		case (ModelAccessors::Name):
			m->setName(srcvar->asCharacter());
			break;
		case (ModelAccessors::Atoms):
		case (ModelAccessors::Cell):
		case (ModelAccessors::Bonds):
 		case (ModelAccessors::NAngleTerms):
		case (ModelAccessors::NAtoms):
		case (ModelAccessors::NAtomtypes):
		case (ModelAccessors::NBonds):
		case (ModelAccessors::NBondTerms):
		case (ModelAccessors::NPatterns):
		case (ModelAccessors::NTorsionTerms):
		case (ModelAccessors::Patterns):
			msg.print("Member '%s' in Model is read-only.\n", accessorPointers[vid]->name());
			result = FALSE;
			break;
		default:
			printf("ModelAccessors::set doesn't know how to use member '%s'.\n", accessorPointers[vid]->name());
			result = FALSE;
			break;
	}
	msg.exit("ModelAccessors::set");
	return result;
}