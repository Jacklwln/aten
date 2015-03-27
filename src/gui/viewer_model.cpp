/*
	*** Model Rendering
	*** src/gui/viewer_model.cpp
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

#include "gui/viewer.uih"
#include "model/model.h"

ATEN_USING_NAMESPACE

// Render full Model
void Viewer::renderModel(Model* source, int viewPortX, int viewPortY, int viewPortWidth, int viewPortHeight)
{
	Messenger::enter("Viewer::renderModel");
	GLfloat colour[4];

	// Valid pointer passed?
	if (source == NULL)
	{
		Messenger::exit("Viewer::renderModel");
		return;
	}
	Messenger::print(Messenger::Verbose, " --> RENDERING BEGIN : source model pointer = %p, renderpoint = %d", source, source->changeLog.log(Log::Total));

	// Setup view for model, in the supplied viewport
	source->setupView(viewPortX, viewPortY, viewPortWidth, viewPortHeight);

	// Set initial transformation matrix, including any translation occurring from cell...
	modelTransformationMatrix_ = source->modelViewMatrix();
	modelTransformationMatrix_.applyTranslation(source->cell()->centre());
	
	// Set target matrix mode and reset it, and set colour mode
	glColorMaterial(GL_FRONT_AND_BACK, GL_AMBIENT_AND_DIFFUSE);
	glEnable(GL_COLOR_MATERIAL);
	glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);

	// Render rotation globe in small viewport in lower right-hand corner
	if (prefs.viewRotationGlobe())
	{
		int n = prefs.globeSize();
// 		if (aten_->nVisibleModels() > 2) n /= 2;
		glViewport(viewPortX+viewPortWidth-n, viewPortY, n, n);
		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
		glOrtho(-1.0, 1.0, -1.0, 1.0, -10.0, 10.0);
		glMatrixMode(GL_MODELVIEW);
		glLoadIdentity();
		Matrix A = modelTransformationMatrix_;
		A.removeTranslationAndScaling();
		A[14] = -1.2;
		glMultMatrixd(A.matrix());
		prefs.copyColour(Prefs::GlobeColour, colour);
		glColor4fv(colour);
		primitives_[primitiveSet_].rotationGlobe().sendToGL();
	}

	// Prepare for model rendering
	glViewport(viewPortX, viewPortY, viewPortWidth, viewPortHeight);
	glMatrixMode(GL_PROJECTION);
	glLoadMatrixd(source->modelProjectionMatrix().matrix());
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();

	// Draw unit cell (if one exists)
	if (source->cell()->type() != UnitCell::NoCell)
	{
		// Copy colour for cell
		GLfloat colour[4];
		prefs.copyColour(Prefs::UnitCellColour, colour);
		
		
		// Reset current view matrix and apply the cell's axes matrix
		glLoadIdentity();
		Matrix A = source->modelViewMatrix() * source->cell()->axes();
		glMultMatrixd(A.matrix());
		
		// Draw a wire cube for the cell
		primitives_[primitiveSet_].wireCube().sendToGL();

		// Copy colour for axes, move to llh corner, and draw them
		prefs.copyColour(Prefs::UnitCellAxesColour, colour);
		glColor4fv(colour);
		glTranslated(-0.5, -0.5, -0.5);
		Vec3<double> v = source->cell()->lengths();
		glScaled(1.0 / v.x, 1.0 / v.y, 1.0 / v.z);
		primitives_[primitiveSet_].cellAxes().sendToGL();
	}

	// Get RenderGroup for model (it will be updated if necessary by the called function)
	RenderGroup& renderGroup = source->renderGroup(primitives_[primitiveSet_]);

	// Draw main model (atoms, bonds, etc.)
	Matrix offset;
	for (int x = -source->repeatCellsNegative(0); x <= source->repeatCellsPositive(0); ++x)
	{
		for (int y = -source->repeatCellsNegative(1); y <= source->repeatCellsPositive(1); ++y)
		{
			for (int z = -source->repeatCellsNegative(2); z <= source->repeatCellsPositive(2); ++z)
			{
				offset.setIdentity();
				offset.addTranslation(source->cell()->axes() * Vec3<double>(x,y,z));
				
				renderGroup.sendToGL(modelTransformationMatrix_);
			}
		}
	}

	Messenger::exit("Viewer::renderModel");
}
