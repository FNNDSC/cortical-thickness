#!/usr/bin/env python3
"""
Script useful to analyze data in a txt file.
Made by Jose Cisneros, May 13 2022
"""
import os
import argparse
import numpy as np

class AnalyzeTxt():
    def __init__(self):
        self.args = None
        self.argumentParser()
        self.run()
    
    def run(self):
        lines = []
        with open(self.args.IN_PATH) as f:
            lines = [float(line.rstrip()) for line in f]
        
        output = "Data size: " + str(len(lines)) + "\n" \
                + "RMS: " + str(np.sqrt(np.mean(np.square(lines)))) + "\n" \
                + "Average: " + str(np.average(lines)) + "\n" \
                + "Std dev: " + str(np.std(lines)) + "\n" \
                + "Min: " + str(np.min(lines)) + "\n" \
                + "Max: " + str(np.max(lines))
        with open(self.args.OUT_PATH, 'w') as f:
            f.write(output)

    def argumentParser(self):
        parser = argparse.ArgumentParser("   ==========   Analyze a list of numbers and save the results by Jose Cisneros (May 13), 2022 ver.1)   ==========   ")
        parser.add_argument("-inPath", "--IN_PATH",action="store",dest="IN_PATH",type=str, default="/neuro/labs/grantlab/research/MRI_processing/jose.cisneros/CorticalThickness/Results/FCB028/morphometrics/native_rms_tlink_10mm_right.txt", help="input txt file with list of numbers")
        parser.add_argument("-outPath", "--OUT_PATH",action="store",dest="OUT_PATH",type=str, default="/neuro/labs/grantlab/research/MRI_processing/jose.cisneros/CorticalThickness/Results/FCB028/morphometrics/native_rms_tlink_10mm_right_res.txt", help="output txt file with the analysis")
        self.args = parser.parse_args()

AnalyzeTxt()
