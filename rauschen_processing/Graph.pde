class Graph {
	ArrayList<PVector> points;

	// constructor
	Graph() {
		points = new ArrayList<PVector>();
	}

	// add a point to the graph
	public void setPoint(PVector point) {
		points.add(point);
	}
}