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
int manualWidth = 2560;
int manualHeight = 1440 - 28 - 24;	// minus menu bar minus window bar
Boolean showDebug = true;

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
// number of historical points to show in each graph
int graphLength = 600;

// HashMap to store debugInfo values
HashMap<String, Object> debugInfo = new HashMap<String, Object>();

// screenshot gallery
int numDisplaySlots = 4; 			// number of fixed display slots
PImage[] slotImages_Original;    	// original, unscaled PImage for each display slot
PImage[] slotImages_Scaled;      	// PImage scaled for display for each slot
File[] slotImageFiles;         		// File object for image in each slot
long[] slotTimestamps;           	// millis of when the image in a slot was last updated
Rectangle[] slotBounds;          	// display bounds for each slot

File lastSuccessfullyPlacedCandidateFile = null; // newest candidate file last successfully placed

// background loading for loadScreensInBackground 
PImage[] tempRecentScreens; 
File[] tempFiles; 

String screensDir = "../rauschen_screens/temp/";
String savedScreensDir = "../rauschen_screens/saved/";
int savedAnimation = 0;
int animatingSaveForSlot = -1; 
public boolean mouseOver = true;
float screenshotAreaBottomY;
float scaledImageWidth;

// background screen loading
volatile boolean newScreensReady = false; // flag to signal completion (volatile for thread visibility)
volatile boolean isLoadingScreens = false; // flag to prevent starting multiple loads

// UI
float padding = 10;
float borderWeight = 1;
// debug table
float debugRowHeight = 20;
float debugKeyWidth = 250;
float debugValueWidth = 100;
// bounds for the graph display area determined at runtime
float graphAreaX;
float graphAreaY;
float graphAreaWidth;
float graphAreaHeight;
float graphInternalPadding = 10;

// macOS cursors (P2D renderer's look awful)
PImage defaultCursor, handCursor;

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
	size(manualWidth, manualHeight, P2D);
	smooth(16);	// AA
}

public void setup() {	
	// set this window title
	windowTitle("RAUSCHEN controls");

	// determine window location on screen
	//surface.setLocation(1000, 40);

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

	// prepare the UI for the given resolution
	setupUI();

	// load default macOS cursor PNGs
	defaultCursor = loadImage("cursors/default.png");
	handCursor = loadImage("cursors/pointer.png");
}

public void draw() {
	background(201, 203, 201);

	checkForRecentScreens();
	// load new screens once every X frames in background thread
	if (frameCount % 10 == 0 && !isLoadingScreens && !newScreensReady) {
		isLoadingScreens = true; // set flag to indicate loading has started
		thread("loadScreensInBackground");
	}

	displayRecentScreens();
	drawGraphsArea();

	if (showDebug) displayDebugInfo();
}

// setup areas and dimensions for screenshots, debugInfo and graphsArea
public void setupUI() {

	// screenshot gallery
	slotImages_Original = new PImage[numDisplaySlots];
    slotImages_Scaled = new PImage[numDisplaySlots];
    slotImageFiles = new File[numDisplaySlots];
    slotTimestamps = new long[numDisplaySlots]; 	// default values will be 0
    slotBounds = new Rectangle[numDisplaySlots];
	// init Rectangle objects
    for (int i = 0; i < numDisplaySlots; i++) {
        slotBounds[i] = new Rectangle();
    }

	// assumes square images fitting numScreensToShow across the width
	float totalHorizontalPadding = (numDisplaySlots + 1) * padding;
    float availableWidthForImages = width - totalHorizontalPadding;
    if (numDisplaySlots > 0) { // avoid division by zero
        scaledImageWidth = availableWidthForImages / numDisplaySlots;
    } else {
        scaledImageWidth = 0;
    }

	// top padding + image height
	screenshotAreaBottomY = padding + scaledImageWidth; 
	// calculate the x-coordinate of the 2nd screenshot's image (index i=1)
    graphAreaX = padding + 1 * (scaledImageWidth + padding); // Use index 1

    // calculate width from new graphAreaX to right edge minus padding
    graphAreaWidth = width - padding - graphAreaX;

    // y position and height  based on screenshotAreaBottomY
    graphAreaY = screenshotAreaBottomY + padding;

	// height is from y to bottom padding
    graphAreaHeight = height - graphAreaY - padding; 
}

