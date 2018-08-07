#setup

export DM_RELEASE=w_2018_28
export DM_SETUP="/cvmfs/sw.lsst.eu/linux-x86_64/lsst_distrib/${DM_RELEASE}/loadLSST.bash"
export REFCAT="/sps/lsst/users/nchotard/dc2/test/input/ref_cats"
export CALIB="/sps/lsst/users/lsstprod/desc/DC2-test/newCam/input/CALIB"

source ${DM_SETUP}
setup lsst_distrib
export OMP_NUM_THREADS=1

#need an obs_lsstCam" working with diffim  
export ROOT_SOFTS="/sps/lsst/users/fouchez/pipeline/DC2/Run1.1-testDF/new"
eups declare -r $ROOT_SOFTS/obs_lsstCam obs_lsstCam localver
setup obs_lsstCam localver

# start
cd "myworkdir"


# get some raw images
ll /sps/lsst/datasets/desc/DC2/Run1.2p-newformat/DC2-R1-2p-WFD-r/0182014-r/lsst_*R22*_S* | awk '{print $9}' > filesToIngest_test.txt
ll /sps/lsst/datasets/desc/DC2/Run1.2p-newformat/DC2-R1-2p-WFD-r/0417009-r/lsst_*R22*_S* | awk '{print $9}' >> filesToIngest_test.txt
ll /sps/lsst/datasets/desc/DC2/Run1.2p-newformat/DC2-R1-2p-WFD-r/0417057-r/lsst_*R22*_S* | awk '{print $9}' >> filesToIngest_test.txt
ll /sps/lsst/datasets/desc/DC2/Run1.2p-newformat/DC2-R1-2p-WFD-r/0452599-r/lsst_*R*_S* | awk '{print $9}' >> filesToIngest_test.txt

# start

cd "myworkdir"

mkdir tst1;cd tst1

cp ../filesToIngest_test.txt .

mkdir input output
echo lsst.obs.lsstCam.LsstCamMapper > input/_mapper

ngestDriver.py input @filesToIngest_test.txt --config clobber=True allowError=True register.ignore=True --cores 16

cd input
ln -sfn $REFCAT ref_cats
ln -sfn $CALIB CALIB
cd ..

#map to the sky
makeSkyMap.py input --output output --configfile ../dm_configs/makeSkyMapConfig.py

#driver to run processCcd
singleFrameDriver.py input --output output --id visit=182014^417009^417057^452599 --cores 32 --timeout 999999999 --configfile ../singleFrameDriverConfig_basiccalib.py

#find the tract/patches overlapping visit 182014
./reportPatchesWithImages.py output --visits 182014 --filt r
sed -e 's/^/--id filter=r /' r_182014_patches.list > patches_r.txt

#make coadd on these patches to create template
makeCoaddTempExp.py input --output output @patches_r.txt --selectId filter=r visit=182014^452599 -j 32
assembleCoadd.py output --output output @patches_r.txt --selectId filter=r visit=182014^452599 -j 32 

#make difference of 417057 and 417009 to coadd
imageDifference.py output --output output --id visit=417057 raftName=R22 filter=r tract=5064 patch=0,0 --templateId filter=r tract=5064 patch=0,0 --configfile ../imageDifferenceConfig.py

imageDifference.py output --output output --id visit=417009 raft=2,2 filter=r tract=5064 patch=0,0 --templateId filter=r tract=5064 patch=0,0 --configfile ../imageDifferenceConfig.py

#match the diasources produced (just dump some result, no persistence here, to be implemented as a DMstack task) 
export DATADIR="myworkdir"/tst1/output
mmatch.py

