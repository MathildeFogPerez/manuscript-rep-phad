#!/bin/bash

FOLDER=$1
DATE=$2
DBSPECIES=$3
IGBLASTPATH=$4
DBPATH="$IGBLASTPATH/database/$5" #  D1_db or D2_db or imgt_db_human_07_07_20
SCRIPTSFOLDER=$6
WITHAGSPE=$7

set -e

dt=`date '+%d/%m/%Y %H:%M:%S'`
echo "$dt- Merge ENTIRE dataset..."

runs=()
for file in $FOLDER/*samples.txt; do
        filename=$(basename -- "$file")
        echo $filename
        name=${filename//samples.txt/}
        echo $name
        runs+=("$name")
done

if [ -f heavy_parse-select.tsv ]
then
	echo "remove heavy file"
	rm heavy_parse-select.tsv
fi
if [ -f light_parse-select.tsv ]
then
	echo "remove light file"
	rm light_parse-select.tsv
fi

cat airr_header.txt > heavy_parse-select.tsv
cat airr_header.txt > light_parse-select.tsv

for run in "${runs[@]}"
do
	cat all"$run"/all_cleaned_heavy_parse-select_clone-pass_clone_id_modified.tsv | tail -n +2 >> heavy_parse-select.tsv
	cat all"$run"/all_light_parse-select.tsv | tail -n +2 >> light_parse-select.tsv
	
done

if [ "$WITHAGSPE" == "agspe" ]
then
	echo "Add ag spe data!"
	cat agspe/heavy_parse-select_withCellIdAndUmis.tsv | tail -n +2 >> heavy_parse-select.tsv
	cat agspe/light_parse-select_withCellIdAndUmis.tsv | tail -n +2 >> light_parse-select.tsv
fi

heavySequences=$(cat heavy_parse-select.tsv | wc -l )
heavySeq="$((heavySequences-1))"
echo "Number of heavy sequences after concatenation $heavySeq"

#make the clustering for heavy chain
dt=`date '+%d/%m/%Y %H:%M:%S'`
echo "$dt- Heavy chain clustering"
DefineClones.py -d heavy_parse-select.tsv --act set --model ham --norm len --dist 0.15 

dt=`date '+%d/%m/%Y %H:%M:%S'`
echo "$dt- Light chain checking..."
light_cluster.py -d heavy_parse-select_clone-pass.tsv -e light_parse-select.tsv -o cleaned_heavy_parse-select_clone-pass.tsv

newheavySequences=$(cat cleaned_heavy_parse-select_clone-pass.tsv | wc -l )
newheavySeq="$((newheavySequences-1))"
dt=`date '+%d/%m/%Y %H:%M:%S'`
echo "$dt- Number of heavy sequences after checking light chain $newheavySeq"
removed=$(($heavySequences - $newheavySequences))
echo "$dt- **** Number of REMOVED heavy sequences after checking light chain of ALL run $removed ****"

#Add ag spe without light chain that were kicked out with "light_cluster.py" script
java -Xmx12288m -jar $SCRIPTSFOLDER/GetBackAgSpeWithoutLightIntoClusters.jar

#create the germlines
dt=`date '+%d/%m/%Y %H:%M:%S'`
echo "$dt- Create germline heavy chain"
CreateGermlines.py -d cleaned_heavy_parse-select_clone-pass_withAgspeHeavy.tsv --cloned -g dmask -r $DBPATH/"$DBSPECIES"_ig_V_imgt_gapped.fasta $DBPATH/"$DBSPECIES"_ig_D_imgt_gapped.fasta $DBPATH/"$DBSPECIES"_ig_J_imgt_gapped.fasta 

dt=`date '+%d/%m/%Y %H:%M:%S'`
echo "$dt- Create germline light chain"
CreateGermlines.py -d light_parse-select.tsv -g dmask -r $DBPATH/"$DBSPECIES"_ig_V_imgt_gapped.fasta $DBPATH/"$DBSPECIES"_ig_D_imgt_gapped.fasta $DBPATH/"$DBSPECIES"_ig_J_imgt_gapped.fasta 

dt=`date '+%d/%m/%Y %H:%M:%S'`
echo "$dt- Create final AIRR file"
#The makeSequenceIds option will use metadata.txt file and create for each sequence an unique ID like the following: 
#M-MA231-K-H-A0-1102-A-1 -> M = memory, MA231=id (not unique for 10X data), K= kappa, H=related heavy mate, A0= experiment id, 1102=collection date (2011 02), A= donor (D1), 1=duplicate count
#P-22004-G4-K-AT11mh-2102-A-1 > P = plasma, 22004=id (not unique for 10X data), G4= isotype, K=related light mate, AT11mh= experiment id, 2102=collection date (2021 02), A= donor (D1), 1=duplicate count
java -Xmx12288m -jar $SCRIPTSFOLDER/CreateAIRRtsvFile.jar cleaned_heavy_parse-select_clone-pass_withAgspeHeavy_germ-pass.tsv light_parse-select_germ-pass.tsv AIRR_file_"$DBSPECIES"_"$DATE".tsv makeSequenceIds

mkdir -p matrices
dt=`date '+%d/%m/%Y %H:%M:%S'`
echo "$dt- Create matrices for platform"
java -Xmx12288m -jar $SCRIPTSFOLDER/CreateHeavyLightMatricesAIRR.jar AIRR_file_"$DBSPECIES"_"$DATE".tsv matrices/

#Create a file containing the clone_ids that have at least 2 members (used to run IgPhyML) with 4000 clonal families by file (for multithreading) and the biggest family should be <500 sequences 
java -Xmx12288m -jar $SCRIPTSFOLDER/MakeClonalFamListForIgPhyML.jar AIRR_file_"$DBSPECIES"_"$DATE".tsv 4000 500

