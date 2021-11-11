#!/bin/bash
DATE=$1
DBSPECIES=$2 #can be D1 or D2 or human
START=$3
END=$4

set -e
dt=`date '+%d/%m/%Y %H:%M:%S'`
echo "STARTING IGPHYML PIPELINE $dt"

#run igphyml, remove option --clean all because it crashes 
for ((i=START;i<=END;i++)); do
	echo "Run IgPhyML for index $i"
	if [ ! -f AIRR_file_"$DBSPECIES"_"$DATE"_"$i"_igphyml-pass_hlp_asr.fasta ]; then
		BuildTrees.py -d AIRR_file_"$DBSPECIES"_"$DATE".tsv --clones $(cat AIRR_file_"$DBSPECIES"_"$DATE"_clonalFamForIgPhyML_"$i".txt) --igphyml --asr 0.1 --nproc 50 --outname AIRR_file_"$DBSPECIES"_"$DATE"_"$i" --fail
		rm -r -f AIRR_file_"$DBSPECIES"_"$DATE"_"$i"/
	fi
done



dt=`date '+%d/%m/%Y %H:%M:%S'`
echo "END OF IGPHYML PIPELINE $dt"
