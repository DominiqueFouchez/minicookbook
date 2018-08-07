# get some raw images
ll /sps/lsst/datasets/desc/DC2/Run1.2p-newformat/DC2-R1-2p-WFD-r/0182014-r/lsst_*R22*_S* | awk '{print $9}' > filesToIngest_test.txt
ll /sps/lsst/datasets/desc/DC2/Run1.2p-newformat/DC2-R1-2p-WFD-r/0417009-r/lsst_*R22*_S* | awk '{print $9}' >> filesToIngest_test.txt
ll /sps/lsst/datasets/desc/DC2/Run1.2p-newformat/DC2-R1-2p-WFD-r/0417057-r/lsst_*R22*_S* | awk '{print $9}' >> filesToIngest_test.txt
ll /sps/lsst/datasets/desc/DC2/Run1.2p-newformat/DC2-R1-2p-WFD-r/0452599-r/lsst_*R*_S* | awk '{print $9}' >> filesToIngest_test.txt
