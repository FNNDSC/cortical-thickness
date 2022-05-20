#!/bin/bash

if [ $# -lt 1 ]; then
  echo 1>&2 "$0: not enough arguments, missing case id."
  return
fi

RESULTS_PREFIX=${9:-}
CASE=${1}
BASE_PATH=${2:-"/neuro/labs/grantlab/research/MRI_processing/jose.cisneros/CorticalThickness"}
BASE_DIR=${BASE_PATH}/Samples
RESOURCES_DIR=${BASE_PATH}
INPUT_DIR=${3:-"${BASE_DIR}/${CASE}"}
OUTPUT_DIR=${4:-"${BASE_PATH}/"}
TARGET_DIR=${OUTPUT_DIR}/${RESULTS_PREFIX}Results

rm -rf ${TARGET_DIR}/${CASE}

mkdir -p ${TARGET_DIR}
mkdir -p ${TARGET_DIR}/${CASE}
mkdir -p ${TARGET_DIR}/${CASE}/input
mkdir -p ${TARGET_DIR}/${CASE}/temp
mkdir -p ${TARGET_DIR}/${CASE}/morphometrics
mkdir -p ${TARGET_DIR}/${CASE}/output

INPUT_MRI_FILE=$(find $INPUT_DIR -name "recon_to31_nuc.nii")
INPUT_MRI_SEG_FILE=$(find $INPUT_DIR -name "segmentation_to31_final.nii")

if [ -z "$INPUT_MRI_FILE" ]; then
  echo "recon_to31_nuc.nii file not found inside $INPUT_DIR"
  return
fi
if [ -z "$INPUT_MRI_SEG_FILE" ]; then
  echo "segmentation_to31_final.nii file not found inside $INPUT_DIR"
  return
fi

# Flag to enable Surface Extraction.
ENABLE_SURFACE_EXTRACTION=${5:-true}
# Flag to enable Intensity Method for Skeleton Refinement.
ENABLE_INTENSITY_REFINEMENT=${6:-true}
# Clustering Method.
CLUSTERING_METHODS=("GMM" "FCM" "sFCM")
CLUSTERING_METHOD=${7:-${CLUSTERING_METHODS[2]}}
# Running Script without Docker.
OUTSIDE_DOCKER=${8:-true}

# Setup Dependencies
if [ $OUTSIDE_DOCKER = true ]; then
    . neuro-fs stable 6.0;
    FSLDIR=/neuro/users/jose.cisneros/arch/Linux64/packages/fsl/6.0;
    . ${FSLDIR}/etc/fslconf/fsl.sh;
    PATH=${FSLDIR}/bin:${PATH};
    export FSLDIR PATH;
fi
PATH="${RESOURCES_DIR}/bin:"$PATH
LD_LIBRARY_PATH="${RESOURCES_DIR}/lib:"$LD_LIBRARY_PATH
LD_LIBRARY_PATH="${RESOURCES_DIR}/bin/brainvisa-4.5.0/lib:"$LD_LIBRARY_PATH
export PATH
export LD_LIBRARY_PATH

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

# Prepare input files.
cp $INPUT_MRI_FILE ${TARGET_DIR}/${CASE}/input/input_mri.nii
cp $INPUT_MRI_SEG_FILE ${TARGET_DIR}/${CASE}/input/input_mri_seg.nii
${RESOURCES_DIR}/bin/nii2mnc -clobber ${TARGET_DIR}/${CASE}/input/input_mri.nii ${TARGET_DIR}/${CASE}/input/input_mri.mnc -float
${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/input/input_mri.mnc ${TARGET_DIR}/${CASE}/input/input_mri.nii -float
${RESOURCES_DIR}/bin/nii2mnc -clobber ${TARGET_DIR}/${CASE}/input/input_mri.nii ${TARGET_DIR}/${CASE}/input/input_mri.mnc -float

${RESOURCES_DIR}/bin/nii2mnc -clobber ${TARGET_DIR}/${CASE}/input/input_mri_seg.nii ${TARGET_DIR}/${CASE}/input/input_mri_seg.mnc -float
${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/input/input_mri_seg.mnc ${TARGET_DIR}/${CASE}/input/input_mri_seg.nii -float
${RESOURCES_DIR}/bin/nii2mnc -clobber ${TARGET_DIR}/${CASE}/input/input_mri_seg.nii ${TARGET_DIR}/${CASE}/input/input_mri_seg.mnc -float

# Segment and Join Cerebral Exterior Labels 1 & 42.
mincmath -clobber -eq -const $EXT_LEFT ${TARGET_DIR}/${CASE}/input/input_mri_seg.mnc ${TARGET_DIR}/${CASE}/temp/cerebral_left_ext.mnc
mincmath -clobber -eq -const $EXT_RIGHT ${TARGET_DIR}/${CASE}/input/input_mri_seg.mnc ${TARGET_DIR}/${CASE}/temp/cerebral_right_ext.mnc
mincmath -or ${TARGET_DIR}/${CASE}/temp/cerebral_left_ext.mnc ${TARGET_DIR}/${CASE}/temp/cerebral_right_ext.mnc ${TARGET_DIR}/${CASE}/temp/cerebral_ext.mnc -clobber

# Dilation Cerebral Exterior
mincmorph -filetype -successive D ${TARGET_DIR}/${CASE}/temp/cerebral_ext.mnc -clobber ${TARGET_DIR}/${CASE}/temp/cerebral_ext_d.mnc

# Segment and Join Cerebral Interior Labels 160 & 161.
mincmath -clobber -eq -const $INT_LEFT ${TARGET_DIR}/${CASE}/input/input_mri_seg.mnc ${TARGET_DIR}/${CASE}/temp/cerebral_left_int.mnc
mincmath -clobber -eq -const $INT_RIGHT ${TARGET_DIR}/${CASE}/input/input_mri_seg.mnc ${TARGET_DIR}/${CASE}/temp/cerebral_right_int.mnc
mincmath -or ${TARGET_DIR}/${CASE}/temp/cerebral_left_int.mnc ${TARGET_DIR}/${CASE}/temp/cerebral_right_int.mnc ${TARGET_DIR}/${CASE}/temp/cerebral_int.mnc -clobber

# Dilation Cerebral Interior
mincmorph -filetype -successive D ${TARGET_DIR}/${CASE}/temp/cerebral_int.mnc -clobber ${TARGET_DIR}/${CASE}/temp/cerebral_int_d.mnc
mincmath -not ${TARGET_DIR}/${CASE}/temp/cerebral_int_d.mnc ${TARGET_DIR}/${CASE}/temp/cerebral_int_d_not.mnc -clobber

# Binarize all segmentations [from 1 to 161]
mincmath -segment -const2 1 161 ${TARGET_DIR}/${CASE}/input/input_mri_seg.mnc ${TARGET_DIR}/${CASE}/temp/initial_segmentations.mnc -clobber

# Dilation Initial Segmentations
mincmorph -filetype -successive D ${TARGET_DIR}/${CASE}/temp/initial_segmentations.mnc -clobber ${TARGET_DIR}/${CASE}/temp/initial_segmentations_d.mnc

# Remove Cerebellum
mincmorph -filetype -successive DDDDDDD ${TARGET_DIR}/${CASE}/temp/initial_segmentations.mnc -clobber ${TARGET_DIR}/${CASE}/temp/initial_segmentations_7_dilated.mnc
minccalc -expression 'if(A[0]==1){out=A[1]}else{out=0}' ${TARGET_DIR}/${CASE}/temp/initial_segmentations_7_dilated.mnc ${TARGET_DIR}/${CASE}/input/input_mri.mnc ${TARGET_DIR}/${CASE}/input/input_mri_processed.mnc -clobber

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

if [ $CLUSTERING_METHOD = "GMM" ] && [ $ENABLE_INTENSITY_REFINEMENT = true ]; then
    # GMM - Gaussian Mixture Model, Soft Clustering CSF/GM
    #### Prepare files
    ${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/temp/clustering_input.mnc ${TARGET_DIR}/${CASE}/temp/clustering_input.nii
    ${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/input/input_mri_processed.mnc ${TARGET_DIR}/${CASE}/temp/mri.nii

    #### Call Script
    python3 ${RESOURCES_DIR}/code/skeleton/GMM.py \
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

if [ $CLUSTERING_METHOD = "FCM" ] && [ $ENABLE_INTENSITY_REFINEMENT = true ]; then
    # FCM - Fuzzy C Means, Soft Clustering CSF/GM
    #### Prepare files
    ${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/temp/clustering_input.mnc ${TARGET_DIR}/${CASE}/temp/clustering_input.nii
    ${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/input/input_mri_processed.mnc ${TARGET_DIR}/${CASE}/temp/mri.nii

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

if [ $CLUSTERING_METHOD = "sFCM" ] && [ $ENABLE_INTENSITY_REFINEMENT = true ]; then
    # sFCM - Spatial Fuzzy C Means, Soft Clustering CSF/GM
    #### Prepare files
    ${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/temp/clustering_input.mnc ${TARGET_DIR}/${CASE}/temp/clustering_input.nii
    ${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/input/input_mri_processed.mnc ${TARGET_DIR}/${CASE}/temp/mri.nii

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

if [ $ENABLE_INTENSITY_REFINEMENT = true ]; then
    #### Join Clustering Output with Skeleton limiting inner boundary to skeleton.
    mincmath -or ${TARGET_DIR}/${CASE}/temp/clustering_output.mnc ${TARGET_DIR}/${CASE}/temp/skeleton_2_corr.mnc -clobber ${TARGET_DIR}/${CASE}/temp/ps2_csf.mnc
    #### Prepare files
    ${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/temp/ps2_csf.mnc ${TARGET_DIR}/${CASE}/temp/ps2_csf.nii
    ${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/temp/cerebral_int.mnc ${TARGET_DIR}/${CASE}/temp/ps2_wm.nii
    ${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/temp/cerebral_ext.mnc ${TARGET_DIR}/${CASE}/temp/ps2_gm.nii
    ${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/input/input_mri_processed.mnc ${TARGET_DIR}/${CASE}/temp/mri.nii
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
    source ${RESOURCES_DIR}/code/WHITE-EXTRACTION.bash ${CASE} ${BASE_PATH} ${TARGET_DIR}
    source ${RESOURCES_DIR}/code/SURFACE-EXTRACTION.bash ${CASE} ${BASE_PATH} ${TARGET_DIR}
fi
#############################################################
################ END SURFACE EXTRACTION #####################
#############################################################


#############################################################
######### START CORTICAL MORPHOMETRICS COMPUTATION ##########
#############################################################

${RESOURCES_DIR}/bin/cortical_thickness -tlink -fwhm 10 -transform ${RESOURCES_DIR}/share/surftmat.xfm ${TARGET_DIR}/${CASE}/surfaces/lh.smoothwm.to31.obj ${TARGET_DIR}/${CASE}/surfaces/lh.pial.native.obj ${TARGET_DIR}/${CASE}/morphometrics/native_rms_tlink_10mm_left.txt
${RESOURCES_DIR}/bin/cortical_thickness -tlink -fwhm 10 -transform ${RESOURCES_DIR}/share/surftmat.xfm ${TARGET_DIR}/${CASE}/surfaces/rh.smoothwm.to31.obj ${TARGET_DIR}/${CASE}/surfaces/rh.pial.native.obj ${TARGET_DIR}/${CASE}/morphometrics/native_rms_tlink_10mm_right.txt

${RESOURCES_DIR}/bin/cortical_thickness -tlaplace -fwhm 10 -transform ${RESOURCES_DIR}/share/surftmat.xfm ${TARGET_DIR}/${CASE}/surfaces/lh.smoothwm.to31.obj ${TARGET_DIR}/${CASE}/surfaces/lh.pial.native.obj ${TARGET_DIR}/${CASE}/morphometrics/native_rms_tlaplace_10mm_left.txt
${RESOURCES_DIR}/bin/cortical_thickness -tlaplace -fwhm 10 -transform ${RESOURCES_DIR}/share/surftmat.xfm ${TARGET_DIR}/${CASE}/surfaces/rh.smoothwm.to31.obj ${TARGET_DIR}/${CASE}/surfaces/rh.pial.native.obj ${TARGET_DIR}/${CASE}/morphometrics/native_rms_tlaplace_10mm_right.txt

${RESOURCES_DIR}/bin/cortical_thickness -tnear -fwhm 10 -transform ${RESOURCES_DIR}/share/surftmat.xfm ${TARGET_DIR}/${CASE}/surfaces/lh.smoothwm.to31.obj ${TARGET_DIR}/${CASE}/surfaces/lh.pial.native.obj ${TARGET_DIR}/${CASE}/morphometrics/native_rms_tnear_10mm_left.txt
${RESOURCES_DIR}/bin/cortical_thickness -tnear -fwhm 10 -transform ${RESOURCES_DIR}/share/surftmat.xfm ${TARGET_DIR}/${CASE}/surfaces/rh.smoothwm.to31.obj ${TARGET_DIR}/${CASE}/surfaces/rh.pial.native.obj ${TARGET_DIR}/${CASE}/morphometrics/native_rms_tnear_10mm_right.txt

${RESOURCES_DIR}/bin/depth_potential -alpha 0.05 -depth_potential ${TARGET_DIR}/${CASE}/surfaces/lh.smoothwm.to31.obj ${TARGET_DIR}/${CASE}/morphometrics/wm_sulcaldepth_left.txt
${RESOURCES_DIR}/bin/depth_potential -alpha 0.05 -depth_potential ${TARGET_DIR}/${CASE}/surfaces/rh.smoothwm.to31.obj ${TARGET_DIR}/${CASE}/morphometrics/wm_sulcaldepth_right.txt

#############################################################
########## END CORTICAL MORPHOMETRICS COMPUTATION ###########
#############################################################

#### Python venv - deactivate
deactivate

# Convert all mnc files to nii.
source ${RESOURCES_DIR}/code/utils/convertmnc.bash ${TARGET_DIR}/${CASE}/temp ${BASE_PATH}
