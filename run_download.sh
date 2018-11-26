#!/bin/bash

#PBS -N download
#PBS -W group_list=bhurwitz
#PBS -q standard
#PBS -l select=1:ncpus=4:mem=24gb:pcmem=6gb
#PBS -l walltime=10:00:00
#PBS -l cput=40:00:00
#PBS -l place=pack:shared
#PBS -m bea
#PBS -M xiangl1@email.arizona.edu


wget http://www.genoscope.cns.fr/tara/localdata/data/Geneset-v1/MATOU-v1.fna.gz /rsgrps/bhurwitz/xiang/virsorter_euk/MATOU

wget http://www.genoscope.cns.fr/tara/localdata/data/Geneset-v1/metagenomic_occurrences.tsv.gz /rsgrps/bhurwitz/xiang/virsorter_euk/MATOU

wget http://www.genoscope.cns.fr/tara/localdata/data/Geneset-v1/metatranscriptomic_occurrences.tsv.gz /rsgrps/bhurwitz/xiang/virsorter_euk/MATOU 
