BASE_PATH=/neuro/labs/grantlab/research/MRI_processing
BASE_DIR=${BASE_PATH}/jose.cisneros/CSFSegmentation/Samples # ${2}

for d in ${BASE_DIR}/*/ ; do
    source code/CSF-SEGMENTATION-pipeline-0.0.3.bash `basename "$d"`
done
