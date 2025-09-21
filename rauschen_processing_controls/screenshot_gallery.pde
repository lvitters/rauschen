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
		slotIsSaved[targetSlotIndex] = false;
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

			// display image
            strokeWeight(borderWeight); stroke(0); noFill();
            rect(x - borderWeight / 2, y - borderWeight / 2, w + borderWeight, h + borderWeight);
            image(displayImg, x, y);

			// saved label
			String savedLabel = "SAVE";
			float labelTextSize = constrain(h * 0.06f, 20, 28);
			
			// padding around the text within its background box, relative to text size
			float labelPadding = textSize * 0.5f;

			// set text properties for measuring and drawing
			// textFont(font); // assuming 'font' is already set globally as desired
			textSize(textSize + 2);
			textAlign(LEFT, TOP); // align text to the top-left

			// calculate width
			float labelTextWidth = textWidth(savedLabel);
			// for height, with textAlign(LEFT, TOP), textSize is a good approximation
			float labelTextHeight = debugRowHeight; 

			// define background box properties
			float boxX = x; // position the box at the screenshot's top-left X
			float boxY = y; // position the box at the screenshot's top-left Y
			float boxWidth = labelTextWidth + (labelPadding * 3);
			float boxHeight = labelTextHeight + (labelPadding * 2);

			// when hovering over
            boolean isOverThisImage = (mouseX > x && mouseX < x + w && mouseY > y && mouseY < y + h && mouseOver && !slotIsSaved[i]);
            if (isOverThisImage) {

				// image overlay 
                noStroke(); 
                fill(0, 150, 50, 20); 	// background grey
                rect(x, y, w, h);

				// draw the background box for the label
				stroke(0); // set the border color
				strokeWeight(borderWeight);
                fill(170, 170, 170); // background grey
                // aligning with image edge
                rect(boxX + 5, boxY + 5, boxWidth + 10, boxHeight);
                // draw "SAVED" text
                fill(0);
                // position text inside box, accounting for padding
                text(savedLabel, boxX + 12 + labelPadding, boxY + 9 + labelPadding);	// font is slightly off so add more here
            }

			// check if the image in this slot is marked as saved
            if (slotIsSaved != null && i < slotIsSaved.length && slotIsSaved[i]) {
				savedLabel = "SAVED";
				labelTextWidth = textWidth(savedLabel);
				boxWidth = labelTextWidth + (labelPadding * 2);
                // draw the background box for the label
                fill(0, 150, 50); // green from solo button
                // aligning with image edge
                rect(boxX + 5, boxY + 5, boxWidth + 15, boxHeight);
                // draw "SAVED" text
                fill(255);
                // position text inside box, accounting for padding
                text(savedLabel, boxX + 12 + labelPadding, boxY + 9 + labelPadding);	// font is slightly off so add more here
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