import java.util.concurrent.ThreadLocalRandom;

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
Noise rNoise;
Noise rNoiseInc;
Noise gNoise;
Noise gNoiseInc;
Noise bNoise;
Noise bNoiseInc;
Noise shaderTimeNoise;

// toggles
Boolean isApplyingShader = false;

// timed events
int minSwitchTime = 1;
int maxSwitchTime = 10;
int nextResEvent = 1;		// init in X seconds
int resEventCounter = 0;
int nextColorEvent = 1;		// init in X seconds
int colorEventCounter = 0;

// buffer for display
PGraphics resBuffer;

// shader stuff
PShader noiseShader;
float shaderTime = 0;

public void settings() {
	size(width, height, P2D);
}

public void setup() {
	// create buffer
	resBuffer = createGraphics((int)width, (int)height, P2D);

	// set this window title
	windowTitle("Rauschen");

	// determine this window location on screen
	surface.setLocation(10, 60);

	// can't go in settings for some reason
	frameRate(120);
	colorMode(RGB, 100, 100, 100);

	// shader stuff
	noiseShader = loadShader("noiseFrag.glsl");
	noiseShader.set("u_resolution", (float)width, (float)height);

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
	rNoise = new Noise(random(100), .01);
	noises.add(rNoise);
	rNoiseInc = new Noise(random(100), .01);
	noises.add(rNoiseInc);
	gNoise = new Noise(random(100), .01);
	noises.add(gNoise);
	gNoiseInc = new Noise(random(100), .01);
	noises.add(gNoiseInc);
	bNoise = new Noise(random(100), .01);
	noises.add(bNoise);
	bNoiseInc = new Noise(random(100), .01);
	noises.add(bNoiseInc);
	shaderTimeNoise = new Noise(random(100), .01);
	noises.add(shaderTimeNoise);
}

public void draw() {
	// handle any timed events first because it may affect the pixel array manipulation
	timedEvents();

	// manipulate pixel array
	if (!isApplyingShader) {
		manipulatePixelArray();
	} else {
		applyShader();
	}

	// display resBuffer
	image(resBuffer, 0, 0, width, height);

	// Disable shader before drawing text
    resetShader();

	// display FPS
    fill(100, 0, 0);
    textSize(25);
    text("fps: " + (int) frameRate, 50, 50);
}

// apply from setNewGrid() to the pixel array 
void manipulatePixelArray() {
	resBuffer.loadPixels();
		// iterate through pixel array with step and apply offset
		for (int x = 0; x < resBuffer.width; x += xStep - xOffset) {
			// offset only applies to first iteration
			if (x > 0) xOffset = 0;
			else xOffset = xOffsetRecord;
			for (int y = 0; y < resBuffer.height; y += yStep - yOffset) {
				// offset only applies to first iteration
				if (y > 0) yOffset = 0;
				else yOffset = yOffsetRecord;
				// get color in PVector (it stores three floats) for pixels or steps
				PVector col = new PVector(intRandom(0, 100), intRandom(0, 100), intRandom(0, 100));
				// determine indices for pixels array from coordinates and step
				for (int dx = 0; dx < xStep; dx++) {
					for (int dy = 0; dy < yStep; dy++) {
						// get offset
						int px = x + dx;
						int py = y + dy;
						// check boundaries (edges won't have neighboring pixels)
						if (px < resBuffer.width && py < resBuffer.height) {
							// get index
							int index = py * width + px;
							// apply respective color to pixels array
							resBuffer.pixels[index] = color(col.x, col.y, col.z);
						}
					}
				}
			}
		}
	resBuffer.updatePixels();
}

// for noise stuff on individual pixels, use a shader
void applyShader() {
	shaderTime += shaderTimeNoise.getNoiseRange(.01, .1, 1);
	noiseShader.set("u_time", shaderTime);
	resBuffer.beginDraw();
		resBuffer.shader(noiseShader);
		resBuffer.rect(0, 0, width, height);
	resBuffer.endDraw();
}

// empty the display buffer 
void clearBuffer(PGraphics buffer) {
	buffer.loadPixels();
	for (int i = 0; i < buffer.pixels.length; i++) {
		buffer.pixels[i] = 0;
	}
	buffer.updatePixels();
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

// like "setNewGrid()", but just resize for shader use
void resizeBuffer(float w, float h) {
	resBuffer.dispose();
	resBuffer = createGraphics((int)w, (int)h, P2D);
	println("buffer resized to: x:" + w + " y: " + h);
}

// sometimes things should happen at random intervals instead
void timedEvents() {

	// sometimes switch to a new resolution step
	resEventCounter++;
	if (resEventCounter > (nextResEvent * 60)) {
		if (!isApplyingShader) {
			setNewGrid();
		} else {
			resizeBuffer(intRandom(0, width), intRandom(0, height));
		} 
		nextResEvent = (int)random(minSwitchTime, maxSwitchTime);
		resEventCounter = 0;
	}

	// sometimes switch to a new color mode
	colorEventCounter++;
	if (colorEventCounter > (nextColorEvent * 60)) {
		isApplyingShader = toggleColorNoise.getNoiseBool(-1, 1);
		println("isApplyingShader: " + isApplyingShader);
		nextColorEvent = (int)random(minSwitchTime, maxSwitchTime);
		colorEventCounter = 0;
		resizeBuffer(width, height);
	}
}

// ------------------------------------------------ DEPRECATED ------------------------------------------------ //

// take range and cut at cutoff; useful when a value needs to stick towards the cutoff but should still change sometimes
float cutoff(float range, float cutoff) {
	if (range > cutoff) return range;
	else return cutoff;
}

// determine a color for a pixel or a step in the pixel array
PVector getColor() {
	float h, s, b;
	if (isApplyingShader) {
		// inc noises randomly so not all pixels have the same color
		rNoise.changeInc(rNoiseInc.getVariableNoiseRange(0.001, 0.01, 0.01, 0.1, 1));
		gNoise.changeInc(random(.005, .01));
		bNoise.changeInc(random(.005, .01));
		// get color values from noise
		h = rNoise.getNoiseRange(-30, 390, 1);
		s = gNoise.getNoiseRange(0, 110, 1);
		b = bNoise.getNoiseRange(0, 110, 1);
	} else {
		// get color values at random
		h = intRandom(0, 360);
		s = intRandom(20, 100);
		b = intRandom(20, 100);
	}
	return new PVector(h, s, b);
}