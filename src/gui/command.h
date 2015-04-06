/*
	*** Command Dock Widget
	*** src/gui/command.h
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

#ifndef ATEN_COMMANDWIDGET_H
#define ATEN_COMMANDWIDGET_H

#include "gui/ui_command.h"
#include "templates/reflist.h"
#include "parser/program.h"
#include "base/namespace.h"

// Forward Declarations (Qt)
class AtenWindow;

ATEN_USING_NAMESPACE

// Script/command window
class CommandWidget : public QDockWidget
{
	// All Qt declarations derived from QObject must include this macro
	Q_OBJECT

	public:
	// Constructor
	CommandWidget(AtenWindow& parent, Qt::WindowFlags flags = 0);
	// Main form declaration
	Ui::CommandWidget ui;
	// Finalise widgets (things that couldn't be done in Qt Designer)
	void finaliseUi();

	private:
	// Reference to main window
	AtenWindow& parent_;


	/*
	 * Window Functions
	 */
	public:
	void showWidget();
	void refresh();


	/*
	 * Prompt Page
	 */
	private slots:
	void on_CommandPrompt_returnPressed();
	protected:
	void closeEvent(QCloseEvent* event);
	
	public:
	// Set list of commands in command tab
	void setCommandList(QStringList cmds);
	// Return list of commands stored in command tab
	QStringList commandList();

	
	/*
	 * Interactive Page
	 */
	private:
	Program interactiveProgram_;
	// Update variable list
	void updateVariableList();
	
	private slots:
	void on_InteractivePrompt_returnPressed();
		
	public:
	// Set list of commands in command tab
	void setInteractiveList(QStringList cmds);
	// Return list of commands stored in command tab
	QStringList interactiveList();
	

	/*
	 * Scripts Page
	 */
	private:
	// List of scripts and their associated Menu item actions
	Reflist<QAction, Program*> scriptActions_;
	
	private slots:
	void on_ReloadAllScriptsButton_clicked(bool checked);
	void on_RunSelectedScriptButton_clicked(bool checked);
	void on_RemoveSelectedScriptButton_clicked(bool checked);
	void on_OpenScriptButton_clicked(bool checked);
	void on_ScriptsList_currentRowChanged(int row);
	void runScript();
	
	public:
	void refreshScripts(bool refreshactions = true, bool refreshlist = true);

	
	/*
	 * Command Index Page
	 */
	private:
	void repopulateCommandList(const char* search);
	
	private slots:
	void on_ClearSearchButton_clicked(bool checked);
	void on_CommandSearchEdit_textChanged(QString test);
	void on_CommandList_currentTextChanged(const QString &text);
};

#endif
