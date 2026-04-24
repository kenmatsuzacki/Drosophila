macro "Batch Color Threshold + Analyze Particles" {

    inputDir = getDirectory("Choose input folder");
    if (inputDir == "") exit("No input folder selected.");

    outputDir = getDirectory("Choose output folder");
    if (outputDir == "") exit("No output folder selected.");

    fileList = getFileList(inputDir);
    setBatchMode(true);
    
    // Optional: reset results at start
    run("Clear Results");
    if (isOpen("Summary")) {
        selectWindow("Summary");
        run("Close");
    }

    for (f = 0; f < fileList.length; f++) {
        name = fileList[f];
        lower = toLowerCase(name);
        
        // Process only tif/tiff files
        if (!(endsWith(lower, ".tif") || endsWith(lower, ".tiff")))
            continue;

        open(inputDir + name);
        a = getTitle();

        // -----------------------------
        // Color Thresholding
        // -----------------------------
        min = newArray(3);
        max = newArray(3);
        filter = newArray(3);

        run("HSB Stack");
        run("Convert Stack to Images");

        selectWindow("Hue");
        rename("0");
        selectWindow("Saturation");
        rename("1");
        selectWindow("Brightness");
        rename("2");
        
        
        // Change threshold here
        min[0] = 15;
        max[0] = 35;
        filter[0] = "pass";

        min[1] = 100;
        max[1] = 255;
        filter[1] = "pass";

        min[2] = 0;
        max[2] = 255;
        filter[2] = "pass";

        for (i = 0; i < 3; i++) {
            selectWindow("" + i);
            setThreshold(min[i], max[i]);
            run("Convert to Mask");
            if (filter[i] == "stop")
                run("Invert");
        }

        imageCalculator("AND create", "0", "1");
        imageCalculator("AND create", "Result of 0", "2");

        for (i = 0; i < 3; i++) {
            selectWindow("" + i);
            close();
        }

        selectWindow("Result of 0");
        close();

        selectWindow("Result of Result of 0");
        rename(a);
        
        // -----------------------------
        // Selection + mask + particles
        // -----------------------------
        run("Create Selection");
        run("Create Mask");
        run("Fill Holes");
        
        // make base filename
		dot = lastIndexOf(name, ".");
		if (dot > 0)
    		base = substring(name, 0, dot);
		else
    		base = name;
    		
    	rename(base);
        
        // Remove noise
        run("Analyze Particles...", "size=100000-Infinity display clear summarize overlay");
        
        // SAVE OVERLAY IMAGE
		run("Flatten");
		saveAs("Tiff", outputDir + base + "_overlay.tif");

        // make base filename
        dot = lastIndexOf(name, ".");
        if (dot > 0)
            base = substring(name, 0, dot);
        else
            base = name;

        // close Results if open
        if (isOpen("Results")) {
            selectWindow("Results");
            run("Close");
        }

        // close processed image
        if (isOpen(a)) {
            selectWindow(a);
            close();
            
        if (nImages > 0) {
        	while (nImages > 0) {
        		selectImage(nImages);
        		close();
        }
    }
        }
    }

    setBatchMode(false);
    showMessage("Done", "Batch processing finished. Save the result manually.");
}
