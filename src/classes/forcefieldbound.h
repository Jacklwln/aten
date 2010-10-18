/*
	*** Forcefield bound term
	*** src/classes/forcefieldbound.h
	Copyright T. Youngs 2007-2010

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

#ifndef ATEN_FORCEFIELDBOUND_H
#define ATEN_FORCEFIELDBOUND_H

#include "base/dnchar.h"
#include "ff/forms.h"

// Forcefield bound interaction type
class ForcefieldBound
{
	public:
	// List pointers
	ForcefieldBound *prev, *next;
	// Constructor
	ForcefieldBound();
	// Forcefield Bound Interaction Type
	enum BoundType { NoInteraction, BondInteraction, AngleInteraction, TorsionInteraction, ImproperInteraction, UreyBradleyInteraction };
	static const char *boundType(ForcefieldBound::BoundType bt);
	static int boundTypeNAtoms(ForcefieldBound::BoundType bt);

	private:
	// Type of bound interaction
	BoundType type_;
	// Form of bound interaction type
	int form_;
	// Forcefield types involved in this term
	Dnchar typeNames_[MAXFFBOUNDTYPES];
	// Interaction parameter data
	double params_[MAXFFPARAMDATA];
	// Electrostatic scale factor (if torsion)
	double elecScale_;
	// VDW scale factor (if torsion)
	double vdwScale_;	

	public:
	// Set the type of bound interaction
	void setType(BoundType fc);
	// Return the type of bound interaction
	BoundType type() const;
	// Return functional form text
	const char *formText() const;
	// Return the functional form (cast as a bond style)
	BondFunctions::BondFunction bondForm() const;
	// Return the functional form (cast as a angle style)
	AngleFunctions::AngleFunction angleForm() const;
	// Return the functional form (cast as a torsion style)
	TorsionFunctions::TorsionFunction torsionForm() const;
	// Set the bond functional form
	void setBondForm(BondFunctions::BondFunction bf);
	// Set the angle functional form
	void setAngleForm(AngleFunctions::AngleFunction af);
	// Set the torsion functional form
	void setTorsionForm(TorsionFunctions::TorsionFunction tf);
	// Set the functional form by name
	bool setForm(const char *form);
	// Set the parameter data specified
	void setParameter(int i, double d);
	// Return parameter data specified
	double parameter(int i) const;
	// Return pointer to parameter array
	double *parameters();
	// Return the atom type 'n'
	const char *typeName(int n) const;
	// Return the atom type array
	Dnchar *typeNames();
	// Set the atom type 'n'
	void setTypeName(int n, const char *s);
	// Set both 1-4 scale factors
	void setScaleFactors(double escale, double vscale);
	// Set electrostatic scale factor
	void setElecScale(double d);
	// Return electrostatic scale factor (if torsion)
	double elecScale() const;
	// Set Vdw scale factor
	void setVdwScale(double d);
	// Return VDW scale factor (if torsion)
	double vdwScale() const;
	// Return if supplied names match those stored (in either 'direction')
	bool namesMatch(const char *namei, const char *namej,const char *namek = NULL, const char *namel = NULL);
};

#endif

