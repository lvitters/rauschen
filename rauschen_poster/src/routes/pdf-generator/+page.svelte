<script lang="ts">
    // define the expected shape of the data prop
    interface LoadData {
      imageFilenames: string[];
    }

    // receive data from the server load function
    export let data: LoadData;

    // extract all image filenames, provide an empty array as a fallback
    const allImages = data?.imageFilenames || [];

    // group images into pairs for PDF pages
    const imagePairs: string[][] = [];
    for (let i = 0; i < allImages.length; i += 2) {
        imagePairs.push(allImages.slice(i, i + 2));
    }

    // function to get filename without extension for cleaner display
    function getDisplayName(filename: string): string {
        return filename.replace(/\.[^/.]+$/, "");
    }
</script>

<!-- PDF Layout: Each page contains two images with filenames -->
{#each imagePairs as pair, pageIndex}
    <div class="a2-page" class:page-break={pageIndex > 0}>
        
        <!-- First image -->
        <div class="image-container">
            <div class="image-wrapper">
                <div class="image-with-label">
                    <img 
                        src="/prints/{pair[0]}" 
                        alt="screenshot {pair[0]}"
                        class="screenshot-image"
                    />
                    <div class="filename-label">
                        {getDisplayName(pair[0])}
                    </div>
                </div>
            </div>
        </div>

        <!-- Second image (if exists) -->
        {#if pair[1]}
            <div class="image-container">
                <div class="image-wrapper">
                    <div class="image-with-label">
                        <img 
                            src="/prints/{pair[1]}" 
                            alt="screenshot {pair[1]}"
                            class="screenshot-image"
                        />
                        <div class="filename-label">
                            {getDisplayName(pair[1])}
                        </div>
                    </div>
                </div>
            </div>
        {:else}
            <!-- Empty space if odd number of images -->
            <div class="image-container empty"></div>
        {/if}

    </div>
{/each}

<style>
    .a2-page {
        width: 420mm;  /* A2 width: 420mm */
        height: 594mm; /* A2 height: 594mm */
        padding: 0mm;
        background: white;
        display: flex;
        flex-direction: column;
        gap: 0mm; /* Increased gap to prevent border overlap */
        box-sizing: border-box;
        position: relative;
    }

    .page-break {
        page-break-before: always;
    }

    .image-container {
        flex: 1;
        background: white;
        border: 3mm solid white;
        position: relative;
        display: flex;
        flex-direction: column;
        min-height: 0; /* Important for flex child */
    }

    .image-container.empty {
        opacity: 0;
    }

    .image-wrapper {
        flex: 1;
        padding: 0mm;
        display: flex;
        align-items: center;
        justify-content: center;
        min-height: 0; /* Important for flex child */
    }

    .image-with-label {
        display: inline-block;
        position: relative;
        border: 1px solid #333;
        padding: 16mm; /* Equal 10mm padding on all sides */
    }

    /* Make top border white (invisible) on first image */
    .image-container:first-child .image-with-label {
        border-top: 1px solid white;
    }

    /* Make bottom border white (invisible) on last image */
    .image-container:last-child .image-with-label {
        border-bottom: 1px solid white;
    }

    .screenshot-image {
		width: 100%;
		height: 100%;
		object-fit: contain;
		display: block;
		transform: scale(1.05);
    }

    .filename-label {
        position: absolute;
        bottom: 0mm; /* Position filename in the bottom 10mm space */
        right: 9mm; /* Align with right edge of image (accounting for border padding) */
        text-align: right;
        font-family: 'tiny5', monospace;
        font-size: 7mm;
        color: #333;
        font-weight: 500;
        box-sizing: border-box;
    }

    /* Print styles */
    @media print {
        @page {
            size: A2;
            margin: 0;
        }

        body {
            margin: 0;
            padding: 0;
        }

        .a2-page {
            -webkit-print-color-adjust: exact !important;
            print-color-adjust: exact !important;
        }

        .screenshot-image {
            -webkit-print-color-adjust: exact !important;
            print-color-adjust: exact !important;
        }

        .filename-label {
            -webkit-print-color-adjust: exact !important;
            print-color-adjust: exact !important;
            color: #333 !important;
        }
    }

    /* Screen preview styles */
    @media screen {
        .a2-page {
            margin: 20px auto;
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
            transform: scale(0.3); /* Scale down for screen preview */
            transform-origin: top center;
            margin-bottom: 120px; /* Compensate for scaling */
        }

        body {
            background: #f5f5f5;
            padding: 20px;
        }
    }
</style>