#!/bin/bash

BASE_PATH=/home/jose/Desktop/Projects/HarvardIntern # /neuro/labs/grantlab/research/MRI_processing
CASE=FCB028 # ${1}
BASE_DIR=${BASE_PATH}/jose.cisneros/CSFSegmentation/Samples # ${2}
TARGET_DIR=${BASE_PATH}/jose.cisneros/CSFSegmentation/Results # ${3}
RESOURCES_DIR=${BASE_PATH}/jose.cisneros/CSFSegmentation # ${3}

rm -rf ${TARGET_DIR}/${CASE}

mkdir -p ${TARGET_DIR}
mkdir -p ${TARGET_DIR}/${CASE}
mkdir -p ${TARGET_DIR}/${CASE}/input
mkdir -p ${TARGET_DIR}/${CASE}/temp
mkdir -p ${TARGET_DIR}/${CASE}/output


INPUT_NAME=recon_to31
INPUT_NAME_POSPROCESS=recon_to31_posprocess
INPUT_SEG_NAME=segmentation_to31_final

# Setup Dependencies
LD_LIBRARY_PATH="${RESOURCES_DIR}/lib:"$LD_LIBRARY_PATH
LD_LIBRARY_PATH="${RESOURCES_DIR}/bin/brainvisa-4.5.0/lib:"$LD_LIBRARY_PATH

#### Python venv - activate
source ${RESOURCES_DIR}/bin/pyenv/bin/activate


###############################
# Labels:
# 1: Left-Cerebral-Exterior
# 42: Right-Cerebral-Exterior
# 160: Right-Cerebral-WM
# 161: Left-Cerebral-WM
###############################

