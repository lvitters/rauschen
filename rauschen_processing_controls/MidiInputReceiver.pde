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
						// case 10:
						// 	name = "";
						// break;
						case 2:
							name = "/noiseColorChance";
						break;
						case 6:
							name = "/noiseColorInc";
						break;
						case 11:
							name = "/noiseColorType";
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
						// case 14:
						// 	name = "";
						// break;
						case 4:
							name = "/globalSpeedDivisor";
						break;
						case 8:
							name = "/globalBrightnessAndVolume";
						break;
						// case 15:
						// 	name = "";
						// break;
						// case 16:
						// 	name = "";
						// break;
						// case 17:
						// 	name = "";
						// break;
						// case 21:
						// 	name = "";
						// break;
						// case 25:
						// 	name = "";
						// break;
						// case 26:
						// 	name = "";
						// break;
						// case 18: 
						// 	name = "";
						// break;
						// case 22:
						// 	name = "";
						// break;						
						// case 19:
						// 	name = "";
						// break;
						// case 23:
						// 	name = "";
						// break;
						// case 29:
						// 	name = "";
						// break;
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