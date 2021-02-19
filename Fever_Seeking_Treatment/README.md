# DHS Fever Seeking Treatment (Treatment seeking for fever in children)

### Summary

FME workbench to create and execute SQL code for extracting information on treatment seeking for fever in children from the DHS database.

README updated 2021-02-18, HSG

This is a re-written version of the code to extract Fever-Treatment-Seeking data from DHS surveys within the [Malaria Atlas Project](http://www.map.ox.ac.uk) (MAP).

### Description

The required output in these studies is a child-level dataset tabulating whether a child had fever in the last two weeks, and if so whether they sought treatment (=it was sought for them) at a public healthcare facility, at any healthcare facility (public or private medical), or not at all (or only at a non-medical facility). We also need output datasets that are summarised by woman (mother), cluster, region, and survey.

The question "did the child have fever in the last two weeks" is directly present in the surveys. However information about where treatment is sought for a fever is stored in DHS surveys in a combination of many different columns, each of which specifies a particular location or type of location that may provide treatment with a yes/no answer for whether the child was taken there.

These are generally columns H32A - H32Z of table REC43; occasionally these columns are to be found in a different table (REC4A in all newer surveys). The meaning of each column (i.e. the location it corresponds to) varies between surveys, within certain constraints.

For example column H32A will always mean "Sought treatment for the fever in &lt;some form of public hospital&gt;", where the exact wording will vary between surveys. However other questions vary more significantly: H32Q might mean "sought treatment in a private clinic" in one survey, but "sought treatment from a traditional medicine practitioner" in another survey. In the first case we would want to count that answer as having sought medical treatment, but in the second case we would not.

The first "few" columns alphabetically will always refer to public treatment sources, but "few" is not a constant. Later columns tend to vary more in their meaning.

Therefore, for every survey we need to extract the data from a different subset of the H32* columns in order to determine whether a child sought public or any medical treatment. That is, the categorisation of which columns equate to public treatment / private treatment / non-medical treatment is not constant between surveys.

#### Approach

Our desired output has two columns: "sought treatment in a public facility" and "sought treatment in any medical facility". Thus for each survey we need to map a potentially different combination of the input columns onto each of these two outputs. As with the [antimalarial usage extraction](../Antimalarial_Usage), the processing is therefore a two stage process.

Firstly we dump out from the DHS metadata tables a full listing of all possible column names relating to treatment seeking, from all surveys: so approximately 26 rows for each survey (not all surveys use all 26 options).

A researcher will then add two additional columns to this file, representing "Use As Public Treatment" and "Use As Any Treatment". A 'Y' in one of these columns against a given row means that for that survey, a positive answer to that questions should count as "sought public treatment" or "sought any treatment".

Then the second stage of the processing will read this coding file and use it to build SQL queries that select "Sought Public Treatment" as 'Yes' when any of the flagged column names for that survey contained a positive response.  The data are SELECTed at the level of the individual child (to whom the source data correspond) and also aggregated by woman (mother), cluster, region, and overall survey.

### Usage history

This extraction was originally developed to enable the following study:

    [Treatment-seeking rates in malaria endemic countries](https://doi.org/10.1186/s12936-015-1048-x); Battle et al., *Malaria Journal*, 2016

*(The original implementation was developed before the DHS database was created and ran directly against the parsed CSV data tables, manipulated within an FME workbench. However it was functionally identical to the present version)*

More recently the treatment seeking for fever data have become a part of the overall malaria incidence modelling process within MAP. (An understanding of the proportion of childhood fevers for which treatment is sought is necessary to help understand the true community incidence of malaria when the only information we have relates to the number of cases where treatment was sought.) As such this code underpins the global modelling studies such as 

    [Mapping the global prevalence, incidence, and mortality of Plasmodium falciparum, 2000–17: a spatial and temporal modelling study](https://doi.org/10.1016/s0140-6736(19)31097-9); Weiss et al., *The Lancet*, 2019


### Implementation

As described above the basic process is to dump a spreadsheet containing all the potential survey/question pairs that could relate to answering the question "was treatment sought at a public facility" and "was treatment sought at a private facility". A researcher then populates a column for each output variable, flagging the question / survey pairs for which a positive answer should equate to that type of treatment being sought. 

A single FME workbench then reads in the populated file and uses this to generate SQL queries which are then executed against the database to retrieve the results at different levels of aggregation. Within the workbench, the queries are generated by translating each flagged row of the spreadsheet into an SQL clause, before concatenating all the clauses for each survey together with appropriate boolean logic into a single SELECT statement.

An output CSV file is generated for each survey, at each aggregation level: Child, Woman, Cluster, Regional, National (or Survey). Additionally a single output file is generated at each of these aggregation levels containing the data from all surveys extracted in that run, i.e. a concatentaion of all the other files of a given level.

In the national-level output files we also calculate 95% confidence intervals for the estimates of proportion of fevers seeking public or any treatment. These are calculated by two methods, described in the Usage section. Both sets of CIs are calculated from the cluster-level treatment seeking proportions for each survey, and the CIs are recorded in the national-level output files.

#### 1. Create and populate output mapping

The template output-mapping table can be generated simply by dumping out the appropriate rows from the `dhs_survey_specs.dhs_table_specs_flat` table with a query such as:

`SELECT surveyid, recordname, name, label, '' as "NewPublicTreat", '' as "NewAnyTreat" FROM dhs_survey_specs.dhs_table_specs_flat WHERE name like 'H32%' ORDER BY surveyid, name`

This should be modified to include any other potential columns (=rows in this query) based on knowledge of new surveys, fuzzy-matching on the 'label' column, etc: it's better to include too many possibilities rather than too few. Obviously filter by surveyid if you do not want to do a full extraction of all surveys.

A sample coding file that has been populated appropriately is provided for a couple of random surveys. The researcher should populate a new copy of this table for all the surveys for which treatment-seeking data are required.

#### 2. Translate to SQL, extract data, calculate CIs

The main FME workbench should then be run with this completed coding file as an input. It will generate a query for each survey specified in the input file, for each output level (Child, Woman, Cluster, Regional, National). It will execute each of these queries against the database (assuming that the connection details have been provided) and it will calculate confidence intervals for the national-level results based on the cluster-level results for the same surveys.

The required data for the output files also include columns found in other tables of the DHS schema, including (at the child and woman levels) sample weight and household wealth, and (at the child, woman and cluster levels) the cluster latitude/longitude and rural/urban classification. The queries therefore need to join several tables, and because the table where the treatment-seeking information is found varies between surveys (REC43 or REC4A) then the workbench has to embed this information to construct the join clauses appropriately.

It will write out the queries themselves (as SQL files) and the results of those executing those queries (as CSV files) to the specified location.

Example outputs are provided (both SQL files and their CSV outputs), generated from the sample input coding file.

##### 2.1 Confidence Interval calculation

Note that the confidence intervals calculation has changed from that done in the initial fever-seeking treatment work (where it was not part of the original extraction but happened downstream). In various iterations earlier versions of the code has calculated confidence intervals for the **national-level treatment seeking proportion estimates**, using several different different methods:
* Using the **cluster-treatment-seeking-proportion data**, applying the "standard" central limit theorem approach of assuming a normal distribution, calculating the SD and SE of the data, and taking the 95% CI as +- 1.96 SE from the mean. The cluster-based SE was applied to the national-level mean.
* Using the **cluster-treatment-seeking-proportion data**, normalising the values by the size (n with fever) of the cluster, then bootstrapping distributions from the data (per-survey) and estimating CIs with no assumptions about the distribution of the data. This fixed the problem of non-normality in the cluster proportion data, but is still not the correct approach as the CIs are estimated on a different population (cluster data) to the national-level result (from child-level data).
* Using the **binary child-level sought-treatment data**, modelled using a GLM and a quasibinomial distribution.
* Using the **binary child level sought-treatment data**, modelled using the pre-rolled R "Survey" package. Under the hood this probably does *something something* binomial but *something something* design effects, however it is hard to be clear exactly what it does without looking into the source code of the survey package.
The latter two approaches are the most appropriate as they are calculating the CIs from the "full" dataset, rather than from a cluster level summary. 

It isn't clear which of these two is the most appropriate, but the R "Survey" package was deemed by the researchers to give the "best" results so at present the code will calculate only this set of CIs. The R code for this is embedded within the workbench; a separate R file `fme_rcaller_confidence_intervals.r` is provided for illustration purposes only to show other approaches.

The CIs (other than those derived simply from mean +- SE estimates) cannot be done directly in FME; they are implemented via RCaller transformers. This requires the R interpreter to be setup in FME workbench, and a couple of R libraries, listed in a workbench annotation, to be installed at the system level (run R Console as administrator and install them to the program files location). You can run the workbench without this requirement (and without calculating CIs) simply by disabling the RCaller transformers.

### Example Data

The sample_data folder provides various examples of the input and output. 
- input contains a question-mapping file in which the questions have been appropriately flagged. This can be used as input to the SQL-generation workbench
- output contains the SQL files generated by the workbench (under generated_sql/) and the CSV data files produced by executing these queries against the DHS database.