#!/bin/bash

if [ $# -lt 1 ]; then
  echo 1>&2 "$0: not enough arguments, missing case id."
  return
fi

RESULTS_PREFIX=${3:-}
CASE=${1}
BASE_PATH=${2:-"/neuro/labs/grantlab/research/MRI_processing/jose.cisneros/CorticalThickness"}
BASE_DIR=${BASE_PATH}/Samples
TARGET_DIR=${BASE_PATH}/${RESULTS_PREFIX}Results
RESOURCES_DIR=${BASE_PATH}
export RESOURCES_DIR

INPUT_SKELETON=${TARGET_DIR}/${CASE}/output/skeleton_output.mnc
USE_SKELETON=true # False to extract surface using deeplearning segementation external boundary.

if [ "$USE_SKELETON" = true ] ; then
  # Remove Skeleton Intersection from CP.
  minccalc -expression 'if(A[0] && !A[1]){out=1}else{out=0}' ${TARGET_DIR}/${CASE}/temp/cerebral_left_ext.mnc ${INPUT_SKELETON} ${TARGET_DIR}/${CASE}/temp/cerebral_left_ext_skel.mnc -clobber
  minccalc -expression 'if(A[0] && !A[1]){out=1}else{out=0}' ${TARGET_DIR}/${CASE}/temp/cerebral_right_ext.mnc ${INPUT_SKELETON} ${TARGET_DIR}/${CASE}/temp/cerebral_right_ext_skel.mnc -clobber
else
  cp ${TARGET_DIR}/${CASE}/temp/cerebral_left_ext.mnc ${TARGET_DIR}/${CASE}/temp/cerebral_left_ext_skel.mnc
  cp ${TARGET_DIR}/${CASE}/temp/cerebral_right_ext.mnc ${TARGET_DIR}/${CASE}/temp/cerebral_right_ext_skel.mnc
fi

# Change Labels For Laplace Field
minccalc -expression 'if(A[0]==1){out=3}else if(A[1]==1){out=2}else{out=0}' -clobber \
  ${TARGET_DIR}/${CASE}/temp/cerebral_left_int.mnc \
  ${TARGET_DIR}/${CASE}/temp/cerebral_left_ext_skel.mnc \
  ${TARGET_DIR}/${CASE}/temp/in_laplace_left.mnc
minccalc -expression 'if(A[0]==1){out=3}else if(A[1]==1){out=2}else{out=0}' -clobber \
  ${TARGET_DIR}/${CASE}/temp/cerebral_right_int.mnc \
  ${TARGET_DIR}/${CASE}/temp/cerebral_right_ext_skel.mnc \
  ${TARGET_DIR}/${CASE}/temp/in_laplace_right.mnc

# Generate Laplace Field
CP_LABEL=2
${RESOURCES_DIR}/code/surfaceExtraction/laplace.pl \
  ${TARGET_DIR}/${CASE}/temp/in_laplace_left.mnc \
  ${TARGET_DIR}/${CASE}/surfaces/lh.smoothwm.to31.obj \
  ${CP_LABEL} \
  ${TARGET_DIR}/${CASE}/surfaces/laplacian_to31_left.mnc;
${RESOURCES_DIR}/code/surfaceExtraction/laplace.pl \
  ${TARGET_DIR}/${CASE}/temp/in_laplace_right.mnc \
  ${TARGET_DIR}/${CASE}/surfaces/rh.smoothwm.to31.obj \
  ${CP_LABEL} \
  ${TARGET_DIR}/${CASE}/surfaces/laplacian_to31_right.mnc;

if [ "$USE_SKELETON" = true ] ; then
  # Laplace Field - Skeleton Corrections
  minccalc -expression 'if(A[0]==1 && A[1]<10){out=10}else{out=A[1]}' -clobber \
    ${INPUT_SKELETON} \
    ${TARGET_DIR}/${CASE}/surfaces/laplacian_to31_left.mnc \
    ${TARGET_DIR}/${CASE}/surfaces/laplacian_to31_left_fixed.mnc
  minccalc -expression 'if(A[0]==1 && A[1]<10){out=10}else{out=A[1]}' -clobber \
    ${INPUT_SKELETON} \
    ${TARGET_DIR}/${CASE}/surfaces/laplacian_to31_right.mnc \
    ${TARGET_DIR}/${CASE}/surfaces/laplacian_to31_right_fixed.mnc
else
  cp ${TARGET_DIR}/${CASE}/surfaces/laplacian_to31_left.mnc ${TARGET_DIR}/${CASE}/surfaces/laplacian_to31_left_fixed.mnc
  cp ${TARGET_DIR}/${CASE}/surfaces/laplacian_to31_right.mnc ${TARGET_DIR}/${CASE}/surfaces/laplacian_to31_right_fixed.mnc
fi

# Expand White Matter till Laplace Field, CP Surface Extraction
${RESOURCES_DIR}/code/surfaceExtraction/expand_from_white_fetal.pl -left \
  ${TARGET_DIR}/${CASE}/surfaces/lh.smoothwm.to31.obj \
  ${TARGET_DIR}/${CASE}/surfaces/lh.pial.native_81920.obj \
  ${TARGET_DIR}/${CASE}/surfaces/laplacian_to31_left_fixed.mnc;
${RESOURCES_DIR}/code/surfaceExtraction/expand_from_white_fetal.pl -right \
  ${TARGET_DIR}/${CASE}/surfaces/rh.smoothwm.to31.obj \
  ${TARGET_DIR}/${CASE}/surfaces/rh.pial.native_81920.obj \
  ${TARGET_DIR}/${CASE}/surfaces/laplacian_to31_right_fixed.mnc;

${RESOURCES_DIR}/bin/mesh_to_std_format.pl -left ${TARGET_DIR}/${CASE}/surfaces/lh.pial.native_81920.obj ${TARGET_DIR}/${CASE}/surfaces/lh.pial.native.to31.obj;
${RESOURCES_DIR}/bin/mesh_to_std_format.pl -right ${TARGET_DIR}/${CASE}/surfaces/rh.pial.native_81920.obj ${TARGET_DIR}/${CASE}/surfaces/rh.pial.native.to31.obj;
${RESOURCES_DIR}/bin/transform_objects ${TARGET_DIR}/${CASE}/surfaces/lh.pial.native.to31.obj ${RESOURCES_DIR}/share/surftmat.xfm ${TARGET_DIR}/${CASE}/surfaces/lh.pial.native.obj;
${RESOURCES_DIR}/bin/transform_objects ${TARGET_DIR}/${CASE}/surfaces/rh.pial.native.to31.obj ${RESOURCES_DIR}/share/surftmat.xfm ${TARGET_DIR}/${CASE}/surfaces/rh.pial.native.obj;

# Freesurfer format
${RESOURCES_DIR}/bin/obj2asc ${TARGET_DIR}/${CASE}/surfaces/lh.pial.native.obj ${TARGET_DIR}/${CASE}/surfaces/lh.pial.native.asc;
${RESOURCES_DIR}/bin/obj2asc ${TARGET_DIR}/${CASE}/surfaces/rh.pial.native.obj ${TARGET_DIR}/${CASE}/surfaces/rh.pial.native.asc;
