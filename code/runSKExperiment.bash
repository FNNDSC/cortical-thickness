BASE_PATH=/neuro/labs/grantlab/research/MRI_processing
BASE_DIR=${BASE_PATH}/jose.cisneros/CorticalThickness/Samples # ${2}

for i in $(seq 0 0.1 1); do
    source code/SKELETON-pipeline-0.1.bash FCB028 $i
done
