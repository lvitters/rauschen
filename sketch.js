//res of canvas, change size in index.html
let canvasWidth = 400;
let canvasHeight = 400;

let xGridStep;
let yGridStep;
let rangeGridStep;

function setup() {
	createCanvas(canvasWidth, canvasHeight);
	frameRate(30);
	pixelDensity(1);

	//init NoiseObjects
	xGridStep = new NoiseObject(Math.random() * 100, .01);
	yGridStep = new NoiseObject(Math.random() * 100, .01);
	rangeGridStep = new NoiseObject(Math.random() * 100, .01);

	//get pixel array for manipulation
	loadPixels();
}

function draw() {
	//background(0);	//not needed because the pixel array itself gets refreshed

	refreshPixelArray();	//TODO: don't always do this

	//get gridLines
	let gridLines = computeGridLines();

	//manipulate pixel array
	for (let x = 0; x < canvasWidth; x += gridLines.x) {
		for (let y = 0; y < canvasHeight; y += gridLines.y) {
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

//refresh the pixel array with all black pixels, because background() doesn't do that
function refreshPixelArray() {
	for(let p = 0; p < pixels.length; p++) {
		pixels[p] = 0;
	}
}

//compute grid lines to apply to pixel array manipulation, weighted
function computeGridLines() {
	let x = floor(xGridStep.getMappedNoise(
		rangeGridStep.getMappedNoise(-10, -20), 
		rangeGridStep.getMappedNoise(1, 40)
	));
	if (x < 1) x = 1;	//cap over 0
	let y = floor(yGridStep.getMappedNoise(
		rangeGridStep.getMappedNoise(-10, -20), 
		rangeGridStep.getMappedNoise(1, 40)
	));
	if (y < 1) y = 1;	//cap over 0
	return {x, y};
}