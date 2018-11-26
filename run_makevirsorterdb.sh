#!/bin/bash

#PBS -N make_db
#PBS -W group_list=bhurwitz
#PBS -q standard
#PBS -l select=1:ncpus=28:mem=168gb:pcmem=6gb
#PBS -l walltime=72:00:00
#PBS -l cput=2016:00:00
#PBS -l place=pack:shared
#PBS -m bea
#PBS -M xiangl1@email.arizona.edu

#--------------------------------------------
# initial directory function
init_dir()
{
    if [ ! -d "$1" ]; then
        mkdir $1
    else
        rm -rf $1
    mkdir $1
        fi
}
#-------------------------------------------- 

module load mafft
module load hmmer
module load blast

export PREFIX_DIR="/rsgrps/bhurwitz/xiang/matou_virus"
export PROJECT_DIR="$PREFIX_DIR/refseq_euk_vir"
export DATA_DIR="$PROJECT_DIR"
export FINAL_DIR="$PROJECT_DIR/final_result"

# temporary directories
export TEMP_DIR="$PROJECT_DIR/temp"
export LIST_DIR="$TEMP_DIR/lists"

# script directories
export SCRIPT_DIR="/rsgrps/bhurwitz/xiang/virsorter_euk/make_virsorter_db/scripts"
export WORKER_DIR="$SCRIPT_DIR/worker"

init_dir $TEMP_DIR
init_dir $FINAL_DIR
init_dir $LIST_DIR

# Step 0: cd-hit to cluster proteins
cd-hit -i $DATA_DIR/refseq_euk_virus.faa -o $PROJECT_DIR/euk_w_mmetsp_vir -c 0.9 -d 0

## Step 1: distribute seqs by cluster. (>= 3 seqs per cluster go to clustered; otherwise go to unclustered)
# Step 1.1: split .clstr by cluster 
export CLUSTER_DIR="$TEMP_DIR/clusters"
export CLSTR_FILE="$PROJECT_DIR/euk_w_mmetsp_vir.clstr"

init_dir $CLUSTER_DIR

$WORKER_DIR/split-cdhit-clstr.pl -i $CLSTR_FILE -o $CLUSTER_DIR/euk_w_mmetsp_vir

# Setp 1.2: make extract seqs parallel list.
export UNCLUSTER_FA_DIR="$TEMP_DIR/unclustered_fa"
export CLUSTER_FA_DIR="$TEMP_DIR/clustered_fa"
export CLUSTER_LIST="$LIST_DIR/cluster_list" 
export SPLIT_FA_PAR_LIST="$LIST_DIR/split_fa_parallel_list"

init_dir $UNCLUSTER_FA_DIR
init_dir $CLUSTER_FA_DIR

ls $CLUSTER_DIR > $CLUSTER_LIST

while read CLUSTER; do
	# count seqs number
	wc -l $CLUSTER_DIR/$CLUSTER > $TEMP_DIR/temp
	read COUNT NAME < $TEMP_DIR/temp
	rm -rf $TEMP_DIR/temp

	if [ $COUNT -ge 3 ]; then
		echo $WORKER_DIR/extract-seq.pl -i $DATA_DIR/euk_w_mmetsp_vir.faa -f $CLUSTER_DIR/$CLUSTER -t extract -o $CLUSTER_FA_DIR/$CLUSTER >> $SPLIT_FA_PAR_LIST
	else
		echo $WORKER_DIR/extract-seq.pl -i $DATA_DIR/euk_w_mmetsp_vir.faa -f $CLUSTER_DIR/$CLUSTER -t extract -o $UNCLUSTER_FA_DIR/$CLUSTER >> $SPLIT_FA_PAR_LIST
	fi

done < "$CLUSTER_LIST"

# step 1.3: run parallel to distribute seqs
parallel -j 20 -k < $SPLIT_FA_PAR_LIST

