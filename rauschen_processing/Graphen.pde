class Graphen extends PApplet {
	ArrayList<Graph> graphs;
	
	public Graphen() {
		super();
		PApplet.runSketch(new String[]{this.getClass().getName()}, this);

		graphs = new ArrayList<Graph>();
	}

	public void settings() {
		size(gWidth, gHeight);
	}

	public void setup() {
		windowTitle("Graphen");

		// determine window location on screen
		surface.setLocation(1020, 50);
		
		// how many graphs will there be
		for (int i = 0; i < 2; i++) {
			graphs.add(new Graph());
		}
	}

	public void draw() {
		background(0);
		stroke(255);

		// add NoiseObject values to graphs 
		graphs.get(0).addPoint(xStepNoise.value);
		graphs.get(1).addPoint(yStepNoise.value);

		// display graphs
		for (int i = 0; i < graphs.size(); i++) {
			// get graph
			Graph g = graphs.get(i);
			
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