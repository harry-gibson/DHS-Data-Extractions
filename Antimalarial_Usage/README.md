# Antimalarial usage in children

### Summary

FME workbench to create and execute SQL code for extracting information on antimalarial drugs from the DHS database.

README updated 2021-02-18, HSG

### Description

In this project we needed to extract standardised information relating to the treatment of children with antimalarial drugs, broken down by generic drug type. 

In the surveys, this information is broken down across numerous questions with yes/no answers, one for each drug, of the form "Was Chloroquine taken for the fever/cough?"
The main difficulty here is that the columns in which each drug is mentioned can vary, and so we need a different SQL query for each survey. 

For example the question "Was Quinine taken for fever/cough" can be found in column `H37D` or in column `H37F` (amongst others), depending on survey. But column `H37D` can, in other surveys, mean e.g. "Was ibuprofen/acetaminophen taken for fever/cough" and `H37F` can mean "Was a country-specific antimalarial taken for fever/cough".

Thus to produce an extract spanning multiple surveys where we have a common output column for "Was quinine taken", we need to extract the data from a different column for each survey, and thus write a slightly different SQL query for each survey. We take a two part approach to this. 

Firstly, we select all possibly-relevant rows (questions) from the survey metadata table, across all surveys: e.g. all rows mentioning the word "quinine" as well as all rows relating to questions that at least *sometimes* mean "was quinine taken", e.g. `H37D` and `H37F` for all surveys from the example above. This information is dumped into a spreadsheet with the form 

| survey_id | table_name | column_name | question_text | use_as_quinine_output |
| --------- | ---------- | ----------- | ------------- | --------------------- |
| 169 | REC43 | H37F | Quinine taken for fever | *Y* |
| 334 | REC43 | H37F | Antihistanimico | *N* |
| 211 | REC43 | H37G | Quinine taken for fever | *Y* |

This example shows one (of many) rows where the quinine question is in column H37F, one row where H37F means something different, and one row where the quinine question is somewhere else. This spreadsheet is dumped from the metadata table, and then it is the task of the malaria researcher to populate the "use_as_quinine_output" column to identify the survey/column pairs which should be selected for this output. 

*In reality the table has many different rows for Quinine (it can be found in other questions apart from those mentioned above) and several more output columns for other drugs (chloroquine, artesunate, etc), and thus many rows (potential survey questions).*

Secondly, we read this populated spreadsheet table and use it to construct a bespoke SQL query for each survey. For this project, this has been implemented using an FME workbench. This "writes" and executes the SQL for each survey in turn, saving the results to a common output file. 

### Usage history

TBD (publication in preparation)

### Implementation

The two-part process used here, of extracting metadata, flagging it, then creating queries based on the flags, was first developed for the DHS [Fever-seeking-treatment work](https://github.com/harry-gibson/dhs-fever-seeking-treatment).

The SQL file [extract_antimalarial_value_coding.sql](SQL/extract_antimalarial_value_coding.sql) creates the value coding spreadsheet described above. This spreadsheet should then be passed to the researcher with suitable knowledge to add and populate columns for "use_as_quinine_output", etc, as described.

The FME workbench [create_and_execute_antimalarial_queries.fmw](FME/create_and_execute_antimalarial_queries.fmw) is then run, using the populated spreadsheet as input. The workbench encompasses the necessary information for constructing queries to JOIN the relevant tables and SELECT the necessary columns - one clause for each row in the spreadsheet that has been flagged for use - for each survey in turn. It creates the SQL text, before executing it and saving the results to CSV (as well as saving a copy of the SQL itself for reference).



