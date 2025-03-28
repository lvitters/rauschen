import java.util.concurrent.ThreadLocalRandom;		// faster random functions
import java.util.concurrent.*;						
import wellen.*;									// audio stuff
import wellen.dsp.*;								// should be included in the above, but for some reason isn't
import oscP5.*;
import netP5.*;

// main window
int width = 1000;
int height = 1000;

// resolution steps
int maxStep = width;
int xStep = 1;
int yStep = 1;
int nextX = 1;
int nextY = 1;
float xStepMultiplier = 1;			// has to start at 1 
float yStepMultiplier = 1;			// has to start at 1 
Boolean stepUpdated = false;
int xOffset = 0;
int xOffsetRecord = 0;
int yOffset = 0;
int yOffsetRecord = 0;
int maxIndex = width * height * 4;

// buffer for display
PGraphics buffer;
PGraphics tempBuffer;

// audio sampling line debug pixels
CopyOnWriteArrayList<PVector> audioDebugPixels = new CopyOnWriteArrayList<PVector>();
// audio sampling line orientation: 0 = diagonal, 1 = horizontal, 2 = vertical
int audioSamplingMode = 0;

// shader stuff
ArrayList<PShader> shaders = new ArrayList<PShader>();
float shaderTime = 0;
int shaderChoice = 0;

// color
color c;

// noises
ArrayList<Noise> noises = new ArrayList<Noise>();
Noise xStepNoise;
Noise yStepNoise;
Noise stepBiasNoise;
Noise toggleSameStepDimsNoise;
Noise toggleNoiseColorNoise;
Noise redNoise;
Noise greenNoise;
Noise blueNoise;
Noise toggleShader;
Noise shaderTimeNoise;
Noise toggleRandomShaderEachFrameNoise;

// toggles
Boolean showDebug = false;
Boolean printDebug = false;
Boolean isAutoMode = true;
Boolean isRandomSwitchTime = true;
Boolean isNoiseColor = false;
Boolean isApplyingShader = false;
Boolean isRandomShaderEachFrame = false;
Boolean isMakingSound = false;

// timed events
float switchTime = 1;
float minSwitchTime = 1;
float maxSwitchTime = 10;
float switchTimeMultiplier = 0;
float nextEvent = 1;		// init with 1 second
float eventCounter = 0;

// communication with control sketch
OscP5 oscP5;
NetAddress controlSketchLocation;

public void settings() {
	size(width, height, P2D);
}

public void setup() {
	// set this window title
	windowTitle("RAUSCHEN");

	// determine this window location on screen
	surface.setLocation(10, 60);

	// can't go in settings for some reason
	frameRate(120);
	colorMode(RGB, 255, 255, 255);

	// create buffers
	buffer = createGraphics((int)width, (int)height, P2D);
	tempBuffer = createGraphics((int)width, (int)height, P2D);

	// set up shaders
	shaders.add(loadShader("1DNoise.glsl"));
  	shaders.add(loadShader("GameOfLife.glsl"));
  
	// set uniform variables for all shaders
	for (int i = 0; i < shaders.size(); i++) {
		shaders.get(i).set("u_resolution", (float)width, (float)height);
	}

	// init OSC
	oscP5 = new OscP5(this, 9000); // local port for this sketch
	controlSketchLocation = new NetAddress("127.0.0.1", 12000); // receiver IP and port

	// start wellen's digital signal processing but pause for now
	DSP.start(this);
	DSP.pause(true);
	
	// fill audioDebugPixels with empty pixels to ensure correct size
	while (audioDebugPixels.size() < 1024) {
		audioDebugPixels.add(null); // add placeholder elements
	}

	// init NoiseInstances with starting value and increment, add to list of noises
	xStepNoise = new Noise(intRandom(0, 100), .01);
	noises.add(xStepNoise);
	yStepNoise = new Noise(intRandom(0, 100), .01);
	noises.add(yStepNoise);
	toggleSameStepDimsNoise = new Noise(intRandom(0, 100), 1);
	noises.add(toggleSameStepDimsNoise);		// TODO: do I want Booleans to show their actual number on the graph or do I want it as 1 and 0?
	toggleNoiseColorNoise = new Noise(intRandom(0, 100), 1);
	noises.add(toggleNoiseColorNoise);
	redNoise = new Noise(intRandom(0, 100), .001);
	noises.add(redNoise);
	greenNoise = new Noise(intRandom(0, 100), .001);
	noises.add(greenNoise);
	blueNoise = new Noise(intRandom(0, 100), .001);
	noises.add(blueNoise);
	toggleShader = new Noise(intRandom(0, 100), 1);
	noises.add(toggleShader);
	shaderTimeNoise = new Noise(intRandom(0, 100), .01);
	noises.add(shaderTimeNoise);
	toggleRandomShaderEachFrameNoise = new Noise(intRandom(0, 100), .01);
	noises.add(toggleRandomShaderEachFrameNoise);
}

