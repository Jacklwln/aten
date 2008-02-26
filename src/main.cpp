/*
	*** Aten Main
	*** src/main.cpp
	Copyright T. Youngs 2007,2008

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

#include <time.h>
#include <ctime>
#include <string>
#include <iostream>
#include "parse/parser.h"
#include "model/model.h"
#include "classes/fourier.h"
#include "base/elements.h"
#include "base/prefs.h"
#include "base/master.h"
#include "base/debug.h"
#include "gui/gui.h"

int main(int argc, char *argv[])
{
	// Print GPL license information
	printf("Aten version %s, Copyright (C) 2007,2008  T. Youngs\n", PACKAGE_VERSION);
	printf("Aten comes with ABSOLUTELY NO WARRANTY.\n");
	printf("This is free software, and you are welcome to redistribute it under certain conditions.\n");
	printf("For more details read the GPL at <http://www.gnu.org/copyleft/gpl.html>.\n\n");

	// Prepare command line parser and act on debug options
	master.prepare_cli();

	// Run any early commands that the GUI requires (e.g. g_type_init for GTK+)
	gui.prepare();
	
	// Prepare memdebug variables (if on)
	prepare_debug();

	char filename[256];

	srand( (unsigned)time( NULL ) );
	//printf("Atom Type is currently %lu bytes.\n",sizeof(atom));

	// Get environment variables
	master.homedir = getenv("HOME");
	master.workdir = getenv("PWD");
	master.datadir = getenv("ATENDATA");
	printf("Home directory is %s, working directory is %s.\n",master.homedir.get(),master.workdir.get());

	// Initialise elements
	elements.initialise();

	// Load in spacegroup definitions
	sprintf(filename,"%s%s",master.datadir.get(),"/spgrp.dat");
	spacegroups.load(filename);

	// Read default filters from data directory (pass directory)
	sprintf(filename,"%s%s",master.datadir.get(),"/filters/");
	if (!master.open_filters(filename,TRUE)) return 1;

	// Read user filters from home directory (pass directory)
	sprintf(filename,"%s%s",master.homedir.get(),"/.aten/filters/");
	master.open_filters(filename,FALSE);

	// Load in user preferences
	sprintf(filename,"%s%s",master.homedir.get(),"/.aten/prefs.dat");
	prefs.load(filename);

	// Parse program arguments - return value is how many models were loaded, or -1 for some kind of failure
	if (master.parse_cli(argc,argv) == -1) return -1;

	// Do various things depending on the program mode that has been set
	// Execute scripts / command lists if they were provided
	if (master.get_program_mode() == PM_COMMAND)
	{
		for (commandlist *cl = master.scripts.first(); cl != NULL; cl = cl->next)
		{
			if (!cl->execute(NULL)) master.set_program_mode(PM_NONE);
			// Need to check program mode after each script since it can be changed
			if (master.get_program_mode() != PM_COMMAND) break;
		}
		// All scripts done - set program mode to PM_GUI if it is still PM_COMMAND
		if (master.get_program_mode() == PM_COMMAND) master.set_program_mode(PM_GUI);
	}
	// Enter interactive mode once any commands/scripts have been executed
	if (master.get_program_mode() == PM_INTERACTIVE)
	{
		std::string cmd;
		printf("Entering interactive mode...\n");
		do
		{
			// Get string from user
			printf(">>> ");
			getline(cin,cmd);
			master.i_script.clear();
			master.i_script.cache_line(cmd.c_str());
			master.i_script.execute();
		} while (master.get_program_mode() == PM_INTERACTIVE);
		//master.set_program_mode(PM_NONE);
	}
	// Enter full GUI 
	if (master.get_program_mode() == PM_GUI)
	{
		// Add empty model if none were specified on the command line
		if (master.get_nmodels() == 0) model *m = master.add_model();
		gui.run(argc,argv);
	}

	// Cleanup
	master.clear();
	fourier.clear();

	// Print out final debug information (if on)
	print_debuginfo();

	// Done.
	return 0;
}

