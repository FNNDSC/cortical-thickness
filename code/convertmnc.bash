#!/bin/bash
BASE_PATH=/neuro/labs/grantlab/research/MRI_processing
CASE=FCB028
TARGET_DIR=${BASE_PATH}/jose.cisneros/CSFSegmentation/Results/${CASE}/temp
RESOURCES_DIR=${BASE_PATH}/jose.cisneros/CSFSegmentation

# Setup Dependencies
LD_LIBRARY_PATH="${RESOURCES_DIR}/lib:"$LD_LIBRARY_PATH
LD_LIBRARY_PATH="${RESOURCES_DIR}/bin/brainvisa-4.5.0/lib:"$LD_LIBRARY_PATH


for i in ${TARGET_DIR}/*.mnc; do
    [ -f "$i" ] || break
    ${RESOURCES_DIR}/bin/mnc2nii $i "${i%.mnc}.nii"
done
