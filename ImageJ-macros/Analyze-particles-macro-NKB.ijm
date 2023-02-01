/*
 * Given a Z-projected image (ideally ilastik-generated segmentation tiffs), 
 * with a large ROI encompasssing your particles of interest, 
 * perform Anlalze particles to get the ROIs of all particles in all timepoints
 * and save the Results table and ROIs for that image in its folder.
 * Also set the scale of the image to its micron value.
 * For 100X images, 1 pixel=0.065 micron
 * 
 * 
 * 2022-02-09 Navanaeetha Krishnan Bharathan nfb5367@psu.edu
 * 
 */
 //Select a folder to save your images.
dir = getDirectory("Select A folder");
filename = File.nameWithoutExtension;
//output_dir = output + File.separator + filename;

run("Set Scale...", "distance=1 known=0.065 unit=micron global");
roiManager("Add");
run("Clear Outside", "stack");
//roiManager("Select", 0);
roiManager("Save", dir+File.separator+filename+"-LargeROI.roi");
roiManager("Deselect");
roiManager("Delete");

run("Invert LUT");
run("Analyze Particles...", "size=4-Infinity pixel display exclude add stack");

saveAs("Results",dir+File.separator+filename+".csv");
roiManager("Save", dir+File.separator+filename+"_ROI.zip");
roiManager("Deselect");
roiManager("Delete");

run("Close All");