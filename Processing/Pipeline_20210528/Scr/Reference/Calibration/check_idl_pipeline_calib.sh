#!/bin/bash

# First argument: directory where to check out the pipeline
out_dir=$1

# Second argument: revision of the IDL pipeline 
rev=$2

# Third argument: number of the NIKA2 run N2R_
n2r=$3

# go to out_dir and check out the pipeline
current_dir=$PWD
export CHECK_IDL_PIPELINE_DIR=$out_dir
cd $CHECK_IDL_PIPELINE_DIR

if [ ! -d  Pipeline_$rev ]
then
    mkdir Pipeline_$rev
    svn --username archeops checkout https://lpsc-secure.in2p3.fr/svn/NIKA/Processing/Pipeline Pipeline_$rev -r $rev
fi

# get acquisition and calibration files + bascalrun.pro (rev 26107)
nika_pipeline_ori=$NIKA_PIPELINE
nika_preproc_dir_ori=$NIKA_PREPROC_DIR
cp $nika_pipeline_ori/Readdata/IDL_so_files/*so Pipeline_$rev/Readdata/IDL_so_files/.
cp $nika_pipeline_ori/IDLtools/*txt Pipeline_$rev/IDLtools/.
cp $nika_pipeline_ori/Scr/Reference/Calibration/basecalrun.pro Pipeline_$rev/Scr/Reference/Calibration/.

# new IDL pipeline config
config_file=$CHECK_IDL_PIPELINE_DIR/local_config.txt
echo "export NIKA_PIPELINE='$CHECK_IDL_PIPELINE_DIR/Pipeline_"$rev"'" >> $config_file
echo "export NIKA_PREPROC_DIR='$CHECK_IDL_PIPELINE_DIR/Preproc_"$rev"'" >> $config_file
source $config_file

# go back to the previous dir
cd $current_dir
out_dir_calib=${out_dir}/Check_Calibration
if [ ! -d  ${out_dir_calib} ]
then
    mkdir ${out_dir_calib}
fi
idl check_idl_pipeline_calib -args ${out_dir_calib} ${rev} ${n2r}

# restore original NIKA2 env variables
echo "export NIKA_PIPELINE='"$nika_pipeline_ori"'" >> $config_file
echo "export NIKA_PREPROC_DIR='"$nika_preproc_dir_ori"'" >> $config_file
source $config_file
