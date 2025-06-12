// communication with control sketch

// send noises over OSC
void sendNoisesOSC() {
	// create a new OSC message
	OscMessage msg = new OscMessage("/noises");
	
	// add all noise values to the message
	for (Noise n : noises) {
		msg.add(n.value);
	}

	// send the message
	oscP5.send(msg, controlSketchLocation);
}

// send debug info over OSC
void sendDebugOSC() {
    // send each parameter as its own OSC message (booleans need to be converted to 1 and 0)
    oscP5.send(new OscMessage("/info/fps").add((int)frameRate), controlSketchLocation);
    oscP5.send(new OscMessage("/info/xStep").add(xStep), controlSketchLocation);
    oscP5.send(new OscMessage("/info/yStep").add(yStep), controlSketchLocation);
    oscP5.send(new OscMessage("/info/isAutoMode").add(isAutoMode ? 1 : 0), controlSketchLocation);
    oscP5.send(new OscMessage("/info/nextEvent").add(nextEvent), controlSketchLocation);
    oscP5.send(new OscMessage("/info/isRandomSwitchTime").add(isRandomSwitchTime ? 1 : 0), controlSketchLocation);
    oscP5.send(new OscMessage("/info/isNoiseColorRandomOffset").add(isNoiseColorRandomOffset ? 1 : 0), controlSketchLocation);
    oscP5.send(new OscMessage("/info/isNoiseColorFastNoiseOffset").add(isNoiseColorFastNoiseOffset ? 1 : 0), controlSketchLocation);
    if (!isNoiseColorFastNoiseOffset || !isNoiseColorRandomOffset|| isApplyingShader) oscP5.send(new OscMessage("/info/fastNoiseType").add("none"), controlSketchLocation);
	else oscP5.send(new OscMessage("/info/fastNoiseType").add(fastNoiseType.toString()), controlSketchLocation);
    oscP5.send(new OscMessage("/info/isFastNoiseColor").add(isFastNoiseColor ? 1 : 0), controlSketchLocation);
    oscP5.send(new OscMessage("/info/isApplyingShader").add(isApplyingShader ? 1 : 0), controlSketchLocation);
	oscP5.send(new OscMessage("/info/isRandomShaderEachFrame").add(isRandomShaderEachFrame ? 1 : 0), controlSketchLocation);
    oscP5.send(new OscMessage("/info/shaderTime").add(shaderTime), controlSketchLocation);
	oscP5.send(new OscMessage("/info/isShadersOnly").add(isShadersOnly ? 1 : 0), controlSketchLocation);
	oscP5.send(new OscMessage("/info/isEvenOffset").add(isEvenOffset ? 1 : 0), controlSketchLocation);
	oscP5.send(new OscMessage("/info/isTakingScreenshots").add(isTakingScreenshots ? 1 : 0), controlSketchLocation);
	oscP5.send(new OscMessage("/info/isGeneratingSound").add(isGeneratingSound ? 1 : 0), controlSketchLocation);
	oscP5.send(new OscMessage("/info/isApplyingAudioFilter").add(isApplyingAudioFilter ? 1 : 0), controlSketchLocation);
	oscP5.send(new OscMessage("/info/globalSpeedDivisor").add(globalSpeedDivisor), controlSketchLocation);
}

// send shader names and choice over OSC
void sendShaderInfoOSC() {
    // create OSC message with shader filenames
    OscMessage msg = new OscMessage("/shaderNames");
	// extract filename and add to message
    for (String name : shaderNames) {
        msg.add(name.toString());
    }

	// send message
    oscP5.send(msg, controlSketchLocation);

	// make sure UI is overwritten
	if (activeShaders.isEmpty()) shaderChoice = -1;

	// create OSC message with shader choice
    oscP5.send(new OscMessage("/shaderChoice").add(shaderChoice), controlSketchLocation);
}

