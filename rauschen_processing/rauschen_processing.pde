import java.util.concurrent.ThreadLocalRandom;		// faster random functions
import javax.sound.midi.*;							// midi controller input
import wellen.*;									// audio stuff
import wellen.dsp.*;								// should be included in the above, but for some reason isn't
import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress controlSketchLocation;

// buffer for display
PGraphics buffer;
PGraphics tempBuffer;

// shader stuff
PShader shader;
float shaderTime = 0;

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
Noise redNoise;
Noise greenNoise;
Noise blueNoise;
Noise shaderTimeNoise;

// toggles
Boolean showDebug = false;
Boolean printDebug = false;
Boolean isAutoMode = true;
Boolean isRandomSwitchTime = true;
Boolean isApplyingShader = false;
Boolean isNoiseColor = false;
Boolean isMakingSound = false;

// timed events
float switchTime = 1;
float minSwitchTime = 1;
float maxSwitchTime = 10;
float switchTimeMultiplier = 0;
float nextEvent = 1;		// init with 1 second
float eventCounter = 0;

// input
MidiDevice inputDevice;
int[] knobValues = new int[4]; // currently using 4 knobs

public void settings() {
	size(width, height, P2D);
}

public void setup() {
	// set this window title
	windowTitle("Rauschen");

	// determine this window location on screen
	surface.setLocation(10, 60);

	// can't go in settings for some reason
	frameRate(120);
	colorMode(RGB, 255, 255, 255);

	// midi controls
	setupMidi();

	// init OSC
	oscP5 = new OscP5(this, 9000); // local port for this sketch
	controlSketchLocation = new NetAddress("127.0.0.1", 12000); // receiver IP and port

	// start wellen's digital signal processing but pause for now
	DSP.start(this);
	DSP.pause(true);

	// create buffer
	buffer = createGraphics((int)width, (int)height, P2D);
	tempBuffer = createGraphics((int)width, (int)height, P2D);

	// shader stuff
	shader = loadShader("1DNoise.glsl");
	shader.set("u_resolution", (float)width, (float)height);

	// init ArrayList of noises
	noises = new ArrayList<Noise>();

	// init NoiseInstances with starting value and increment, add to list of noises
	xStepNoise = new Noise(intRandom(0, 100), .01);
	noises.add(xStepNoise);
	yStepNoise = new Noise(intRandom(0, 100), .01);
	noises.add(yStepNoise);
	toggleSameStepDims = new Noise(intRandom(0, 100), 1);
	noises.add(toggleSameStepDims);		// TODO: do I want Booleans to show their actual number on the graph or do I want it as 1 and 0?
	toggleShader = new Noise(intRandom(0, 100), 1);
	noises.add(toggleShader);
	toggleNoiseColor = new Noise(intRandom(0, 100), 1);
	noises.add(toggleNoiseColor);
	redNoise = new Noise(intRandom(0, 100), .001);
	noises.add(redNoise);
	greenNoise = new Noise(intRandom(0, 100), .001);
	noises.add(greenNoise);
	blueNoise = new Noise(intRandom(0, 100), .001);
	noises.add(blueNoise);
	shaderTimeNoise = new Noise(intRandom(0, 100), .01);
	noises.add(shaderTimeNoise);
}

public void draw() {
	receiveMidi();

	// handle any timed events first because it may affect the pixel array manipulation
	if (isAutoMode) timedEvents();

	// to avoid bad performance
	if (xStep < 10 || yStep < 10) isNoiseColor = false;
	else isNoiseColor = true;	//debug

	// manipulate buffer's pixels
	if (!isApplyingShader) {
		manipulatePixelArray();
	} else {
		applyShader();
		// load shader pixels into buffer for audioblock() to generate sound from
		buffer.loadPixels();
	}

	// display buffer
	image(buffer, 0, 0, width, height);

	if (showDebug) showDebug();

	// send information to control sketch
	sendNoisesOSC();
	sendInfoOSC();
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
				float r, g, b;
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
							// apply respective color to pixels array
							buffer.pixels[index] = 0xFF000000 | ((int)col.x << 16) | ((int)col.y << 8) | (int)col.z;
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
	if (buffer != null) {
		try {
			buffer.beginDraw();
				buffer.shader(shader);
				buffer.rect(0, 0, width, height);
			buffer.endDraw();
		} catch (Exception e) {
			println("buffer error: " + e.getMessage());
			buffer = createGraphics(width, height, P2D);
		}
	}
}


// set canvas and sketch to a new resolution
void setNewGrid() {

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
	if (toggleSameStepDims.getNoiseBool(-4, 3)) {
		// apply same step to both dimensions
		yStep = xStep;
		if (printDebug) println("same step");
	}

	// determine offset for first iteration that is of random size of the cuttoff cell
	// so that the "cells" are cutoff not only on the right and bottom edge
	xOffset = (int)random(xStep % width);
	xOffsetRecord = xOffset;
	yOffset = (int)random(yStep % height);
	yOffsetRecord = yOffset;
}