# Conversion input from .nii to .mnc
${RESOURCES_DIR}/bin/nii2mnc -clobber ${BASE_DIR}/${CASE}/${INPUT_NAME}.nii ${TARGET_DIR}/${CASE}/input/${INPUT_NAME}.mnc -float
${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/input/${INPUT_NAME}.mnc ${TARGET_DIR}/${CASE}/input/${INPUT_NAME}.nii -float
${RESOURCES_DIR}/bin/nii2mnc -clobber ${TARGET_DIR}/${CASE}/input/${INPUT_NAME}.nii ${TARGET_DIR}/${CASE}/input/${INPUT_NAME}.mnc -float

${RESOURCES_DIR}/bin/nii2mnc -clobber ${BASE_DIR}/${CASE}/${INPUT_SEG_NAME}.nii ${TARGET_DIR}/${CASE}/input/${INPUT_SEG_NAME}.mnc -float
${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/input/${INPUT_SEG_NAME}.mnc ${TARGET_DIR}/${CASE}/input/${INPUT_SEG_NAME}.nii -float
${RESOURCES_DIR}/bin/nii2mnc -clobber ${TARGET_DIR}/${CASE}/input/${INPUT_SEG_NAME}.nii ${TARGET_DIR}/${CASE}/input/${INPUT_SEG_NAME}.mnc -float

# Segment and Join Cerebral Exterior Labels 1 & 42.
mincmath -segment -const2 0.5 1.5 ${TARGET_DIR}/${CASE}/input/${INPUT_SEG_NAME}.mnc ${TARGET_DIR}/${CASE}/temp/cerebral_left_ext.mnc -clobber
mincmath -segment -const2 41.5 42.5 ${TARGET_DIR}/${CASE}/input/${INPUT_SEG_NAME}.mnc ${TARGET_DIR}/${CASE}/temp/cerebral_right_ext.mnc -clobber
mincmath -or ${TARGET_DIR}/${CASE}/temp/cerebral_left_ext.mnc ${TARGET_DIR}/${CASE}/temp/cerebral_right_ext.mnc ${TARGET_DIR}/${CASE}/temp/cerebral_ext.mnc -clobber

# Segment and Join Cerebral Interior Labels 160 & 161.
mincmath -segment -const2 159.5 160.5 ${TARGET_DIR}/${CASE}/input/${INPUT_SEG_NAME}.mnc ${TARGET_DIR}/${CASE}/temp/cerebral_left_int.mnc -clobber
mincmath -segment -const2 160.5 161.5 ${TARGET_DIR}/${CASE}/input/${INPUT_SEG_NAME}.mnc ${TARGET_DIR}/${CASE}/temp/cerebral_right_int.mnc -clobber
mincmath -or ${TARGET_DIR}/${CASE}/temp/cerebral_left_int.mnc ${TARGET_DIR}/${CASE}/temp/cerebral_right_int.mnc ${TARGET_DIR}/${CASE}/temp/cerebral_int.mnc -clobber

# Binarize all segmentations [from 1 to 161]
mincmath -segment -const2 1 161 ${TARGET_DIR}/${CASE}/input/${INPUT_SEG_NAME}.mnc ${TARGET_DIR}/${CASE}/temp/initial_segmentations.mnc -clobber

# Join Side Segmentations
minccalc -expression 'if(A[0]==1 || A[0]==42){out=1}else if(A[0]==160||A[0]==161){out=2}' ${TARGET_DIR}/${CASE}/input/${INPUT_SEG_NAME}.mnc ${TARGET_DIR}/${CASE}/temp/initial_segmentations_sides_joined.mnc -clobber
${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/temp/initial_segmentations_sides_joined.mnc ${TARGET_DIR}/${CASE}/temp/initial_segmentations_sides_joined.nii

# Remove Cerebellum
mincmorph -filetype -successive DDDDDDD ${TARGET_DIR}/${CASE}/temp/initial_segmentations.mnc -clobber ${TARGET_DIR}/${CASE}/temp/initial_segmentations_7_dilated.mnc
minccalc -expression 'if(A[0]==1){out=A[1]}else{out=0}' ${TARGET_DIR}/${CASE}/temp/initial_segmentations_7_dilated.mnc ${TARGET_DIR}/${CASE}/input/${INPUT_NAME}.mnc ${TARGET_DIR}/${CASE}/input/${INPUT_NAME_POSPROCESS}.mnc -clobber

#############################################################
# GM External Boundary - 2 voxels apart.
# Dilation Cerebral Exterior
mincmorph -filetype -successive DD ${TARGET_DIR}/${CASE}/temp/cerebral_ext.mnc -clobber ${TARGET_DIR}/${CASE}/temp/cerebral_ext_d.mnc
# Subtract initial segmentations  from the dilated cerebral exterior.
mincmath -not ${TARGET_DIR}/${CASE}/temp/initial_segmentations.mnc ${TARGET_DIR}/${CASE}/temp/initial_segmentations_not.mnc -clobber
mincmath -and ${TARGET_DIR}/${CASE}/temp/initial_segmentations_not.mnc ${TARGET_DIR}/${CASE}/temp/cerebral_ext_d.mnc ${TARGET_DIR}/${CASE}/temp/csf_from_gm.mnc -clobber

# GM External Boundary - 3th voxel apart.
# Dilation Cerebral Exterior
mincmorph -filetype -successive DDD ${TARGET_DIR}/${CASE}/temp/cerebral_ext.mnc -clobber ${TARGET_DIR}/${CASE}/temp/cerebral_ext_d.mnc
# Dilatation Initial Segmentation.
mincmorph -filetype -successive DD ${TARGET_DIR}/${CASE}/temp/initial_segmentations.mnc -clobber ${TARGET_DIR}/${CASE}/temp/initial_segmentations_dilated.mnc
# Subtract initial segmentations dilated from the dilated cerebral exterior.
mincmath -not ${TARGET_DIR}/${CASE}/temp/initial_segmentations_dilated.mnc ${TARGET_DIR}/${CASE}/temp/initial_segmentations_dilated_not.mnc -clobber
mincmath -and ${TARGET_DIR}/${CASE}/temp/initial_segmentations_dilated_not.mnc ${TARGET_DIR}/${CASE}/temp/cerebral_ext_d.mnc ${TARGET_DIR}/${CASE}/temp/csf_from_gm_ext.mnc -clobber

${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/temp/csf_from_gm_ext.mnc ${TARGET_DIR}/${CASE}/temp/csf_from_gm_ext.nii
${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/temp/csf_from_gm.mnc ${TARGET_DIR}/${CASE}/temp/csf_from_gm.nii

#############################################################
# CSF segmentation - Intensity clustering using GMM.

# Extract Skull
#### Prepare files
${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/temp/cerebral_int.mnc ${TARGET_DIR}/${CASE}/temp/skull_wm.nii
${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/input/${INPUT_NAME_POSPROCESS}.mnc ${TARGET_DIR}/${CASE}/temp/mri.nii

#### Call Script
python3 ${RESOURCES_DIR}/code/python/skull.py \
    -inPath ${TARGET_DIR}/${CASE}/temp \
    -inMRI mri.nii \
    -inWM skull_wm.nii \
    -outPath ${TARGET_DIR}/${CASE}/temp \
    -outSkull skull.nii \
    -iterations 15 \
    -verbose 1

${RESOURCES_DIR}/bin/nii2mnc ${TARGET_DIR}/${CASE}/temp/skull.nii ${TARGET_DIR}/${CASE}/temp/skull_a.mnc

# GMM - Gaussian Mixture Model, Soft Clustering CSF/GM
#### Prepare files
${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/temp/cerebral_int.mnc ${TARGET_DIR}/${CASE}/temp/gmm_wm.nii
${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/temp/cerebral_ext.mnc ${TARGET_DIR}/${CASE}/temp/gmm_gm.nii
${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/input/${INPUT_NAME_POSPROCESS}.mnc ${TARGET_DIR}/${CASE}/temp/mri.nii

#### Call Script
python3 ${RESOURCES_DIR}/code/python/gmm_clustering.py \
    -inPath ${TARGET_DIR}/${CASE}/temp \
    -inMRI mri.nii \
    -inWM gmm_wm.nii \
    -inGM gmm_gm.nii \
    -outPath ${TARGET_DIR}/${CASE}/temp \
    -outCSF gmm_csf.nii \
    -verbose 1 \
    -plot 1 \
    -threshold 0.67

${RESOURCES_DIR}/bin/nii2mnc ${TARGET_DIR}/${CASE}/temp/gmm_csf.nii ${TARGET_DIR}/${CASE}/temp/gmm_csf.mnc

#############################################################
# Graymatter including Skull, GM = Brain - WM - CSF_gmm.
mincmath -or ${TARGET_DIR}/${CASE}/temp/csf_from_gm_ext.mnc ${TARGET_DIR}/${CASE}/temp/cerebral_ext.mnc  -clobber ${TARGET_DIR}/${CASE}/temp/gray.mnc
#minccalc -expr 'if(A[0]>0 && A[1]==0 && A[2]==0){ out=1 }else{ out=0 }' ${TARGET_DIR}/${CASE}/input/${INPUT_NAME_POSPROCESS}.mnc ${TARGET_DIR}/${CASE}/temp/cerebral_int.mnc ${TARGET_DIR}/${CASE}/temp/gmm_csf_a.mnc -clobber ${TARGET_DIR}/${CASE}/temp/gray.mnc

# Join GM and WM
minccalc -expression 'if(A[0]>0){out=3}else if(A[1]>0){out=2} else {out=0}' ${TARGET_DIR}/${CASE}/temp/cerebral_int.mnc ${TARGET_DIR}/${CASE}/temp/gray.mnc -clobber ${TARGET_DIR}/${CASE}/temp/wm_and_gm.mnc
${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/temp/wm_and_gm.mnc ${TARGET_DIR}/${CASE}/temp/wm_and_gm.nii -short

#####################(GM + CSF -> Skeleton)########################################
#### Prepare file, Gray Scale and nii zipped.
minccalc -expression 'if(A[2] == 1){out=0}else if(A[0]==1 || A[1]==1){out=255}else{out=11}' ${TARGET_DIR}/${CASE}/temp/csf_from_gm.mnc ${TARGET_DIR}/${CASE}/temp/gray.mnc ${TARGET_DIR}/${CASE}/temp/cerebral_int.mnc -clobber ${TARGET_DIR}/${CASE}/temp/csf_and_gm_with_wm_grayscale.mnc
${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/temp/csf_and_gm_with_wm_grayscale.mnc ${TARGET_DIR}/${CASE}/temp/csf_and_gm_with_wm1.nii -short
gzip -k ${TARGET_DIR}/${CASE}/temp/csf_and_gm_with_wm1.nii --verbose

#### Skeleton
${RESOURCES_DIR}/bin/brainvisa-4.5.0/bin/VipSkeleton -i ${TARGET_DIR}/${CASE}/temp/csf_and_gm_with_wm1.nii.gz -so ${TARGET_DIR}/${CASE}/temp/skeleton_1.nii -vo ${TARGET_DIR}/${CASE}/temp/roots.nii -g ${TARGET_DIR}/${CASE}/temp/wm_and_gm.nii -p c -wp 0 -lz 0 -lu 10 -e 0.5 -mct 0 -gct -10
#### Call Align Script
python3 ${RESOURCES_DIR}/code/python/align_nii.py \
    -inPath ${TARGET_DIR}/${CASE}/temp \
    -inNii skeleton_1.nii \
    -inTemplate csf_and_gm_with_wm1.nii \
    -outPath ${TARGET_DIR}/${CASE}/temp \
    -outNii skeleton.nii \
    -verbose 1 \

# Binarize Skeleton
${RESOURCES_DIR}/bin/nii2mnc -clobber ${TARGET_DIR}/${CASE}/temp/skeleton.nii ${TARGET_DIR}/${CASE}/temp/skeleton_.mnc -float
minccalc -clobber -expression 'if(A[0]>11.5){out=1}else{out=0}' ${TARGET_DIR}/${CASE}/temp/skeleton_.mnc ${TARGET_DIR}/${CASE}/temp/skeleton_1_corr.mnc

${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/temp/skeleton_1_corr.mnc ${TARGET_DIR}/${CASE}/temp/skeleton_corr.nii
#########################################################################

# Pial Surface Extraction, WM expansion. (Using GMM Intensity CSF joined with skeleton)
#### Prepare files

mincmath -or ${TARGET_DIR}/${CASE}/temp/gmm_csf.mnc ${TARGET_DIR}/${CASE}/temp/skeleton_1_corr.mnc -clobber ${TARGET_DIR}/${CASE}/temp/ps2_csf.mnc
${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/temp/ps2_csf.mnc ${TARGET_DIR}/${CASE}/temp/ps2_csf.nii
${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/temp/cerebral_int.mnc ${TARGET_DIR}/${CASE}/temp/ps2_wm.nii
${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/input/${INPUT_NAME_POSPROCESS}.mnc ${TARGET_DIR}/${CASE}/temp/mri.nii
#### Call Script
python3 ${RESOURCES_DIR}/code/python/pial_surface.py \
    -inPath ${TARGET_DIR}/${CASE}/temp \
    -inMRI mri.nii \
    -inCSF ps2_csf.nii \
    -inWM ps2_wm.nii \
    -outPath ${TARGET_DIR}/${CASE}/output \
    -outPS ps2.nii \
    -iterations 10 \
    -verbose 1 \
    -plot 1

#### Python venv - deactivate
deactivate

# freeview ${TARGET_DIR}/${CASE}/temp/csf_and_gm_with_wm1.nii.gz 
# freeview ${TARGET_DIR}/${CASE}/temp/csf_and_gm_with_wm1.nii.gz ${TARGET_DIR}/${CASE}/temp/skeleton_corr.nii ${TARGET_DIR}/${CASE}/temp/roots.nii ${TARGET_DIR}/${CASE}/temp/wm_and_gm.nii ${TARGET_DIR}/${CASE}/temp/mri.nii