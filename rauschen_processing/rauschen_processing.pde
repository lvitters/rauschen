int width = 1000;
int height = 1000;
int maxStepMultiplier = 20;
int resStep = 1;

color c, nc;
int r, g, b;

//noises
NoiseObject resolution;

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
	resolution = new NoiseObject(random(100), 1);
	
	// get pixel array for manipulation
	loadPixels();
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
			// determine indices for pixels array from coordinates and step
			for (int dx = 0; dx < resStep; dx++) {
				for (int dy = 0; dy < resStep; dy++) {
					// get offset
					int px = x + dx;
					int py = y + dy;
					//check boundaries (edges won't have neighboring pixels)
					if (px < width && py < height) {
						// get index
						int index = py * width + px;
						// apply respective color to pixels array
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

	// cutoff over one and apply
	if (stepMultiplier < 1) stepMultiplier = 1;
	resStep *= stepMultiplier;
}