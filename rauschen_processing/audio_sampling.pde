// a thread-safe container for audio pixel data and its dimensions.
class AudioFrame {
  final int[] pixels;
  final int width;
  final int height;

  AudioFrame(int[] p, int w, int h) {
    this.pixels = p;
    this.width = w;
    this.height = h;
  }
}

volatile AudioFrame audioFrame;

// make a thread-safe copy for the audio sampler to use
void makeBufferCopyForAudio() {
	if (buffer != null && buffer.pixels != null && buffer.pixels.length > 0) {
		// create a new pixel array and copy the data into it.
		int[] pixelsCopy = new int[buffer.pixels.length];
			System.arraycopy(buffer.pixels, 0, pixelsCopy, 0, buffer.pixels.length);
		
		// create a new, immutable AudioFrame and swap it in atomically.
		audioFrame = new AudioFrame(pixelsCopy, buffer.width, buffer.height);
	}
}

// this gets called by wellen's digital signal processing (DSP) and takes an array of samples for playback
// creates audio samples from a diagonal line through the buffer's pixels
void audioblock(float[] pSamples) {
  // grab a local, stable reference to the current frame. this should be thread-safe
  AudioFrame frame = audioFrame;

	if (frame != null) {
		int bufferWidth = frame.width;
		int bufferHeight = frame.height;
		
		// map samples to pixels along line
		for (int i = 0; i < pSamples.length; i++) {
			int x, y;
			
			// calculate position based on current mode
			switch (audioSamplingMode) {
				case 0: 
					// diagonal (top-left to bottom-right)
					// map sample index directly to buffer diagonal
					float diagonalPos = map(i, 0, pSamples.length - 1, 0, 1);
					x = (int) (diagonalPos * (bufferWidth - 1));
					y = (int) (diagonalPos * (bufferHeight - 1));
				break;
				case 1: 
					// horizontal (left to right)
					// map sample index directly to buffer width
					x = (int) map(i, 0, pSamples.length - 1, 0, bufferWidth - 1);
					y = bufferHeight / 2; // middle of the buffer
				break;
				case 2: 
					// vertical (top to bottom)
					// map sample index directly to buffer height
					x = bufferWidth / 2; // middle of the buffer
					y = (int) map(i, 0, pSamples.length - 1, 0, bufferHeight - 1);
				break;
				default:
					x = 0;
					y = 0;
				break;
			}
			
			// store coordinates for debug visualization
			audioDebugPixels.set(i, new PVector(x, y));
			
			// calculate pixel index
			int pixelIndex = y * bufferWidth + x;
			
      // check bounds explicitly for safety.
      if (pixelIndex >= 0 && pixelIndex < frame.pixels.length) {
        // extract RGB components
        float red = red(frame.pixels[pixelIndex]);
        float green = green(frame.pixels[pixelIndex]);
        float blue = blue(frame.pixels[pixelIndex]);
        
        // calculate the average
        float average = (red + green + blue) / 3.0;

        // map to audio sample range, at half volume
        pSamples[i] = map(average, 0, 255, -0.5, 0.5) * globalBrightnessAndVolume;

        // apply audio filter
        pSamples[i] = bandPassFilter.process(pSamples[i]);
      } else {
        // if something is wrong, produce silence.
        pSamples[i] = 0;
      }
		}
	} else {
		// fill with silence if no frame is available
		for (int i = 0; i < pSamples.length; i++) {
			pSamples[i] = 0;
			if (printDebug) println("audioblock(): audioFrame is null");
		}
	}
}

// toggle DSP on/off
void toggleSound(Boolean generateSound) {
	if (DSP.is_paused() && generateSound) {
		DSP.pause(false);
		isGeneratingSound = true;
	}
	else if (!generateSound) {
		DSP.pause(true);
		isGeneratingSound = false;
	}
}

// apply audio filter with noise
void applyAudioFilter() {
	if (isApplyingAudioFilter) {
		bandPassFilter.set_frequency(frequencyNoise.getNoiseRange(100, 18000));
		bandPassFilter.set_bandwidth(bandwidthNoise.getNoiseRange(100, 18000));
	} else {
		// println(audioFrequency);
		// println(audioBandwidth);
		bandPassFilter.set_frequency(audioFrequency);
		bandPassFilter.set_bandwidth(audioBandwidth);
	}
	// manually via mouse
	// float targetFreq = map(mouseX, 0, width, 1.0f, Wellen.DEFAULT_SAMPLING_RATE * 1.0f);
	// float bandwidth = map(mouseY, 0, height, 1.0f, Wellen.DEFAULT_SAMPLING_RATE * 0.5f);
	if (printDebug) println("applyAudioFilter(): freq: " + bandPassFilter.get_frequency() + "\n" + "bandwidth: " + bandPassFilter.get_bandwidth());
}
