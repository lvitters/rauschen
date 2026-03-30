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
						case 1:
							name = "/stepChance";
						break;
						case 5:
							name = "/stepNoiseInc";
						break;
						case 9:
							name = "/stepDims";
						break;
						case 2:
							name = "/pixelColorModeChance";
						break;
						case 6:
							name = "/noiseColorOffsetInc";
						break;
						case 11:
							name = "/pixelColorMode";
						break;
						case 12:
							name = "/resetFastNoiseType";
						break;
						case 3:
							name = "/shaderChance";
						break;
						case 7:
							name = "/shaderTimeNoiseInc";
						break;
						case 13:
							name = "/isRandomShaderEachFrame";
						break;
						case 4:
							name = "/nextEvent";
						break;
						case 8:
							name = "/globalSpeedDivisor";
						break;
						case 15:
							name = "/isRandomMode";
						break;
						case 16:
							name = "/isRandomSwitchTime";
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