import java.util.concurrent.ThreadLocalRandom;

// Window size
int width = 1000;
int height = 1000;

float tR = 0; // Time variable for animation
float tG = 0; // Time variable for animation
float tB = 0; // Time variable for animation

void settings() {
    size(width, height, OPENGL);
    pixelDensity(1);
}

void setup() {
    frameRate(120);
    loadPixels();
}

void draw() { 
    for (int x = 0; x < width; x++) {
        for (int y = 0; y < height; y++) {

            // Generate a scattered seed (avoids diagonal/horizontal banding)
            float seed = sin(x * 0.1) * cos(y * 0.1) * 1000; 

            // Generate smooth colors using evolving 1D noise
            float r = noise(tR + seed) * 255;
            float g = noise(tG + seed) * 255;
            float b = noise(tB + seed) * 255;

            pixels[y * width + x] = color(r, g, b);
        }
    }
    updatePixels();

    tR += random(.01, 1); // Controls animation speed
	tG += random(.01, 1); // Controls animation speed
	tB += random(.01, 1); // Controls animation speed

    // Display FPS
    fill(255, 0, 0);
    textSize(25);
    text("fps: " + (int) frameRate, 50, 50);
}


