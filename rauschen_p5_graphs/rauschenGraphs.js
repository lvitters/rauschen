let canvasWidth = 1000;
let canvasHeight = 600;

let graphs = [];
let values = 8;
let graphsLength = 0;
let graphStep = 2;

let colors = [];

//osc stuff
let receivingNoises = true;
let socket;

function setup() {
	createCanvas(canvasWidth, canvasHeight);
	frameRate(60);
	pixelDensity(1);

	//predetermined colors look better and make it more easily readable
	colors = [	
		color('#FF0000'), 
		color('#00FF00'),
		color('#0000FF'), 
		color('#DC143C'), 
		color('#228B22'), 
		color('#1E90FF'), 
		color('#BA55D3'), 
		color('#3CB371'), 
		color('#7B68EE'), 
		color('#C71585'), 
		color('#00FA9A'), 
		color('#0000CD')
	];

	//setup osc connection (in port, out port)
	if (receivingNoises) setupOsc(3334, 12000);
}

function draw() {
	background(255);
	stroke(0);
	noFill();

	//check if number of values / length of graphs changes
	if (graphsLength != values) {
		setupGraphs();
		values = graphsLength;
	}

	//draw vertices from the graphs
	for (let g = 0; g < graphsLength; g++) {
		let points = graphs[g].points;
		//fill with predetermined or random colors
		let randomColor;
		if (colors[g] != null) {
			randomColor = colors[g];
		} else {
			randomColor = graphs[g].color;
		}
		stroke(randomColor);
		beginShape();
			for (let x = 0; x < points.length; x+=1) {
				let y = points[x];
				//console.log(y);
				if (y != null) vertex(x, map(y, 0, 1, canvasHeight - 20, 20));
			}
		endShape();
	}

	//noLoop();
}

//empty graphs array and set up with new number of graphs, depending on what OSC packet comes in
function setupGraphs() {
	graphs = [];
	for (let i = 0; i < graphsLength; i++) {
		let randomColor = color(Math.random() * 255, Math.random() * 255, Math.random() * 255);
		let graph = new Graph(randomColor);
		//add empty points
		for (let j = 0; j < canvasWidth; j++) {
			graph.setPoint(canvasHeight/2);
		}
		graphs.push(graph);
	}
	console.log("set up " + graphsLength + " graphs");
}


// -------------------- https://github.com/genekogan/p5js-osc -------------------- //
// ----------------- run 'node lib/bridge.js' to start connection ---------------- //

function receiveOsc(address, value) {
	//console.log("received OSC: " + address + ", " + value);
	//console.log(value.length);

	let values = value.length;
	graphsLength = values;
	
	//assign values from noises to graphs
	if (address == '/noises') {
		for (let i = 0; i < values; i++) {
			let val = value[i];
			//console.log(val);

			//check if points exists and is of correct type
			if(graphs[i].points === undefined) {
				return;
			} else {
				//console.log(graphs[i].points);
				graphs[i].points.shift();
				graphs[i].points.push(val);
				//fill with null points to space out graph
				for (let j = 0; j < graphStep; j++) {
					graphs[i].points.shift();
					graphs[i].points.push(null);
				}
			}
		}
	}
}

function sendOsc(address, value) {
	socket.emit('message', [address].concat(value));
}

function setupOsc(oscPortIn, oscPortOut) {
	socket = io.connect('http://127.0.0.1:8082', { port: 8082, rememberTransport: false });
	socket.on('connect', function() {
		socket.emit('config', {
			server: { port: oscPortIn,  host: '127.0.0.1'},
			client: { port: oscPortOut, host: '127.0.0.1'}
		});
	});
	socket.on('message', function(msg) {
		if (msg[0] == '#bundle') {
			for (var i=2; i<msg.length; i++) {
				receiveOsc(msg[i][0], msg[i].splice(1));
			}
		} else {
			receiveOsc(msg[0], msg.splice(1));
		}
	});
}