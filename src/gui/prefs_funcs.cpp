/*
	*** Qt prefs window functions
	*** src/gui/prefs_funcs.cpp
	Copyright T. Youngs 2007-2011

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

#include "main/aten.h"
#include "gui/prefs.h"
#include "gui/selectelement.h"
#include "gui/tcombobox.h"
#include "model/model.h"
#include "base/sysfunc.h"

// Constructor
AtenPrefs::AtenPrefs(QWidget *parent) : QDialog(parent)
{
	ui.setupUi(this);
	refreshing_ = FALSE;

	int i;
	// Add elements to element list and select first item
	QListWidgetItem *item;
	for (i=0; i<elements().nElements(); i++)
	{
		item = new QListWidgetItem(ui.ElementList);
		item->setText(elements().name(i));
	}
	ui.ElementList->setCurrentRow(0);
}

// Set controls
void AtenPrefs::setControls()
{
	msg.enter("AtenPrefs::setControls");
	refreshing_ = TRUE;

	// Select the first element in the elements list
	ui.ElementList->setCurrentRow(0);

	// Set Controls
	// View Page - Style Tab
	ui.StickRadiusSpin->setValue(prefs.atomStyleRadius(Atom::StickStyle));
	ui.TubeRadiusSpin->setValue(prefs.atomStyleRadius(Atom::TubeStyle));
	ui.SphereRadiusSpin->setValue(prefs.atomStyleRadius(Atom::SphereStyle));
	ui.ScaledRadiusSpin->setValue(prefs.atomStyleRadius(Atom::ScaledStyle));
	ui.StickBondRadiusSpin->setValue(prefs.bondStyleRadius(Atom::StickStyle));
	ui.TubeBondRadiusSpin->setValue(prefs.bondStyleRadius(Atom::TubeStyle));
	ui.SphereBondRadiusSpin->setValue(prefs.bondStyleRadius(Atom::SphereStyle));
	ui.ScaledBondRadiusSpin->setValue(prefs.bondStyleRadius(Atom::ScaledStyle));
	ui.SelectionScaleSpin->setValue(prefs.selectionScale());
	ui.AngleLabelFormatEdit->setText(prefs.angleLabelFormat());
	ui.DistanceLabelFormatEdit->setText(prefs.distanceLabelFormat());
	ui.LabelSizeSpin->setValue(prefs.labelSize());
	ui.RenderDashedAromaticsCheck->setChecked(prefs.renderDashedAromatics());
	ui.DrawHydrogenBondsCheck->setChecked(prefs.drawHydrogenBonds());
	ui.HydrogenBondDotRadiusSpin->setValue(prefs.hydrogenBondDotRadius());
	// View Page - Colours Tab
	ui.ColoursTable->setRowCount(Prefs::nObjectColours);
	QColor qcol;
	for (int n = 0; n < Prefs::nObjectColours; ++n)
	{
		QTableWidgetItem *item = new QTableWidgetItem(Prefs::objectColourName( (Prefs::ObjectColour) n ));
		ui.ColoursTable->setItem(n, 0, item);
		item = new QTableWidgetItem();
		double *colour = prefs.colour( (Prefs::ObjectColour) n );
		qcol.setRgbF( colour[0], colour[1], colour[2], colour[3] );
		item->setBackgroundColor(qcol);
		ui.ColoursTable->setItem(n, 1, item);
	}
	// View Page - Rendering / Quality tab
	ui.SpotlightAmbientColourFrame->setColour(prefs.spotlightColour(Prefs::AmbientComponent));
	ui.SpotlightDiffuseColourFrame->setColour(prefs.spotlightColour(Prefs::DiffuseComponent));
	ui.SpotlightSpecularColourFrame->setColour(prefs.spotlightColour(Prefs::SpecularComponent));
	double *pos = prefs.spotlightPosition();
	ui.SpotlightPositionXSpin->setValue(pos[0]);
	ui.SpotlightPositionYSpin->setValue(pos[1]);
	ui.SpotlightPositionZSpin->setValue(pos[2]);
	ui.ShininessSpin->setValue(prefs.shininess());
	ui.PrimitiveQualitySpin->setValue(prefs.primitiveQuality());
	ui.ImagePrimitiveQualitySpin->setValue(prefs.imagePrimitiveQuality());
	ui.ImagePrimitivesGroup->setChecked(!prefs.reusePrimitiveQuality());
	ui.LevelOfDetailNLevelsSpin->setValue(prefs.levelsOfDetail());
	ui.LevelOfDetailStartZSpin->setValue(prefs.levelOfDetailStartZ());
	ui.LevelOfDetailWidthSpin->setValue(prefs.levelOfDetailWidth());
	ui.TransparencyGroup->setChecked(prefs.transparencyCorrect());
	ui.TransparencyNSlicesSpin->setValue(prefs.transparencyNBins());
	ui.TransparencyStartZSpin->setValue(prefs.transparencyBinStartZ());
	ui.TransparencyBinWidthSpin->setValue(prefs.transparencyBinWidth());
	ui.LineAliasingCheck->setChecked(prefs.lineAliasing());
	ui.PolygonAliasingCheck->setChecked(prefs.polygonAliasing());
	ui.MultiSamplingCheck->setChecked(prefs.multiSampling());
	ui.NearClipSpin->setValue(prefs.clipNear());
	ui.FarClipSpin->setValue(prefs.clipFar());
	ui.NearDepthSpin->setValue(prefs.depthNear());
	ui.FarDepthSpin->setValue(prefs.depthFar());
	ui.FrameCurrentModelCheck->setChecked(prefs.frameCurrentModel());
	ui.FrameWholeViewCheck->setChecked(prefs.frameWholeView());

	// Set controls in interaction page
	ui.LeftMouseCombo->setCurrentIndex(prefs.mouseAction(Prefs::LeftButton));
	ui.MiddleMouseCombo->setCurrentIndex(prefs.mouseAction(Prefs::MiddleButton));
	ui.RightMouseCombo->setCurrentIndex(prefs.mouseAction(Prefs::RightButton));
	ui.WheelMouseCombo->setCurrentIndex(prefs.mouseAction(Prefs::WheelButton));
	ui.ShiftButtonCombo->setCurrentIndex(prefs.keyAction(Prefs::ShiftKey));
	ui.CtrlButtonCombo->setCurrentIndex(prefs.keyAction(Prefs::CtrlKey));
	ui.AltButtonCombo->setCurrentIndex(prefs.keyAction(Prefs::AltKey));
	ui.ZoomThrottleSpin->setValue(prefs.zoomThrottle());
	ui.MouseMoveFilterSpin->setValue(prefs.mouseMoveFilter());

	// Set controls in Program page
	ui.CommonElementsEdit->setText(prefs.commonElements());
	ui.DensityUnitCombo->setCurrentIndex(prefs.densityUnit());
	ui.EnergyUnitCombo->setCurrentIndex(prefs.energyUnit());
	ui.EnergyUpdateSpin->setValue(prefs.energyUpdate());
	ui.HAddDistanceSpin->setValue(prefs.hydrogenDistance());
	ui.MaxCuboidsSpin->setValue(prefs.maxCuboids());
	ui.MaxRingsSpin->setValue(prefs.maxRings());
	ui.MaxRingSizeSpin->setValue(prefs.maxRingSize());
	ui.MaxUndoLevelsSpin->setValue(prefs.maxUndoLevels());
	ui.ModelUpdateSpin->setValue(prefs.modelUpdate());

	// Set pen colours and colourscale names and checks
	Dnchar name;
	for (int n=0; n<10; n++)
	{
		QListWidgetItem *item = ui.ScaleList->item(n);
		name.sprintf("%i. %s", n+1, prefs.colourScale[n].name());
		item->setText(name.get());
		item->setCheckState( prefs.colourScale[n].visible() ? Qt::Checked : Qt::Unchecked);
	}
	updateScalePointsList();

	// Set controls in Energy/FF page
	ui.CalculateIntraCheck->setChecked(prefs.calculateIntra());
	ui.CalculateVdwCheck->setChecked(prefs.calculateVdw());
	ui.ElectrostaticMethodCombo->setCurrentIndex(prefs.electrostaticsMethod());
	ui.VdwCutoffSpin->setValue(prefs.vdwCutoff());
	ui.ElecCutoffSpin->setValue(prefs.elecCutoff());
	ui.EwaldPrecisionMantissaSpin->setValue(prefs.ewaldPrecision().mantissa());
	ui.EwaldPrecisionExponentSpin->setValue(prefs.ewaldPrecision().exponent());
	ui.EwaldManualAlphaSpin->setValue(prefs.ewaldAlpha());
	ui.EwaldManualKXSpin->setValue(prefs.ewaldKMax().x);
	ui.EwaldManualKYSpin->setValue(prefs.ewaldKMax().y);
	ui.EwaldManualKZSpin->setValue(prefs.ewaldKMax().z);
	ui.FunctionalFormList->clear();
	QListWidgetItem *listitem;
	for (int n=0; n<VdwFunctions::nVdwFunctions; ++n)
	{
		listitem = new QListWidgetItem(ui.FunctionalFormList);
		listitem->setText(VdwFunctions::VdwFunctions[n].name);
	}
	ui.FunctionalFormList->setCurrentRow(0);

	// External Programs
	ui.TemporaryDirEdit->setText(prefs.tempDir());
	ui.MopacExecutableEdit->setText(prefs.mopacExe());
	ui.EncoderExecutableEdit->setText(prefs.encoderExe());
	ui.EncoderArgumentsEdit->setText(prefs.encoderArguments());
	ui.EncoderPostExecutableEdit->setText(prefs.encoderPostExe());
	ui.EncoderPostArgumentsEdit->setText(prefs.encoderPostArguments());

	// Store current values in the Prefs structure...
	prefsBackup_ = prefs;
	elements().backupData();

	refreshing_ = FALSE;
	msg.exit("AtenPrefs::setControls");
}

// Close window
void AtenPrefs::on_PrefsCancelButton_clicked(bool checked)
{
	// Copy old preferences values back into main structure, update view and close window
	prefs = prefsBackup_;
	elements().restoreData();

	aten.currentModel()->changeLog.add(Log::Style);
	gui.mainWidget()->postRedisplay();
	reject();
}

// Store current prefs values as defaults
void AtenPrefs::on_PrefsSaveAsDefaultButton_clicked(bool checked)
{
	Dnchar filename;
	filename.sprintf("%s%c%s%cprefs.dat", aten.homeDir(), PATHSEP, aten.atenDir(), PATHSEP);
	// Temporarily disable prefs window
	gui.prefsDialog->setEnabled(FALSE);
	bool result = prefs.save(filename);
	gui.prefsDialog->setEnabled(TRUE);
	if (!result) QMessageBox::warning(NULL, "Aten", "User preferences file could not be saved.\n", QMessageBox::Ok, QMessageBox::Ok);
	else msg.print("Prefs file saved to '%s'\n", filename.get());
}

/*
// Element Page
*/

