
# Setup:
SET BASE_PATH indicating the path to CorticalThickness folder.

Ex.
```
BASE_PATH=${1:-"/neuro/labs/grantlab/research/MRI_processing/jose.cisneros/CorticalThickness"}
```

# Bash Environment

## 1-. Create Image with Bash Entrypoint. 
```
docker build -t cortical-thickness-b ${BASE_PATH} -f ${BASE_PATH}/deploy/Dockerfile.bash
```
## 2-. Create Container for cortical-thickness image.
```
${BASE_PATH}/deploy/runBash.sh
```
## 3-. Enter cortical-thickness container bash.
```
docker exec -it cortical-thickness-test bash
```

# Python Entrypoint

## 1-. Create Image with Python Entrypoint. 
```
docker build -t cortical-thickness ${BASE_PATH} -f ${BASE_PATH}/deploy/Dockerfile
```
## 2-. Call Script in temporary Container using cortical-thickness image.
See optional arguments:
```
docker run cortical-thickness -v ${BASE_PATH}:/CorticalThickness -h
```

See optional arguments:
```
docker run cortical-thickness -v ${BASE_PATH}:/CorticalThickness -h
```

Ex.

```
docker run cortical-thickness -v ${BASE_PATH}:/CorticalThickness -ca FCB028
```
