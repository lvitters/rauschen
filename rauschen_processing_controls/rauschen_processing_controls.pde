import javax.sound.midi.*;
import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress mainSketchLocation;

int width = 750;
int height = 500;

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

// midi input
MidiDevice inputDevice;

// variables to change with Midi to send over to main sketch
float minSwitchTime;
float maxSwitchTime;
float switchTime;
float switchTimeMultiplier;
int xStep;
int yStep;

public void settings() {
	size(width, height);
}

public void setup() {	
	// set this window title
	windowTitle("controls");
	
	// determine window location on screen
	surface.setLocation(1020, 60);

	// can't go in settings for some reason
	frameRate(120);
	colorMode(RGB, 255, 255, 255);

	// init OSC
	oscP5 = new OscP5(this, 12000); // local port for this sketch
	mainSketchLocation = new NetAddress("127.0.0.1", 9000); // receiver on port 12000

	// midi controls
	//listMidiControllers();
	setupMidi();
}

public void draw() {
	background(0);

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
	// check if it's the message with noises
	if (msg.checkAddrPattern("/noises")) {
		// get the typetag to know how many values were sent
		String typetag = msg.typetag();
		int numValues = typetag.length() - 1; // subtract 1 for the comma at the beginning

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
	// general handler for debug info messages
	else if (msg.addrPattern().startsWith("/info/")) {
		String key = msg.addrPattern().substring(6); // remove "/info/" prefix to get the key
		
		// extract the value based on the OSC message's typetag
		Object value = null;
		char type = msg.typetag().charAt(0); // get the type of the first argument
		
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
			// default to float for unknown types
			value = msg.get(0).floatValue();
		}
		
		// special handling for boolean values (sent as integers)
		if (key.startsWith("is") && value instanceof Integer) {
			value = ((Integer)value == 1);
		}
		
		// store the value in our map
		debugInfo.put(key, value);
	}
}

// display function to show debug info
void displayDebugInfo() {
	if (debugInfo.isEmpty()) return;
	
	// text parameters
	float x = 10;
	float y = 25;
	fill(255, 255, 255);
	textSize(20);

	// display debug alphabetically (order wouldn't be what it is in the other sketch anyways)
	ArrayList<String> keys = new ArrayList<String>(debugInfo.keySet());
	java.util.Collections.sort(keys);		// sort alphabetically
	
	// from all the received keys
	for (String key : keys) {
			// get the value
			Object value = debugInfo.get(key);
			String display;
			
			// display different formats
			if (value instanceof Boolean) {
				// get boolean from 1 and 0
				display = (Boolean)value ? "TRUE" : "FALSE";
			} else if (value instanceof Float) {
				// round floats to 2 decimal places
				display = nf((Float)value, 0, 2);
			// everything else
			} else {
				display = value.toString();
			}
			
			// display
			text(key + ": " + display, x, y);
			y += 20;
	}
}

// get info from device list and set controller as input device
void setupMidi() {
    try {
        // get all MIDI devices
        MidiDevice.Info[] infos = MidiSystem.getMidiDeviceInfo();

        // look specifically for MPKmini2 with transmitter capability
        for (int i = 0; i < infos.length; i++) {
            MidiDevice device = MidiSystem.getMidiDevice(infos[i]);
            if (infos[i].getName().equals("Grid") && device.getMaxTransmitters() != 0) {
                inputDevice = device;
                inputDevice.open();
                Transmitter transmitter = inputDevice.getTransmitter();
                transmitter.setReceiver(new MidiInputReceiver());
                println("Successfully opened Grid for input");
                break;
            }
        }
        if (inputDevice == null) {
            println("Could not find Grid with input capability");
        }
    } catch (Exception e) {
        println("Error: " + e.getMessage());
        e.printStackTrace();
    }
}

// detect and list all available MIDI devices
void listMidiControllers() {
	try {
		// get all MIDI devices
		MidiDevice.Info[] infos = MidiSystem.getMidiDeviceInfo();
		
		// print detailed info about all available MIDI devices
		println("Available MIDI Devices:");
		for (int i = 0; i < infos.length; i++) {
		MidiDevice device = MidiSystem.getMidiDevice(infos[i]);
		println("-------------------------------");
		println("Device #" + i);
		println("Name: " + infos[i].getName());
		println("Description: " + infos[i].getDescription());
		println("Vendor: " + infos[i].getVendor());
		println("Version: " + infos[i].getVersion());
		println("Max Transmitters: " + device.getMaxTransmitters());
		println("Max Receivers: " + device.getMaxReceivers());
		}
	} catch (Exception e) {
		println("Error: " + e.getMessage());
		e.printStackTrace();
	}
}