void AtenPrefs::on_ElementList_currentRowChanged(int row)
{
	// Update the info for the current element
	ui.ElementNameLabel->setText(elements().name(row));
	ui.ElementSymbolLabel->setText(elements().symbol(row));
	ui.ElementMassLabel->setText(ftoa(elements().atomicMass(row)));
	ui.ElementColourFrame->setColour(elements().colour(row));
	ui.ElementRadiusSpin->setValue(elements().atomicRadius(row));
}

void AtenPrefs::on_ElementColourButton_clicked(bool checked)
{
	// Get current row
	int el = ui.ElementList->currentRow();
	if (el == -1) return;
	// Get element's current ambient colour and convert into a QColor
	double *col = elements().colour(el);
	QColor oldcol, newcol;
	oldcol.setRgbF( col[0], col[1], col[2], col[3] );
	// Request a colour dialog
	bool ok = FALSE;
	newcol.setRgba(QColorDialog::getRgba(oldcol.rgba(), &ok, this));
	if (!ok) return;
	// Store new colour
	elements().setColour(el, newcol.redF(), newcol.greenF(), newcol.blueF());
	ui.ElementColourFrame->setColour(newcol);
	ui.ElementColourFrame->update();
	// Re-set atom colours in model(s)
	aten.currentModel()->changeLog.add(Log::Style);
	gui.mainWidget()->postRedisplay();
}

