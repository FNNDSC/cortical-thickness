#!/bin/bash

if [ $# -lt 1 ]; then
  echo 1>&2 "$0: not enough arguments, missing case id."
  return
fi

BASE_PATH=/neuro/labs/grantlab/research/MRI_processing
CASE=${1} #FCB028
BASE_DIR=${BASE_PATH}/jose.cisneros/CorticalThickness/Samples # ${2}
TARGET_DIR=${BASE_PATH}/jose.cisneros/CorticalThickness/Results # ${3}
RESOURCES_DIR=${BASE_PATH}/jose.cisneros/CorticalThickness # ${3}

rm -rf ${TARGET_DIR}/${CASE}

mkdir -p ${TARGET_DIR}
mkdir -p ${TARGET_DIR}/${CASE}
mkdir -p ${TARGET_DIR}/${CASE}/input
mkdir -p ${TARGET_DIR}/${CASE}/temp
mkdir -p ${TARGET_DIR}/${CASE}/output


INPUT_NAME=recon_to31
INPUT_NAME_POSPROCESS=recon_to31_posprocess
INPUT_SEG_NAME=segmentation_to31_final

# Flag to do Surface Extraction.
ENABLE_SURFACE_EXTRACTION=true
# Flag to use Intensity Method for Skeleton Refinement.
USE_INTENSITY=true
# Clustering Method.
CLUSTERING_METHODS=("GMM" "FCM" "sFCM")
CLUSTERING_METHOD=${CLUSTERING_METHODS[2]}

# Setup Dependencies
. neuro-fs stable 6.0;
FSLDIR=/neuro/users/jose.cisneros/arch/Linux64/packages/fsl/6.0;
. ${FSLDIR}/etc/fslconf/fsl.sh;
PATH=${FSLDIR}/bin:${PATH};
export FSLDIR PATH;
PATH="${RESOURCES_DIR}/bin:"$PATH
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
EXT_LEFT=1
EXT_RIGHT=42
INT_RIGHT=160
INT_LEFT=161

# Conversion input from .nii to .mnc
${RESOURCES_DIR}/bin/nii2mnc -clobber ${BASE_DIR}/${CASE}/${INPUT_NAME}.nii ${TARGET_DIR}/${CASE}/input/${INPUT_NAME}.mnc -float
${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/input/${INPUT_NAME}.mnc ${TARGET_DIR}/${CASE}/input/${INPUT_NAME}.nii -float
${RESOURCES_DIR}/bin/nii2mnc -clobber ${TARGET_DIR}/${CASE}/input/${INPUT_NAME}.nii ${TARGET_DIR}/${CASE}/input/${INPUT_NAME}.mnc -float

${RESOURCES_DIR}/bin/nii2mnc -clobber ${BASE_DIR}/${CASE}/${INPUT_SEG_NAME}.nii ${TARGET_DIR}/${CASE}/input/${INPUT_SEG_NAME}.mnc -float
${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/input/${INPUT_SEG_NAME}.mnc ${TARGET_DIR}/${CASE}/input/${INPUT_SEG_NAME}.nii -float
${RESOURCES_DIR}/bin/nii2mnc -clobber ${TARGET_DIR}/${CASE}/input/${INPUT_SEG_NAME}.nii ${TARGET_DIR}/${CASE}/input/${INPUT_SEG_NAME}.mnc -float

# Segment and Join Cerebral Exterior Labels 1 & 42.
mincmath -clobber -eq -const $EXT_LEFT ${TARGET_DIR}/${CASE}/input/${INPUT_SEG_NAME}.mnc ${TARGET_DIR}/${CASE}/temp/cerebral_left_ext.mnc
mincmath -clobber -eq -const $EXT_RIGHT ${TARGET_DIR}/${CASE}/input/${INPUT_SEG_NAME}.mnc ${TARGET_DIR}/${CASE}/temp/cerebral_right_ext.mnc
mincmath -or ${TARGET_DIR}/${CASE}/temp/cerebral_left_ext.mnc ${TARGET_DIR}/${CASE}/temp/cerebral_right_ext.mnc ${TARGET_DIR}/${CASE}/temp/cerebral_ext.mnc -clobber

# Dilation Cerebral Exterior
mincmorph -filetype -successive D ${TARGET_DIR}/${CASE}/temp/cerebral_ext.mnc -clobber ${TARGET_DIR}/${CASE}/temp/cerebral_ext_d.mnc

# Segment and Join Cerebral Interior Labels 160 & 161.
mincmath -clobber -eq -const $INT_LEFT ${TARGET_DIR}/${CASE}/input/${INPUT_SEG_NAME}.mnc ${TARGET_DIR}/${CASE}/temp/cerebral_left_int.mnc
mincmath -clobber -eq -const $INT_RIGHT ${TARGET_DIR}/${CASE}/input/${INPUT_SEG_NAME}.mnc ${TARGET_DIR}/${CASE}/temp/cerebral_right_int.mnc
mincmath -or ${TARGET_DIR}/${CASE}/temp/cerebral_left_int.mnc ${TARGET_DIR}/${CASE}/temp/cerebral_right_int.mnc ${TARGET_DIR}/${CASE}/temp/cerebral_int.mnc -clobber

# Dilation Cerebral Interior
mincmorph -filetype -successive D ${TARGET_DIR}/${CASE}/temp/cerebral_int.mnc -clobber ${TARGET_DIR}/${CASE}/temp/cerebral_int_d.mnc
mincmath -not ${TARGET_DIR}/${CASE}/temp/cerebral_int_d.mnc ${TARGET_DIR}/${CASE}/temp/cerebral_int_d_not.mnc -clobber

# Binarize all segmentations [from 1 to 161]
mincmath -segment -const2 1 161 ${TARGET_DIR}/${CASE}/input/${INPUT_SEG_NAME}.mnc ${TARGET_DIR}/${CASE}/temp/initial_segmentations.mnc -clobber

# Dilation Initial Segmentations
mincmorph -filetype -successive D ${TARGET_DIR}/${CASE}/temp/initial_segmentations.mnc -clobber ${TARGET_DIR}/${CASE}/temp/initial_segmentations_d.mnc

# Remove Cerebellum
mincmorph -filetype -successive DDDDDDD ${TARGET_DIR}/${CASE}/temp/initial_segmentations.mnc -clobber ${TARGET_DIR}/${CASE}/temp/initial_segmentations_7_dilated.mnc
minccalc -expression 'if(A[0]==1){out=A[1]}else{out=0}' ${TARGET_DIR}/${CASE}/temp/initial_segmentations_7_dilated.mnc ${TARGET_DIR}/${CASE}/input/${INPUT_NAME}.mnc ${TARGET_DIR}/${CASE}/input/${INPUT_NAME_POSPROCESS}.mnc -clobber

#############################################################
###################### START SKELETON #######################
#############################################################

# GM External Boundary - 1th voxel apart.
#   Subtract initial segmentations dilated from the dilated cerebral exterior.
mincmath -not ${TARGET_DIR}/${CASE}/temp/initial_segmentations.mnc ${TARGET_DIR}/${CASE}/temp/initial_segmentations_not.mnc -clobber
mincmath -and ${TARGET_DIR}/${CASE}/temp/initial_segmentations_not.mnc ${TARGET_DIR}/${CASE}/temp/initial_segmentations_d.mnc ${TARGET_DIR}/${CASE}/temp/gm_ext.mnc -clobber
${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/temp/gm_ext.mnc ${TARGET_DIR}/${CASE}/temp/gm_ext.nii

#############################################################
# Join GM and WM
minccalc -expression 'if(A[0]>0){out=3}else if(A[1]>0){out=2} else {out=0}' ${TARGET_DIR}/${CASE}/temp/cerebral_int.mnc ${TARGET_DIR}/${CASE}/temp/cerebral_ext.mnc -clobber ${TARGET_DIR}/${CASE}/temp/wm_and_gm.mnc
${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/temp/wm_and_gm.mnc ${TARGET_DIR}/${CASE}/temp/wm_and_gm.nii -short

#####################(GM -> Skeleton)########################################
#### GM in Gray Scale. Prepare file.
minccalc -expression 'if(A[1] == 1){out=0}else if(A[0]==1){out=255}else{out=11}' ${TARGET_DIR}/${CASE}/temp/cerebral_ext.mnc ${TARGET_DIR}/${CASE}/temp/cerebral_int.mnc -clobber ${TARGET_DIR}/${CASE}/temp/gm_grayscale.mnc
${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/temp/gm_grayscale.mnc ${TARGET_DIR}/${CASE}/temp/gm_grayscale.nii -short
gzip -k ${TARGET_DIR}/${CASE}/temp/gm_grayscale.nii --verbose

#### Skeleton
${RESOURCES_DIR}/bin/brainvisa-4.5.0/bin/VipSkeleton \
    -i ${TARGET_DIR}/${CASE}/temp/gm_grayscale.nii.gz \
    -so ${TARGET_DIR}/${CASE}/temp/skeleton_1.nii \
    -vo ${TARGET_DIR}/${CASE}/temp/roots_1.nii \
    -g ${TARGET_DIR}/${CASE}/temp/wm_and_gm.nii \
    -p c -wp 0 -lz 0 -lu 10 -e 0.5 -mct 0 -gct -10

#### Align Skeleton To Original MRI
python3 ${RESOURCES_DIR}/code/skeleton/align_nii.py \
    -inPath ${TARGET_DIR}/${CASE}/temp \
    -inNii skeleton_1.nii \
    -inTemplate gm_grayscale.nii \
    -outPath ${TARGET_DIR}/${CASE}/temp \
    -outNii skeleton.nii \
    -verbose 1
#### Align Roots To Original MRI
python3 ${RESOURCES_DIR}/code/skeleton/align_nii.py \
    -inPath ${TARGET_DIR}/${CASE}/temp \
    -inNii roots_1.nii \
    -inTemplate gm_grayscale.nii \
    -outPath ${TARGET_DIR}/${CASE}/temp \
    -outNii roots.nii \
    -verbose 1

# Binarize Skeleton
${RESOURCES_DIR}/bin/nii2mnc -clobber ${TARGET_DIR}/${CASE}/temp/skeleton.nii ${TARGET_DIR}/${CASE}/temp/skeleton_.mnc -float
minccalc -clobber -expression 'if(A[0]>11.5){out=1}else{out=0}' ${TARGET_DIR}/${CASE}/temp/skeleton_.mnc ${TARGET_DIR}/${CASE}/temp/skeleton_1_corr.mnc

# Join Skeleton with GM external boundary.
mincmath -or ${TARGET_DIR}/${CASE}/temp/gm_ext.mnc ${TARGET_DIR}/${CASE}/temp/skeleton_1_corr.mnc  -clobber ${TARGET_DIR}/${CASE}/temp/skeleton_2_corr.mnc
${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/temp/skeleton_2_corr.mnc ${TARGET_DIR}/${CASE}/temp/skeleton_corr.nii

# Clustering Input Volume: GM -> 1 extra outer voxel and without 1 inner voxel.
mincmath -and ${TARGET_DIR}/${CASE}/temp/cerebral_int_d_not.mnc ${TARGET_DIR}/${CASE}/temp/cerebral_ext_d.mnc ${TARGET_DIR}/${CASE}/temp/clustering_input.mnc -clobber

#############################################################
# CSF segmentation - Intensity clustering using GMM.

if [ $CLUSTERING_METHOD = "GMM" ] && [ $USE_INTENSITY = true ]; then
    # GMM - Gaussian Mixture Model, Soft Clustering CSF/GM
    #### Prepare files
    ${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/temp/clustering_input.mnc ${TARGET_DIR}/${CASE}/temp/clustering_input.nii
    ${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/input/${INPUT_NAME_POSPROCESS}.mnc ${TARGET_DIR}/${CASE}/temp/mri.nii

    #### Call Script
    python3 ${RESOURCES_DIR}/code/skeleton/gmm_clustering.py \
        -inPath ${TARGET_DIR}/${CASE}/temp \
        -inMRI mri.nii \
        -inVOL clustering_input.nii \
        -outPath ${TARGET_DIR}/${CASE}/temp \
        -outCSF gmm_csf.nii \
        -verbose 1 \
        -plot 1 \
        -threshold 0.67

    ${RESOURCES_DIR}/bin/nii2mnc ${TARGET_DIR}/${CASE}/temp/gmm_csf.nii ${TARGET_DIR}/${CASE}/temp/gmm_csf.mnc
    cp ${TARGET_DIR}/${CASE}/temp/gmm_csf.mnc ${TARGET_DIR}/${CASE}/temp/clustering_output.mnc
fi

#########################################################################
# CSF segmentation - Intensity clustering using FCM.

if [ $CLUSTERING_METHOD = "FCM" ] && [ $USE_INTENSITY = true ]; then
    # FCM - Fuzzy C Means, Soft Clustering CSF/GM
    #### Prepare files
    ${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/temp/clustering_input.mnc ${TARGET_DIR}/${CASE}/temp/clustering_input.nii
    ${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/input/${INPUT_NAME_POSPROCESS}.mnc ${TARGET_DIR}/${CASE}/temp/mri.nii

    #### Call Script
    python3 ${RESOURCES_DIR}/code/skeleton/MRI_FCM.py \
        -inPath ${TARGET_DIR}/${CASE}/temp \
        -inMRI mri.nii \
        -inVOL clustering_input.nii \
        -outPath ${TARGET_DIR}/${CASE}/temp \
        -outCSF fcm_csf.nii \
        -verbose 1 \
        -plot 1 \
        -threshold 0.67

    ${RESOURCES_DIR}/bin/nii2mnc ${TARGET_DIR}/${CASE}/temp/fcm_csf.nii ${TARGET_DIR}/${CASE}/temp/fcm_csf.mnc
    cp ${TARGET_DIR}/${CASE}/temp/fcm_csf.mnc ${TARGET_DIR}/${CASE}/temp/clustering_output.mnc
fi

#########################################################################
# CSF segmentation - Intensity clustering using sFCM.

if [ $CLUSTERING_METHOD = "sFCM" ] && [ $USE_INTENSITY = true ]; then
    # sFCM - Spatial Fuzzy C Means, Soft Clustering CSF/GM
    #### Prepare files
    ${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/temp/clustering_input.mnc ${TARGET_DIR}/${CASE}/temp/clustering_input.nii
    ${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/input/${INPUT_NAME_POSPROCESS}.mnc ${TARGET_DIR}/${CASE}/temp/mri.nii

    #### Call Script
    python3 ${RESOURCES_DIR}/code/skeleton/MRI_sFCM.py \
        -inPath ${TARGET_DIR}/${CASE}/temp \
        -inMRI mri.nii \
        -inVOL clustering_input.nii \
        -outPath ${TARGET_DIR}/${CASE}/temp \
        -outCSF sfcm_csf.nii \
        -verbose 1 \
        -plot 1 \
        -threshold 0.67

    ${RESOURCES_DIR}/bin/nii2mnc ${TARGET_DIR}/${CASE}/temp/sfcm_csf.nii ${TARGET_DIR}/${CASE}/temp/sfcm_csf.mnc
    cp ${TARGET_DIR}/${CASE}/temp/sfcm_csf.mnc ${TARGET_DIR}/${CASE}/temp/clustering_output.mnc
fi

#########################################################################

# Pial Surface Extraction, WM expansion. (Using GMM Intensity CSF defined by Intensity joined with skeleton)

if [ $USE_INTENSITY = true ]; then
    #### Join Clustering Output with Skeleton limiting inner boundary to skeleton.
    mincmath -or ${TARGET_DIR}/${CASE}/temp/clustering_output.mnc ${TARGET_DIR}/${CASE}/temp/skeleton_2_corr.mnc -clobber ${TARGET_DIR}/${CASE}/temp/ps2_csf.mnc
    #### Prepare files
    ${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/temp/ps2_csf.mnc ${TARGET_DIR}/${CASE}/temp/ps2_csf.nii
    ${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/temp/cerebral_int.mnc ${TARGET_DIR}/${CASE}/temp/ps2_wm.nii
    ${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/temp/cerebral_ext.mnc ${TARGET_DIR}/${CASE}/temp/ps2_gm.nii
    ${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/input/${INPUT_NAME_POSPROCESS}.mnc ${TARGET_DIR}/${CASE}/temp/mri.nii
    #### Call Script
    python3 ${RESOURCES_DIR}/code/skeleton/pial_surface.py \
        -inPath ${TARGET_DIR}/${CASE}/temp \
        -inMRI mri.nii \
        -inCSF ps2_csf.nii \
        -inWM ps2_wm.nii \
        -inGM ps2_gm.nii \
        -inSK skeleton_corr.nii \
        -outPath ${TARGET_DIR}/${CASE}/output \
        -outPS ps2.nii \
        -iterations 10 \
        -verbose 1 \
        -plot 1
    ${RESOURCES_DIR}/bin/nii2mnc ${TARGET_DIR}/${CASE}/output/ps2.nii ${TARGET_DIR}/${CASE}/output/skeleton_output.mnc -clobber
else
    cp ${TARGET_DIR}/${CASE}/temp/skeleton_2_corr.mnc ${TARGET_DIR}/${CASE}/output/skeleton_output.mnc
fi

#############################################################
###################### END SKELETON #########################
#############################################################

#############################################################
############### START SURFACE EXTRACTION ####################
#############################################################

if [ $ENABLE_SURFACE_EXTRACTION = true ]; then
    source ${RESOURCES_DIR}/code/WHITE-EXTRACTION.bash ${CASE}
    source ${RESOURCES_DIR}/code/SURFACE-EXTRACTION.bash ${CASE}
fi
#############################################################
################ END SURFACE EXTRACTION #####################
#############################################################

#### Python venv - deactivate
deactivate

# Convert all mnc files to nii.
source ${RESOURCES_DIR}/code/convertmnc.bash ${TARGET_DIR}/${CASE}/temp
