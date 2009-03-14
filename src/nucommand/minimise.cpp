/*
	*** Minimiser Commands
	*** src/nucommand/minimise.cpp
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

#include "nucommand/commands.h"
#include "parser/commandnode.h"
#include "methods/sd.h"
#include "methods/mc.h"
#include "methods/cg.h"
#include "model/model.h"

// Local variables
double econverge = 0.001, fconverge = 0.01, linetolerance = 0.0001;

// Minimise with conjugate gradient
bool NuCommand::function_CGMinimise(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	if (obj.notifyNull(Bundle::ModelPointer)) return FALSE;
	cg.setTolerance(linetolerance);
	cg.setNCycles(c->argi(0));
	// Store current positions of atoms so we can undo the minimisation
	Reflist< Atom, Vec3<double> > oldpos;
	for (Atom *i = obj.rs->atoms(); i != NULL; i = i->next) oldpos.add(i, i->r());
	cg.minimise(obj.rs, econverge, fconverge);
	// Finalise the 'transformation' (creates an undo state)
	obj.rs->finalizeTransform(oldpos, "Minimise (Conjugate Gradient)");
	rv.reset();
	return TRUE;
}

// Set convergence criteria
bool NuCommand::function_Converge(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	econverge = c->argd(0);
	fconverge = c->argd(1);
	rv.reset();
	return TRUE;
}

// Set line minimiser tolerance
bool NuCommand::function_LineTol(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	linetolerance = c->argd(0);
	rv.reset();
	return TRUE;
}

// Minimise current model with Monte-Carlo method ('mcminimise <maxsteps>')
bool NuCommand::function_MCMinimise(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	if (obj.notifyNull(Bundle::ModelPointer)) return FALSE;
	mc.setNCycles(c->argi(0));
	// Store current positions of atoms so we can undo the minimisation
	Reflist< Atom, Vec3<double> > oldpos;
	for (Atom *i = obj.rs->atoms(); i != NULL; i = i->next) oldpos.add(i, i->r());
	mc.minimise(obj.rs, econverge, fconverge);
	// Finalise the 'transformation' (creates an undo state)
	obj.rs->finalizeTransform(oldpos, "Minimise (Monte Carlo)");
	rv.reset();
	return TRUE;
}

// Minimise current model with Steepest Descent method ('sdminimise <maxsteps>')
bool NuCommand::function_SDMinimise(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	if (obj.notifyNull(Bundle::ModelPointer)) return FALSE;
	sd.setTolerance(linetolerance);
	sd.setNCycles(c->argi(0));
	// Store current positions of atoms so we can undo the minimisation
	Reflist< Atom, Vec3<double> > oldpos;
	for (Atom *i = obj.rs->atoms(); i != NULL; i = i->next) oldpos.add(i, i->r());
	sd.minimise(obj.rs, econverge, fconverge);
	// Finalise the 'transformation' (creates an undo state)
	obj.rs->finalizeTransform(oldpos, "Minimise (Steepest Descent)");
	rv.reset();
	return TRUE;
}

bool NuCommand::function_SimplexMinimise(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	rv.reset();
	return FALSE;
}
