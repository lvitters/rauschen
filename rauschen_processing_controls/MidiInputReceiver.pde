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
							name = "/switchTime";
						break;
						case 5:
							name = "/switchTimeMultiplier";
						break;
						case 9:
							name = "/isAutoMode";
						break;
						case 10:
							name = "/isRandomSwitchTime";
						break;
						case 2:
							name = "/sameStep";
						break;
						case 6:
							name = "/sameStepMultiplier";
						break;
						case 11:
							name = "/isNoiseColorRandomOffset";
						break;
						case 12:
							name = "/isNoiseColorFastNoiseOffset";
						break;
						case 3:
							name = "/xStep";
						break;
						case 7:
							name = "/xStepMultiplier";
						break;
						case 13:
							name = "/isFastNoiseColor";
						break;
						case 14:
							name = "/resetFastNoiseType";
						break;
						case 4:
							name = "/yStep";
						break;
						case 8:
							name = "/yStepMultiplier";
						break;
						case 15:
							name = "/isShadersOnly";
						break;
						case 16:
							name = "/isRandomShaderEachFrame";
						break;
						case 17:
							name = "/shaderTimeMultiplier";
						break;
						case 21:
							name = "/shaderTimeDivisor";
						break;
						case 25:
							name = "/isShadersOnly";
						break;
						case 26:
							name = "/isRandomShaderEachFrame";
						break;
						case 18: 
							name = "/globalSpeedDivisor";
						break;
						case 22:
							name = "/globalBrightnessAndVolume";
						break;						
						case 19:
							name = "/cornerNoiseWalkAmt";
						break;
						case 23:
							name = "/cornerNoiseWalkSpeed";
						break;
						case 29:
							name = "/isCornerNoiseWalk";
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