void AtenPrefs::on_ElementRadiusSpin_valueChanged(double value)
{
	// Get current row
	int el = ui.ElementList->currentRow();
	if (el == -1) return;
	elements().setAtomicRadius(el, value);
	// Re-draw models
	aten.currentModel()->changeLog.add(Log::Style);
	gui.mainWidget()->postRedisplay();
}

/*
// View Page
*/

void AtenPrefs::updateAfterViewPrefs(bool force)
{
	if (refreshing_) return;
	gui.mainWidget()->updatePrimitives();
	gui.mainWidget()->postRedisplay();
}

/*
// View Page - Style Tab
*/

void AtenPrefs::setRadiusChanged(Atom::DrawStyle ds, double value, bool foratom)
{
	if (refreshing_) return;
	if (foratom) prefs.setAtomStyleRadius(ds, value);
	else prefs.setBondStyleRadius(ds, value);
	updateAfterViewPrefs(TRUE);
}

void AtenPrefs::on_StickRadiusSpin_valueChanged(double value)
{
	setRadiusChanged(Atom::StickStyle, value, TRUE);
}

void AtenPrefs::on_TubeRadiusSpin_valueChanged(double value)
{
	setRadiusChanged(Atom::TubeStyle, value, TRUE);
}

void AtenPrefs::on_SphereRadiusSpin_valueChanged(double value)
{
	setRadiusChanged(Atom::SphereStyle, value, TRUE);
}

void AtenPrefs::on_ScaledRadiusSpin_valueChanged(double value)
{
	setRadiusChanged(Atom::ScaledStyle, value, TRUE);
}

void AtenPrefs::on_StickBondRadiusSpin_valueChanged(double value)
{
	setRadiusChanged(Atom::StickStyle, value, FALSE);
}

void AtenPrefs::on_TubeBondRadiusSpin_valueChanged(double value)
{
	setRadiusChanged(Atom::TubeStyle, value, FALSE);
}

void AtenPrefs::on_SphereBondRadiusSpin_valueChanged(double value)
{
	setRadiusChanged(Atom::SphereStyle, value, FALSE);
}

void AtenPrefs::on_ScaledBondRadiusSpin_valueChanged(double value)
{
	setRadiusChanged(Atom::ScaledStyle, value, FALSE);
}

void AtenPrefs::on_SelectionScaleSpin_valueChanged(double value)
{
	prefs.setSelectionScale(value);
	updateAfterViewPrefs(TRUE);
}

