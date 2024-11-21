//res of canvas, change size in index.html
let canvasWidth = 400;
let canvasHeight = 400;

let gridLinesX;
let gridLinesY;

function setup() {
	createCanvas(canvasWidth, canvasHeight);
	frameRate(30);
	pixelDensity(1);

	gridLinesX = new NoiseObject(Math.random() * 100, .1);
	gridLinesY = new NoiseObject(Math.random() * 100, .1);

	//get pixel array for manipulation
	loadPixels();
}

function draw() {

	//console.log(computeGridLines().x + " " + computeGridLines().y);

	//manipulate pixel array
	for (let x = 0; x < canvasWidth; x += computeGridLines().x) {
		for (let y = 0; y < canvasHeight; y += computeGridLines().y) {
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

//compute grid lines (every x columns and every y rows) to apply to pixel array manipulation
function computeGridLines() {
	let x = floor(map(gridLinesX.getNoise(), 0, 1, -128, 64));
	let y = floor(map(gridLinesY.getNoise(), 0, 1, -128, 64));
	if (x < 1) x = 1;
	if (y < 1) y = 1;
	return {x, y};
}