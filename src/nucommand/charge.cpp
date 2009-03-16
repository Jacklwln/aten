/*
	*** Charge Commands
	*** src/nucommand/charge.cpp
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

#include "parser/commandnode.h"
#include "nucommand/commands.h"
#include "model/model.h"
#include "base/pattern.h"

// Assign charges from forcefield atom types ('chargeff')
bool NuCommand::function_ChargeFF(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	if (obj.notifyNull(Bundle::ModelPointer)) return FALSE;
	obj.rs->beginUndoState("Assign forcefield charges");
	bool result = obj.rs->assignForcefieldCharges();
	obj.rs->endUndoState();
	return (result ? TRUE : FALSE);
}

// Copy atomic charges from model to model's current trajectory frame
bool NuCommand::function_ChargeFromModel(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	if (obj.notifyNull(Bundle::ModelPointer)) return FALSE;
	if (obj.rs == obj.m) 
	{
		msg.print("Error - 'chargefrommodel' requires an active trajectory frame in the current model.\n");
		return FALSE;
	}
	else obj.rs->copyAtomData(obj.m, Atom::ChargeData);
	return TRUE;
}

// Assign charge to a pattern atom, propagated over the model ('chargepatom <id> <q>')
bool NuCommand::function_ChargePAtom(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	if (obj.notifyNull(Bundle::ModelPointer)) return FALSE;
	obj.rs->beginUndoState("Charge single pattern atom");
	obj.rs->chargePatternAtom(obj.p,c->argi(0),c->argd(1));
	obj.rs->endUndoState();
	return TRUE;
}

// Assign charge to selected atoms in model ('charge <q>')
bool NuCommand::function_Charge(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	if (obj.notifyNull(Bundle::ModelPointer)) return FALSE;
	obj.rs->beginUndoState("Charge selected atoms");
	for (Atom *i = obj.rs->firstSelected(); i != NULL; i = i->nextSelected()) obj.rs->chargeAtom(i, c->argd(0));
	obj.rs->endUndoState();
	return TRUE;
}

// Assign charges to a specified forcefield type ('chargetype <atomtype> <q>')
bool NuCommand::function_ChargeType(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	printf("Not implemented yet!\n");
	return FALSE;
}

// Clears charge in current model ('clearcharges')
bool NuCommand::function_ClearCharges(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	if (obj.notifyNull(Bundle::ModelPointer)) return FALSE;
	obj.rs->beginUndoState("Remove charges");
	obj.rs->clearCharges();
	obj.rs->endUndoState();
	return TRUE;
}