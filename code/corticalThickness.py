#!/usr/bin/env python3
"""
Script useful to parse cmd line args for Cortical Thickness pipeline.
Made by Jose Cisneros, May 5 2022
"""
import os
import sys
import argparse
import subprocess

def parseArg(var):
    if type(var) == bool:
        return "true" if var else "false"
    return '"' + var + '"'

class CorticalThickness():
    def __init__(self):
        self.args = None
        self.argumentParser()
        self.run()
    
    def run(self):
        bashCommand = "bash -c \'source " + self.args.BASE_PATH + "/code/SKELETON-pipeline-0.1.bash " \
                    + parseArg(self.args.CASE) + " " \
                    + parseArg(self.args.BASE_PATH) + " " \
                    + parseArg(self.args.IN_MRI) + " " \
                    + parseArg(self.args.IN_MRI_SEG) + " " \
                    + parseArg(self.args.ENABLE_SURFACE_EXTRACTION) + " " \
                    + parseArg(self.args.ENABLE_INTENSITY_REFINEMENT) + " " \
                    + parseArg(self.args.INTENSITY_CLUSTERING_METHOD) + "\'"
        process = subprocess.call([bashCommand], stderr=sys.stderr, stdout=sys.stdout, shell=True)

    def argumentParser(self):
        parser = argparse.ArgumentParser("   ==========   Cortical Thickness Pipeline by Jose Cisneros (May 5, 2022 ver.1)   ==========   \n\n")
        parser.add_argument("-c", "--case", action="store", dest="CASE", type=str, required=True, help="Subject id")
        parser.add_argument("-p", "--base-path",action="store",dest="BASE_PATH",type=str, default="/neuro/labs/grantlab/research/MRI_processing/jose.cisneros/CorticalThickness", help="Path containing code & resources.")
        parser.add_argument("-im", "--input-mri",action="store",dest="IN_MRI",type=str, default="", help="Input MRI .nii file path.")
        parser.add_argument("-is", "--input-segmented",action="store",dest="IN_MRI_SEG",type=str, default="", help="Input MRI segmented .nii file path.")
        parser.add_argument("-se", "--surface-extraction",action="store",dest="ENABLE_SURFACE_EXTRACTION",type=bool, default=True, help="Enable Surface Extraction")
        parser.add_argument("-ir", "--intensity-refinement",action="store",dest="ENABLE_INTENSITY_REFINEMENT",type=bool, default=True, help="Enable Intensity Clustering for CP external boundary refinement.")
        parser.add_argument("-icm", "--intensity-clustering-method",action="store",dest="INTENSITY_CLUSTERING_METHOD",type=str, default="sFCM", help="Soft Clustering Method use for Intensity Refinement. Options: GMM, FCM, sFCM")
        self.args = parser.parse_args()

CorticalThickness()
