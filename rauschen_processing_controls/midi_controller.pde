// setup midi controllers

// get info from device list and set controller as input device
void setupMidiInput() {
    try {
        // get all MIDI devices
        MidiDevice.Info[] infos = MidiSystem.getMidiDeviceInfo();

        // look specifically for MPKmini2 with transmitter capability
        for (int i = 0; i < infos.length; i++) {
            MidiDevice device = MidiSystem.getMidiDevice(infos[i]);
            if (infos[i].getName().equals("Grid") && device.getMaxTransmitters() != 0) {
                inputDevice = device;
                inputDevice.open();
                Transmitter transmitter = inputDevice.getTransmitter();
                transmitter.setReceiver(new MidiInputReceiver());
                println("successfully opened Grid for input");
                break;
            }
        }
        if (inputDevice == null) {
            println("could not find Grid with input capability");
        }
    } catch (Exception e) {
        println("error: " + e.getMessage());
        e.printStackTrace();
    }
}

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
				println("successfully opened Grid for output");
				break;
			}
		}
		if (outputDevice == null) {
			println("could not find Grid with output capability");
		} else {
			// reset all controller LEDs
			resetControllerLEDs();
		}
	} catch (Exception e) {
		println("error setting up MIDI output: " + e.getMessage());
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

			println("reset all controller LEDs");
		}
	} catch (Exception e) {
		println("error resetting controller: " + e.getMessage());
		e.printStackTrace();
	}
}

// detect and list all available MIDI devices
void listMidiControllers() {
	try {
		// get all MIDI devices
		MidiDevice.Info[] infos = MidiSystem.getMidiDeviceInfo();
		
		// print detailed info about all available MIDI devices
		println("available MIDI devices:");
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
		println("error: " + e.getMessage());
		e.printStackTrace();
	}
}

// clean up when sketch exits
void stop() {
	// close MIDI devices
	if (inputDevice != null) {
		inputDevice.close();
	}
	if (outputDevice != null) {
		outputDevice.close();
	}
	super.stop();
}