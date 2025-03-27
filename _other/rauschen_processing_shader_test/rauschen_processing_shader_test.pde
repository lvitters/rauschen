import java.util.concurrent.ThreadLocalRandom;

// Window size
float width = 1000;
float height = 1000;

// timed events
int minSwitchTime = 1;
int maxSwitchTime = 10;
int nextResEvent = 1;		// init in X seconds
int resEventCounter = 0;

PGraphics resBuffer;
PShader noiseShader;

float t = random(100);
float tt = random(100);
float ttt = random(100);

void setup() {
    size(1000, 1000, P2D);
    pixelDensity(1);

	resBuffer = createGraphics((int)width/4, (int)height/4, P2D);

	noiseShader = loadShader("noiseFrag.glsl");
	noiseShader.set("u_resolution", width, height);
}

void draw() { 
	ttt += random(.001, .01);
	tt += random(.001, .01);
    t += noise(tt) * .1;
    noiseShader.set("u_time", t); // pass time to shader

	resBuffer.beginDraw();
		resBuffer.shader(noiseShader); // apply shader
		resBuffer.rect(0, 0, width, height); // render a full-screen rectangle
	resBuffer.endDraw();

	// Disable shader before drawing text
    resetShader();

	//timedEvents();

    // display FPS
    fill(255, 0, 0);
    textSize(25);
    text("fps: " + (int) frameRate, 50, 50);
}

void resizeBuffer(float w, float h) {
	resBuffer.dispose();
	resBuffer = createGraphics((int)w, (int)h, P2D);
}

// sometimes things should happen at random intervals instead
void timedEvents() {
	// sometimes switch to a new resolution step
	resEventCounter++;
	if (resEventCounter > (nextResEvent * 60)) {
		resizeBuffer(random(width/2), random(height/2));
		nextResEvent = (int)random(minSwitchTime, maxSwitchTime);
		resEventCounter = 0;
	}
}
