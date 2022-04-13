#!/usr/bin/env python3
"""
Gaussian Mixture Model, Soft Clustering CSF/GM considering intensity & position.
Made by Jose Cisneros, April 13 2022
"""
import os
import argparse
import numpy as np
from scipy import ndimage
from nibabel import load, save, Nifti1Image
import matplotlib.pyplot as plt
from matplotlib.colors import LogNorm
from sklearn.mixture import GaussianMixture

class GmmClustering():
    N_CLUSTERS = 3
    LABELS = ["CSF", "GM", "SKULL"]

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
        self.mriData = np.where(self.mriData > 0, self.mriData, 0)

        # Add constant skull.
        mriDataBin = np.where(self.mriData > 0, 1 , 0)
        mriDataDil = ndimage.binary_dilation(mriDataBin, iterations=1)
        skullData = np.logical_and(mriDataDil, np.logical_not(mriDataBin))
        skullData = np.where(skullData == 1, np.random.randint(45, 300, skullData.shape), 0)
        self.mriData = self.mriData + skullData
        
        # GM & CSF & Skull = Brain - WM.
        gmCSFSkull = self.mriData * np.logical_not(self.wmData)
        
        # Separate Data: Value [intensity, distanceToWM], Index
        self.showInfo("Calculating distance to white matter.")
        values = []
        indexes = []
        finishFlag = True
        distanceToWM = 1
        while finishFlag:
            print("Processing DistanceToWM "+ str(distanceToWM))
            self.wmData = ndimage.binary_dilation(self.wmData, iterations=1) # 3D06 Kernel
            intersection = np.logical_and(self.wmData, gmCSFSkull)
            gmCSFSkull =  np.logical_and(gmCSFSkull, np.logical_not(intersection)) # Remove Intersection from gmCSFSkull. (gmCSFSkull & !intersection)

            it = np.nditer(intersection, flags=['multi_index'])
            for mask in it:
                intensity = self.mriData[it.multi_index]
                if mask != 0:
                    values.append([intensity, distanceToWM])
                    indexes.append(it.multi_index)
            
            distanceToWM += 1
            finishFlag = gmCSFSkull.max() != 0
            if distanceToWM > 20:
                finishFlag = True
        
        self.showInfo("Data Ready.")

        n = len(values)
        values = np.array(values).reshape(n, 2)
        minIntensity = (values.T[0]).min()
        maxIntensity = (values.T[0]).max()

        # Calculate GMM Clustering
        gmm = GaussianMixture(n_components=GmmClustering.N_CLUSTERS, covariance_type='full').fit(values)
        prob = gmm.predict_proba(values)
        
        # Display predicted scores by the model as a contour plot.
        x = np.linspace(minIntensity - 100, maxIntensity + 100)
        y = np.linspace(-15, 15)
        X, Y = np.meshgrid(x, y)
        XX = np.array([X.ravel(), Y.ravel()]).T
        Z = -gmm.score_samples(XX)
        Z = Z.reshape(X.shape)
        self.plot(X, Y, Z, values)
        
        # Generate Resultant Mask for each cluster.
        self.outputData = [np.zeros(self.mriData.shape, dtype=self.mriData.dtype) for _ in range(GmmClustering.N_CLUSTERS)]
        self.outputMask = [np.zeros(self.mriData.shape, dtype=self.mriData.dtype) for _ in range(GmmClustering.N_CLUSTERS)]
        for i in range(len(values)):
            for j in range(GmmClustering.N_CLUSTERS):
                if prob[i][j] > self.args.THRESHOLD:
                    self.outputData[j][indexes[i]] = values[i][0]
                    self.outputMask[j][indexes[i]] = 1
        
        # Save Max Intensity Mean as CSF
        maxIndex = 0
        max_ = np.mean(self.outputData[0])
        for i in range(GmmClustering.N_CLUSTERS):
            if max_ < np.mean(self.outputData[i]):
                max_ = np.mean(self.outputData[i])
                maxIndex = i

        self.saveNII(self.args.OUT_PATH + "/" + self.args.OUT_CSF, self.outputMask[maxIndex])
        self.saveNII(self.args.OUT_PATH + "/gmm_mri.nii", self.mriData)
        self.saveNII(self.args.OUT_PATH + "/gmm_0.nii", self.outputMask[0])
        self.saveNII(self.args.OUT_PATH + "/gmm_1.nii", self.outputMask[1])
        self.saveNII(self.args.OUT_PATH + "/gmm_2.nii", self.outputMask[2])

    def plot(self, X, Y, Z, data, name="gmm_pos"):
        plt.title("Density Estimation by a GMM")
        CS = plt.contour(
            X, Y, Z, levels=np.logspace(0, 1.5, 30)
        )
        CB = plt.colorbar(CS, shrink=0.8, extend="both")
        plt.scatter(data[:, 0], data[:, 1], 0.8)
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

GmmClustering()