void AtenPrefs::on_AngleLabelFormatEdit_textEdited(const QString &text)
{
	prefs.setAngleLabelFormat( qPrintable(text) );
	gui.mainWidget()->postRedisplay();
}

void AtenPrefs::on_DistanceLabelFormatEdit_textEdited(const QString &text)
{
	prefs.setDistanceLabelFormat( qPrintable(text) );
	gui.mainWidget()->postRedisplay();
}

void AtenPrefs::on_LabelSizeSpin_valueChanged(int value)
{
	prefs.setLabelSize(value);
	gui.mainWidget()->postRedisplay();
}

void AtenPrefs::on_RenderDashedAromaticsCheck_clicked(bool checked)
{
	prefs.setRenderDashedAromatics(checked);
	aten.globalLogChange(Log::Style);
	gui.mainWidget()->postRedisplay();
}

void AtenPrefs::on_DrawHydrogenBondsCheck_clicked(bool checked)
{
	prefs.setDrawHydrogenBonds(checked);
	aten.globalLogChange(Log::Style);
	gui.mainWidget()->postRedisplay();
}

void AtenPrefs::on_HydrogenBondDotRadiusSpin_valueChanged(double value)
{
	prefs.setHydrogenBondDotRadius(value);
	if (prefs.drawHydrogenBonds())
	{
		aten.globalLogChange(Log::Style);
		gui.mainWidget()->postRedisplay();
	}
}

/*
// View Page - Colours Tab
*/

void AtenPrefs::on_ColoursTable_cellDoubleClicked(int row, int column)
{
	// Get clicked item in table
	if (column != 1) return;
	if (row == -1) return;
	Prefs::ObjectColour pencol = (Prefs::ObjectColour) row;
	double *col = prefs.colour(pencol);
	QColor oldcol, newcol;
	oldcol.setRgbF( col[0], col[1], col[2], col[3] );
	// Request a colour dialog
	bool ok = FALSE;
	newcol.setRgba(QColorDialog::getRgba(oldcol.rgba(), &ok, this));
	if (!ok) return;
	// Store new colour
	prefs.setColour(pencol, newcol.redF(), newcol.greenF(), newcol.blueF(), newcol.alphaF());
	ui.ColoursTable->item(row, 1)->setBackgroundColor(newcol);
	aten.currentModel()->changeLog.add(Log::Style);
	// Update display
	gui.mainWidget()->postRedisplay();
}

/*
// View Page - Rendering / Quality Tab
*/

void AtenPrefs::on_PrimitiveQualitySlider_valueChanged(int value)
{
	prefs.setPrimitiveQuality(value);
	updateAfterViewPrefs(TRUE);
}

void AtenPrefs::on_PrimitiveQualitySpin_valueChanged(int value)
{
	prefs.setPrimitiveQuality(value);
	updateAfterViewPrefs(TRUE);
}

void AtenPrefs::on_ImagePrimitivesGroup_clicked(bool checked)
{
	prefs.setReusePrimitiveQuality(!checked);
}

void AtenPrefs::on_ImagePrimitiveQualitySlider_valueChanged(int value)
{
	prefs.setImagePrimitiveQuality(value);
}

void AtenPrefs::on_ImagePrimitiveQualitySpin_valueChanged(int value)
{
	prefs.setImagePrimitiveQuality(value);
}

void AtenPrefs::on_LevelOfDetailNLevelsSpin_valueChanged(int value)
{
	prefs.setLevelsOfDetail(value);
	updateAfterViewPrefs(TRUE);
}

void AtenPrefs::on_LevelOfDetailStartZSpin_valueChanged(double value)
{
	prefs.setLevelOfDetailStartZ(value);
	updateAfterViewPrefs(TRUE);
}

void AtenPrefs::on_LevelOfDetailWidthSpin_valueChanged(double value)
{
	prefs.setLevelOfDetailWidth(value);
	updateAfterViewPrefs(TRUE);
}

void AtenPrefs::on_TransparencyGroup_clicked(bool checked)
{
	prefs.setTransparencyCorrect(checked);
	gui.mainWidget()->postRedisplay();
}

void AtenPrefs::on_TransparencyNSlicesSpin_valueChanged(int value)
{
	prefs.setTransparencyNBins(value);
	if (refreshing_) return;
	gui.mainWidget()->reinitialiseTransparency();
	gui.mainWidget()->postRedisplay();
}

void AtenPrefs::on_TransparencyStartZSpin_valueChanged(double value)
{
	prefs.setTransparencyBinStartZ(value);
	if (refreshing_) return;
	gui.mainWidget()->reinitialiseTransparency();
	gui.mainWidget()->postRedisplay();
}

void AtenPrefs::on_TransparencyBinWidthSpin_valueChanged(double value)
{
	prefs.setTransparencyBinWidth(value);
	if (refreshing_) return;
	gui.mainWidget()->reinitialiseTransparency();
	gui.mainWidget()->postRedisplay();
}

