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
import processing.opengl.PSurfaceJOGL;				// to set window undecorated
import com.jogamp.newt.Window;
import com.jogamp.newt.util.EDTUtil;

// buffer
int width = 1000;
int height = 1000;

// screenshots
int screenshotHeight = 1000;
int screenshotWidth = 1000;

// display mode: 0 = regular window, 1 = undecorated window with separate dimensions
int displayMode = 0;

// window for displayMode 1
int windowWidth = 1100;
int windowHeight = 1100;
Window newtWindow = null;
EDTUtil edtUtil = null;
volatile boolean isCurrentlyUndecorated = false;

// move around undecorated window 
boolean upArrowDown = false;
boolean downArrowDown = false;
boolean leftArrowDown = false;
boolean rightArrowDown = false;
boolean plusKeyDown = false;
boolean minusKeyDown = false;

// video mapping controls
boolean showVideoMappingControls = false;
PVector[] corners = new PVector[4]; // top-left, top-right, bottom-right, bottom-left
int draggedCorner = -1; // which corner is being dragged (-1 = none)
int handleSize = 25;
int meshResolution = 20; // subdivision for perspective-correct rendering

// resolution steps
int maxStep = width;
int minStep = 1;									// minimum step size to mitigate moiré
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
int globalSpeedDivisor = 1;

// buffer for display
PGraphics buffer;
PGraphics tempBuffer;
PGraphics screenshotBuffer; // for clean screenshots when video mapping is active

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
// manual controls
float audioFrequency = 1;
float audioBandwidth = 1000;

// shader stuff
ArrayList<PShader> shaders = new ArrayList<PShader>();
ArrayList<Integer> activeShaders = new ArrayList<Integer>();
float shaderTime = 0;
int shaderChoice = -1;
int lastShaderChoice;
float shaderTimeMultiplier = 1;
float shaderTimeDivisor = 1;
String[] shaderNames = {
		"250408_RectangularCells.glsl", 
		"250430_GameOfLife.glsl",
		"250501_1DNoise.glsl",
		"250501_1DNoiseGrid.glsl",
		"250501_FlowFieldAdvection.glsl",
		"250501_SmoothLife.glsl",
		"250526_Voronoi_Simple.glsl",
		"250526_Voronoi_Dimensions_Input.glsl",
		"250530_FlowField_Direction.glsl",
		"250603_RectangularCellsLines.glsl",
		"250603_ReshuffleGrid.glsl",
		"250606_RotationalPropagationGlitch.glsl",
		"250606_RotationCenter.glsl",
		"250611_RotationChaos.glsl",
		"250613_GradientCellularAutomaton.glsl",
		"250613_RotationalPropagation.glsl"
};

// color
color c;

// standard Perlin noises
ArrayList<Noise> noises = new ArrayList<Noise>();
Noise autoAutoNoise;
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
Noise noiseColorFastNoiseOffsetXNoise;
Noise noiseColorFastNoiseOffsetYNoise;

// FastNoiseLite for fast 2D noise textures 
FastNoiseLite noiseColorOffsetFastNoise;
float noiseColorOffsetFastNoiseTime = 0;
float colorOffset;
// same for isFastNoiseColor
FastNoiseLite fastColorNoiseR, fastColorNoiseG, fastColorNoiseB;
float fastColorNoiseRTime, fastColorNoiseGTime, fastColorNoiseBTime;

// for switching between fast noise types
FastNoiseLite.NoiseType[] fastNoiseTypes = {
		FastNoiseLite.NoiseType.OpenSimplex2,
		FastNoiseLite.NoiseType.OpenSimplex2S,
		// FastNoiseLite.NoiseType.Cellular,		// kinda ugly
		FastNoiseLite.NoiseType.Perlin,
		FastNoiseLite.NoiseType.ValueCubic,
		FastNoiseLite.NoiseType.Value
};
FastNoiseLite.NoiseType fastNoiseType;
float xOff;
float yOff;

// colors
PVector finalCellColor;
float finalCellR, finalCellG, finalCellB;
PVector leadingColor;
float noiseColorOffset;

