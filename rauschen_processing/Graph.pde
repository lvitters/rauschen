// a Graph is a series of values on the Y axis

class Graph {
	ArrayList<Float> points;

	// constructor
	public Graph() {
		points = new ArrayList<Float>();
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
}