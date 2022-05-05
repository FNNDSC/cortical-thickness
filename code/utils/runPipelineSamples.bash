BASE_PATH=/neuro/labs/grantlab/research/MRI_processing
BASE_DIR=${BASE_PATH}/jose.cisneros/CorticalThickness/Samples # ${2}

for d in ${BASE_DIR}/*/ ; do
    source code/SKELETON-pipeline-0.1.bash `basename "$d"`
done
