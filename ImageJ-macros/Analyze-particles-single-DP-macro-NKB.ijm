/*
 * Given a Z-projected image (ideally ilastik-generated segmentation tiffs), 
/* with a single ROI encompasssing your particles of interest, 
/* perform Anlalze particles to get the measurements of that ROI in all timepoints
 /* and save the Results table and ROIs for that image in its folder.
 /* Also set the scale of the image to its micron value.
 /* For 100X images, 1 pixel=0.065 micron
 * 
 * 
 * 2022-02-10 Navanaeetha Krishnan Bharathan nfb5367@psu.edu
 * 
 */

//#@ File (label = "Input directory", style = "directory") input_CH1
#@ File (label = "Output directory", style = "directory") output

//Select a folder to save your images.
//dir = getDirectory("Select A folder");
filename = File.nameWithoutExtension;
//output_dir = output + File.separator + filename;
//fileList = getFileList(output);

//change this value for each ROI within that image one at a time.
i=0;
	run("Set Scale...", "distance=1 known=0.065 unit=micron global");
	roiManager("Add");
	run("Clear Outside", "stack");
	//roiManager("Select", 0);
	roiManager("Save", output+File.separator+filename+"-LargeROI_"+(i+1)+".roi");
	roiManager("Deselect");
	roiManager("Delete");

	run("Invert LUT");
	run("Analyze Particles...", "size=4-Infinity pixel display exclude add stack");

	saveAs("Results",output+File.separator+filename+"_"+(i+1)+".csv");
	roiManager("Save", output+File.separator+filename+"ROI_"+(i+1)+".zip");
	roiManager("Deselect");
	roiManager("Delete");

run("Close All");