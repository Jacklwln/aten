/*
	*** Rendering Canvas
	*** src/render/canvas.h
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

#ifndef ATEN_CANVAS_H
#define ATEN_CANVAS_H

#include "templates/vector3.h"
#include "templates/reflist.h"
#include "classes/prefs.h"
#include "base/log.h"

// Forward declarations
class Atom;
class Bond;
class Model;
class Geometry;
class Subselection;
class Cell;
class TCanvas;

// Text object
class TextObject
{
	public:
	// Constructor
	TextObject(int,int,bool,const char*);

	// Screen coordinates for text
	int x, y;
	// Whether to right-align text at the provided coordinate
	bool rightAlign;
	// Text to render
	Dnchar text;
	// List pointers
	TextObject *prev, *next;
};

// User action texts
class UserActionText
{
	public:
	// Action texts
	const char *name;
	const char *unModified;
	const char *shiftModified;
	const char *ctrlModified;
	const char *altModified;
};

extern UserActionText UserActionTexts[];

/*
// Canvas Master Class
// Provides GL rendering functions for a context
*/
class Canvas
{
	public:
	// Constructor
	Canvas();


	// Actions
	enum UserAction { NoAction, SelectAction, SelectMoleculeAction, SelectElementAction, SelectRadialAction, MeasureDistanceAction, MeasureAngleAction, MeasureTorsionAction, DrawAtomAction, DrawChainAction, DrawFragmentAction, DrawTransmuteAction, DrawDeleteAction, DrawProbeAction, DrawBondSingleAction, DrawBondDoubleAction, DrawBondTripleAction, DrawDeleteBondAction, DrawAddHydrogenAction, RotateXYAction, RotateZAction, TranslateAction, ZoomAction, TransformRotateXYAction, TransformRotateZAction, TransformTranslateAction, ManualPickAction, nUserActions };
	
	// Keyboard Key Codes (translated from GTK/Qt keysyms)
	enum KeyCode { OtherKey, EscapeKey, LeftShiftKey, RightShiftKey, LeftControlKey, RightControlKey, LeftAltKey, RightAltKey, LeftKey, RightKey, UpKey, DownKey, nKeyCodes };

	// GL Objects
	enum GlObject { StickAtomGlob, TubeAtomGlob, SphereAtomGlob, UnitAtomGlob, WireTubeAtomGlob, WireSphereAtomGlob, WireUnitAtomGlob, CylinderGlob, SelectedCylinderGlob, WireCylinderGlob, SelectedWireCylindedGlob, GlobeGlob, GuideGlob, CircleGlob, CellAxesGlob, SelectedTubeAtomGlob, SelectedSphereAtomGlob, SelectedUnitAtomGlob, WireUnitCubeGlob, UnitCubeGlob, CrossedUnitCubeGlob, TubeArrowGlob, ModelGlob, nGlobs };


	/*
	// Base rendering context
	*/
	private:
	// Internal name of the canvas for error reporting
	const char *name_;
	// Width, height, and aspect ratio of the canvas
	GLsizei width_, height_;
	// Aspect ratio of canvas
	GLdouble aspect_;
	// Point at which the stored atom display list was valid (sum of Change::StructureLog and Change::CoordinateLog points)
	Log renderPoint_;
	// Flag to indicate whether we may draw to the canvas
	bool valid_;
	// Flag indicating if we are currently drawing to this canvas
	bool drawing_;
	// Flag to prevent rendering (used to restrict unnecessary renders before canvas is even visible)
	bool noDraw_;
	// Qt Target widget
	TCanvas *contextWidget_;
	// Flag used by some sub-rendering processes (e.g. surfaces) in order to decide which display list to use
	bool renderOffScreen_;

	public:
	// Set the internal name of the canvas
	void setName(const char *s);
	// Return the current height of the drawing area
	GLsizei height() const;
	// Return the current width of the drawing area
	GLsizei width() const;
	// Return whether the canvas is currently drawing
	bool isDrawing() const;
	// Return if the canvas is valid
	bool isValid() const;
	// Set the validity of the canvas
	void setValid(bool valid);
	// Set up widget for OpenGL drawing
	bool setWidget(TCanvas*);
	// Update Canvas
	void postRedisplay();
	// Called when context has changed size etc.
	void configure(int w, int h);
	// Enable rendering
	void enableDrawing();
	// Disable rendering
	void disableDrawing();
	// Set whether offscreen rendering is being performed
	void setOffScreenRendering(bool b);
	// Return whether offscreen renderinf is being performed
	bool offScreenRendering() const;


