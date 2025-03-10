import java.util.concurrent.ThreadLocalRandom;

// main window
int width = 1000;
int height = 1000;

public void settings() {
	size(width, height, OPENGL);
	pixelDensity(1);
}

public void setup() {
	size(width, height, OPENGL);
	frameRate(120);

	loadPixels();
}

public void draw() { 
	pushMatrix();
		for (int x = 0; x < width; x++) {
			for (int y = 0; y < height; y++) {

				float r = intRandom(50, 255);
				float g = intRandom(50, 255);
				float b = intRandom(50, 255);

				pixels[y * width + x] = color(r, g, b);
			}
		}
		updatePixels();
	popMatrix();

	// fps 
	fill(255, 0, 0);
	textSize(25);
	text("fps: "+(int) frameRate, 50, 50);
}