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
                if (printDebug) println("setupMidiInput(): successfully opened Grid for input");
                break;
            }
        }
        if (inputDevice == null) {
            if (printDebug) println("setupMidiInput(): could not find Grid with input capability");
        }
    } catch (Exception e) {
        if (printDebug) println("setupMidiInput(): error: " + e.getMessage());
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
	if (inputDevice != null) {
		inputDevice.close();
	}
	super.stop();
}
