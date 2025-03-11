// Graphs displays all Noises' values in graphs
class Graphs extends PApplet {
	ArrayList<Graph> graphs;
	color[] colors;

	// contructor
	public Graphs() {
		// some stuff for making the child applet work
		super();
		PApplet.runSketch(new String[]{this.getClass().getName()}, this);

		// init ArrayList of graphs
		graphs = new ArrayList<Graph>();

		// init some predetermined colors so that they are easily differentiated
		colors = new color[] {
			#FF0000, 
			#00FF00,
			#0000FF, 
			#DC143C, 
			#228B22, 
			#1E90FF, 
			#BA55D3, 
			#3CB371, 
			#7B68EE, 
			#C71585, 
			#00FA9A, 
			#0000CD,
			#FF4500,  // OrangeRed
			#32CD32,  // LimeGreen
			#4169E1,  // RoyalBlue
			#FFD700,  // Gold
			#8A2BE2,  // BlueViolet
			#20B2AA,  // LightSeaGreen
			#FF69B4,  // HotPink
			#8B0000,  // DarkRed
			#556B2F,  // DarkOliveGreen
			#00CED1,  // DarkTurquoise
			#DAA520,  // GoldenRod
			#9400D3,  // DarkViolet
			#4682B4,  // SteelBlue
			#D2691E,  // Chocolate
			#B22222,  // FireBrick
			#708090,  // SlateGray
			#9932CC,  // DarkOrchid
			#FF6347,  // Tomato
			#48D1CC,  // MediumTurquoise
			#7FFF00   // Chartreuse
		};
	}

	public void settings() {
		size(gWidth, gHeight);
	}

	public void setup() {
		windowTitle("Graphs");

		// determine window location on screen
		surface.setLocation(1050, 60);
		
		// add graph for each noise with color from predetermined colors
		for (int i = 0; i < noises.size(); i++) {
			graphs.add(new Graph(colors[i]));
		}
	}

	public void draw() {
		background(0);
		strokeWeight(2);

		// add new point and display graphs
		for (int i = 0; i < graphs.size(); i++) {
			// get graph
			Graph g = graphs.get(i);

			// add new point
			g.addPoint(noises.get(i).value);

			// display the Graph // FOR SOME REASON THIS CANNOT BE IN A FUNCTION IN THE GRAPH CLASS
			stroke(g.col);
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