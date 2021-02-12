# IRS Spraying

### Summary

SQL code for extracting information on IRS (Insecticide Residual Spraying) from the DHS database.

README updated 2021-02-12, HSG

### Description

This was a very simple extraction of information on the prevalence of IRS spraying along with basic information on number of household members.  

There's a direct mapping between database columns and output columns, consistent among surveys, i.e. there are no survey-specific exceptions. 

This was checked first using the metadata tables.

### Usage history

The data extracted with this query contributed towards the analysis in [Indoor residual spraying for malaria control
in sub-Saharan Africa 1997 to 2017: an adjusted
retrospective analysis](https://doi.org/10.1186/s12936-020-03216-6) (Tangena et al., *Malaria Journal*, 2020), among other studies.


### Implementation

This is simply an SQL query that selects all relevant information for all surveys; results can just be saved to a CSV etc for further analysis.