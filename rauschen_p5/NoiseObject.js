//create a class of NoiseObjects because we will need so many
class NoiseObject {
	//initialise
	constructor(t, i) {
		this.time = t;		//keep track of how far we move through the noise field
		this.inc = i;		//how much are we moving through the noise field per frame
		this.value = 0;		//what is the current value in the noise field
	}

	//compute noise
	compute() {
		this.time += this.inc;
		this.value = noise(this.time);
	}

	//change the increment with which to move through the noise field
	changeInc(i) {
		this.inc = i;
	}

	//compute and return noise
	getNoise() {
		this.compute();
		return this.value;
	}

	//compute and return noise range
	noiseRange(low, high) {
		this.compute();
		return map(this.value, 0, 1, low, high);
	}

	//compute and return noise range where low and high bounds are a range as well
	noiseVariableRange(low, lo, hi, high) {
		return this.noiseRange(
			this.noiseRange(low, lo), 
			this.noiseRange(hi, high)
		);
	}

	//return boolean according to noise range, cutoff at 0
	noiseBool(low, high) {
		this.compute();
		let range = map(this.value, 0, 1, low, high);
		if (range > 0) return true;
		else return false;
	}
}