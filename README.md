### Intro

This is a re-written version of the code to extract Fever-Treatment-Seeking data from DHS surveys within the [Malaria Atlas Project](http://www.map.ox.ac.uk) (MAP).

The original version of the code operated against CSV files which were manipulated by a series of FME workbenches. That was somewhat unmaintainable; this version replaces that entirely and works with a copy of the DHS data corpus held in a PostgreSQL database.

A single FME workbench reads in the configuration file (below) and uses this to generate SQL queries which are then executed against the database to retrieve the results at different levels of aggregation. Barring any dramatic changes to the DHS survey schemas the code can be easily re-run to extract data for new surveys (after they have been loaded to our database); similarly it can be re-run should the required output value mappings change.

### Background

Information about where treatment is sought for a fever is stored in DHS surveys in a combination of many different columns, generally columns H32A - H32Z of table REC43.
Occasionally these columns are to be found in a different table (REC4A - in newer surveys).

Each of these columns can have a Yes or No answer. The meaning of each column (i.e. the question text) varies between surveys, within certain constraints.

For example column H32A will always mean "Sought treatment for the fever in &lt;some form of public hospital&gt;", where the exact wording will vary between surveys. Other questions vary more significantly: H32Q might mean "sought treatment in a private clinic" in one survey, but "sought treatment from a traditional medicine practitioner" in another survey (in the first case we would want to count that answer as having sought medical treatment, but in the second case we would not).

The first "few" columns alphabetically will always refer to public treatment sources, but "few" is not a constant. Later columns tend to vary more in their meaning.

Therefore, for every survey we need to extract the data from a different subset of the H32* columns in order to determine whether a child sought public or any medical treatment.

### Approach

Our desired output has two columns: "sought treatment in a public facility" and "sought treatment in any medical facility". Thus for each survey we need to map a potentially different combination of the input columns onto each of these two outputs, depending on the wording of the questions in that survey.

Like with version 1 of the code, the processing is therefore a two stage process.

Firstly we dump out from the DHS metadata tables a full listing of all possible column names relating to treatment seeking, from all surveys: so approximately 26 rows for each survey (not all surveys use all 26 options).

A researcher will then add two additional columns to this file, representing "Use As Public Treatment" and "Use As Any Treatment". A 'Y' in one of these columns against a given row means that for that survey, a positive answer to that questions should count as "sought public treatment" or "sought any treatment".

Then the second stage of the processing will read this coding file and use it to build SQL queries that select "Sought Public Treatment" as 'Yes' when any of the flagged column names for that survey contained a positive response.  The data are SELECTed at the level of the individual child (to whom the source data correspond) and also aggregated by woman (mother), cluster, region, and overall survey.

The required data for the output files also include columns found in other tables of the DHS schema, including (at the child and woman levels) sample weight and household wealth, and (at the child, woman and cluster levels) the cluster latitude/longitude and rural/urban classification. The queries therefore need to join several tables, and because the table where the treatment-seeking information is found varies between surveys (REC43 or REC4A) then the workbench has to embed this information to construct the join clauses appropriately.

An output CSV file is generated for each survey, at each aggregation level: Child, Woman, Cluster, Regional, National (or Survey). Additionally a single output file is generated at each of these aggregation levels containing the data from all surveys extracted in that run, i.e. a concatentaion of all the other files of a given level.

In the national-level output files we also calculate 95% confidence intervals for the estimates of proportion of fevers seeking public or any treatment. These are calculated by two methods, described in the Usage section. Both sets of CIs are calculated from the cluster-level treatment seeking proportions for each survey, and the CIs are recorded in the national-level output files.

### Usage

#### 1. Create and populate output mapping
The template output-mapping table can be generated within MAP simply by dumping out the appropriate rows from the dhs_survey_specs.dhs_table_specs_flat table with a query such as:

`SELECT surveyid, recordname, name, label, '' as "NewPublicTreat", '' as "NewAnyTreat" FROM dhs_survey_specs.dhs_table_specs_flat WHERE name like 'H32%' ORDER BY surveyid, name`

This should be modified to include any other potential columns (=rows in this query) based on knowledge of new surveys, fuzzy-matching on the 'label' column, etc: it's better to include too many possibilities rather than too few. Obviously filter by surveyid if you do not want to do a full extraction of all surveys.

A sample coding file that has been populated appropriately is provided for a couple of random surveys. The investigator should populate a new copy of this table for all the surveys for which treatment-seeking data are required.

#### 2. Translate to SQL, extract data, calculate CIs
The main FME workbench should then be run with this completed coding file as an input. It will generate a query for each survey specified in the input file, for each output level (Child, Woman, Cluster, Regional, National). It will execute each of these queries against the database (assuming that the connection details have been provided) and it will calculate confidence intervals for the national-level results based on the cluster-level results for the same surveys.

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