void AtenPrefs::on_FarClipSpin_valueChanged(double value)
{
	prefs.setClipFar(value);
	gui.mainWidget()->postRedisplay();
}

void AtenPrefs::on_FarDepthSpin_valueChanged(int value)
{
	prefs.setDepthFar(value);
	gui.mainWidget()->postRedisplay();
}

void AtenPrefs::on_NearClipSpin_valueChanged(double value)
{
	prefs.setClipNear(value);
	gui.mainWidget()->postRedisplay();
}

void AtenPrefs::on_NearDepthSpin_valueChanged(int value)
{
	prefs.setDepthNear(value);
	updateAfterViewPrefs(FALSE);
}

void AtenPrefs::on_LineAliasingCheck_stateChanged(int state)
{
	prefs.setLineAliasing(state == Qt::Checked);
	updateAfterViewPrefs(FALSE);
}

void AtenPrefs::on_PolygonAliasingCheck_stateChanged(int state)
{
	prefs.setPolygonAliasing(state == Qt::Checked);
	gui.mainWidget()->postRedisplay(TRUE);
}

void AtenPrefs::on_MultiSamplingCheck_stateChanged(int state)
{
	prefs.setMultiSampling(state == Qt::Checked);
	gui.mainWidget()->postRedisplay(TRUE);
}

void AtenPrefs::on_SpotlightGroup_clicked(bool checked)
{
	prefs.setSpotlightActive(checked);
	gui.mainWidget()->postRedisplay(TRUE);
}

void AtenPrefs::spotlightPosChanged(int i, double value)
{
	prefs.setSpotlightPosition(i, (GLfloat) value);
	gui.mainWidget()->postRedisplay(TRUE,TRUE);
}

void AtenPrefs::on_SpotlightPositionXSpin_valueChanged(double value)
{
	spotlightPosChanged(0, value);
}

void AtenPrefs::on_SpotlightPositionYSpin_valueChanged(double value)
{
	spotlightPosChanged(1, value);
}

void AtenPrefs::on_SpotlightPositionZSpin_valueChanged(double value)
{
	spotlightPosChanged(2, value);
}

void AtenPrefs::spotlightColourChanged(Prefs::ColourComponent sc)
{
	// Get current component colour and convert it to a QColor
	double *col = prefs.spotlightColour(sc);
	QColor oldcol, newcol;
	oldcol.setRgbF( col[0], col[1], col[2], col[3] );
	// Request a colour dialog
	bool ok = FALSE;
	newcol.setRgba(QColorDialog::getRgba(oldcol.rgba(), &ok, this));
	if (!ok) return;
	// Store new colour
	prefs.setSpotlightColour(sc, newcol.redF(), newcol.greenF(), newcol.blueF());
	TColourFrame *colframe = NULL;
	if (sc == Prefs::AmbientComponent) colframe = ui.SpotlightAmbientColourFrame;
	else if (sc == Prefs::DiffuseComponent) colframe = ui.SpotlightDiffuseColourFrame;
	else if (sc == Prefs::SpecularComponent) colframe = ui.SpotlightSpecularColourFrame;	
	colframe->setColour(newcol);
	colframe->update();
	// Update display
	gui.mainWidget()->postRedisplay(TRUE);
}

void AtenPrefs::on_SpotlightAmbientColourButton_clicked(bool checked)
{
	spotlightColourChanged(Prefs::AmbientComponent);
}

void AtenPrefs::on_SpotlightDiffuseColourButton_clicked(bool checked)
{
	spotlightColourChanged(Prefs::DiffuseComponent);
}

void AtenPrefs::on_SpotlightSpecularColourButton_clicked(bool checked)
{
	spotlightColourChanged(Prefs::SpecularComponent);
}

void AtenPrefs::on_ShininessSpin_valueChanged(int value)
{
	prefs.setShininess(value);
	aten.currentModel()->changeLog.add(Log::Camera);
	gui.mainWidget()->postRedisplay();
}

void AtenPrefs::on_FrameCurrentModelCheck_clicked(bool checked)
{
	prefs.setFrameCurrentModel(checked);
	gui.mainWidget()->postRedisplay();
}

void AtenPrefs::on_FrameWholeViewCheck_clicked(bool checked)
{
	prefs.setFrameWholeView(checked);
	gui.mainWidget()->postRedisplay();
}

/*
// Interaction Page
*/

void AtenPrefs::on_LeftMouseCombo_currentIndexChanged(int ma)
{
	prefs.setMouseAction(Prefs::LeftButton, (Prefs::MouseAction) ma);
}

void AtenPrefs::on_MiddleMouseCombo_currentIndexChanged(int ma)
{
	prefs.setMouseAction(Prefs::MiddleButton, (Prefs::MouseAction) ma);
}

void AtenPrefs::on_RightMouseCombo_currentIndexChanged(int ma)
{
	prefs.setMouseAction(Prefs::RightButton, (Prefs::MouseAction) ma);
}

