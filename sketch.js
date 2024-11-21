//res of canvas, change size in index.html
let canvasWidth = 400;
let canvasHeight = 400;

let resMultiplierX;
let resMultiplierY;

function setup() {
	createCanvas(canvasWidth, canvasHeight);
	frameRate(30);
	pixelDensity(1);

	resMultiplierX = new NoiseObject(Math.random() * 100, .1);
	resMultiplierY = new NoiseObject(Math.random() * 100, .1);

	//get pixel array for manipulation
	loadPixels();
}

function draw() {

	computeNoiseObjects();

	//manipulate pixel array
	for (let x = 0; x < canvasWidth; x += floor(map(resMultiplierX.getNoise(), 0, 1, 1, 16))) {
		for (let y = 0; y < canvasHeight; y += floor(map(resMultiplierY.getNoise(), 0, 1, 1, 16))) {
			//get index in array from coordinates
			let index = (x + y * canvasWidth) * 4;
			pixels[index + 0] = Math.random() * 255;		//red
			pixels[index + 1] = Math.random() * 255;		//green
			pixels[index + 2] = Math.random() * 255;		//blue
			pixels[index + 3] = Math.random() * 255;		//alpha
		}
	}

	//write to pixels array
	updatePixels();
}

//compute noise objects
function computeNoiseObjects() {
	resMultiplierX.compute();
	resMultiplierY.compute();
}