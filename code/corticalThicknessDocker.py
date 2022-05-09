#!/usr/bin/env python3
"""
Script useful to parse cmd line args for Cortical Thickness pipeline using Docker Image.
Made by Jose Cisneros, May 9 2022
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
        return "True" if var else "False"
    return '"' + var + '"'

class CorticalThickness():
    def __init__(self):
        self.args = None
        self.argumentParser()
        self.run()
    
    def run(self):
        # Create Container
        bashCommand = self.args.BASE_PATH + "/deploy/runBash.sh"
        process = subprocess.run([bashCommand], stderr=sys.stderr, stdout=sys.stdout, shell=True)
        # Copy Input Files
        bashCommand = "docker cp " + self.args.IN_MRI +  " cortical-thickness-test:/tmp/in_mri.nii && " \
                    + "docker cp " + self.args.IN_MRI_SEG +  " cortical-thickness-test:/tmp/in_mri_seg.nii"
        process = subprocess.run([bashCommand], stderr=sys.stderr, stdout=sys.stdout, shell=True)
        # Run Script
        bashCommand = "docker exec cortical-thickness-test python3 /corticalThickness/code/corticalThickness.py " \
                    + "-ca " + parseArg(self.args.CASE) + " " \
                    + "-bp  /corticalThickness " \
                    + "-im  /tmp/in_mri.nii " \
                    + "-is  /tmp/in_mri_seg.nii " \
                    + "-se " + parseArg(self.args.ENABLE_SURFACE_EXTRACTION) + " " \
                    + "-ir " + parseArg(self.args.ENABLE_INTENSITY_REFINEMENT) + " " \
                    + "-do False " \
                    + "-icm " + parseArg(self.args.INTENSITY_CLUSTERING_METHOD)
        process = subprocess.run([bashCommand], stderr=sys.stderr, stdout=sys.stdout, shell=True)
        bashCommand = "mkdir -p " + self.args.OUTPUT
        process = subprocess.run([bashCommand], stderr=sys.stderr, stdout=sys.stdout, shell=True)
        bashCommand = "docker cp cortical-thickness-test:/corticalThickness/Results/" + self.args.CASE + " " + self.args.OUTPUT
        process = subprocess.run([bashCommand], stderr=sys.stderr, stdout=sys.stdout, shell=True)
        bashCommand = "docker container stop cortical-thickness-test"
        process = subprocess.run([bashCommand], stderr=sys.stderr, stdout=sys.stdout, shell=True)
        bashCommand = "docker container rm cortical-thickness-test"
        process = subprocess.run([bashCommand], stderr=sys.stderr, stdout=sys.stdout, shell=True)

    def argumentParser(self):
        parser = argparse.ArgumentParser("   ==========   Cortical Thickness Pipeline using Docker by Jose Cisneros (May 9, 2022 ver.1)   ==========   \n\n")
        parser.add_argument("-ca", "--case", action="store", dest="CASE", type=str, required=True, help="Subject id")
        parser.add_argument("-bp", "--base-path",action="store",dest="BASE_PATH",type=str, default="/neuro/labs/grantlab/research/MRI_processing/jose.cisneros/CorticalThickness", help="Path containing code & resources.")
        parser.add_argument("-im", "--input-mri",action="store",dest="IN_MRI",type=str, required=True, default="", help="Input MRI .nii file with path.")
        parser.add_argument("-is", "--input-segmented",action="store",dest="IN_MRI_SEG",type=str, required=True, default="", help="Input MRI segmented .nii file with path.")
        parser.add_argument("-o", "--output-folder",action="store",dest="OUTPUT",type=str, required=True, default="", help="Output folder containing all generated files.")
        parser.add_argument("-se", "--surface-extraction",action="store",dest="ENABLE_SURFACE_EXTRACTION",type=boolean_string, default=True, help="Enable Surface Extraction")
        parser.add_argument("-ir", "--intensity-refinement",action="store",dest="ENABLE_INTENSITY_REFINEMENT",type=boolean_string, default=True, help="Enable Intensity Clustering for CP external boundary refinement.")
        parser.add_argument("-icm", "--intensity-clustering-method",action="store",dest="INTENSITY_CLUSTERING_METHOD",type=str, default="sFCM", help="Soft Clustering Method use for Intensity Refinement. Options: GMM, FCM, sFCM")
        self.args = parser.parse_args()

CorticalThickness()