void AtenPrefs::on_WheelMouseCombo_currentIndexChanged(int ma)
{
	prefs.setMouseAction(Prefs::WheelButton, (Prefs::MouseAction) ma);
}

void AtenPrefs::on_ShiftButtonCombo_currentIndexChanged(int ka)
{
	prefs.setKeyAction(Prefs::ShiftKey, (Prefs::KeyAction) ka);
}

void AtenPrefs::on_CtrlButtonCombo_currentIndexChanged(int ka)
{
	prefs.setKeyAction(Prefs::CtrlKey, (Prefs::KeyAction) ka);
}

void AtenPrefs::on_AltButtonCombo_currentIndexChanged(int ka)
{
	prefs.setKeyAction(Prefs::AltKey, (Prefs::KeyAction) ka);
}

void AtenPrefs::on_ZoomThrottleSpin_valueChanged(double value)
{
	prefs.setZoomThrottle(value);
}

void AtenPrefs::on_MouseMoveFilterSpin_valueChanged(int value)
{
	prefs.setMouseMoveFilter(value);
}

/*
// Colours Page
*/

void AtenPrefs::updateScalePointsList()
{
	// Clear current list items
	ui.ScalePointsTable->clear();
	// Get the id of the currently selected point and scale
	int scale = ui.ScaleList->currentRow();
	if (scale == -1) return;
	// Cycle over scale points and add the items
	GLfloat colour[4];
	QColor qcol;
	ui.ScalePointsTable->setRowCount(prefs.colourScale[scale].nPoints());
	QTableWidgetItem *item;
	int count = 0;
	for (ColourScalePoint *csp = prefs.colourScale[scale].firstPoint(); csp != NULL; csp = csp->next)
	{

		item = new QTableWidgetItem(ftoa(csp->value()));
		ui.ScalePointsTable->setItem(count, 0, item);
		item = new QTableWidgetItem();
		csp->copyColour(colour);
		qcol.setRgbF( colour[0], colour[1], colour[2], colour[3] );
		item->setBackgroundColor(qcol);
		ui.ScalePointsTable->setItem(count, 1, item);
		++count;
	}
	// Select first item in list
	ui.ScalePointsTable->setCurrentItem(0);
}

void AtenPrefs::on_ScaleList_currentRowChanged(int id)
{
	if (id == -1) return;
	// Scale selection has changed, so update points list
	updateScalePointsList();
}

void AtenPrefs::on_ScalePointsTable_currentCellChanged(int row, int col, int prevrow, int prevcol)
{
	// Get the id of the currently selected point and scale
	int scale = ui.ScaleList->currentRow();
	if (scale == -1) return;
	if (row == -1) return;
	// Set colour frame and value spin
	ColourScalePoint *csp = prefs.colourScale[scale].point(row);
	ui.PointColourFrame->setColour(csp->colour());
	ui.PointColourFrame->update();
	ui.PointValueSpin->setValue(csp->value());
}

void AtenPrefs::on_PointValueSpin_valueChanged(double d)
{
	// Get the id of the currently selected point and scale
	int scale = ui.ScaleList->currentRow();
	if (scale == -1) return;
	int id = ui.ScalePointsTable->currentRow();
	if (id == -1) return;
	// Set value in colourscale
	prefs.colourScale[scale].setPointValue(id, d);
	ui.ScalePointsTable->item(id, 0)->setText(ftoa(d));
	// Update display
	aten.currentModel()->changeLog.add(Log::Style);
	gui.mainWidget()->postRedisplay();
}

void AtenPrefs::on_PointColourButton_clicked(bool checked)
{
	// Get the id of the currently selected point and scale
	int scale = ui.ScaleList->currentRow();
	if (scale == -1) return;
	int id = ui.ScalePointsTable->currentRow();
	if (id == -1) return;
	// Get new colour
	ColourScalePoint *csp = prefs.colourScale[scale].point(id);
	double *col = csp->colour();
	QColor oldcol, newcol;
	oldcol.setRgbF( col[0], col[1], col[2], col[3] );
	// Request a colour dialog
	bool ok = FALSE;
	newcol.setRgba(QColorDialog::getRgba(oldcol.rgba(), &ok, this));
	if (!ok) return;
	// Store new colour, and set colours in frame and pointlist
	prefs.colourScale[scale].setPointColour(id, newcol.redF(), newcol.greenF(), newcol.blueF(), newcol.alphaF());
	ui.PointColourFrame->setColour(newcol);
	ui.PointColourFrame->update();
	ui.ScalePointsTable->item(id, 1)->setBackgroundColor(newcol);
	// Update display
	aten.currentModel()->changeLog.add(Log::Style);
	gui.mainWidget()->postRedisplay();
}

void AtenPrefs::on_AddPointButton_clicked(bool checked)
{
	// Get the id of the currently selected scale
	int scale = ui.ScaleList->currentRow();
	if (scale == -1) return;
	// Add a new point to the end of the scale and refresh the list
	double value = (prefs.colourScale[scale].nPoints() == 0 ? 0.0 : prefs.colourScale[scale].lastPoint()->value() + 1.0);
	prefs.colourScale[scale].addPointAtEnd(value, 0.5f, 0.5f, 0.5f);
	updateScalePointsList();
}

