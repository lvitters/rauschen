//res of canvas, change size in index.html
let canvasWidth = 400;
let canvasHeight = 400;

let gridLines;
let gridLinesRange;

function setup() {
	createCanvas(canvasWidth, canvasHeight);
	frameRate(30);
	pixelDensity(1);

	//init NoiseObjects
	gridLines = new NoiseObject(Math.random() * 100, .1);
	gridLinesRange = new NoiseObject(Math.random() * 100, .1);

	//get pixel array for manipulation
	loadPixels();
}

function draw() {
	background(0);

	//get gridLines
	let gridLines = computeGridLines();
	console.log(gridLines);

	//manipulate pixel array
	for (let x = 0; x < canvasWidth; x += gridLines) {
		for (let y = 0; y < canvasHeight; y += gridLines) {
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

//compute grid lines to apply to pixel array manipulation, weighted
function computeGridLines() {
	let x = floor(gridLines.getMappedNoise(
		gridLinesRange.getMappedNoise(-5, -10), 
		gridLinesRange.getMappedNoise(1, 20)
	));
	if (x < 1) x = 1;	//don't go under one
	else if (x > 1) x *= 2;		//keep number even
	return x;
}