#!/bin/bash

if [ $# -lt 1 ]; then
  echo 1>&2 "$0: not enough arguments, missing case id."
  return
fi

CASE=${1}
BASE_PATH=${2:-"/neuro/labs/grantlab/research/MRI_processing/jose.cisneros/CorticalThickness"}
BASE_DIR=${BASE_PATH}/Samples
TARGET_DIR=${3:-${BASE_PATH}/Results}
RESOURCES_DIR=${BASE_PATH}
export RESOURCES_DIR

LEFT=161
RIGHT=160

rm -rf ${TARGET_DIR}/${CASE}/surfaces
mkdir -p ${TARGET_DIR}/${CASE}/surfaces

mincmath -clobber -eq -const $LEFT  ${TARGET_DIR}/${CASE}/input/input_mri_seg.mnc ${TARGET_DIR}/${CASE}/temp/inner_left.mnc
mincmath -clobber -eq -const $RIGHT ${TARGET_DIR}/${CASE}/input/input_mri_seg.mnc ${TARGET_DIR}/${CASE}/temp/inner_right.mnc

mincblur -clobber -fwhm 3 ${TARGET_DIR}/${CASE}/temp/inner_left.mnc ${TARGET_DIR}/${CASE}/temp/inner_left_fwhm;
mincblur -clobber -fwhm 3 ${TARGET_DIR}/${CASE}/temp/inner_right.mnc ${TARGET_DIR}/${CASE}/temp/inner_right_fwhm;

${RESOURCES_DIR}/bin/extract_white_surface_fetus_new.pl ${TARGET_DIR}/${CASE}/temp/inner_left_fwhm_blur.mnc ${TARGET_DIR}/${CASE}/temp/lh.white.obj 0.5;
${RESOURCES_DIR}/bin/extract_white_surface_fetus_new.pl ${TARGET_DIR}/${CASE}/temp/inner_right_fwhm_blur.mnc ${TARGET_DIR}/${CASE}/temp/rh.white.obj 0.5;
${RESOURCES_DIR}/bin/mesh_to_std_format.pl -left ${TARGET_DIR}/${CASE}/temp/lh.white_20480.obj ${TARGET_DIR}/${CASE}/surfaces/lh.smoothwm.to31.obj;
${RESOURCES_DIR}/bin/mesh_to_std_format.pl -right ${TARGET_DIR}/${CASE}/temp/rh.white_20480.obj ${TARGET_DIR}/${CASE}/surfaces/rh.smoothwm.to31.obj;
${RESOURCES_DIR}/bin/transform_objects ${TARGET_DIR}/${CASE}/surfaces/lh.smoothwm.to31.obj ${RESOURCES_DIR}/share/surftmat.xfm ${TARGET_DIR}/${CASE}/surfaces/lh.smoothwm.native.obj;
${RESOURCES_DIR}/bin/transform_objects ${TARGET_DIR}/${CASE}/surfaces/rh.smoothwm.to31.obj ${RESOURCES_DIR}/share/surftmat.xfm ${TARGET_DIR}/${CASE}/surfaces/rh.smoothwm.native.obj;
# Freesurfer format
${RESOURCES_DIR}/bin/obj2asc ${TARGET_DIR}/${CASE}/surfaces/lh.smoothwm.native.obj ${TARGET_DIR}/${CASE}/surfaces/lh.smoothwm.native.asc;
${RESOURCES_DIR}/bin/obj2asc ${TARGET_DIR}/${CASE}/surfaces/rh.smoothwm.native.obj ${TARGET_DIR}/${CASE}/surfaces/rh.smoothwm.native.asc;
