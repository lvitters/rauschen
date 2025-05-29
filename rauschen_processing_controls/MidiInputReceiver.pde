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
				
				if (printDebug) println("send(): knob/controller: CC#" + number + " value: " + value + " channel: " + channel);
				
				// map the control element number to the correct parameter
				if (number >= 0) {
					String name = "";
					switch(number) {
						case 0:
							name = "/switchTime";
						break;
						case 4:
							name = "/switchTimeMultiplier";
						break;
						case 1:
							name = "/sameStep";
						break;
						case 5:
							name = "/sameStepMultiplier";
						break;
						case 2:
							name = "/xStep";
						break;
						case 6:
							name = "/xStepMultiplier";
						break;
						case 3:
							name = "/yStep";
						break;
						case 7:
							name = "/yStepMultiplier";
						break;
						case 8:
							name = "/isAutoMode";
						break;
						case 12:
							name = "/isRandomSwitchTime";
						break;
						case 9:
							name = "/isNoiseColor";
						break;
						case 10:
							name = "/isEvenOffset";
						break;
						case 11:
							name = "/isGeneratingSound";
						break;
						case 15:
							name = "/isApplyingAudioFilter";
						break;
						case 27:
							// rauschen
							name = "/showDebug";
						break;
						case 32:
							name = "/setControllerLEDs";
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