//res of canvas, change size in index.html
let minWidth = 2;
let maxWidth = 100;
let minHeight = 2;
let maxHeight = 100;
let canvasWidth = maxWidth;
let canvasHeight = maxHeight;
let newWidth;
let newHeight;

//rauschen
let resolution;
let rauschenSpeed;
let xGridStep;
let yGridStep;
let rangeGridStep;
let toggleGridStep;
let toggleNoiseColor;

//noiseObject for pixels' colors
let colors = [];

//timedEvents
const maxSwitchTime = 10;
let nextResEvent = 5; 		//init in x seconds
let resEventCounter = 0;

function setup() {
	reset();
}

//setup everything in here so that it can be called again at will
function reset() {
	createCanvas(canvasWidth, canvasHeight);
	frameRate(60);
	pixelDensity(1);

	//init NoiseObjects with starting value and increment
	resolution = new NoiseObject(Math.random() * 100, .001);
	rauschenSpeed = new NoiseObject(Math.random() * 100, .001);
	xGridStep = new NoiseObject(Math.random() * 100, .002);
	yGridStep = new NoiseObject(Math.random() * 100, .002);
	rangeGridStep = new NoiseObject(Math.random() * 100, .001);
	toggleGridStep = new NoiseObject(Math.random() * 100, .001);
	toggleNoiseColor = new NoiseObject(Math.random() * 100, .0001);

	//get pixel array for manipulation
	loadPixels();

	//create NoiseObject for every pixels color value
	for(let c = 0; c < pixels.length; c++) {
		colors[c] = new NoiseObject(Math.random() * 100, .1);
	}
}

function draw() {
	//draw every x frames
	let x = cutoff(floor(rauschenSpeed.noiseRange(-6, 4)), 1);
	if ((frameCount % x) == 0) {

		//change noise for resolution in the background, but only fire event occasionally
		newWidth = resolution.noiseRange(-50, maxWidth);
		newHeight = resolution.noiseRange(-50, maxHeight);

		//do that here because it might change the resolution
		timedEvents();

		//don't always refresh the background
		if (toggleGridStep.noiseBool(-5, 10)) {
			refreshPixelArray();
		}

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
					if (toggleNoiseColor.noiseBool(-10, 5)) {
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
}

//refresh the pixel array with all black pixels, because background() doesn't do that
function refreshPixelArray() {
	for(let p = 0; p < pixels.length; p++) {
		pixels[p] = 0;
	}
}

//compute grid lines to apply to pixel array manipulation
function computeGridLines() {
	let x = floor(cutoff(xGridStep.noiseVariableRange(-10, -20, 1, 20), 1));
	let y = floor(cutoff(yGridStep.noiseVariableRange(-10, -20, 1, 20), 1));
	return {x, y};		//return as tuple
}

//take range and cut at cutoff; useful when a value needs to stick towards the cutoff, but should still change sometimes
function cutoff(range, cutoff) {
	if (range > cutoff) return range;
	else return cutoff;
}

//sometimes things should happen at random intervals instead
function timedEvents() {
	//sometimes switch to a new random resolution
	resEventCounter++;
	if (resEventCounter > (nextResEvent * 60)) {
		setRandomResolution();
		nextResEvent = floor(random(5, maxSwitchTime));
		resEventCounter = 0;
	}
}

//set canvas and sketch to a new resolution
function setRandomResolution() {
	canvasWidth = floor(cutoff(newWidth, minWidth));
	canvasHeight = floor(cutoff(newHeight, minHeight));
	//console.log("width: " + canvasWidth + "\n" + "height: " + canvasHeight);
	reset();
}