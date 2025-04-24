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
		if (points.size() > graphLength) {
			points.remove(0);
		}
		// add a new point
		points.add(point);
	}

	// add empty points to the graph on setup
	public void init() {
		for (int i = 0; i < graphLength; i++) {
			points.add(0.0);
		}
	}

	// display the points in points
	public void display() {
        if (points.size() < 2) {
            return; 
        }

		// isolate transformations
        pushMatrix();
			translate(graphAreaX, graphAreaY); // move origin to graph area's top-left
			stroke(col);
			strokeWeight(1f);

			beginShape(LINES);
			// loop through points
			for (int i = 0; i < points.size() - 1; i += 1) {
				Float y1Value = points.get(i);
				Float y2Value = points.get(i + 1); 

				if (y1Value != null && y2Value != null) {
					// map index i to graph area's width
					float x1 = map(i, 0, points.size() - 1, 0, graphAreaWidth - 1);
					// map value to graph area's height (with internal padding)
					float y1 = map(y1Value, 0, 1, graphAreaHeight - graphInternalPadding, graphInternalPadding);
					// map index i+1 to graph area's width
					float x2 = map(i + 1, 0, points.size() - 1, 0, graphAreaWidth - 1);
					// map value to graph area's height (with internal padding)
					float y2 = map(y2Value, 0, 1, graphAreaHeight - graphInternalPadding, graphInternalPadding);

					// add the two vertices relative to the translated origin
					vertex(x1, y1);
					vertex(x2, y2);
				}
			}
			endShape();
        popMatrix(); // restore original transformations
    }
}