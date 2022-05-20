# Cortical Thickness - Folder Structure

## bin/
This folder includes:
- All the third-party executables used by this project.
- Python Environment called pyenv and the requirements.txt.

## lib/
This folder includes third-party libraries.

## share/
This folder includes resources used by the scripts such as templates and transform files.

## code/
This folder includes all the scripts made for this project.

## code/corticalThickness.py
Script useful to parse cmd line args for Cortical Thickness pipeline.
## code/corticalThicknessDocker.py
Script useful to parse cmd line args for Cortical Thickness pipeline using Docker Image.

## code/SKELETON-pipeline-0.1.bash
Main Script, It includes all the steps of the pipeline, mainly focused in the CP outer boundary extraction using homotopic skeletonization method, but it also calls/uses the surface extractions scripts.
## code/WHITE-EXTRACTION.bash
Script useful for white matter surface extraction.
## code/SURFACE-EXTRACTION.bash
Script useful for gray matter surface extraction expanding WM till the Skeleton extracted previously.

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

## deploy/
This folder includes all files related to docker deployment.
## deploy/cmds.md
File with indications about Docker.
## deploy/Dockerfile
File with instructions to build a docker image.
## deploy/runBash.sh
Script to create a docker container using cortical-thickness image.
## deploy/runScript.sh
Script to call the pipeline using docker container.

## refs/
This folder includes useful technical resources for the understading of the project.
## refs/Pipeline_Overview.pdf
Slides explaining each step of the pipeline.
## refs/ProyectProposal.pdf
Background Knowledge about the project and the goal of this pipeline in it.
## refs/spatialFuzzyC.pdf
Technical Paper used for the development of sFCM (spatial Fuzzy Clustering Method).
## refs/VipSkeleton.txt
Command Arguments of the executable capable of making the homotopic skeleton.
