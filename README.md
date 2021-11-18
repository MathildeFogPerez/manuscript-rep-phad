# manuscript-rep-phad #
Scripts to process 10X BCR data from multiple runs and create a unique AIRR input file.

Copyright (C) 2021  Mathilde Foglierini Perez

email: mathilde.foglierini-perez@chuv.ch

### SUMMARY ###

We have made available here a series of scripts to process paired BCR data (10X genomics) coming from different donors. The 10X samples represent different time points and/or different cell types (B cell memory or plasma cells). The output of the pipeline is a single AIRR (Adaptive Immune Receptor Repertoire) file format containing one clonotype per row (heavy and light chain) and the related metadata (collection date, antigen specificity, donor etc..). 
The AIRR file can be used for AIRR compliant software tools.

The scripts are primarily intended as reference for manuscript "Clonal structure and dynamics of human memory B cells and circulating plasma cells”" rather than a stand-alone application.

The input of the pipeline are cellranger v5.0.0 VDJ output files (filtered_contig.fasta and filtered_contig_annotations.csv files).
10X VDJ data can be found at ArrayExpress accession number E-MTAB-11174 and GenBank accession numbers OL450601-OL451038 for the antigenic specific mAbs.

These scripts were run on Linux machines.


### LICENSES ###

This code is distributed open source under the terms of the Apache License, Version 2.0.


### INSTALL ###

Before the pipeline can be run, the following software are required:

a) Java JDK 12 https://www.oracle.com/java/technologies/javase/jdk12-archive-downloads.html

b) IgBlast v1.16 (see ncbi-igblast-1.16.0 folder with D1 and D2 specific database) or download last version from https://ftp.ncbi.nih.gov/blast/executables/igblast/release/LATEST

c) Change-O https://changeo.readthedocs.io/en/stable/install.html#installation

d) light_cluster.py script https://bitbucket.org/kleinstein/immcantation/src/master/scripts/

e) dnaml from Phylip package https://evolution.genetics.washington.edu/phylip.html

f) igphyml https://igphyml.readthedocs.io/en/latest/install.html (OPTIONAL)


### PIPELINE ###

Once the git directory is cloned, create a directory where you will put a metadata.txt file, the samples names for each 10X run (T1samples.txt, T2samples.txt ..etc.. ) and the airr_header.txt file. You can find all files needed for donor D1 and D2 in their respective D1_files and D2_files folders. Cellranger output files can be extracted from ArrayExpress accession number E-MTAB-11174.
The example_files folder contains one sample from D1 donor, from T7 run with its related cell ranger output files.

All the following command lines can be run in a bash script.  
  
  
1. Set the variables

        SCRIPTSFOLDER="$YOURPATH/manuscript-rep-phad/scripts_folder"
        WORKINGDIR="$YOURPATH/manuscript-rep-phad/example_files"
        #cellranger_out folder should contain AT7ma_VDJ/outs/ folder with filtered_contig.fasta and filtered_contig_annotations.csv files
        CELLRANGEROUTDIR="$YOURPATH/manuscript-rep-phad/example_files/cellranger_out"
        DATE="01_01_22"
        IGBLAST="$YOURPATH/manuscript-rep-phad/ncbi-igblast-1.16.0" 
        DBSPECIES="D1" #can be D1, D2 or human
        DBNAME="D1_db" #can be D1_db or D2_db or imgt_db_human_07_07_20
  
2. Launch change-O 10X pipeline for each run (only T7 run in example_files)

        cd $WORKINGDIR  
        #Launch IgBlast annotation and first steps of Change-O pipeline (make db, filtering, clustering)
        $SCRIPTSFOLDER/launchChangeO10XPipeline_forALLsamples.sh $DATE $WORKINGDIR $DBSPECIES $DBNAME T7 $SCRIPTSFOLDER $IGBLAST $CELLRANGEROUTDIR 
        
3. Launch change-O for the antigen specific mAbs sequences       
        
        $SCRIPTSFOLDER/launchChangeOPipeline_other.sh $WORKINGDIR/agspe AgSpe_sequences.fasta $DBSPECIES $IGBLAST $DBNAME $SCRIPTSFOLDER 1 
        
4. Combine data all together and launch change-O pipeline             

        #clustering, checking with light chain, germline reconstruction and creation of AIRR file and matrices files for the Repseq platform
        #the option 'agspe' is used in the case you have agspe sequences that were Sanger sequenced and that can be paired OR not paired.
        #if you do not have agspe data write 'noagspe'
        $SCRIPTSFOLDER/launchChangeOPipeline.sh $WORKINGDIR $DATE $DBSPECIES $IGBLAST $DBNAME $SCRIPTSFOLDER agspe 

5. Create dnaml phylogenic tress

        mkdir dnaml
        #run dnaml multithreads (n=50)
        java -jar $SCRIPTSFOLDER/LaunchDnamlForAllClones.jar  AIRR_file_"$DBSPECIES"_"$DATE".tsv $WORKINGDIR/dnaml 50 
        #Create one single file with all info + failed dnaml file
        java -jar $SCRIPTSFOLDER/MakeUniqueFileWithDnamlTrees.jar AIRR_file_"$DBSPECIES"_"$DATE".tsv $WORKINGDIR/dnaml
        
5. Create igphyml phylogenic trees (OPTIONAL)

        mkdir igphyml
        #replace 0 by the correct number (see output files created in step 4: AIRR_file_"$DBSPECIES"_"$DATE"_clonalFamForIgPhyML_"$i".txt where $i is the higher number, it can be used in the case of the analysis of multiple runs)
        $SCRIPTSFOLDER/launchIgPhyML.sh $DATE $DBSPECIES 0 0 
        #Merge igphml output files in one in the case of multiple files ($i >0)
        $SCRIPTSFOLDER/launchMergingIgPhyMLFiles.sh $DATE $DBSPECIES 0 0 
        
 The generated AIRR_file_D1_01_01_22.tsv file can be used for AIRR format compliant software tools.

 All the other files/folder automatically generated by the pipeline (similarity matrices, dnaml and igphyml files) were used as input for the RepSeq Platform. D1 and D2 repertoire can be explored (basics statics and phylogenic analysis of clonal families) at the following link:  **RepSeq platform** 
 


