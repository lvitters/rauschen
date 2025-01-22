// Create a class of NoiseObjects because we will need so many
class NoiseObject {
	float time;   // Keep track of how far we move through the noise field
	float inc;    // How much are we moving through the noise field per frame
	float value;  // What is the current value in the noise field

	// Constructor
	NoiseObject(float t, float i) {
		time = t;
		inc = i;
		value = 0;
	}

	// Compute noise
	void compute() {
		time += inc;
		value = noise(time);
	}

	// Change the increment with which to move through the noise field
	void changeInc(float i) {
		inc = i;
	}

	// Compute and return noise
	float getNoise() {
		compute();
		return value;
	}

	// Compute and return noise range
	float noiseRange(float low, float high) {
		compute();
		return map(value, 0, 1, low, high);
	}

	// Compute and return noise range where low and high bounds are a range as well
	float noiseVariableRange(float low, float lo, float hi, float high) {
		return noiseRange(
			noiseRange(low, lo),
			noiseRange(hi, high)
		);
	}

	// Return boolean according to noise range, cutoff at 0
	boolean noiseBool(float low, float high) {
		compute();
		float range = map(value, 0, 1, low, high);
		return range > 0;
	}
}