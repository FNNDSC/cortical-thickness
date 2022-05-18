${RESOURCES_DIR}/bin/cortical_thickness -tlink -fwhm 10 -transform ${RESOURCES_DIR}/share/surftmat.xfm ${TARGET_DIR}/${CASE}/surfaces/lh.smoothwm.to31.obj ${TARGET_DIR}/${CASE}/surfaces/lh.pial.native.obj ${TARGET_DIR}/${CASE}/morphometrics/native_rms_tlink_10mm_left.txt
${RESOURCES_DIR}/bin/cortical_thickness -tlink -fwhm 10 -transform ${RESOURCES_DIR}/share/surftmat.xfm ${TARGET_DIR}/${CASE}/surfaces/rh.smoothwm.to31.obj ${TARGET_DIR}/${CASE}/surfaces/rh.pial.native.obj ${TARGET_DIR}/${CASE}/morphometrics/native_rms_tlink_10mm_right.txt

${RESOURCES_DIR}/bin/cortical_thickness -tlaplace -fwhm 10 -transform ${RESOURCES_DIR}/share/surftmat.xfm ${TARGET_DIR}/${CASE}/surfaces/lh.smoothwm.to31.obj ${TARGET_DIR}/${CASE}/surfaces/lh.pial.native.obj ${TARGET_DIR}/${CASE}/morphometrics/native_rms_tlaplace_10mm_left.txt
${RESOURCES_DIR}/bin/cortical_thickness -tlaplace -fwhm 10 -transform ${RESOURCES_DIR}/share/surftmat.xfm ${TARGET_DIR}/${CASE}/surfaces/rh.smoothwm.to31.obj ${TARGET_DIR}/${CASE}/surfaces/rh.pial.native.obj ${TARGET_DIR}/${CASE}/morphometrics/native_rms_tlaplace_10mm_right.txt

${RESOURCES_DIR}/bin/cortical_thickness -tnear -fwhm 10 -transform ${RESOURCES_DIR}/share/surftmat.xfm ${TARGET_DIR}/${CASE}/surfaces/lh.smoothwm.to31.obj ${TARGET_DIR}/${CASE}/surfaces/lh.pial.native.obj ${TARGET_DIR}/${CASE}/morphometrics/native_rms_tnear_10mm_left.txt
${RESOURCES_DIR}/bin/cortical_thickness -tnear -fwhm 10 -transform ${RESOURCES_DIR}/share/surftmat.xfm ${TARGET_DIR}/${CASE}/surfaces/rh.smoothwm.to31.obj ${TARGET_DIR}/${CASE}/surfaces/rh.pial.native.obj ${TARGET_DIR}/${CASE}/morphometrics/native_rms_tnear_10mm_right.txt

${RESOURCES_DIR}/bin/depth_potential -alpha 0.05 -depth_potential ${TARGET_DIR}/${CASE}/surfaces/lh.smoothwm.to31.obj ${TARGET_DIR}/${CASE}/morphometrics/wm_sulcaldepth_left.txt
${RESOURCES_DIR}/bin/depth_potential -alpha 0.05 -depth_potential ${TARGET_DIR}/${CASE}/surfaces/rh.smoothwm.to31.obj ${TARGET_DIR}/${CASE}/morphometrics/wm_sulcaldepth_right.txt
