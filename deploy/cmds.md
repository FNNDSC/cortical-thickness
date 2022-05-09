
# Setup:
SET BASE_PATH indicating the path to CorticalThickness folder.

Ex.
```
BASE_PATH=${1:-"/neuro/labs/grantlab/research/MRI_processing/jose.cisneros/CorticalThickness"}
```

## Usage Example
Output Folder: {BASE_PATH}/Results/{CASE}
```
${BASE_PATH}/code/corticalThickness.py \
    -ca FCB028 \
    -im ${BASE_PATH}/Samples/FCB028/recon_to31.nii \
    -is ${BASE_PATH}/Samples/FCB028/segmentation_to31_final.nii \
```

## Usage Example with Docker
Args Documentation:
```
${BASE_PATH}/code/corticalThicknessDocker.py -h
```

```
${BASE_PATH}/code/corticalThicknessDocker.py \
    -ca FCB028 \
    -im ${BASE_PATH}/Samples/FCB028/recon_to31.nii \
    -is ${BASE_PATH}/Samples/FCB028/segmentation_to31_final.nii \
    -o ${BASE_PATH}/Results
```