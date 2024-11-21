//create a class of NoiseObjects because we will need so many
class NoiseObject {
	//initialise
	constructor(t, i) {
		this.time = t;
		this.inc = i;
		this.value = 0;
	}

	//compute noise
	compute() {
		this.time += this.inc;
		this.value = noise(this.time);
	}

	//compute and return noise
	getNoise() {
		this.compute();
		return this.value;
	}

	//compute, map and return noise
	getMappedNoise(low, high) {
		this.compute();
		return map(this.value, 0, 1, low, high);
	}
}