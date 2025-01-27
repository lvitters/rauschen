// create a class of noise instances because we will need so many
class Noise {
	float time;   // keep track of how far we move through the noise field
	float inc;    // how much are we moving through the noise field per frame
	float value;  // what is the current value in the noise field

	// constructor
	Noise(float t, float i) {
		time = t;
		inc = i;
		value = 0;
	}

	// compute noise
	void compute() {
		time += inc;
		value = noise(time);
	}

	// change the increment with which to move through the noise field
	void changeInc(float i) {
		inc = i;
	}

	// compute and return noise
	float getNoise() {
		compute();
		return value;
	}

	// compute and return noise range
	float getNoiseRange(float low, float high) {
		compute();
		return map(value, 0, 1, low, high);
	}

	// compute and return noise range where low and high bounds are a range as well
	float getVariableNoiseRange(float low, float lo, float hi, float high) {
		return getNoiseRange(
			getNoiseRange(low, lo),
			getNoiseRange(hi, high)
		);
	}

	// compute and return noise range that is biased towards one end (greater than 1 biases towards 1, less than 1 biases towards 0)
	float getBiasedNoiseRange(float low, float high, float bias) {
		float value = getNoiseRange(low, high);
		value = pow(value, bias);
		return value;
	}

	// compute and return variable noise range that is biased towards one end (greater than 1 biases towards 1, less than 1 biases towards 0)
	float getBiasedVariableNoiseRange(float low, float lo, float hi, float high, float bias) {
		float value = getVariableNoiseRange(low, lo, hi, high);
		value = pow(value, bias);
		return value;
	}

	// return boolean according to noise range, cutoff at 0
	boolean noiseBool(float low, float high) {
		compute();
		float range = map(value, 0, 1, low, high);
		return range > 0;
	}
}