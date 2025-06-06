<script lang="ts">
    // define the expected shape of the data prop
    interface LoadData {
      imageFilenames: string[];
    }

    // receive data from the server load function
    export let data: LoadData;

    // extract all image filenames, provide an empty array as a fallback
    const allImages = data?.imageFilenames || [];

    // grid configuration
    const columns = 20;
    const rows = 20;
    const totalImagesNeeded = columns * rows;

    // function to shuffle an array (Fisher-Yates shuffle algorithm)
    function shuffleArray<T>(array: T[]): T[] {
        const newArray = [...array]; // create a copy to avoid mutating the original
        for (let i = newArray.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [newArray[i], newArray[j]] = [newArray[j], newArray[i]]; // swap elements
        }
        return newArray;
    }

    // huffle all available images
    const shuffledImages = shuffleArray(allImages);

    // get the specific images for the grid from the shuffled list
    const displayImages = shuffledImages.slice(0, totalImagesNeeded);

    const chosenBackgroundImageFilename = 'background.png';
    const backgroundImageUrl = `/${chosenBackgroundImageFilename}`;
    const backgroundOpacityValue = 0.6;
    const tintOpacityValue = 0.4;
    const imageTileSize = '40%';

	const tintColorRGB = '170, 170, 170';

    const backgroundStyle = `
        position: absolute;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background-image: 
        linear-gradient(rgba(${tintColorRGB}, ${tintOpacityValue}), rgba(${tintColorRGB}, ${tintOpacityValue})),
        url('${backgroundImageUrl}');
        background-size: ${imageTileSize};
        background-position: center;
        background-repeat: repeat;
        background-attachment: scroll;
        opacity: ${backgroundOpacityValue};
    `;

    // function to calculate opacity based on index
    function getOpacity(index: number): number {
        const rowIndex = Math.floor(index / columns);
        const colIndex = index % columns;
        const lastRowIndex = rows - 1;

        // calculate opacity for the first row (index 0)
        if (rowIndex === 0) {
            const opacity = 0.1 + (1.0 - 0.1) * (colIndex / (columns - 1));
            return opacity;
        }

        // calculate opacity for the last row
        if (rowIndex === lastRowIndex) {
            const opacity = 1.0 + (0.1 - 1.0) * (colIndex / (columns - 1));
            return opacity;
        }

        // default opacity for all middle rows
        return 1.0; // fully opaque (0% transparent)
    }

</script>

<!-- interference -->

<!-- <div class="relative bg-zinc-200">

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
        </h1>
		
		<h1 class="text-4xl font-interference text-right w-[90vmin] font-bold mt-2">
			<br>
            JUNE 19 + 20
			<br>
            5PM - 8PM
        </h1>

		<br>

        <div class="text-2xl font-interference text-right w-[90vmin] font-bold mt-2">
            Speicher XI A
            <br>
            Halle 1
        </div>

    </div>

</div> -->

<!-- mix -->

<!-- <div class="relative bg-zinc-200">

    <div style="{backgroundStyle}"></div>

    <div class="p-4 min-h-screen flex flex-col items-center justify-center mx-4" style="position: relative; z-index: 1;">
        
		<h1 class="text-8xl text-left w-[90.5vmin] font-tiny5 font-bold mb-0">
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

        <h1 class="text-6xl font-tiny5 text-right w-[90vmin] font-bold mt-2">
			MASTER EXHIBITION
			<br>
        </h1>
		
		<h1 class="text-5xl font-tiny5 text-right w-[90vmin] font-bold mt-2">
			Lucca Vitters
        </h1>
		
		<h1 class="text-4xl font-interference text-right w-[90vmin] font-bold mt-2">
			<br>
            JUNE 19 + 20
			<br>
            5PM - 8PM
        </h1>

        <div class="text-2xl font-interference text-right w-[90vmin] font-bold mt-2">
            Speicher XI A
            <br>
            Halle 1
        </div>

    </div>

</div> -->

<!-- tiny5 -->

<!-- <div class="relative bg-zinc-200">

    <div style="{backgroundStyle}"></div>

    <div class="p-4 min-h-screen flex flex-col items-center justify-center mx-4" style="position: relative; z-index: 1;">
        
		<h1 class="text-8xl text-left w-[90.5vmin] font-tiny5 font-bold mb-0">
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

        <h1 class="text-6xl font-tiny5 text-right w-[90vmin] font-bold mt-2">
			MASTER EXHIBITION
			<br>
        </h1>
		
		<h1 class="text-5xl font-tiny5 text-right w-[90vmin] font-bold mt-2">
			Lucca Vitters
        </h1>
		
		<h1 class="text-4xl font-tiny5 text-right w-[90vmin] font-bold mt-2">
			<br>
            JUNE 19 + 20
			<br>
            5PM - 8PM
        </h1>

        <div class="text-2xl font-tiny5 text-right w-[90vmin] font-bold mt-2">
            Speicher XI A
            <br>
            Halle 1
        </div>

    </div>

</div> -->

<!-- sharepic -->

<div class="relative bg-zinc-200">

    <div style="{backgroundStyle}"></div>

    <div class="p-4 min-h-screen flex flex-col items-center justify-center mx-4" style="position: relative; z-index: 1;">
        
		<h1 class="text-7xl text-left w-[90.5vmin] font-tiny5 font-bold mb-0">
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

        <h1 class="text-5xl font-tiny5 text-right w-[90vmin] font-bold mt-2">
			MASTER EXHIBITION
			<br>
        </h1>
		
		<h1 class="text-3xl font-tiny5 text-right w-[90vmin] font-bold mt-2">
            JUNE 19 + 20 &nbsp| &nbsp5pm - 8pm
        </h1>

        <div class="text-3xl font-tiny5 text-right w-[90vmin] font-bold mt-2">
            Speicher XIa &nbsp| &nbspHalle 1
        </div>

    </div>

</div>

<!-- square -->

<!-- <div class="relative bg-zinc-200">

    <div style="{backgroundStyle}"></div>

	<div style="position: relative; z-index: 1;">

        <div class="w-[100vmin] h-[100vmin]">
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
	</div>
</div> -->

<style>
    @media print {
        /* target the dedicated background div by its inline style presence */
        .relative > div[style*="background-image"] { /* a bit more specific selector */
            -webkit-print-color-adjust: exact !important;
            print-color-adjust: exact !important;
        }
        h1, .text-3xl {
            color: #000000 !important; /* ensure text is black for print */
            text-shadow: none !important;
        }
    }
</style>