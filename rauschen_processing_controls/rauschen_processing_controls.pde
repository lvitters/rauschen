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

// init font
PFont font;

// init ArrayList of graphs
ArrayList<Graph> graphs = new ArrayList<Graph>();
// number of historical points to show in each graph
int graphLength = 600;

// HashMap to store debugInfo values
HashMap<String, Object> debugInfo = new HashMap<String, Object>();

// print debug messages or not (this is different from the debug info table);
Boolean printDebug = false;

// store the shaders names for display
ArrayList<String> shaderNames = new ArrayList<String>();
int currentShaderChoice = -1;

// screenshot gallery
int numDisplaySlots = 4; 			// number of fixed display slots
int nextSlotIndexToUpdate;			// next slot to update
PImage[] slotImages_Original;    	// original, unscaled PImage for each display slot
PImage[] slotImages_Scaled;      	// PImage scaled for display for each slot
File[] slotImageFiles;         		// File object for image in each slot
Rectangle[] slotBounds;          	// display bounds for each slot
File lastSuccessfullyPlacedCandidateFile = null; // newest candidate file last successfully placed
PImage[] tempRecentScreens; 		// background loading for loadScreensInBackground 
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
final int GLOBAL_MOUSE_OFFSET_X = 6;
final int GLOBAL_MOUSE_OFFSET_Y = 9;
float padding = 10;
float borderWeight = 1;
int textSize = 16;
// debug table
float debugRowHeight = 20;
// bounds for the graph display area determined at runtime
float graphAreaX;
float graphAreaY;
float graphAreaWidth;
float graphAreaHeight;
float graphInternalPadding = 10;
// solo/mute buttons
boolean[] soloStates; // tracks solo state for each shader
boolean[] muteStates; // tracks mute state for each shader
// store bounds for clickable solo/mute buttons
ArrayList<Rectangle> soloButtonBounds = new ArrayList<Rectangle>();
ArrayList<Rectangle> muteButtonBounds = new ArrayList<Rectangle>();
float shaderButtonWidth = 50;
float shaderButtonSpacing = 12; 	// spacing around buttons

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
	font = createFont("assets/CommitMono-400-Regular.otf", 128);
	textFont(font);

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
	defaultCursor = loadImage("assets/default.png");
	handCursor = loadImage("assets/pointer.png");

	// init shader controls
	if (shaderNames.isEmpty()) {
        shaderNames.add("placeholder");		// if other sketch isn't running
    }
    initializeShaderControls();
}

public void draw() {
	background(170, 170, 170);

	checkForRecentScreens();
	// load new screens once every X frames in background thread
	if (frameCount % 10 == 0 && !isLoadingScreens && !newScreensReady) {
		isLoadingScreens = true; // set flag to indicate loading has started
		thread("loadScreensInBackground");
	}

	displayRecentScreens();
	displayGraphsArea();
	displayInfoTables();
}

