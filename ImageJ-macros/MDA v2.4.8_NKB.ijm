/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//   MDA: Membrane Displacement Analysis
//   Copyright (C) 2021  Lenard M. Voortman, Menno Spits
//
//   This MDA macro quantifies displacement in membrane like structures
//
//   HOWTO:   - Open timelapse dataset (can be z-stack and/or multichannel)
//            - Add ROIs to ROI manager
//            - Start macro
//            - Analysis will be performed on all channels on all ROIs
//            - ROIfile and cropped tifs are saved in directory of source
//              file, results table needs to be saved manually.
//
//   Authors:   Lenard M. Voortman, Menno Spits
//   Version:   2.4 - now supports single channel as well as multi
//
//   Citation:  Spits, et al. "Mobile late endosomes modulate peripheral 
//              endoplasmic reticulum network architecture." EMBO reports 
//              22.3 (2021): e50815.
//
//    This program is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License.
// 
//    This program is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
// 
//    You should have received a copy of the GNU General Public License
//    along with this program.  If not, see <https://www.gnu.org/licenses/>.


////////////////////////////////////////
////////////////////////////////////////
// MACRO SETTINGS:
////////////////////////////////////////

max_distance = 10; // pixels per frame
nBins = 10;

// currently configured for 2 channel images (ch1: TMD-GFP, ch2: Lysosomes)
// NKB: CH1: DP, CH2: VAPB
//preMeanFilterArray = newArray(0,0);
thresholdArray = newArray("Triangle", "Percentile");
//thresholdArray = newArray("Percentile","Triangle");
//thresholdArray = newArray("Huang","Moments");

////////////////////////////////////////

setOption("black background", true);
run("Options...", "iterations=1 count=1 black do=Nothing");
run("Colors...", "foreground=white background=black selection=yellow");

nResults_now = nResults;
original = getTitle();
dir = getDirectory("image");
filename = File.nameWithoutExtension;
// prepare a folder to output the images
output_dir = dir + File.separator + filename + "_MDA" + File.separator ;
File.makeDirectory(output_dir);

nRoi = roiManager("count");

roiManager("Save", output_dir+filename+"_ROI.zip");

setBatchMode("hide");

for (i=0 ; i<nRoi; i++) {
	selectWindow(original);
	
	roiManager("select", i);
	run("Duplicate...", "duplicate");

	rename("input");
	getDimensions(width, height, channels, slices, frames);
	nChannels = channels;
	
	run("Split Channels");
	for(c=0; c<nChannels; c++){
		selectWindow("C"+(c+1)+"-input");
		rename("cinput");
		
		///////////////////
		
		selectWindow("cinput");

		//if(preMeanFilterArray[c] > 0){
		//run("Mean...", "radius="+preMeanFilterArray[c]+" stack");
		//}
	
		///////////////////
		
		selectWindow("cinput");
		if (slices > 1){
			run("Z Project...", "projection=[Max Intensity] all");
			selectWindow("cinput");
			close();
			selectWindow("MAX_cinput");
			rename("cinput");
		}

		///////////////////
	
		selectWindow("cinput");
		run("Gaussian Window MSE", "sigma=4 maximal_distance="+max_distance);
		selectWindow("cinput optic flow");
		close();

		///////////////////
	
		selectWindow("cinput");
		run("Duplicate...", "duplicate range=2-" + frames);
		rename("Result of cinput-1");

		run("Duplicate...", "title=[Mask of cinput] duplicate");
		
		selectWindow("Mask of cinput");
		run("Median...", "radius=1 stack");
		//run("Subtract Background...", "rolling=20 stack");
		run("Convert to Mask", "method="+thresholdArray[c]+" background=Dark calculate black");
		run("Divide...", "value=255 stack");
		setMinAndMax(0, 1);
		
		selectWindow("cinput flow vectors");
		run("Split Channels");
		
		selectWindow("C1-cinput flow vectors");
		run("Multiply...", "value="+max_distance+" stack");
		setMinAndMax(0, max_distance);
	
		imageCalculator("Multiply create 32-bit stack", "Mask of cinput","C1-cinput flow vectors");
		selectWindow("Result of Mask of cinput");
		rename("C1-cinput");

		////////////////////////////////////////
		
		selectWindow("C2-cinput flow vectors");
		close();
		selectWindow("C1-cinput flow vectors");
		close();
		
		selectWindow("Result of cinput-1");
		run("32-bit");
		selectWindow("Mask of cinput");
		run("32-bit");
	
		selectWindow("cinput");
		close();
	
		////////////////////////////////////////
	
	
		selectWindow("Mask of cinput");
		run("8-bit");
		
		histMin = 0;
		histMax = max_distance;
		
		counts_accum = newArray(nBins);
		area_accum = 0;
		
		for (n = 0; n < nBins; n++) {
			counts_accum[n] = 0;
		}
		
		for (iF = 0; iF < frames - 1; iF++) {
			selectWindow("Mask of cinput");
			Stack.setFrame(iF+1);
			run("Create Selection");
			//run("Make Inverse");
			
			selectWindow("C1-cinput");
			Stack.setFrame(iF+1);
			run("Restore Selection");
			//getStatistics(area);
			getRawStatistics(area);
			area_accum += area;
			
			getHistogram(values, counts, nBins, histMin, histMax);
			
			for (n = 0; n < nBins; n++) {
				//print("value: " + values[n] + " counts: " + counts[n]);
				counts_accum[n] += counts[n];
			}
		}
	
		setResult("Label", nResults_now+nChannels*i+c, original+"_c"+(c+1)+"_ROI"+(i+1));
		setResult("area [#pix*#frames]", nResults_now+nChannels*i+c, area_accum);
		//print("cinput: area: " + area_accum);
		for (n = 0; n < nBins; n++) {
			//print("cinput: value: " + values[n] + " counts: " + counts_accum[n]);
			setResult("histcount (#pix/frame "+values[n]+") [%]", nResults_now+nChannels*i+c, counts_accum[n]/area_accum);
			saveAs("Results", output_dir+filename+"_Results.csv");
		}

		////////////////////////////////////////
		
		selectWindow("Mask of cinput");
		run("32-bit");
	
		//run("Merge Channels...", "c1=[Result of cinput-1] c2=C1-cinput c3=[Mask of cinput] create");
		run("Merge Channels...", "c1=[Result of cinput-1] c2=C1-cinput c3=[Mask of cinput] create ignore");
		Stack.setActiveChannels("110");
		saveAs("Tiff", output_dir+filename+"_c"+(c+1)+"_ROI"+(i+1)+".tif");
		
		////////////////////////////////////////
	}
}

run("Close All");