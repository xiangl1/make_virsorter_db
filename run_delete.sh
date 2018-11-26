#!/bin/bash

#PBS -N delete
#PBS -W group_list=bhurwitz
#PBS -q standard
#PBS -l select=1:ncpus=4:mem=24gb:pcmem=6gb
#PBS -l walltime=10:00:00
#PBS -l cput=40:00:00
#PBS -l place=pack:shared
#PBS -m bea
#PBS -M xiangl1@email.arizona.edu

rm -rf /rsgrps/bhurwitz/xiang/virsorter_euk/make_virsorter_db/old
