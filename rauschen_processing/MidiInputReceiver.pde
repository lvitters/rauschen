class MidiInputReceiver implements Receiver {
	public void send(MidiMessage message, long timeStamp) {
		if (message instanceof ShortMessage) {
		ShortMessage sm = (ShortMessage) message;
		
		if (sm.getCommand() == ShortMessage.CONTROL_CHANGE) {
				int channel = sm.getChannel();
				int number = sm.getData1();  // CC number (identifies which knob)
				int value = sm.getData2();   // CC value (0-127)
				
				//println("Knob/Controller: CC#" + number + " Value: " + value + " Channel: " + channel);
				
				// // store the knob value (if within our array range), using knob 1 and 2
				// if (number >= 0 && number < knobValues.length) {
				// 	knobValues[number - 1] = value;
				// }

				// store the knob value (if within our array range), using knob 1 and 2
				if (number == 1) {
					knobValues[0] = value;
				} else if (number == 2) {
					knobValues[1] = value;
				} else if (number == 3) {
					knobValues[2] = value;
				}
			}
		}
	}
	// must implement this
	public void close() {}
}