import fs from 'fs'; // Or 'node:fs' if @types/node is installed and working correctly
import path from 'path'; // Or 'node:path'

// Define the structure of the data returned by the load function
interface LoadData {
  imageFilenames: string[];
  error?: string; // Optional field for error messages during loading
}

// The load function runs on the server to get the list of image filenames
export async function load(): Promise<LoadData> {
    // Resolve the absolute path to the static screenshots directory on the server
    const imageDirPath = path.resolve('./static/saved');

    // Initialize variables
    let imageFilenames: string[] = []; // Explicitly typed as string array
    let errorMessage: string | undefined = undefined; // Declared to hold potential errors

    try {
        console.log(`Attempting to read directory: ${imageDirPath}`);
        // Read all file names from the directory
        const files = fs.readdirSync(imageDirPath);

        // Filter the list to include only common image file types
        imageFilenames = files.filter(file =>
            /\.(jpg|jpeg|png|gif|webp)$/i.test(file)
        );

        // Sort the filenames alphabetically
        imageFilenames.sort((a, b) => a.localeCompare(b));

        console.log(`Successfully found ${imageFilenames.length} images.`);

    } catch (error: unknown) { // Catch variable defaults to 'unknown'
        console.error(`Error reading image directory '${imageDirPath}':`, error);

        // --- Safely handle the 'unknown' error type ---
        let message = 'An unknown error occurred while reading images.';
        let errorCode: string | undefined = undefined;

        if (error instanceof Error) {
            // If it's a standard Error object, use its message
            message = error.message;
            // Check for the common 'code' property on Node.js system errors
            if ('code' in error && typeof (error as any).code === 'string') {
                errorCode = (error as any).code;
            }
        } else if (typeof error === 'string') {
            // If a string was thrown, use it as the message
            message = error;
        }
        // --- End of safe error handling ---

        console.error(`Processed error message: ${message}`);
        // Assign the processed message to the variable declared outside the catch block
        errorMessage = `Failed to load images: ${message}`;

        // Provide a more specific message if the directory wasn't found
        if (errorCode === 'ENOENT') {
            console.error("Directory does not exist. Please create 'static/saved' and add images.");
            errorMessage = "Screenshots directory ('static/saved') not found.";
        }
    }

    // Return the result, including the list of filenames and any error message
    return {
        imageFilenames,
        error: errorMessage // Include the errorMessage (will be undefined if no error)
    };
}