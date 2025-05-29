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