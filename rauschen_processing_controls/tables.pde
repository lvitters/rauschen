// display function to show debug info in a table
public void displayInfoTables() {

    float tableStartX = padding - 1;
    float currentTopY = screenshotAreaBottomY + padding; // initial Y position for the first table
    float totalTableWidth = graphAreaX - 2 * padding + 1;
    if (totalTableWidth < 0) totalTableWidth = 0;
    float internalPadding = padding; // use consistent padding

    // set up bounds for mouse wheel scrolling
    float availableHeight = height - currentTopY - padding;
    tablesAreaBounds.setBounds((int)tableStartX, (int)currentTopY, (int)totalTableWidth, (int)availableHeight);

    // store original top for bounds checking
    float originalTopY = currentTopY;

    // apply scroll offset
    currentTopY -= tablesScrollOffset;

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
        // java.util.Collections.sort(keys); // alphabetical sorting removed to preserve insertion order

        // calculate debug table height
        float headerTextY_debug = currentTopY + internalPadding + 3;
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

        // draw debug table header only if visible
        float headerLineY_debug = headerTextY_debug + 20 + 5; // Y position of the underline
        if (headerTextY_debug >= originalTopY && headerTextY_debug <= height) {
            text("key", round(tableStartX) + internalPadding, headerTextY_debug);
            text("value", round(dynamicValueX), headerTextY_debug);

            stroke(0);
            strokeWeight(1);
            line(tableStartX, headerLineY_debug, tableStartX + totalTableWidth, headerLineY_debug);
        }

        // draw vertical separator line for debug table
        float separatorX = tableStartX + internalPadding + dynamicKeyWidth;
        if (actualDebugTableHeight > 0 && currentTopY < height && currentTopY + actualDebugTableHeight >= originalTopY) {
            float lineStartY = max(currentTopY, originalTopY);
            float lineEndY = min(currentTopY + actualDebugTableHeight, height);
            if (lineEndY > lineStartY) {
                line(separatorX, lineStartY, separatorX, lineEndY);
            }
        }

        // draw debug table key/value rows ---
        for (int i = 0; i < keys.size(); i++) {
            String key = keys.get(i);
            Object value = debugInfo.get(key);
            String displayValue = formatDisplayValue(value);

            float rowTextY = headerLineY_debug + internalPadding + (i * debugRowHeight);
            // only draw if row is visible and within table bounds
            if (rowTextY >= originalTopY && rowTextY <= height &&
                rowTextY + debugRowHeight <= currentTopY + actualDebugTableHeight - internalPadding) {
                text(key, round(tableStartX) + internalPadding, rowTextY);
                text(displayValue, round(dynamicValueX), rowTextY);
            } else if (rowTextY > height) {
                break; // stop drawing if we're past the bottom of the screen
            }
        }

        // draw debug table border
        if (actualDebugTableHeight > 0 && currentTopY < height && currentTopY + actualDebugTableHeight >= originalTopY) {
            noFill();
            stroke(0);
            strokeWeight(borderWeight);
            float borderStartY = max(currentTopY, originalTopY);
            float borderEndY = min(currentTopY + actualDebugTableHeight, height);
            float borderHeight = borderEndY - borderStartY;
            if (borderHeight > 0) {
                rect(round(tableStartX), borderStartY, totalTableWidth, borderHeight);
            }
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

// helper function to format debug values
String formatDisplayValue(Object value) {
    if (value == null) return "null";
    if (value instanceof Boolean) {
        return (Boolean)value ? "TRUE" : "FALSE";
    } else if (value instanceof Float) {
        return nf((Float)value, 0, 6); // round floats
    } else {
        return value.toString();
    }
}

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
    float headerLineY_shaders = headerTextY_shaders + 20 + 5; // Y position of the underline (original comment)

    if (headerTextY_shaders >= screenshotAreaBottomY + padding - 20 && headerTextY_shaders <= height) {
        text("shaders", tableX + internalPadding, headerTextY_shaders);
        text("actions", actionsColContentStartX + 2, headerTextY_shaders);

        stroke(0);
        strokeWeight(1);
        line(tableX, headerLineY_shaders, tableX + tableWidth, headerLineY_shaders);
    }

    // draw vertical separator line only if there's height for it and visible
    if (availableHeightForShaders > (headerLineY_shaders - tableY) && tableY < height && tableY + availableHeightForShaders >= screenshotAreaBottomY + padding) {
        float lineStartY = max(tableY, screenshotAreaBottomY + padding);
        float lineEndY = min(tableY + availableHeightForShaders, height);
        if (lineEndY > lineStartY) {
            line(separatorLineX, lineStartY, separatorLineX, lineEndY);
        }
    }

    // draw shader names rows
    // (shaderNames.size() > 0 is already confirmed by the initial check if we reach here)
    for (int i = 0; i < shaderNames.size(); i++) {
        String displayName = shaderNames.get(i); // Safe due to loop condition
        float rowContentY = headerLineY_shaders + internalPadding + (i * debugRowHeight);
        float buttonDrawY_float = rowContentY;

        // only draw if row is visible
        if (rowContentY < screenshotAreaBottomY + padding || rowContentY > height) {
            if (rowContentY > height) break; // stop if past bottom
            continue; // skip if above visible area
        }
        if (rowContentY + debugRowHeight > tableY + availableHeightForShaders) {
            break; // stop drawing if rows exceed table boundary
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
    if (tableY < height && tableY + availableHeightForShaders >= screenshotAreaBottomY + padding) {
        float borderStartY = max(tableY, screenshotAreaBottomY + padding);
        float borderEndY = min(tableY + availableHeightForShaders, height);
        float borderHeight = borderEndY - borderStartY;
        if (borderHeight > 0) {
            rect(tableX, borderStartY, tableWidth, borderHeight);
        }
    }
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