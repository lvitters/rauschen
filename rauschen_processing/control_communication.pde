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
	oscP5.send(new OscMessage("/info/globalSpeedDivisor").add(globalSpeedDivisor), controlSketchLocation);

    oscP5.send(new OscMessage("/info/isRandomMode").add(isRandomMode ? 1 : 0), controlSketchLocation);
	
    oscP5.send(new OscMessage("/info/switchTime").add(switchTime), controlSketchLocation);
    oscP5.send(new OscMessage("/info/isRandomSwitchTime").add(isRandomSwitchTime ? 1 : 0), controlSketchLocation);

	oscP5.send(new OscMessage("/info/stepChance").add(stepChance), controlSketchLocation);
    oscP5.send(new OscMessage("/info/xStep").add(xStep), controlSketchLocation);
    oscP5.send(new OscMessage("/info/yStep").add(yStep), controlSketchLocation);
    String stepDimsStr = "x";
    if ((int)stepDims == 1) stepDimsStr = "both";
    else if ((int)stepDims == 2) stepDimsStr = "y";
    oscP5.send(new OscMessage("/info/stepDims").add(stepDimsStr), controlSketchLocation);
    oscP5.send(new OscMessage("/info/stepNoiseInc").add(stepNoiseInc), controlSketchLocation);

	oscP5.send(new OscMessage("/info/pixelColorModeChance").add(pixelColorModeChance), controlSketchLocation);
    String pixelColorModeStr = "random";
    if (pixelColorMode == 1) pixelColorModeStr = "noiseColorRandomOffset";
    else if (pixelColorMode == 2) pixelColorModeStr = "noiseColorFastNoiseOffset";
    else if (pixelColorMode == 3) pixelColorModeStr = "fastNoiseColor";
    oscP5.send(new OscMessage("/info/pixelColorMode").add(pixelColorModeStr), controlSketchLocation);
    
    oscP5.send(new OscMessage("/info/noiseColorOffsetInc").add(noiseColorOffsetInc), controlSketchLocation);

    if (pixelColorMode < 2 || isApplyingShader) {
        oscP5.send(new OscMessage("/info/fastNoiseType").add("none"), controlSketchLocation);
    } else {
        oscP5.send(new OscMessage("/info/fastNoiseType").add(fastNoiseType.toString()), controlSketchLocation);
    }

	oscP5.send(new OscMessage("/info/shaderChance").add(shaderChance), controlSketchLocation);
    oscP5.send(new OscMessage("/info/isApplyingShader").add(isApplyingShader ? 1 : 0), controlSketchLocation);
    oscP5.send(new OscMessage("/info/shaderTime").add(shaderTime), controlSketchLocation);
    oscP5.send(new OscMessage("/info/shaderTimeNoiseInc").add(shaderTimeNoiseInc), controlSketchLocation);
	oscP5.send(new OscMessage("/info/isRandomShaderEachFrame").add(isRandomShaderEachFrame ? 1 : 0), controlSketchLocation);

	oscP5.send(new OscMessage("/info/isEvenOffset").add(isEvenOffset ? 1 : 0), controlSketchLocation);
	oscP5.send(new OscMessage("/info/isGeneratingSound").add(isGeneratingSound ? 1 : 0), controlSketchLocation);
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
	if (message.checkAddrPattern("/stepChance")) {
		float value = message.get(0).floatValue();
		stepChance = map(value, 0, 127, 0, 1);
	}
	else if (message.checkAddrPattern("/stepNoiseInc")) {
		float value = message.get(0).floatValue();
		stepNoiseInc = map(value, 0, 127, 0, .05);
		stepNoise.changeInc(stepNoiseInc);
	}
	else if (message.checkAddrPattern("/stepDims")) {
		stepDims += 1;
		if (stepDims > 2) {
			stepDims = 0;
		}
	}
	else if (message.checkAddrPattern("/pixelColorModeChance")) {
		float value = message.get(0).floatValue();
		pixelColorModeChance = map(value, 0, 127, 0, 1);
	}
	else if (message.checkAddrPattern("/noiseColorOffsetInc")) {
		float value = message.get(0).floatValue();
		noiseColorOffsetInc = map(value, 0, 127, 0, .05);
		noiseColorOffsetNoise.changeInc(noiseColorOffsetInc);
	}
	else if (message.checkAddrPattern("/pixelColorMode")) {
		pixelColorMode += 1;
		if (pixelColorMode > 3) {
			pixelColorMode = 0;
		}
	}
	else if (message.checkAddrPattern("/resetFastNoiseType")) {
		resetFastNoiseType();
	}	
	else if (message.checkAddrPattern("/shaderTimeNoiseInc")) {
		float value = message.get(0).floatValue();
		shaderTimeNoiseInc = map(value, 0, 127, .001, 0);
		shaderTimeNoise.changeInc(shaderTimeNoiseInc);
	}	
	else if (message.checkAddrPattern("/shaderChance")) {
		float value = message.get(0).floatValue();
		shaderChance = map(value, 0, 127, 0, 1);
	}
	else if (message.checkAddrPattern("/isRandomShaderEachFrame")) {
		isRandomShaderEachFrame = !isRandomShaderEachFrame;
	}
	else if (message.checkAddrPattern("/isRandomMode")) {
		isRandomMode = !isRandomMode;
	}
	else if (message.checkAddrPattern("/isRandomSwitchTime")) {
		isRandomSwitchTime = !isRandomSwitchTime;
	}
	else if (message.checkAddrPattern("/globalSpeedDivisor")) {
		float value = message.get(0).floatValue();
		globalSpeedDivisor = (int) map(value, 0, 127, 1, 20);
	}
	else if (message.checkAddrPattern("/nextEvent")) {
		float value = message.get(0).floatValue();
		switchTime = map(value, 0, 127, 0, 10);
	}
	else if (message.checkAddrPattern("/globalBrightnessAndVolume")) {
		float value = message.get(0).floatValue();
		globalBrightnessAndVolume = map(value, 0, 127, 1, 0);
	}

	// other
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