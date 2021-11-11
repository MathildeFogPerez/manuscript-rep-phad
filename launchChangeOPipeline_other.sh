#!/bin/bash

FOLDER=$1
FASTAFILE=$2
DBSPECIES=$3
IGBLASTPATH=$4
DBPATH="$IGBLASTPATH/database/$5" #  D1_db or D2_db or imgt_db_human_07_07_20
SCRIPTSFOLDER=$6
INDEX=$7

set -e

dt=`date '+%d/%m/%Y %H:%M:%S'`
echo "$dt- Launch IgBlast other dataset..."
cd $IGBLASTPATH
igblastn -num_threads 50 -germline_db_V $DBPATH/"$DBSPECIES"_ig_V -germline_db_D $DBPATH/"$DBSPECIES"_ig_D  -germline_db_J $DBPATH/"$DBSPECIES"_ig_J -auxiliary_data optional_file/human_gl.aux  -ig_seqtype Ig -organism human  -outfmt '7 std qseq sseq btop'  -query $FOLDER/$FASTAFILE  -out $FOLDER/heavy_and_light_seq_igblast.fmt7

dt=`date '+%d/%m/%Y %H:%M:%S'`
echo "$dt- MakeDb"
cd $FOLDER
MakeDb.py igblast -i heavy_and_light_seq_igblast.fmt7 -s $FASTAFILE -r $DBPATH/"$DBSPECIES"_ig_V_imgt_gapped.fasta $DBPATH/"$DBSPECIES"_ig_D_imgt_gapped.fasta $DBPATH/"$DBSPECIES"_ig_J_imgt_gapped.fasta --extended

ParseDb.py select -d heavy_and_light_seq_igblast_db-pass.tsv -f productive -u T

ParseDb.py select -d heavy_and_light_seq_igblast_db-pass_parse-select.tsv -f locus -u "IGH" --logic all --regex --outname heavy
ParseDb.py select -d heavy_and_light_seq_igblast_db-pass_parse-select.tsv -f locus -u "IG[LK]" --logic all --regex --outname light

dt=`date '+%d/%m/%Y %H:%M:%S'`
echo "$dt- End ParseDb"

heavySequences=$(cat heavy_parse-select.tsv | wc -l )
echo "Number of other dataset heavy sequences $heavySequences"

lightSequences=$(cat light_parse-select.tsv  | wc -l)
echo "Number of otherdataset light sequences $lightSequences"

#add cell_id and umi_count
java -jar $SCRIPTSFOLDER/AddCellBarcodeAndUmi.jar heavy_parse-select.tsv light_parse-select.tsv $INDEX


