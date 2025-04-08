// setup midi controllers

// get info from device list and set controller as input device
void setupMidi() {
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
                println("Successfully opened Grid for input");
                break;
            }
        }
        if (inputDevice == null) {
            println("Could not find Grid with input capability");
        }
    } catch (Exception e) {
        println("Error: " + e.getMessage());
        e.printStackTrace();
    }
}

// detect and list all available MIDI devices
void listMidiControllers() {
	try {
		// get all MIDI devices
		MidiDevice.Info[] infos = MidiSystem.getMidiDeviceInfo();
		
		// print detailed info about all available MIDI devices
		println("Available MIDI Devices:");
		for (int i = 0; i < infos.length; i++) {
		MidiDevice device = MidiSystem.getMidiDevice(infos[i]);
		println("-------------------------------");
		println("Device #" + i);
		println("Name: " + infos[i].getName());
		println("Description: " + infos[i].getDescription());
		println("Vendor: " + infos[i].getVendor());
		println("Version: " + infos[i].getVersion());
		println("Max Transmitters: " + device.getMaxTransmitters());
		println("Max Receivers: " + device.getMaxReceivers());
		}
	} catch (Exception e) {
		println("Error: " + e.getMessage());
		e.printStackTrace();
	}
}