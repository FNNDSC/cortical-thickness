BASE_PATH=/neuro/labs/grantlab/research/MRI_processing/jose.cisneros/CorticalThickness

for d in ${BASE_PATH}/Samples/*/ ; do
    ${BASE_PATH}/code/corticalThickness.py \
        -ca `basename "$d"` \
        -im ${BASE_PATH}/Samples/FCB028/recon_to31.nii \
        -is ${BASE_PATH}/Samples/FCB028/segmentation_to31_final.nii \
        -ir False \
        -rp no_intensity_
    ${BASE_PATH}/code/corticalThickness.py \
        -ca `basename "$d"` \
        -im ${BASE_PATH}/Samples/FCB028/recon_to31.nii \
        -is ${BASE_PATH}/Samples/FCB028/segmentation_to31_final.nii \
        -ir True \
        -icm sFCM
done
