/*
	*** Popup Widget - Reset View
	*** src/gui/popupviewreset.h
	Copyright T. Youngs 2007-2018

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

#ifndef ATEN_VIEWRESETPOPUP_H
#define ATEN_VIEWRESETPOPUP_H

#include "gui/ui_popupviewreset.h"
#include "gui/tpopupwidget.hui"
#include "parser/returnvalue.h"

// Forward Declarations (Qt)
class AtenWindow;

ATEN_BEGIN_NAMESPACE

// Forward Declarations (Aten)
class ReturnValue;

ATEN_END_NAMESPACE

ATEN_USING_NAMESPACE

// Popup Widget - ResetView
class ResetViewPopup : public TPopupWidget
{
	// All Qt declarations derived from QObject must include this macro
	Q_OBJECT

	private:
	// Reference to main window
	AtenWindow& parent_;

	public:
	// Constructor / Destructor
	ResetViewPopup(AtenWindow& parent, TMenuButton* buttonParent);
	// Main form declaration
	Ui::ResetViewPopup ui;
	// Update controls (before show()) (virtual)
	void updateControls();
	// Call named method associated to popup
	bool callMethod(QString methodName, ReturnValue& rv);
	

	/*
	 * Reimplementations
	 */
	protected:
	void hideEvent(QHideEvent* event) { TPopupWidget::hideEvent(event); }


	/*
	 * Widget Functions
	 */
	private:
	void setCartesianView(double x, double y, double z);
	void setCellView(double x, double y, double z);

	private slots:
	void on_CartesianNegativeXButton_clicked(bool checked);
	void on_CartesianPositiveXButton_clicked(bool checked);
	void on_CartesianNegativeYButton_clicked(bool checked);
	void on_CartesianPositiveYButton_clicked(bool checked);
	void on_CartesianNegativeZButton_clicked(bool checked);
	void on_CartesianPositiveZButton_clicked(bool checked);
	void on_CellNegativeXButton_clicked(bool checked);
	void on_CellPositiveXButton_clicked(bool checked);
	void on_CellNegativeYButton_clicked(bool checked);
	void on_CellPositiveYButton_clicked(bool checked);
	void on_CellNegativeZButton_clicked(bool checked);
	void on_CellPositiveZButton_clicked(bool checked);
};

#endif