// check "temp" folder for new screenshot
public void checkForRecentScreens() {
    if (newScreensReady) {
        isLoadingScreens = false; 

        // focus only on the top candidate from the background thread's list.
        // tempFiles[0] is the newest among the candidates selected by loadScreensInBackground.
        File currentTopCandidateFile = tempFiles[0];
        PImage currentTopCandidateImage = tempRecentScreens[0];
        
        // check if newest file is different from last newest file
        if (currentTopCandidateFile.equals(lastSuccessfullyPlacedCandidateFile)) {
            newScreensReady = false;
            return;
        }

        // is the file already displayed in the sketch
        boolean alreadyDisplayed = false;
        int displayedInSlot = -1; 
        for (int j = 0; j < numDisplaySlots; j++) {
            if (slotImageFiles[j] != null && slotImageFiles[j].equals(currentTopCandidateFile)) {
                alreadyDisplayed = true;
                displayedInSlot = j;
                break;
            }
        }

        if (alreadyDisplayed) {
            lastSuccessfullyPlacedCandidateFile = currentTopCandidateFile; 
            newScreensReady = false; 
            return;
        }
        
        // find slot for placement (oldest display time, or first empty).
		int targetSlotIndex = -1;
        long oldestSlotTimestamp = Long.MAX_VALUE; // using a more descriptive name for clarity

		// prioritize empty slots: check from right to left
		for(int i = numDisplaySlots - 1; i >= 0; --i) {
			if(slotImageFiles[i] == null) { // if slot is currently empty
				targetSlotIndex = i;
				oldestSlotTimestamp = Long.MIN_VALUE; // mark this as "oldest"
				break;
			}
		}

		// if no empty slot was found (targetSlotIndex is still -1, or oldestSlotTimestamp not Long.MIN_VALUE),
		// find the slot with the truly oldest content.
		if (targetSlotIndex == -1 || oldestSlotTimestamp != Long.MIN_VALUE) { 
				// initialize with right slot's values as a starting point for finding "oldest"
				targetSlotIndex = numDisplaySlots - 1; 
				oldestSlotTimestamp = slotTimestamps[numDisplaySlots - 1]; 
				
				// iterate through the rest of the slots from right-to-left
				for (int i = numDisplaySlots - 2; i >= 0; --i) { 
					if (slotTimestamps[i] < oldestSlotTimestamp) {
						oldestSlotTimestamp = slotTimestamps[i];
						targetSlotIndex = i;
					}
				}
		}

        // place the new image into the identified target slot
        slotImages_Original[targetSlotIndex] = currentTopCandidateImage;
        slotImageFiles[targetSlotIndex] = currentTopCandidateFile;
        slotTimestamps[targetSlotIndex] = millis(); 
        updateSpecificScaledScreen(targetSlotIndex); 

        lastSuccessfullyPlacedCandidateFile = currentTopCandidateFile;

        newScreensReady = false; // reset flag: batch fully processed
    }
}

