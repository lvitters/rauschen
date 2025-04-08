// communication with main sketch "rauschen"

// called when new OSC message is received
void oscEvent(OscMessage msg) {
	// check if it's the message with noises
	if (msg.checkAddrPattern("/noises")) {
		// get the typetag to know how many values were sent
		String typetag = msg.typetag();
		int numValues = typetag.length() - 1; // subtract 1 for the comma at the beginning

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
			float value = msg.get(i).floatValue();
			graphs.get(i).addPoint(value);
		}
	}
	// general handler for debug info messages
	else if (msg.addrPattern().startsWith("/info/")) {
		String key = msg.addrPattern().substring(6); // remove "/info/" prefix to get the key
		
		// extract the value based on the OSC message's typetag
		Object value = null;
		char type = msg.typetag().charAt(0); // get the type of the first argument
		
		switch(type) {
		case 'i': // integer
			value = msg.get(0).intValue();
			break;
		case 'f': // float
			value = msg.get(0).floatValue();
			break;
		case 's': // string
			value = msg.get(0).stringValue();
			break;
		default:
			// default to float for unknown types
			value = msg.get(0).floatValue();
		}
		
		// special handling for boolean values (sent as integers)
		if (key.startsWith("is") && value instanceof Integer) {
			value = ((Integer)value == 1);
		}
		
		// store the value in our map
		debugInfo.put(key, value);
	}
}