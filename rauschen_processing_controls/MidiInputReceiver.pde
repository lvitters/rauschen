class MidiInputReceiver implements Receiver {
	// gets called whenever there is a new midi value
	public void send(MidiMessage message, long timeStamp) {
		if (message instanceof ShortMessage) {
			ShortMessage sm = (ShortMessage) message;
			
			// parse message
			if (sm.getCommand() == ShortMessage.CONTROL_CHANGE) {
				int channel = sm.getChannel();
				int number = sm.getData1();  // CC number (identifies which knob)
				int value = sm.getData2();   // CC value (value between 0-127)
				
				// println("Knob/Controller: CC#" + number + " Value: " + value + " Channel: " + channel);
				
				// if it is from a knob
				if (number >= 0) {
					// get knob index
					int index = number - 1;
					
					// calculate the actual parameter value
					float paramValue = 0;
					String paramName = "";
					
					// map the knob index to the correct parameter
					switch(index) {
						case 0:
						paramValue = (1 + value) / 12.8;	// cannot be 0
						paramName = "/minSwitchTime";
						break;
						case 1:
						paramValue = (1 + value) / 12.8;	// cannot be 0
						paramName = "/maxSwitchTime";
						break;
						case 2:
						paramValue = value / 12.8 / 2;		// can be 0
						paramName = "/switchTime";
						break;
						case 3:
						paramValue = value;					// should be 0 most of the time
						paramName = "/switchTimeMultiplier";
						break;
						case 4:
						paramValue = 1 + value;				// cannot be 0
						paramName = "/xStep";
						break;
						case 5:
						paramValue = 1 + value;				// cannot be 0
						paramName = "/yStep";
						break;
						case 6:
						paramValue = 1 + value;				// cannot be 0
						paramName = "/sameStep";
						break;
					}
					
					// send OSC message with the calculated value
					OscMessage oscMessage = new OscMessage(paramName);
					oscMessage.add(paramValue);
					oscP5.send(oscMessage, mainSketchLocation);
				}
			}
		}
	}
  
	// must implement this
	public void close() {}
}