# Building quality and household-level child health

### Summary

SQL code for extracting datasets relating to building quality and to childhood health outcomes from the DHS database.

README updated 2021-02-15, HSG

### Description

This is a large and complex extraction of data relating to improved housing, household wealth, and child health outcomes. The data were extracted in two sections: one at household level and one at child level. Data for households were extracted according to the presence of an entry in the RECH0 (basic household information) table. Data for children were extracted according to the presence of an entry in the RECH1 (household schedule) table.

Especially in the children's section of the extraction, there were numerous country-specific and other exceptions to standard variable locations. The queries therefore make extensive use of `COALESCE` and `CASE` statements to select the required values from each survey into the common output columns. For coded value variables, the data are retrieved both as the coded values and also as the value descriptions (using sub-queries against the metadata table).

 
### Usage history

This folder contains the code that was developed and used to extract the datasets for the study [Housing and child health in sub-Saharan Africa: A cross-sectional analysis](https://doi.org/10.1371/journal.pmed.1003055) (Tusting et al., *PLoS Medicine*, 2020), and [Environmental temperature and growth faltering in African children: a cross-sectional study](https://doi.org/10.1016/s2542-5196(20)30037-1); (Tusting et al., Lancet Planetary Health, 2020)

#### Relationship to previous studies 

Following the [earlier study](../Stage_02_Building_Quality_Childhood_Malaria) which investigated the relationship between improved housing and childhood malaria outcomes, [Tusting at al 2020](https://doi.org/10.1371/journal.pmed.1003055) sought to synthesise these datasets to conduct a cross-sectional analysis of the relationships between these outcomes. 

To do this we re-created and slightly developed the more comprehensive building quality dataset that [was developed](../Stage_03_Extended_Building_Info) for another [previous paper](https://doi.org/10.1038/s41586-019-1050-5), along with a much more comprehensive dataset on childhood health outcomes (not just malaria).

### Implementation

There were separate extractions for household-level (one row per household) and child-level (one row per child) variables. A separate SQL file was developed for each. Each query selects both the coded value data and the translated textual descriptions as separate columns. Each query was executed once per survey using a simple FME workbench to substitute in the survey id. 

The main query used for the household-level info is [Extended_Building_Quality_Generic_Query_2018.sql](SQL/Extended_Building_Quality_Generic_Query_2018.sql). This is very similar to the query that was used in the [earlier study](../Stage_03_Extended_Building_Info); only information on indoor smoking and IRS treatment has been added.

The main query used for the child-level info is 
[HH_Level_Children_Health_Generic_Query_2018.sql](SQL/HH_Level_Children_Health_Generic_Query_2018.sql). This query is based off the household schedule table RECH1: that is, it extracts one row for each entry in the household schedule table where the occupant is aged <=5. 

#### Challenges 

Within the DHS survey structure, questions relating to malaria in individuals are stored in the tables linked to household schedule. In the [2017 study](../Stage_02_Building_Quality_Childhood_Malaria) the child-level table was based off the household schedule, as malaria questions were the only ones of interest then. 

However in this extended study, we have added numerous extra child-health variables which are stored in the woman/child level tables (`REC01` / `REC21`). Therefore we originally planned to create the child-level information as an extraction based off the `REC21` (birth history) table. The query [Children_Health_Generic_Query_2018.sql](SQL/Children_Health_Generic_Query_2018.sql) was developed with this aim in mind, along with [Child_Malaria_Standard_Labelled_Query.sql](SQL/Child_Malaria_Standard_Labelled_Query.sql) to get the data on malaria from the household-level tables.

However upon running this query we realised that a different, smaller, set of child respondents were being covered than before. It turns out that the population of `RECH1` (the household schedule table, used before) aged < 5 is not the same as the population of `REC21` (the birth history table). Our understanding is that `REC21` has entries only for the children of mothers who were surveyed. If a mother was not surveyed (e.g. she was absent or ineligible) then her children will not be present in `REC21`, but the child will still be present in `RECH1` and linked tables on that side of the survey, hence the difference.

Therefore we returned to basing this extraction off the household-level table, hence [**HH_Level**_Children_Health_Generic_Query_2018.sql](SQL/HH_Level_Children_Health_Generic_Query_2018.sql). The other file is redundant but is provided for interest.

Despite this we have to join through to the birth-history tables where possible to match the child-health data with the malaria data. This is done via the linking variable `REC21.B16` (child's line number in household). This variable was not present in early surveys, and so there are times when this is not possible. 

For all of these reasons, LEFT OUTER joins are used throughout to ensure that a row is extracted for every matching child even where there is no data in some of the other tables.