public void draw() {
	// handle any timed events first because it may affect the pixel array manipulation
	if (isAutoMode) timedEvents();

	// to avoid bad performance
	if (xStep < 10 || yStep < 10) isNoiseColor = false;

	// manipulate buffer's pixels
	if (!isApplyingShader) {
		manipulatePixelArray();
	} else {
		if (isRandomShaderEachFrame) applyShader(intRandom(0, shaders.size() - 1));
		else applyShader(shaderChoice);
		// load shader pixels into buffer for audioblock() to generate sound from
		buffer.loadPixels();
	}

	// display buffer
	image(buffer, 0, 0, width, height);

	if (showDebug) showDebug();

	// send information to control sketch
	sendNoisesOSC();
	sendDebugOSC();
}

// apply from setNewGridWithNoise() to the pixel array 
void manipulatePixelArray() {
	// update steps from controller, if there are new steps
	if (stepUpdated) {
		xStep = (int) (nextX * xStepMultiplier);
		yStep = (int) (nextY * yStepMultiplier);
		stepUpdated = false;
		determineOffset(xStep, yStep);
	}
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
				PVector col;
				if (isNoiseColor) {
					// with noise
					redNoise.changeInc(floatRandom(.01, .1));
					greenNoise.changeInc(floatRandom(.01, .1));
					blueNoise.changeInc(floatRandom(.01, .1));
					col = new PVector(	redNoise.getNoiseRange(0, 255), 
										greenNoise.getNoiseRange(0, 255), 
										blueNoise.getNoiseRange(0, 255));
				} else {
					// or at random
					col = new PVector(intRandom(0, 255), intRandom(0, 255), intRandom(0, 255));
				}
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
							// apply respective color to pixels array, handle out of bounds
							if (index >= 0 && index < buffer.pixels.length) {
								buffer.pixels[index] = 0xFF000000 | ((int)col.x << 16) | ((int)col.y << 8) | (int)col.z;
							}
						}
					}
				}
			}
		}
	buffer.updatePixels();
}

// set canvas and sketch to a new resolution
void setNewGridWithNoise() {

	// get new step close to old step with noise, bias towards lower numbers
	xStep = (int)xStepNoise.getVariableNoiseRange(-maxStep/2, 0, maxStep/2, maxStep, 2);
	yStep = (int)yStepNoise.getVariableNoiseRange(-maxStep/2, 0, maxStep/2, maxStep, 2);
	// xStep = (int)xStepNoise.getNoiseRange(-10, maxStep, 2);
	// yStep = (int)yStepNoise.getNoiseRange(-10, maxStep, 2);

	// cutoff over one and apply
	if (xStep < 1) xStep = 1;
	if (yStep < 1) yStep = 1;

	if (printDebug) println("xStep: " + xStep + " yStep: " + yStep);

	// determine if step should be the same in both dimensions
	if (toggleSameStepDimsNoise.getNoiseBool(-4, 3)) {
		// apply same step to both dimensions
		yStep = xStep;
		if (printDebug) println("same step");
	}

	determineOffset(xStep, yStep);
}

// determine offset for first iteration of manipulatePixels() that is of random size of the cuttoff cell
// so that the "cells" are cutoff not only on the right and bottom edge
void determineOffset(int x, int y) {
	xOffset = (int)random(x % width);
	xOffsetRecord = xOffset;
	yOffset = (int)random(y % height);
	yOffsetRecord = yOffset;
}

// for resource intensive calculations on individual pixels, use a shader
void applyShader(int shader) {
	shaderTime += shaderTimeNoise.getNoiseRange(.05, .3);
	shaders.get(shader).set("u_time", shaderTime);
	shaders.get(shader).set("u_texture", tempBuffer);
	if (buffer != null) {
		try {
			buffer.beginDraw();
				buffer.shader(shaders.get(shader));
				buffer.rect(0, 0, width, height);
			buffer.endDraw();
		} catch (Exception e) {
			println("buffer error: " + e.getMessage());
			buffer = createGraphics(width, height, P2D);
		}
	}
}

// rsize buffer for "zooming into" shader
void resizeBuffer(float w, float h) {
	buffer.dispose();
	buffer = createGraphics((int)w, (int)h, P2D);
	if (printDebug) println("buffer resized to: x:" + (int)w + " y: " + (int)h);
}

