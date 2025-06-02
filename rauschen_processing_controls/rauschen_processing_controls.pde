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
boolean[] slotIsSaved;				// which slots have been saved
File lastSuccessfullyPlacedCandidateFile = null; // newest candidate file last successfully placed
PImage[] tempRecentScreens; 		// background loading for loadScreensInBackground 
File[] tempFiles; 
String screensDir = "../rauschen_screens/temp/";
String savedScreensDir = "../rauschen_screens/saved/";
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
	slotIsSaved = new boolean[numDisplaySlots];
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
                    slotIsSaved[i] = true;
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