// toggles
Boolean showDebug = false;
boolean stopped = false;
Boolean showAudioLine = false;
Boolean printDebug = false;
Boolean isAutoAutoMode = false;
Boolean isAutoMode = true;
Boolean isRandomSwitchTime = false;
Boolean isNoiseColorRandomOffset = false;
Boolean isNoiseColorFastNoiseOffset = false;
Boolean isFastNoiseColor = false;
Boolean isApplyingShader = false;
Boolean isShadersOnly = false;
Boolean isRandomShaderEachFrame = true;
Boolean isGeneratingSound = true;
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
long lastAudioBufferUpdateTime = 0;

// communication with control sketch
OscP5 oscP5;
NetAddress controlSketchLocation;

// midi input
MidiDevice outputDevice;
Receiver midiReceiver;

public void settings() {
	if (displayMode == 0) {
		size(width, height, P2D);
	} else if (displayMode == 1) {
		size(windowWidth, windowHeight, P2D);
	}
}

public void setup() {
	// set this window title
	windowTitle("RAUSCHEN");

	// determine this window location on screen and setup based on display mode
	if (displayMode == 0) {
		surface.setLocation(0, 40);
	} else if (displayMode == 1) {
		// for displayMode 1, remove title bar
		surface.setLocation(0, 40);
		removeTitleBar();
	}

	// can't go in settings for some reason
	frameRate(120);
	colorMode(RGB, 255, 255, 255);

	// midi controls
	//listMidiControllers();
	setupMidiOutput();

	// create buffers
	buffer = createGraphics((int)width, (int)height, P2D);
	tempBuffer = createGraphics((int)width, (int)height, P2D);
	screenshotBuffer = createGraphics(screenshotWidth, screenshotHeight, P2D);

	// init OSC
	oscP5 = new OscP5(this, 9000); // local port for this sketch
	controlSketchLocation = new NetAddress("127.0.0.1", 12000); // receiver IP and port

	// set up shaders
	for (String name : shaderNames) {
		shaders.add(loadShader("shaders/" + name));
	}
  
	// set uniform variables for all shaders
	for (int i = 0; i < shaders.size(); i++) {
		shaders.get(i).set("u_resolution", (float)width, (float)height);
		activeShaders.add(i);	// init all active
	}

	// start wellen's digital signal processing but pause for now
	DSP.start(this);
	DSP.pause(true);

	// turn on by default
	toggleSound(true);
	
	// fill audioDebugPixels with empty pixels to ensure correct size
	while (audioDebugPixels.size() < 1024) {
		audioDebugPixels.add(null); // add placeholder elements
	}

	// init NoiseInstances with starting value and increment, add to list of noises	
	autoAutoNoise = new Noise(intRandom(0, 100), .001);
	noises.add(autoAutoNoise);
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
	frequencyNoise = new Noise(intRandom(0, 100), .002);
	noises.add(frequencyNoise);
	bandwidthNoise = new Noise(intRandom(0, 100), .002);
	noises.add(bandwidthNoise);

	noiseColorFastNoiseOffsetXNoise = new Noise(intRandom(0, 100), .0008);
	noises.add(noiseColorFastNoiseOffsetXNoise);
	noiseColorFastNoiseOffsetYNoise = new Noise(intRandom(0, 100), .0008);
	noises.add(noiseColorFastNoiseOffsetYNoise);

	// init 2D texture with random fastNoise type
	noiseColorOffsetFastNoise = new FastNoiseLite();
	fastNoiseType = fastNoiseTypes[intRandom(0, fastNoiseTypes.length -1)];
	noiseColorOffsetFastNoise.SetNoiseType(fastNoiseType);

	// "complete" fastColorNoise
	fastColorNoiseR = new FastNoiseLite();
	fastColorNoiseR.SetSeed(intRandom(1, 10000));
	fastColorNoiseR.SetNoiseType(fastNoiseType);
	fastColorNoiseG = new FastNoiseLite();
	fastColorNoiseG.SetSeed(intRandom(1, 10000));
	fastColorNoiseG.SetNoiseType(fastNoiseType);
	fastColorNoiseB = new FastNoiseLite();
	fastColorNoiseB.SetSeed(intRandom(1, 10000));
	fastColorNoiseB.SetNoiseType(fastNoiseType);

	// initialize video mapping corners
	initVideoMappingCorners();
}

