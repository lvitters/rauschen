// Res of canvas, change size in index.html
int minWidth = 2;
int maxWidth = 800;
int minHeight = 2;
int maxHeight = 800;
int canvasWidth = maxWidth;
int canvasHeight = maxHeight;
float newWidth;
float newHeight;

// Rauschen
NoiseObject resolution;
NoiseObject xGridStep;
NoiseObject yGridStep;
NoiseObject toggleGridStep;
NoiseObject toggleNoiseColor;
NoiseObject noiseColorSpeed;

// NoiseObject for pixels' colors
ArrayList<NoiseObject> colors = new ArrayList<NoiseObject>();

// Timed events
int maxSwitchTime = 10;
int nextResEvent = 5;       // init in x seconds
int resEventCounter = 0;

// Record for graphs that get reset
float resRecord;

public void settings() {
	size(canvasWidth, canvasHeight);
	pixelDensity(1);
}

public void setup() {
	// can't go in settings for some reason
	frameRate(60);

	// init NoiseObjects with starting value and increment
	resolution = new NoiseObject(random(1000), 0.001);
	xGridStep = new NoiseObject(random(1000), 0.002);
	yGridStep = new NoiseObject(random(1000), 0.002);
	toggleGridStep = new NoiseObject(random(1000), 0.001);
	toggleNoiseColor = new NoiseObject(random(1000), 0.0001);
	noiseColorSpeed = new NoiseObject(random(1000), 1);

	// get pixel array for manipulation
	loadPixels();

	// create NoiseObject for every pixel's color value
	for (int c = 0; c < pixels.length; c++) {
		colors.add(new NoiseObject(random(100), 0.1));
	}
}

public void draw() {
	// do that here because it might change the resolution
	//timedEvents();

	// don't always refresh the background
	if (toggleGridStep.noiseBool(-5, 10)) {
		refreshPixelArray();
	}

	// get grid lines
	PVector gridLines = computeGridLines();

	// manipulate pixel array
	for (int x = 0; x < canvasWidth; x += (int)gridLines.x) {
		for (int y = 0; y < canvasHeight; y += (int)gridLines.y) {
			// get index in array from coordinates
			int index = (x + y * canvasWidth);
			// each pixel is of the color datatype
			// set values at random
			if (toggleNoiseColor.noiseBool(-10, 5) || canvasWidth > maxWidth / 2) {
				color c = color((int)random(255), (int)random(255), (int)random(255));
				pixels[index] = c;
			// set values according to noise
			} else {
				// change noise color speed independently
				colors.get(index).changeInc(noiseColorSpeed.noiseVariableRange(0.00001f, 0.01f, 0.01f, 0.1f));
				pixels[index] = (int)colors.get(index).noiseRange(0, 255);
			}
		}
	}

	// write to pixels array
	updatePixels();
}

// refresh the pixel array with all black pixels, because background() doesn't do that
void refreshPixelArray() {
	for (int p = 0; p < pixels.length; p++) {
		pixels[p] = 0;
	}
}

// Compute grid lines to apply to pixel array manipulation
PVector computeGridLines() {
	float x = floor(cutoff(xGridStep.noiseVariableRange(-10, -20, 1, 20), 1));
	float y = floor(cutoff(yGridStep.noiseVariableRange(-10, -20, 1, 20), 1));
	return new PVector(x, y);      // Return as tuple
}

// take range and cut at cutoff; useful when a value needs to stick towards the cutoff but should still change sometimes
float cutoff(float range, float cutoff) {
	return range > cutoff ? range : cutoff;
}

// // sometimes things should happen at random intervals instead
// void timedEvents() {
// 	// sometimes switch to a new random resolution
// 	resEventCounter++;
// 	if (resEventCounter > (nextResEvent * 60)) {
// 		setRandomResolution();
// 		nextResEvent = (int)random(5, maxSwitchTime);
// 		resEventCounter = 0;
// 	}
// }

// // set canvas and sketch to a new resolution
// void setRandomResolution() {
// 	// get new res close to old res with noise
// 	newWidth = resolution.noiseRange(-50, maxWidth);
// 	newHeight = resolution.noiseRange(-50, maxHeight);

// 	resRecord = resolution.value;

// 	// apply to canvas dimensions
// 	canvasWidth = floor(cutoff(newWidth, minWidth));
// 	canvasHeight = floor(cutoff(newHeight, minHeight));

// 	//reset();
// }