// handle incoming OSC messages from control sketch
void oscEvent(OscMessage message) {
	// handle parameter updates according to names given in "MidiInputReceiver" which should correspond to variables here
	if (message.checkAddrPattern("/switchTime")) {
		float value = message.get(0).floatValue();
		if (isRandomSwitchTime) maxSwitchTime = map(value, 0, 127, 0, 5);
		else switchTime = map(value, 0, 127, 0, 5);				// 0 means switch every frame
	}
	else if (message.checkAddrPattern("/switchTimeMultiplier")) {
		float value = message.get(0).floatValue();
		switchTimeMultiplier = map(value, 0, 127, 1, 5);		// should be 0 most of the time
	}
	else if (message.checkAddrPattern("/isAutoMode")) {
		float value = message.get(0).floatValue();
		value = map(value, 0, 127, 0, 1);						// switch between 0 and 1 with actual button value
		if (value == 0) isAutoMode = false;
		if (value == 1) isAutoMode = true;
	}
	else if (message.checkAddrPattern("/isRandomSwitchTime")) {
		float value = message.get(0).floatValue();
		value = map(value, 0, 127, 0, 1);						// switch between 0 and 1 with actual button value
		if (value == 0) isRandomSwitchTime = false;
		if (value == 1) isRandomSwitchTime = true;
	}
	else if (message.checkAddrPattern("/sameStep")) {
		float value = message.get(0).floatValue();
		nextX = nextY = (int) map(value, 0, 127, 1, width/10);	// cannot be 0, should depend on the res
		stepUpdatedManually = true;
	}
	else if (message.checkAddrPattern("/sameStepMultiplier")) {
		float value = message.get(0).floatValue();
		xStepMultiplier = yStepMultiplier = map(value, 0, 127, 1, width/100);		// cannot be 0, should depend on the res
		stepUpdatedManually = true;
	}
	else if (message.checkAddrPattern("/isNoiseColorRandomOffset")) {
		float value = message.get(0).floatValue();
		value = map(value, 0, 127, 0, 1);						// switch between 0 and 1 with actual button value
		if (value == 0) isNoiseColorRandomOffset = false;
		if (value == 1) isNoiseColorRandomOffset = true;
	}
	else if (message.checkAddrPattern("/isNoiseColorFastNoiseOffset")) {
		float value = message.get(0).floatValue();
		value = map(value, 0, 127, 0, 1);						// switch between 0 and 1 with actual button value
		if (value == 0) isNoiseColorFastNoiseOffset = false;
		if (value == 1) isNoiseColorFastNoiseOffset = true;
	}
	else if (message.checkAddrPattern("/xStep")) {
		float value = message.get(0).floatValue();
		nextX = (int) map(value, 0, 127, 1, width/10);			// cannot be 0, should depend on the res
		stepUpdatedManually = true;
	}
	else if (message.checkAddrPattern("/xStepMultiplier")) {
		float value = message.get(0).floatValue();
		xStepMultiplier = map(value, 0, 127, 1, width/100);		// cannot be 0, should depend on the res
		stepUpdatedManually = true;
	}
	else if (message.checkAddrPattern("/isFastNoiseColor")) {
		float value = message.get(0).floatValue();
		value = map(value, 0, 127, 0, 1);						// switch between 0 and 1 with actual button value
		if (value == 0) isFastNoiseColor = false;
		if (value == 1) isFastNoiseColor = true;
	}
	else if (message.checkAddrPattern("/yStep")) {
		float value = message.get(0).floatValue();
		nextY = (int) map(value, 0, 127, 1, height/10);			// cannot be 0, should depend on the res
		stepUpdatedManually = true;
	}
	else if (message.checkAddrPattern("/yStepMultiplier")) {
		float value = message.get(0).floatValue();
		yStepMultiplier = map(value, 0, 127, 1, width/100);		// cannot be 0, should depend on the res
		stepUpdatedManually = true;
	}
	else if (message.checkAddrPattern("/isRandomShaderEachFrame")) {
		float value = message.get(0).floatValue();
		value = map(value, 0, 127, 0, 1);						// switch between 0 and 1 with actual button value
		if (value == 0) isRandomShaderEachFrame = false;
		if (value == 1) isRandomShaderEachFrame = true;
	}
	else if (message.checkAddrPattern("/isEvenOffset")) {
		float value = message.get(0).floatValue();
		value = map(value, 0, 127, 0, 1);						// switch between 0 and 1 with actual button value
		if (value == 0) isEvenOffset = false;
		if (value == 1) isEvenOffset = true;
	}
	else if (message.checkAddrPattern("/shaderTimeMultiplier")) {
		float value = message.get(0).floatValue();
		shaderTimeMultiplier = map(value, 0, 127, 1, 10);			// cannot be 0
	}
	else if (message.checkAddrPattern("/shaderTimeDivisor")) {
		float value = message.get(0).floatValue();
		shaderTimeDivisor = map(value, 0, 127, 1, 0.001);			// cannot be 0
	}
	else if (message.checkAddrPattern("/isShadersOnly")) {
		float value = message.get(0).floatValue();
		value = map(value, 0, 127, 0, 1);						// switch between 0 and 1 with actual button value
		if (value == 0) isShadersOnly = false;
		if (value == 1) isShadersOnly = true;
	}
	else if (message.checkAddrPattern("/globalSpeedDivisor")) {
		float value = message.get(0).floatValue();
		globalSpeedDivisor = (int) map(value, 0, 127, 1, 20);				// cannot be 0
	}
	else if (message.checkAddrPattern("/isGeneratingSound")) {
		float value = message.get(0).floatValue();
		value = map(value, 0, 127, 0, 1);						// switch between 0 and 1 with actual button value
		if (value == 0) toggleSound(false);						// turn DSP on
		if (value == 1) toggleSound(true);						// or off
	}
	else if (message.checkAddrPattern("/isApplyingAudioFilter")) {
		float value = message.get(0).floatValue();
		value = map(value, 0, 127, 0, 1);						// switch between 0 and 1 with actual button value
		if (value == 0) isApplyingAudioFilter = false;
		if (value == 1) isApplyingAudioFilter = true;
	}
	else if (message.checkAddrPattern("/showDebug")) {
		float value = message.get(0).floatValue();
		value = map(value, 0, 127, 0, 1);						// switch between 0 and 1 with actual button value
		if (value == 0) showDebug = false;
		if (value == 1) showDebug = true;
	}	
	else if (message.checkAddrPattern("/showAudioLine")) {
		float value = message.get(0).floatValue();
		value = map(value, 0, 127, 0, 1);						// switch between 0 and 1 with actual button value
		if (value == 0) showAudioLine = false;
		if (value == 1) showAudioLine = true;
	}

	// other
	else if (message.checkAddrPattern("/setControllerLEDs")) {
		setControllerLEDs();
	}	
	else if (message.checkAddrPattern("/activeShaderIndices")) {
		// clear shader states
		activeShaders.clear();
		// get how many arguments where send
        int numactiveShaders = message.arguments().length;
        // write to shader states 
        for (int i = 0; i < numactiveShaders; i++) {
            activeShaders.add(message.get(i).intValue());
        }
		// when isRandomShaderEachFrame, set lastShaderChoice to whatever activeShaders came in last
		if (!isRandomShaderEachFrame) {
			if (!activeShaders.isEmpty()) {
				int rand = pickRandomActiveShader();
				shaderChoice = rand;
				lastShaderChoice = rand;
			}
		}
	}
}