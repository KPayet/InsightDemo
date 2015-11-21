# -*- coding: utf-8 -*-
"""
Created on Sat Nov 21 14:59:27 2015

@author: PAYET KEVIN
"""

import sys
import fiona
import shapely.geometry as sg
from shapely.ops import transform
import json
from matplotlib.path import Path
import pyproj
from functools import partial

def GetState(lon, lat, States):

    #origine = sg.Point(lon, lat)
    wgs84 = pyproj.Proj("+init=EPSG:4326")
    origine = wgs84(lon, lat)
    for key in States:
        if States[key].contains_point(origine):
            return key

def ProjectPath(param):

    wgs84 = pyproj.Proj("+init=EPSG:4326")

    new_param = []

    for point in param:
        old_x = point[0]
        old_y = point[1]
        new_param.append(wgs84(old_x, old_y))

    return new_param

def computeGeoDict(shapefile=None):
    
    if shapefile is None:
        exit
    
    fc = fiona.open("USA_adm/USA_adm1.shp")

    States = {}
    
    for record in fc:
        name = record["properties"]["VARNAME_1"]
        #poly = sg.asShape(record['geometry'])
        if len(record['geometry']["coordinates"][0]) > 1:
            path_proj = ProjectPath(record['geometry']["coordinates"][0])
            poly = Path(path_proj)
        else:
            path_proj = ProjectPath(record['geometry']["coordinates"][0][0])
            poly = Path(path_proj)
        States[name] = poly
    
    return States