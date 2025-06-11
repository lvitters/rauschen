// drawn shader names table below debug table, or where the debug table would have started
public void displayShaderNamesList(float tableX, float tableY, float tableWidth, float internalPadding) {
    if (shaderNames == null || shaderNames.isEmpty()) {
        return; // return if there's nothing to show (original comment adapted)
    }
    
    // critical check: soloStates and muteStates should not be null at this point.
    // Their initialization and sizing are handled by initializeShaderControls() in setup()
    // and critically by updateSharedShaderDataFromOSC() when OSC messages arrive.
    if (soloStates == null || muteStates == null) {
        if (printDebug) println("displayShaderNamesList(): FATAL ERROR: soloStates or muteStates are null!");
        return; 
    }

    // Critical check: Array lengths must match shaderNames.size().
    // If they don't, the synchronized update logic has failed.
    if (soloStates.length != shaderNames.size() || muteStates.length != shaderNames.size()) {
        if (printDebug) println("displayShaderNamesList(): CRITICAL ERROR: mismatch in array sizes!");
        return; // avoid drawing with inconsistent data to prevent IndexOutOfBoundsException
    }

    // clear button bounds at the start of each redraw of this list
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
    float actionsColumnProportion = 0.2f; // example: 20% for the actions column (adjust as needed)
    
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
    float headerTextY_shaders = tableY + internalPadding + 3;
    text("shaders", tableX + internalPadding, headerTextY_shaders);
    text("actions", actionsColContentStartX + 2, headerTextY_shaders);
    
    stroke(0);
    strokeWeight(1);
    float headerLineY_shaders = headerTextY_shaders + 20 + 5; // Y position of the underline (original comment)
    line(tableX, headerLineY_shaders, tableX + tableWidth, headerLineY_shaders); 

    // draw vertical separator line only if there's height for it
    if (availableHeightForShaders > (headerLineY_shaders - tableY)) { // ensure separator doesn't draw over header if space is tight
        line(separatorLineX, tableY, separatorLineX, tableY + availableHeightForShaders);
    }

    // draw shader names rows
    // (shaderNames.size() > 0 is already confirmed by the initial check if we reach here)
    for (int i = 0; i < shaderNames.size(); i++) {
        String displayName = shaderNames.get(i); // Safe due to loop condition
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
        // accessing soloStates[i] - safe due to earlier length checks
        fill(soloStates[i] ? color(0, 150, 50) : color(170, 170, 170)); 
        rect(currentSoloBound.x, currentSoloBound.y, currentSoloBound.width, currentSoloBound.height); 
        
        fill(soloStates[i] ? color(255) : color(0)); // safe
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
        // accessing muteStates[i] - safe due to earlier length checks
        fill(muteStates[i] ? color(255, 100, 100) : color(170, 170, 170)); 
        rect(currentMuteBound.x, currentMuteBound.y, currentMuteBound.width, currentMuteBound.height); 
        
        fill(muteStates[i] ? color(255) : color(0)); // safe
        text("MUTE", currentMuteBound.x + currentMuteBound.width / 2, currentMuteBound.y + currentMuteBound.height / 2);
        
        textSize(textSize); // reset global/default textSize
        textAlign(LEFT, TOP); // reset textAlign
        
        fill(0); // reset fill color (original comment adapted)
    }

    // draw shader names table border (original comment)
    noFill();
    stroke(0);
    strokeWeight(borderWeight); // borderWeight is a global from your setupUI
    rect(tableX, tableY, tableWidth, availableHeightForShaders);
}

// update shader names synchronously with OSC messages
void updateSharedShaderDataFromOSC() {
    if (newShaderDataFromOSC) { // quick check before locking
        List<String> tempNewNames = new ArrayList<String>();
        boolean actuallyProcessUpdate = false;

        synchronized (shaderDataLock) {
            if (newShaderDataFromOSC) { // double-check inside lock
                tempNewNames.addAll(incomingShaderNames_staging);
                newShaderDataFromOSC = false; // reset flag immediately
                actuallyProcessUpdate = true;
            }
        }

        if (actuallyProcessUpdate) {
            // update the main lists. This part modifies data read by draw() and mousePressed().
            // To ensure atomicity of this update block relative to other uses,
            // we could re-acquire the lock, or ensure this method completes before other uses.
            // For simplicity, this block will update the main data structures.
            
            boolean listStructureChanged = false;
            if (shaderNames.size() != tempNewNames.size()) {
                listStructureChanged = true;
            } else {
                for (int i = 0; i < shaderNames.size(); i++) {
                    if (!shaderNames.get(i).equals(tempNewNames.get(i))) {
                        listStructureChanged = true;
                        break;
                    }
                }
            }

            if (listStructureChanged) {
                shaderNames.clear();
                shaderNames.addAll(tempNewNames);

                // CRITICAL: re-initialize soloStates and muteStates based on the new shaderNames
                int numShaders = shaderNames.size();
                soloStates = new boolean[numShaders]; // all false by default
                muteStates = new boolean[numShaders]; // all false by default

                // reset currentShaderChoice if it's now out of bounds
                if (currentShaderChoice >= numShaders) {
                    currentShaderChoice = (numShaders > 0) ? 0 : -1; // select first or none
                }
            }
        }
    }
}

// init shader control states
void initializeShaderControls() {
    synchronized(shaderDataLock) { // lock for consistency if called from multiple places
        if (shaderNames == null) { // should be initialized globally
            shaderNames = new ArrayList<String>(); 
        }

        int numShaders = shaderNames.size();

        // initialize or resize state arrays if they don't match.
        // this will typically run to create them based on the initial shaderNames list (e.g. with a placeholder).
        if (soloStates == null || soloStates.length != numShaders) {
            soloStates = new boolean[numShaders]; 
        }
        if (muteStates == null || muteStates.length != numShaders) {
            muteStates = new boolean[numShaders];
        }

        if (soloButtonBounds == null) soloButtonBounds = new ArrayList<Rectangle>();
        if (muteButtonBounds == null) muteButtonBounds = new ArrayList<Rectangle>();
    }
}

// determine active shader indices based on solo/mute states
ArrayList<Integer> getActiveShaderIndices() {
	ArrayList<Integer> activeIndices = new ArrayList<Integer>();
    
    synchronized (shaderDataLock) { // lock to ensure consistent read of shaderNames and states
        if (shaderNames == null || soloStates == null || muteStates == null || 
            soloStates.length != shaderNames.size() || muteStates.length != shaderNames.size()) {
            if (printDebug) println("getActiveShaderIndices(): error: state arrays not initialized or mismatch with shaderNames size.");
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
    } // end synchronized block
    return activeIndices;
}