# FNNDSC - Cortical Thickness

## bin/
This folder includes:
- All the third-party executables used by this project.
- Python Environment called pyenv and the requirements.txt.

## code/
This folder includes all the scripts made for this project.

## code/cortical
This folder includes all the scripts made for this project.

## code/skeleton
This folder includes all the python scripts made to build a homotopic skeleton of the cortical plate.
## code/skeleton/align_nii.py
Script useful to align two nii files to the same center.
## code/skeleton/FCM.py
Fuzzy C Means, Soft Clustering. General Implementation Class
## code/skeleton/MRI_FCM.py
Fuzzy C Means, Soft Clustering. Usign FCM.py for MRI intensity segmentation purpose.
## code/skeleton/sFCM.py
Fuzzy Spatial C Means, Soft Clustering. General Implementation Class
## code/skeleton/MRI_sFCM.py
Fuzzy Spatial C Means, Soft Clustering. Usign sFCM.py for MRI intensity segmentation purpose.
## code/skeleton/GMM.py
Gaussian Mixture Model, Soft Clustering CSF/GM considering intensity.
## code/skeleton/pial_surface.py
Pial Surface extraction (inner boundary of CSF) expanding White Matter till CSF.

## code/surfaceExtraction/analyzeTxt.py
Script useful to analyze data (RMS, Average, Std dev, Min, Max) enlisted in a txt file.
## code/surfaceExtraction/expand_from_white_fetal.pl
Script capable of expanding white matter obj till laplacian field for cp surface extraction.
## code/surfaceExtraction/laplace.pl
Script that generates a laplacian field for Cortica Plate given its volume file.

## code/utils/convertmnc.bash
Script that converts all mnc files of a given path to nii.
## code/utils/morphometrics.bash
Script that calculates cortical thickness using three different methods.
## code/utils/openfreeviewResults.bash
Script that opens in freeeview all important files of a given case.
## code/utils/runAnalysis.bash
Script that run analyzeTxt.py for all txt files inside a folder (recursively).
## code/utils/runPipelineSamples.bash
Script that run the current pipeline for all cases in Samples folder.
## code/utils/runPipelineSamples.bash
Script that run the surface extraction for all cases in Samples folder.