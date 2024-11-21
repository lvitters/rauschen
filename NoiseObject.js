//create a class of NoiseObjects because we will need so many
class NoiseObject {
	//initialise
	constructor(t, i) {
		this.time = t;
		this.inc = i;
		this.value = 0;
	}

	//compute and return
	getNoise() {
		this.time += this.inc;
		this.value = noise(this.time);
		return this.value;
	}
}