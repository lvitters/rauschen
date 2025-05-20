// sample pixels for audio using Wellen's DSP

// make a thread-safe copy for the audio sampler to use
void makeBufferCopyForAudio() {
	if (buffer != null) {
		if (buffer.pixels != null) {
			if (audioPixels == null || audioPixels.length != buffer.pixels.length) {
				audioPixels = new int[buffer.pixels.length];
			}
			System.arraycopy(buffer.pixels, 0, audioPixels, 0, buffer.pixels.length);
		}
	}
}

// this gets called by wellen's digital signal processing (DSP) and takes an array of samples for playback
// creates audio samples from a diagonal line through the buffer's pixels
void audioblock(float[] pSamples) {
	if (audioPixels != null) {
		int bufferWidth = buffer.width;
		int bufferHeight = buffer.height;
		
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
			
			// extract RGB components - no need for bounds check as we've mapped directly to buffer dimensions
			float red = red(audioPixels[pixelIndex]);
			float green = green(audioPixels[pixelIndex]);
			float blue = blue(audioPixels[pixelIndex]);
			
			// calculate the average
			float average = (red + green + blue) / 3.0;

			// map to audio sample range, at half volume
			pSamples[i] = map(average, 0, 255, -0.5, 0.5);

			// apply audio filter
			pSamples[i] = hiPassFilter.process(pSamples[i]);
			pSamples[i] = loPassFilter.process(pSamples[i]);
		}
	} else {
		// fill with silence if no pixels
		for (int i = 0; i < pSamples.length; i++) {
			pSamples[i] = 0;
			println("buffer empty");
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