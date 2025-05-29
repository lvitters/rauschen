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
    
    if (printDebug) println("initializeShaderControls(): shader controls initialized for " + numShaders + " shaders.");
}

// determine active shader indices based on solo/mute states
ArrayList<Integer> getActiveShaderIndices() {
    ArrayList<Integer> activeIndices = new ArrayList<Integer>();
    if (shaderNames == null || soloStates == null || muteStates == null || 
        soloStates.length != shaderNames.size() || muteStates.length != shaderNames.size()) {
        if (printDebug) println("getActiveShaderIndices(): error: cannot get active shader indices, states not initialized correctly or mismatch with shaderNames size.");
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