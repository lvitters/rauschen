int width = 800;
int height = 800;
int maxStepMultiplier = 4;
int resStep = 8;

//noises
NoiseObject resolution;
NoiseObject xGridStep;
NoiseObject yGridStep;
NoiseObject toggleGridStep;
NoiseObject toggleNoiseColor;
NoiseObject noiseColorSpeed;

// NoiseObject for pixels' colors
ArrayList<NoiseObject[]> colors = new ArrayList<NoiseObject[]>();

// Timed events
int maxSwitchTime = 5;
int nextResEvent = 5;       // init in x seconds
int resEventCounter = 0;

// Record for graphs that get reset
float resRecord;

public void settings() {
	size(width, height);
	pixelDensity(1);
}

public void setup() {
	// can't go in settings for some reason
	frameRate(60);

	// init NoiseObjects with starting value and increment
	resolution = new NoiseObject(random(1000), 1);
	xGridStep = new NoiseObject(random(1000), 0.002);
	yGridStep = new NoiseObject(random(1000), 0.002);
	toggleGridStep = new NoiseObject(random(1000), 0.001);
	toggleNoiseColor = new NoiseObject(random(1000), 0.0001);
	noiseColorSpeed = new NoiseObject(random(1000), 1);

	// get pixel array for manipulation
	loadPixels();

	// create NoiseObject for every pixel's color value and store in colors ArrayList
	for (int c = 0; c < pixels.length; c++) {
		NoiseObject r = new NoiseObject(random(100), 0.1);
		NoiseObject g = new NoiseObject(random(100), 0.1);
		NoiseObject b = new NoiseObject(random(100), 0.1);
		colors.add(new NoiseObject[]{r, g, b});
	}
}

public void draw() {
	// do this first because it affects the pixels array manipulation
	timedEvents();

	// don't always refresh the background
	if (toggleGridStep.noiseBool(-5, 10)) {
		refreshPixelArray();
	}

	// get grid lines
	PVector gridLines = computeGridLines();

	// manipulate pixel array
	for (int x = 0; x < width - resStep; x += (int)gridLines.x) {
		for (int y = 0; y < height - resStep; y += (int)gridLines.y) {
			// get color values at random
			color c = color((int)random(255), (int)random(255), (int)random(255));
			// override color values according to noise (same for each pixel in step)
			if ((!toggleNoiseColor.noiseBool(-5, 10))) {
				// get index in array from coordinates and step and apply determined color to pixels array
				for (int s = 0; s < resStep; s++) {
					int index = (y + resStep) * width + (x + resStep);
					// change noise color speed independently for r, g, b
					for (int a = 0; a < 3; a++) {
						colors.get(index)[a].changeInc(noiseColorSpeed.noiseVariableRange(0.00001f, 0.01f, 0.01f, 0.1f));
						c = (int)colors.get(index)[a].noiseRange(0, 255);
					}
				}
			}
			// get index in array from coordinates and step and apply determined color to pixels array
			for (int s = 0; s < resStep; s++) {
				int index = (y + resStep) * width + (x + resStep);
				pixels[index] = c;
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
	if (range > cutoff) return range;
	else return cutoff;
}

// sometimes things should happen at random intervals instead
void timedEvents() {
	// sometimes switch to a new resolution step
	resEventCounter++;
	if (resEventCounter > (nextResEvent * 60)) {
		setRandomResolutionStep();
		nextResEvent = (int)random(5, maxSwitchTime);
		resEventCounter = 0;
	}
}

// set canvas and sketch to a new resolution
void setRandomResolutionStep() {
	// get new res close to old res with noise
	int stepMultiplier = (int)resolution.noiseRange(-2, maxStepMultiplier);

	println(stepMultiplier);

	// apply to canvas dimensions
	if (stepMultiplier < 1) stepMultiplier = 1;
	resStep *= stepMultiplier;

	println(resStep);
}