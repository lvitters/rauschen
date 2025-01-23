// a Graph is a series of values on the Y axis that is displayed in a certain color
class Graph {
	ArrayList<Float> points;
	color col;

	// constructor
	public Graph(color c) {
		points = new ArrayList<Float>();
		col = c;
		init();
	}

	// add a point to the graph
	public void addPoint(float point) {
		// if the graph is wider than the window, remove the first point
		if (points.size() > gWidth) {
			points.remove(0);
		}
		// add a new point
		points.add(point);
	}

	// add empty points to the graph on setup
	public void init() {
		for (int i = 0; i < gWidth; i++) {
			points.add(0.0);
		}
	}

	// display points from graph // CURRENTLY UNUSED BECAUSE VERTICES ONLY DISPLAY WHEN DONE IN GRAPHS DIRECTLY
	// public void display() {
	// 	stroke(col);
	// 	beginShape(LINES);
	// 		for (int x = 0; x < points.size(); x++) {
	// 			// draw the points
	// 			Float y = points.get(x);
	// 			if (y != null) {
	// 				vertex(x, map(y, 0, 1, height - 20, 20));
	// 			}
	// 		}
	// 	endShape();
	// }
}