public void draw() {
	// move window around with arrow keys if there is no title bar
	if (displayMode == 1) {
		moveWindow();
		resizeWindow();
	}

	// stop (almost) everything
	if (!stopped) {

		// handle any timed events first because it may affect the pixel array manipulation
		if (isAutoMode) timedEvents();

		// limit for performance in certain modes
		if ((isNoiseColorRandomOffset && isNoiseColorFastNoiseOffset) || (isNoiseColorRandomOffset && isFastNoiseColor)) {
			if (xStep <= 1 && yStep <= 1) {
				xStep += 2;
				yStep += 2;
			} else if (xStep <= 2 && yStep <= 2) {
				xStep += 1;
				yStep += 1;
			}
		}

		// apply globalSpeed to buffer manipulation
		if (frameCount % globalSpeedDivisor == 0) {
			// manipulate buffer's pixels
			if (isApplyingShader || isShadersOnly || frameCount < 10) {
				// reset shader time occasionally
				if (shaderTime > 1000) shaderTime = intRandom(0, 10);		// don't start at the same spot every time
				// apply shaders
				if (isRandomShaderEachFrame) {
					int rand = pickRandomActiveShader();
					if (!activeShaders.isEmpty()) {
						applyShader(rand);
					}
					// set to shaderChoice for display
					shaderChoice = rand;
				} else {
					// use last choice to apply in case currently no shader is set
					if (shaderChoice == -1) shaderChoice = lastShaderChoice;
					if (!activeShaders.isEmpty()) {
						applyShader(shaderChoice);
					}
				}
			} else {
				manipulatePixelArray();
				// set to -1 for displaying no shader is used
				if (shaderChoice != -1) lastShaderChoice = shaderChoice;
				shaderChoice = -1;
			}
		}

		makeBufferCopyForAudio();
		applyAudioFilter();

		// display buffer
		if (displayMode == 0) {
			image(buffer, 0, 0, width, height);
		} else if (displayMode == 1) {
			// clear background to black first
			background(0);
			drawMappedBuffer();
		}

		// take screenshot every 3 seconds
		if (isTakingScreenshots && (frameCount % (60 * 3) == 0)) takeScreenshot();

		if (showDebug) showDebug();
		if (showAudioLine) showAudioLine();
		if (showVideoMappingControls && displayMode == 1) drawVideoMappingControls();
	}

	// send information to control sketch
	if (frameCount % 2 == 0) {
		sendNoisesOSC();
		sendDebugOSC();
		sendShaderInfoOSC();
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
	if (isNoiseColorRandomOffset) {
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
		// inc FastNoise time
		if (isNoiseColorFastNoiseOffset) {
			noiseColorOffsetFastNoiseTime += noiseColorOffsetNoise.getNoiseRange(.1, 3);
			
			// generate random offset so texture "wobbles"
			xOff = noiseColorFastNoiseOffsetXNoise.getNoiseRange(-5, 5);
			yOff = noiseColorFastNoiseOffsetYNoise.getNoiseRange(-5, 5);
		}
		// inc fastNoiseColor times
		if (isFastNoiseColor) {
			fastColorNoiseRTime += floatRandom(.1, 10);
			fastColorNoiseGTime += floatRandom(.1, 10);
			fastColorNoiseBTime += floatRandom(.1, 10);
		}
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
				// calculate noise coordinates for "zoom" centered in buffer
				float nX = ((buffer.width/2.0) / 2.0f) * (1.0f - xOff) + (x / 2.0f) * xOff;
				float nY = ((buffer.height/2.0) / 2.0f) * (1.0f - yOff) + (y / 2.0f) * yOff;
				// apply global noise color with slight random offset for each pixel/cell
				if (isNoiseColorRandomOffset) {
					if (isFastNoiseColor) {
						finalCellR = map(fastColorNoiseR.GetNoise(nX, nY, fastColorNoiseRTime), -1, 1, 0, 255);
						finalCellG = map(fastColorNoiseG.GetNoise(nX, nY, fastColorNoiseGTime), -1, 1, 0, 255);
						finalCellB = map(fastColorNoiseB.GetNoise(nX, nY, fastColorNoiseBTime), -1, 1, 0, 255);
					} else {
						// color for each pixel or cell so the color offset won't be added continuously
						finalCellR = leadingColor.x;
						finalCellG = leadingColor.y;
						finalCellB = leadingColor.z;
						// change only one value per pixel and constrain to rgb
						int rand = intRandom(1, 3);
						if (!isNoiseColorFastNoiseOffset) colorOffset = floatRandom(-noiseColorOffset, noiseColorOffset + 1);
						else if (isNoiseColorFastNoiseOffset) colorOffset = map(noiseColorOffsetFastNoise.GetNoise(nX, nY, noiseColorOffsetFastNoiseTime), -1, 1, -255, 255);
						// set to one channel per frame
						if (rand == 1) 	{
							finalCellR += colorOffset;
							if (finalCellR < 0) finalCellR = 0; else if (finalCellR > 255) finalCellR = 255;
						} else if (rand == 2) {
							finalCellG += colorOffset;
							if (finalCellG < 0) finalCellG = 0; else if (finalCellG > 255) finalCellG = 255;
						} else {
							finalCellB += colorOffset;
							if (finalCellB < 0) finalCellB = 0; else if (finalCellB > 255) finalCellB = 255;
						}
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

	// cutoff at minimum step size and apply
	if (xStep < minStep) xStep = minStep;
	if (yStep < minStep) yStep = minStep;

	if (printDebug) println("setNewGridWithNoise(): xStep: " + xStep + " yStep: " + yStep);

	// determine if step should be the same in both dimensions
	if (toggleSameStepDimsNoise.getNoiseBool(-4, 3)) {
		// apply same step to both dimensions
		yStep = xStep;
		if (printDebug) println("setNewGridWithNoise(): same step");
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
	if (shader == -1) {
		if (printDebug) println("applyShader(): no shader to apply");
		return;
	}

	// apply shader time (like T in noise)
    shaderTime += (shaderTimeNoise.getNoiseRange(.05, .3) * shaderTimeMultiplier) * shaderTimeDivisor;
    shaders.get(shader).set("u_time", shaderTime);

    // set resolution uniform just in case it wasn't set universally or needs update
    shaders.get(shader).set("u_resolution", (float)buffer.width, (float)buffer.height); 

	// set grid dimensions in case shader needs it
	shaders.get(shader).set("u_cells_x", (int)buffer.width/xStep);
	shaders.get(shader).set("u_cells_y", (int)buffer.height/yStep);
    
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
            println("applyShader(): buffer draw error in applyShader: " + e.getMessage());
        }
    }

    // copy the result drawn into buffer into tempBuffer so 'tempBuffer' is ready as the input for the next frame's call to applyShader
    if (buffer != null && tempBuffer != null) {
        tempBuffer.beginDraw();
			// use image() to copy buffer's content onto tempBuffer
			tempBuffer.image(buffer, 0, 0); 
        tempBuffer.endDraw();
    } else {
        println("applyShader(): cannot copy buffer to tempBuffer - one of them is null.");
    }

	// copy shader output to buffer so audioSampling can use it
	buffer.loadPixels();
}

// pick new shader according to activeShaders, returns -1 if no shader can be picked
public Integer pickRandomActiveShader() {
    // check if there are any shaders loaded at all.
    if (shaders.isEmpty()) {
        if (printDebug) println("pickRandomActiveShader(): shaders list empty");
        return -1;
    }

    // check if the activeShaders list itself is empty
    if (activeShaders.isEmpty()) {
        if (printDebug) println("pickRandomActiveShader(): no active shaders");
        return -1;
    }

    ArrayList<Integer> candidateIndices = new ArrayList<Integer>();

    // iterate from 0 up to the number of loaded shaders.
    for (int i = 0; i < shaders.size(); i++) {
		// check if it contains index, add to candidates
        if (activeShaders.contains(i)) {
            candidateIndices.add(i);
        }
    }

    // if there are no candidates
    if (candidateIndices.isEmpty()) {
        if (printDebug) println("pickRandomActiveShader(): no candidate shaders found");
        return -1;
    }

    // randomly pick one index from the list of valid, active candidates
    int randomIndexWithinCandidates = intRandom(0, candidateIndices.size() - 1);
    
	return candidateIndices.get(randomIndexWithinCandidates);
}

// occasionally set another noise type for FastNoiseLite noises
void resetFastNoiseType() {
	fastNoiseType = fastNoiseTypes[intRandom(0, fastNoiseTypes.length -1)];
	noiseColorOffsetFastNoise.SetNoiseType(fastNoiseType);
	fastColorNoiseR.SetNoiseType(fastNoiseType);
	fastColorNoiseG.SetNoiseType(fastNoiseType);
	fastColorNoiseB.SetNoiseType(fastNoiseType);
}

// resize buffer for "zooming into" shader, similar to grid step being higher in manipulatePixelArray()
public void resizeBuffer(float w, float h) {
    int newW = (int)w;
    int newH = (int)h;

    // exit if size hasn't actually changed
    if (buffer != null && buffer.width == newW && buffer.height == newH) {
        return;
    }
    
    if (printDebug) println("resizeBuffer(): resizing buffers to: " + newW + "x" + newH + " with content preservation.");

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
	// if manual switch time
	if (!isRandomSwitchTime) {
		if (!isAutoAutoMode) {
			nextEvent = switchTime + (switchTime * switchTimeMultiplier);
		// if isAutoAutoMode, make nextEvent be dependant on noise, but use switchtime for controlling amount
		} else {
			// println(switchTime * switchTimeMultiplier);
			nextEvent = autoAutoNoise.getNoiseRange(- (switchTime + switchTimeMultiplier) / 2,  switchTime * switchTimeMultiplier);
			if (nextEvent < 0) nextEvent = 0;
		}
	}
	// apply
	if (eventCounter > (nextEvent * frameRate)) {
		chooseEvent(intRandom(0, 5));
		if (maxSwitchTime > minSwitchTime) nextEvent = floatRandom(minSwitchTime + (minSwitchTime * switchTimeMultiplier), maxSwitchTime + (maxSwitchTime * switchTimeMultiplier));
		else nextEvent = 0;
		eventCounter = 0;
	}
}

// switch between which events to fire
void chooseEvent(int event) {
	if (printDebug) println("chooseEvent(): event: " + event);
	audioSamplingMode = intRandom(0, 2);	// choose new audio line orientation
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
				if (printDebug) println("chooseEvent(): applying shader");
				tempBuffer.copy(buffer, 0, 0, buffer.width, buffer.height, 0, 0, tempBuffer.width, tempBuffer.height);
			}
			resizeBuffer(width, height);
		break;
		case 2:
			isNoiseColorRandomOffset = toggleNoiseColorNoise.getNoiseBool(-1, 1);
		break;
		case 3:
			// set new noise type and apply (use toggleNoiseColorNoise because isNoiseColorFastNoiseOffset 
			// only works when isNoiseColorRandomOffset - previously isNoiseColor - is true anyways)
			isNoiseColorFastNoiseOffset = toggleNoiseColorNoise.getNoiseBool(-1, 1);
			resetFastNoiseType();
		break;
		case 4:
			// set new noise type and apply (set isNoiseCOlorFastNoiseOffset to opposite of isFastNoiseColor because only of them can be on)
			isFastNoiseColor = toggleNoiseColorNoise.getNoiseBool(-1, 1);
			isNoiseColorFastNoiseOffset = !isFastNoiseColor;
			resetFastNoiseType();
		break;
		case 5:
			isRandomShaderEachFrame = toggleRandomShaderEachFrameNoise.getNoiseBool(-1, 1.5);
			if (isRandomShaderEachFrame) shaderChoice = pickRandomActiveShader();
		break;
	}
}

// take a screenshot with date and time to special path
void takeScreenshot() {
    // enerate the timestamp and filename
    final String timeStamp = year() + nf(month(), 2) + nf(day(), 2) + "-" + nf(hour(), 2) + nf(minute(), 2) + nf(second(), 2) + "-" + nf(millis() % 1000, 3);
    final String filename = "../rauschen_screens/temp/rauschen-" + timeStamp + ".png";

    // capture current frame to save - always use clean buffer render in displayMode 1
	final PImage frameToSave;
	if (displayMode == 1) {
		screenshotBuffer.beginDraw();
		screenshotBuffer.clear();
		// scale buffer to fill screenshot dimensions
		screenshotBuffer.image(buffer, 0, 0, screenshotWidth, screenshotHeight);
		screenshotBuffer.endDraw();
		frameToSave = screenshotBuffer.get();
	} else {
		frameToSave = get();
	}

    // create and start new thread to actually save for performance
    new Thread(new Runnable() {
        public void run() {
            frameToSave.save(filename);
            if (printDebug) println("takeScreenshot(): screenshot saved: " + filename);
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
			if (printDebug) println("cleanupImageFolder(): deleting old file: " + files[i].getName());
			files[i].delete();
		}
	}
}

// render rudimentary debug info to the main window (rest is handled in control sketch)
void showDebug() {
		translate(80, 0);
			fill(0, 0, 0);
			rect(0, 0, 210, 65);
			fill(255, 255, 255);
			textSize(25);
			text("fps: " + (int) frameRate, 10, 30);
			text("isAutoMode: " + isAutoMode, 10, 55);
		translate(-80, 0);
}

// audio pixels debug line (only show when sound is actually playing)
void showAudioLine() {
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
	// use auto auto mode or not
	if (key == 'y') {
		isAutoAutoMode = !isAutoAutoMode;
	}
	// switch to next mode now!
	if (key == 's') {
		chooseEvent(intRandom(0, 6));
	}
	// stop noise (audio)
	if (key == 'n') {
		if (!isGeneratingSound) toggleSound(true);
		else toggleSound(false);
	}
	// toggle video mapping controls (displayMode 1 only)
	if ((key == 'c' || key == 'C') && displayMode == 1) {
		showVideoMappingControls = !showVideoMappingControls;
	}
	// reset video mapping corners (displayMode 1 only)
	if ((key == 'x' || key == 'X') && displayMode == 1) {
		initVideoMappingCorners();
	}
	// save current setup to JSON (displayMode 1 only)
	if ((key == 'k' || key == 'K') && displayMode == 1) {
		saveSetupToJSON();
	}
	// load setup from JSON (displayMode 1 only)
	if ((key == 'l' || key == 'L') && displayMode == 1) {
		loadSetupFromJSON();
	}
	//stop entire sketch
	if (key == ' ') {
		stopped = !stopped;

		// stop audio as well because otherwise annoying
		if (!isGeneratingSound) toggleSound(true);
		else toggleSound(false);
	}
	
	// change window size
	if (key == '+') {
		plusKeyDown = true;
	} else if (key == '-') {
		minusKeyDown = true;
	}

	// move window around
	if (key == CODED) {
		if (keyCode == UP) {
			upArrowDown = true;
		} else if (keyCode == DOWN) {
			downArrowDown = true;
		} else if (keyCode == LEFT) {
			leftArrowDown = true;
		} else if (keyCode == RIGHT) {
			rightArrowDown = true;
		}
  	}
}

// for moving window when there is title bar
void keyReleased() { 
	// change window size
	if (key == '+') {
		plusKeyDown = false;
	} else if (key == '-') {
		minusKeyDown = false;
	}

	// move window around
	if (key == CODED) {
		if (keyCode == UP) {
			upArrowDown = false;
		} else if (keyCode == DOWN) {
			downArrowDown = false;
		} else if (keyCode == LEFT) {
			leftArrowDown = false;
		} else if (keyCode == RIGHT) {
			rightArrowDown = false;
		} else if (key == '+') {
			plusKeyDown = false;
			println(plusKeyDown);
		} else if (key == '-') {
			minusKeyDown = false;
		}
	}
}

// move window according to arrow key states
void moveWindow() {
	if (newtWindow != null && edtUtil != null) {
		int deltaX = 0;
		int deltaY = 0;
		final int moveAmount = 1; // pixels to move per frame if key is held

		if (upArrowDown) {
			deltaY -= moveAmount;
		}
		if (downArrowDown) {
			deltaY += moveAmount;
		}
		if (leftArrowDown) {
			deltaX -= moveAmount;
		}
		if (rightArrowDown) {
			deltaX += moveAmount;
		}

		// if there's any movement to apply
		if (deltaX != 0 || deltaY != 0) {
			// get current position (reading is safe from any thread)
			final int currentX = newtWindow.getX();
			final int currentY = newtWindow.getY();
			
			final int finalNewX = currentX + deltaX;
			final int finalNewY = currentY + deltaY;

			// dispatch the setPosition call to the NEWT EDT (non-blocking)
			edtUtil.invoke(false, new Runnable() {
				@Override
				public void run() {
					try { 
						newtWindow.setPosition(finalNewX, finalNewY);
					} catch (Throwable t) {
						t.printStackTrace();
					}
				}
			});
		}
	}
}

// move window according to arrow key states
void resizeWindow() {
	if (newtWindow != null && edtUtil != null) {
		int deltaSize = 0;
		final int moveAmount = 1; // pixels to move per frame if key is held

		if (plusKeyDown) {
			deltaSize += moveAmount;
		}
		if (minusKeyDown) {
			deltaSize -= moveAmount;
		}

		// if there's any transform to apply
		if (deltaSize != 0) {
			// get current size (reading is safe from any thread)
			final int currentSize = newtWindow.getWidth();
			final int finalNewSize = currentSize + deltaSize;

			// dispatch the setPosition call to the NEWT EDT (non-blocking)
			edtUtil.invoke(false, new Runnable() {
				@Override
				public void run() {
					try {
						newtWindow.setSize(finalNewSize, finalNewSize);
					} catch (Throwable t) {
						t.printStackTrace();
					}
				}
			});
		}
	}
}

// remove title bar of window for faux full screen
void removeTitleBar() {
	// get both surfaces
	if (surface instanceof PSurfaceJOGL) {
		PSurfaceJOGL joglSurface = (PSurfaceJOGL) surface;
		Object nativeObject = joglSurface.getNative();
		if (nativeObject instanceof Window) {
			// assign to the GLOBAL newtWindow variable
			newtWindow = (Window) nativeObject;
			if (newtWindow.getScreen() != null && newtWindow.getScreen().getDisplay() != null) {
				// assign to the GLOBAL edtUtil variable
				edtUtil = newtWindow.getScreen().getDisplay().getEDTUtil();
				if (edtUtil == null) {
				newtWindow = null; // invalidate newtWindow if edtUtil is not available
				}
			} else {
				newtWindow = null; // invalidate newtWindow
			}
		}
	}

	// call title bar removal logic if both are not null
	if (newtWindow != null && edtUtil != null) {
		edtUtil.invoke(false, new Runnable() { 
			@Override
			public void run() {
				if (newtWindow.isVisible()) { 
					newtWindow.setVisible(false);
					newtWindow.setUndecorated(true);
					newtWindow.setVisible(true);
				} else {
					newtWindow.setUndecorated(true);
				}
			}
		});
	}
}

// initialize video mapping corners to default positions (displayMode 1 only)
void initVideoMappingCorners() {
	if (displayMode == 1) {
		// for displayMode 1, corners are centered in window
		int offsetX = (windowWidth - width) / 2;
		int offsetY = (windowHeight - height) / 2;
		corners[0] = new PVector(offsetX, offsetY); // top-left
		corners[1] = new PVector(offsetX + width, offsetY); // top-right
		corners[2] = new PVector(offsetX + width, offsetY + height); // bottom-right
		corners[3] = new PVector(offsetX, offsetY + height); // bottom-left
	}
	// displayMode 0 doesn't use video mapping, so no corners are initialized
}

// draw video mapping control handles
void drawVideoMappingControls() {
	if (corners[0] == null) return; // not initialized yet

	for (int i = 0; i < 4; i++) {
		// draw handle circle - semi-transparent
		if (draggedCorner == i) {
			fill(255, 0, 0, 80); // red when dragged, semi-transparent
			stroke(255, 0, 0); // red outline when dragged
		} else {
			fill(255, 255, 0, 80); // yellow normally, semi-transparent
			stroke(255, 255, 0); // yellow outline normally
		}
		strokeWeight(2);
		ellipse(corners[i].x, corners[i].y, handleSize, handleSize);

		// draw number - opaque
		fill(255);
		textAlign(CENTER, CENTER);
		textSize(12);
		text(str(i + 1), corners[i].x, corners[i].y);

		// reset stroke
		noStroke();
	}
}

// draw the mapped buffer using the corner positions with perspective-correct subdivision
void drawMappedBuffer() {
	if (corners[0] == null) return; // not initialized yet

	// create a subdivided mesh for better perspective approximation
	// the more subdivisions, the more accurate the perspective transformation
	noStroke(); // disable stroke to avoid black lines between triangles
	textureMode(NORMAL); // use normalized texture coordinates (0.0 to 1.0)

	for (int row = 0; row < meshResolution; row++) {
		beginShape(TRIANGLE_STRIP);
		texture(buffer);

		for (int col = 0; col <= meshResolution; col++) {
			// calculate normalized coordinates in the grid (0.0 to 1.0)
			float u1 = (float) col / meshResolution;
			float v1 = (float) row / meshResolution;
			float u2 = (float) col / meshResolution;
			float v2 = (float) (row + 1) / meshResolution;

			// interpolate position on the destination quadrilateral using bilinear interpolation
			// this creates the perspective effect when the quad is not rectangular
			PVector pos1 = bilinearInterpolation(corners, u1, v1);
			PVector pos2 = bilinearInterpolation(corners, u2, v2);

			// draw vertices with texture coordinates
			vertex(pos1.x, pos1.y, u1, v1);
			vertex(pos2.x, pos2.y, u2, v2);
		}

		endShape();
	}

	textureMode(IMAGE); // reset to default
}

// bilinear interpolation for mapping normalized (u,v) coordinates to the quadrilateral
PVector bilinearInterpolation(PVector[] quad, float u, float v) {
	// quad[0] = top-left, quad[1] = top-right, quad[2] = bottom-right, quad[3] = bottom-left
	// interpolate along top edge
	PVector top = PVector.lerp(quad[0], quad[1], u);
	// interpolate along bottom edge
	PVector bottom = PVector.lerp(quad[3], quad[2], u);
	// interpolate between top and bottom
	return PVector.lerp(top, bottom, v);
}

// mouse events for dragging corners (displayMode 1 only)
void mousePressed() {
	if (showVideoMappingControls && corners[0] != null && displayMode == 1) {
		// check if mouse is over any corner handle
		for (int i = 0; i < 4; i++) {
			float distance = dist(mouseX, mouseY, corners[i].x, corners[i].y);
			if (distance < handleSize / 2) {
				draggedCorner = i;
				break;
			}
		}
	}
}

void mouseDragged() {
	if (draggedCorner != -1 && displayMode == 1) {
		corners[draggedCorner].x = mouseX;
		corners[draggedCorner].y = mouseY;
	}
}

void mouseReleased() {
	draggedCorner = -1;
}

// save current window position, dimensions and corner positions to JSON
void saveSetupToJSON() {
	JSONObject setup = new JSONObject();

	// window information
	JSONObject window = new JSONObject();
	if (displayMode == 1 && newtWindow != null) {
		window.setInt("x", newtWindow.getX());
		window.setInt("y", newtWindow.getY());
		window.setInt("width", newtWindow.getWidth());
		window.setInt("height", newtWindow.getHeight());
	} else {
		// for displayMode 0, use surface position and size
		window.setInt("x", 0); // Processing doesn't easily expose window position
		window.setInt("y", 40);
		window.setInt("width", width);
		window.setInt("height", height);
	}
	setup.setJSONObject("window", window);

	// corner positions
	JSONArray cornersArray = new JSONArray();
	if (corners[0] != null) {
		for (int i = 0; i < 4; i++) {
			JSONObject corner = new JSONObject();
			corner.setFloat("x", corners[i].x);
			corner.setFloat("y", corners[i].y);
			cornersArray.setJSONObject(i, corner);
		}
	}
	setup.setJSONArray("corners", cornersArray);

	// save to file
	saveJSONObject(setup, "windowSetup.json");
	if (printDebug) println("saveSetupToJSON(): setup saved to dwindowSetup.json");
}

// load window position, dimensions and corner positions from JSON
void loadSetupFromJSON() {
	JSONObject setup = loadJSONObject("windowSetup.json");
	if (setup == null) {
		if (printDebug) println("loadSetupFromJSON(): no windowSetup.json found");
		return;
	}

	try {
		// load window position and dimensions (only for displayMode 1)
		if (setup.hasKey("window") && displayMode == 1 && newtWindow != null && edtUtil != null) {
			JSONObject window = setup.getJSONObject("window");
			final int newX = window.getInt("x");
			final int newY = window.getInt("y");
			final int newWidth = window.getInt("width");
			final int newHeight = window.getInt("height");

			// update window dimensions
			windowWidth = newWidth;
			windowHeight = newHeight;

			// dispatch window changes to NEWT EDT
			edtUtil.invoke(false, new Runnable() {
				@Override
				public void run() {
					try {
						newtWindow.setPosition(newX, newY);
						newtWindow.setSize(newWidth, newHeight);
					} catch (Throwable t) {
						t.printStackTrace();
					}
				}
			});
		}

		// load corner positions
		if (setup.hasKey("corners")) {
			JSONArray cornersArray = setup.getJSONArray("corners");
			if (cornersArray.size() >= 4) {
				for (int i = 0; i < 4; i++) {
					JSONObject corner = cornersArray.getJSONObject(i);
					corners[i] = new PVector(corner.getFloat("x"), corner.getFloat("y"));
				}
				if (printDebug) println("loadSetupFromJSON(): corners loaded");
			}
		}

		if (printDebug) println("loadSetupFromJSON(): setup loaded from data/setup.json");
	} catch (Exception e) {
		if (printDebug) println("loadSetupFromJSON(): error loading setup: " + e.getMessage());
	}
}