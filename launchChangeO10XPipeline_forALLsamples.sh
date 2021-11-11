#!/bin/bash
DATE=$1
FOLDER=$2
DBSPECIES=$3 #can be D1 or D2 or human
IGBLASTPATH=$7
DBNAME=$4 #  D1_db or D2_db or imgt_db_human_07_07_20
DBPATH="$IGBLASTPATH/database/$4"
RUNFILE=$5"samples.txt"
SCRIPTSFOLDER=$6
CELLRANGEROUTFOLDER=$7

set -e

dt=`date '+%d/%m/%Y %H:%M:%S'`
echo "STARTING PIPELINE $dt"

#Do some checking with the needed files
if [ ! -f airr_header.txt ]
then
	echo "Missing airr_header.txt file!"
	exit
fi

if [ ! -f metadata.txt ]
then
	echo "Missing metadata.txt file!"
	exit
fi

if [ ! -f $RUNFILE ]
then
	echo "Missing $RUNFILE file!"
	exit
fi

while IFS= read -r donor
do
	$SCRIPTSFOLDER/launchChangeO10XPipeline.sh $FOLDER/$donor $DBSPECIES $DBNAME $donor $IGBLASTPATH $SCRIPTSFOLDER $CELLRANGEROUTFOLDER
done < $RUNFILE

mkdir -p all$5
cp metadata.txt all$5

#If the files exist delete them
if [ -f all$5/all_heavy_parse-select.tsv ]
then
	echo "remove heavy file"
	rm all$5/all_heavy_parse-select.tsv
fi
if [ -f all$5/all_light_parse-select.tsv ]
then
	echo "remove light file"
	rm all$5/all_light_parse-select.tsv
fi

#concatenate the files
cat airr_header.txt > all$5/all_heavy_parse-select.tsv
cat airr_header.txt > all$5/all_light_parse-select.tsv
while IFS= read -r donor
do
	cat $donor/"$donor"_heavy_parse-select.tsv >>  all$5/all_heavy_parse-select.tsv
	cat $donor/"$donor"_light_parse-select.tsv >>  all$5/all_light_parse-select.tsv
done < $RUNFILE

cd all$5

heavySequences=$(cat all_heavy_parse-select.tsv | wc -l )
echo "Number of heavy sequences after concatenation $heavySequences"

lightSequences=$(cat all_light_parse-select.tsv  | wc -l)
echo "Number of light sequences after concatenation $lightSequences"

echo "Heavy chain clustering..."
DefineClones.py -d all_heavy_parse-select.tsv --act set --model ham --norm len --dist 0.15 

dt=`date '+%d/%m/%Y %H:%M:%S'`
echo "$dt- Light chain checking..."
light_cluster.py -d all_heavy_parse-select_clone-pass.tsv -e all_light_parse-select.tsv -o all_cleaned_heavy_parse-select_clone-pass.tsv

newheavySequences=$(cat all_cleaned_heavy_parse-select_clone-pass.tsv | wc -l )
dt=`date '+%d/%m/%Y %H:%M:%S'`
echo "$dt- Number of heavy sequences after checking light chain $newheavySequences"
removed=$(($heavySequences - $newheavySequences))
echo "$dt- **** Number of REMOVED heavy sequences after checking light chain $removed ****"

#Remove clone_id column to be able to rerun clustering  Before was $5 in args[1]
echo "Remove clone_id column from heavy sequences file"
$SCRIPTSFOLDER/RemoveCloneidColumn.jar $FOLDER/all$5/all_cleaned_heavy_parse-select_clone-pass.tsv

dt=`date '+%d/%m/%Y %H:%M:%S'`
echo "END OF PIPELINE $dt"
