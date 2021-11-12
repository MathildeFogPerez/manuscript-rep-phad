#!/bin/bash

FOLDER=$1
DBSPECIES=$2 #can be D1 or D2 or human
SAMPLE=$4
IGBLASTPATH=$5
DBPATH="$IGBLASTPATH/database/$3" # D1_db or D2_db or imgt_db_human_07_07_20
SCRIPTSFOLDER=$6
CELLRANGEROUTFOLDER=$7

set -e

#copy the files from 10X
mkdir -p $FOLDER

#Check here that the path of cell ranger output is CORRECT!
cp $CELLRANGEROUTFOLDER/"$SAMPLE"_VDJ/outs/filtered_contig_annotations.csv $FOLDER
cp $CELLRANGEROUTFOLDER/"$SAMPLE"_VDJ/outs/filtered_contig.fasta $FOLDER

cd $IGBLASTPATH
igblastn -num_threads 50 -germline_db_V $DBPATH/"$DBSPECIES"_ig_V -germline_db_D $DBPATH/"$DBSPECIES"_ig_D  -germline_db_J $DBPATH/"$DBSPECIES"_ig_J -auxiliary_data optional_file/human_gl.aux  -ig_seqtype Ig -organism human  -outfmt '7 std qseq sseq btop'  -query $FOLDER/filtered_contig.fasta  -out $FOLDER/"$SAMPLE"_filtered_contig_igblast.fmt7

dt=`date '+%d/%m/%Y %H:%M:%S'`
echo "IgBlast ended, MakeDb $dt"
cd $FOLDER
MakeDb.py igblast -i "$SAMPLE"_filtered_contig_igblast.fmt7 -s filtered_contig.fasta -r $DBPATH/"$DBSPECIES"_ig_V_imgt_gapped.fasta $DBPATH/"$DBSPECIES"_ig_D_imgt_gapped.fasta $DBPATH/"$DBSPECIES"_ig_J_imgt_gapped.fasta --10x filtered_contig_annotations.csv --extended

#Keep only the productive sequences
ParseDb.py select -d "$SAMPLE"_filtered_contig_igblast_db-pass.tsv -f productive -u T

ParseDb.py select -d "$SAMPLE"_filtered_contig_igblast_db-pass_parse-select.tsv -f locus -u "IGH" --logic all --regex --outname heavy
ParseDb.py select -d "$SAMPLE"_filtered_contig_igblast_db-pass_parse-select.tsv -f locus -u "IG[LK]" --logic all --regex --outname light

#Add the sample name to the cell_id
echo "Add sample name to 10XBarcode (cell_id) in heavy sequences file"
TOADD=$SAMPLE"_"
$SCRIPTSFOLDER/AddSampleToCellBarcode.jar $FOLDER/heavy_parse-select.tsv $TOADD
echo "Add sample name to 10XBarcode (cell_id) in light sequences file"
$SCRIPTSFOLDER/AddSampleToCellBarcode.jar $FOLDER/light_parse-select.tsv $TOADD

#Add the sample name to the sequence_id
sed -e "s/^/$TOADD/" heavy_parse-select_cell_id_modified.tsv | tail -n +2 > "$SAMPLE"_heavy_parse-select.tsv
sed -e "s/^/$TOADD/" light_parse-select_cell_id_modified.tsv | tail -n +2 > "$SAMPLE"_light_parse-select.tsv
