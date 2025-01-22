class Graphen extends PApplet {
	public Graphen() {
		super();
		PApplet.runSketch(new String[]{this.getClass().getName()}, this);
	}

	public void settings() {
		size(775, 200);
	}

	public void setup() {
		windowTitle("Graphen");

		// determine window location on screen
		surface.setLocation(1020, 50);
	}

	public void draw() {
		background(0);
	}
}