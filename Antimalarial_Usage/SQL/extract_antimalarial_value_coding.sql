-- Attempt to select all questions from the metadata table which relate to antimalarial drugs given to children. 
-- Inevitably this will pull out some irrelevant questions (e.g. the string '%alu%' matches all kinds of stuff, and 
-- sometimes the questions are asked of the mother not the child, or are about general knowledge not specific incidences, etc,
-- so the results of this query need to be flagged manually to determine whether each question should be used.
-- Also, this query will likely miss some, particularly country-specific drug names that don't match any of these strings and 
-- are not stored against an ML13 or H37 question. 
-- So for example we also need to look for cases where the query pulls out say SM237C and SM237D 
-- for a particular survey and then look at the data for that survey and see if questions SM237A-Z are all also relevant, and if 
-- so add those rows in.
--
SELECT surveyid, recordname, name, label
FROM dhs_survey_specs.dhs_table_specs_flat
WHERE
  -- the default antimalarial-to-children question locations
  name like 'ML13%'
  OR name like 'H37%'
  -- try to catch all the antimalarial questions lurking in nonstandard columns using text matches
  OR lower(label) like '%quin%'
  OR lower(label) like '%fansidar%'
  OR lower(label) like '%artesunate%'
  OR lower(label) like '%coartem%'
  OR lower(label) like '%dhap%'
  OR lower(label) like '%dhasp%'
  OR (lower(label) like '%alu%' and lower(label) not like '%salud%')
  -- try to get all questions about heel prick
  OR lower(label) like '%heel%'
ORDER BY surveyid::Integer, recordname, name

-- here is a way of checking the data for a specific survey and table to see if there are any other relevant questions 
-- as described in the second part of the initial remarks above.
-- Configure datagrip to copy data in tab-separated format then you can directly copy-paste the results from datagrip to excel
-- to add extra rows.
select surveyid, '', '', 'y', recordname, recordlabel, name, label from dhs_survey_specs.dhs_table_specs_flat where recordname='REC99' and surveyid = '154'

select * from dhs_survey_specs.dhs_table_specs_flat where lower(label) like '%assp%' and lower(label) not like '%aspirin%'

select * from dhs_survey_specs.dhs_table_specs_flat where name = 'H22'