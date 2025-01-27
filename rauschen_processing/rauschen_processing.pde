// child window for displaying graphs
int gWidth = 775;
int gHeight = 200;
Graphs graphs;

// main window
int width = 1000;
int height = 1000;

// resolution steps
int maxStep = width;
int xStep = 1;
int yStep = 1;
int xOffset = 0;
int xOffsetRecord = 0;
int yOffset = 0;
int yOffsetRecord = 0;

// pixel colors
color c, nc;
int r, g, b;

//noises
ArrayList<Noise> noises;
Noise xStepNoise;
Noise yStepNoise;
Noise toggleSameStepDims;

// timed events
int minSwitchTime = 1;
int maxSwitchTime = 1;
int nextResEvent = 1;		// init in X seconds
int resEventCounter = 0;

public void settings() {
	size(width, height);
	pixelDensity(1);
}

public void setup() {
	// set this window title
	windowTitle("Rauschen");

	// determine this window location on screen
	surface.setLocation(5, 50);

	// can't go in settings for some reason
	frameRate(60);

	// init ArrayList of noises
	noises = new ArrayList<Noise>();

	// init NoiseInstances with starting value and increment, add to list of noises
	xStepNoise = new Noise(random(100), .1);
	noises.add(xStepNoise);
	yStepNoise = new Noise(random(100), .1);
	noises.add(yStepNoise);
	toggleSameStepDims = new Noise(random(100), 1);
	noises.add(toggleSameStepDims);		// TODO: do I want Booleans to show their actual number on the graph or do I want it as 1 and 0?

	// create a new window for child applet
	graphs = new Graphs();
	
	// get pixel array for manipulation
	loadPixels();
}

public void draw() {
	// refresh background
	background(0);

	// handle any timed events here because it may affect the pixel array manipulation
	timedEvents();

	// manipulate pixel array
	manipulatePixelArray();

	// write to pixels array
	updatePixels();
}

// apply from setNewGrid() to the pixel array 
void manipulatePixelArray() {
	// iterate through pixel array with step and apply offset
	for (int x = 0; x < width; x += xStep - xOffset) {
		// offset only applies to first iteration
		if (x > 0) xOffset = 0;
		else xOffset = xOffsetRecord;
		for (int y = 0; y < height; y += yStep - yOffset) {
			// offset only applies to first iteration
			if (y > 0) yOffset = 0;
			else yOffset = yOffsetRecord;
			// get color values at random
			c = color((int)random(255), (int)random(255), (int)random(255));
			// determine indices for pixels array from coordinates and step
			for (int dx = 0; dx < xStep; dx++) {
				for (int dy = 0; dy < yStep; dy++) {
					// get offset
					int px = x + dx;
					int py = y + dy;
					// check boundaries (edges won't have neighboring pixels)
					if (px < width && py < height) {
						// get index
						int index = py * width + px;
						// apply respective color to pixels array
						pixels[index] = c;
					}
				}
			}
		}
	}
}

// set canvas and sketch to a new resolution
void setNewGrid() {

	// get new step close to old step with noise, bias towards lower numbers
	xStep = (int)xStepNoise.getVariableNoiseRange(- maxStep/4, 0, maxStep/2, maxStep, .3);
	yStep = (int)yStepNoise.getVariableNoiseRange(- maxStep/4, 0, maxStep/2, maxStep, .3);

	// cutoff over one and apply
	if (xStep < 1) xStep = 1;
	if (yStep < 1) yStep = 1;

	println(xStep + " " + yStep);

	// determine if step should be the same in both dimensions
	if (toggleSameStepDims.noiseBool(-2, 3)) {
		// apply same step to both dimensions
		yStep = xStep;
	}

	// determine offset for first iteration so that the "cells" are cutoff not only on the right and bottom edge, that is of random size of the cuttoff cell
	xOffset = (int)random(xStep % width);
	xOffsetRecord = xOffset;
	yOffset = (int)random(yStep % height);
	yOffsetRecord = yOffset;
}

// UNUSED: refresh the pixel array with all black pixels, because background() doesn't do that
void refreshPixelArray() {
	for (int p = 0; p < pixels.length; p++) {
		pixels[p] = 0;
	}
}

// sometimes things should happen at random intervals instead
void timedEvents() {
	// sometimes switch to a new resolution step
	resEventCounter++;
	if (resEventCounter > (nextResEvent * 60)) {
		setNewGrid();
		nextResEvent = (int)random(minSwitchTime, maxSwitchTime);
		resEventCounter = 0;
	}
}

// take range and cut at cutoff; useful when a value needs to stick towards the cutoff but should still change sometimes
float cutoff(float range, float cutoff) {
	if (range > cutoff) return range;
	else return cutoff;
}