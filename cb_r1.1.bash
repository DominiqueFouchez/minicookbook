ll /sps/lsst/datasets/desc/DC2/Run1.1-test/DC2-phoSim-3_WFD-r/000233/lsst_e*R*_S* | awk '{print $9}' >> filesToIngest_test.txt

mkdir input output
echo lsst.obs.lsstSim.LsstSimMapper > input/_mapper
ingestDriver.py input @filesToIngest_test.txt --config clobber=True --cores 2

cd input
ln -sfn $REFCAT ref_cats
cd ..

processEimage.py input --output output --id visit=182014^417009^417057^452599 -j 8

makeSkyMap.py output --output output/coadd_dir --configfile ../makeSkyMapConfig.py

python ../reportPatchesWithImages.py output/coadd_dir | grep tract > patches.txt
sed -e 's/^/--id filter=r /' patches.txt > patches_r.txt

cat patches_r.txt | awk {'print $3'} |uniq | sed s/=/' '/ | awk {'print $2'} > tract.list

jointcal.py output --output output --id tract=5064 --configfile ../jointcalConfig.py

jointcalCoadd.py output/coadd_dir --output output/coadd_dir --id filter=r tract=5064 --selectId visit=182014^193861^219976 --configfile ../jointcalCoaddConfig.py --clobber-config

cat patches_r.txt | grep 5064 > patches_r_5064.txt

assembleCoadd.py output/coadd_dir --output output/coadd_dir @patches_r_5064.txt --selectId visit=182014^193861^219976 --configfile ../assembleCoaddConfig.py --clobber-config

detectCoaddSources.py output/coadd_dir --output output/coadd_dir @patches_r_5064.txt --configfile ../detectCoaddConfig.py --clobber-version

measureCoaddSources.py output/coadd_dir --output output/coadd_dir @patches_r_5064.txt --configfile ../measureCoaddSourcesConfig.py --clobber-version

imageDifference.py output --output output --id visit=417057 raft=2,2 filter=r tract=5064 patch=0,0 --templateId filter=r tract=5064 patch=0,0 --configfile ../imageDifferenceConfig.py --clobber-config --clobber-versions

