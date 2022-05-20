#!/bin/bash
BASE_PATH=/neuro/labs/grantlab/research/MRI_processing/jose.cisneros/CorticalThickness
CASE=${1}
freeview    -v ${BASE_PATH}/Results/${CASE}/output/skeleton_output.mnc \
            -v ${BASE_PATH}/Results/${CASE}/surfaces/laplacian_to31_left_fixed.mnc \
            -v ${BASE_PATH}/Results/${CASE}/surfaces/laplacian_to31_right_fixed.mnc \
            -f ${BASE_PATH}/Results/${CASE}/surfaces/*.asc \
            -v ${BASE_PATH}/Results/${CASE}/input/input_mri.mnc \
            -v ${BASE_PATH}/Results/${CASE}/temp/gm_ext.mnc \
            -v ${BASE_PATH}/NUC_Results/${CASE}/output/skeleton_output.mnc \
            -v ${BASE_PATH}/NUC_Results/${CASE}/surfaces/laplacian_to31_left_fixed.mnc \
            -v ${BASE_PATH}/NUC_Results/${CASE}/surfaces/laplacian_to31_right_fixed.mnc \
            -f ${BASE_PATH}/NUC_Results/${CASE}/surfaces/*.asc \
            -v ${BASE_PATH}/NUC_Results/${CASE}/input/input_mri.mnc \
            -v ${BASE_PATH}/NUC_Results/${CASE}/temp/gm_ext.mnc