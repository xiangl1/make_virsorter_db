#!/bin/bash

export GB_FILE=$1 
export TEMP_FILE="/Users/Xiang/Dissertation/MMETSP/virsorter_result/final_report/temp"
export TEMP_FILE2="/Users/Xiang/Dissertation/MMETSP/virsorter_result/final_report/temp2"
export WORKER_DIR="/Users/Xiang/Dissertation/MMETSP/virsorter_result"
export HEADER_FILE="/Users/Xiang/Dissertation/MMETSP/virsorter_result/euk_vir_db_header"
export OUT_FILE=$2


egrep "/product" $GB_FILE > $TEMP_FILE 

sed 's/^.*product=//g' $TEMP_FILE | sed 's/"//g' | sed 's/^.*_PFAM/PFAM/'> $TEMP_FILE2

$WORKER_DIR/parse_protein_name.pl $HEADER_FILE $TEMP_FILE2 $OUT_FILE 

rm -rf $TEMP_FILE
rm -rf $TEMP_FILE2
