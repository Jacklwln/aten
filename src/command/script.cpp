/*
	*** Script Commands
	*** src/command/script.cpp
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

#include "command/commands.h"
#include "parser/commandnode.h"
#include "main/aten.h"
#include "gui/gui.h"
#include "gui/command.h"

// List available scripts
bool Command::function_ListScripts(CommandNode *c, Bundle &obj, ReturnValue &rv)
{
	if (aten.nScripts() == 0) msg.print("No scripts loaded.\n");
	else msg.print("Currently loaded scripts:\n");
	for (Forest *f = aten.scripts(); f != NULL; f = f->next) msg.print("  %s (%s)\n", f->filename(), f->name());
	rv.reset();
	return TRUE;
}

// Load script from disk
bool Command::function_LoadScript(CommandNode *c, Bundle &obj, ReturnValue &rv)
{
	Forest *f = aten.addScript();
	if (!f->generateFromFile(c->argc(0), "ScriptFile"))
	{
		aten.removeScript(f);
		return FALSE;
	}
	if (c->hasArg(1)) f->setName(c->argc(1));
	else f->setName(c->argc(0));
	rv.reset();
	// Update GUI
	if (gui.exists()) gui.commandWindow->refreshScripts();
	return TRUE;
}

// Run specified script
bool Command::function_RunScript(CommandNode *c, Bundle &obj, ReturnValue &rv)
{
	// Find the script...
	Forest *f;
	for (f = aten.scripts(); f != NULL; f = f->next) if (strcmp(c->argc(0), f->name()) == 0) break;
	if (f != NULL)
	{
		msg.print("Executing script '%s':\n",c->argc(0));
		ReturnValue result;
		f->executeAll(result);
	}
	else msg.print("Couldn't find script '%s'.\n",c->argc(0));
	rv.reset();
	return TRUE;
}
