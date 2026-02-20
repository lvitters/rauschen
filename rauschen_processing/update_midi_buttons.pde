// setup midi controllers

// get info from device list and set controller as output device
void setupMidiOutput() {
	try {
		// get all MIDI devices
		MidiDevice.Info[] infos = MidiSystem.getMidiDeviceInfo();
		
		// look for Intech Studio Grid with receiver capability
		for (int i = 0; i < infos.length; i++) {
			MidiDevice device = MidiSystem.getMidiDevice(infos[i]);
			if (infos[i].getName().equals("Grid") && device.getMaxReceivers() != 0) {
				outputDevice = device;
				outputDevice.open();
				midiReceiver = outputDevice.getReceiver();
				if (printDebug) println("setupMidiOutput(): successfully opened Grid for output");
				break;
			}
		}
		if (outputDevice == null) {
			if (printDebug) println("setupMidiOutput(): could not find Grid with output capability");
		} else {
			// set all controller LEDs
			//resetControllerLEDs();
			setControllerLEDs();
		}
	} catch (Exception e) {
		if (printDebug) println("setupMidiOutput(): error setting up MIDI output: " + e.getMessage());
		e.printStackTrace();
	}
}

// reset all controller LEDs
void setControllerLEDs() {
	try {
		if (midiReceiver != null) {
			// default off
			int value = 0;

			// LEDs values 8 to 15
			// short press / long press are spaced apart 4 CCs
			for (int control = 8; control < 16; control++) {
				switch (control) {
					case 8: 
						value = isAutoMode ? 127 : 0;
					break;
					case 12:
						value = isRandomSwitchTime ? 127 : 0;
					break;
					case 9:
						value = isNoiseColorRandomOffset ? 127 : 0;
					break;
					case 13:
						value = isNoiseColorFastNoiseOffset ? 127 : 0;
					break;
					case 10:
						value = isFastNoiseColor ? 127 : 0;
					break;
					case 14:
						value = 0;
					break;
					case 11:
						value = isRandomShaderEachFrame ? 127 : 0;
					break;
					case 15:
						value = isShadersOnly ? 127 : 0;
					break;
				}

				ShortMessage message = new ShortMessage();
				// channel, CC number, value (127 = on / 0 = off)
				message.setMessage(ShortMessage.CONTROL_CHANGE, 0, control, value);
				midiReceiver.send(message, -1);
			}
			
			// reset
			value = 0;			
			
			// LEDs values 24 to 31 (32 is debug in controls) 
			// short press / long press are spaced apart 4 CCs
			for (int control = 24; control < 32; control++) {
				switch (control) {
					case 24:
						value = isEvenOffset ? 127 : 0;
					break;
					case 28:
						value = 0;
					break;
					case 25:
						value = 0;
					break;
					case 29:
						value = 0;
					break;
					case 26:
						value = isGeneratingSound ? 127 : 0;
					break;
					case 30:
						value = isApplyingAudioFilter ? 127 : 0;
					break;
					case 27:
						value = showDebug ? 127 : 0;
					break;
					case 31:
						value = showAudioLine ? 127 : 0;
					break;
				}

				ShortMessage message = new ShortMessage();
				// channel, CC number, value (127 = on / 0 = off)
				message.setMessage(ShortMessage.CONTROL_CHANGE, 0, control, value);
				midiReceiver.send(message, -1);
			}
		}
	} catch (Exception e) {
		if (printDebug) println("setControllerLEDs(): error setting LEDs: " + e.getMessage());
		e.printStackTrace();
	}
}

// reset all controller LEDs
void resetControllerLEDs() {
	try {
		if (midiReceiver != null) {
			// turn of corresponding LEDs

			// LEDs are numbered 9 to 12, only needs to be done for one page because this gets translated
			// to the "element" numbers, which is the same for the buttons on all pages of the controller
			for (int control = 9; control <= 12; control++) {
				ShortMessage message = new ShortMessage();
				// channel, CC number, value (0 = off)
				message.setMessage(ShortMessage.CONTROL_CHANGE, 0, control, 0);
				midiReceiver.send(message, -1);
			}

			if (printDebug) println("resetControllerLEDs(): reset all controller LEDs");
		}
	} catch (Exception e) {
		if (printDebug) println("resetControllerLEDs(): error resetting controller: " + e.getMessage());
		e.printStackTrace();
	}
}

// detect and list all available MIDI devices
void listMidiControllers() {
	try {
		// get all MIDI devices
		MidiDevice.Info[] infos = MidiSystem.getMidiDeviceInfo();
		
		// print detailed info about all available MIDI devices
		println("listMidiControllers(): available MIDI devices:");
		for (int i = 0; i < infos.length; i++) {
			MidiDevice device = MidiSystem.getMidiDevice(infos[i]);
			println("-------------------------------");
			println("device #" + i);
			println("name: " + infos[i].getName());
			println("description: " + infos[i].getDescription());
			println("vendor: " + infos[i].getVendor());
			println("version: " + infos[i].getVersion());
			println("max transmitters: " + device.getMaxTransmitters());
			println("max receivers: " + device.getMaxReceivers());
		}
	} catch (Exception e) {
		println("listMidiControllers(): error: " + e.getMessage());
		e.printStackTrace();
	}
}

// clean up when sketch exits
void stop() {
	// close MIDI devices
	if (outputDevice != null) {
		outputDevice.close();
	}
	super.stop();
}

// need an receiver to get transmitter from
class MidiInputReceiver implements Receiver {
	// must implement this
	public void send(MidiMessage message, long timeStamp) {}
	public void close() {}
}