#!/usr/bin/env python3
"""
Skull extraction expanding White Matter till outside.
Made by Jose Cisneros, April 1 2022
"""
import os
import argparse
import numpy as np
from scipy import ndimage
from nibabel import load, save, Nifti1Image

class Skull():
    def __init__(self):
        self.args = None
        self.argumentParser()
        self.nii = None
        self.mriData = None
        self.wmData = None
        self.loadData()
        self.outputData = None
        self.run()
    
    def run(self):
        self.outputData = np.zeros(self.mriData.shape, dtype=self.mriData.dtype)
        for i in range(self.args.ITERATIONS):
            self.showInfo("Running Iteration " + str(i))
            self.iteration()
        self.saveNII(self.args.OUT_PATH + "/" + self.args.OUT_SKULL, self.outputData)

    def saveNII(self, name, data):
        out = Nifti1Image(data, header=self.nii.header, affine=self.nii.affine)
        save(out, name)
        self.showInfo("Nii File Saved. " + name)

    def loadData(self):
        self.nii = load(self.args.IN_PATH + "/" + self.args.IN_WM)
        self.wmData = np.asarray(self.nii.dataobj)
        self.showInfo("WM Data Loaded: " + str(self.wmData.shape))
        self.nii = load(self.args.IN_PATH + "/" + self.args.IN_MRI)
        self.mriData = np.asarray(self.nii.dataobj)
        self.mriData = np.where(self.mriData > 0, 1, 0) # Mask
        self.showInfo("MRI Data Loaded: " + str(self.mriData.shape))
    
    def iteration(self):
        self.wmData = ndimage.binary_dilation(self.wmData, iterations=1) # 3D06 Kernel
        intersection = np.logical_and(self.wmData, np.logical_not(self.mriData))
        self.outputData = np.logical_or(self.outputData, intersection)
        self.wmData =  np.logical_and(self.wmData, np.logical_not(intersection)) # Remove Intersection from WM. (WM & !intersection)

    def argumentParser(self):
        parser = argparse.ArgumentParser("   ==========   Skull Extraction by Jose Cisneros (March 21), 2022 ver.1)   ==========   ")
        parser.add_argument("-inPath", "--IN_PATH",action="store",dest="IN_PATH",type=str, default="/neuro/labs/grantlab/research/MRI_processing/jose.cisneros/CSFSegmentation/Results/FCB028/temp", help="input folder")
        parser.add_argument("-inMRI", "--IN_MRI",action="store",dest="IN_MRI",type=str, default="mri.nii", help="input .nii file containing original MRI")
        parser.add_argument("-inWM", "--IN_WM",action="store",dest="IN_WM",type=str, default="skull_wm.nii", help="input binarize .nii file containing White Matter")
        parser.add_argument("-outPath", "--OUT_PATH",action="store",dest="OUT_PATH",type=str, default="/neuro/labs/grantlab/research/MRI_processing/jose.cisneros/CSFSegmentation/Results/FCB028/output", help="output folder")
        parser.add_argument("-outSkull", "--OUT_SKULL",action="store",dest="OUT_SKULL",type=str, default="skull.nii", help="output binarize .nii file containing Skull external boundary")
        parser.add_argument("-iterations", "--ITERATIONS",action="store",dest="ITERATIONS",type=int, default=15, help="# Dilations of WM")
        parser.add_argument("-verbose", "--VERBOSE",action="store",dest="VERBOSE",type=bool, default=True, help="Show logs")
        self.args = parser.parse_args()
    
    def showInfo(self, text):
        if self.args.VERBOSE:
            print(text)

Skull()
