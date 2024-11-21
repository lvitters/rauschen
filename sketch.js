let canvasWidth = 800;
let canvasHeight = 800;

function setup() {
	createCanvas(canvasWidth, canvasHeight);
	frameRate(30);
}

function draw() {
	//get pixel array for manipulation
	loadPixels();

		//every pixel has 4 values, and 4 indices in the pixels array
		for  (let i = 0; i < pixels.length; i += 4) {
			pixels[i] = Math.random() * 255;		//red
			pixels[i+1] = Math.random() * 255;		//green
			pixels[i+2] = Math.random() * 255;		//blue
			pixels[i+3] = Math.random() * 255;		//alpha
		}

	//write to pixels array
	updatePixels();
}