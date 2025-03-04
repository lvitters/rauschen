// create a class of noise instances because we will need so many
class Noise {
	float time;   			// keep track of how far we move through the noise field
	float inc;    			// how much are we moving through the noise field per frame
	float value;  			// what is the current value in the noise field

	// constructor
	Noise(float t, float i) {
		time = t;
		inc = i;
		value = 0;
	}

	// compute noise
	void compute(float bias) {
		// increment time
		time += inc;
		// get noise value
		value = noise(time);
		// apply reciprocal of bias because the base to be raised (value) is between 0 and 1, so that <1 biases towards 0, 1 is no bias, >1 biases towards 1
		value = pow(value, 1.0 / bias);
	}

	// change the increment with which to move through the noise field
	void changeInc(float i) {
		inc = i;
	}

	// compute and return noise
	float getNoise(float bias) {
		compute(bias);
		return value;
	}

	// compute and return noise range
	float getNoiseRange(float low, float high, float bias) {
		compute(bias);
		return map(value, 0, 1, low, high);
	}

	// compute and return noise range where low and high bounds are a range as well
	float getVariableNoiseRange(float low, float lo, float hi, float high, float bias) {
		return getNoiseRange(
			getNoiseRange(low, lo, 1),
			getNoiseRange(hi, high, 1),
			bias
		);
	}

	// return boolean according to noise range, >0 is true
	boolean getNoiseBool(float low, float high) {
		compute(1);
		float range = map(value, 0, 1, low, high);
		return range > 0;
	}
}