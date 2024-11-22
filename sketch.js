//res of canvas, change size in index.html
let canvasWidth = 400;
let canvasHeight = 400;

//only show every x column and y row
let xGridStep;
let yGridStep;
let rangeGridStep;

//effect toggles
let toggleGridStep;

function setup() {
	createCanvas(canvasWidth, canvasHeight);
	frameRate(30);
	pixelDensity(1);

	//init NoiseObjects with starting value and increment
	xGridStep = new NoiseObject(Math.random() * 100, .01);
	yGridStep = new NoiseObject(Math.random() * 100, .01);
	rangeGridStep = new NoiseObject(Math.random() * 100, .01);
	toggleGridStep = new NoiseObject(Math.random() * 100, .01);

	//get pixel array for manipulation
	loadPixels();
}

function draw() {
	//background(0);	//not needed because the pixel array itself gets refreshed

	//don't always refresh the background
	if (toggleGridStep.getBoolNoise(-3, 10)) {
		refreshPixelArray();
	}

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
	let x = floor(xGridStep.getRangedNoise(
		rangeGridStep.getRangedNoise(-10, -20), 
		rangeGridStep.getRangedNoise(1, 40)
	));
	if (x < 1) x = 1;	//cap over 0
	let y = floor(yGridStep.getRangedNoise(
		rangeGridStep.getRangedNoise(-10, -20), 
		rangeGridStep.getRangedNoise(1, 40)
	));
	if (y < 1) y = 1;	//cap over 0
	return {x, y};
}