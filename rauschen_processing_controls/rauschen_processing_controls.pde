import java.util.PriorityQueue;
import java.util.Collections;
import java.util.Comparator;
import java.io.FilenameFilter;
import java.util.Arrays;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;
import javax.sound.midi.*;

import oscP5.*;
import netP5.*;

// screenshot gallery
PImage[] recentScreens;
File[] files;
int numScreensToShow = 4;
String screensDir = "../rauschen_screens/temp/";
String savedScreensDir = "../rauschen_screens/saved/";
int savedAnimation = 0;
int savedImageIndex = -1;  // which image was saved (-1: none)
public boolean mouseOver = true;

OscP5 oscP5;
NetAddress mainSketchLocation;

int width = 800;
int height = 500;
Boolean showDebug = true;

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
	surface.setLocation(1000, 40);

	// can't go in settings for some reason
	frameRate(120);
	colorMode(RGB, 255, 255, 255);

	// init OSC
	oscP5 = new OscP5(this, 12000); // local port for this sketch
	mainSketchLocation = new NetAddress("127.0.0.1", 9000); // receiver on port 12000

	// midi controls
	//listMidiControllers();
	setupMidi();

	// screenshot gallery
	loadRecentScreens();
}

public void draw() {
	background(0);

	// display screenshot gallery
	if (frameCount % 60 == 0) loadRecentScreens();
	displayRecentScreens();

	// display all graphs
	for (int i = 0; i < graphs.size(); i++) {
		// get and display graph
		Graph g = graphs.get(i);
		g.display();
	}

	if (showDebug) displayDebugInfo();
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
	textAlign(CORNER, CORNER);
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

// listen to key presses (fallback - stuff generally handled by control sketch)
void keyPressed() {
	// f - show debug / fps
	if (keyCode == 70) {
		showDebug = !showDebug;
	}
}

// fire if mouse was pressed
void mousePressed() {
	if (recentScreens != null) {
		int imgWidth = width / numScreensToShow;
		
		// check if click is within one of the image's location
		for (int i = 0; i < recentScreens.length; i++) {
			if (mouseX >= i * imgWidth && mouseX < (i + 1) * imgWidth && recentScreens[i] != null) {
				// screens are shown in reverse order, so they must be accessed from array in reverse order here
				saveScreenshot(files[recentScreens.length - 1 - i]);
				
				// reset animation variables
				savedAnimation = 90;  // 1.5 seconds at 60fps
				savedImageIndex = i;  // save which image was clicked
				
				break;
			}
		}
	}
}
    
// when the mouse exits the window
public void mouseExited() {
	mouseOver = false;
	cursor(ARROW);
}

// when the mouse enters the window
public void mouseEntered() {
	mouseOver = true;
}

// copy a chosen screenshot to another folder
void saveScreenshot(File sourceFile) {
	try {
		// create destination file in saved directory
		File destDir = new File(sketchPath(savedScreensDir));
		if (!destDir.exists()) {
			destDir.mkdirs();
		}
		
		File destFile = new File(destDir, sourceFile.getName());
		
		// copy the file
		Files.copy(sourceFile.toPath(), destFile.toPath(), StandardCopyOption.REPLACE_EXISTING);
		
		// println("Saved screenshot: " + sourceFile.getName() + " to " + destFile.getAbsolutePath());
		
	} catch (Exception e) {
		println("Error saving screenshot: " + e.getMessage());
		e.printStackTrace();
	}
}

// display a set number from the images collected in loadRecentScreens()
void displayRecentScreens() {
	// remember if the mouse is over any of the screenshots
	boolean mouseOverAnyImage = false;

	// if there are recent screenshots
	if (recentScreens != null) {
		int imgWidth = width / numScreensToShow;
		
		// for all screenshots
		for (int i = 0; i < recentScreens.length; i++) {
		if (recentScreens[i] != null) {
			// calculate position to display images side by side
			float x = i * imgWidth;
			float y = 0;
			
			// scale the image to fit while maintaining aspect ratio
			float scaleFactor = min((float)imgWidth / recentScreens[i].width, 
					(float)height / recentScreens[i].height);
			
			float w = recentScreens[i].width * scaleFactor;
			float h = recentScreens[i].height * scaleFactor;
			
			// center the image in its section
			x = x + (imgWidth - w) / 2;
			
			// display in descending order (images flow from right to left, like the graphs)
			image(recentScreens[recentScreens.length - 1 - i], x, y, w, h);

			// check if mouse is over this image
			boolean isOverThisImage = (mouseX > x && mouseX < x + w && mouseY > y && mouseY < y + h && mouseOver);

			// draw transparent rect when hovering with mouse
			if (isOverThisImage) {
				mouseOverAnyImage = true;  // set flag for cursor change later
				noStroke();
				fill(50, 255, 50, 40);  // light green with low opacity
				rect(x, y, w, h);
			}

			// draw a flash animation after a screenshot is saved, only for the saved image
			if (savedAnimation > 0 && i == savedImageIndex) {
				// calculate fade-out effect
				float alpha = map(savedAnimation, 0, 90, 0, 230);
				
				// draw semi-transparent overlay
				noStroke();
				fill(0, 200, 0, alpha * 0.3);
				rect(x, y, w, h);
				
				// draw "SAVED" text
				fill(255, alpha);
				textAlign(CENTER, CENTER);
				textSize(min(w, h) * 0.2);  // size text proportional to image
				text("SAVED", x + w/2, y + h/2);
			}
		}
		}

		// set cursor only once after checking all images to avoid flashing
		if (mouseOverAnyImage) {
			cursor(HAND);
		} else {
			cursor(ARROW);
		}
	}
	
	// decrement the animation counter once per frame
	if (savedAnimation > 0) {
		savedAnimation--;
	}
}

// load only a set number of recent screenshots from the folder for display
void loadRecentScreens() {
	// create the directory if it doesn't exist
	File dir = new File(sketchPath(screensDir));
	if (!dir.exists()) {
		dir.mkdirs();
		return;
	}
	
	// use a priority queue to keep track of only the N most recent files
	PriorityQueue<File> mostRecentFiles = new PriorityQueue<File>(
		numScreensToShow + 1, 
		new Comparator<File>() {
			public int compare(File f1, File f2) {
				// sort by modified time (oldest first to allow easy removal of oldest items)
				return Long.valueOf(f1.lastModified()).compareTo(f2.lastModified());
			}
		}
	);
	
	// custom filenameFilter to only get png files
	FilenameFilter imageFilter = new FilenameFilter() {
		public boolean accept(File dir, String name) {
			name = name.toLowerCase();
			return name.endsWith(".png");
		}
	};
	
	// process files one by one, keeping only the most recent
	for (File f : dir.listFiles(imageFilter)) {
		mostRecentFiles.add(f);
		
		// if there are more than needed, remove the oldest
		if (mostRecentFiles.size() > numScreensToShow) {
			mostRecentFiles.poll();
		}
	}
	
	// convert to array and reverse to get most recent first
	ArrayList<File> imageFiles = new ArrayList<File>(mostRecentFiles);
	Collections.sort(imageFiles, new Comparator<File>() {
		public int compare(File f1, File f2) {
			return Long.valueOf(f2.lastModified()).compareTo(f1.lastModified());
		}
	});
	
	// load the images
	int count = imageFiles.size();
	recentScreens = new PImage[count];
	files = new File[count];
	
	for (int i = 0; i < count; i++) {
		files[i] = imageFiles.get(i);
		recentScreens[i] = loadImage(files[i].getAbsolutePath());
	}
}