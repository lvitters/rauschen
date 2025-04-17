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
		if (points.size() > width) {
			points.remove(0);
		}
		// add a new point
		points.add(point);
	}

	// add empty points to the graph on setup
	public void init() {
		for (int i = 0; i < width; i++) {
			points.add(0.0);
		}
	}

	// display points from graph
	public void display() {
		stroke(col);
		strokeWeight(2);
		
		// precalculate map min max
		float yMin = height - 20;
		float yMax = height/2;
		float yRange = yMin - yMax;
		
		// draw lines
		beginShape(LINES);
			for (int x = 1; x < points.size() - 1; x += 1) {
				// draw the points
				Float y = points.get(x);
				Float yNext = points.get(x + 1);
				if (y != null && yNext != null) {
					// calculate individual mapped Y
					float mappedY = yMin - (y * yRange);
            		float mappedYNext = yMin - (yNext * yRange);
					vertex(x, mappedY);
					vertex(x, mappedYNext);
				}
			}
		endShape();
	}
}