# Standardised Malaria Parasite Rate (PR) DHS data extraction

### Summary

SQL code for extracting data on malaria parasite rate (PR), i.e. malaria test results, from the DHS database, in a particular spreadsheet format used internally at MAP for import to a downstream database.

README updated 2021-02-18, HSG

### Description

This DHS analysis was to retrieve PR data from DHS surveys, following the format in which the data were previously collated manually in order to be loaded to a separate database of PR information from a range of sources. This previous work was done using spreadsheets and pivot tables and copy and pasting based on DHS flat-file datasets. The SQL queries here were written to replicate the exact structure of those earlier extractions so that the same downstream code could be used to import the resulting data to a separate PR database within MAP.

### Usage history

PR data underpin a lot of malaria mapping work within MAP - although DHS surveys are by no means the only source of this type of data. Extractions created using this code contributed at least to the following studies:

[Mapping the global endemicity and clinical burden of Plasmodium vivax, 2000–17: a spatial and temporal modelling study](https://doi.org/10.1016/s0140-6736(19)31096-7); Battle et al., *The Lancet*, 2019

[Mapping the global prevalence, incidence, and mortality of Plasmodium falciparum, 2000–17: a spatial and temporal modelling study](https://doi.org/10.1016/s0140-6736(19)31097-9); Weiss et al., *The Lancet*, 2019

### Implementation

It is not generally envisaged that these queries would find usage outside of MAP as they are designed to replicate internal data formats used there. However they may be of interest in terms of seeing the approach used to summarise child-level data to a cluster-level proportional variable.


