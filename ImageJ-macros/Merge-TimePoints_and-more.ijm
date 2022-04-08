/*
 * Given a folder of hyperstacks (assumed to be split time points with equivalent number of time points for all),
 * merge back into a hyperstack. 
 * 
 * The original motivation is to merge timepoints which have been processed by N2V or 3DRCAN back into one file. 
 * 2021-12-14: Added a Boolean script parameter to deal with N2V-processed files with a _N2V suffix
 * 2021-12-15: Added Boolean script parameters for conversion to 16bit and MIP. Does not scale when converting.
 * 
 * William Giang
 * 
 */

#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".tif") suffix
#@ String (label = "Number of Channels", value = "2") n_channels
#@ String (label = "Number of z-slices", value = "7") n_slices
#@ String (label = "Number of Time points", value = "16") n_frames
#@ Boolean (label= "_N2V suffix?", value=false, persist=false) has_N2V_suffix
#@ Boolean (label= "Convert to 16 bit?", value=false, persist=false) want_16bit
#@ Boolean (label= "Want a maximum intensity projection instead?", value=false, persist=false) want_MIP


setBatchMode(true);
run("Conversions...", " ");
processFolder(input);
setBatchMode(false);

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list_all = getFileList(input);
	list_all = Array.sort(list_all);

	// Goal for following lines (before for-loop) is to get an array of unique filename patterns 
	// for loading every timepoint of each dataset.
	// 
	// Since each split-timepoint has the string "_T-" followed by a four digit number corresponding to each timepoint,
	// we'll use regular expressions to find this substring and remove its presence for all filenames.
	// Then we'll get another array with only the unique elements.
	reg_exp = "_T-\\d{4}"; // reg. expression for "_T-" followed by four digits
	if (has_N2V_suffix) reg_exp = "_T-\\d{4}_N2V"; 
	
	list_replaced = ReplaceStringsInArray(list_all, reg_exp, ""); 
	list = ArrayUnique(list_replaced);
	
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], suffix))
			processFile(input, output, list[i], suffix, n_channels, n_slices, n_frames);
	}
}

function processFile(input, output, file, suffix, n_channels, n_slices, n_frames) {
	 
	sequence = replace(file, suffix, ""); // prepare name of pattern for "Image Sequence..."
	
	run("Image Sequence...", "open="+input+ " file=" +sequence + " sort"); // load all timepoints
	run("Stack to Hyperstack...", "order=xyczt(default) channels="+n_channels+" slices="+n_slices+" frames="+n_frames +" display=Grayscale");
	rename(sequence);
	
	if (want_16bit) run("16-bit");
	if (want_MIP) run("Z Project...", "projection=[Max Intensity] all");
	
	saveAs(".tif", output + File.separator + sequence);
	
	run("Close All");
	
}


//thanks Rainer M. Engel! https://imagej.nih.gov/ij/macros/Array_Functions.txt
function ArrayUnique(array) {
	array 	= Array.sort(array);
	array 	= Array.concat(array, 999999);
	uniqueA = newArray();
	i = 0;	
   	while (i<(array.length)-1) {
		if (array[i] == array[(i)+1]) {			
		} else {
			uniqueA = Array.concat(uniqueA, array[i]);
		}
   		i++;
   	}
	return uniqueA;
}

function ReplaceStringsInArray(array, old, new) {
	new_array = newArray();
	for (i=0; i < array.length; i++){
		new_element = replace(array[i], old, new);
		new_array = Array.concat(new_array, new_element);
	}
	return new_array;
}
