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
    oscP5.send(new OscMessage("/info/isNoiseColor").add(isNoiseColor ? 1 : 0), controlSketchLocation);
    oscP5.send(new OscMessage("/info/isApplyingShader").add(isApplyingShader ? 1 : 0), controlSketchLocation);
	oscP5.send(new OscMessage("/info/isRandomShaderEachFrame").add(isRandomShaderEachFrame ? 1 : 0), controlSketchLocation);
    oscP5.send(new OscMessage("/info/shaderTime").add(shaderTime), controlSketchLocation);
	oscP5.send(new OscMessage("/info/isEvenOffset").add(isEvenOffset ? 1 : 0), controlSketchLocation);
	oscP5.send(new OscMessage("/info/isTakingScreenshots").add(isTakingScreenshots ? 1 : 0), controlSketchLocation);
	oscP5.send(new OscMessage("/info/isGeneratingSound").add(isGeneratingSound ? 1 : 0), controlSketchLocation);
	oscP5.send(new OscMessage("/info/isApplyingAudioFilter").add(isApplyingAudioFilter ? 1 : 0), controlSketchLocation);
}

// send shader names and choice over OSC
void sendShaderInfoOSC() {
    // create OSC message with shader filenames
    OscMessage shaderNamesMsg = new OscMessage("/shaders/names");
	// extract filename
    for (String name : shaderNames) {
        shaderNamesMsg.add(name);
    }
	// send message
    oscP5.send(shaderNamesMsg, controlSketchLocation);

	// create OSC message with shader choice
    oscP5.send(new OscMessage("/info/shaderChoice").add(shaderChoice), controlSketchLocation);
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
	else if (message.checkAddrPattern("/isEvenOffset")) {
		float value = message.get(0).floatValue();
		value = map(value, 0, 127, 0, 1);						// switch between 0 and 1 with actual button value
		if (value == 0) isEvenOffset = false;
		if (value == 1) isEvenOffset = true;
	}
	else if (message.checkAddrPattern("/isNoiseColor")) {
		float value = message.get(0).floatValue();
		value = map(value, 0, 127, 0, 1);						// switch between 0 and 1 with actual button value
		if (value == 0) isNoiseColor = false;
		if (value == 1) isNoiseColor = true;
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
	else if (message.checkAddrPattern("/setControllerLEDs")) {
		setControllerLEDs();
	}
}