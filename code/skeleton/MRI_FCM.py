#!/usr/bin/env python3
"""
Soft Clustering CSF/GM considering intensity using FCM.
Made by Jose Cisneros, April 19 2022
"""
import os
import argparse
import numpy as np
from scipy import ndimage
from nibabel import load, save, Nifti1Image
import matplotlib.pyplot as plt
from matplotlib import colors
import sys
import pathlib
sys.path.append(str(pathlib.Path(__file__).parent))
from FCM import FCM

class MRI_FCM():
    MIN_ERROR = 1e-6
    MAX_ITER = 500
    N_CLUSTERS = 2
    LABELS = ["CSF", "GM"]

    def __init__(self):
        self.args = None
        self.argumentParser()
        
        self.nii = None
        self.mriData = None
        self.wmData = None
        self.gmData = None
        self.loadData()
        
        self.outputData = None
        self.run()
    
    def run(self):
        mriDataFiltered = self.mriData * self.inData
        
        # Split Input Data, Value, Index
        intensities = []
        indexes = []
        it = np.nditer(mriDataFiltered, flags=['multi_index'])
        count = 0
        for x in it:
            if x != 0:
                intensities.append(x)
                indexes.append(it.multi_index)
        n = len(intensities)
        
        # Calculate FCM Clustering
        intensities = np.array(intensities).reshape(n,-1)
        FCM_ = FCM(n_clusters=MRI_FCM.N_CLUSTERS, min_error = MRI_FCM.MIN_ERROR, max_iter = MRI_FCM.MAX_ITER, verbose = True)
        FCM_.fit(intensities)
        prob = FCM_.soft_predict(intensities)
        intensities = np.array(intensities).reshape((n,))
        
        if self.args.PLOT:
            self.plot(intensities, prob)
        
        # Generate & Save Resultant CSF Mask.
        self.outputDataL1 = np.zeros(self.mriData.shape, dtype=self.mriData.dtype)
        self.outputMaskL1 = np.zeros(self.mriData.shape, dtype=self.mriData.dtype)
        self.outputDataL2 = np.zeros(self.mriData.shape, dtype=self.mriData.dtype)
        self.outputMaskL2 = np.zeros(self.mriData.shape, dtype=self.mriData.dtype)
        for i in range(len(intensities)):
            if prob[i][0] > self.args.THRESHOLD:
                self.outputDataL1[indexes[i]] = intensities[i]
                self.outputMaskL1[indexes[i]] = 1
            elif prob[i][1] > self.args.THRESHOLD:
                self.outputDataL2[indexes[i]] = intensities[i]
                self.outputMaskL2[indexes[i]] = 1
        
        if (np.mean(self.outputDataL1) > np.mean(self.outputDataL2)):
            self.saveNII(self.args.OUT_PATH + "/" + self.args.OUT_CSF, self.outputMaskL1)
            self.saveNII(self.args.OUT_PATH + "/_" + self.args.OUT_CSF, self.outputMaskL2)
        else:
            self.saveNII(self.args.OUT_PATH + "/" + self.args.OUT_CSF, self.outputMaskL2)
            self.saveNII(self.args.OUT_PATH + "/_" + self.args.OUT_CSF, self.outputMaskL1)

    def plot(self, x, data, name="gmm"):
        data = data.T
        self.showInfo("Data Ready " + str(data.shape) )

        fig = plt.figure()
        ax = fig.add_subplot(131)
        ax.plot(x, data[0], color='red', alpha=0.7)
        ax.plot(x, data[1], color='gray', alpha=0.5)
        ax.set_ylim(0, 1)
        ax.set_xlabel('$x$')
        ax.set_ylabel(r'$p({\rm class}|x)$')

        plt.savefig(self.args.OUT_PATH + "/" + name + ".png")

    def saveNII(self, name, data):
        out = Nifti1Image(data, header=self.nii.header, affine=self.nii.affine)
        save(out, name)
        self.showInfo("Nii File Saved. " + name)

    def loadData(self):
        self.nii = load(self.args.IN_PATH + "/" + self.args.IN_VOL)
        self.inData = np.asarray(self.nii.dataobj)
        self.showInfo("IN Data Loaded: " + str(self.inData.shape))
        self.nii = load(self.args.IN_PATH + "/" + self.args.IN_MRI)
        self.mriData = np.asarray(self.nii.dataobj)
        self.showInfo("MRI Data Loaded: " + str(self.mriData.shape))

    def argumentParser(self):
        parser = argparse.ArgumentParser("   ==========   Gaussian Mixture Model, Soft Clustering CSF/GM by Jose Cisneros (March 22), 2022 ver.1)   ==========   ")
        parser.add_argument("-inPath", "--IN_PATH",action="store",dest="IN_PATH",type=str, default="/neuro/labs/grantlab/research/MRI_processing/jose.cisneros/CSFSegmentation/Results/FCB028/temp", help="input folder")
        parser.add_argument("-inMRI", "--IN_MRI",action="store",dest="IN_MRI",type=str, default="mri.nii", help="input .nii file containing MRI with intensities")
        parser.add_argument("-inVOL", "--IN_VOL",action="store",dest="IN_VOL",type=str, default="gmm_input.nii", help="input binarize .nii file containing CSF & GM")
        parser.add_argument("-outPath", "--OUT_PATH",action="store",dest="OUT_PATH",type=str, default="/neuro/labs/grantlab/research/MRI_processing/jose.cisneros/CSFSegmentation/Results/FCB028/temp", help="output folder")
        parser.add_argument("-outCSF", "--OUT_CSF",action="store",dest="OUT_CSF",type=str, default="gmm_csf.nii", help="output binarize .nii file containing improved CSF")
        parser.add_argument("-verbose", "--VERBOSE",action="store",dest="VERBOSE",type=bool, default=True, help="Show logs")
        parser.add_argument("-plot", "--PLOT",action="store",dest="PLOT",type=bool, default=False, help="Save Plot")
        parser.add_argument("-threshold", "--THRESHOLD",action="store",dest="THRESHOLD",type=float, default=0.62, help="Threshold Probability of being CSF")
        self.args = parser.parse_args()
    
    def showInfo(self, text):
        if self.args.VERBOSE:
            print(text)

MRI_FCM()
