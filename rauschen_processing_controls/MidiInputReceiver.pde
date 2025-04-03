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
				
				//println("Knob/Controller: CC#" + number + " Value: " + value + " Channel: " + channel);
				
				// if it is from a knob
				if (number >= 1) {
					// get knob index
					int index = number;
					
					// set the parameter value
					float paramValue = value;
					
					// map the knob index to the correct parameter
					String paramName = "";
					switch(index) {
						case 1:
							paramName = "/switchTime";
						break;
						case 5:
							paramName = "/switchTimeMultiplier";
						break;
						case 2:
							paramName = "/sameStep";
						break;
						case 6:
							paramName = "/sameStepMultiplier";
						break;
						case 3:
							paramName = "/xStep";
						break;
						case 7:
							paramName = "/xStepMultiplier";
						break;
						case 4:
							paramName = "/yStep";
						break;
						case 8:
							paramName = "/yStepMultiplier";
						break;
						case 9:
							paramName = "/isAutoMode";
						break;
						case 10:
							paramName = "/isRandomSwitchTime";
						break;
						case 11:
							paramName = "/isEvenOffset";
						break;
						case 12:
							paramName = "/isNoiseColor";
						break;
						case 21:
							paramName = "/isMakingSound";
						break;
						case 22:
							paramName = "/isTakingScreenshots";
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