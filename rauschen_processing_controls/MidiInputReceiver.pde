class MidiInputReceiver implements Receiver {
	// gets called whenever there is a new midi value
	public void send(MidiMessage message, long timeStamp) {
		if (message instanceof ShortMessage) {
			ShortMessage sm = (ShortMessage) message;
			
			// parse message
			if (sm.getCommand() == ShortMessage.CONTROL_CHANGE) {
				int channel = sm.getChannel();
				int number = sm.getData1();  // CC number (identifies which knob)
				float value = sm.getData2();   // CC value (value between 0-127)
				
				//println("Knob/Controller: CC#" + number + " Value: " + value + " Channel: " + channel);
				
				// map the control element number to the correct parameter
				if (number >= 1) {
					String name = "";
					switch(number) {
						case 1:
							name = "/switchTime";
						break;
						case 5:
							name = "/switchTimeMultiplier";
						break;
						case 2:
							name = "/sameStep";
						break;
						case 6:
							name = "/sameStepMultiplier";
						break;
						case 3:
							name = "/xStep";
						break;
						case 7:
							name = "/xStepMultiplier";
						break;
						case 4:
							name = "/yStep";
						break;
						case 8:
							name = "/yStepMultiplier";
						break;
						case 9:
							name = "/isAutoMode";
						break;
						case 10:
							name = "/isRandomSwitchTime";
						break;
						case 11:
							name = "/isEvenOffset";
						break;
						case 13:
							name = "/isNoiseColor";
						break;
						case 15:
							name = "/isGeneratingSound";
						break;
						case 16:
							name = "/isTakingScreenshots";
						break;
						case 31:
							if (value == 0) showDebug = false;
							else showDebug = true;
						break;
						case 32:
							name = "/showDebug";
						break;
					}
					
					// send OSC message with the calculated value
					OscMessage oscMessage = new OscMessage(name);
					oscMessage.add(value);
					oscP5.send(oscMessage, mainSketchLocation);
				}
			}
		}
	}
  
	// must implement this
	public void close() {}
}