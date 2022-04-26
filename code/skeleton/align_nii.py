#!/usr/bin/env python3
"""
Script useful to align two nii files.
Made by Jose Cisneros, April 4 2022
"""
import os
import argparse
import numpy as np
from scipy import ndimage
from nibabel import load, save, Nifti1Image

class AlignNii():
    def __init__(self):
        self.args = None
        self.argumentParser()
        self.niiIn = None
        self.inData = None
        self.niiTemplate = None
        self.templateData = None
        self.loadData()
        self.outputData = None
        self.run()
    
    def run(self):
        self.outputData = self.inData
        self.saveNII(self.args.OUT_PATH + "/" + self.args.OUT_NII, self.outputData)

    def saveNII(self, name, data):
        out = Nifti1Image(data, header=self.niiTemplate.header, affine=self.niiTemplate.affine)
        save(out, name)
        self.showInfo("Nii File Saved. " + name)

    def loadData(self):
        self.niiIn = load(self.args.IN_PATH + "/" + self.args.IN_NII)
        self.inData = np.asarray(self.niiIn.dataobj)
        self.showInfo("IN Nii Data Loaded: " + str(self.inData.shape))
        self.niiTemplate = load(self.args.IN_PATH + "/" + self.args.IN_TEMPLATE)
        self.templateData = np.asarray(self.niiTemplate.dataobj)
        self.showInfo("IN Template Data Loaded: " + str(self.templateData.shape))

    def argumentParser(self):
        parser = argparse.ArgumentParser("   ==========   Align Two Nii Files by Jose Cisneros (April 4), 2022 ver.1)   ==========   ")
        parser.add_argument("-inPath", "--IN_PATH",action="store",dest="IN_PATH",type=str, default="/neuro/labs/grantlab/research/MRI_processing/jose.cisneros/CSFSegmentation/Results/FCB028/temp", help="input folder")
        parser.add_argument("-inNii", "--IN_NII",action="store",dest="IN_NII",type=str, default="mri.nii", help="input .nii file containing original MRI")
        parser.add_argument("-inTemplate", "--IN_TEMPLATE",action="store",dest="IN_TEMPLATE",type=str, default="skull_wm.nii", help="input binarize .nii file containing White Matter")
        parser.add_argument("-outPath", "--OUT_PATH",action="store",dest="OUT_PATH",type=str, default="/neuro/labs/grantlab/research/MRI_processing/jose.cisneros/CSFSegmentation/Results/FCB028/output", help="output folder")
        parser.add_argument("-outNii", "--OUT_NII",action="store",dest="OUT_NII",type=str, default="out.nii", help="output binarize .nii file aligned with template")
        parser.add_argument("-verbose", "--VERBOSE",action="store",dest="VERBOSE",type=bool, default=True, help="Show logs")
        self.args = parser.parse_args()

    def showInfo(self, text):
        if self.args.VERBOSE:
            print(text)

AlignNii()
