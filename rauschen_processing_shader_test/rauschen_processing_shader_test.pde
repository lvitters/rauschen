import java.util.concurrent.ThreadLocalRandom;

// Window size
int width = 1000;
int height = 1000;

PShader noiseShader;

float t = 0;

void setup() {
    size(1000, 1000, P2D);
    pixelDensity(1);
	noiseShader = loadShader("noiseFrag.glsl");
	noiseShader.set("u_resolution", float(width), float(height));
}

void draw() { 
    t += .001;
    noiseShader.set("u_time", t); // pass time to shader
    shader(noiseShader); // apply shader
    rect(0, 0, width, height); // render a full-screen rectangle

	// Disable shader before drawing text
    resetShader();

    // display FPS
    fill(255, 0, 0);
    textSize(25);
    text("fps: " + (int) frameRate, 50, 50);
}


