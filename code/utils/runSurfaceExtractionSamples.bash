BASE_PATH=/neuro/labs/grantlab/research/MRI_processing/jose.cisneros/CorticalThickness

for d in ${BASE_PATH}/Samples/*/ ; do
    ${BASE_PATH}/code/SURFACE-EXTRACTION.bash `basename "$d"` ${BASE_PATH}
done
