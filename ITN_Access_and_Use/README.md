# ITN Access and Use

### Summary

SQL code to retrieve and calculate data about the availability and usage of insecticide-treated bednets (ITNs) from the corpus of DHS surveys, in an output format matching a pre-existing dataset.

README updated 2021-02-12, HSG

### Description

This work was developed in the [Malaria Atlas Project](http://malariaatlas.org). Data on the availability and usage of ITNs underpins a wide range of malaria modelling and DHS surveys provide an important source of this information. 

Prior to the development of the [DHS database](https://github.com/harry-gibson/DHS-To-Database) extractions of these ITN data had been performed manually through careful manipulation of large flat-file spreadsheets, using some enormous pivot tables and copy-paste work. This resulted in an output schema that then became part of the downstream modelling routine; thus when this SQL version was developed it was a requirement to match that pre-existing output schema.

Converting the data as they are held in the survey questions into the variables of the output schema involves classifying nets by what type they are and how old they are. From the published paper at http://dx.doi.org/10.7554/eLife.09672:

    "A net was considered an ITN if it was an LLIN, or a pre-treated net obtained within the past 12 months, or a net that has been soaked with insecticide within the past 12 months. ITNs were then subdivided into the two classes, LLINs and cITNs."

### Usage history

The ITN data extractions produced via this code are a key part of the modelling chain in the [Malaria Atlas Project](http://malariaatlas.org), and thus contribute to papers such as [Mapping the global prevalence, incidence, and mortality of Plasmodium falciparum, 2000–17: a spatial and temporal modelling study](https://doi.org/10.1016/s0140-6736(19)31097-9) (Weiss et al., *The Lancet*, 2019).


### Implementation 

All the data selection and summarisation logic is implemented in the [SQL query](SQL/ITN_By_HH_Generic_Template.sql) presented here. This extracts the data at household level: i.e. one row per household. A [second version](SQL/ITN_By_Cluster_Generic_Template.sql) extracts the same data, but summarised by cluster.

Some surveys store some of the required information in a different, country-specific table, RECH7. Due to the complexity of the clauses involved, a separate query was provided for these surveys, rather than making a single generic one.

A simple FME workbench is provided to run the queries for each survey in turn, writing the results to individual CSVs for each survey. 
