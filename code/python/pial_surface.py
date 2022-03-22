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
import matplotlib.pyplot as plt
from matplotlib import colors

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
            if self.args.PLOT:
                self.plot3D("output_" + str(i))
        self.saveNII(self.args.OUT_PATH + "/" + self.args.OUT_PS, self.outputData)

    def saveNII(self, name, data):
        out = Nifti1Image(data, header=self.nii.header, affine=self.nii.affine)
        save(out, name)
        self.showInfo("Nii File Saved. " + name)

    def loadData(self):
        self.nii = load(self.args.IN_PATH + "/" + self.args.IN_MRI)
        self.mriData = np.asarray(self.nii.dataobj)
        self.showInfo("MRI Data Loaded: " + str(self.mriData.shape))
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
        parser = argparse.ArgumentParser("   ==========   Fetal Pial Surface Extraction by Jose Cisneros (March 21), 2022 ver.1)   ==========   ")
        parser.add_argument("-inPath", "--IN_PATH",action="store",dest="IN_PATH",type=str, default="/neuro/labs/grantlab/research/MRI_processing/jose.cisneros/CSFSegmentation/Results/FCB028/temp", help="input folder")
        parser.add_argument("-inMRI", "--IN_MRI",action="store",dest="IN_MRI",type=str, default="mri.nii", help="input .nii file containing original MRI")
        parser.add_argument("-inWM", "--IN_WM",action="store",dest="IN_WM",type=str, default="ps_wm.nii", help="input binarize .nii file containing White Matter")
        parser.add_argument("-inCSF", "--IN_CSF",action="store",dest="IN_CSF",type=str, default="ps_csf.nii", help="input binarize .nii file containing CSF")
        parser.add_argument("-outPath", "--OUT_PATH",action="store",dest="OUT_PATH",type=str, default="/neuro/labs/grantlab/research/MRI_processing/jose.cisneros/CSFSegmentation/Results/FCB028/output", help="output folder")
        parser.add_argument("-outPS", "--OUT_PS",action="store",dest="OUT_PS",type=str, default="ps.nii", help="output binarize .nii file containing Pial Surface")
        parser.add_argument("-iterations", "--ITERATIONS",action="store",dest="ITERATIONS",type=int, default=7, help="# Dilations of WM")
        parser.add_argument("-verbose", "--VERBOSE",action="store",dest="VERBOSE",type=bool, default=True, help="Show logs")
        parser.add_argument("-plot", "--PLOT",action="store",dest="PLOT",type=bool, default=False, help="Plot 3D")
        self.args = parser.parse_args()
    
    def plot3D(self, name="output"):
        img = self.mriData
        labelWM = self.wmData.astype(int)
        labelCSF = self.csfData.astype(int)
        labelCSF[labelCSF == 1] = 2
        labelPS = self.outputData.astype(int)
        labelPS[labelPS == 1] = 3

        f,axarr = plt.subplots(3,3,figsize=(9,9))
        f.patch.set_facecolor("k")
        cmap = colors.ListedColormap(['none','cyan', 'green', 'red'])
        bounds=[0, 0.5, 1.5, 2.5, 3.5]
        norm = colors.BoundaryNorm(bounds, cmap.N)

        f.text(0.4, 0.95, name, size="large", color="White")

        axarr[0,0].imshow(np.rot90(img[:,:,int(img.shape[-1]*0.4)]),cmap="gray")
        axarr[0,0].imshow(np.rot90(labelWM[:,:,int(labelWM.shape[-1]*0.4)]),alpha=0.15, interpolation='nearest', cmap=cmap, norm = norm)
        axarr[0,0].imshow(np.rot90(labelCSF[:,:,int(labelCSF.shape[-1]*0.4)]),alpha=0.15, interpolation='nearest', cmap=cmap, norm = norm)
        axarr[0,0].imshow(np.rot90(labelPS[:,:,int(labelPS.shape[-1]*0.4)]),alpha=0.5, interpolation='nearest', cmap=cmap, norm = norm)
        axarr[0,0].axis("off")

        axarr[0,1].imshow(np.rot90(img[:,:,int(img.shape[-1]*0.5)]),cmap="gray")
        axarr[0,1].imshow(np.rot90(labelWM[:,:,int(labelWM.shape[-1]*0.5)]),alpha=0.15, interpolation='nearest', cmap=cmap, norm = norm)
        axarr[0,1].imshow(np.rot90(labelCSF[:,:,int(labelCSF.shape[-1]*0.5)]),alpha=0.15, interpolation='nearest', cmap=cmap, norm = norm)
        axarr[0,1].imshow(np.rot90(labelPS[:,:,int(labelPS.shape[-1]*0.5)]),alpha=0.5, interpolation='nearest', cmap=cmap, norm = norm)
        axarr[0,1].axis("off")

        axarr[0,2].imshow(np.rot90(img[:,:,int(img.shape[-1]*0.6)]),cmap="gray")
        axarr[0,2].imshow(np.rot90(labelWM[:,:,int(labelWM.shape[-1]*0.6)]),alpha=0.15, interpolation='nearest', cmap=cmap, norm = norm)
        axarr[0,2].imshow(np.rot90(labelCSF[:,:,int(labelCSF.shape[-1]*0.6)]),alpha=0.15, interpolation='nearest', cmap=cmap, norm = norm)
        axarr[0,2].imshow(np.rot90(labelPS[:,:,int(labelPS.shape[-1]*0.6)]),alpha=0.5, interpolation='nearest', cmap=cmap, norm = norm)
        axarr[0,2].axis("off")

        axarr[1,0].imshow(np.rot90(img[:,int(img.shape[-2]*0.4),:]),cmap="gray")
        axarr[1,0].imshow(np.rot90(labelWM[:,int(labelWM.shape[-2]*0.4),:]),alpha=0.15, interpolation='nearest', cmap=cmap, norm = norm)
        axarr[1,0].imshow(np.rot90(labelCSF[:,int(labelCSF.shape[-2]*0.4),:]),alpha=0.15, interpolation='nearest', cmap=cmap, norm = norm)
        axarr[1,0].imshow(np.rot90(labelPS[:,int(labelPS.shape[-2]*0.4),:]),alpha=0.5, interpolation='nearest', cmap=cmap, norm = norm)
        axarr[1,0].axis("off")

        axarr[1,1].imshow(np.rot90(img[:,int(img.shape[-2]*0.5),:]),cmap="gray")
        axarr[1,1].imshow(np.rot90(labelWM[:,int(labelWM.shape[-2]*0.5),:]),alpha=0.15, interpolation='nearest', cmap=cmap, norm = norm)
        axarr[1,1].imshow(np.rot90(labelCSF[:,int(labelCSF.shape[-2]*0.5),:]),alpha=0.15, interpolation='nearest', cmap=cmap, norm = norm)
        axarr[1,1].imshow(np.rot90(labelPS[:,int(labelPS.shape[-2]*0.5),:]),alpha=0.5, interpolation='nearest', cmap=cmap, norm = norm)
        axarr[1,1].axis("off")

        axarr[1,2].imshow(np.rot90(img[:,int(img.shape[-2]*0.6),:]),cmap="gray")
        axarr[1,2].imshow(np.rot90(labelWM[:,int(labelWM.shape[-2]*0.6),:]),alpha=0.15, interpolation='nearest', cmap=cmap, norm = norm)
        axarr[1,2].imshow(np.rot90(labelCSF[:,int(labelCSF.shape[-2]*0.6),:]),alpha=0.15, interpolation='nearest', cmap=cmap, norm = norm)
        axarr[1,2].imshow(np.rot90(labelPS[:,int(labelPS.shape[-2]*0.6),:]),alpha=0.5, interpolation='nearest', cmap=cmap, norm = norm)
        axarr[1,2].axis("off")

        axarr[2,0].imshow(np.rot90(img[int(img.shape[0]*0.4),:,:]),cmap="gray")
        axarr[2,0].imshow(np.rot90(labelWM[int(labelWM.shape[0]*0.4),:,:]),alpha=0.15, interpolation='nearest', cmap=cmap, norm = norm)
        axarr[2,0].imshow(np.rot90(labelCSF[int(labelCSF.shape[0]*0.4),:,:]),alpha=0.15, interpolation='nearest', cmap=cmap, norm = norm)
        axarr[2,0].imshow(np.rot90(labelPS[int(labelPS.shape[0]*0.4),:,:]),alpha=0.5, interpolation='nearest', cmap=cmap, norm = norm)
        axarr[2,0].axis("off")

        axarr[2,1].imshow(np.rot90(img[int(img.shape[0]*0.5),:,:]),cmap="gray")
        axarr[2,1].imshow(np.rot90(labelWM[int(labelWM.shape[0]*0.5),:,:]),alpha=0.15, interpolation='nearest', cmap=cmap, norm = norm)
        axarr[2,1].imshow(np.rot90(labelCSF[int(labelCSF.shape[0]*0.5),:,:]),alpha=0.15, interpolation='nearest', cmap=cmap, norm = norm)
        axarr[2,1].imshow(np.rot90(labelPS[int(labelPS.shape[0]*0.5),:,:]),alpha=0.5, interpolation='nearest', cmap=cmap, norm = norm)
        axarr[2,1].axis("off")

        axarr[2,2].imshow(np.rot90(img[int(img.shape[0]*0.6),:,:]),cmap="gray")
        axarr[2,2].imshow(np.rot90(labelWM[int(labelWM.shape[0]*0.6),:,:]),alpha=0.15, interpolation='nearest', cmap=cmap, norm = norm)
        axarr[2,2].imshow(np.rot90(labelCSF[int(labelCSF.shape[0]*0.6),:,:]),alpha=0.15, interpolation='nearest', cmap=cmap, norm = norm)
        axarr[2,2].imshow(np.rot90(labelPS[int(labelPS.shape[0]*0.6),:,:]),alpha=0.5, interpolation='nearest', cmap=cmap, norm = norm)
        axarr[2,2].axis("off")

        f.subplots_adjust(wspace=0, hspace=0)
        plt.savefig(self.args.OUT_PATH + "/" + name + ".png", facecolor=f.get_facecolor())

    def showInfo(self, text):
        if self.args.VERBOSE:
            print(text)

PialSurface()