	/*
	// Rendering display lists
	*/
	private:
	// Display list ID's for normal and temporary rendering contexts
	GLuint globList_[nGlobs], temporaryGlobList_[nGlobs];
	// Function to return glob integer id
	GLuint glob(Canvas::GlObject ob) const;

	public:
	// Create globs for rendering
	void createLists();


	/*
	// Rendering Primitives
	*/
	private:
	// Draw a diamond
	void diamondPrimitive(double xcenter, double ycentre, double size) const;
	// Draw a square
	void squarePrimitive(double xcentre, double ycentre, double size) const;
	// Draw a rectangle
	void rectanglePrimitive(double l, double t, double r, double b) const;
	// Draw a circle
	void circlePrimitive(double xcentre, double ycenter, double radius) const;
	// Manually draw a unit sphere
	void spherePrimitive(double radius, bool filled, int nslices = -1, int nstacks = -1) const;
	// Manually draw unit cylinder
	void cylinderPrimitive(double startradius, double endradius, bool filled, int nslices = -1, int nstacks = -1) const;


	/*
	// Rendering Objects
	*/
	private:
	// Render text string at specific coordinates
	void glText(double x, double y, const char *text) const;
	// Render text string at atom's screen coordinates
	void glText(const Vec3<double> v, const char *text) const;
	// Draw 3d marks for the atoms in the subselection
	void glSubsel3d() const;
	// Draw a cylinder along vector supplied
	void glCylinder(const Vec3<double> &vec, double length, int style, double radius) const;
	// Draw ellipsoid (construct third vector from the tqo supplied)
	void glEllipsoid(const Vec3<double> &centre, const Vec3<double> &x, const Vec3<double> &y) const;
	// Draw ellipsoid in the supplied axis sytem
	void glEllipsoid(const Vec3<double> &centre, const Vec3<double> &x, const Vec3<double> &y, const Vec3<double> &z) const;
	// Draw the unit cell of the model
	void glCell(Cell *cell) const;
	// Draw a line arrow
	void glArrow(const Vec3<double> &origin, const Vec3<double> &vector, bool swaphead = FALSE) const;
	// Draw a cylinder arrow
	void glCylinderArrow(const Vec3<double> &origin, const Vec3<double> &vector, bool swaphead = FALSE) const;
	// Draw the specified Miller plane (and directional arrow)
	void millerPlane(int h, int k, int l, int dir) const;


	/*
	// General Rendering Calle
	*/
	protected:
	// Last model rendered by canvas (needed for mouse hover etc.)
	Model *displayModel_;
	// Last frame ID rendered by the canvas
	int displayFrameId_;

	public:
	// Configure OpenGL, generating display lists
	void initGl();
	// Set OpenGL options ready for drawing
	void prepGl();
	// Begin construct for any OpenGL commands
	bool beginGl();
	// Finish OpenGL commands
	void endGl();
	// Check for GL error
	void checkGlError();
	// Reset the projection matrix based on the current canvas geometry
	void doProjection();
	// Projection matrices for scene and rotation globe
	Mat4<GLdouble> PMAT, GlobePMAT;
	// Viewport matrix for canvas
	GLint VMAT[4];
	// Return the current display model
	Model *displayModel() const;


	/*
	// Scene Rendering
	*/
	private:
	// List of text nuggets to render
	List<TextObject> textObjects_;
	// Render colourscales
	void renderColourscales() const;
	// Add extra 2D objects
	void renderExtra2d() const;
	// Add extra 3D objects
	void renderExtra3d() const;
	// Render the model specified
	void renderModelAtoms(Model *source) const;
	// Render model cell
	void renderModelCell(Model *source) const;
	// Draw model force arrows		// TODO Defunct now glyphs are available?
	void renderModelForceArrows() const;
	// Render glyphs in the current model
	void renderModelGlyphs(Model *source);
	// Add labels to the model
	void renderModelLabels(Model *source);
	// Add geometry measurements to the model
	void renderModelMeasurements(Model *source);
	// Render text glyphs in the current model
	void renderModelTextGlyphs(Model *source);
	// Draw regions specified for MC insertion
	void renderRegions() const;
	// Render the rotation globe
	void renderRotationGlobe(double *rotmat, double camrot) const;
	// Render model surfaces
	void renderSurfaces(Model *source) const;

