int width = 1000;
int height = 1000;
int maxStepMultiplier = 10;
int resStep = 1;

color c;
int r, g, b;

//noises
NoiseObject resolution;

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

	c = color((int)random(255), (int)random(255), (int)random(255));

	// init NoiseObjects with starting value and increment
	resolution = new NoiseObject(random(1000), 1);

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
	// refresh background
	background(0);

	// do this first because it affects the pixels array manipulation
	timedEvents();

	// manipulate pixel array
	for (int x = 0; x < width; x += resStep) {
		for (int y = 0; y < height; y += resStep) {
			// get color values at random
			c = color((int)random(255), (int)random(255), (int)random(255));
			// get index in array from coordinates and step and apply determined color to pixels array
			for (int dx = 0; dx < resStep; dx++) {
				for (int dy = 0; dy < resStep; dy++) {
					int px = x + dx;
					int py = y + dy;
					if (px < width && py < height) {
						int index = py * width + px;
						//println(index);
						pixels[index] = c;
					}
				}
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
	// reset
	resStep = 1;

	// get new step close to old step with noise
	int stepMultiplier = (int)resolution.noiseRange(0, maxStepMultiplier);

	println(stepMultiplier);

	// apply
	if (stepMultiplier < 1) stepMultiplier = 1;
	resStep *= stepMultiplier;

	println(resStep);
}