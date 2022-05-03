#!/usr/bin/env python3
"""
Fuzzy Spatial C Means, Soft Clustering.
Made by Jose Cisneros, April 19 2022
"""
import os
import argparse
import numpy as np
import matplotlib.pyplot as plt
from matplotlib import colors

class sFCM():
    def __init__(self, n_clusters, min_error = 1e-5, max_iter = 500, verbose = True, kernel = "06"):
        self.n_clusters = n_clusters
        self.min_error = min_error
        self.max_iter = max_iter
        self.verbose = verbose
        self.kernel = kernel
        self.trained = False
        self.m = 2
        self.p = 1
        self.q = 2
    
    """ Soft predict of sFCM """
    def soft_predict(self, X, _1DTo3D, _3DTo1D, map3D):
        temp = sFCM._dist(X, self._v) ** (2 / (self.m - 1))
        denominator_ = temp.reshape((X.shape[0], 1, -1)).repeat(
            temp.shape[-1], axis=1
        )
        denominator_ = temp[:, :, np.newaxis] / denominator_
        self.u = 1 / denominator_.sum(2)

        Fik = np.ones(shape=(self.n_samples, self.n_clusters))
        avgX = X.copy()
        for i in range(self.n_clusters):
            for k in range(self.n_samples):
                if self.kernel = "06":
                    Fik[k][i], avgX[k] = self.Fik_06(i, k, X, _1DTo3D, _3DTo1D, map3D)
                else:
                    Fik[k][i], avgX[k] = self.Fik_26(i, k, X, _1DTo3D, _3DTo1D, map3D)

        temp = sFCM._dist(avgX, self._v) ** (2 / (self.m - 1))
        denominator_ = temp.reshape((avgX.shape[0], 1, -1)).repeat(
            temp.shape[-1], axis=1
        )
        denominator_ = temp[:, :, np.newaxis] / denominator_
        denominator_ = 1 / denominator_.sum(2)
        numerator_ = (Fik ** (1 / (self.m - 1)))
        self.u_ = (numerator_ + denominator_) / 2

        return sFCM._z(self.u, self.u_, self.p, self.q, self.n_clusters)

    def init_prob(self):
        rng = np.random.default_rng()
        tmp = rng.uniform(size=(self.n_samples, self.n_clusters))
        return tmp / np.tile(
            tmp.sum(axis=1)[np.newaxis].T, self.n_clusters
        )

    """ Train the fuzzy-c-means model """
    def fit(self, X, _1DTo3D, _3DTo1D, map3D):
        self.n_samples = X.shape[0]
        self.u = self.init_prob()
        self.u_ = self.init_prob()
        self.z = sFCM._z(self.u, self.u_, self.p, self.q, self.n_clusters)
        for i in range(self.max_iter):
            z_old = self.z.copy()
            self._v = sFCM._v(X, self.u, self.m)
            self._w = sFCM._w(X, self.z, self.m)
            self.z = self.soft_predict(X, _1DTo3D, _3DTo1D, map3D)
            # Stopping rule
            if np.linalg.norm(self.z - z_old) < self.min_error:
                break
            self.showInfo("Iteration " + str(i) + " - " + str(np.linalg.norm(self.z - z_old)))
        self.trained = True

    def predict(self, X, _1DTo3D, _3DTo1D, map3D):
        """ Predict the closest cluster each sample in X belongs to. """
        if self._is_trained():
            X = np.expand_dims(X, axis=0) if len(X.shape) == 1 else X
            return self.soft_predict(X, indexes, map3D).argmax(axis=-1)

    def Fik_26(self, i, k, X, _1DTo3D, _3DTo1D, map3D):
        """ Probabilistic Function for a voxel k that belong to the ith cluster. """
        """ Using 3D26 Kernel """
        M = 26
        count = 0
        sumX = 0
        index3D = _1DTo3D[k]
        for x in range(-1, 2):
            for y in range(-1, 2):
                for z in range(-1, 2):
                    if x == y == z == 0:
                        continue
                    neighbor = (index3D[0] + x, index3D[1] + y, index3D[2] + z)
                    if neighbor in map3D and map3D[neighbor] != 0:
                        index1D = _3DTo1D[neighbor]
                        sumX += X[index1D]
                        if self.u[index1D][i] >= 0.5:
                            count+=1
                    else:
                        M -= 1
        if M == 0:
            M = 1
        return count / M, sumX / M
    
    def Fik_06(self, i, k, X, _1DTo3D, _3DTo1D, map3D):
        """ Probabilistic Function for a voxel k that belong to the ith cluster. """
        """ Using 3D06 Kernel """
        M = 6
        count = 0
        sumX = 0
        index3D = _1DTo3D[k]
        def checkIndex(neighbor, map3D):
            sh=map3D.shape
            if neighbor[0] < 0 or sh[0] < neighbor[0]:
                return False
            if neighbor[1] < 0 or sh[1] < neighbor[1]:
                return False
            if neighbor[2] < 0 or sh[2] < neighbor[2]:
                return False
            return True

        for idx in range(0, 3):
            for val in [-1, 1]:
                x = val if (idx == 0) else 0
                y = val if (idx == 1) else 0
                z = val if (idx == 2) else 0
                neighbor = (index3D[0] + x, index3D[1] + y, index3D[2] + z)
                if checkIndex(neighbor, map3D) and map3D[neighbor] != 0:
                    index1D = _3DTo1D[neighbor]
                    sumX += X[index1D]
                    if self.u[index1D][i] >= 0.5:
                        count+=1
                else:
                    M -= 1
        if M == 0:
            M = 1
        return count / M, sumX / M

    @staticmethod
    def _dist(A, B):
        """Compute the euclidean distance two matrices"""
        return np.sqrt(np.einsum("ijk->ij", (A[:, None, :] - B) ** 2))

    @staticmethod
    def _v(X, u, m):
        """Unweighted cluster centers v"""
        um = u**m
        return (X.T @ um / np.sum(um, axis=0)).T
    
    @staticmethod
    def _z(u, u_, p, q, n_clusters):
        """Weighted Joint Membership function z"""
        up = u**p
        u_q = u_**q
        return ( (up * u_q) / np.tile(
            np.sum(up * u_q, axis=1)[np.newaxis].T, n_clusters
        ))

    @staticmethod
    def _w(X, z, m):
        """Weighted cluster centers w"""
        zm = z**m
        return (X.T @ zm / np.sum(zm, axis=0)).T

    def showInfo(self, text):
        if self.verbose:
            print(text)
