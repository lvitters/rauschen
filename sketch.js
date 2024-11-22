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
	xGridStep = new NoiseObject(Math.random() * 100, .002);
	yGridStep = new NoiseObject(Math.random() * 100, .002);
	rangeGridStep = new NoiseObject(Math.random() * 100, .001);
	toggleGridStep = new NoiseObject(Math.random() * 100, .001);

	//get pixel array for manipulation
	loadPixels();
}

function draw() {

	//don't always refresh the background
	if (toggleGridStep.noiseBool(-10, 10))	refreshPixelArray();

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

//compute grid lines to apply to pixel array manipulation
function computeGridLines() {
	let x = floor(stickTo(xGridStep.noiseVariableRange(-10, -20, 1, 40), 1));
	let y = floor(stickTo(yGridStep.noiseVariableRange(-10, -20, 1, 40), 1));
	return {x, y};		//return as tuple
}

//take range and cut at cutoff; useful when a value needs to stick at the cutoff, but should still change sometimes
function stickTo(range, cutoff) {
	if (range > cutoff) return range;
	else return cutoff;
}