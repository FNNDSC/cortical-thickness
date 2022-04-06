#### Python venv - activate
source ${RESOURCES_DIR}/bin/pyenv/bin/activate

# Test: GMM - Gaussian Mixture Model, Soft Clustering CSF/GM
#### Prepare files
${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/temp/cerebral_int.mnc ${TARGET_DIR}/${CASE}/temp/gmm_wm.nii -short
${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/temp/cerebral_ext.mnc ${TARGET_DIR}/${CASE}/temp/gmm_gm.nii -short
${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/input/${INPUT_NAME_POSPROCESS}.mnc ${TARGET_DIR}/${CASE}/temp/mri.nii -short
#### Call Script
python3 ${RESOURCES_DIR}/code/python/gmm_clustering.py \
    -inPath ${TARGET_DIR}/${CASE}/temp \
    -inMRI mri.nii \
    -inWM gmm_wm.nii \
    -inGM gmm_gm.nii \
    -outPath ${TARGET_DIR}/${CASE}/temp \
    -outCSF gmm_csf.nii \
    -verbose 1 \
    -plot 1 \
    -threshold 0.67

#### Python venv - deactivate
deactivate

# Test: Pial Surface Extraction, WM expansion. (Using 65% Mean Intensity CSF)
#### Prepare files
${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/temp/CSFfirstguess.mnc ${TARGET_DIR}/${CASE}/temp/ps_csf.nii -short
${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/temp/cerebral_int.mnc ${TARGET_DIR}/${CASE}/temp/ps_wm.nii -short
${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/input/${INPUT_NAME_POSPROCESS}.mnc ${TARGET_DIR}/${CASE}/temp/mri.nii -short
#### Call Script
python3 ${RESOURCES_DIR}/code/python/pial_surface.py \
    -inPath ${TARGET_DIR}/${CASE}/temp \
    -inMRI mri.nii \
    -inCSF ps_csf.nii \
    -inWM ps_wm.nii \
    -outPath ${TARGET_DIR}/${CASE}/output \
    -outPS ps.nii \
    -iterations 10 \
    -verbose 1 \
    -plot 1

# Test: Pial Surface Extraction, WM expansion. (Using GMM Intensity CSF)
#### Prepare files

# Join CSF with initial contour determined by CP (to obtain an enclosed surface).
# ${RESOURCES_DIR}/bin/nii2mnc -clobber ${TARGET_DIR}/${CASE}/temp/gmm_csf.nii ${TARGET_DIR}/${CASE}/temp/gmm_csf.mnc -double
# mincmath -or ${TARGET_DIR}/${CASE}/temp/gmm_csf.mnc ${TARGET_DIR}/${CASE}/temp/csf_skeleton_from_cerebral_ext.mnc ${TARGET_DIR}/${CASE}/temp/ps2_csf.mnc -clobber
# ${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/temp/ps2_csf.mnc ${TARGET_DIR}/${CASE}/temp/ps2_csf.nii -short

cp ${TARGET_DIR}/${CASE}/temp/gmm_csf.nii ${TARGET_DIR}/${CASE}/temp/ps2_csf.nii
${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/temp/cerebral_int.mnc ${TARGET_DIR}/${CASE}/temp/ps2_wm.nii -short
${RESOURCES_DIR}/bin/mnc2nii ${TARGET_DIR}/${CASE}/input/${INPUT_NAME_POSPROCESS}.mnc ${TARGET_DIR}/${CASE}/temp/mri.nii -short
#### Call Script
python3 ${RESOURCES_DIR}/code/python/pial_surface.py \
    -inPath ${TARGET_DIR}/${CASE}/temp \
    -inMRI mri.nii \
    -inCSF ps2_csf.nii \
    -inWM ps2_wm.nii \
    -outPath ${TARGET_DIR}/${CASE}/output \
    -outPS ps2.nii \
    -iterations 10 \
    -verbose 1 \
    -plot 1

#### Python venv - deactivate
deactivate
