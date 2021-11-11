#!/bin/bash
DATE=$1
DBSPECIES=$2 #can be ALA or human or RBI
END=$3

set -e

#We merge the files together (first we remove the header of all files apart the 0)
for ((i=1;i<=END;i++)); do
	tail -n +3 AIRR_file_"$DBSPECIES"_"$DATE"_"$i"_igphyml-pass.tab > AIRR_file_RBI_"$DATE"_"$i"_igphyml-pass_withoutHeader.tab
done

cat AIRR_file_"$DBSPECIES"_"$DATE"_0_igphyml-pass.tab >  igphyml/AIRR_file_"$DBSPECIES"_"$DATE"_igphyml-pass.tab

for ((i=1;i<=END;i++)); do
	cat AIRR_file_"$DBSPECIES"_"$DATE"_"$i"_igphyml-pass.tab >>  igphyml/AIRR_file_"$DBSPECIES"_"$DATE"_igphyml-pass.tab
done


