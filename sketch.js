//res of canvas, change size in index.html
let minWidth = 2;
let minHeight = 2;
let maxWidth = 100;
let maxHeight = 100;
let canvasWidth;
let canvasHeight;
let resMultiplier;

//only show every x column and y row
let xGridStep;
let yGridStep;
let rangeGridStep;

//noiseObject for pixels' colors
let colors = [];

//effect toggles
let toggleGridStep;
let toggleNoiseColor;

function setup() {
	createCanvas(maxWidth, maxHeight);
	frameRate(30);
	pixelDensity(1);

	//init NoiseObjects with starting value and increment
	resMultiplier = new NoiseObject(Math.random() * 100, .01);
	xGridStep = new NoiseObject(Math.random() * 100, .002);
	yGridStep = new NoiseObject(Math.random() * 100, .002);
	rangeGridStep = new NoiseObject(Math.random() * 100, .001);
	toggleGridStep = new NoiseObject(Math.random() * 100, .001);
	toggleNoiseColor = new NoiseObject(Math.random() * 100, .001);

	//get pixel array for manipulation
	loadPixels();

	//create NoiseObject for every pixels color value
	for(let c = 0; c < pixels.length; c++) {
		colors[c] = new NoiseObject(Math.random() * 100, .1);
	}
}

function draw() {
	translate(width/2, height/2);

	let noiseWidth = floor(resMultiplier.noiseRange(minWidth, maxWidth));
	canvasWidth = noiseWidth;
	canvasHeight = noiseWidth;
	resizeCanvas(noiseWidth, noiseWidth);

	translate(width/2, height/2);

	//don't always refresh the background
	if (toggleGridStep.noiseBool(-5, 10))	refreshPixelArray();

	//get gridLines
	let gridLines = computeGridLines();

	//manipulate pixel array
	for (let x = 0; x < canvasWidth; x += gridLines.x) {
		for (let y = 0; y < canvasHeight; y += gridLines.y) {
			//get index in array from coordinates
			let index = (x + y * canvasWidth) * 4;
			//one pixel has 4 spots in the array: r, g, b, a
			for (let i = 0; i < 4; i++) {
				//set values at random
				if (toggleNoiseColor.noiseBool(-4, 5)) {
					pixels[index + i] = Math.random() * 255;
				//set values according to noise
				} else {
					pixels[index + i] = colors[index + i].noiseRange(0, 255);
				}
			}
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

//take range and cut at cutoff; useful when a value needs to stick towards the cutoff, but should still change sometimes
function stickTo(range, cutoff) {
	if (range > cutoff) return range;
	else return cutoff;
}