	public:
	// Render a scene based on the specified model
	void renderScene(Model*);
	// Render text for the current scene
	void renderText(QPainter&);
	// Save scene as vector image
	//void saveVector(Model *source, vector_format vf, const char *filename);


	/*
	// Selection
	*/
	private:
	// Number of atoms to pick in PickAtomsAction
	int nAtomsToPick_;
	// User action before picking mode was entered
	QAction *actionBeforePick_;
	// List of picked atoms
	Reflist<Atom,int> pickedAtoms_;
	// Pointer to callback function when PickAtomsAction exits
	void (*pickAtomsCallback_)(Reflist<Atom,int>*);
	// Atom that was clicked at the start of a mouse press event
	Atom *atomClicked_;
	// Whether we are selecting atoms and placing them in the subsel list	
	bool pickEnabled_;
	// Reflist of selected atoms and their positions so manipulations may be un-done
	Reflist< Atom,Vec3<double> > oldPositions_;

	public:
	// Returns the clicked atom within a mouse click event
	Atom *atomClicked();
	// Clears the subsel of atoms
	void clearPicked();
	// Manually enter picking mode to select N atoms
	void beginManualPick(int natoms, void (*callback)(Reflist<Atom,int>*));
	// End manual picking
	void endManualPick(bool resetaction);


	/*
	// Mouse
	*/
	protected:
	// Canvas coordinates of mouse down / mouse up events
	Vec3<double> rMouseUp_, rMouseDown_;
	// Canvas coordinates of mouse cursor
	Vec3<double> rMouseLast_;


	/*
	// Interaction
	*/
	protected:
	// Active interaction mode of the main canvas
	UserAction activeMode_;
	// Selected interaction mode (from GUI)
	UserAction selectedMode_;
	// Button flags (uses enum 'MouseButton')
	bool mouseButton_[Prefs::nMouseButtons];
	// Key flags (set by Gui::informMouseDown and used by TCanvas::beginMode)
	bool keyModifier_[Prefs::nModifierKeys];
	// Begin an action on the model (called from MouseButtondown)
	void beginMode(Prefs::MouseButton);
	// Handle mouse motion while performing actions
	void modeMotion(double, double);
	// Handle mousewheel scroll events
	void modeScroll(bool);
	// End an action on the model (called from MouseButtonup)
	void endMode(Prefs::MouseButton);
	// Whether the mouse has moved between begin_mode() and end_mode() calls
	bool hasMoved_;
	// Current drawing depth for certain tools
	double currentDrawDepth_;
	// Whether to accept editing actions (i.e. anything other than view manipulation)
	bool editable_;

	public:
	// Set the active mode to the current user mode
	void useSelectedMode();
	// Sets the currently selected interact mode
	void setSelectedMode(UserAction);
	// Return the currently selected mode
	UserAction selectedMode() const;
	// Inform the canvas of a mouse down event
	void informMouseDown(Prefs::MouseButton, double x, double y, bool shiftkey, bool ctrlkey, bool altkey);
	// Inform the canvas of a mouse up event
	void informMouseUp(Prefs::MouseButton, double, double);
	// Inform the canvas of a mouse move event
	void informMouseMove(double, double);
	// Inform the canvas of a mouse wheel scroll event
	void informScroll(bool);
	// Inform the canvas of a keydown event
	void informKeyDown(KeyCode kc, bool shiftkey, bool ctrlkey, bool altkey);
	// Inform the canvas of a keydown event
	void informKeyUp(KeyCode kc, bool shiftkey, bool ctrlkey, bool altkey);
	// Return modifier status
	bool modifierOn(Prefs::ModifierKey) const;
	// Set whether to accept editing actions (i.e. anything other than view manipulation)
	void setEditable(bool b);
	// Return whether to accept editing actions (i.e. anything other than view manipulation)
	bool editable();
};

#endif
