# Extended building quality information

### Summary

SQL code for extracting extended information on house building quality and other household level outcomes such as wealth, from the DHS database.

README updated 2021-02-12, HSG

### Description

This is a household level extraction of a range of variables relating to the status of households; including building quality (e.g. material of the floor, wall and ceiling); ownership of goods such as car, phone, etc; and wealth and education levels of the household head.

It's based on the DHS database tables and is just a simple join. Preliminary checks were undertaken first (using the metadata tables) to ensure that all the columns referenced had constant meaning across all the surveys for which data were extracted. This would need to be done again if running for other surveys in future.

### Usage history

This dataset was produced in August 2016. The data extracted formed the main input to the paper [Mapping changes in housing in sub-Saharan Africa from 2000 to 2015](https://doi.org/10.1038/s41586-019-1050-5); Tusting et al., *Nature*, 2019. 


### Implementation

This was a development and re-implementation of the building quality part of the [earlier extraction](../Stage_02_Building_Quality_And_Child_Health) published in [PloS Medicine](https://doi.org/10.1371/journal.pmed.1002234). 

The extraction is run using the SQL files in the SQL folder. Whereas the earlier version used an FME workbench to map the coded output values, this version extracts them directly. The query extracts both the coded values and - where appropriate - the translated value descriptions from the metadata tables using inline sub-queries. (This is also different from the [first iteration](../Stage_01_Basic_Building_Info)). 

The FME workbench simply runs the queries for each survey in turn by reading in the SQL file, string-substituting in the surveyid, and writing the output.

