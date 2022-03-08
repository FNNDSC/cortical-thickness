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
INPUT_SEG_NAME=segmentation_to31_final

# Setup Dependencies
/neuro/labs/grantlab/research/HyukJin_MRI/CIVET/quarantines/Linux-x86_64/init.sh

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

# Dilation Cerebral Exterior
mincmorph -filetype -successive DD ${TARGET_DIR}/${CASE}/temp/cerebral_ext.mnc -clobber ${TARGET_DIR}/${CASE}/temp/cerebral_ext_d.mnc

#############################################################
# CSF Skeleton extracted from Cerebral Exterior - Getting the out part of dilation.

# Binarize all segmentations [from 1 to 161]
mincmath -segment -const2 1 161 ${TARGET_DIR}/${CASE}/input/${INPUT_SEG_NAME}.mnc ${TARGET_DIR}/${CASE}/temp/initial_segmentations.mnc -clobber
# Dilatation Initial Segmentation.
mincmorph -filetype -successive D ${TARGET_DIR}/${CASE}/temp/initial_segmentations.mnc -clobber ${TARGET_DIR}/${CASE}/temp/initial_segmentations_dilated.mnc
# Subtract initial segmentations dilated from the dilated cerebral exterior.
mincmath -sub ${TARGET_DIR}/${CASE}/temp/cerebral_ext_d.mnc ${TARGET_DIR}/${CASE}/temp/initial_segmentations_dilated.mnc ${TARGET_DIR}/${CASE}/temp/sub_dilation.mnc -clobber
# Remove all negative areas (inner part).
mincmath -gt -const 0 ${TARGET_DIR}/${CASE}/temp/sub_dilation.mnc -clobber ${TARGET_DIR}/${CASE}/temp/csf_skeleton_from_cerebral_ext.mnc


#############################################################
# Try to fill some of the undetected sulcus due to similar intensity between WM and CSFs.

# Calculate the max intensities in MRI
MAX_INTENSITY=`mincstats ${TARGET_DIR}/${CASE}/input/${INPUT_NAME}.mnc -max -quiet`
# Calculate the mean intensities for CSFs
MEAN_CSF=`mincstats ${TARGET_DIR}/${CASE}/input/${INPUT_NAME}.mnc -mean -mask ${TARGET_DIR}/${CASE}/temp/csf_skeleton_from_cerebral_ext.mnc -mask_binvalue 1 -quiet`
AMP_=0.65
MEAN_CSF2=$(echo "${AMP_}*${MEAN_CSF}" | bc)

echo $MAX_INTENSITY
echo $MEAN_CSF
echo $MEAN_CSF2

#mincmath -segment -const2 0.5 2.5 ${TARGET_DIR}/${CASE}/temp/${PREFIX}_${CASE}_final_classify_defrag3.mnc ${TARGET_DIR}/${CASE}/temp/graycsf_union.mnc -clobber

# Segment areas brighter than 65% percent of the CSF mean.
mincmath -segment -const2 $MEAN_CSF2 $MAX_INTENSITY ${TARGET_DIR}/${CASE}/input/${INPUT_NAME}.mnc ${TARGET_DIR}/${CASE}/temp/CSFmeanall.mnc -clobber
# Subtract ground truth from initial segmentations.
mincmath -sub ${TARGET_DIR}/${CASE}/temp/CSFmeanall.mnc ${TARGET_DIR}/${CASE}/temp/initial_segmentations.mnc ${TARGET_DIR}/${CASE}/temp/CSFfirstguess_tmp.mnc -clobber
# Remove all negative areas (inner part).
mincmath -gt -const 0 ${TARGET_DIR}/${CASE}/temp/CSFfirstguess_tmp.mnc -clobber ${TARGET_DIR}/${CASE}/temp/CSFfirstguess_tmp2.mnc
# Remove noise.
mincmorph -filetype -successive DEED ${TARGET_DIR}/${CASE}/temp/CSFfirstguess_tmp2.mnc -clobber ${TARGET_DIR}/${CASE}/temp/CSFfirstguess.mnc

exit 0
# mincmorph -group ${TARGET_DIR}/${CASE}/temp/CSFmeanall.mnc ${TARGET_DIR}/${CASE}/temp/tmp.mnc -clobber
# mincmath -segment -const2 5 1000 ${TARGET_DIR}/${CASE}/temp/tmp.mnc ${TARGET_DIR}/${CASE}/temp/CSF_fill.mnc -clobber

