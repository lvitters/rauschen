// fast integer random function (thanks Ralf)
public static int intRandom(int min, int max) {
   return ThreadLocalRandom.current().nextInt(min, max + 1);
}

// fast float random function 
public static float floatRandom(float min, float max) {
	return ThreadLocalRandom.current().nextFloat(min, max + 1);
}