// load recent screenshots from file folder in background thread
public void loadScreensInBackground() {
	// define the directory to search for screenshots
	File dir = new File(sketchPath(screensDir));
	// initialize local temporary variables for results
	PImage[] loadedImages = null;
	File[] foundFiles = null;

	// ensure the screenshot directory exists, create if necessary
	if (!dir.exists()) {
		if (dir.mkdirs()) {
			println("Created screenshots directory: " + screensDir);
		} else {
			// handle error if directory creation fails
			println("Error: Failed to create screenshots directory: " + screensDir);
			loadedImages = new PImage[0]; // set to empty results
			foundFiles = new File[0];
			// update global temporary variables even on error
			tempRecentScreens = loadedImages;
			tempFiles = foundFiles;
			// signal completion to prevent getting stuck
			newScreensReady = true;
			return; // Exit thread
		}
	}

	// define a filter to only accept .png files (case-insensitive)
	FilenameFilter imageFilter = new FilenameFilter() {
		public boolean accept(File dir, String name) {
			name = name.toLowerCase();
			return name.endsWith(".png");
		}
	};

	// get all files matching the filter in the directory
	File[] allImageFiles = dir.listFiles(imageFilter);

	// handle cases where listing files fails or returns null
	if (allImageFiles == null) {
		println("Warning: listFiles returned null for " + screensDir);
		loadedImages = new PImage[0]; // Set to empty results
		foundFiles = new File[0];
	} else {
		// convert the array to an ArrayList for easier manipulation
		ArrayList<File> sortedFiles = new ArrayList<File>(Arrays.asList(allImageFiles));

		// sort the files by modification date, newest file first
		Collections.sort(sortedFiles, new Comparator<File>() {
			public int compare(File f1, File f2) {
				return Long.valueOf(f2.lastModified()).compareTo(f1.lastModified()); // descending order
			}
		});

		// if any files were found, remove the single newest one (at index 0)
		// this prevents trying to load a file that might still be actively written to.
		if (!sortedFiles.isEmpty()) {
			File newestFile = sortedFiles.remove(0);
		}

		// use a PriorityQueue to efficiently find the N most recent files among the *remaining* files (after removing the newest).
		// the queue keeps the oldest items at the head for easy removal.
		PriorityQueue<File> mostRecentFiles = new PriorityQueue<File>(
			numDisplaySlots + 1, // capacity slightly larger than needed
			new Comparator<File>() {
				public int compare(File f1, File f2) {
					// sort oldest first to allow easy polling of the oldest
					return Long.valueOf(f1.lastModified()).compareTo(f2.lastModified());
				}
			}
		);

		// add the remaining files (newest excluded) to the priority queue
		for (File f : sortedFiles) {
			mostRecentFiles.add(f);
			// if the queue size exceeds the desired number, remove the oldest file
			if (mostRecentFiles.size() > numDisplaySlots) {
				mostRecentFiles.poll(); // Removes the head (oldest)
			}
		}

		// convert the final set of files from the queue back to an ArrayList
		ArrayList<File> imageFilesList = new ArrayList<File>(mostRecentFiles);

		// sort this final list newest-first, matching the display order
		Collections.sort(imageFilesList, new Comparator<File>() {
			public int compare(File f1, File f2) {
				// sort newest first for consistency with how they'll be displayed
				return Long.valueOf(f2.lastModified()).compareTo(f1.lastModified());
			}
		});

		// prepare the local arrays to hold the loaded images and their file objects
		int count = imageFilesList.size(); // actual number of images to load
		loadedImages = new PImage[count];
		foundFiles = new File[count];

		// load each selected image file
		for (int i = 0; i < count; i++) {
			foundFiles[i] = imageFilesList.get(i); // store the File object
			try {
				// load the image using Processing's loadImage
				loadedImages[i] = loadImage(foundFiles[i].getAbsolutePath());
				// check if loading failed (loadImage returns null)
				if (loadedImages[i] == null) {
					println("Warning (background): loadImage returned null for " + foundFiles[i].getName());
				}
			} catch (Exception e) {
				// catch potential errors during image loading
				println("Error loading image in background " + foundFiles[i].getName() + ": " + e.getMessage());
				loadedImages[i] = null; // set to null on error
			}
		}
	}

	// store the results (loaded images and files) in the global temporary variables
	// these will be picked up by the main draw thread.
	tempRecentScreens = loadedImages;
	tempFiles = foundFiles;

	// set the flag to true, signaling the main thread that new data is ready
	newScreensReady = true;
}