// choose a random event after a random interval, or set the time until the next event to switchTime
void timedEvents() {
	eventCounter++;
	if (!isRandomSwitchTime) nextEvent = switchTime + (switchTime * switchTimeMultiplier);
	if (eventCounter > (nextEvent * 60)) {
		chooseEvent(intRandom(0, 3));
		if (maxSwitchTime > minSwitchTime) nextEvent = floatRandom(minSwitchTime + (minSwitchTime * switchTimeMultiplier), maxSwitchTime + (maxSwitchTime * switchTimeMultiplier));
		else nextEvent = 0;
		eventCounter = 0;
	}
}

// switch between which events to fire
void chooseEvent(int event) {
	if (printDebug) println("event: " + event);
	audioSamplingMode = intRandom(0, 2);
	switch (event) {
		case 0:
			if (!isApplyingShader) {
				setNewGridWithNoise();
			} else {
				resizeBuffer(intRandom(0, width), intRandom(0, height));
			}
		break;
		case 1:
			isApplyingShader = toggleShader.getNoiseBool(-1, 1);
			if (isApplyingShader) {
				if (printDebug) println("applying shader");
				tempBuffer.copy(buffer, 0, 0, buffer.width, buffer.height, 0, 0, tempBuffer.width, tempBuffer.height);
			}
			resizeBuffer(width, height);
		break;
		case 2:
			isNoiseColor = toggleNoiseColorNoise.getNoiseBool(-1, 1);
		break;
		case 3:
			isRandomShaderEachFrame = toggleRandomShaderEachFrameNoise.getNoiseBool(-1, 1);
			if (!isRandomShaderEachFrame) shaderChoice = intRandom(0, shaders.size() - 1);
		break;
	}
}

// this gets called by wellen's digital signal processing (DSP) and takes an array of samples for playback
// creates audio samples from a diagonal line through the buffer's pixels
void audioblock(float[] pSamples) {
	if (buffer.pixels != null) {
		int bufferWidth = buffer.width;
		int bufferHeight = buffer.height;
		
		// map samples to pixels along line
		for (int i = 0; i < pSamples.length; i++) {
			int x, y;
			
			// calculate position based on current mode
			switch (audioSamplingMode) {
				case 0: 
					// diagonal (top-left to bottom-right)
					// map sample index directly to buffer diagonal
					float diagonalPos = map(i, 0, pSamples.length - 1, 0, 1);
					x = (int) (diagonalPos * (bufferWidth - 1));
					y = (int) (diagonalPos * (bufferHeight - 1));
				break;
				case 1: 
					// horizontal (left to right)
					// map sample index directly to buffer width
					x = (int) map(i, 0, pSamples.length - 1, 0, bufferWidth - 1);
					y = bufferHeight / 2; // middle of the buffer
				break;
				case 2: 
					// vertical (top to bottom)
					// map sample index directly to buffer height
					x = bufferWidth / 2; // middle of the buffer
					y = (int) map(i, 0, pSamples.length - 1, 0, bufferHeight - 1);
				break;
				default:
					x = 0;
					y = 0;
				break;
			}
			
			// store coordinates for debug visualization
			audioDebugPixels.set(i, new PVector(x, y));
			
			// calculate pixel index
			int pixelIndex = y * bufferWidth + x;
			
			// extract RGB components - no need for bounds check as we've mapped directly to buffer dimensions
			float red = red(buffer.pixels[pixelIndex]);
			float green = green(buffer.pixels[pixelIndex]);
			float blue = blue(buffer.pixels[pixelIndex]);
			
			// calculate the average
			float average = (red + green + blue) / 3.0;
			
			// map to audio sample range, at half volume
			pSamples[i] = map(average, 0, 255, -0.5, 0.5);
		}
	} else {
		// fill with silence if no pixels
		for (int i = 0; i < pSamples.length; i++) {
			pSamples[i] = 0;
			println("buffer empty");
		}
	}
}

// render some debug info to the main window
void showDebug() {
		fill(0, 0, 0);
		rect(0, 0, 400, 220);
		fill(255, 255, 255);
		textSize(25);
		text("fps: " + (int) frameRate, 10, 30);
		text("xStep: " + xStep + " yStep: " + yStep, 10, 55);
		text("isAutoMode: " + isAutoMode, 10, 80);
		text("nextEvent: " + nf(nextEvent, 2, 3), 10, 105);
		text("isRandomSwitchTime: " + isRandomSwitchTime, 10, 130);
		text("isNoiseColor: " + isNoiseColor, 10, 155);
		text("isApplyingShader: " + isApplyingShader, 10, 180);
		text("isRandomShaderEachFrame: " + isRandomShaderEachFrame, 10, 205);

		// audio pixels debug line
		if (showDebug && audioDebugPixels != null) {
			for (int i = 0; i < audioDebugPixels.size(); i++) {
				PVector p = audioDebugPixels.get(i);
				if (i == 0 || i == audioDebugPixels.size() - 1) {
					stroke(0, 255, 0);
					strokeWeight(10);
				} else {
					stroke(255, 0, 0);
					strokeWeight(5);
				}
				if (p != null) point(p.x, p.y);
				noStroke();
			}
		}
}

