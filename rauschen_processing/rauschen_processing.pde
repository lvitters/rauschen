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
Noise toggleShader;
Noise toggleNoiseColor;
Noise rNoise;
Noise rNoiseInc;
Noise gNoise;
Noise gNoiseInc;
Noise bNoise;
Noise bNoiseInc;
Noise shaderTimeNoise;

// toggles
Boolean isApplyingShader = false;
Boolean showFPS = false;

// timed events
float minSwitchTime = .01;
float maxSwitchTime = .1;
float nextEvent = 1;		// init with 1 second
float eventCounter = 0;

// buffer for display
PGraphics buffer;
PGraphics tempBuffer;

// shader stuff
PShader shader;
float shaderTime = 0;

public void settings() {
	size(width, height, P2D);
}

public void setup() {
	// create buffer
	buffer = createGraphics((int)width, (int)height, P2D);
	tempBuffer = createGraphics((int)width, (int)height, P2D);

	// set this window title
	windowTitle("Rauschen");

	// determine this window location on screen
	surface.setLocation(10, 60);

	// can't go in settings for some reason
	frameRate(60);
	colorMode(RGB, 100, 100, 100);

	// shader stuff
	shader = loadShader("1DNoise.glsl");
	shader.set("u_resolution", (float)width, (float)height);

	// init ArrayList of noises
	noises = new ArrayList<Noise>();

	// init NoiseInstances with starting value and increment, add to list of noises
	xStepNoise = new Noise(intRandom(0, 100), .1);
	noises.add(xStepNoise);
	yStepNoise = new Noise(intRandom(0, 100), .1);
	noises.add(yStepNoise);
	stepBiasNoise = new Noise(intRandom(0, 100), .1);
	noises.add(stepBiasNoise);
	toggleSameStepDims = new Noise(intRandom(0, 100), 1);
	noises.add(toggleSameStepDims);		// TODO: do I want Booleans to show their actual number on the graph or do I want it as 1 and 0?
	toggleShader = new Noise(intRandom(0, 100), 1);
	noises.add(toggleShader);
	toggleNoiseColor = new Noise(intRandom(0, 100), 1);
	noises.add(toggleNoiseColor);
	rNoise = new Noise(intRandom(0, 100), .01);
	noises.add(rNoise);
	rNoiseInc = new Noise(intRandom(0, 100), .01);
	noises.add(rNoiseInc);
	gNoise = new Noise(intRandom(0, 100), .01);
	noises.add(gNoise);
	gNoiseInc = new Noise(intRandom(0, 100), .01);
	noises.add(gNoiseInc);
	bNoise = new Noise(intRandom(0, 100), .01);
	noises.add(bNoise);
	bNoiseInc = new Noise(intRandom(0, 100), .01);
	noises.add(bNoiseInc);
	shaderTimeNoise = new Noise(intRandom(0, 100), .01);
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

	// display buffer
	image(buffer, 0, 0, width, height);

	// Disable shader before drawing text
    resetShader();

	if (showFPS) {
		// display FPS
		fill(100, 0, 0);
		textSize(25);
		text("fps: " + (int) frameRate, 50, 50);
	}
}

// apply from setNewGrid() to the pixel array 
void manipulatePixelArray() {
	buffer.loadPixels();
		// iterate through pixel array with step and apply offset
		for (int x = 0; x < buffer.width; x += xStep - xOffset) {
			// offset only applies to first iteration
			if (x > 0) xOffset = 0;
			else xOffset = xOffsetRecord;
			for (int y = 0; y < buffer.height; y += yStep - yOffset) {
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
						if (px < buffer.width && py < buffer.height) {
							// get index
							int index = py * width + px;
							// apply respective color to pixels array
							buffer.pixels[index] = color(col.x, col.y, col.z);
						}
					}
				}
			}
		}
	buffer.updatePixels();
}

// for resource intensive calculations on individual pixels, use a shader
void applyShader() {
	shaderTime += shaderTimeNoise.getNoiseRange(.05, .3);
	shader.set("u_time", shaderTime);
	shader.set("u_texture", tempBuffer);
	buffer.beginDraw();
		buffer.shader(shader);
		buffer.rect(0, 0, width, height);
	buffer.endDraw();
}

// load a random shader
void chooseRandomShader() {
	int rand = intRandom(0, 2);
}

// set canvas and sketch to a new resolution
void setNewGrid() {

	// get new step close to old step with noise, bias towards lower numbers
	xStep = (int)xStepNoise.getVariableNoiseRange(- maxStep, -maxStep/2, maxStep/2, maxStep, -20);
	yStep = (int)yStepNoise.getVariableNoiseRange(- maxStep, -maxStep/2, maxStep/2, maxStep, -20);

	// cutoff over one and apply
	if (xStep < 1) xStep = 1;
	if (yStep < 1) yStep = 1;

	println("xStep: " + xStep + " yStep: " + yStep);

	// determine if step should be the same in both dimensions
	if (toggleSameStepDims.getNoiseBool(-4, 3)) {
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
	buffer.dispose();
	buffer = createGraphics((int)w, (int)h, P2D);
	println("buffer resized to: x:" + w + " y: " + h);
}

// choose a random event after a random interval
void timedEvents() {
	eventCounter++;
	if (eventCounter > (nextEvent * 60)) {
		chooseRandomEvent(intRandom(0, 1));
		nextEvent = floatRandom(minSwitchTime, maxSwitchTime);
		eventCounter = 0;
	}
}

// switch between which events to fire
void chooseRandomEvent(int event) {
	println("event: " + event);
	switch (event) {
		case 0:
			if (!isApplyingShader) {
				setNewGrid();
			} else {
				resizeBuffer(intRandom(0, width/2), intRandom(0, height/2));
			}
		break;
		case 1:
			isApplyingShader = toggleShader.getNoiseBool(-1, 1);
			println("applying shader: " + isApplyingShader);
			if (isApplyingShader) tempBuffer.copy(buffer, 0, 0, buffer.width, buffer.height, 0, 0, tempBuffer.width, tempBuffer.height);
			resizeBuffer(width, height);
		break;
	}
}

// listen to key presses
void keyPressed() {
	if (keyCode == 70) {
		showFPS = !showFPS;
	}
}

// ------------------------------------------------ UNUSED ------------------------------------------------ //

// empty the display buffer 
void clearBuffer(PGraphics buffer) {
	buffer.loadPixels();
	for (int i = 0; i < buffer.pixels.length; i++) {
		buffer.pixels[i] = 0;
	}
	buffer.updatePixels();
}

// take range and cut at cutoff; useful when a value needs to stick towards the cutoff but should still change sometimes
float cutoff(float value, float cutoff) {
	if (value > cutoff) return value;
	else return cutoff;
}

// determine a color for a pixel or a step in the pixel array
PVector getColor() {
	float r, g, b;
	if (isApplyingShader) {
		// inc noises randomly so not all pixels have the same color
		rNoise.changeInc(floatRandom(.005, .01));
		gNoise.changeInc(floatRandom(.005, .01));
		bNoise.changeInc(floatRandom(.005, .01));
		// get color values from noise
		r = rNoise.getNoiseRange(0, 110);
		g = gNoise.getNoiseRange(0, 110);
		b = bNoise.getNoiseRange(0, 110);
	} else {
		// get color values at random
		r = intRandom(0, 360);
		g = intRandom(20, 100);
		b = intRandom(20, 100);
	}
	return new PVector(r, g, b);
}