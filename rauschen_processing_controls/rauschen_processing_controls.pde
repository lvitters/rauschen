import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress mainSketchLocation;

int width = 700;
int height = 700;

// init some predetermined colors so that they are easily differentiated
color[] colors = new color[] {
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

// init ArrayList of graphs
ArrayList<Graph> graphs = new ArrayList<Graph>();

// HashMap to store debugInfo values
HashMap<String, Object> debugInfo = new HashMap<String, Object>();

public void settings() {
	size(width, height);
}

public void setup() {
	// determine window location on screen
	surface.setLocation(1050, 60);

	// init OSC
	oscP5 = new OscP5(this, 12000); // local port for this sketch
	mainSketchLocation = new NetAddress("127.0.0.1", 9000); // receiver on port 12000
}

public void draw() {
	background(0);
	strokeWeight(2);

	// display all graphs
	for (int i = 0; i < graphs.size(); i++) {
		// get and display graph
		Graph g = graphs.get(i);
		g.display();
	}

	displayDebugInfo();
}

// called when new OSC message is received
void oscEvent(OscMessage msg) {
	// check if it's the message with our noise values
	if (msg.checkAddrPattern("/noises")) {
		// Get the typetag to know how many values were sent
		String typetag = msg.typetag();
		int numValues = typetag.length() - 1; // Subtract 1 for the comma at the beginning

		// ensure there is the right number of graphs
		while (graphs.size() < numValues) {
			graphs.add(new Graph(colors[graphs.size() % colors.length]));
		}
		
		// if there are too many graphs, remove extras
		while (graphs.size() > numValues) {
			graphs.remove(graphs.size() - 1);
		}
		
		// add received values directly to graphs
		for (int i = 0; i < numValues; i++) {
			float value = msg.get(i).floatValue();
			graphs.get(i).addPoint(value);
		}
	}
	// General handler for all debug info messages
	else if (msg.addrPattern().startsWith("/info/")) {
		String key = msg.addrPattern().substring(6); // Remove "/info/" prefix to get the key
		
		// Extract the value based on the OSC message's typetag
		Object value = null;
		char type = msg.typetag().charAt(0); // Get the type of the first argument
		
		switch(type) {
		case 'i': // integer
			value = msg.get(0).intValue();
			break;
		case 'f': // float
			value = msg.get(0).floatValue();
			break;
		case 's': // string
			value = msg.get(0).stringValue();
			break;
		default:
			// Default to float for unknown types
			value = msg.get(0).floatValue();
		}
		
		// Special handling for boolean values (sent as integers)
		if (key.startsWith("is") && value instanceof Integer) {
			value = ((Integer)value == 1);
		}
		
		// Store the value in our map
		debugInfo.put(key, value);
	}
}

// Display function to show debug info
void displayDebugInfo() {
	if (debugInfo.isEmpty()) return;
	
	fill(255);
	textAlign(LEFT);
	textSize(12);
	
	float y = 20;
	float x = 10;
	
	// Sort keys alphabetically for consistent display
	ArrayList<String> keys = new ArrayList<String>(debugInfo.keySet());
	java.util.Collections.sort(keys);
	
	for (String key : keys) {
			Object value = debugInfo.get(key);
			String display;
			
			// Format different types of values
			if (value instanceof Boolean) {
			display = (Boolean)value ? "ON" : "OFF";
			}
			else if (value instanceof Float && (key.equals("nextSwitch") || key.contains("Time"))) {
			// Format time values nicely
			display = nf((Float)value, 2, 3);
			}
			else if (value instanceof Float) {
			// Round other floats to 2 decimal places
			display = nf((Float)value, 0, 2);
			}
			else {
			display = value.toString();
			}
			
			text(key + ": " + display, x, y);
			y += 20;
	}
}