#!/usr/bin/env python3
"""
Fuzzy C Means, Soft Clustering.
Made by Jose Cisneros, May 2 2022
"""
import os
import argparse
import numpy as np
import matplotlib.pyplot as plt
from matplotlib import colors

class FCM():
    def __init__(self, n_clusters, min_error = 1e-5, max_iter = 500, verbose = True):
        self.n_clusters = n_clusters
        self.min_error = min_error
        self.max_iter = max_iter
        self.verbose = verbose
        self.trained = False
        self.m = 2

    """ Soft predict of FCM """
    def soft_predict(self, X):
        temp = FCM._dist(X, self._centers) ** (2 / (self.m - 1))
        denominator_ = temp.reshape((X.shape[0], 1, -1)).repeat(
            temp.shape[-1], axis=1
        )
        denominator_ = temp[:, :, np.newaxis] / denominator_
        return 1 / denominator_.sum(2)

    """ Train the fuzzy-c-means model """
    def fit(self, X):
        self.rng = np.random.default_rng()
        n_samples = X.shape[0]
        self.u = self.rng.uniform(size=(n_samples, self.n_clusters))
        self.u = self.u / np.tile(
            self.u.sum(axis=1)[np.newaxis].T, self.n_clusters
        )
        for i in range(self.max_iter):
            u_old = self.u.copy()
            self._centers = FCM._next_centers(X, self.u, self.m)
            self.u = self.soft_predict(X)
            # Stopping rule
            if np.linalg.norm(self.u - u_old) < self.min_error:
                break
            self.showInfo("Iteration " + str(i) + " - " + str(np.linalg.norm(self.u - u_old)))
        self.trained = True

    def predict(self, X):
        """ Predict the closest cluster each sample in X belongs to. """
        if self._is_trained():
            X = np.expand_dims(X, axis=0) if len(X.shape) == 1 else X
            return self.soft_predict(X).argmax(axis=-1)

    @staticmethod
    def _dist(A, B):
        """Compute the euclidean distance two matrices"""
        return np.sqrt(np.einsum("ijk->ij", (A[:, None, :] - B) ** 2))

    @staticmethod
    def _next_centers(X, u, m: float):
        """Update cluster centers"""
        um = u**m
        return (X.T @ um / np.sum(um, axis=0)).T

    def showInfo(self, text):
        if self.verbose:
            print(text)