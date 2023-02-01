/*
 * Given a folder of image hypestacks separated by channel (ideally ilastik-generated segmentation tiffs), 
 * perform a multiply calculation function to
 * get an output of the overlap between the 2 channels. 
 * 
 * 
 * 2022-0202 Navanaeetha Krishnan Bharathan nfb5367@psu.edu
 * 
 */
#@ boolean (label = "CH2 in different dir from CH1") CH2_in_diff_dir_than_CH1
#@ File (label = "Input CH1 directory", style = "directory") input_CH1
#@ File (label = "Input CH2 directory", style = "directory") input_CH2
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".tif") suffix


if (CH2_in_diff_dir_than_CH1) {
	list_CH1 = getFileList(input_CH1);
	list_CH1 = Array.sort(list_CH1);

	list_CH2 = getFileList(input_CH2);
	list_CH2 = Array.sort(list_CH2);

	for (i = 0; i < list_CH1.length; i++) {
		CH1_file = list_CH1[i];
		CH2_file = list_CH2[i];

		open(input_CH1 + File.separator + CH1_file);
		open(input_CH2 + File.separator + CH2_file);

		imageCalculator("Multiply create stack", CH1_file, CH2_file);
		merged_name = substring(CH1_file,2);//change the number in the substring depending on how many characters you want to remove from the front, incl channel names, etc...
		saveAs("tiff", output + File.separator + "Multiply" + merged_name);
		run("Close All");
	}
}

