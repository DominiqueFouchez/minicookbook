#!/usr/bin/env python
#
import lsst.daf.persistence as dafPersist
import matplotlib.pyplot as plt
import numpy as np

import lsst.afw.table as afwTable
import lsst.afw.geom as afwGeom
import lsst.afw.display.ds9 as ds9
from astropy.time import Time

import re
from astropy.table import Table
import astropy.coordinates as coord
import astropy.units as u


DATADIR="/sps/lsst/data/fouchez/DC2/testCB2/tst3/output"

print(DATADIR)
exit

butler = dafPersist.Butler(DATADI)

visits=butler.queryMetadata('deepDiff_diaSrc', ['visit'], dataId={'filter': 'r'})

print(visits)

print(butler.datasetExists("deepDiff_diaSrc", {"raftName":"R22","detectorName":"S11","filter":'r', "visit":417009}))

rafts = butler.queryMetadata('deepDiff_diaSrc', ['raftName'], dataId={'filter': 'r'})

detectors = butler.queryMetadata('deepDiff_diaSrc', ['detectorName'], dataId={'filter': 'r'})

rafts = ['R22']
detectors=['S02']

multi_matches = None
for visit in visits:
    date_catalog = None
    for raft in rafts:
        for detector in detectors:
            print(raft,detector,visit)        
            print (butler.datasetExists("deepDiff_diaSrc", {"raftName":raft,"detectorName":detector,"filter":'r', "visit":visit}))
            if butler.datasetExists("deepDiff_diaSrc", {"raftName":raft,"detectorName":detector,"filter":'r', "visit":visit}) == True:
                catalog = butler.get("deepDiff_diaSrc",{"raftName":raft,"detectorName":detector,"filter":'r', "visit":visit}) 
                if date_catalog is None: 
                    date_catalog = catalog.copy()
                else:
                    date_catalog.extend(catalog)
    if date_catalog != None :
        if multi_matches is None and len(date_catalog)>0:
            multi_matches = afwTable.MultiMatch(date_catalog[0].schema, {'date':float})
    
        #t = Time(date)
        multi_matches.add(date_catalog, {'date':visit})
                
results = multi_matches.finish(removeAmbiguous=False)


def build_lightcurve(source_list):
    """
    Assemble a light curve data table from available files.
    """

    bandpasses = ['r','i']


    lightcurve = {}
    lightcurve['classification'] = []
    lightcurve['bandpass'] = []
    lightcurve['mjd'] = []
    lightcurve['ra'] = []
    lightcurve['dec'] = []
    lightcurve['flux'] = []
    lightcurve['flux_error'] = []
    lightcurve['zp'] = []
    lightcurve['zpsys'] = []


    for mjd, src in source_list:

        #print 'yep',visit
        lightcurve['classification'].append(src['ip_diffim_ClassificationDipole_value'])
        lightcurve['bandpass'].append(str('sdss' + bandpasses[0]))
        lightcurve['mjd'].append(mjd)
        lightcurve['ra'].append(src['coord_ra'])
        lightcurve['dec'].append(src['coord_dec'])
        lightcurve['flux'].append(src['base_CircularApertureFlux_4_5_flux'])
        lightcurve['flux_error'].append(src['base_CircularApertureFlux_4_5_fluxSigma'])
        lightcurve['zp'].append(25.0)
        lightcurve['zpsys'].append('ab')
    lightcurve = Table(data=lightcurve)
    return lightcurve


light_curves = []
i = 0
current = -1
while i < len(results):
    result = results[i]
    if current == -1 or current != result['object']:
        lc = [(result['date'],result)]
        light_curves.append(lc)
        current = result['object']
    else:
        light_curves[-1].append((result['date'],result))
    i+=1

lcs = []
for light_curve in light_curves:
    lcs.append(build_lightcurve(light_curve))


PI= 3.141592   
for i, lc in enumerate(lcs):
       print(i,"%2.8f"% (lc[0]['ra']/PI*180),"%2.8f"% (lc[0]['dec']/PI*180),' ',lc[0]['flux'],lc[0]['flux_error'])