// setup areas and dimensions for screenshots, debugInfo and graphsArea
public void setupUI() {

	// screenshot gallery
	slotImages_Original = new PImage[numDisplaySlots];
    slotImages_Scaled = new PImage[numDisplaySlots];
    slotImageFiles = new File[numDisplaySlots];
    slotBounds = new Rectangle[numDisplaySlots];
	// init Rectangle objects
    for (int i = 0; i < numDisplaySlots; i++) {
        slotBounds[i] = new Rectangle();
    }

	// init next slot index for right-to-left rotation
    nextSlotIndexToUpdate = numDisplaySlots - 1;

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

        File currentTopCandidateFile = tempFiles[0];
        PImage currentTopCandidateImage = tempRecentScreens[0];
        
        // is file different from file that last successfully triggered an update?
        if (currentTopCandidateFile.equals(lastSuccessfullyPlacedCandidateFile)) {
            newScreensReady = false; 
            return;
        }

        // is it not already displayed in another slot?
        boolean alreadyDisplayed = false;
        for (int j = 0; j < numDisplaySlots; j++) {
            if (slotImageFiles[j] != null && slotImageFiles[j].equals(currentTopCandidateFile)) {
                alreadyDisplayed = true;
                break;
            }
        }

        if (alreadyDisplayed) {
            lastSuccessfullyPlacedCandidateFile = currentTopCandidateFile; // acknowledge it's current top, even if displayed
            newScreensReady = false; 
            return;
        }

		// set target to rotating index
        int targetSlotIndex = nextSlotIndexToUpdate;

        // place the new image into the determined target slot
        slotImages_Original[targetSlotIndex] = currentTopCandidateImage;
        slotImageFiles[targetSlotIndex] = currentTopCandidateFile;
        updateSpecificScaledScreen(targetSlotIndex); 
        lastSuccessfullyPlacedCandidateFile = currentTopCandidateFile;

        // update nextSlotIndexToUpdate for the next cycle (right to left rotation)
        nextSlotIndexToUpdate = (nextSlotIndexToUpdate - 1 + numDisplaySlots) % numDisplaySlots;

        newScreensReady = false; 
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
			if (printDebug) println("loadScreensInBackground(): created screenshots directory: " + screensDir);
		} else {
			// handle error if directory creation fails
			if (printDebug) println("loadScreensInBackground(): error: failed to create screenshots directory: " + screensDir);
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
		if (printDebug) println("loadScreensInBackground(): warning: listFiles returned null for " + screensDir);
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
					if (printDebug) println("loadScreensInBackground(): warning (background): loadImage returned null for " + foundFiles[i].getName());
				}
			} catch (Exception e) {
				// catch potential errors during image loading
				if (printDebug) println("loadScreensInBackground(): error loading image in background " + foundFiles[i].getName() + ": " + e.getMessage());
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
                fill(255, 255, 255, alpha * 0.6);
                rect(x, y, w, h);
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
			// line from top-left to bottom-right
            line(x, y, x + scaledImageWidth, y + scaledImageWidth);
            // line from top-right to bottom-left
            line(x + scaledImageWidth, y, x, y + scaledImageWidth);
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
		
		// println("saveScreenshot(): saved screenshot: " + sourceFile.getName() + " to " + destFile.getAbsolutePath());
		
	} catch (Exception e) {
		if (printDebug) println("saveScreenshot(): error saving screenshot: " + e.getMessage());
		e.printStackTrace();
	}
}

