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

# Change Labels For Laplace
minccalc -expression 'if(A[0]==161){out=3}else if(A[0]==1){out=2}else{out=0}' ${TARGET_DIR}/${CASE}/input/${INPUT_SEG_NAME}.mnc ${TARGET_DIR}/${CASE}/temp/${INPUT_SEG_NAME}_left.mnc -clobber
minccalc -expression 'if(A[0]==160){out=3}else if(A[0]==42){out=2}else{out=0}' ${TARGET_DIR}/${CASE}/input/${INPUT_SEG_NAME}.mnc ${TARGET_DIR}/${CASE}/temp/${INPUT_SEG_NAME}_right.mnc -clobber

laplace.pl segmentation_to31_final_left.mnc lh.white_marching_cube.obj 2 laplacian_to31_left.mnc;

expand_from_white.pl ${file}/lh.smoothwm.native_81920.obj ${file}/lh.pial.native_81920.obj ${file}/laplacian_to31_left.mnc;
