import java.util.concurrent.ThreadLocalRandom;		// faster random functions
import java.util.concurrent.*;
import java.io.File;
import java.util.Arrays;
import java.util.Comparator;						
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
float xStepMultiplier = 1;							// has to start at 1 
float yStepMultiplier = 1;							// has to start at 1 
Boolean stepUpdatedManually = false;
int xOffset = 0;
int xOffsetRecord = 0;
int yOffset = 0;
int yOffsetRecord = 0;
int maxIndex = width * height * 4;

// buffer for display
PGraphics buffer;
PGraphics tempBuffer;

// screenshots
String screensDir = "../rauschen_screens/temp/";
int maxFiles = 100; // maximum number of files to keep
Boolean takeSingleScreenshot = false;

// audio sampling line debug pixels
CopyOnWriteArrayList<PVector> audioDebugPixels = new CopyOnWriteArrayList<PVector>();
// audio sampling line orientation: 0 = diagonal, 1 = horizontal, 2 = vertical
int audioSamplingMode = 0;
// thread-safe pixel array copy for audio to access
int[] audioPixels;

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
Boolean isAutoMode = false;
Boolean isRandomSwitchTime = false;
Boolean isNoiseColor = false;
Boolean isApplyingShader = false;
Boolean isRandomShaderEachFrame = false;
Boolean isGeneratingSound = false;
Boolean isTakingScreenshots = false;
Boolean isEvenOffset = false;

// timed events
float switchTime = 1;
float minSwitchTime = 0;
float maxSwitchTime = 1;
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
	surface.setLocation(0, 40);

	// can't go in settings for some reason
	frameRate(120);
	colorMode(RGB, 255, 255, 255);

	// create buffers
	buffer = createGraphics((int)width, (int)height, P2D);
	tempBuffer = createGraphics((int)width, (int)height, P2D);

	// set up shaders
	// shaders.add(loadShader("shaders/250314_1DNoise.glsl"));
  	shaders.add(loadShader("shaders/250325_GameOfLife.glsl"));
  	shaders.add(loadShader("shaders/250403_FlowField.glsl"));
  	shaders.add(loadShader("shaders/250408_1DNoise.glsl"));
  	// shaders.add(loadShader("shaders/250408_ReactionDiffusion.glsl"));
  	shaders.add(loadShader("shaders/250408_RectangularCells.glsl"));
  
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
	}

	makeBufferCopyForAudio();

	// display buffer
	image(buffer, 0, 0, width, height);

	// take screenshot every 3 seconds
	if (isTakingScreenshots && (frameCount % (60 * 3) == 0)) takeScreenshot();
	else if (takeSingleScreenshot) {
		takeScreenshot();
		takeSingleScreenshot = false;
	}

	if (showDebug) showDebug();

	// send information to control sketch
	sendNoisesOSC();
	sendDebugOSC();
}

// apply from setNewGridWithNoise() to the pixel array 
void manipulatePixelArray() {
	// update steps from controller, if there are new steps
	if (stepUpdatedManually) {
		xStep = (int) (nextX * xStepMultiplier);
		yStep = (int) (nextY * yStepMultiplier);
		stepUpdatedManually = false;
		if (isEvenOffset) determineEvenOffset(xStep, yStep);
		else determineRandomOffset(xStep, yStep);
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

	determineRandomOffset(xStep, yStep);
}

// determine offset for first iteration of manipulatePixels() that is of random size of the cuttoff cell
// so that the "cells" are cutoff not only on the right and bottom edge
void determineRandomOffset(int x, int y) {
	xOffset = (int)random(x % width);
	xOffsetRecord = xOffset;
	yOffset = (int)random(y % height);
	yOffsetRecord = yOffset;
}

// determine offset but make it even (looks better with manual or gradual pixel manipulation)
void determineEvenOffset(int x, int y) {
	xOffset = (int)(x % width) / 2;
	xOffsetRecord = xOffset;
	yOffset = (int)(y % height) / 2;
	yOffsetRecord = yOffset;
}

// for resource intensive calculations on individual pixels, use a shader
void applyShader(int shader) {
	// apply shader time (like T in noise)
    shaderTime += shaderTimeNoise.getNoiseRange(.05, .3); 
    shaders.get(shader).set("u_time", shaderTime);
    // set resolution uniform just in case it wasn't set universally or needs update
    shaders.get(shader).set("u_resolution", (float)width, (float)height); 
    
    // set the input texture for the shader to read from tempBuffer with result from last frame's copy
    shaders.get(shader).set("u_texture", tempBuffer); 
                                        
    if (buffer != null) {
        try {
            // draw the shader output onto 'buffer'
            buffer.beginDraw();
                buffer.shader(shaders.get(shader));
                // draw rect covering the buffer to execute the shader for all pixels
                buffer.rect(0, 0, width, height); 
                //buffer.resetShader(); // good practice
            buffer.endDraw();
            // 'buffer' now holds the result of this frame's shader pass
        } catch (Exception e) {
            println("buffer draw error in applyShader: " + e.getMessage());
        }
    }

    // copy the result drawn into buffer into tempBuffer
    // so 'tempBuffer' is ready as the input for the next frame's call to applyShader
    // if (buffer != null && tempBuffer != null) {
    //     tempBuffer.beginDraw();
	// 		// use image() to copy buffer's content onto tempBuffer
	// 		tempBuffer.image(buffer, 0, 0); 
    //     tempBuffer.endDraw();
    // } else {
    //      println("applyShader: cannot copy buffer to tempBuffer - one of them is null.");
    // }
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
				resizeBuffer(intRandom(width/4, width), intRandom(height/4, height));
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

// take a screenshot with date and time to special path (change for exhibition)
void takeScreenshot() {
	String timeStamp = year() + nf(month(), 2) + nf(day(), 2) + "-" + nf(hour(), 2) + nf(minute(), 2) + nf(second(), 2) + "-" + nf(millis() % 1000, 3);
	saveFrame("../rauschen_screens/temp/rauschen-" + timeStamp + ".png");

	// cleanup after every new screenshot
	cleanupImageFolder();
}

// check if there are more than maxFiles files in the screenshot folder, delete oldest
void cleanupImageFolder() {
	File folder = new File(sketchPath(screensDir));
	File[] files = folder.listFiles();
	
	if (files != null && files.length > maxFiles) {
		// sort files by last modified date (oldest first)
		Arrays.sort(files, new Comparator<File>() {
			public int compare(File f1, File f2) {
				return Long.compare(f1.lastModified(), f2.lastModified());
			}
		});
		
		// delete oldest files until we're back to the maximum
		int numToDelete = files.length - maxFiles;
		for (int i = 0; i < numToDelete; i++) {
			if (printDebug) println("Deleting old file: " + files[i].getName());
			files[i].delete();
		}
	}
}

// render rudimentary debug info to the main window (rest is handled in control sketch)
void showDebug() {
		// audio pixels debug line (only show when sound is actually playing)
		if (isGeneratingSound && audioDebugPixels != null) {
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
		// rudimentary debug info
		fill(0, 0, 0);
		rect(0, 0, 210, 65);
		fill(255, 255, 255);
		textSize(25);
		text("fps: " + (int) frameRate, 10, 30);
		text("isAutoMode: " + isAutoMode, 10, 55);
}

// listen to key presses (fallback - stuff generally handled by control sketch)
void keyPressed() {
	// f - show debug / fps
	if (keyCode == 70) {
		showDebug = !showDebug;
	}
	// p - print (more) debug info
	if (keyCode == 80) {
		printDebug = !printDebug;
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
		if (!isGeneratingSound) toggleSound(true);
		else toggleSound(false);
	}
}