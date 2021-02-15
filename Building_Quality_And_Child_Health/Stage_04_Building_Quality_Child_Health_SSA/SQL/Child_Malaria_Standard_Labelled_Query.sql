-- Create the child-malaria extraction for Lucy Tusting, using SQL to extract the descriptions from the metadata tables, 
-- rather than the previous approach of using an FME schemamapper to create the recoded value descriptions.

-- This file has been created to reflect some non-standard variable names which were identified (manually) by Lucy. For example 
-- some surveys have the blood smear test result in a non-standard table, or table+column. Fortunately in these cases, the "standard" name 
-- column doesn't exist with something different in, it's just missing, so we can run the same SQL for all surveys and just COALESCE to get 
-- whichever value is non-null.

-- It's intended that this SQL should be run via the FME workbench in the same folder which will rename the columns created by the query 
-- to include various special characters and match Lucy's required output format. The SQL is embedded in the workbench, so this file is just a backup.

SELECT
r1.surveyid
, r1.hhid as "HHID"
, r1.hvidx as "Child_Line_Num"
, r1.hhid||'_'||r1.hvidx as "Child_ID"
, r0.hv001 as "hv001_ClusterID"
, r0.hv002 as "hv002_hh_number"
, r1.hv104 as "hv104_sex_id"
, (SELECT value_desc from dhs_survey_specs.dhs_value_descs where col_name='HV104' AND surveyid=r0.surveyid AND value=hv104 AND value_type='ExplicitValue') as hv104_sex
, r1.hv105 as "hv105_Age"
, rc.hc53 as "hc53_hemoglobin_g/l_1decimal"
, rc.hc56 as "hc56_alt_adj_hemoglobin_g/l_1decimal"
, rc.hc57
, v_hc57.value_desc as "hc57_anemia_level"
, rm.hml19
, v_hml19.value_desc as "hml19_Person sleep under an ever treated bednet"
, rm.hml20
, v_hml20.value_desc as "hml20_Person sleep under an llin net"

-- depending on the survey the lab test data can be in one of the following columns: just use the first non-null
-- one to avoid rewriting query each time, and output it as the standard name hml32 regardless of input
, COALESCE(
	rm.hml32 -- the standard lab test column
	, rm.shmala -- used in 437 ghana
	, rm2.hml32 -- a few surveys have hml32 in a different table, rechm2
	, rmc.stestch -- used in 323 rwanda, table rechmc
	, rc.sh214r -- used in 338 senegal, table rec96
	) as hml32 
-- we join one subselection of the value specs table for each possible column _name_ 
, COALESCE(
	v_hml32.value_desc 
	, v_hml32b.value_desc 
	, v_hml32c.value_desc
	, v_hml32d.value_desc
	) as "hml32_Final result of malaria from blood smear test"

, COALESCE(rm.hml33, rm2.hml33) as hml33
, v_hml33.value_desc as "hml33_Result of malaria measurement"

-- depending on the survey the rdt data can be in one of the following columns: just use the first non-null
-- one to avoid rewriting query each time, and output it as the standard name hml35 regardless of input
, COALESCE(
	rm.hml35
	, rm2.hml35
	, rm.sh418
	, rmc.sh119
	, rc.sh212
	) as hml35
-- seperate joins to get the desc as there are two different names the column can take
, COALESCE(
	v_hml35.value_desc
	, v_hml35b.value_desc
	, v_hml35c.value_desc
	, v_hml35d.value_desc) as "hml35_Final result of malaria from RDT"


FROM 
dhs_data_tables."RECH1" r1
LEFT JOIN
dhs_data_tables."RECH0" r0
ON r1.surveyid = r0.surveyid AND r1.hhid = r0.hhid

-- Join the tables that might supply the malaria test info, using outer joins as we don't expect a 
-- row to be present in all these join tables (or any of them, if there was no test done)
LEFT JOIN 
dhs_data_tables."RECHMH" rm 
ON r1.surveyid = rm.surveyid AND r1.hhid = rm.hhid AND r1.hvidx = text(rm.hmhidx)
LEFT JOIN 
dhs_data_tables."RECHM2" rm2
ON r1.surveyid = rm2.surveyid AND r1.hhid = rm2.hhid AND r1.hvidx = text(rm2.hmldx)
LEFT JOIN 
dhs_data_tables."RECHMC" rmc
ON r1.surveyid = rmc.surveyid AND r1.hhid = rmc.hhid AND r1.hvidx = text(rmc.idxhmc)

