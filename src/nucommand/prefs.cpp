/*
	*** Prefs Commands
	*** src/nucommand/prefs.cpp
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
#include "main/aten.h"
#include "gui/gui.h"
#include "model/model.h"
#include "ff/forcefield.h"
#include "classes/prefs.h"

// Angle label postfix
bool NuCommand::function_AngleLabel(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	prefs.setAngleLabel(c->argc(0));
	gui.mainView.postRedisplay();
	rv.reset();
	return TRUE;
}

// Atom quadric detail
bool NuCommand::function_AtomDetail(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	prefs.setAtomDetail(c->argi(0));
	if (obj.rs != NULL) obj.rs->changeLog.add(Log::Visual);
	gui.mainView.postRedisplay();
	rv.reset();
	return TRUE;
}

// Bond quadric detail
bool NuCommand::function_BondDetail(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	prefs.setBondDetail(c->argi(0));
	if (obj.rs != NULL) obj.rs->changeLog.add(Log::Visual);
	gui.mainView.postRedisplay();
	rv.reset();
	return TRUE;
}

// Colours
bool NuCommand::function_Colour(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	Prefs::PenColour col = Prefs::penColour(c->argc(0));
	if (col == Prefs::nPenColours) return FALSE;
	Vec3<GLfloat> colvec = c->arg3GLf(1);
	GLfloat alpha = (c->hasArg(4) ? (GLfloat) c->argd(4) : 1.0f);
	prefs.setColour(col, colvec.x, colvec.y, colvec.z, alpha);
	if (obj.rs != NULL) obj.rs->changeLog.add(Log::Visual);
	gui.mainView.postRedisplay();
	rv.reset();
	return TRUE;
}

// Common elements list
bool NuCommand::function_CommonElements(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	prefs.setCommonElements(c->argc(0));
	rv.reset();
	return TRUE;
}

// Set density unit to use in output ('densityunits <unit>')
bool NuCommand::function_DensityUnits(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	Prefs::DensityUnit du = Prefs::densityUnit(c->argc(0));
	if (du == Prefs::nDensityUnits) return FALSE;
	else prefs.setDensityUnits(du);
	rv.reset();
	return TRUE;
}

// Distance label postfix
bool NuCommand::function_DistanceLabel(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	prefs.setDistanceLabel(c->argc(0));
	gui.mainView.postRedisplay();
	rv.reset();
	return TRUE;
}

// Set electrostatics cutoff ('ecut <cut>')
bool NuCommand::function_ECut(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	prefs.setElecCutoff(c->argd(0));
	rv.reset();
	return TRUE;
}

// Set electrostatic method to use ('elec none|coulomb|ewald|ewaldauto')
bool NuCommand::function_Elec(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	Electrostatics::ElecMethod em = Electrostatics::elecMethod(c->argc(0));
	if (em == Electrostatics::nElectrostatics) return FALSE;
	switch (em)
	{
		// Set ewald sum params ('elec ewald <alpha> <kx ky kz>')
		case (Electrostatics::Ewald):
			if (!c->hasArg(4))
			{
				msg.print("Must supply the alpha parameter and kmax vectors to used this electrostatics option.\n");
				return FALSE;
			}
			prefs.setEwaldAlpha(c->argd(1));
			prefs.setEwaldKvec(c->arg3i(2));
			break;
		// Set ewald precision
		case (Electrostatics::EwaldAuto):
			if (!c->hasArg(1))
			{
				msg.print("Must supply the Ewald precision parameter to used this electrostatics option.\n");
				return FALSE;
			}
			prefs.setEwaldPrecision(c->argd(1));
			break;
	}
	// Set method
	prefs.setElectrostaticsMethod(em);
	prefs.setCalculateElec(em == Electrostatics::None ? FALSE : TRUE);
	rv.reset();
	return TRUE;
}

// Set element's ambient colour
bool NuCommand::function_ElementAmbient(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	int el = elements().findAlpha(c->argc(0));
	if (el == 0) return FALSE;
	elements().setAmbientColour(el,0,c->argi(1));
	elements().setAmbientColour(el,1,c->argi(2));
	elements().setAmbientColour(el,2,c->argi(3));
	if (obj.rs != NULL) obj.rs->changeLog.add(Log::Visual);
	gui.mainView.postRedisplay();
	rv.reset();
	return TRUE;
}

// Set element's diffuse colour
bool NuCommand::function_ElementDiffuse(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	int el = elements().findAlpha(c->argc(0));
	if (el == 0) return FALSE;
	elements().setDiffuseColour(el,0,c->argi(1));
	elements().setDiffuseColour(el,1,c->argi(2));
	elements().setDiffuseColour(el,2,c->argi(3));
	if (obj.rs != NULL) obj.rs->changeLog.add(Log::Visual);
	gui.mainView.postRedisplay();
	rv.reset();
	return TRUE;
}

// Set element's radius
bool NuCommand::function_ElementRadius(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	int el = elements().findAlpha(c->argc(0));
	if (el == 0) return FALSE;
	elements().setAtomicRadius(el, c->argd(1));
	if (obj.rs != NULL) obj.rs->changeLog.add(Log::Visual);
	gui.mainView.postRedisplay();
	rv.reset();
	return TRUE;
}

// Set energy unit to use in output ('energyunits <unit>')
bool NuCommand::function_EnergyUnits(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	Prefs::EnergyUnit eu = Prefs::energyUnit(c->argc(0));
	if (eu == Prefs::nEnergyUnits) return FALSE;
	else
	{
		prefs.setEnergyUnit(eu);
		// Convert loaded forcefields
		for (Forcefield *ff = aten.forcefields(); ff != NULL; ff = ff->next) ff->convertParameters();
	}
	rv.reset();
	return TRUE;
}

// GL Options
bool NuCommand::function_GL(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	Prefs::GlOption go = Prefs::glOption(c->argc(0));
	if (go == Prefs::nGlOptions) return FALSE;
	if (c->argb(1)) prefs.addGlOption(go);
	else prefs.removeGlOption(go);
	gui.mainView.initGl();
	if (obj.rs != NULL) obj.rs->changeLog.add(Log::Visual);
	gui.mainView.postRedisplay();
	rv.reset();
	return TRUE;
}

// Set distance to use when adding hydrogens ('hdistance <d>')
bool NuCommand::function_HDistance(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	prefs.setHydrogenDistance(c->argd(0));
	rv.reset();
	return TRUE;
}

// Turn on/off calculation of intra ('intra on|off')
bool NuCommand::function_Intra(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	prefs.setCalculateIntra(c->argb(0));
	rv.reset();
	return TRUE;
}

// Key bindings
bool NuCommand::function_Key(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	Prefs::ModifierKey mk = Prefs::modifierKey(c->argc(0));
	Prefs::KeyAction ka = Prefs::keyAction(c->argc(1));
	if ((mk != Prefs::nModifierKeys) && (ka != Prefs::nKeyActions)) prefs.setKeyAction(mk,ka);
	else return FALSE;
	rv.reset();
	return TRUE;
}

// Text label pointsize
bool NuCommand::function_LabelSize(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	prefs.setLabelSize(c->argi(0));
	gui.mainView.postRedisplay();
	rv.reset();
	return TRUE;
}

// Turn on/off spotlight
bool NuCommand::function_Light(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	prefs.setSpotlightActive(c->argb(0));
	gui.mainView.postRedisplay();
	rv.reset();
	return TRUE;
}

// Set ambient component of spotlight
bool NuCommand::function_LightAmbient(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	prefs.setSpotlightColour(Prefs::AmbientComponent, c->argGLf(0), c->argGLf(1), c->argGLf(2));
	gui.mainView.postRedisplay();
	rv.reset();
	return TRUE;
}

// Set diffuse component of spotlight
bool NuCommand::function_LightDiffuse(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	prefs.setSpotlightColour(Prefs::DiffuseComponent, c->argGLf(0), c->argGLf(1), c->argGLf(2));
	gui.mainView.postRedisplay();
	rv.reset();
	return TRUE;
}

bool NuCommand::function_LightPosition(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	prefs.setSpotlightPosition(c->argGLf(0), c->argGLf(1), c->argGLf(2));
	gui.mainView.postRedisplay();
	rv.reset();
	return TRUE;
}

// Set specular component of spotlight
bool NuCommand::function_LightSpecular(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	prefs.setSpotlightColour(Prefs::SpecularComponent, c->argGLf(0), c->argGLf(1), c->argGLf(2));
	gui.mainView.postRedisplay();
	rv.reset();
	return TRUE;
}

// Mouse bindings
bool NuCommand::function_Mouse(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	Prefs::MouseButton mb = Prefs::mouseButton(c->argc(0));
	Prefs::MouseAction ma = Prefs::mouseAction(c->argc(1));
	if ((ma != Prefs::nMouseActions) && (mb != Prefs::nMouseButtons)) prefs.setMouseAction(mb,ma);
	else return FALSE;
	rv.reset();
	return TRUE;
}

// Atom screen radii
bool NuCommand::function_Radius(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	Atom::DrawStyle ds = Atom::drawStyle(c->argc(0));
	if (ds != Atom::nDrawStyles) prefs.setAtomStyleRadius(ds, c->argd(1));
	else return FALSE;
	rv.reset();
	return TRUE;
}

// Set whether replicate folds atoms beforehand
bool NuCommand::function_ReplicateFold(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	prefs.setReplicateFold(c->argb(0));
	msg.print("Folding of atoms into unit cell before replicate is %s.\n", prefs.replicateFold() ? "on" : "off");
	rv.reset();
	return TRUE;
}

// Set whether replicate trims atoms afterwards
bool NuCommand::function_ReplicateTrim(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	prefs.setReplicateTrim(c->argb(0));
	msg.print("Trimming of atoms outside of unit cell after replicate is %s.\n", prefs.replicateTrim() ? "on" : "off");
	rv.reset();
	return TRUE;
}

// Colouring scheme
bool NuCommand::function_Scheme(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	if (c->hasArg(0))
	{
		Prefs::ColouringScheme cs = Prefs::colouringScheme(c->argc(0));
		if (cs != Prefs::nColouringSchemes)
		{
			prefs.setColourScheme(cs);
			if (obj.rs != NULL) obj.rs->changeLog.add(Log::Visual);
			gui.mainView.postRedisplay();
		}
		else return FALSE;
	}
	else msg.print( "Current atom colouring scheme is '%s'\n", Prefs::colouringScheme( prefs.colourScheme() ));
	rv.reset();
	return TRUE;
}

// Atom shininess
bool NuCommand::function_Shininess(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	prefs.setShininess(c->argi(0));
	if (obj.rs != NULL) obj.rs->changeLog.add(Log::Visual);
	gui.mainView.postRedisplay();
	rv.reset();
	return TRUE;
}

// Render Objects on screen
bool NuCommand::function_ShowOnScreen(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	if (c->hasArg(0))
	{
		Prefs::ViewObject vo = Prefs::viewObject(c->argc(0));
		if (vo != Prefs::nViewObjects)
		{
			prefs.setVisibleOnScreen(vo, c->argb(1));
			if (obj.rs != NULL) obj.rs->changeLog.add(Log::Visual);
			gui.mainView.postRedisplay();
		}
		else return FALSE;
	}
	else
	{
		char shown[512], notshown[512];
		shown[0] = '\0';
		notshown[0] = '\0';
		strcat(shown,"Visible: ");
		strcat(notshown,"Hidden : ");
		msg.print( "Current on-screen object status:\n");
		for (int i=0; i<Prefs::nViewObjects; i++)
		{
			if (prefs.isVisibleOnScreen( (Prefs::ViewObject) i))
			{
				strcat(shown, Prefs::viewObject( (Prefs::ViewObject) i));
				strcat(shown, " ");
			}
			else
			{
				strcat(notshown, Prefs::viewObject( (Prefs::ViewObject) i));
				strcat(notshown, " ");
			}
		}
		msg.print( "%s\n", shown);
		msg.print( "%s\n", notshown);
	}
	rv.reset();
	return TRUE;
}

// Render Objects on saved images
bool NuCommand::function_ShowOnImage(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	if (c->hasArg(0))
	{
		Prefs::ViewObject vo = Prefs::viewObject(c->argc(0));
		if (vo != Prefs::nViewObjects) prefs.setVisibleOffScreen(vo, c->argb(1));
		else return FALSE;
	}
	else
	{
		char shown[512], notshown[512];
		shown[0] = '\0';
		notshown[0] = '\0';
		strcat(shown,"Visible: ");
		strcat(notshown,"Hidden : ");
		msg.print( "Current on-image object status:\n");
		for (int i=0; i<Prefs::nViewObjects; i++)
		{
			if (prefs.isVisibleOffScreen( (Prefs::ViewObject) i))
			{
				strcat(shown, Prefs::viewObject( (Prefs::ViewObject) i));
				strcat(shown, " ");
			}
			else
			{
				strcat(notshown, Prefs::viewObject( (Prefs::ViewObject) i));
				strcat(notshown, " ");
			}
		}
		msg.print( "%s\n", shown);
		msg.print( "%s\n", notshown);
	}
	rv.reset();
	return TRUE;
}

// View Styles
bool NuCommand::function_Style(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	if (c->hasArg(0))
	{
		Atom::DrawStyle ds = Atom::drawStyle(c->argc(0));
		if (ds != Atom::nDrawStyles)
		{
			prefs.setRenderStyle(ds);
			if (obj.rs != NULL) obj.rs->changeLog.add(Log::Visual);
			gui.mainView.postRedisplay();
		rv.reset();
		}
		else return FALSE;
	}
	else msg.print( "Current model drawing style is '%s'\n", Atom::drawStyle(prefs.renderStyle()));
	rv.reset();
	return TRUE;
}

// Set whether to perform manual buffer swapping ('swapbuffers [on|off]')
bool NuCommand::function_SwapBuffers(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	if (c->hasArg(0)) prefs.setManualSwapBuffers(c->argb(0));
	else msg.print("Manual swapping of buffers is %s.\n", prefs.manualSwapBuffers() ? "on" : "off");
	rv.reset();
	return TRUE;
}

// Set whether to use nice text rendering ('usenicetext on|off')
bool NuCommand::function_UseNiceText(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	prefs.setUseNiceText(c->argb(0));
	rv.reset();
	return TRUE;
}

// Set VDW cutoff ('vcut <cut>')
bool NuCommand::function_VCut(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	prefs.setVdwCutoff(c->argd(0));
	rv.reset();
	return TRUE;
}

// Turn on/off calculation of vdw ('vdw on|off')
bool NuCommand::function_Vdw(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	prefs.setCalculateVdw(c->argb(0));
	rv.reset();
	return TRUE;
}

// Display or set zoom throttle ('zoomthrottle [ratio]')
bool NuCommand::function_ZoomThrottle(NuCommandNode *c, Bundle &obj, NuReturnValue &rv)
{
	if (c->hasArg(0)) prefs.setZoomThrottle(c->argd(0));
	else msg.print("Zooming throttle is %f.\n", prefs.zoomThrottle());
	rv.reset();
	return TRUE;
}