// like "setNewGrid()", but just resize for shader use
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
		chooseEvent(intRandom(0, 2));
		if (maxSwitchTime > minSwitchTime) nextEvent = floatRandom(minSwitchTime + (minSwitchTime * switchTimeMultiplier), maxSwitchTime + (maxSwitchTime * switchTimeMultiplier));
		else nextEvent = 0;
		eventCounter = 0;
	}
}

// switch between which events to fire
void chooseEvent(int event) {
	if (printDebug) println("event: " + event);
	switch (event) {
		case 0:
			if (!isApplyingShader) {
				setNewGrid();
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
			isNoiseColor = toggleNoiseColor.getNoiseBool(-1, 1);
	}
}

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

// this gets called by wellen's digital signal processing (DSP) and takes an array of samples for playback
void audioblock(float[] pSamples) {
	if (buffer.pixels != null) {
		for (int i = 0; i < pSamples.length; i++) {
			// extract RGB components from buffer pixel array
			float red = red(buffer.pixels[i]);
			float green = green(buffer.pixels[i]);
			float blue = blue(buffer.pixels[i]);

			// calculate the average
			float average = (red + green + blue) / 3.0;

			// map to (desired) audio sample range
			pSamples[i] = map(average, 0, 255, -.5, 5);

			//println(pSamples[i]);
		}
	}
}

// render some debug info to the main window
void showDebug() {
		fill(0, 0, 0);
		rect(0, 0, 300, 200);
		fill(255, 0, 0);
		textSize(25);
		text("fps: " + (int) frameRate, 10, 30);
		text("xStep: " + xStep + " yStep: " + yStep, 10, 55);
		text("auto mode: " + isAutoMode, 10, 80);
		text("next switch in: " + nf(nextEvent, 2, 3), 10, 105);
		text("random switch time: " + isRandomSwitchTime, 10, 130);
		text("applying shader: " + isApplyingShader, 10, 155);
		text("noise color: " + isNoiseColor, 10, 180);
}

// listen to key presses
void keyPressed() {
	// f - show fps
	if (keyCode == 70) {
		showDebug = !showDebug;
	}
	// d - print debug
	if (keyCode == 68) {
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
		if (DSP.is_paused()) DSP.pause(false);
		else DSP.pause(true);
	}
}

// map variables to midi input
void receiveMidi() {
	minSwitchTime = (1 + knobValues[0]) / 12.8;	// cannot be 0
	maxSwitchTime = (1 + knobValues[1]) / 12.8;	// cannot be 0
	switchTime = (knobValues[2]) / 12.8 / 2;	// can be 0
	switchTimeMultiplier = knobValues[3];		// should be 0 most of the time
}

// get info from device list and set controller as input device
void setupMidi() {
	try {
		// get all MIDI devices
		MidiDevice.Info[] infos = MidiSystem.getMidiDeviceInfo();
		
		// look specifically for MPKmini2 with transmitter capability
		for (int i = 0; i < infos.length; i++) {
			MidiDevice device = MidiSystem.getMidiDevice(infos[i]);
			if (infos[i].getName().equals("MPKmini2") && device.getMaxTransmitters() != 0) {
				inputDevice = device;
				inputDevice.open();
				Transmitter transmitter = inputDevice.getTransmitter();
				transmitter.setReceiver(new MidiInputReceiver());
				println("Successfully opened MPKmini2 for input");
				break;
			}
		}
		if (inputDevice == null) {
			println("Could not find MPKmini2 with input capability");
		}
	} catch (Exception e) {
		println("Error: " + e.getMessage());
		e.printStackTrace();
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
void sendInfoOSC() {
    // send each parameter as its own OSC message (booleans need to be converted to 1 and 0)
    oscP5.send(new OscMessage("/info/fps").add((int)frameRate), controlSketchLocation);
    oscP5.send(new OscMessage("/info/xStep").add(xStep), controlSketchLocation);
    oscP5.send(new OscMessage("/info/yStep").add(yStep), controlSketchLocation);
    oscP5.send(new OscMessage("/info/isAutoMode").add(isAutoMode ? 1 : 0), controlSketchLocation);
    oscP5.send(new OscMessage("/info/nextSwitch").add(nextEvent), controlSketchLocation);
    oscP5.send(new OscMessage("/info/isRandomSwitchTime").add(isRandomSwitchTime ? 1 : 0), controlSketchLocation);
    oscP5.send(new OscMessage("/info/isApplyingShader").add(isApplyingShader ? 1 : 0), controlSketchLocation);
    oscP5.send(new OscMessage("/info/isNoiseColor").add(isNoiseColor ? 1 : 0), controlSketchLocation);
    oscP5.send(new OscMessage("/info/isMakingSound").add(isMakingSound ? 1 : 0), controlSketchLocation);
}