<script lang="ts">
    // Define the expected shape of the data prop
    interface LoadData {
      imageFilenames: string[];
      // Error property is ignored as requested
    }

    // Receive data from the server load function
    export let data: LoadData;

    // Extract all image filenames, provide an empty array as a fallback
    const allImages = data?.imageFilenames || [];

    // Grid configuration
    const columns = 20;
    const rows = 20;
    const totalImagesNeeded = columns * rows;

    // Function to shuffle an array (Fisher-Yates shuffle algorithm)
    function shuffleArray<T>(array: T[]): T[] {
        const newArray = [...array]; // Create a copy to avoid mutating the original
        for (let i = newArray.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [newArray[i], newArray[j]] = [newArray[j], newArray[i]]; // Swap elements
        }
        return newArray;
    }

    // Shuffle all available images
    const shuffledImages = shuffleArray(allImages);

    // Get the specific images for the grid from the shuffled list
    const displayImages = shuffledImages.slice(0, totalImagesNeeded);

    const chosenBackgroundImageFilename = 'background.png'; // Your background image filename
    // Assuming 'background.png' is in your 'static' folder or public root
    const backgroundImageUrl = `/${chosenBackgroundImageFilename}`;

    // Define opacity (0.0 to 1.0) and other background properties
    const backgroundOpacityValue = 0.25; // For 20% opacity, use 0.2
    const imageTileSize = '30%'; // Your desired size for each tile

    // This style is for a dedicated background div
    const backgroundStyle = `
        position: absolute;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background-image: url('${backgroundImageUrl}');
        background-size: ${imageTileSize};
        background-position: center;
        background-repeat: repeat;
        background-attachment: scroll;
        opacity: ${backgroundOpacityValue}; /* Corrected opacity value */
        z-index: 0; /* To sit behind the main content */
    `;

    // Function to calculate opacity based on index
    function getOpacity(index: number): number {
        const rowIndex = Math.floor(index / columns);
        const colIndex = index % columns;
        const lastRowIndex = rows - 1;

        // Calculate opacity for the first row (index 0)
        if (rowIndex === 0) {
            const opacity = 0.1 + (1.0 - 0.1) * (colIndex / (columns - 1));
            return opacity;
        }

        // Calculate opacity for the last row
        if (rowIndex === lastRowIndex) {
            const opacity = 1.0 + (0.1 - 1.0) * (colIndex / (columns - 1));
            return opacity;
        }

        // Default opacity for all middle rows
        return 1.0; // Fully opaque (0% transparent)
    }

</script>

<div class="relative bg-zinc-200">

    <div style="{backgroundStyle}"></div>

    <div class="p-4 min-h-screen flex flex-col items-center justify-center mx-4" style="position: relative; z-index: 1;">
        
		<h1 class="text-8xl text-left w-[90.5vmin] font-interference font-bold mb-0">
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

        <h1 class="text-5xl font-interference text-right w-[90vmin] font-bold mt-2">
			MASTER EXHIBITION
			<br>
        </h1>
		
		<h1 class="text-4xl font-interference text-right w-[90vmin] font-bold mt-2">
			Lucca Vitters
			<br>
			<br>
            JUNE 19 + 20
        </h1>
		
		<h1 class="text-4xl font-interference text-right w-[90vmin] font-bold mt-2">
            5pm - 8pm
        </h1>

		<br>

        <div class="text-2xl font-interference text-right w-[90vmin] font-bold mt-2">
            Speicher XI A
            <br>
            Halle 1
        </div>

    </div>

</div>

<style>
    @media print {
        /* Target the dedicated background div by its inline style presence */
        .relative > div[style*="background-image"] { /* A bit more specific selector */
            -webkit-print-color-adjust: exact !important;
            print-color-adjust: exact !important;
        }
        h1, .text-3xl {
            color: #000000 !important; /* Ensure text is black for print */
            text-shadow: none !important;
        }
    }
</style>