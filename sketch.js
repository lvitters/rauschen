//res of canvas, change size in index.html
let canvasWidth = 400;
let canvasHeight = 400;

let resMutiplierT = 0;

function setup() {
	createCanvas(canvasWidth, canvasHeight);
	frameRate(30);

	//get pixel array for manipulation
	loadPixels();
}

function draw() {

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

//get noise
function noisyResMultiplier() {
	resMutiplierT += .1;
	return noise(resMutiplierT);
}