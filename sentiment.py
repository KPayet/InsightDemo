# -*- coding: utf-8 -*-
"""
Created on Sat Nov 21 11:12:14 2015

@author: PAYET KEVIN
"""

import os
import json
import numpy as np
from textblob import TextBlob
from geopy.geocoders import GoogleV3


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
                         .map(lambda tweet: (tweet["coordinates"]["coordinates"], tweet["text"])))          # project early

# extract state from coordinates using geopy
geolocator = GoogleV3()
state_text = (parsedTweets.filter(lambda t: geolocator.reverse(str(t[0][1])+", "+str(t[0][0])) == "us"))

state_text = (parsedTweets.map(lambda t: (t[0].split(","), t[1]) )
                .filter(lambda t: len(t[0]) > 1) # loses only 0.6% of data
                .map(lambda t: (t[0][1][1:], t[1]))
                .filter(lambda t: t[0] != "" and t[0] != "USA"))
# at this point data is like (u'state', u'tweet text') for each tweet
                
# compute sentiment for each tweet and return a list of (state, sentiment) tuples

state_sent = state_text.map(lambda t: (t[0].upper(), TextBlob(t[1]).sentiment.polarity))

# and I simply save two files
# First all the state, sentiment entries, for detailed statistical analysis

saveAsTextFile(state_sent.map(lambda t: ",".join(map(str, (t[0], t[1])))) , # turn into nice output to store as csv
               "./sentiments_states.csv", overwrite = True)

# and now produce an aggregated version with only average sentiment for each state


state_avgSent = (state_sent.groupByKey()
                           .map(lambda t: (t[0], np.mean(list(t[1])))))