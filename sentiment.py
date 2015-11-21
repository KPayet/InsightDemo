# -*- coding: utf-8 -*-
"""
Created on Sat Nov 21 11:12:14 2015

@author: PAYET KEVIN
"""

import os
import json
import numpy as np
from textblob import TextBlob
import reverse_geocoder as geo

from pyspark import SparkContext

# A simple save function for my RDDs, where I add the overwrite option
def saveAsTextFile(rdd, path, overwrite=False):
    if overwrite:
        os.system("rm -r " + path)
    rdd.saveAsTextFile(path)

sc = SparkContext(appName="SentimentAnalysis")

rawTweets = sc.textFile("./tweets.json", 100)

# first thing to do is extract the information we need from the tweets, i.e. the coordinates and the text
parsedTweets = (rawTweets.map(lambda tweet: json.loads(tweet))
                         .filter(lambda tweet: tweet["text"] != "" and tweet["coordinates"] is not None)  # filter early
                         .map(lambda tweet: (tweet["coordinates"]["coordinates"], tweet["text"])) # project early
                         .map(lambda t: ((t[0][1], t[0][0]), t[1])))    # putting coordinates in usual lat - lon format        

# extract state from coordinates using geopy

state_text = (parsedTweets.map(lambda t: (geo.search(t[0])[0], t[1]))
                          .map(lambda t: ( (t[0]["cc"], t[0]["admin1"]), t[1]) )
                          .filter(lambda t: t[0][0] == "US")
                          .map(lambda t: (t[0][1], t[1]) ) )

# at this point data is like (u'state', u'tweet text') for each tweet
                
# compute sentiment for each tweet and return a list of (state, sentiment) tuples

state_sent = state_text.map(lambda t: (t[0].upper(), TextBlob(t[1]).sentiment.polarity))

# and I simply save one file
#  all the state, sentiment entries, for detailed statistical analysis in R

saveAsTextFile(state_sent.map(lambda t: ",".join(map(str, (t[0], t[1])))) , # turn into nice output to store as csv
               "./sentiments_states.csv", overwrite = True)