void AtenPrefs::on_RemovePointButton_clicked(bool checked)
{
	// Get the id of the currently selected scale and point
	int scale = ui.ScaleList->currentRow();
	if (scale == -1) return;
	int id = ui.ScalePointsTable->currentRow();
	if (id == -1) return;
	// Remove selected point
	prefs.colourScale[scale].removePoint(id);
	updateScalePointsList();
}

void AtenPrefs::on_ScaleList_itemClicked(QListWidgetItem *item)
{
	// Get row number associated with item
	int row = ui.ScaleList->row(item);
	if (row == -1) return;
	// Look at checked state
	prefs.colourScale[row].setVisible( (item->checkState() == Qt::Checked ? TRUE : FALSE) );
	gui.mainWidget()->postRedisplay();
}

void AtenPrefs::on_ScaleList_itemDoubleClicked(QListWidgetItem *item)
{
	// Get row number associated with item
	int row = ui.ScaleList->row(item);
	if (row == -1) return;
	bool ok;
	QString text = QInputDialog::getText(this, tr("Rename Colourscale: ") + (row+1), tr("New name:"), QLineEdit::Normal, prefs.colourScale[row].name(), &ok);
	if (ok && !text.isEmpty())
	{
		prefs.colourScale[row].setName( qPrintable(text) );
		gui.mainWidget()->postRedisplay();
	}
}

/*
// Program Page
*/

void AtenPrefs::on_CommonElementsEdit_textEdited(const QString &text)
{
	prefs.setCommonElements( qPrintable(text) );
	gui.selectElementDialog->addCommonButtons(prefs.commonElements());
}

void AtenPrefs::on_DensityUnitCombo_currentIndexChanged(int index)
{
	prefs.setDensityUnit( (Prefs::DensityUnit) index );
}

void AtenPrefs::on_EnergyUnitCombo_currentIndexChanged(int index)
{
	prefs.setEnergyUnit( (Prefs::EnergyUnit) index );
}

void AtenPrefs::on_EnergyUpdateSpin_valueChanged(int value)
{
	prefs.setEnergyUpdate(value);
}

void AtenPrefs::on_HAddDistanceSpin_valueChanged(double value)
{
	prefs.setHydrogenDistance(value);
}

void AtenPrefs::on_MaxCuboidsSpin_valueChanged(int value)
{
	prefs.setMaxCuboids(value);
}

void AtenPrefs::on_MaxRingsSpin_valueChanged(int value)
{
	prefs.setMaxRings(value);
}

void AtenPrefs::on_MaxRingSizeSpin_valueChanged(int value)
{
	prefs.setMaxRingSize(value);
}

void AtenPrefs::on_MaxUndoLevelsSpin_valueChanged(int value)
{
	prefs.setMaxUndoLevels(value);
}

void AtenPrefs::on_ModelUpdateSpin_valueChanged(int value)
{
	prefs.setModelUpdate(value);
}

/*
// Energy / FF Page
*/

void AtenPrefs::updateParameterTable()
{
	msg.enter("AtenPrefs::updateParameterTable");
	int row = ui.FunctionalFormList->currentRow();
	if (row == -1)
	{
		ui.ParameterTable->setRowCount(0);
		msg.exit("AtenPrefs::updateParameterTable");
		return;
	}
	int n;
	QStringList combrules;
	TComboBox *combo;
	QTableWidgetItem *item;
	for (n=0; n<Combine::nCombinationRules; ++n) combrules << Combine::combinationRuleName( (Combine::CombinationRule) n);
	ui.ParameterTable->setColumnCount(2);
	ui.ParameterTable->setRowCount(VdwFunctions::VdwFunctions[row].nParameters);
	for (n=0; n<VdwFunctions::VdwFunctions[row].nParameters; ++n)
	{
		item = new QTableWidgetItem(VdwFunctions::VdwFunctions[row].parameters[n]);
		ui.ParameterTable->setItem(n, 0, item);
		combo = new TComboBox(this);
		combo->setMinimumSize(78,24);
		combo->addItems(combrules);
		combo->setInteger(n);
		combo->setCurrentIndex(VdwFunctions::VdwFunctions[row].combinationRules[n]);
		ui.ParameterTable->setCellWidget(n, 1, combo);
		QObject::connect(combo, SIGNAL(activated(int)), this, SLOT(ParameterRuleChanged(int)));
	}
	msg.exit("AtenPrefs::updateParameterTable");
}

void AtenPrefs::on_CalculateIntraCheck_stateChanged(int state)
{
	prefs.setCalculateIntra(state);
}

void AtenPrefs::on_CalculateVdwCheck_stateChanged(int state)
{
	prefs.setCalculateVdw(state);
}

void AtenPrefs::on_ElectrostaticMethodCombo_currentIndexChanged(int index)
{
	prefs.setElectrostaticsMethod( (Electrostatics::ElecMethod) index);
}

