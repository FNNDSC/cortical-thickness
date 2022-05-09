#!/bin/bash
TARGET_FILES=${1}
BASE_PATH=${2:-"/neuro/labs/grantlab/research/MRI_processing/jose.cisneros/CorticalThickness"}
RESOURCES_DIR=${BASE_PATH}

# Setup Dependencies
LD_LIBRARY_PATH="${RESOURCES_DIR}/lib:"$LD_LIBRARY_PATH
LD_LIBRARY_PATH="${RESOURCES_DIR}/bin/brainvisa-4.5.0/lib:"$LD_LIBRARY_PATH

for i in ${TARGET_FILES}/*.mnc; do
    [ -f "$i" ] || break
    ${RESOURCES_DIR}/bin/mnc2nii $i "${i%.mnc}.nii"
done