// display all the graph and the border around their area
public void displayGraphsArea() {
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
public void displayInfoTables() {

    float tableStartX = padding - 1;
    float currentTopY = screenshotAreaBottomY + padding; // initial Y position for the first table
    float totalTableWidth = graphAreaX - 2 * padding + 1;
    if (totalTableWidth < 0) totalTableWidth = 0;
    float internalPadding = padding; // use consistent padding

    // debug info table
    if (debugInfo != null && !debugInfo.isEmpty()) {
        // calculate dynamic internal column sizes for Debug Table
        float usableWidth = totalTableWidth - 3 * internalPadding; // width available for key/value text
        float dynamicKeyWidth = usableWidth * 0.6f; // key column gets 60% of usable width
        float dynamicValueX = tableStartX + internalPadding + dynamicKeyWidth + internalPadding; // x position where value column starts
        if (usableWidth <= 0) { // handle case where table is too narrow
            dynamicKeyWidth = 0;
            dynamicValueX = tableStartX + internalPadding;
        }

        fill(0);
        textAlign(LEFT, TOP);
        textSize(textSize); // adjust text size for better fit

        ArrayList<String> keys = new ArrayList<String>(debugInfo.keySet());
        java.util.Collections.sort(keys);

        // calculate debug table height
        float headerTextY_debug = currentTopY + internalPadding;
        float headerHeight_debug = (headerTextY_debug - currentTopY) + 20 + 5; // height of header text area + line spacing

        float rowsHeight_debug = 0;
        if (!keys.isEmpty()) {
            rowsHeight_debug = internalPadding + (keys.size() * debugRowHeight); // padding above rows + all rows
        }

        // total internal content height + bottom padding
        float requiredDebugContentHeight = headerHeight_debug + rowsHeight_debug + internalPadding;

        // if no keys, adjust required height to be just header + bottom padding
        if (keys.isEmpty()) {
            requiredDebugContentHeight = headerHeight_debug + internalPadding;
        }
        
        float maxPossibleHeightForDebug = height - currentTopY - padding; // max space it *could* take from currentTopY
        float actualDebugTableHeight = min(requiredDebugContentHeight, maxPossibleHeightForDebug);
        if (actualDebugTableHeight < 0) actualDebugTableHeight = 0;

        // draw debug table header
        text("key", round(tableStartX) + internalPadding, headerTextY_debug);
        text("value", round(dynamicValueX), headerTextY_debug);

        stroke(0);
        strokeWeight(1);
        float headerLineY_debug = headerTextY_debug + 20 + 5; // Y position of the underline
        line(tableStartX, headerLineY_debug, tableStartX + totalTableWidth, headerLineY_debug);

        // draw vertical separator line for debug table
        float separatorX = tableStartX + internalPadding + dynamicKeyWidth;
        if (actualDebugTableHeight > 0) { // only draw if table has height
            line(separatorX, currentTopY, separatorX, currentTopY + actualDebugTableHeight);
        }

        // draw debug table key/value rows ---
        for (int i = 0; i < keys.size(); i++) {
            String key = keys.get(i);
            Object value = debugInfo.get(key);
            String displayValue = formatDisplayValue(value);

            float rowTextY = headerLineY_debug + internalPadding + (i * debugRowHeight);
            // check if the row fits within the calculated actual height of the debug table (inside its border)
            if (rowTextY + debugRowHeight <= currentTopY + actualDebugTableHeight - internalPadding) {
                text(key, round(tableStartX) + internalPadding, rowTextY);
                text(displayValue, round(dynamicValueX), rowTextY);
            } else {
                break; // stop drawing if rows exceed allocated height
            }
        }

        // draw debug table border
        if (actualDebugTableHeight > 0) {
            noFill();
            stroke(0);
            strokeWeight(borderWeight);
            rect(round(tableStartX), currentTopY, totalTableWidth, actualDebugTableHeight);
        }
        
        // update currentTopY for the next table, adding padding if the debug table was drawn
        if (actualDebugTableHeight > 0) {
            currentTopY += actualDebugTableHeight + padding;
        } else {
            // if debug table had no height (e.g., no keys and error in calc)
            // still ensure shader table starts correctly
            // this case should ideally not happen with correct height calculation
        }

    }

    // shader names table at `currentTopY` variable
    displayShaderNamesList(tableStartX, currentTopY, totalTableWidth, internalPadding);
}

// drawn shader names table below debug table, or where the debug table would have started
public void displayShaderNamesList(float tableX, float tableY, float tableWidth, float internalPadding) {
    if (shaderNames == null || shaderNames.isEmpty()) {
        // return if there's nothing to show
        return;
    }
    
    // ensure states are initialized
    if (soloStates == null || muteStates == null || 
        soloStates.length != shaderNames.size() || muteStates.length != shaderNames.size()) {
        initializeShaderControls(); 
        if (soloStates == null || muteStates == null || 
            soloStates.length != shaderNames.size() || muteStates.length != shaderNames.size()) {
            if (printDebug) println("displayShaderNamesList(): error: mismatch in shaderNames and solo/mute state array sizes. aborting displayShaderNamesList.");
            return;
        }
    }

    soloButtonBounds.clear();
    muteButtonBounds.clear();

    // calculate height available for shader names table (remaining space on screen)
    float availableHeightForShaders = height - tableY - padding; // 'padding' is a global from your setupUI
    if (availableHeightForShaders <= internalPadding * 2 + 20 + 5) { // not enough space for header and minimal content
         return; // no space to draw meaningfully
    }

    // define column widths with a simpler proportional approach
    // usableWidthForShaderList is the total space for the content of both columns, 
    // after accounting for the table's side paddings and the padding between columns.
    float usableWidthForShaderList = tableWidth - (2 * internalPadding) - internalPadding; // effectively tableWidth - 3 * internalPadding
    if (usableWidthForShaderList < 0) usableWidthForShaderList = 0;

    // define the proportion of the usable width for the "Actions" column.
    float actionsColumnProportion = 0.2f; // example: 35% for the actions column
    
    float proposedActionsColContentWidth = usableWidthForShaderList * actionsColumnProportion;

    // calculate the minimum width required to just show the buttons + a small bit of padding
    float buttonsActualCombinedWidth = (shaderButtonWidth * 2) + shaderButtonSpacing;
    float minWidthForButtonsAndMinimalPadding = buttonsActualCombinedWidth + 4; // e.g., 2px padding on each side of button group

    // the actions column content width will be the larger of the two:
    // either what the proportion gives it, or what's minimally needed for buttons.
    // this ensures buttons are never cut off if the proportion is too small.
    float actionsColContentWidth = max(proposedActionsColContentWidth, minWidthForButtonsAndMinimalPadding);
    
    // shader name column takes the remaining usable width
    float shaderNameColContentWidth = usableWidthForShaderList - actionsColContentWidth;
    
    // final safety check: if calculations made shaderNameColContentWidth negative, adjust.
    if (shaderNameColContentWidth < 0) {
        shaderNameColContentWidth = 0;
        // and ensure actions column doesn't exceed total usable width in this edge case
        actionsColContentWidth = usableWidthForShaderList; 
    }
    
    // X position for the start of the content of the 'Actions' column
    float actionsColContentStartX = tableX + internalPadding + shaderNameColContentWidth + internalPadding;
    // vertical separator line position
    float separatorLineX = actionsColContentStartX - internalPadding / 2;

    fill(0); 
    textAlign(LEFT, TOP); 
    textSize(textSize); // consistent text size

    // draw shader names table header (adapted for two columns)
    float headerTextY_shaders = tableY + internalPadding;
    text("shaders", tableX + internalPadding, headerTextY_shaders);
    text("actions", actionsColContentStartX, headerTextY_shaders);
    
    stroke(0);
    strokeWeight(1);
    float headerLineY_shaders = headerTextY_shaders + 20 + 5; // Y position of the underline (original comment)
    line(tableX, headerLineY_shaders, tableX + tableWidth, headerLineY_shaders); 

    if (availableHeightForShaders > 0) { 
        line(separatorLineX, tableY, separatorLineX, tableY + availableHeightForShaders);
    }

    // draw shader names rows
    for (int i = 0; i < shaderNames.size(); i++) {
        String displayName = shaderNames.get(i);
        float rowContentY = headerLineY_shaders + internalPadding + (i * debugRowHeight); 
        float buttonDrawY_float = rowContentY; 

        if (rowContentY + debugRowHeight > tableY + availableHeightForShaders - internalPadding) {
            break; // stop drawing if rows exceed available height (original comment)
        }
        
        // shader name (column 1)
        float shaderNameTextX = tableX + internalPadding;
        textAlign(LEFT, CENTER); 
        float shaderNameCenterY = rowContentY + debugRowHeight / 2; 

        if (i == currentShaderChoice) {
            // highlight the current shader choice with different text color (original comment)
            fill(20, 150, 20); // A distinct green color (original comment)
            text("> " + displayName + " <", shaderNameTextX + 5, shaderNameCenterY); // add arrows and indent (original comment)
            fill(0); // reset fill color for subsequent items or tables (original comment)
        } else {
            fill(0); 
            text(displayName, shaderNameTextX, shaderNameCenterY);
        }
        textAlign(LEFT, TOP); // reset textAlign

        // actions (S/M Buttons in column 2)
        // buttonsGroupOffsetX will center the buttons within the actionsColContentWidth
        float buttonsGroupOffsetX = (actionsColContentWidth - buttonsActualCombinedWidth) / 2;
        if (buttonsGroupOffsetX < 0) buttonsGroupOffsetX = 0; // prevent negative offset if column is very narrow

        float soloButtonActualX_float = actionsColContentStartX + buttonsGroupOffsetX;
        float muteButtonActualX_float = soloButtonActualX_float + shaderButtonWidth + shaderButtonSpacing;

        int roundedButtonDrawY = Math.round(buttonDrawY_float);
        int roundedButtonHeight = Math.round(debugRowHeight); 
        int roundedShaderButtonControlWidth = Math.round(shaderButtonWidth);
        
        int roundedSoloButtonActualX = Math.round(soloButtonActualX_float);
        int roundedMuteButtonActualX = Math.round(muteButtonActualX_float);

        // solo button
        Rectangle currentSoloBound = new Rectangle(
            roundedSoloButtonActualX, roundedButtonDrawY, 
            roundedShaderButtonControlWidth, roundedButtonHeight 
        );
        soloButtonBounds.add(currentSoloBound);
        
        stroke(0); 
        strokeWeight(1);
        fill(soloStates[i] ? color(0, 150, 50) : color(170, 170, 170)); 
        rect(currentSoloBound.x, currentSoloBound.y, currentSoloBound.width, currentSoloBound.height); 
        
        fill(soloStates[i] ? color(255) : color(0)); 
        textAlign(CENTER, CENTER);
        textSize(roundedButtonHeight * 0.60f); 
        text("SOLO", currentSoloBound.x + currentSoloBound.width / 2, currentSoloBound.y + currentSoloBound.height / 2);
        
        // mute button
        Rectangle currentMuteBound = new Rectangle(
            roundedMuteButtonActualX, roundedButtonDrawY, 
            roundedShaderButtonControlWidth, roundedButtonHeight
        );
        muteButtonBounds.add(currentMuteBound); 

        stroke(0); 
        strokeWeight(1);
        fill(muteStates[i] ? color(255, 100, 100) : color(170, 170, 170)); 
        rect(currentMuteBound.x, currentMuteBound.y, currentMuteBound.width, currentMuteBound.height); 
        
        fill(muteStates[i] ? color(255) : color(0)); 
        text("MUTE", currentMuteBound.x + currentMuteBound.width / 2, currentMuteBound.y + currentMuteBound.height / 2);
        
        textSize(textSize); 
        textAlign(LEFT, TOP); 
        
        fill(0); 
    }

    // draw shader names table border (original comment)
    noFill();
    stroke(0);
    strokeWeight(borderWeight); // borderWeight is a global from your setupUI
    rect(tableX, tableY, tableWidth, availableHeightForShaders);
}

// init shader control states
void initializeShaderControls() {
    if (shaderNames == null) {
        // this case should ideally be avoided by ensuring shaderNames is populated first.
        if (printDebug) println("initializeShaderControls(): warning: shaderNames is null during initializeShaderControls. initializing as empty.");
        shaderNames = new ArrayList<String>(); 
    }

    int numShaders = shaderNames.size();

    // initialize or resize state arrays if needed
    // this ensures that if shaderNames were to be repopulated with a different size,
    // these arrays would be correctly sized. given shaderNames is static at runtime
    // after initial population, this will effectively run once for sizing.
    if (soloStates == null || soloStates.length != numShaders) {
        soloStates = new boolean[numShaders]; // all false by default (not soloed)
    }
    if (muteStates == null || muteStates.length != numShaders) {
        muteStates = new boolean[numShaders]; // all false by default (not muted)
    }

    // button bounds lists will be cleared and repopulated in displayShaderNamesList,
    // so no need to size them here, just ensure they are not null.
    if (soloButtonBounds == null) soloButtonBounds = new ArrayList<Rectangle>();
    if (muteButtonBounds == null) muteButtonBounds = new ArrayList<Rectangle>();
    
    if (printDebug) ("initializeShaderControls(): shader controls initialized for " + numShaders + " shaders.");
}

// determine active shader indices based on solo/mute states
ArrayList<Integer> getActiveShaderIndices() {
    ArrayList<Integer> activeIndices = new ArrayList<Integer>();
    if (shaderNames == null || soloStates == null || muteStates == null || 
        soloStates.length != shaderNames.size() || muteStates.length != shaderNames.size()) {
        if (printDebug) ("getActiveShaderIndices(): error: cannot get active shader indices, states not initialized correctly or mismatch with shaderNames size.");
        return activeIndices; // return empty list
    }

    boolean anySoloActive = false;
    for (int i = 0; i < shaderNames.size(); i++) {
        if (soloStates[i]) {
            anySoloActive = true;
            break;
        }
    }

    if (anySoloActive) {
        for (int i = 0; i < shaderNames.size(); i++) {
            if (soloStates[i]) { // only soloed shaders are active
                activeIndices.add(i);
            }
        }
    } else { // no solos active, so consider mutes
        for (int i = 0; i < shaderNames.size(); i++) {
            if (!muteStates[i]) { // add if not muted
                activeIndices.add(i);
            }
        }
    }
    return activeIndices;
}

// helper function to format debug values (keeps displayInfoTables cleaner)
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

// fire if mouse was pressed
void mousePressed() {
    // adjust mouse coordinates for global offset
    int adjustedMouseX = mouseX - GLOBAL_MOUSE_OFFSET_X;
    int adjustedMouseY = mouseY - GLOBAL_MOUSE_OFFSET_Y;

    boolean stateChanged = false; 

    // handle Solo/Mute button clicks using ADJUSTED coordinates
    if (soloButtonBounds != null && muteButtonBounds != null && 
        soloStates != null && muteStates != null && 
        shaderNames != null && !shaderNames.isEmpty()) {

        for (int i = shaderNames.size() - 1; i >= 0; i--) { // iterate backwards for potential UI overlap
            // check Mute buttons using adjusted coordinates
            if (i < muteButtonBounds.size() && muteButtonBounds.get(i).contains(adjustedMouseX, adjustedMouseY)) {
                muteStates[i] = !muteStates[i];
                if (muteStates[i]) { 
                    soloStates[i] = false; 
                }
                stateChanged = true;
                break; 
            }

            // check Solo buttons using adjusted coordinates
            if (i < soloButtonBounds.size() && soloButtonBounds.get(i).contains(adjustedMouseX, adjustedMouseY)) {
                soloStates[i] = !soloStates[i];
                if (soloStates[i]) { 
                    muteStates[i] = false; 
                }
                stateChanged = true;
                break; 
            }
        }

        if (stateChanged) {
            sendActiveShaderList(); 
        }
    }

    // screenshot save logic
    if (!stateChanged && slotBounds != null && slotImageFiles != null) {
        for (int i = 0; i < numDisplaySlots; i++) {
            // adjusted coordinates for checking screenshot slot bounds
            if (slotBounds[i] != null && slotBounds[i].width > 0 && slotBounds[i].contains(adjustedMouseX, adjustedMouseY)) { // MODIFIED
                File fileToSave = slotImageFiles[i];
                if (fileToSave != null) {
                    saveScreenshot(fileToSave);
                    savedAnimation = 90;        
                    animatingSaveForSlot = i;   
                }
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

// listen to key presses
void keyPressed() {
	// print (more) debug info
	if (key == 'p') {
		printDebug = !printDebug;
	}
}