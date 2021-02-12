# DHS Indicators

### Summary

SQL code for generating certain DHS indicators

README updated 2021-02-12, HSG

### Description

The DHS analysis work in this folder relates to recreating a number of the DHS's own existing "indicators", i.e. specific metrics that the DHS already extract and publish (via their API, StatCompiler, etc) from their data. 

However the DHS only publish these indicators at national and regional levels and this work was to apply those same metrics to generate indicator data at the cluster level. 

This was done to allow continuous predicted surfaces of these indicators to be produced, work which was led by Sam Bhatt and Pete Gething on behalf of DHS, which ultimately led to the published "indicator surfaces" now on the DHS spatial data site: https://spatialdata.dhsprogram.com/modeled-surfaces/. The code here is thus the ultimate source of the data published there.

We were provided approximate code in Stata format for each of the required indicators and the task here was to translate that into SQL code to reproduce the same things. Due to the politics of how this project came about, I had to do this by trial and error rather than DHS doing it / providing this information themselves - even though DHS must by definition already do all of this themselves in the background internally, in order to create the regional / national indicators they publish.

This was a pretty tricky process as it wasn't necessarily the same sets of value mappings for every survey (e.g. what answers counted as an improved water source). There were therefore various iterations to get things right (where "right" was defined by whether the cluster-level results, when summarised nationally, matched the indicator data in the DHS API). 

### Implementation

For each indicator, a template SQL file was developed.  The SQL contains all the logic for selecting and combining variables and responses to create the indicators, which as alluded to above was divined through a process of trial-and-error.

Each of these queries was then run via a simple FME workbench to substitute in survey ids. That workbench also makes a call to the DHS API to extract national-level values for the relevant indicator / survey data pair and compares the result to the one it has generated.

Each SQL file creates identically-named output columns. The FME workbench and subsequent processing are thus very simple.
