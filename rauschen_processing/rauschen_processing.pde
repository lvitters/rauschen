// child window for displaying graphs
int gWidth = 1700;
int gHeight = 300;
Graphs graphs;

// main window
int width = 500;
int height = 500;

// resolution steps
int maxStep = width;
int xStep = 1;
int yStep = 1;
int xOffset = 0;
int xOffsetRecord = 0;
int yOffset = 0;
int yOffsetRecord = 0;
int maxIndex = width * height * 4;

// color
color c;

// noises
ArrayList<Noise> noises;
Noise xStepNoise;
Noise yStepNoise;
Noise stepBiasNoise;
Noise toggleSameStepDims;
Noise toggleColorNoise;
Noise hueNoise;
Noise hueNoiseInc;
Noise saturationNoise;
Noise satNoiseInc;
Noise brightnessNoise;
Noise briNoiseInc;

// toggles
Boolean isNoiseColor = true;

// timed events
int minSwitchTime = 1;
int maxSwitchTime = 1;
int nextResEvent = 1;		// init in X seconds
int resEventCounter = 0;
int nextColorEvent = 1;		// init in X seconds
int colorEventCounter = 0;

public void settings() {
	size(width, height);
	pixelDensity(1);
}

public void setup() {
	// set this window title
	windowTitle("Rauschen");

	// determine this window location on screen
	surface.setLocation(10, 60);

	// can't go in settings for some reason
	frameRate(30);
	colorMode(HSB, 360, 100, 100);

	// init ArrayList of noises
	noises = new ArrayList<Noise>();

	// init NoiseInstances with starting value and increment, add to list of noises
	xStepNoise = new Noise(random(100), .1);
	noises.add(xStepNoise);
	yStepNoise = new Noise(random(100), .1);
	noises.add(yStepNoise);
	stepBiasNoise = new Noise(random(100), .1);
	noises.add(stepBiasNoise);
	toggleSameStepDims = new Noise(random(100), 1);
	noises.add(toggleSameStepDims);		// TODO: do I want Booleans to show their actual number on the graph or do I want it as 1 and 0?
	toggleColorNoise = new Noise(random(100), 1);
	noises.add(toggleColorNoise);
	hueNoise = new Noise(random(100), .01);
	noises.add(hueNoise);
	hueNoiseInc = new Noise(random(100), .01);
	noises.add(hueNoiseInc);
	saturationNoise = new Noise(random(100), .01);
	noises.add(saturationNoise);
	satNoiseInc = new Noise(random(100), .01);
	noises.add(satNoiseInc);
	brightnessNoise = new Noise(random(100), .01);
	noises.add(brightnessNoise);
	briNoiseInc = new Noise(random(100), .01);
	noises.add(briNoiseInc);

	// create a new window for child applet
	graphs = new Graphs();
	
	// get pixel array for manipulation
	loadPixels();
}

public void draw() {
	// refresh background
	refreshPixelArray();

	// handle any timed events here because it may affect the pixel array manipulation
	timedEvents();

	// manipulate pixel array
	manipulatePixelArray();

	// write to pixels array
	updatePixels();

	// display FPS
    fill(360, 100, 100);
    textSize(25);
    text("fps: " + (int) frameRate, 50, 50);
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
			// get color in PVector (it stores three floats) for pixels or steps
			PVector col = getColor();
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
						pixels[index] = color(col.x, col.y, col.z);
					}
				}
			}
		}
	}
}

// set canvas and sketch to a new resolution
void setNewGrid() {

	// change stepBias with Noise so that it won't always skew and without bias itself here the full range is possible; otherwise bias would limit that;
	float stepBias = stepBiasNoise.getNoiseRange(.01, 1.6, 1);
	
	println("stepBias: " + stepBias);

	// get new step close to old step with noise, bias towards lower numbers
	xStep = (int)xStepNoise.getVariableNoiseRange(- maxStep/4, 0, maxStep/2, maxStep, stepBias);
	yStep = (int)yStepNoise.getVariableNoiseRange(- maxStep/4, 0, maxStep/2, maxStep, stepBias);

	// cutoff over one and apply
	if (xStep < 1) xStep = 1;
	if (yStep < 1) yStep = 1;

	println("xStep: " + xStep + " yStep: " + yStep);

	// determine if step should be the same in both dimensions
	if (toggleSameStepDims.getNoiseBool(-2, 3)) {
		// apply same step to both dimensions
		yStep = xStep;
		println("same step");
	}

	// determine offset for first iteration so that the "cells" are cutoff not only on the right and bottom edge, that is of random size of the cuttoff cell
	xOffset = (int)random(xStep % width);
	xOffsetRecord = xOffset;
	yOffset = (int)random(yStep % height);
	yOffsetRecord = yOffset;
}

// determine a color for a pixel or a step in the pixel array
PVector getColor() {
	float h, s, b;
	if (isNoiseColor) {
		// inc noises randomly so not all pixels have the same color
		hueNoise.changeInc(hueNoiseInc.getVariableNoiseRange(0.001, 0.01, 0.01, 0.1, 1));
		saturationNoise.changeInc(random(.005, .01));
		brightnessNoise.changeInc(random(.005, .01));
		// get color values from noise
		h = hueNoise.getNoiseRange(-30, 390, 1);
		s = saturationNoise.getNoiseRange(0, 110, 1);
		b = brightnessNoise.getNoiseRange(0, 110, 1);
	} else {
		// get color values at random
		h = (int)random(360);
		s = (int)random(100);
		b = (int)random(100);
	}
	return new PVector(h, s, b);
}

// refresh the pixel array with all black pixels, because background() doesn't do that
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
	// sometimes switch to a new color mode
	colorEventCounter++;
	if (colorEventCounter > (nextColorEvent * 60)) {
		isNoiseColor = toggleColorNoise.getNoiseBool(-1, 1);
		println("isNoiseColor: " + isNoiseColor);
		nextColorEvent = (int)random(minSwitchTime, maxSwitchTime);
		colorEventCounter = 0;
	}
}

// take range and cut at cutoff; useful when a value needs to stick towards the cutoff but should still change sometimes
float cutoff(float range, float cutoff) {
	if (range > cutoff) return range;
	else return cutoff;
}