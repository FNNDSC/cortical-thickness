BASE_PATH=/neuro/labs/grantlab/research/MRI_processing/jose.cisneros/CorticalThickness/Results/FCB028

find ${BASE_PATH} -type f '(' -name "*.txt" '!' -name '*_res.txt' ')' | while read txt; do
  dir=`dirname "$txt"`
  fileNameOld=`basename "$txt"`
  fileName="${fileNameOld%.txt}_res.txt"
  python ${BASE_PATH}/../../code/surfaceExtraction/analyzeTxt.py \
    -inPath "$dir/$fileNameOld" \
    -outPath "$dir/$fileName"
done
