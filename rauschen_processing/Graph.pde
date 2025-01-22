class Graph {
	ArrayList<Float> points;

	// constructor
	public Graph() {
		points = new ArrayList<Float>();
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
}