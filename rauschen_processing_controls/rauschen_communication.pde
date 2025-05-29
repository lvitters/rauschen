// communication with main sketch "rauschen"

// called when new OSC message is received
void oscEvent(OscMessage message) {
	// check if it's the message with noises
	if (message.checkAddrPattern("/noises")) {
		// get how many arguments where send
		int numValues = message.arguments().length;

		// ensure there is the right number of graphs
		while (graphs.size() < numValues) {
			graphs.add(new Graph(colors[graphs.size() % colors.length]));
		}
		
		// if there are too many graphs, remove extras
		while (graphs.size() > numValues) {
			graphs.remove(graphs.size() - 1);
		}
		
		// add received values directly to graphs
		for (int i = 0; i < numValues; i++) {
			float value = message.get(i).floatValue();
			graphs.get(i).addPoint(value);
		}
	}

	// general handler for debug info messages
	else if (message.addrPattern().startsWith("/info/")) {
		String key = message.addrPattern().substring(6); // remove "/info/" prefix to get the key
		
		// extract the value based on the OSC message's typetag
		Object value = null;
		char type = message.typetag().charAt(0); // get the type of the first argument
		
		switch(type) {
		case 'i': // integer
			value = message.get(0).intValue();
			break;
		case 'f': // float
			value = message.get(0).floatValue();
			break;
		case 's': // string
			value = message.get(0).stringValue();
			break;
		default:
			// default to float for unknown types
			value = message.get(0).floatValue();
		}
		
		// special handling for boolean values (sent as integers)
		if (key.startsWith("is") && value instanceof Integer) {
			value = ((Integer)value == 1);
		}
		
		// store the value in our map
		debugInfo.put(key, value);
	}

	// handler for shader info messages
	else if (message.checkAddrPattern("/shaderNames")) {
        shaderNames.clear();
		// get how many arguments where send
        int numShaders = message.arguments().length;
        
        for (int i = 0; i < numShaders; i++) {
            shaderNames.add(message.get(i).stringValue());
        }
    }
    
    // update current shader choice when received
    else if (message.addrPattern().equals("/shaderChoice")) {
		// set to currentShaderChoice
        currentShaderChoice = message.get(0).intValue();
    }

	// add control sketch's fps
	// debugInfo.put("thisFps", frameRate);
}

// send the list of active shader indices via OSC
void sendActiveShaderList() {
    if (oscP5 == null || mainSketchLocation == null) {
       if (printDebug)  println("sendActiveShaderList(): OSC not initialized. Cannot send shader list.");
        return;
    }

    ArrayList<Integer> activeIndices = getActiveShaderIndices();
    
    OscMessage shaderListMessage = new OscMessage("/activeShaderIndices");
    
    for (Integer index : activeIndices) {
        shaderListMessage.add(index.intValue());
    }
    
    oscP5.send(shaderListMessage, mainSketchLocation);
}