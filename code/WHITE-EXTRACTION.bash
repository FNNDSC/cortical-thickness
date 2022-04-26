#!/bin/bash

if [ $# -lt 1 ]; then
  echo 1>&2 "$0: not enough arguments, missing case id."
  return
fi

BASE_PATH=/neuro/labs/grantlab/research/MRI_processing
CASE=${1} #FCB028
BASE_DIR=${BASE_PATH}/jose.cisneros/CSFSegmentation/Samples # ${2}
TARGET_DIR=${BASE_PATH}/jose.cisneros/CSFSegmentation/Results # ${3}
RESOURCES_DIR=${BASE_PATH}/jose.cisneros/CSFSegmentation # ${3}

INPUT_NAME=recon_to31
INPUT_NAME_POSPROCESS=recon_to31_posprocess
INPUT_SEG_NAME=segmentation_to31_final

# Dependencies
source /neuro/labs/grantlab/research/HyukJin_MRI/CIVET/quarantines/Linux-x86_64/init.sh;

rm -rf ${TARGET_DIR}/${CASE}/surfaces
mkdir -p ${TARGET_DIR}/${CASE}/surfaces

LEFT=161
RIGHT=160
mincmath -clobber -eq -const $LEFT  ${TARGET_DIR}/${CASE}/input/${INPUT_SEG_NAME}.mnc ${TARGET_DIR}/${CASE}/temp/inner_left.mnc
mincmath -clobber -eq -const $RIGHT ${TARGET_DIR}/${CASE}/input/${INPUT_SEG_NAME}.mnc ${TARGET_DIR}/${CASE}/temp/inner_right.mnc

mincblur -clobber -fwhm 3 ${TARGET_DIR}/${CASE}/temp/inner_left.mnc ${TARGET_DIR}/${CASE}/temp/inner_left_fwhm;
mincblur -clobber -fwhm 3 ${TARGET_DIR}/${CASE}/temp/inner_right.mnc ${TARGET_DIR}/${CASE}/temp/inner_right_fwhm;

${RESOURCES_DIR}/bin/extract_white_surface_fetus_new.pl ${TARGET_DIR}/${CASE}/temp/inner_left_fwhm_blur.mnc ${TARGET_DIR}/${CASE}/temp/lh.white.obj 0.5;
${RESOURCES_DIR}/bin/extract_white_surface_fetus_new.pl ${TARGET_DIR}/${CASE}/temp/inner_right_fwhm_blur.mnc ${TARGET_DIR}/${CASE}/temp/rh.white.obj 0.5;
${RESOURCES_DIR}/bin/mesh_to_std_format.pl -left ${TARGET_DIR}/${CASE}/temp/lh.white_20480.obj ${TARGET_DIR}/${CASE}/surfaces/lh.smoothwm.to31.obj;
${RESOURCES_DIR}/bin/mesh_to_std_format.pl -right ${TARGET_DIR}/${CASE}/temp/rh.white_20480.obj ${TARGET_DIR}/${CASE}/surfaces/rh.smoothwm.to31.obj;
${RESOURCES_DIR}/bin/transform_objects ${TARGET_DIR}/${CASE}/surfaces/lh.smoothwm.to31.obj /neuro/labs/grantlab/research/MRI_processing/valeria.cruz/mri_data/surftmat.xfm ${TARGET_DIR}/${CASE}/surfaces/lh.smoothwm.native.obj;
${RESOURCES_DIR}/bin/transform_objects ${TARGET_DIR}/${CASE}/surfaces/rh.smoothwm.to31.obj /neuro/labs/grantlab/research/MRI_processing/valeria.cruz/mri_data/surftmat.xfm ${TARGET_DIR}/${CASE}/surfaces/rh.smoothwm.native.obj;
# Freesurfer format
${RESOURCES_DIR}/bin/obj2asc ${TARGET_DIR}/${CASE}/surfaces/lh.smoothwm.native.obj ${TARGET_DIR}/${CASE}/surfaces/lh.smoothwm.native.asc;
${RESOURCES_DIR}/bin/obj2asc ${TARGET_DIR}/${CASE}/surfaces/rh.smoothwm.native.obj ${TARGET_DIR}/${CASE}/surfaces/rh.smoothwm.native.asc;



# matlab_ulsan -nodisplay << EOF 

# addpath (genpath('${RESOURCES_DIR}/code/surfaceExtraction'))
# INPUT='${TARGET_DIR}/${CASE}/input/${INPUT_SEG_NAME}.nii'
# OUTPUT_L='${TARGET_DIR}/${CASE}/temp/lh.white'
# OUTPUT_R='${TARGET_DIR}/${CASE}/temp/rh.white'
# brainseg_isofurface(INPUT, 161, OUTPUT_L)
# brainseg_isofurface(INPUT, 160, OUTPUT_R)

# EOF

# mris_smooth -n 3 ${TARGET_DIR}/${CASE}/temp/lh.white ${TARGET_DIR}/${CASE}/temp/lh.smoothwm
# mris_smooth -n 3 ${TARGET_DIR}/${CASE}/temp/rh.white ${TARGET_DIR}/${CASE}/temp/rh.smoothwm