void AtenPrefs::on_VdwCutoffSpin_valueChanged(double d)
{
	prefs.setVdwCutoff(d);
}

void AtenPrefs::on_ElecCutoffSpin_valueChanged(double d)
{
	prefs.setElecCutoff(d);
}

void AtenPrefs::on_EwaldPrecisionMantissaSpin_valueChanged(double d)
{
	prefs.ewaldPrecision().setMantissa(d);
}

void AtenPrefs::on_EwaldPrecisionExponentSpin_valueChanged(int i)
{
	prefs.ewaldPrecision().setExponent(i);
}

void AtenPrefs::on_EwaldManualAlphaSpin_valueChanged(double d)
{
	prefs.setEwaldAlpha(d);
}

void AtenPrefs::on_EwaldManualKXSpin_valueChanged(int i)
{
	prefs.setEwaldKMax(0,i);
}

void AtenPrefs::on_EwaldManualKYSpin_valueChanged(int i)
{
	prefs.setEwaldKMax(1,i);
}

void AtenPrefs::on_EwaldManualKZSpin_valueChanged(int i)
{
	prefs.setEwaldKMax(2,i);
}

void AtenPrefs::on_FunctionalFormList_currentRowChanged(int row)
{
	updateParameterTable();
}

void AtenPrefs::ParameterRuleChanged(int id)
{
	// Get current functional form highlighted
	msg.enter("AtenPrefs::ParameterRuleChanged");
	int row = ui.FunctionalFormList->currentRow();
	if (row == -1)
	{
		msg.exit("AtenPrefs::ParameterRuleChanged");
		return;
	}
	// Determine ID of sender
	TComboBox *combo = (TComboBox*) sender();
	if (!combo)
	{
		printf("AtenPrefs::ParameterRuleChanged - Sender could not be cast to a TComboBox.\n");
		msg.exit("AtenPrefs::ParameterRuleChanged");
		return;
	}
	VdwFunctions::VdwFunctions[row].combinationRules[combo->integer()] = (Combine::CombinationRule) id;
// 	printf("SET %i %i %i\n", row, combo->integer(), id);
	msg.exit("AtenPrefs::ParameterRuleChanged");
}

void AtenPrefs::on_ParameterTable_itemChanged(QTableWidgetItem *w)
{
	// TGAY Do we need this?
}

/*
// External Programs
*/

void AtenPrefs::on_TemporaryDirButton_clicked(bool checked)
{
	static QString dir = prefs.tempDir();
	dir = QFileDialog::getExistingDirectory(this, "Select temporary directory", dir, QFileDialog::ShowDirsOnly);
	if (!dir.isEmpty())
	{
		prefs.setTempDir( qPrintable(dir) );
		ui.TemporaryDirEdit->setText(dir);
	}
}

void AtenPrefs::on_TemporaryDirEdit_textEdited(const QString &text)
{
	prefs.setTempDir( qPrintable(text) );
}

void AtenPrefs::on_MopacExecutableButton_clicked(bool checked)
{
	// Call a fileselector....
	QString filename = QFileDialog::getOpenFileName(this, "Select MOPAC Executable", prefs.mopacExe());
	if (!filename.isEmpty())
	{
		prefs.setMopacExe( qPrintable(filename) );
		ui.MopacExecutableEdit->setText(filename);
	}
}

void AtenPrefs::on_MopacExecutableEdit_textEdited(const QString &text)
{
	prefs.setMopacExe( qPrintable(text) );
}

void AtenPrefs::on_EncoderExecutableButton_clicked(bool checked)
{
	// Call a fileselector....
	QString filename = QFileDialog::getOpenFileName(this, "Select Video Encoder Executable", prefs.mopacExe());
	if (!filename.isEmpty())
	{
		prefs.setEncoderExe( qPrintable(filename) );
		ui.EncoderExecutableEdit->setText(filename);
	}
}

void AtenPrefs::on_EncoderExecutableEdit_textEdited(const QString &text)
{
	prefs.setEncoderExe( qPrintable(text) );
}

void AtenPrefs::on_EncoderArgumentsEdit_textEdited(const QString &text)
{
	prefs.setEncoderArguments( qPrintable(text) );
}

void AtenPrefs::on_EncoderPostExecutableButton_clicked(bool checked)
{
	// Call a fileselector....
	QString filename = QFileDialog::getOpenFileName(this, "Select Video Post-Processor Executable", prefs.mopacExe());
	if (!filename.isEmpty())
	{
		prefs.setEncoderPostExe( qPrintable(filename) );
		ui.EncoderPostExecutableEdit->setText(filename);
	}
}

void AtenPrefs::on_EncoderPostExecutableEdit_textEdited(const QString &text)
{
	prefs.setEncoderPostExe( qPrintable(text) );
}

void AtenPrefs::on_EncoderPostArgumentsEdit_textEdited(const QString &text)
{
	prefs.setEncoderPostArguments( qPrintable(text) );
}
