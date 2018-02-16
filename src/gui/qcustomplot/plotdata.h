/*
	*** Plot Data
	*** src/gui/qcustomplot/plotdata.h
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

#ifndef ATEN_PLOTDATA_H
#define ATEN_PLOTDATA_H

#include "base/namespace.h"
#include "templates/list.h"
#include <QWidget>

// Forward Declarations (Qt)
/* none */

ATEN_USING_NAMESPACE

// Simple container for data displayed in QCustomPlot
class PlotData : public ListItem<PlotData>
{
	public:
	// Constructor
	PlotData(QString title = QString());
	// Copy Constructor
	PlotData(const PlotData& source);
	// Assignment Operator
	PlotData& operator=(const PlotData& source);


	/*
	 * Data
	 */
	private:
	// X data
	QVector<double> x_;
	// Y data
	QVector<double> y_;
	// Title
	QString title_;

	public:
	// Set titlesfor data
	void setTitle(QString title);
	// Return X data
	QVector<double>& x();
	// Return Y data
	QVector<double>& y();
	// Return title of the data
	QString title();
};

#endif

