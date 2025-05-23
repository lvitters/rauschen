import java.util.concurrent.ThreadLocalRandom;		// faster random functions
import java.util.concurrent.*;
import java.io.File;
import java.util.Arrays;
import java.util.Comparator;						
import wellen.*;									// audio stuff
import wellen.dsp.*;								// should be included in the above, but for some reason isn't
import javax.sound.midi.*;
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
// filter for making noise more "bearable"
FilterBandPass bandPassFilter = new FilterBandPass();

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
Noise noiseColorOffsetNoise;
Noise toggleShader;
Noise shaderTimeNoise;
Noise toggleRandomShaderEachFrameNoise;
Noise frequencyNoise;
Noise bandwidthNoise;

// colors
PVector finalCellColor;
float finalCellR, finalCellG, finalCellB;
PVector leadingColor;
float noiseColorOffset;

// toggles
Boolean showDebug = true;
Boolean printDebug = false;
Boolean isAutoMode = false;
Boolean isRandomSwitchTime = false;
Boolean isNoiseColor = false;
Boolean isApplyingShader = false;
Boolean isRandomShaderEachFrame = false;
Boolean isGeneratingSound = false;
Boolean isApplyingAudioFilter = true;
Boolean isTakingScreenshots = true;
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

// midi input
MidiDevice outputDevice;
Receiver midiReceiver;

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

	// midi controls
	//listMidiControllers();
	setupMidiOutput();

	// create buffers
	buffer = createGraphics((int)width, (int)height, P2D);
	tempBuffer = createGraphics((int)width, (int)height, P2D);

	// set up shaders
  	shaders.add(loadShader("shaders/250403_FlowField.glsl"));
  	shaders.add(loadShader("shaders/250408_RectangularCells.glsl"));
  	shaders.add(loadShader("shaders/250430_GameOfLife.glsl"));
  	shaders.add(loadShader("shaders/250501_1DNoise.glsl"));
  	shaders.add(loadShader("shaders/250501_1DNoiseGrid.glsl"));
  	shaders.add(loadShader("shaders/250501_FlowFieldAdvection.glsl"));
  	shaders.add(loadShader("shaders/250501_SmoothLife.glsl"));
  
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
	noises.add(toggleSameStepDimsNoise);
	toggleNoiseColorNoise = new Noise(intRandom(0, 100), 1);
	noises.add(toggleNoiseColorNoise);
	redNoise = new Noise(intRandom(0, 100), .001);
	noises.add(redNoise);
	greenNoise = new Noise(intRandom(0, 100), .001);
	noises.add(greenNoise);
	blueNoise = new Noise(intRandom(0, 100), .001);
	noises.add(blueNoise);
	noiseColorOffsetNoise = new Noise(intRandom(0, 100), .001);
	noises.add(noiseColorOffsetNoise);
	toggleShader = new Noise(intRandom(0, 100), 1);
	noises.add(toggleShader);
	shaderTimeNoise = new Noise(intRandom(0, 100), .01);
	noises.add(shaderTimeNoise);
	toggleRandomShaderEachFrameNoise = new Noise(intRandom(0, 100), .01);
	noises.add(toggleRandomShaderEachFrameNoise);
	frequencyNoise = new Noise(intRandom(0, 100), .005);
	noises.add(frequencyNoise);
	bandwidthNoise = new Noise(intRandom(0, 100), .005);
	noises.add(bandwidthNoise);
}