// listen to key presses
void keyPressed() {
	// f - show debug / fps
	if (keyCode == 70) {
		showDebug = !showDebug;
	}
	// p - print (more) debug info
	if (keyCode == 80) {
		printDebug = !printDebug;
	}
	// r - use random time for next event
	if (keyCode == 82) {
		isRandomSwitchTime = !isRandomSwitchTime;
	}
	// a - use auto mode or not
	if (keyCode == 65) {
		isAutoMode = !isAutoMode;
	}
	// s - switch now!
	if (keyCode == 83) {
		chooseEvent(intRandom(0, 2));
	}
	// n - stop noise (audio)
	if (keyCode == 78) {
		isMakingSound = !isMakingSound;
		if (DSP.is_paused()) DSP.pause(false);
		else DSP.pause(true);
	}
	// c - toggle noise color
	if (keyCode == 67) {
		isNoiseColor = !isNoiseColor;
	}
}

// send noises over OSC
void sendNoisesOSC() {
	// create a new OSC message
	OscMessage msg = new OscMessage("/noises");
	
	// add all noise values to the message
	for (Noise n : noises) {
		msg.add(n.value);
	}
	
	// send the message
	oscP5.send(msg, controlSketchLocation);
}

// send debug info over OSC
void sendDebugOSC() {
    // send each parameter as its own OSC message (booleans need to be converted to 1 and 0)
    oscP5.send(new OscMessage("/info/fps").add((int)frameRate), controlSketchLocation);
    oscP5.send(new OscMessage("/info/xStep").add(xStep), controlSketchLocation);
    oscP5.send(new OscMessage("/info/yStep").add(yStep), controlSketchLocation);
    oscP5.send(new OscMessage("/info/isAutoMode").add(isAutoMode ? 1 : 0), controlSketchLocation);
    oscP5.send(new OscMessage("/info/nextEvent").add(nextEvent), controlSketchLocation);
    oscP5.send(new OscMessage("/info/isRandomSwitchTime").add(isRandomSwitchTime ? 1 : 0), controlSketchLocation);
    oscP5.send(new OscMessage("/info/isNoiseColor").add(isNoiseColor ? 1 : 0), controlSketchLocation);
    oscP5.send(new OscMessage("/info/isApplyingShader").add(isApplyingShader ? 1 : 0), controlSketchLocation);
	oscP5.send(new OscMessage("/info/isRandomShaderEachFrame").add(isRandomShaderEachFrame ? 1 : 0), controlSketchLocation);
}

// handle incoming OSC messages from control sketch
void oscEvent(OscMessage message) {
	// handle parameter updates according to names given in "MidiInputReceiver" which should correspond to variables here
	if (message.checkAddrPattern("/maxSwitchTime")) {
		float value = message.get(0).floatValue();
		maxSwitchTime = map(value, 0, 127, 1, 10);				// cannot be 0
	}
	else if (message.checkAddrPattern("/switchTime")) {
		float value = message.get(0).floatValue();
		switchTime = map(value, 0, 127, 0, 10);					// can be 0
	}
	else if (message.checkAddrPattern("/switchTimeMultiplier")) {
		float value = message.get(0).floatValue();
		switchTimeMultiplier = map(value, 0, 127, 1, 6);		// should be 0 most of the time
	}
	else if (message.checkAddrPattern("/sameStep")) {
		float value = message.get(0).floatValue();
		nextX = nextY = (int) map(value, 0, 127, 1, width/10);	// cannot be 0, should depend on the res
		stepUpdated = true;
	}
	else if (message.checkAddrPattern("/xStep")) {
		float value = message.get(0).floatValue();
		nextX = (int) map(value, 0, 127, 1, width/10);			// cannot be 0, should depend on the res
		stepUpdated = true;
	}
	else if (message.checkAddrPattern("/xStepMultiplier")) {
		float value = message.get(0).floatValue();
		xStepMultiplier = map(value, 0, 127, 1, width/100);		// cannot be 0, should depend on the res
		stepUpdated = true;
	}
	else if (message.checkAddrPattern("/yStep")) {
		float value = message.get(0).floatValue();
		nextY = (int) map(value, 0, 127, 1, height/10);			// cannot be 0, should depend on the res
		stepUpdated = true;
	}
	else if (message.checkAddrPattern("/yStepMultiplier")) {
		float value = message.get(0).floatValue();
		yStepMultiplier = map(value, 0, 127, 1, width/100);		// cannot be 0, should depend on the res
		stepUpdated = true;
	}
}
