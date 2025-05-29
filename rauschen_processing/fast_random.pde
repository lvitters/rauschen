// fast integer random function (thanks Ralf)
public static int intRandom(int min, int max) {
   return ThreadLocalRandom.current().nextInt(min, max + 1);
}

// fast float random function (thanks Claude)
public static float floatRandom(float min, float max) {
    // Slightly adjusting the formula to potentially include the exact max value
    return ThreadLocalRandom.current().nextFloat(min, max);
}
