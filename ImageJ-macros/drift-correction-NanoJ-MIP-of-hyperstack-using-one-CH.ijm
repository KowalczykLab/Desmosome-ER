/*
 * Drift correction (XY) for hyperstacks (multiple channels, z-positions, and timepoints) 
 * 
 * It will 
 * - Use NanoJ-Core's Estimate Drift on a MIP of a chosen channel
 * - Save the drift correction file in a folder
 * - Apply the drift correction to each channel's z-position and then recombine
 * 
 * Warning: Downside is the manual choosing of the drift table
 * 
 * Input: 
 * 		- Folder of unaligned hyperstacks
 * 		- Channel # for drift correction 
 * 		- File suffix
 * Output: 
 * 		- Folder of drift-corrected hyperstacks
 * 		- Folder of drift tables
 * 

 * 
 * William Giang
 * 2021-10
 */

#@ File (label = "Input directory (unaligned images)", style = "directory") input
#@ File (label = "Output directory (aligned images)", style = "directory") output
#@ File (label = "NanoJ Drift Table Output directory", style = "directory") drift_table_dir
#@ String (label = "Channel to use for drift correction", value = "2") drift_correction_num
#@ String (label = "File suffix", value = ".tif") suffix

//setBatchMode(true);
processFolder(input);
//setBatchMode(false);

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], suffix)){
			processFile(input, output, list[i], drift_correction_num, drift_table_dir);
		}
	}
}

function processFile(input, output, file, drift_correction_num, drift_table_dir) {
	print(file);
	run("Bio-Formats Importer", "open="+ input + File.separator + list[i] + " color_mode=Default view=Hyperstack stack_order=XYCZT");
	orig_name = File.nameWithoutExtension;
	orig_title = getTitle(); // "foo.tif"
	
	// save nChannels and slices for looping
	getDimensions(width, height, nChannels, slices, nFrames);

	// initialize an array to hold the names of the drift corrected single-channel z-stacks
	//single_channel_DC_z_stack_names = newArray("C1-" + orig_name + "_DC.tif");
	// initialize an array to be 

	// initialize an array to hold the names of the drift corrected single-channel z-stacks
	DC_channels_array_for_merging = newArray("c1=C1-" + orig_name + "_DC.tif");
	for (i=2; i <= nChannels; i++){
		additional_CH = "C" + i + "-"+ orig_name + "_DC.tif";
		DC_channels_array_for_merging = Array.concat(DC_channels_array_for_merging, "c"+i+"="+additional_CH);
	}
	DC_channels_str_for_merging = String.join(DC_channels_array_for_merging, " ");
	
	// NanoJ's Drift Correction can't handle hyperstacks.
	// Our drift is pretty much only XY, so having it estimate on a MIP is ok
	// Then we take the drift table and apply it to each z-plane.
	selectWindow(orig_title);
	run("Z Project...", "projection=[Max Intensity] all");
	if (nChannels > 1) run("Split Channels");

	// We'll use the ER channel instead of DP because it's present in all frames 
	drift_correction_ch = "C" + drift_correction_num;
	
	MIP_for_estimating_drift = drift_correction_ch + "-MAX_" + orig_title; // "C#-MAX_foo.tif"
	drift_table_full_dir = drift_table_dir + File.separator + orig_name + ".njt";
	selectWindow(MIP_for_estimating_drift); // "C2-MAX_foo.tif"
	run("Estimate Drift", "time=1 max=0 reference=[previous frame (better for live)] choose="+drift_table_full_dir);

	selectWindow(orig_title); // "foo.tif"
	if (nChannels > 1) run("Split Channels");

	
	// Process the split-channel hyperstacks.
	for (j = 1; j <= nChannels; j++){
		current_channel_name = "C" + j + "-" + orig_title; // "C#-foo.tif"
		selectWindow(current_channel_name);

		current_channel_name_without_tif = replace(current_channel_name, ".tif", ""); // "C#-foo"
		rename(current_channel_name_without_tif);
		selectWindow(current_channel_name_without_tif);
		
		// As far as I know, there's no easy way to split by Z.
		// So we'll swap Z and channels using Re-order Hyperstack and then "Split Channels" (Z!)	
		run("Re-order Hyperstack ...", "channels=[Slices (z)] slices=[Channels (c)] frames=[Frames (t)]");
		run("Split Channels");
		// now we have single slice timelapses like C1-C2-foo.tif, C2-C2-foo.tif
		// that need to be drift corrected using the results from the MIP timelapse.  
		for (i = 1; i <= slices; i++) {
	    	selectWindow("C"+i+"-"+current_channel_name_without_tif); // "C#-C#-foo"
	    	//run("Correct Drift", "choose=" + drift_table_full_dir);
	    	run("Correct Drift", drift_table_full_dir);
	    	run("Conversions...", " ");
			run("16-bit");
			
	    	// after running "Correct Drift", it adds " - drift corrected" to the filename
			// e.g. "C1-C2-foo - drift corrected"
			// but spaces are annoying, so we'll change to C#-C#-foo_DC
	
			rename("C"+i+"-"+current_channel_name_without_tif + "_DC.tif"); // "C#-C#-foo_DC"
			
			//print(getTitle());
			//saveAs("Tiff", output + File.separator + getTitle());
			
			// Close the uncorrected single slice timepoint
	    	selectWindow("C"+i+"-"+current_channel_name_without_tif);
	    	close();
		}
		
		// A channel's individual slice timelapses are drift corrected

		// Initialize an array with a string for channel1
		//array_for_channel_merging = newArray("c1=C1-" + current_channel_name + " - drift corrected");
		array_for_channel_merging = newArray("c1=C1-" + current_channel_name_without_tif + "_DC.tif"); //"c1=C1-C#-foo_DC"
		for (i=2; i <= slices; i++){ // these "channels" are actually slices
			//CH_name = "C" + i + "-"+ current_channel_name + " - drift corrected";
			CH_name = "C" + i + "-"+ current_channel_name_without_tif + "_DC.tif"; // "C#-C#-foo_DC"
			array_for_channel_merging = Array.concat(array_for_channel_merging, "c"+i+"="+CH_name);
		}
		
		ch_and_names_for_merging = String.join(array_for_channel_merging, " ");
		print("ch_and_names_for_merging:" + ch_and_names_for_merging);
		
		run("Merge Channels...", ch_and_names_for_merging + " create ignore"); // recombine the split z-slices
		run("Re-order Hyperstack ...", "channels=[Slices (z)] slices=[Channels (c)] frames=[Frames (t)]");
		single_channel_DC_z_stack_name = "C" + j + "-" + orig_name + "_DC.tif";
		rename(single_channel_DC_z_stack_name);
		//print("single_channel_DC_z_stack_name:" + single_channel_DC_z_stack_name);
	} // end loop over nChannels

	//DC_channel_names = String.join(single_channel_DC_z_stack_names, " ");
	//print("DC_channel names: " + DC_channel_names);
	run("Merge Channels...", DC_channels_str_for_merging + " create ignore");
	//rename(orig_title + "_DC");
	saveAs("Tiff", output + File.separator + orig_name + "_DC");
	run("Close All");
	//File.delete(drift_table_full_dir);
}
