<script lang="ts">
    // Define the expected shape of the data prop
    interface LoadData {
      imageFilenames: string[];
      // Error property is ignored as requested
    }

    // Receive data from the server load function
    export let data: LoadData;

    // Extract image filenames, provide an empty array as a fallback
    // Using optional chaining data?. just in case data itself is undefined
    const images = data?.imageFilenames || [];

    // Grid configuration
    const columns = 15;
    const rows = 15;
    const totalImagesNeeded = columns * rows;

    // Get the specific images for the grid based on configuration
    // If 'images' is empty, 'displayImages' will also be empty
    const displayImages = images.slice(0, totalImagesNeeded);

</script>

<div class="p-4 min-h-screen flex flex-col items-center justify-center">

  <h1 class="text-8xl text-left w-[90vmin] font-bold mb-2">
    RAUSCHEN
  </h1>

  <div class="w-[90vmin] h-[90vmin] print:w-full print:h-auto print:aspect-square">
      <div class="grid grid-cols-15 w-full h-full">
          {#each displayImages as filename (filename)}
              <div class="aspect-square overflow-hidden bg-gray-50">
                  <img
                      src="/saved/{filename}"
                      alt="screenshot {filename}"
                      loading="lazy"
                      class=""
                  />
              </div>
          {/each}
          </div>
  </div>

  <h1 class="text-6xl text-right w-[90vmin] font-bold mt-2">
    19 + 20 JUNI 16 - 21 Uhr
  </h1>

  <div class="text-xl text-right w-[90vmin] font-bold mt-2">
	Speicher XI A
	<br>
    HfK Bremen
	<br>
	Überseetor 11
	<br>
	28217 Bremen
  </div>

</div>