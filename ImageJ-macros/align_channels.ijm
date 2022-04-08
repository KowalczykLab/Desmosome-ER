/*
 * Note: This macro is tailored for two channel (DP and VAPB) datasets.
 * It will 
 * - convert the registered image into 16-bit
 * - set LUTs to "BOP orange" and "BOP blue"
 * - set brightness and contrast for the DP channel to compensate for camera offset
 * 
 * Input: Folder of unaligned two-channel hyperstacks + NanoJ Translation Mask file
 * Output: A folder of aligned two-channel hyperstacks
 * 

 * 
 * William Giang
 * 2021-06-28
 */

#@ File (label = "Input directory (unaligned images)", style = "directory") input
#@ File (label = "Output directory (aligned images)", style = "directory") output
#@ File (label = "NanoJ Translation Mask file", style="open") translation_mask
#@ String (label = "File suffix", value = ".tif") suffix

setBatchMode(true);
processFolder(input);
setBatchMode(false);

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], suffix)){
			processFile(input, output, list[i], translation_mask);
		}
	}
}

function processFile(input, output, file, translation_mask) {
	print(file);
	run("Bio-Formats Importer", "open="+ input + File.separator + list[i] + " color_mode=Default view=Hyperstack stack_order=XYCZT");
	orig_name = File.nameWithoutExtension;

	// save dimensions for "Stack to Hyperstack" later
	getDimensions(width, height, nChannels, slices, nFrames);

	run("Register Channels - Apply", "open=["+translation_mask+"]");
	registered_title = getTitle();
	selectWindow(registered_title);
	run("Stack to Hyperstack...", "order=xyczt(default) channels="+nChannels+" slices="+slices+" frames="+nFrames+" display=Composite");
	selectWindow(registered_title);
	run("Conversions...", " ");
	run("16-bit");

	// Set LUTs. 
	Stack.setChannel(1);
	run("BOP orange");
	//setMinAndMax(100, 200);  // DP channel is N2V-processed (camera offset at 100). 
	Stack.setChannel(2);
	run("BOP blue");
	resetMinAndMax(); // 3DRCAN normalizes the dataset to fill 16-bit, so 0-65535 is good

	saveAs("Tiff", output + File.separator + orig_name);
	
	run("Close All");
}
