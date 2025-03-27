//create a class of graphs for displaying the number buffers
class Graph {
	//initialise
	constructor(col) {
		this.points = [];
		this.color = col;
	}

	//add a point to the graph
	setPoint(point) {
		this.points.push(point);
	}
}