import java.util.PriorityQueue;
import java.util.Collections;
import java.util.Comparator;
import java.io.FilenameFilter;
import java.util.Arrays;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;
import java.awt.Rectangle;
import javax.sound.midi.*;

import oscP5.*;
import netP5.*;


// sketch window
int manualWidth = 800;
int manualHeight = 500;
Boolean showDebug = true;
Boolean fullScreen = true;

// main sketch communication
OscP5 oscP5;
NetAddress mainSketchLocation;

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

// screenshot gallery
PImage[] recentScreens;
PImage[] scaledScreens; // store pre-scaled screens for better performance
File[] files;
Rectangle[] screensBounds;
int numScreensToShow = 4;
String screensDir = "../rauschen_screens/temp/";
String savedScreensDir = "../rauschen_screens/saved/";
int savedAnimation = 0;
int savedImageIndex = -1;  // which image was saved (-1: none)
public boolean mouseOver = true;

// UI
float padding = 5;
float borderWeight = 1;
// debug table
float rowHeight = 20;
float keyWidth = 250;
float valueWidth = 100;

// midi input
MidiDevice inputDevice;
MidiDevice outputDevice;
Receiver midiReceiver;

// variables to change with Midi to send over to main sketch
float minSwitchTime;
float maxSwitchTime;
float switchTime;
float switchTimeMultiplier;
int xStep;
int yStep;

public void settings() {
	if (!fullScreen) size(manualWidth, manualHeight);
	else fullScreen(2);
}

public void setup() {	
	// set this window title
	windowTitle("controls");

	// determine window location on screen
	if (!fullScreen) surface.setLocation(1000, 40);

	// can't go in settings for some reason
	frameRate(120);
	colorMode(RGB, 255, 255, 255);

	// init OSC
	oscP5 = new OscP5(this, 12000); // local port for this sketch
	mainSketchLocation = new NetAddress("127.0.0.1", 9000); // receiver on port 12000

	// midi controls
	//listMidiControllers();
	setupMidiOutput();
	setupMidiInput();

	// screenshot gallery
	// store the screenshots' bounds for mouse pressing
	screensBounds = new Rectangle[numScreensToShow];
	// store scaled screenshots for better performance
	scaledScreens = new PImage[numScreensToShow];
	for (int i = 0; i < screensBounds.length; i++) {
    	screensBounds[i] = new Rectangle(); // init
  	}
	loadRecentScreens();
	updateScaledScreens();
}

