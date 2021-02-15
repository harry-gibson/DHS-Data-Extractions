# Building quality and childhood malaria infection

### Summary

FME workbenches for extracting information on a) building quality and b) malaria prevalence outcomes in children from the DHS database, creating datasets that  were used in a paper published in PLoS Medicine in 2017.

README updated 2021-02-15, HSG

### Description

This is a two part extraction that was created with the aim of comparing the physical quality of houses with the risk of malaria infection in children. The data were extracted as two tables: the first with one row per household, covering physical aspects of the house building, and the other with one row per child (as listed in the household schedule), covering the results of malaria tests as well as haemoglobin levels and usage of ITN bednets. 

### Usage history

The datasets extracted using the code in this folder led to a paper comparing building quality to malaria infection outcomes in children:

[Housing Improvements and Malaria Risk in Sub-Saharan Africa: A Multi-Country Analysis of Survey Data](https://doi.org/10.1371/journal.pmed.1002234); Tusting et al., *PLoS Medicine*, 2017

The extractions were initially run in early 2016. 

### Implementation

These extractions were developed as FME workbenches. The workbenches read the necessary data table-by-table from the database using FME readers and information from different tables is joined within the workflow using FME joiners (and not by directly writing SQL to perform SELECT and JOIN operations). Mapping of coded values into value descriptions is also done within the workflow using the FME SchemaMapper. 

