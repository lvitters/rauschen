// Graphs displays all NoiseObjects' values in graphs

class Graphs extends PApplet {
	ArrayList<Graph> graphs;

	// contructor
	public Graphs() {
		// some stuff for making the child applet work
		super();
		PApplet.runSketch(new String[]{this.getClass().getName()}, this);

		// init ArrayList of graphs
		graphs = new ArrayList<Graph>();
	}

	public void settings() {
		size(gWidth, gHeight);
	}

	public void setup() {
		windowTitle("Graphs");

		// determine window location on screen
		surface.setLocation(1020, 50);
		
		// how many graphs will there be
		for (int i = 0; i < noises.size(); i++) {
			graphs.add(new Graph());
		}
	}

	public void draw() {
		background(0);
		stroke(255);

		// add new point and display graphs
		for (int i = 0; i < graphs.size(); i++) {
			// get graph
			Graph g = graphs.get(i);

			// add new point
			g.addPoint(noises.get(i).value);
			
			// display points from graph
			beginShape(LINES);
				for (int x = 0; x < g.points.size(); x++) {
					// draw the points
					Float y = g.points.get(x);
					if (y != null) {
						vertex(x, map(y, 0, 1, height - 20, 20));
					}
				}
			endShape();
		}
	}
}