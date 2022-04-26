#!/usr/bin/env python3
"""
Soft Clustering CSF/GM considering intensity using sFCM.
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
from sFCM import sFCM

class MRI_sFCM():
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
        self.wmData = ndimage.binary_dilation(self.wmData, iterations=1) # 3D06 Kernel
        mriDataFiltered = self.mriData * np.logical_not(self.wmData) # GM & CSF = Brain - WM.
        
        # Split Input Data, Value, Index
        intensities = []
        _1DTo3D = []
        _3DTo1D = {}
        it = np.nditer(mriDataFiltered, flags=['multi_index'])
        count = 0
        for x in it:
            if x != 0:
                intensities.append(x)
                _1DTo3D.append(it.multi_index)
                _3DTo1D[it.multi_index] = count
                count += 1
        n = count
        
        # Calculate sFCM Clustering
        intensities = np.array(intensities).reshape(n,-1)
        sFCM_ = sFCM(n_clusters=MRI_sFCM.N_CLUSTERS, min_error = MRI_sFCM.MIN_ERROR, max_iter = MRI_sFCM.MAX_ITER, verbose = True)
        sFCM_.fit(intensities, _1DTo3D, _3DTo1D, mriDataFiltered)
        prob = sFCM_.soft_predict(intensities, _1DTo3D, _3DTo1D, mriDataFiltered)
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
        self.nii = load(self.args.IN_PATH + "/" + self.args.IN_WM)
        self.wmData = np.asarray(self.nii.dataobj)
        self.showInfo("WM Data Loaded: " + str(self.wmData.shape))
        self.nii = load(self.args.IN_PATH + "/" + self.args.IN_GM)
        self.gmData = np.asarray(self.nii.dataobj)
        self.showInfo("GM Data Loaded: " + str(self.gmData.shape))
        self.nii = load(self.args.IN_PATH + "/" + self.args.IN_MRI)
        self.mriData = np.asarray(self.nii.dataobj)
        self.showInfo("MRI Data Loaded: " + str(self.mriData.shape))

    def argumentParser(self):
        parser = argparse.ArgumentParser("   ==========   Gaussian Mixture Model, Soft Clustering CSF/GM by Jose Cisneros (March 22), 2022 ver.1)   ==========   ")
        parser.add_argument("-inPath", "--IN_PATH",action="store",dest="IN_PATH",type=str, default="/neuro/labs/grantlab/research/MRI_processing/jose.cisneros/CSFSegmentation/Results/FCB028/temp", help="input folder")
        parser.add_argument("-inMRI", "--IN_MRI",action="store",dest="IN_MRI",type=str, default="mri.nii", help="input .nii file containing MRI with intensities")
        parser.add_argument("-inWM", "--IN_WM",action="store",dest="IN_WM",type=str, default="gmm_wm.nii", help="input binarize .nii file containing White Matter")
        parser.add_argument("-inGM", "--IN_GM",action="store",dest="IN_GM",type=str, default="gmm_gm.nii", help="input binarize .nii file containing Gray Matter")
        parser.add_argument("-outPath", "--OUT_PATH",action="store",dest="OUT_PATH",type=str, default="/neuro/labs/grantlab/research/MRI_processing/jose.cisneros/CSFSegmentation/Results/FCB028/temp", help="output folder")
        parser.add_argument("-outCSF", "--OUT_CSF",action="store",dest="OUT_CSF",type=str, default="gmm_csf.nii", help="output binarize .nii file containing improved CSF")
        parser.add_argument("-verbose", "--VERBOSE",action="store",dest="VERBOSE",type=bool, default=True, help="Show logs")
        parser.add_argument("-plot", "--PLOT",action="store",dest="PLOT",type=bool, default=False, help="Save Plot")
        parser.add_argument("-threshold", "--THRESHOLD",action="store",dest="THRESHOLD",type=float, default=0.62, help="Threshold Probability of being CSF")
        self.args = parser.parse_args()
    
    def showInfo(self, text):
        if self.args.VERBOSE:
            print(text)

MRI_sFCM()
