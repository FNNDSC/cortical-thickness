# Cortical Thickness

## Description
This repository includes the code capable of extracting the cortical surface and calculating the cortical thickness given the deeplearning initial segmentations of GM and WM.
Prior exctrating the cortical surface a method of homotopic skeletonization is used to find CSF in the sulcus of the GM deeplearning segmentation and another method of soft clustering is implemented for intensity refinement of its boundary.

## Development team

| Name | Email | Github | Role |
| ---- | ----- | ------ | ---- |
| José Alfonso Cisneros	Morales | [joseacisnerosm@gmail.com](mailto:joseacisnerosm@gmail.com) | [@Josecisneros001](https://github.com/Josecisneros001) | Developer |


## Requirements / Setup

SET BASE_PATH indicating the path to CorticalThickness folder.

Ex.
```
BASE_PATH=/neuro/labs/grantlab/research/MRI_processing/jose.cisneros/CorticalThickness
```

Using Docker:
- Repository
```
    git clone https://github.com/Josecisneros001/fnndsc-cortical-thickness.git
```
- Ubuntu
- Docker Engine
- python3
- Docker Image -> cortical-thickness
    ```
        # Option 1:
        docker build -t cortical-thickness ${BASE_PATH} -f ${BASE_PATH}/deploy/Dockerfile
        # Option 2:
        docker pull ghcr.io/josecisneros001/fnndsc-cortical-thickness
        docker tag ghcr.io/josecisneros001/fnndsc-cortical-thickness cortical-thickness
    ```
Without Docker:
- Repository
```
    git clone https://github.com/Josecisneros001/fnndsc-cortical-thickness.git
```
- Ubuntu
- All Dependencies declared in bin, lib & share folders.
    - Dependencies can be obtained from the original code or from the published Docker Image following this steps:
    ```
        # Pull Image from Container Registry.
        docker pull ghcr.io/josecisneros001/fnndsc-cortical-thickness
        docker tag ghcr.io/josecisneros001/fnndsc-cortical-thickness cortical-thickness

        # Create cortical-thickness-test container using cortical-thickness image.
        source $BASE_PATH/deploy/runBash.sh
        
        # Extract dependencies
        docker cp cortical-thickness-test:/corticalThickness/bin $BASE_PATH/bin
        docker cp cortical-thickness-test:/corticalThickness/lib $BASE_PATH/lib
        docker cp cortical-thickness-test:/corticalThickness/share $BASE_PATH/share

        # Stop Container
        docker container stop cortical-thickness-test
        # Remove Container
        docker container rm cortical-thickness-test
    ```
- python3


## How to Run

### Usage without Docker
Args Documentation
```
${BASE_PATH}/code/corticalThickness.py -h
```

Example:
Output Folder: {BASE_PATH}/Results/{CASE}
```
${BASE_PATH}/code/corticalThickness.py \
    -ca FCB028 \
    -im ${BASE_PATH}/Samples/FCB028/recon_to31.nii \
    -is ${BASE_PATH}/Samples/FCB028/segmentation_to31_final.nii
```

### Usage with Docker
Args Documentation:
```
${BASE_PATH}/code/corticalThicknessDocker.py -h
```

Example:
Output Folder: {BASE_PATH}/Results/{CASE} # Indicated as an argument.
```
${BASE_PATH}/code/corticalThicknessDocker.py \
    -ca FCB028 \
    -im ${BASE_PATH}/Samples/FCB028/recon_to31.nii \
    -is ${BASE_PATH}/Samples/FCB028/segmentation_to31_final.nii \
    -o ${BASE_PATH}/Results
```


## Update Docker Image Published In Github Docker Registry
```
# Login.
docker login ghcr.io
    # Option1: Build your image if it doesn't exist yet.
    docker build -t ghcr.io/josecisneros001/FNNDSC-Cortical-Thickness .
    # Option2: Tag it if already exists.
    docker tag cortical-thickness ghcr.io/josecisneros001/fnndsc-cortical-thickness
# Upload.
docker push ghcr.io/josecisneros001/fnndsc-cortical-thickness
```
