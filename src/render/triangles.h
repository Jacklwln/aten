/*
	*** Triangle Storage Class
	*** src/render/triangles.h
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

#ifndef ATEN_TRIANGLES_H
#define ATEN_TRIANGLES_H

#include <GL/gl.h>
#include "render/primitive.h"
#include "templates/list.h"

#define TRIANGLECHUNKSIZE 1000

// Triangles
class Triangles : public Primitive
{
	public:
	// Constructor
	Triangles();
	// List pointers
	Triangles *prev, *next;
};

// Triangle List
class TriangleList
{
	public:
	// Constructor
	TriangleList();

	private:
	// List of triangle chunks
	List<Triangles> triangles_;
	// Internal pointer to current Triangles structure
	Triangles *currentTriangles_;

	public:
	// Forget all stored triangles (but leave structures and lists intact
	void forgetAll();
	// Add triangle
	void addTriangle(GLfloat *vertices, GLfloat *normals, GLfloat *colour);
	// Add triangle with single colour per vertex
	void addTriangleSingleColour(GLfloat *vertices, GLfloat *normals, GLfloat *colour);
	// Sent triangles to GL
	void sendToGL();
};

// Triangle Chopper
class TriangleChopper
{
	public:
	// Constructor / Destructor
	TriangleChopper();
	~TriangleChopper();

	private:
	// Starting z-depth of chopper
	double startZ_;
	// Ending z-depth of chopper, beyond which range triangles will not be DRAWN / SORTED ???
	double endZ_;
	// Slice width
	double sliceWidth_;
	// Number of slices
	int nSlices_;
	// Triangle Lists
	TriangleList *triangleLists_;
	// Clear all existing trianglelists
	void clear();
	
	public:
	// Initialise structure
	void initialise(double startz, double endz, double slicewidth);
	// Empty all stored triangles, but retain storage
	void emptyTriangles();
	// Store primitive's triangles
	void storeTriangles(PrimitiveInfo *pinfo);
	// Sent triangles to GL (in correct order)
	void sendToGL();
};

#endif