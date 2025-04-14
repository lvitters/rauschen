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
Rectangle[] screensBounds;

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

// UI
float tableX = 5;
float tableY = 205;
float rowHeight = 20;
float keyWidth = 250;
float valueWidth = 100;
float padding = 5;
float borderWeight = 1;

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
	size(width, height);
}

public void setup() {	
	// set this window title
	windowTitle("controls");

	// determine window location on screen
	surface.setLocation(1000, 40);

	// store the screenshots' bounds for mouse pressing
	screensBounds = new Rectangle[numScreensToShow];  
	for (int i = 0; i < screensBounds.length; i++) {
    	screensBounds[i] = new Rectangle(); // init
  	}

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
	loadRecentScreens();
}

public void draw() {
	background(201, 203, 201);

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

// display function to show debug info in a table
void displayDebugInfo() {
    if (debugInfo.isEmpty()) return;

    // text parameters
    fill(0);
    textAlign(LEFT, TOP);
    textSize(20);

    // display debug alphabetically (order wouldn't be what it is in the other sketch anyways)
    ArrayList<String> keys = new ArrayList<String>(debugInfo.keySet());
    java.util.Collections.sort(keys);   // sort alphabetically

    // draw table header
    float headerY = tableY + padding;
    text("Key", tableX + padding, headerY);
    text("Value", tableX + keyWidth + padding * 2, headerY);
    stroke(0);
    line(tableX, tableY + rowHeight + padding / 2, tableX + keyWidth + valueWidth + padding * 3, tableY + rowHeight + (padding * 1.5) / 2); // line below header

    // draw vertical separator line between columns
    line(tableX + keyWidth + padding, tableY, tableX + keyWidth + padding, tableY + rowHeight * (keys.size() + 1) + padding);

    // from all the received keys, display them and their values in rows
    for (int i = 0; i < keys.size(); i++) {
        // get the value
        String key = keys.get(i);
        Object value = debugInfo.get(key);
        String display;

        // format the value
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
        float yPos = tableY + rowHeight * (i + 1) + padding * 1.5; // position text with some padding
        text(key, tableX + padding, yPos);
        text(display, tableX + keyWidth + padding * 2, yPos);
    }

    // draw table border
    noFill();
    stroke(0);
    rect(tableX, tableY, keyWidth + valueWidth + padding * 3, rowHeight * (keys.size() + 1) + padding * 1.5); // adjust height for bottom padding
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

    // if there are recent screenshots and the bounds array is ready
    if (recentScreens != null && screensBounds != null) {

		// get width allocated for each image slot
        int imgWidth = width / numScreensToShow;

        // for all display slots
        for (int i = 0; i < numScreensToShow; i++) {
            // calculate the index for the image data (displaying in reverse order)
            int imgIndex = recentScreens.length - 1 - i;

            // check if imgIndex is valid and the corresponding screen exists
            if (imgIndex >= 0 && imgIndex < recentScreens.length && recentScreens[imgIndex] != null) {
                // calculate the available dimensions for scaling (respecting padding on both sides)
                float availableWidthForScaling = imgWidth - 2 * padding;
                float availableHeightForScaling = height - 2 * padding; // use sketch height minus padding

                // default to safe values if calculation is impossible
                float x = 0, y = 0, w = 0, h = 0;

                // ensure available dimensions are positive before calculating scale
                if (availableWidthForScaling > 0 && availableHeightForScaling > 0 && recentScreens[imgIndex].width > 0 && recentScreens[imgIndex].height > 0) {
                    // scale the image to fit available space
                    float scaleFactor = min(availableWidthForScaling / recentScreens[imgIndex].width,
                                            availableHeightForScaling / recentScreens[imgIndex].height);

                    // calculate scaled dimensions
                    w = recentScreens[imgIndex].width * scaleFactor;
                    h = recentScreens[imgIndex].height * scaleFactor;

                    // calculate position relative to sketch origin (0,0)
                    // place left edge exactly padding pixels into the slot i
                    x = (i * imgWidth) + padding;

                    // place top edge exactly padding pixels down from sketch origin
                    y = padding;

                    // store in screensBounds array, cast to int
                    screensBounds[i].setBounds((int)x, (int)y, (int)w, (int)h);

                } else {
                    // If calculation wasn't possible, store empty bounds
                    screensBounds[i].setBounds(0, 0, 0, 0); // Mark as invalid/empty
                    continue; // Skip drawing etc for this invalid slot
                }

                // draw black border
                pushStyle(); // save current drawing style
					strokeWeight(borderWeight);
					stroke(0);
					noFill();
					rect(x - borderWeight / 2, y - borderWeight / 2, w + borderWeight, h + borderWeight);
                popStyle(); // restore previous drawing style

                // display image
                image(recentScreens[imgIndex], x, y, w, h);

                // check if mouse is over this image (using precise float bounds is good here)
                boolean isOverThisImage = (mouseX > x && mouseX < x + w && mouseY > y && mouseY < y + h && mouseOver);

                // draw transparent rect when hovering with mouse
                if (isOverThisImage) {
                    mouseOverAnyImage = true; // set flag for cursor change later
                    noStroke();
                    fill(50, 255, 50, 40); // light green with low opacity
                    rect(x, y, w, h); // overlay on the image bounds
                }

                // draw a flash animation after a screenshot is saved
                // check if the original index of the saved image matches this image's original index
                if (savedAnimation > 0 && imgIndex == savedImageIndex) {
                    // calculate fade-out effect
                    float alpha = map(savedAnimation, 0, 90, 0, 230);

                    // draw semi-transparent overlay
                    noStroke();
                    fill(0, 200, 0, alpha * 0.3);
                    rect(x, y, w, h);

                    // draw "SAVED" text
                    fill(255, alpha);
                    textAlign(CENTER, CENTER);
                    textSize(min(w, h) * 0.2); // size text proportional to image
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

// listen to key presses (fallback - stuff generally handled by control sketch)
void keyPressed() {
	// f - show debug / fps
	if (keyCode == 70) {
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