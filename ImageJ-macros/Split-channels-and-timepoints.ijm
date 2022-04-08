/*
 * 
 * Input: Folder of hyperstacks
 * Output: A folder for each channel (if desired, with each timepoint split)
 * 
 * William Giang
 * 2021-06-20
 */

#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ boolean (label = "Split timepoints") want_to_split_timepoints
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
			processFile(input, output, list[i]);
		}
	}
}

function processFile(input, output, file) {
	print(file);
	run("Bio-Formats Importer", "open="+ input + File.separator + list[i] + " color_mode=Default view=Hyperstack stack_order=XYCZT");

	orig_name = File.nameWithoutExtension;
	id = getImageID();
	
	// get the number of channels and frames (time points)
	getDimensions(width, height, nChannels, slices, nFrames);

	
	for (channel = 1; channel <= nChannels; channel++) {
		selectImage(id);
		nameWithCH = "C"+channel+"-"+orig_name;
		rename(nameWithCH);

		CH_dir = output + File.separator + "C" + channel;
		File.makeDirectory(CH_dir);

		if (want_to_split_timepoints) {
			for (frame = 1; frame <= nFrames; frame++) {
				selectWindow(nameWithCH);
				Stack.setPosition(channel, 1, frame);
				run("Reduce Dimensionality...", "slices keep");
				id_reduced = getImageID();
				selectImage(id_reduced);
				rename(nameWithCH + "_T-"+ IJ.pad(frame, 4));
				name_timepoint = getTitle();
				//setMinAndMax(100, 300); // assume camera offset of 100 and higher than 8bit image
				run("Grays");
				saveAs("Tiff", CH_dir + File.separator + name_timepoint);
			}
		}
		else {
			run("Duplicate...", "title=["+orig_name+"] duplicate channels="+channel);
			run("Grays");
			saveAs("Tiff", CH_dir + File.separator + orig_name);
			}
		}
	run("Close All");
}
