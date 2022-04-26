#!/usr/bin/python
import nibabel as nib
import numpy as np
import sys
import os


filename = sys.argv[1]
vol = nib.load(sys.argv[1])
vol_data = vol.get_data()




left_in = np.zeros(np.shape(vol.get_data()))
right_in = np.zeros(np.shape(vol.get_data()))
left_plate = np.zeros(np.shape(vol.get_data()))
right_plate = np.zeros(np.shape(vol.get_data()))
total_left = np.zeros(np.shape(vol.get_data()))
total_right = np.zeros(np.shape(vol.get_data()))

loc = np.where(np.round(vol_data)==161)
total_left[loc]=3

loc = np.where(np.round(vol_data)==160)
total_right[loc]=3

loc = np.where(np.round(vol_data)==1)
total_left[loc]=2

loc = np.where(np.round(vol_data)==42)
total_right[loc]=2


new_img_left = nib.Nifti1Image(total_left, vol.affine, vol.header)
new_img_right = nib.Nifti1Image(total_right, vol.affine, vol.header)
nib.save(new_img_left, filename[:-4]+'_left.nii')
nib.save(new_img_right, filename[:-4]+'_right.nii')

os.system('nii2mnc -short '+filename[:-4]+'_left.nii '+filename[:-4]+'_left.mnc')
os.system('nii2mnc -short '+filename[:-4]+'_right.nii '+filename[:-4]+'_right.mnc')

#os.system('mri_morphology '+filename[:-4]+'_left.nii dilate 2 '+filename[:-4]+'_csf_temp_left.nii')
#os.system('mri_morphology '+filename[:-4]+'_right.nii dilate 2 '+filename[:-4]+'_csf_temp_right.nii')

#dil_left = nib.load(filename[:-4]+'_csf_temp_left.nii')
#dil_right = nib.load(filename[:-4]+'_csf_temp_right.nii')
#loc = np.where(total_left==161)

#vol_data = vol.get_data()