public void draw() {
	background(201, 203, 201);

	// update screenshot gallery once every second
	if (frameCount % 60 == 0) {
		loadRecentScreens();
		updateScaledScreens();
	}
	displayRecentScreens();

	// display all graphs
	for (int i = 0; i < graphs.size(); i++) {
		// get and display graph
		Graph g = graphs.get(i);
		g.display();
	}

	if (showDebug) displayDebugInfo();
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

// fill scaledScreens[] with screenshots scaled according to width and height
void updateScaledScreens() {
	if (recentScreens == null || scaledScreens == null || screensBounds == null) return;
	if (numScreensToShow <= 0) return; // avoid division by zero

	int imgWidth = width / numScreensToShow;
	float screenshotAreaHeight = height * (2.0 / 3.0);
	float availableWidthForScaling = imgWidth - 2 * padding;
	float availableHeightForScaling = screenshotAreaHeight - 2 * padding;

	if (availableWidthForScaling <= 0 || availableHeightForScaling <= 0) {
		println("Cannot scale images, available area too small.");
		// clear scaled images maybe?
		for (int i = 0; i < numScreensToShow; i++) scaledScreens[i] = null;
		return;
	}


	for (int i = 0; i < numScreensToShow; i++) {
		int imgIndex = recentScreens.length - 1 - i;

		if (imgIndex >= 0 && imgIndex < recentScreens.length && recentScreens[imgIndex] != null && recentScreens[imgIndex].width > 0 && recentScreens[imgIndex].height > 0) {
			// calculate scale factor based on available area
			float scaleFactor = min(availableWidthForScaling / recentScreens[imgIndex].width,
									availableHeightForScaling / recentScreens[imgIndex].height);

			// calculate target scaled dimensions
			int targetW = int(recentScreens[imgIndex].width * scaleFactor);
			int targetH = int(recentScreens[imgIndex].height * scaleFactor);

			if (targetW > 0 && targetH > 0) {
				// create a scaled copy
				scaledScreens[i] = recentScreens[imgIndex].copy(); // work on a copy
				scaledScreens[i].resize(targetW, targetH);       // resize it ONCE
			} else {
				scaledScreens[i] = null; // cannot resize to zero or negative
			}

		} else {
			// no source image for this slot
			scaledScreens[i] = null;
		}
	}
}

// display a set number from the images collected
void displayRecentScreens() {
    boolean mouseOverAnyImage = false;

    // only check recentScreens for null now, scaledScreens checked inside loop
    if (recentScreens != null && screensBounds != null && scaledScreens != null) {
        if (screensBounds.length != numScreensToShow || scaledScreens.length != numScreensToShow) {
            println("Warning: Array length mismatch!"); return;
        }

        int imgWidth = width / numScreensToShow; // still needed for positioning slots

        for (int i = 0; i < numScreensToShow; i++) {
            // get the pre-scaled image for this display slot
            PImage displayImg = scaledScreens[i];

            if (displayImg != null) {
                // get pre-calculated size
                float w = displayImg.width;
                float h = displayImg.height;

                // calculate position (same logic as before to place the slot)
                // X relative to sketch edge + padding
                float x = (i * imgWidth) + padding;
                // Y relative to sketch edge + padding
                float y = padding;

                // store the actual bounds of the drawn (pre-scaled) image
                screensBounds[i].setBounds((int)x, (int)y, (int)w, (int)h);

                // drawing
                pushStyle();
					strokeWeight(borderWeight); stroke(0); noFill();
					// draw border around the known w, h
					rect(x - borderWeight / 2, y - borderWeight / 2, w + borderWeight, h + borderWeight);
                popStyle();
                // draw the pre-scaled image directly
                image(displayImg, x, y);

                // overlays (use the actual w, h)
                boolean isOverThisImage = (mouseX > x && mouseX < x + w && mouseY > y && mouseY < y + h && mouseOver);
                if (isOverThisImage) { /* ... draw hover rect(x, y, w, h) ... */
                    mouseOverAnyImage = true; noStroke(); fill(50, 255, 50, 40); rect(x, y, w, h);
                }

                // animation check still needs original index mapping
                int imgIndex = recentScreens.length - 1 - i;
                if (imgIndex >= 0 && imgIndex < recentScreens.length) { // check imgIndex validity
                    if (savedAnimation > 0 && imgIndex == savedImageIndex) { // draw save animation rect(x,y,w,h) and text
                        float alpha = map(savedAnimation, 0, 90, 0, 230); noStroke(); fill(0, 200, 0, alpha * 0.3); rect(x, y, w, h);
                        fill(255, alpha); textAlign(CENTER, CENTER); textSize(min(w, h) * 0.2); text("SAVED", x + w/2, y + h/2);
                    }
                }

            } else {
                // no image for this slot
                if (i < screensBounds.length) screensBounds[i].setBounds(0, 0, 0, 0);
            }
        }

		// switch cursor once after everything else is drawn
        if (mouseOverAnyImage) cursor(HAND); else cursor(ARROW);

    }

	// decrement animation timer
    if (savedAnimation > 0) savedAnimation--;
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

// display function to show debug info in a table
void displayDebugInfo() {
    if (debugInfo == null || debugInfo.isEmpty()) return;

    // calculate table position and size dynamically
    float tableStartX = padding; // start padding pixels from left edge
    // start padding pixels below the screenshot area (which occupies top 2/3)
    float tableStartY = height * 0.45 + padding;
    // calculate required height (consistent padding top/bottom)
    ArrayList<String> keys = new ArrayList<String>(debugInfo.keySet()); // get keys to count rows
    float totalTableHeight = padding + rowHeight * (keys.size() + 1) + padding; // topPad + headerRow + dataRows + bottomPad
    // calculate required width
    float totalTableWidth = keyWidth + valueWidth + 3 * padding; // keyCol + valCol + padL + padMid + padR

    // text and drawing setup
    fill(0);
    textAlign(LEFT, TOP);
    textSize(20); // keep font size fixed for now

 	// sort keys alphabetically
    java.util.Collections.sort(keys);

    // draw table header text
    float headerTextY = tableStartY + padding; // text starts padding down from table top
    text("Key", tableStartX + padding, headerTextY); // key text pad left
    text("Value", tableStartX + keyWidth + 2 * padding, headerTextY); // value text pad left

    // draw header underline (position below header text)
    stroke(0);
    strokeWeight(1); // use consistent stroke weight
    float headerLineY = headerTextY + rowHeight * 0.9; // place line below text (adjust 0.9 factor if needed)
    line(tableStartX, headerLineY, tableStartX + totalTableWidth, headerLineY);

    // draw vertical separator line (full height of calculated table area)
    float separatorX = tableStartX + keyWidth + padding; // x pos of line
    line(separatorX, tableStartY, separatorX, tableStartY + totalTableHeight);

    // draw key/value rows
    for (int i = 0; i < keys.size(); i++) {
        String key = keys.get(i);
        Object value = debugInfo.get(key);
        String displayValue = formatDisplayValue(value); // use helper function for clarity

        // calculate Y position for this row's text
        float rowTextY = headerTextY + rowHeight * (i + 1); // header + (i+1) rows down
        text(key, tableStartX + padding, rowTextY);
        text(displayValue, tableStartX + keyWidth + 2 * padding, rowTextY);
    }

    // draw table border
    noFill();
    stroke(0);
    strokeWeight(borderWeight); // use consistent border weight
    rect(tableStartX, tableStartY, totalTableWidth, totalTableHeight);
}

// helper function to format debug values (keeps displayDebugInfo cleaner)
String formatDisplayValue(Object value) {
    if (value == null) return "null";
    if (value instanceof Boolean) {
        return (Boolean)value ? "TRUE" : "FALSE";
    } else if (value instanceof Float) {
        return nf((Float)value, 0, 2); // round floats
    } else {
        return value.toString();
    }
}

// listen to key presses (fallback - stuff generally handled by control sketch)
void keyPressed() {
	// show debug / fps
	if (key == 'f') {
		showDebug = !showDebug;
	}
}

// fire if mouse was pressed
void mousePressed() {
    if (screensBounds != null) {
        // iterate through the stored bounds (which match display order)
        for (int i = 0; i < screensBounds.length; i++) {
            // check if click is within the bounds stored for display slot 'i'
            if (screensBounds[i] != null && screensBounds[i].width > 0 && screensBounds[i].contains(mouseX, mouseY)) {

                // calculate the original file index based on display slot 'i'
                int imgIndex = recentScreens.length - 1 - i; // *** Still need this mapping ***

                // ensure imgIndex is valid before accessing files/recentScreens
                if (imgIndex >= 0 && imgIndex < files.length && recentScreens[imgIndex] != null ) {

                    // get the file using the CORRECT reversed index
                    saveScreenshot(files[imgIndex]);

                    // reset animation variables
                    savedAnimation = 90;
                    savedImageIndex = imgIndex; // store the correct original index

                    return; // exit after handling click
                }
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