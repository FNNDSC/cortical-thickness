#!/usr/bin/env python3
"""
Script useful to parse cmd line args for Cortical Thickness pipeline.
Made by Jose Cisneros, May 5 2022
"""
import os
import sys
import argparse
import subprocess

def boolean_string(s):
    if s not in {'False', 'True', 'false', 'true'}:
        return False
    return s == 'True' or s == 'true'

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
                    + parseArg(self.args.IN_DIR) + " " \
                    + parseArg(self.args.OUT_DIR) + " " \
                    + parseArg(self.args.ENABLE_SURFACE_EXTRACTION) + " " \
                    + parseArg(self.args.ENABLE_INTENSITY_REFINEMENT) + " " \
                    + parseArg(self.args.INTENSITY_CLUSTERING_METHOD) + " " \
                    + parseArg(self.args.OUTSIDE_DOCKER) + " " \
                    + parseArg(self.args.RESULTS_PREFIX) + "\'"
        process = subprocess.call([bashCommand], stderr=sys.stderr, stdout=sys.stdout, shell=True)

    def argumentParser(self):
        parser = argparse.ArgumentParser("   ==========   Cortical Thickness Pipeline by Jose Cisneros (May 5, 2022 ver.1)   ==========   \n\n")
        parser.add_argument("-ca", "--case", action="store", dest="CASE", type=str, required=True, help="Subject id")
        parser.add_argument("-bp", "--base-path",action="store",dest="BASE_PATH",type=str, default="/neuro/labs/grantlab/research/MRI_processing/jose.cisneros/CorticalThickness", help="Path containing code & resources.")
        parser.add_argument("-id", "--input-dir",action="store",dest="IN_DIR",type=str, default="", help="Input Folder including recon_to31_nuc.nii & segmentation_to31_final.nii files.")
        parser.add_argument("-od", "--output-dir",action="store",dest="OUT_DIR",type=str, default="", help="Output path for the Results folder.")
        parser.add_argument("-se", "--surface-extraction",action="store",dest="ENABLE_SURFACE_EXTRACTION",type=boolean_string, default=True, help="Enable Surface Extraction (default: %(default)s)")
        parser.add_argument("-ir", "--intensity-refinement",action="store",dest="ENABLE_INTENSITY_REFINEMENT",type=boolean_string, default=True, help="Enable Intensity Clustering for CP external boundary refinement. (default: %(default)s)")
        parser.add_argument("-do", "--outside-docker",action="store",dest="OUTSIDE_DOCKER",type=boolean_string, default=True, help="Flag indicating if script running outside docker. (default: %(default)s)")
        parser.add_argument("-rp", "--results-prefix",action="store",dest="RESULTS_PREFIX",type=str, default="", help="Prefix for Results folder. (default: %(default)s)")
        parser.add_argument("-icm", "--intensity-clustering-method",action="store",dest="INTENSITY_CLUSTERING_METHOD",type=str, default="sFCM", help="Soft Clustering Method use for Intensity Refinement. Options: GMM, FCM, sFCM (default: %(default)s)")
        self.args = parser.parse_args()

CorticalThickness()
