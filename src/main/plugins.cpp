/*
	*** Aten Plugins
	*** src/main/plugins.cpp
	Copyright T. Youngs 2016-2018

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
#include "plugins/interfaces/fileplugin.h"
#include "plugins/interfaces/methodplugin.h"
#include <QDir>
#include <QPluginLoader>

// Register supplied plugin
bool Aten::registerPlugin(QObject* plugin, QString filename)
{
	// Determine which type of plugin this is by attempting to cast it to the available types
	// -- FilePluginInterface
	FilePluginInterface* filePlugin = qobject_cast<FilePluginInterface*>(plugin);
	if (filePlugin)
	{
		// If the plugin is disabled, don't register it
		if (!filePlugin->enabled()) return true;

		filePlugin->setPluginFilename(filename);
		filePlugin->setPluginStore(&pluginStore_);
		pluginStore_.registerFilePlugin(filePlugin);
		return true;
	}

	// -- MethodPluginInterface
	MethodPluginInterface* methodPlugin = qobject_cast<MethodPluginInterface*>(plugin);
	if (methodPlugin)
	{
		// If the plugin is disabled, don't register it
		if (!methodPlugin->enabled()) return true;

		methodPlugin->setPluginFilename(filename);
		methodPlugin->setPluginStore(&pluginStore_);
		pluginStore_.registerMethodPlugin(methodPlugin);
		return true;
	}

	// -- ToolPluginInterface
	ToolPluginInterface* toolPlugin = qobject_cast<ToolPluginInterface*>(plugin);
	if (toolPlugin)
	{
		// If the plugin is disabled, don't register it
		if (!toolPlugin->enabled()) return true;

		toolPlugin->setPluginFilename(filename);
		toolPlugin->setPluginStore(&pluginStore_);
		pluginStore_.registerToolPlugin(toolPlugin);
		return true;
	}

	return false;
}

// Load specified plugin and register its functions
bool Aten::loadPlugin(QString filename)
{
	Messenger::print(Messenger::Verbose, "Querying plugin file '%s'...\n", qPrintable(filename));

	// Create a pluginloader for the filename provided
	QPluginLoader loader(filename);

	QObject* plugin = loader.instance();
	if (!plugin)
	{
		Messenger::error("File '%s' does not appear to be a valid plugin.", qPrintable(filename));
		Messenger::print(loader.errorString());
		return false;
	}

	return registerPlugin(plugin, filename);
}

// Load plugins
void Aten::loadPlugins()
{
	Messenger::enter("Aten::loadPlugins");

	nPluginsFailed_ = 0;
	failedPlugins_.clear();

	// Load main plugins
	Messenger::print(Messenger::Verbose, "Looking for plugins in '%s'...", qPrintable(pluginDir_.path()));
	int nFailed = searchPluginsDir(pluginDir_);
	if (nFailed > 0) nPluginsFailed_ += nFailed;

	// Try to load user plugins - we don't mind if the directory doesn't exist...
	QDir userPluginsDir = atenDirectoryFile("plugins");
	Messenger::print(Messenger::Verbose, "Looking for user plugins in '%s'...", qPrintable(userPluginsDir.path()));
	nFailed = searchPluginsDir(userPluginsDir);
	if (nFailed > 0) nPluginsFailed_ += nFailed;

	Messenger::exit("Aten::loadPlugins");
}

// Search directory for plugins
int Aten::searchPluginsDir(QDir path)
{
	Messenger::enter("Aten::searchPluginsDir");

	int i, nFailed = 0;
	QString s = "Plugins --> [" + path.absolutePath() + "] ";
	
	// First check - does this directory actually exist
	if (!path.exists())
	{
		Messenger::exit("Aten::searchPluginsDir");
		return -1;
	}

	// Plugins the directory contents - show only files and exclude '.' and '..', and also the potential README
	QStringList pluginsList = path.entryList(QDir::Files | QDir::NoDotAndDotDot, QDir::Name);
	pluginsList.removeOne("README");
	for (i=0; i< pluginsList.size(); ++i)
	{
		QFileInfo fileInfo(pluginsList.at(i));
		if ((fileInfo.suffix() != "so") && (fileInfo.suffix() != "dll")) continue;

		if (loadPlugin(path.absoluteFilePath(pluginsList.at(i)))) s += pluginsList.at(i) + "  ";
		else
		{
			Messenger::error("Failed to load/register plugin from file '" + pluginsList.at(i) + ";");
			++nFailed;
		}
	}
	Messenger::print(s);

	Messenger::exit("Aten::searchPluginsDir");

	return nFailed;
}

// Return plugin store reference
const PluginStore& Aten::pluginStore()
{
	return pluginStore_;
}