## step 2: align each cluster seqs by mafft
# step 2.1: merge all unclustered to one file
cat $UNCLUSTER_FA_DIR/* >> $FINAL_DIR/Pool_unclustered.faa

# step 2.2: make mafft parallel list for each cluster with at least 3 seqs 
export MAFFT_IN_LIST="$LIST_DIR/mafft_in_list"
export MAFFT_OUT_DIR="$TEMP_DIR/mafft_out"
export MAFFT_PAR_LIST="$LIST_DIR/mafft_parallel_list"

init_dir $MAFFT_OUT_DIR

ls $CLUSTER_FA_DIR > $MAFFT_IN_LIST
while read MAFFT_IN; do

	MAFFT_OUT=`basename $MAFFT_IN | sed 's/euk_w_mmetsp_vir/euk_w_mmetsp_vir_mafft/'`
	echo mafft --auto $CLUSTER_FA_DIR/$MAFFT_IN '>' $MAFFT_OUT_DIR/$MAFFT_OUT >> $MAFFT_PAR_LIST

done < $MAFFT_IN_LIST

# step 2.3: run parallel mafft
parallel -j 20 -k < $MAFFT_PAR_LIST

# step 3: use hmmbuild to build hmm profile
# step 3.1: make hmmbuild parallel list for each cluster with at least 3 seqs
export HMMBUILD_IN_LIST="$LIST_DIR/hmmbuild_in_list"
export HMMBUILD_OUT_DIR="$TEMP_DIR/hmmbuild_out"
export HMMBUILD_PAR_LIST="$LIST_DIR/hmmbuild_parallel_list"
init_dir $HMMBUILD_OUT_DIR

ls $MAFFT_OUT_DIR > $HMMBUILD_IN_LIST
while read HMMBUILD_IN; do 

	HMMBUILD_OUT=`basename $HMMBUILD_IN | sed 's/euk_w_mmetsp_vir_mafft/euk_w_mmetsp_vir_hmm/'`
	echo hmmbuild --amino $HMMBUILD_OUT_DIR/$HMMBUILD_OUT $MAFFT_OUT_DIR/$HMMBUILD_IN >> $HMMBUILD_PAR_LIST
done < $HMMBUILD_IN_LIST

# step 3.2: run parallel hmmbuild
parallel -j 20 -k < $HMMBUILD_PAR_LIST

# step 3.3: merge hmm profile to one 
cat $HMMBUILD_OUT_DIR/* > $FINAL_DIR/Pool_clusters.hmm

## Step 4: make summary .tab file
# Step 4.1: make new header file from .faa
grep ">" $DATA_DIR/euk_w_mmetsp_vir.faa | sed 's/^>//' > $TEMP_DIR/faa_header

# make clustered tab file
$WORKER_DIR/make_virsorter_clusters_tab.pl -i $CLSTR_FILE -l $TEMP_DIR/faa_header -o $FINAL_DIR/clusters.tab -s 3

# change cluster name
sed -i 's/Cluster/euk_w_mmetsp_vir_cluster/' $FINAL_DIR/clusters.tab

# Step 4.3: make unclustered tab files 
grep ">" $FINAL_DIR/Pool_unclustered.faa | sed 's/^>//' > $TEMP_DIR/uncluster_faa_header
$WORKER_DIR/make_unclustered_tab.pl $TEMP_DIR/uncluster_faa_header $FINAL_DIR/unclustered.tab

# Step 4.4: merge clustered and unclustered tab file
cat $FINAL_DIR/clusters.tab $FINAL_DIR/unclustered.tab >> $FINAL_DIR/Phage_Clusters_current.tab
cp $FINAL_DIR/Pool_unclustered.faa $FINAL_DIR/Pool_new_unclustered.faa

## Step 5: final database dependency
# Step 5.1: hmmpress Pool_clusters.hmm

hmmpress $FINAL_DIR/Pool_clusters.hmm

# Step 5.2: makeblastdb Pool_new_unclustered.faa
makeblastdb -in $FINAL_DIR/Pool_new_unclustered.faa -parse_seqids -dbtype prot -out $FINAL_DIR/Pool_new_unclustered

# Step 6: clean temp directory
