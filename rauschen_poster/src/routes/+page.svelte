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
    const columns = 20;
    const rows = 20;
    const totalImagesNeeded = columns * rows;

    // Get the specific images for the grid based on configuration
    // If 'images' is empty, 'displayImages' will also be empty
    const displayImages = images.slice(0, totalImagesNeeded);

    // Function to calculate opacity based on index
    function getOpacity(index: number): number {
        const rowIndex = Math.floor(index / columns);
        const colIndex = index % columns;
        const lastRowIndex = rows - 1;

        // Calculate opacity for the first row (index 0)
        if (rowIndex === 0) {
            // Linear interpolation from 0.1 (90% transparent) at colIndex 0
            // to 1.0 (0% transparent) at colIndex (columns - 1)
            const opacity = 0.1 + (1.0 - 0.1) * (colIndex / (columns - 1));
            return opacity;
        }

        // Calculate opacity for the last row
        if (rowIndex === lastRowIndex) {
            // Linear interpolation from 1.0 (0% transparent) at colIndex 0
            // to 0.1 (90% transparent) at colIndex (columns - 1)
            const opacity = 1.0 + (0.1 - 1.0) * (colIndex / (columns - 1));
            return opacity;
        }

        // Default opacity for all middle rows
        return 1.0; // Fully opaque (0% transparent)
    }

</script>

<div class="bg-zinc-200">
    <div class="p-4 min-h-screen flex flex-col items-center justify-center mx-4">

    <h1 class="text-9xl text-left w-[90.5vmin] font-terminal font-bold mb-0">
        RAUSCHEN
    </h1>

    <div class="w-[90vmin] h-[90vmin]">
        <div class="grid grid-cols-20 w-full h-full">
            {#each displayImages as filename, index (filename)}
                <div
                    class="aspect-square overflow-hidden"
                    style="opacity: {getOpacity(index)};"
                >
                    <img
                        src="/saved/{filename}"
                        alt="screenshot {filename}"
                        loading="lazy"
                        class="w-full h-full object-cover"
                    />
                </div>
            {/each}
            </div>
    </div>

    <h1 class="text-6xl font-terminal text-right w-[90vmin] font-bold mt-2">
        19 + 20 JUNI 16 - 21 Uhr
    </h1>

    <div class="text-4xl font-terminal text-right w-[90vmin] font-bold mt-2">
        Speicher XI A
        <br>
        HfK Bremen
        <br>
        Überseetor 11
        <br>
        28217 Bremen
    </div>

    </div>
</div>