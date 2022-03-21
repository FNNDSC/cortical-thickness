#!/usr/bin/env python3
"""
Pial Surface extraction expanding White Matter till CSF.
Made by Jose Cisneros, March 21 2021
"""
import os
import argparse
import numpy as np
from scipy import ndimage
from nibabel import load, save, Nifti1Image

class PialSurface():
    def __init__(self):
        self.args = None
        self.argumentParser()
        self.nii = None
        self.wmData = None
        self.csfData = None
        self.loadData()
        self.outputData = None
        self.run()
    
    def run(self):
        self.outputData = np.zeros(self.csfData.shape, dtype=self.csfData.dtype)
        for i in range(self.args.ITERATIONS):
            self.showInfo("Running Iteration " + str(i))
            self.iteration()
        out = Nifti1Image(self.outputData, header=self.nii.header, affine=self.nii.affine)
        save(out, self.args.OUT_PATH + "/" + self.args.OUT_PS)
        self.showInfo("Output File Saved. " + self.args.OUT_PATH + "/" + self.args.OUT_PS)

    def loadData(self):
        self.nii = load(self.args.IN_PATH + "/" + self.args.IN_WM)
        self.wmData = np.asarray(self.nii.dataobj)
        self.showInfo("WM Data Loaded: " + str(self.wmData.shape))
        self.nii = load(self.args.IN_PATH + "/" + self.args.IN_CSF)
        self.csfData = np.asarray(self.nii.dataobj)
        self.showInfo("CSF Data Loaded: " + str(self.csfData.shape))
    
    def iteration(self):
        self.wmData = ndimage.binary_dilation(self.wmData, iterations=1) # 3D06 Kernel
        intersection = np.logical_and(self.wmData, self.csfData)
        self.outputData = np.logical_or(self.outputData, intersection)
        self.wmData =  np.logical_and(self.wmData, np.logical_not(intersection)) # Remove Intersection from WM. (WM & !intersection)

    def argumentParser(self):
        parser = argparse.ArgumentParser('   ==========   Fetal Pial Surface Extraction by Jose Cisneros (March 21), 2022 ver.1)   ==========   ')
        parser.add_argument('-inPath', '--IN_PATH',action='store',dest='IN_PATH',type=str, default="/neuro/labs/grantlab/research/MRI_processing/jose.cisneros/CSFSegmentation/Results/FCB028/temp", help='input folder')
        parser.add_argument('-inWM', '--IN_WM',action='store',dest='IN_WM',type=str, default="ps_wm.nii", help='input binarize .nii file containing White Matter')
        parser.add_argument('-inCSF', '--IN_CSF',action='store',dest='IN_CSF',type=str, default="ps_csf.nii", help='input binarize .nii file containing CSF')
        parser.add_argument('-outPath', '--OUT_PATH',action='store',dest='OUT_PATH',type=str, default="/neuro/labs/grantlab/research/MRI_processing/jose.cisneros/CSFSegmentation/Results/FCB028/output", help='output folder')
        parser.add_argument('-outPS', '--OUT_PS',action='store',dest='OUT_PS',type=str, default="ps.nii", help='output binarize .nii file containing Pial Surface')
        parser.add_argument('-iterations', '--ITERATIONS',action='store',dest='ITERATIONS',type=int, default=7, help='# Dilations of WM')
        parser.add_argument('-verbose', '--VERBOSE',action='store',dest='VERBOSE',type=bool, default=True, help='Show logs')
        self.args = parser.parse_args()

    def showInfo(self, text):
        if self.args.VERBOSE:
            print(text)

PialSurface()