-- Join the table that supplies the anaemia / haemoglobin info
LEFT JOIN
dhs_data_tables."RECH6" rc
ON r1.surveyid = rc.surveyid AND r1.hhid = rc.hhid AND r1.hvidx = rc.hc0

-- Join the value descriptions table once for each column we need to get descriptions for 
-- referring to each copy by a different name (there may be a neater way of doing this)
LEFT JOIN 
dhs_survey_specs.dhs_value_descs as v_hc57 
ON v_hc57.value = hc57 AND v_hc57.col_name = 'HC57' and v_hc57.surveyid = r1.surveyid
LEFT JOIN 
dhs_survey_specs.dhs_value_descs v_hml19 
ON v_hml19.value = hml19 AND v_hml19.col_name = 'HML19' and v_hml19.surveyid = r1.surveyid
LEFT JOIN 
dhs_survey_specs.dhs_value_descs v_hml20
ON v_hml20.value = hml20 AND v_hml20.col_name = 'HML20' and v_hml20.surveyid = r1.surveyid

LEFT JOIN 
dhs_survey_specs.dhs_value_descs v_hml33
ON v_hml33.value = COALESCE(rm.hml33, rm2.hml33) AND v_hml33.col_name = 'HML33' and v_hml33.surveyid = r1.surveyid

-- value descriptions for lab test columns
LEFT JOIN 
dhs_survey_specs.dhs_value_descs v_hml32
ON v_hml32.value = COALESCE(rm.hml32, rm2.hml32) AND v_hml32.col_name = 'HML32' and v_hml32.surveyid = r1.surveyid
LEFT JOIN 
dhs_survey_specs.dhs_value_descs v_hml32b
ON v_hml32b.value = stestch AND v_hml32b.col_name = 'STESTCH' and v_hml32b.surveyid = r1.surveyid
LEFT JOIN 
dhs_survey_specs.dhs_value_descs v_hml32c
ON v_hml32c.value = sh214r AND v_hml32c.col_name = 'SH214R' and v_hml32c.surveyid = r1.surveyid
LEFT JOIN 
dhs_survey_specs.dhs_value_descs v_hml32d
ON v_hml32d.value = shmala AND v_hml32d.col_name = 'SHMALA' and v_hml32d.surveyid = r1.surveyid

-- Value descriptions for RDT colimns
LEFT JOIN 
dhs_survey_specs.dhs_value_descs v_hml35
ON v_hml35.value = COALESCE(rm.hml35, rm2.hml35) AND v_hml35.col_name = 'HML35' and v_hml35.surveyid = r1.surveyid
LEFT JOIN 
dhs_survey_specs.dhs_value_descs v_hml35b
ON v_hml35b.value = sh418 AND v_hml35b.col_name = 'SH418' and v_hml35b.surveyid = r1.surveyid
LEFT JOIN 
dhs_survey_specs.dhs_value_descs v_hml35c
ON v_hml35c.value = sh119 AND v_hml35c.col_name = 'SH119' and v_hml35c.surveyid = r1.surveyid
LEFT JOIN 
dhs_survey_specs.dhs_value_descs v_hml35d
ON v_hml35d.value = sh212 AND v_hml35d.col_name = 'SH212' and v_hml35d.surveyid = r1.surveyid

LEFT JOIN 
dhs_survey_specs.dhs_value_descs v_hv104
ON v_hv104.value = hv104 AND v_hv104.col_name = 'HV104' and v_hv104.surveyid = r1.surveyid

WHERE 
r1.surveyid::Integer = {SURVEYID} --in (282,323,330,332,337,338,395,399,437,451,473,481,484) 
AND 
r1.hv105::Integer < 18
ORDER BY surveyid, hv001::Integer, hhid, hvidx::Integer