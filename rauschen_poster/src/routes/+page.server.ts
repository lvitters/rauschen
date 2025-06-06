// src/routes/your-page-route/+page.server.ts
import { readdirSync } from 'node:fs';
import { join } from 'node:path';

export async function load({ setHeaders }) {
    // this path should point to your screenshots folder within the 'static' directory.
    // SvelteKit serves files from 'static' at the root.
    // for 'fs' operations, you need the file system path.
    const imageDirectoryPath = join(process.cwd(), 'static', 'saved'); // adjust 'saved' if your folder is named differently

    let allImageFilenames: string[] = [];

    try {
        const filenames = readdirSync(imageDirectoryPath);
        // filter for common image file extensions
        allImageFilenames = filenames.filter(name =>
            /\.(png|jpe?g|gif|webp)$/i.test(name)
        );
    } catch (error) {
        console.error(`Error reading image directory at '${imageDirectoryPath}':`, error);
        // return an empty array or an error state to the client
        return {
            imageFilenames: [],
            error: 'Failed to load images from the server.'
        };
    }

    // to ensure the client gets a fresh list on reloads,
    // especially if there were any doubts about SvelteKit's default caching for this load function.
    // for simple file reads like this, it might not always be strictly necessary,
    // but it explicitly states the caching intent.
    setHeaders({
        'Cache-Control': 'no-cache, no-store, must-revalidate'
    });

    return {
        imageFilenames: allImageFilenames // send the complete list of filenames
    };
}