public void draw() {
	// handle any timed events first because it may affect the pixel array manipulation
	if (isAutoMode) timedEvents();

	// limit for performance
	// if (xStep < 2 || yStep < 2) isNoiseColor = false;

	// manipulate buffer's pixels
	if (!isApplyingShader) {
		manipulatePixelArray();
	} else {
		if (isRandomShaderEachFrame) applyShader(intRandom(0, shaders.size() - 1));
		else applyShader(shaderChoice);
	}

	makeBufferCopyForAudio();

	if (isApplyingAudioFilter) applyAudioFilter();

	// display buffer
	image(buffer, 0, 0, width, height);

	// take screenshot every 3 seconds
	if (isTakingScreenshots && (frameCount % (60 * 3) == 0)) takeScreenshot();

	if (showDebug) showDebug();

	// send information to control sketch
	if (frameCount % 2 == 0) {
		sendNoisesOSC();
		sendDebugOSC();
	}
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
	// get color in PVector (it stores three floats) for pixels or steps
	leadingColor = new PVector(0, 0, 0);
	// generate global color with noise
	if (isNoiseColor) {
		// get noiseColorOffset
		noiseColorOffsetNoise.changeInc(floatRandom(.001, .01));
		noiseColorOffset = noiseColorOffsetNoise.getNoiseRange(0, 255);
		// increment noise
		redNoise.changeInc(floatRandom(.001, .01));
		greenNoise.changeInc(floatRandom(.001, .01));
		blueNoise.changeInc(floatRandom(.001, .01));
		// increment rgb values
		leadingColor.x = redNoise.getNoiseRange(0, 255);
		leadingColor.y = greenNoise.getNoiseRange(0, 255); 
		leadingColor.z = blueNoise.getNoiseRange(0, 255);
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
				// apply global noise color with slight random offset for each pixel
				if (isNoiseColor) {
					// color for each pixel or cell so the color offset won't be added continuously
					finalCellR = leadingColor.x;
					finalCellG = leadingColor.y;
					finalCellB = leadingColor.z;
					// change only one value per pixel and constrain to rgb
					int rand = intRandom(1, 3);
					float colorOffset = floatRandom(-noiseColorOffset, noiseColorOffset + 1);
					if (rand == 1) 	{
						finalCellR += colorOffset;
						if (finalCellR < 0) finalCellR = 0; else if (finalCellR > 255) finalCellR = 255;
					} else if (rand == 2) {
						finalCellG += colorOffset;
						if (finalCellG < 0) finalCellG = 0; else if (finalCellG > 255) finalCellG = 255;
					} else {
						finalCellB += colorOffset;
						if (finalCellG < 0) finalCellB = 0; else if (finalCellB > 255) finalCellB = 255;
					}
				// or apply random color
				} else {
					finalCellR = intRandom(0, 255);
					finalCellG = intRandom(0, 255);
					finalCellB = intRandom(0, 255);
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
								buffer.pixels[index] = 0xFF000000 | ((int)finalCellR << 16) | ((int)finalCellG << 8) | (int)finalCellB;
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
    shaders.get(shader).set("u_resolution", (float)buffer.width, (float)buffer.height); 
    
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

    // copy the result drawn into buffer into tempBuffer so 'tempBuffer' is ready as the input for the next frame's call to applyShader
    if (buffer != null && tempBuffer != null) {
        tempBuffer.beginDraw();
			// use image() to copy buffer's content onto tempBuffer
			tempBuffer.image(buffer, 0, 0); 
        tempBuffer.endDraw();
    } else {
        println("applyShader: cannot copy buffer to tempBuffer - one of them is null.");
    }
}

// resize buffer for "zooming into" shader, similar to grid step being higher in manipulatePixelArray()
public void resizeBuffer(float w, float h) {
    int newW = (int)w;
    int newH = (int)h;

    // exit if size hasn't actually changed
    if (buffer != null && buffer.width == newW && buffer.height == newH) {
        return;
    }
    
    if (printDebug) println("resizing buffers to: " + newW + "x" + newH + " with content preservation.");

    // store references to the current buffers
    PGraphics oldBuffer = buffer; 
    PGraphics oldTempBuffer = tempBuffer;

    // create NEW buffers
    PGraphics newBuffer = createGraphics(newW, newH, P2D);
    PGraphics newTempBuffer = createGraphics(newW, newH, P2D);

    // copy content based on resize type
	// determine if zooming in or out (or same size)
	boolean zoomIn = (newW < oldBuffer.width || newH < oldBuffer.height);
	boolean zoomOut = (newW > oldBuffer.width || newH > oldBuffer.height) && !zoomIn; 
	
	// also copy state for tempBuffer if it's valid
	boolean copyTemp = (oldTempBuffer != null && oldTempBuffer.width > 0 && oldTempBuffer.height > 0);
	if (!copyTemp) println("warning: oldTempBuffer invalid, cannot preserve its state for resize.");

	// zoom in: crop central region from old buffers
	if (zoomIn) {
		if (printDebug) println("zooming IN (cropping center)");
		
		int sWidth = newW; 
		int sHeight = newH;
		int sx = (oldBuffer.width - sWidth) / 2;
		int sy = (oldBuffer.height - sHeight) / 2;
		sx = max(0, sx);
		sy = max(0, sy);
		sWidth = min(sWidth, oldBuffer.width - sx); 
		sHeight = min(sHeight, oldBuffer.height - sy);

		newBuffer.beginDraw();
			newBuffer.copy(oldBuffer, sx, sy, sWidth, sHeight, 0, 0, newW, newH);
		newBuffer.endDraw();
		
		if (copyTemp) {
			newTempBuffer.beginDraw();
				newTempBuffer.copy(oldTempBuffer, sx, sy, sWidth, sHeight, 0, 0, newW, newH);
			newTempBuffer.endDraw();
		}

	// zoom out: stretch old image to fit new, larger buffer
	} else if (zoomOut) {
		if (printDebug) println("zooming OUT (stretching)"); 

		// draw old content stretched onto the entire new buffer
		newBuffer.beginDraw();
			// tell image() to draw oldBuffer onto the destination rect (0,0) to (newW, newH)
			newBuffer.image(oldBuffer, 0, 0, newW, newH); // stretches oldBuffer
		newBuffer.endDraw();
		
		if (copyTemp) {
			newTempBuffer.beginDraw();
				// also stretch old temp buffer content
				newTempBuffer.image(oldTempBuffer, 0, 0, newW, newH); // tretches oldTempBuffer
			newTempBuffer.endDraw();
		}
		
	} else {
		// same size: direct copy
		println("copying content (same size)");
		newBuffer.beginDraw();
			newBuffer.image(oldBuffer, 0, 0, newW, newH); // use image or copy
		newBuffer.endDraw();
		
		if (copyTemp) {
			newTempBuffer.beginDraw();
				newTempBuffer.image(oldTempBuffer, 0, 0, newW, newH); // use image or copy
			newTempBuffer.endDraw();
		}
	}


    // replace main references with the newly created and filled buffers
    buffer = newBuffer;
    tempBuffer = newTempBuffer;

    // dispose the old buffers after content is copied
    if (oldBuffer != null) {
        oldBuffer.dispose();
    }
    if (oldTempBuffer != null) {
        oldTempBuffer.dispose();
    }

    if (printDebug) println("buffers resized successfully with content preservation (crop/stretch).");
}

// choose a random event after a random interval, or set the time until the next event to switchTime
void timedEvents() {
	eventCounter++;
	if (!isRandomSwitchTime) nextEvent = switchTime + (switchTime * switchTimeMultiplier);
	if (eventCounter > (nextEvent * 60)) {
		chooseEvent(intRandom(0, 4));
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
			// isRandomShaderEachFrame = toggleRandomShaderEachFrameNoise.getNoiseBool(-1, 1);
			isRandomShaderEachFrame = !isRandomShaderEachFrame;
			if (!isRandomShaderEachFrame) shaderChoice = intRandom(0, shaders.size() - 1);
		break;
	}
}

// apply audio filter with noise
void applyAudioFilter() {
	bandPassFilter.set_frequency(frequencyNoise.getVariableNoiseRange(0, 100, Wellen.DEFAULT_SAMPLING_RATE - 18000, Wellen.DEFAULT_SAMPLING_RATE - 8000));
	bandPassFilter.set_bandwidth(bandwidthNoise.getVariableNoiseRange(0, 100, Wellen.DEFAULT_SAMPLING_RATE - 18000, Wellen.DEFAULT_SAMPLING_RATE - 8000) * 0.5f);
	// manually
	// float targetFreq = map(mouseX, 0, width, 1.0f, Wellen.DEFAULT_SAMPLING_RATE * 1.0f);
	// float bandwidth = map(mouseY, 0, height, 1.0f, Wellen.DEFAULT_SAMPLING_RATE * 0.5f);
	if (printDebug) println("freq: " + bandPassFilter.get_frequency() + "\n" + "bandwidth: " + bandPassFilter.get_bandwidth());
}

// take a screenshot with date and time to special path
void takeScreenshot() {
    // enerate the timestamp and filename
    final String timeStamp = year() + nf(month(), 2) + nf(day(), 2) + "-" + nf(hour(), 2) + nf(minute(), 2) + nf(second(), 2) + "-" + nf(millis() % 1000, 3);
    final String filename = "../rauschen_screens/temp/rauschen-" + timeStamp + ".png";

    // capture current frame to save
    final PImage frameToSave = get();
    // final PImage frameToSave = myBuffer.get(); // maybe get the buffer instead?

    // create and start new thread to actually save for performance
    new Thread(new Runnable() {
        public void run() {
            frameToSave.save(filename);
            if (printDebug) println("screenshot saved: " + filename);
        }
    }).start();

	// keep image folder x files larges
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
			if (printDebug) println("deleting old file: " + files[i].getName());
			files[i].delete();
		}
	}
}

// render rudimentary debug info to the main window (rest is handled in control sketch)
void showDebug() {
		// audio pixels debug line (only show when sound is actually playing)
		// if (isGeneratingSound && audioDebugPixels != null) {
		// 	for (int i = 0; i < audioDebugPixels.size(); i++) {
		// 		PVector p = audioDebugPixels.get(i);
		// 		if (i == 0 || i == audioDebugPixels.size() - 1) {
		// 			stroke(0, 255, 0);
		// 			strokeWeight(10);
		// 		} else {
		// 			stroke(255, 0, 0);
		// 			strokeWeight(5);
		// 		}
		// 		if (p != null) point(p.x, p.y);
		// 		noStroke();
		// 	}
		// }
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
	// show debug / fps
	if (key == 'f') {
		showDebug = !showDebug;
	}
	// print (more) debug info
	if (key == 'p') {
		printDebug = !printDebug;
	}
	// use auto mode or not
	if (key == 'a') {
		isAutoMode = !isAutoMode;
	}
	// switch to next mode now!
	if (key == 's') {
		chooseEvent(intRandom(0, 2));
	}
	// stop noise (audio)
	if (key == 'n') {
		if (!isGeneratingSound) toggleSound(true);
		else toggleSound(false);
	}
}