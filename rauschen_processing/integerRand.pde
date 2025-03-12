// fast integer randon function (thanks Ralf)
public static int intRandom(int min, int max) {
   return ThreadLocalRandom.current().nextInt(min, max + 1);
}