# mincmath -or ${TARGET_DIR}/${CASE}/temp/CSF_fill.mnc ${TARGET_DIR}/${CASE}/temp/graycsf_union.mnc ${TARGET_DIR}/${CASE}/temp/graycsf_union2.mnc -clobber

mincmorph -successive DEDEDE ${TARGET_DIR}/${CASE}/temp/graycsf_union2.mnc ${TARGET_DIR}/${CASE}/temp/graycsf_union_dil.mnc -clobber

###############################################################
# Use the corrected CSF to 

mincmath -seg -const2 1.5 3.5 ${TARGET_DIR}/${CASE}/temp/${PREFIX}_${CASE}_final_classify_defrag3.mnc ${TARGET_DIR}/${CASE}/temp/graywhite.mnc -clobber

${NEOCIVET_DIR}/civet-2.1.0-cdrom/Linux-x86_64/bin/mnc2nii ${TARGET_DIR}/${CASE}/temp/graywhite.mnc ${TARGET_DIR}/${CASE}/temp/graywhite_a.nii -short

minccalc -clobber -expr 'if(A[1]==0){out=11}else if(A[0]>0){out=512}else{out=0}' ${TARGET_DIR}/${CASE}/temp/graycsf_union_dil.mnc ${TARGET_DIR}/${CASE}/temp/${PREFIX}_${CASE}_t1_final_new_mask.mnc ${TARGET_DIR}/${CASE}/temp/graycsf_union_dil_enhance.mnc

${NEOCIVET_DIR}/civet-2.1.0-cdrom/Linux-x86_64/bin/mnc2nii ${TARGET_DIR}/${CASE}/temp/graycsf_union_dil_enhance.mnc ${TARGET_DIR}/${CASE}/temp/graycsf_union_dil_a.nii -short

${NEOCIVET_DIR}/bin/applywarp -i ${TARGET_DIR}/${CASE}/temp/graycsf_union_dil_a.nii -o ${TARGET_DIR}/${CASE}/temp/graycsf_union_dil_b.nii -r ${RESOURCE_DIR}/test_aaa.nii.gz -d short

${NEOCIVET_DIR}/brainvisa-4.5.0/bin/VipSkeleton -i ${TARGET_DIR}/${CASE}/temp/graycsf_union_dil_b.nii.gz -so ${TARGET_DIR}/${CASE}/temp/skelmask.nii -vo ${TARGET_DIR}/${CASE}/temp/roots.nii -g ${TARGET_DIR}/${CASE}/temp/graywhite_a.nii -p c -wp 0 -lz 0 -lu 10 -e 0.5 -mct 0 -gct -10

${NEOCIVET_DIR}/bin/applywarp -i ${TARGET_DIR}/${CASE}/temp/skelmask.nii -o ${TARGET_DIR}/${CASE}/temp/skelmask_corr.nii -r ${RESOURCE_DIR}/test_aaa.nii.gz -d short 

${NEOCIVET_DIR}/bin/nii2mnc -clobber ${TARGET_DIR}/${CASE}/temp/skelmask_corr.nii ${TARGET_DIR}/${CASE}/temp/skelmask_corr_a.mnc -short

minccalc -clobber -expression 'if(A[0]>12.5) out=1 else out=0' ${TARGET_DIR}/${CASE}/temp/skelmask_corr_a.mnc ${TARGET_DIR}/${CASE}/temp/skelmask_corr_bin.mnc

mincmorph -successive DD ${TARGET_DIR}/${CASE}/temp/skelmask_corr_bin.mnc ${TARGET_DIR}/${CASE}/temp/skelmask_dil.mnc -clobber

#####################

mincmath -and ${TARGET_DIR}/${CASE}/temp/skelmask_dil.mnc ${TARGET_DIR}/${CASE}/temp/${PREFIX}_${CASE}_t1_final_new_mask.mnc ${TARGET_DIR}/${CASE}/temp/skelmask_final_half.mnc -clobber

mincmath -or ${TARGET_DIR}/${CASE}/temp/skelmask_final_half.mnc ${TARGET_DIR}/${CASE}/temp/graycsf_union2.mnc ${TARGET_DIR}/${CASE}/temp/skelmask_final_half2.mnc -clobber

mincmorph -successive DEDEDE ${TARGET_DIR}/${CASE}/temp/skelmask_final_half2.mnc ${TARGET_DIR}/${CASE}/temp/skelmask_final.mnc -clobber
