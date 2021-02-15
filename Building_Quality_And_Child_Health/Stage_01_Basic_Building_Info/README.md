# Building quality information

### Summary

SQL code for extracting basic information on house building quality from the DHS database.

README updated 2021-02-12, HSG

### Description

This is a reasonably straightforward household level extraction of a few variables relating to the quality of households; namely the material of the floor, wall and ceiling.

It's based on the DHS database tables and is just a simple join. No account is automatically taken of whether the meaning of the columns involved changes between surveys, so this had to be checked manually first and this would need to be done again if running for other surveys in future.

### Usage history

This dataset was produced for a preliminary investigation in July 2016. It's here for archival purposes only at this point.

### Implementation

The SQL file in the SQL folder was for development. The extraction was actually run using the FME workbench in the FME folder. This embeds the same query, and used the CSV copies of the value descriptions tables to decode the coded answer values.

