select count(*) 
FROM
dhs_data_tables."REC01" r01
INNER JOIN
dhs_data_tables."REC51" r51
ON r01.surveyid = r51.surveyid and r01.caseid = r51.caseid
where r01.surveyid = '451' and r51.v501::Integer in (1,2)


select distinct(label) from dhs_survey_specs.dhs_table_specs_flat 
WHERE 
name = 'B8'


select distinct(label) from dhs_survey_specs.dhs_table_specs_flat 
WHERE 
name in ('H3','H5', 'H7') and surveyid='468'

select * from dhs_survey_specs.dhs_table_specs_flat 
WHERE 
name = 'S506MR'

select * from dhs_survey_specs.dhs_value_descs 
WHERE col_name = 'M15' and value = '47' 

select min(value::Integer), max(value::Integer), surveyid from dhs_survey_specs.dhs_value_descs
WHERE col_name = 'HV205' and value != '' group by surveyid
order by max

select * from dhs_survey_specs.dhs_value_descs
WHERE col_name = 'B8'
AND surveyid::Integer in (12,27,207)

select * from dhs_survey_specs.dhs_value_descs
WHERE col_name = 'HV205'
AND value != ''
AND value::Integer = 31

select count(*) from 
dhs_data_tables."RECH1" rh1
INNER JOIN 
dhs_data_Tables."RECH5" rh5
ON 
rh1.surveyid=rh5.surveyid
AND
rh1.hhid=rh5.hhid
AND
rh1.hvidx = rh5.ha0
WHERE 
rh1.surveyid::Integer=468
and 
rh1.hv104::Integer=2
and 
rh5.ha1::Integer between 15 and 49

select count(*) from dhs_data_tables."REC01" where 
surveyid='465'

select surveyid svy from dhs_data_tables."REC43" group by svy order by surveyid::Integer