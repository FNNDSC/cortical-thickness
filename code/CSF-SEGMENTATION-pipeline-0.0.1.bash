#!/bin/bash

CASE=FCB028 # ${1}
BASE_DIR=/neuro/labs/grantlab/research/MRI_processing/jose.cisneros/CSFSegmentation/Samples # ${2}
TARGET_DIR=/neuro/labs/grantlab/research/MRI_processing/jose.cisneros/CSFSegmentation/Results # ${3}
RESOURCES_DIR=/neuro/labs/grantlab/research/MRI_processing/jose.cisneros/CSFSegmentation # ${3}

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

###############################
# Labels:
# 1: Left-Cerebral-Exterior
# 42: Right-Cerebral-Exterior
# 160: Right-Cerebral-WM-unmyelinated
# 161: Left-Cerebral-WM-myelinated
###############################

# Conversion from .nii to .mnc
${RESOURCES_DIR}/bin/nii2mnc -clobber ${BASE_DIR}/${CASE}/${INPUT_NAME}.nii ${TARGET_DIR}/${CASE}/input/${INPUT_NAME}.mnc -double
${RESOURCES_DIR}/bin/nii2mnc -clobber ${BASE_DIR}/${CASE}/${INPUT_SEG_NAME}.nii ${TARGET_DIR}/${CASE}/input/${INPUT_SEG_NAME}.mnc -float

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
${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/temp/initial_segmentations_sides_joined.mnc ${TARGET_DIR}/${CASE}/temp/initial_segmentations_sides_joined.nii -short

# Remove Cerebellum
mincmorph -filetype -successive DDDDDDD ${TARGET_DIR}/${CASE}/temp/initial_segmentations.mnc -clobber ${TARGET_DIR}/${CASE}/temp/initial_segmentations_7_dilated.mnc
minccalc -expression 'if(A[0]==1){out=A[1]}else{out=0}' ${TARGET_DIR}/${CASE}/temp/initial_segmentations_7_dilated.mnc ${TARGET_DIR}/${CASE}/input/${INPUT_NAME}.mnc ${TARGET_DIR}/${CASE}/input/${INPUT_NAME_POSPROCESS}.mnc -clobber

#############################################################
# CSF Skeleton extracted from Cerebral Exterior - Getting the out part of dilation.

# Dilation Cerebral Exterior
mincmorph -filetype -successive DD ${TARGET_DIR}/${CASE}/temp/cerebral_ext.mnc -clobber ${TARGET_DIR}/${CASE}/temp/cerebral_ext_d.mnc
# Dilatation Initial Segmentation.
mincmorph -filetype -successive D ${TARGET_DIR}/${CASE}/temp/initial_segmentations.mnc -clobber ${TARGET_DIR}/${CASE}/temp/initial_segmentations_dilated.mnc
# Subtract initial segmentations dilated from the dilated cerebral exterior.
mincmath -sub ${TARGET_DIR}/${CASE}/temp/cerebral_ext_d.mnc ${TARGET_DIR}/${CASE}/temp/initial_segmentations_dilated.mnc ${TARGET_DIR}/${CASE}/temp/sub_dilation.mnc -clobber
# Remove all negative areas (inner part).
mincmath -gt -const 0 ${TARGET_DIR}/${CASE}/temp/sub_dilation.mnc -clobber ${TARGET_DIR}/${CASE}/temp/csf_skeleton_from_cerebral_ext.mnc

#############################################################
# Try to fill some of the undetected sulcus due to similar intensity between WM and CSFs.

# Calculate the max intensities in MRI
MAX_INTENSITY=`mincstats ${TARGET_DIR}/${CASE}/input/${INPUT_NAME_POSPROCESS}.mnc -max -quiet`
# Calculate the mean intensities for CSFs
MEAN_CSF=`mincstats ${TARGET_DIR}/${CASE}/input/${INPUT_NAME_POSPROCESS}.mnc -mean -mask ${TARGET_DIR}/${CASE}/temp/csf_skeleton_from_cerebral_ext.mnc -mask_binvalue 1 -quiet`
AMP_=0.65
MEAN_CSF2=$(echo "${AMP_}*${MEAN_CSF}" | bc)

echo $MAX_INTENSITY
echo $MEAN_CSF
echo $MEAN_CSF2

#mincmath -segment -const2 0.5 2.5 ${TARGET_DIR}/${CASE}/temp/${PREFIX}_${CASE}_final_classify_defrag3.mnc ${TARGET_DIR}/${CASE}/temp/graycsf_union.mnc -clobber

# Segment areas brighter than 65% percent of the CSF mean.
mincmath -segment -const2 $MEAN_CSF2 $MAX_INTENSITY ${TARGET_DIR}/${CASE}/input/${INPUT_NAME_POSPROCESS}.mnc ${TARGET_DIR}/${CASE}/temp/CSFmeanall.mnc -clobber
# Subtract ground truth from initial segmentations.
mincmath -sub ${TARGET_DIR}/${CASE}/temp/CSFmeanall.mnc ${TARGET_DIR}/${CASE}/temp/initial_segmentations.mnc ${TARGET_DIR}/${CASE}/temp/CSFfirstguess_tmp.mnc -clobber
# Remove all negative areas (inner part).
mincmath -gt -const 0 ${TARGET_DIR}/${CASE}/temp/CSFfirstguess_tmp.mnc -clobber ${TARGET_DIR}/${CASE}/temp/CSFfirstguess_tmp2.mnc
# Remove noise.
${RESOURCES_DIR}/bin/mincdefrag ${TARGET_DIR}/${CASE}/temp/CSFfirstguess_tmp2.mnc ${TARGET_DIR}/${CASE}/temp/CSFfirstguess_tmp3.mnc 1 27
# Join with initial contour determined by CP.
mincmath -or ${TARGET_DIR}/${CASE}/temp/CSFfirstguess_tmp3.mnc ${TARGET_DIR}/${CASE}/temp/csf_skeleton_from_cerebral_ext.mnc ${TARGET_DIR}/${CASE}/temp/CSFfirstguess_1.mnc -clobber
# Fill holes inside CSF
mincmorph -filetype -3D26 -successive CC ${TARGET_DIR}/${CASE}/temp/CSFfirstguess_1.mnc -clobber ${TARGET_DIR}/${CASE}/temp/CSFfirstguess.mnc
# Dilation and Erosion Process to join separate clusters.  # Not ideal.Form Alterations
# mincmorph -filetype -3D26 -successive DDDDEEEE ${TARGET_DIR}/${CASE}/temp/CSFfirstguess_2.mnc -clobber ${TARGET_DIR}/${CASE}/temp/CSFfirstguess_f.mnc

#####################(GM + CSF -> Skeleton)########################################
# First Test: Merge CSF estimated with intensities with GM.
mincmath -or ${TARGET_DIR}/${CASE}/temp/CSFfirstguess.mnc ${TARGET_DIR}/${CASE}/temp/cerebral_ext.mnc ${TARGET_DIR}/${CASE}/temp/csf_and_gm_with_intensity.mnc -clobber
#### Prepare file, Gray Scale and nii zipped.
minccalc -expression 'if(A[0]==0){out=0}else{out=255}' ${TARGET_DIR}/${CASE}/temp/csf_and_gm_with_intensity.mnc ${TARGET_DIR}/${CASE}/temp/csf_and_gm_with_intensity_grayscale.mnc -clobber
${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/temp/csf_and_gm_with_intensity_grayscale.mnc ${TARGET_DIR}/${CASE}/temp/csf_and_gm_with_intensity1.nii -short
gzip -k ${TARGET_DIR}/${CASE}/temp/csf_and_gm_with_intensity1.nii --verbose
#### Skeleton
${RESOURCES_DIR}/bin/brainvisa-4.5.0/bin/VipSkeleton -i ${TARGET_DIR}/${CASE}/temp/csf_and_gm_with_intensity1.nii.gz -so ${TARGET_DIR}/${CASE}/temp/skeleton_1.nii -vo ${TARGET_DIR}/${CASE}/temp/roots.nii -g ${TARGET_DIR}/${CASE}/temp/initial_segmentations_sides_joined.nii -p c -wp 0 -lz 0 -lu 10 -e 0.5 -mct 0 -gct -10
# Binarize Skeleton
${RESOURCES_DIR}/bin/nii2mnc -clobber ${TARGET_DIR}/${CASE}/temp/skeleton_1.nii ${TARGET_DIR}/${CASE}/temp/skeleton_1_.mnc -double
minccalc -clobber -expression 'if(A[0]>11.5){out=1}else{out=0}' ${TARGET_DIR}/${CASE}/temp/skeleton_1_.mnc ${TARGET_DIR}/${CASE}/temp/skeleton_1_corr.mnc

# Second Test: Obtain an estimation of CSF merged with GM removing whitematter from brain extraction.
minccalc -expression 'if(A[0]>0&&A[1]==1){out=0}else if(A[0]==0){out=0}else{out=1}' ${TARGET_DIR}/${CASE}/input/${INPUT_NAME_POSPROCESS}.mnc ${TARGET_DIR}/${CASE}/temp/cerebral_int.mnc ${TARGET_DIR}/${CASE}/temp/csf_and_gm_with_wm.mnc -clobber
#### Prepare file, Gray Scale and nii zipped.
minccalc -expression 'if(A[0]==0){out=0}else{out=255}' ${TARGET_DIR}/${CASE}/temp/csf_and_gm_with_wm.mnc ${TARGET_DIR}/${CASE}/temp/csf_and_gm_with_wm_grayscale.mnc -clobber
${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/temp/csf_and_gm_with_wm_grayscale.mnc ${TARGET_DIR}/${CASE}/temp/csf_and_gm_with_wm1.nii -short
gzip -k ${TARGET_DIR}/${CASE}/temp/csf_and_gm_with_wm1.nii --verbose
#### Skeleton
${RESOURCES_DIR}/bin/brainvisa-4.5.0/bin/VipSkeleton -i ${TARGET_DIR}/${CASE}/temp/csf_and_gm_with_wm1.nii -so ${TARGET_DIR}/${CASE}/temp/skeleton_2.nii -g ${TARGET_DIR}/${CASE}/temp/initial_segmentations_sides_joined.nii -p c -wp 0 -lz 0 -lu 10 -e 0.5 -mct 0 -gct -10
# Binarize Skeleton
${RESOURCES_DIR}/bin/nii2mnc -clobber ${TARGET_DIR}/${CASE}/temp/skeleton_2.nii ${TARGET_DIR}/${CASE}/temp/skeleton_2_.mnc -double
minccalc -clobber -expression 'if(A[0]>11.5){out=1}else{out=0}' ${TARGET_DIR}/${CASE}/temp/skeleton_2_.mnc ${TARGET_DIR}/${CASE}/temp/skeleton_2_corr.mnc

# Third Test: GM with 1 voxel dilation to the outside.
#### Subtract interior initial segmentations from the dilated cerebral exterior.
mincmath -sub ${TARGET_DIR}/${CASE}/temp/cerebral_ext_d.mnc ${TARGET_DIR}/${CASE}/temp/cerebral_int.mnc ${TARGET_DIR}/${CASE}/temp/sub_gm_dilated.mnc -clobber
#### Remove all negative areas (inner part).
mincmath -gt -const 0 ${TARGET_DIR}/${CASE}/temp/sub_gm_dilated.mnc -clobber ${TARGET_DIR}/${CASE}/temp/gm_dilated_as_csf_and_gm.mnc
#### Prepare file, Gray Scale and nii zipped.
minccalc -expression 'if(A[0]==0){out=0}else{out=255}' ${TARGET_DIR}/${CASE}/temp/gm_dilated_as_csf_and_gm.mnc ${TARGET_DIR}/${CASE}/temp/gm_dilated_as_csf_and_gm_grayscale.mnc -clobber
${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/temp/gm_dilated_as_csf_and_gm_grayscale.mnc ${TARGET_DIR}/${CASE}/temp/gm_dilated_as_csf_and_gm1.nii -short
gzip -k ${TARGET_DIR}/${CASE}/temp/gm_dilated_as_csf_and_gm1.nii --verbose
#### Skeleton
${RESOURCES_DIR}/bin/brainvisa-4.5.0/bin/VipSkeleton -i ${TARGET_DIR}/${CASE}/temp/gm_dilated_as_csf_and_gm1.nii -so ${TARGET_DIR}/${CASE}/temp/skeleton_3.nii -g ${TARGET_DIR}/${CASE}/temp/initial_segmentations_sides_joined.nii -p c -wp 0 -lz 0 -lu 10 -e 0.5 -mct 0 -gct -10
# Binarize Skeleton
${RESOURCES_DIR}/bin/nii2mnc -clobber ${TARGET_DIR}/${CASE}/temp/skeleton_3.nii ${TARGET_DIR}/${CASE}/temp/skeleton_3_.mnc -double
minccalc -clobber -expression 'if(A[0]>11.5){out=1}else{out=0}' ${TARGET_DIR}/${CASE}/temp/skeleton_3_.mnc ${TARGET_DIR}/${CASE}/temp/skeleton_3_corr.mnc
#########################################################################