// scale image for a specific slot
void updateSpecificScaledScreen(int slotIndex) {
    PImage sourceImg = slotImages_Original[slotIndex];

    if (sourceImg == null) {
        slotImages_Scaled[slotIndex] = null; // no source image, so no scaled image for this slot
        return;
    }

    // target dimensions for the slot (assuming square slots based on scaledImageWidth)
    float targetSlotWidth = scaledImageWidth;
    float targetSlotHeight = scaledImageWidth;

    // calculate scale factor to fit the image within the slot while maintaining aspect ratio
    float scaleFactor = min(targetSlotWidth / sourceImg.width, targetSlotHeight / sourceImg.height);

    int newWidth = int(sourceImg.width * scaleFactor);
    int newHeight = int(sourceImg.height * scaleFactor);

    slotImages_Scaled[slotIndex] = sourceImg.copy(); // work on a copy
    slotImages_Scaled[slotIndex].resize(newWidth, newHeight); // resize it
    
}

// display a set number from the images collected
void displayRecentScreens() {
    boolean mouseOverAnyImage = false;

	// iterate through fixed display slots
    for (int i = 0; i < numDisplaySlots; i++) {
		// get pre-scaled image for this slot
        PImage displayImg = slotImages_Scaled[i];

        // calculate position for this slot. scaledImageWidth is from setupUI().
        float x = padding + i * (scaledImageWidth + padding);
        float y = padding; 


        if (displayImg != null && displayImg.width > 0 && displayImg.height > 0) {
            float w = displayImg.width;
            float h = displayImg.height;

            slotBounds[i].setBounds((int)x, (int)y, (int)w, (int)h);

            strokeWeight(borderWeight); stroke(0); noFill();
            rect(x - borderWeight / 2, y - borderWeight / 2, w + borderWeight, h + borderWeight);
            image(displayImg, x, y);

            boolean isOverThisImage = (mouseX > x && mouseX < x + w && mouseY > y && mouseY < y + h && mouseOver);
            if (isOverThisImage) {
                mouseOverAnyImage = true; 
                noStroke(); 
                fill(50, 255, 50, 40); 
                rect(x, y, w, h);
            }

            // animation check for saving: use animatingSaveForSlot
            if (savedAnimation > 0 && i == animatingSaveForSlot) { 
                float alpha = map(savedAnimation, 0, 90, 0, 230); 
                noStroke();
                textMode(SHAPE);
                fill(0, 200, 0, alpha * 0.3);
                rect(x, y, w, h);
                fill(255, alpha); 
                textAlign(CENTER, CENTER); 
                textSize(min(w, h) * 0.2f); 
                text("SAVED", x + w/2, y + h/2);
                textMode(MODEL);
            }
        } else {
            // no image for this slot, or image has invalid dimensions.
            // ensure bounds are cleared so it's not accidentally interactive
            if (i < slotBounds.length) { // should always be true here
                 slotBounds[i].setBounds(0, 0, 0, 0);
            }
            // draw placeholder for empty/failed slots
            rect(x, y, scaledImageWidth, scaledImageWidth);
        }
    }

    if (mouseOverAnyImage) cursor(handCursor); else cursor(defaultCursor);
    
    if (savedAnimation > 0) {
        savedAnimation--;
    } else {
        animatingSaveForSlot = -1; // reset when animation is done
    }
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

// display all the graph and the border around their area
public void drawGraphsArea() {
	// display the graphs
	for (int i = 0; i < graphs.size(); i++) {
		// get and display graph
		Graph g = graphs.get(i);
		g.display();
	}

	// draw the border
	noFill();
	stroke(0);
	strokeWeight(borderWeight); // use same weight as debug border
	rect(graphAreaX, graphAreaY, graphAreaWidth, graphAreaHeight); 
}


// display function to show debug info in a table
public void displayDebugInfo() {
    if (debugInfo == null || debugInfo.isEmpty()) return;

    // calculate table position and size dynamically
    float tableStartX = padding - 1; // start padding pixels from left edge, add pixel 
    // start padding below the screenshot area
    float tableStartY = screenshotAreaBottomY + padding;
    // calculate width dynamically to stretch to graph area start (minus padding)
    float totalTableWidth = graphAreaX - 2 * padding + 1; // add pixel
    if (totalTableWidth < 0) totalTableWidth = 0; // prevent negative width
    // use the available vertical space for the table's height
    float availableTableHeight = height - tableStartY - padding;

    // calculate dynamic internal column sizes
    float internalPadding = padding; // use same padding inside table
    float usableWidth = totalTableWidth - 3 * internalPadding; // width available for key/value text
    float dynamicKeyWidth = usableWidth * 0.6f; // key column gets 60% of usable width
    float dynamicValueX = tableStartX + internalPadding + dynamicKeyWidth + internalPadding; // x position where value column starts
    if (usableWidth <= 0) { // handle case where table is too narrow
        dynamicKeyWidth = 0;
        dynamicValueX = tableStartX + internalPadding;
    }

    // text and drawing setup
    fill(0);
    textAlign(LEFT, TOP);
    textSize(20); // keep font size fixed for now

    // get keys for display and sort them alphabetically
    ArrayList<String> keys = new ArrayList<String>(debugInfo.keySet());
    java.util.Collections.sort(keys);

    // draw table header text
    float headerTextY = tableStartY + internalPadding; // text starts padding down from table top
    text("Key", round(tableStartX) + internalPadding, headerTextY); // key text position
    text("Value", round(dynamicValueX), headerTextY); // value text position (dynamic)

    // draw header underline (position below header text)
    stroke(0);
    strokeWeight(1); // use consistent stroke weight
	float headerLineY = headerTextY + 20 + 5; // place line below text with padding
    line(tableStartX, headerLineY, tableStartX + totalTableWidth, headerLineY); // draw the line

    // draw vertical separator line based on dynamic key width
    float separatorX = tableStartX + internalPadding + dynamicKeyWidth; // dynamic x pos of line
    // use available height for the line's extent
    line(separatorX, tableStartY, separatorX, tableStartY + availableTableHeight);

    // draw key/value rows
    for (int i = 0; i < keys.size(); i++) {
        String key = keys.get(i);
        Object value = debugInfo.get(key);
        String displayValue = formatDisplayValue(value); // use helper function for clarity

        // calculate Y position for this row's text
        // Start rows below the header line plus some padding
		float rowTextY = headerLineY + internalPadding + (i * debugRowHeight);
        // only draw if row fits within available height
        if (rowTextY + debugRowHeight < tableStartY + availableTableHeight - internalPadding) {
            text(key, round(tableStartX) + internalPadding, rowTextY); // key text position
            text(displayValue, round(dynamicValueX), rowTextY); // value text position (dynamic)
        } else {
            break; // stop drawing if rows exceed available height
        }
    }

    // draw table border using dynamic width and available height
    noFill();
    stroke(0);
    strokeWeight(borderWeight); // use consistent border weight
    rect(round(tableStartX), tableStartY, totalTableWidth, availableTableHeight);
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
    if (slotBounds != null && slotImageFiles != null) {
		// iterate through slots
        for (int i = 0; i < numDisplaySlots; i++) {
            if (slotBounds[i] != null && slotBounds[i].width > 0 && slotBounds[i].contains(mouseX, mouseY)) {
				// get file from clicked slot
                File fileToSave = slotImageFiles[i];

				// save screenshot to 'saved' folder, play animation
                if (fileToSave != null) {
                    saveScreenshot(fileToSave);
                    savedAnimation = 90;        // duration
                    animatingSaveForSlot = i;   // set slot to animate
                }
				// exit after handling click for one image
                return;
            }
        }
    }
}

    
// when the mouse exits the window
public void mouseExited() {
	mouseOver = false;
	cursor(defaultCursor);
}

// when the mouse enters the window
public void mouseEntered() {
	mouseOver = true;
}