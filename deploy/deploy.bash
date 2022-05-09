#!/bin/bash
BASE_PATH=${1:-"/neuro/labs/grantlab/research/MRI_processing/jose.cisneros/CorticalThickness"}
docker build -t cortical-thickness ${BASE_PATH} -f ${BASE_PATH}/deploy/Dockerfile