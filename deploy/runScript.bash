#!/bin/bash
BASE_PATH=${1:-"/neuro/labs/grantlab/research/MRI_processing/jose.cisneros/CorticalThickness"}
${BASE_PATH}/code/corticalThicknessDocker.py -ca FCB028 -im ${BASE_PATH}/Samples/FCB028/recon_to31.nii -is ${BASE_PATH}/Samples/FCB028/segmentation_to31_final.nii -o ${BASE_PATH}/Results -se False