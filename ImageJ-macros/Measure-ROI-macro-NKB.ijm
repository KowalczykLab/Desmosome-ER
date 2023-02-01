/*
 * Given a Z-projected image where you already have the ROIs of particles, 
 * load those ROIs on another image and the macro will measure them
 * and save the Results table for that image in its folder.
 * Also set the scale of the image to its micron value.
 * For 100X images, 1 pixel=0.065 micron
 * 
 * 
 * 2022-02-09 Navanaeetha Krishnan Bharathan nfb5367@psu.edu
 * 
 */
dir = getDirectory("Select A folder");
filename = File.nameWithoutExtension;
//output_dir = output + File.separator + filename;

run("Set Scale...", "distance=1 known=0.065 unit=micron global");
roiManager("Measure");
merged_name = substring(filename,2);
saveAs("Results",dir+File.separator+"Multiply"+merged_name+".csv");
roiManager("Deselect");
roiManager("Delete");

run("Close All");