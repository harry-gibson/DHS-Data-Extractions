-- Extract the raw child-level data needed for all childhood mortality calculations to
-- an intermediate table
-- Table will be populated for all surveys excluding Ethiopia, Nepal, Afghanistan
-- (as these use different date format which I haven't taken the time to figure out
-- as I don't need them - although it should not in fact matter for CMC-based age
-- calulations)
-- dhs_data_summary.child_mortality_raw
DROP TABLE IF EXISTS dhs_data_summary.child_mortality_raw;
CREATE TABLE dhs_data_summary.child_mortality_raw AS
SELECT
r21.surveyid, r21.caseid, LEFT(r21.caseid, -3) AS hhid, v001 AS clusterid,
v024 AS region, latnum as lat, longnum as lon,
v005::INTEGER AS sample_wt,
v025::INTEGER AS type_of_residence,
bidx, bord,
v008::INTEGER AS v008_int_cmc,
v008::INTEGER - 12 AS cmc_1yr_prior,
v008::INTEGER - 60 AS cmc_5yr_prior,
v008::INTEGER - 120 AS cmc_10yr_prior,
v007::INTEGER AS v007_int_yr,
CASE WHEN v007::INTEGER between 0 and 10 then v007::INTEGER + 2000
    WHEN v007::INTEGER BETWEEN 80 and 99 then v007::INTEGER + 1900
    ELSE v007::INTEGER END AS v007_int_yr_cln,
v006::INTEGER AS v006_int_mth,
v016::INTEGER AS v016_int_day,
v008a::INTEGER AS v008a_int_cdc,
b3::INTEGER AS b3_dob_cmc,
b2::INTEGER AS b2_birth_yr,
CASE
    -- affects svy 135, 148, 156, 209
    WHEN b2::INTEGER between 0 and 10 then b2::INTEGER + 2000
    WHEN b2::INTEGER between 11 and 99 then b2::INTEGER + 1900
    ELSE b2::INTEGER END as b2_birth_yr_cln,
b1::INTEGER AS b1_birth_mth,
b17::INTEGER AS b17_birth_day,
b18::INTEGER AS b18_dob_cdc,
b4::INTEGER AS b4_sex,
b5::INTEGER AS b5_is_alive,
b7::INTEGER AS b7_death_age_months,
b11 AS b11_prev_birth_ival_mths
FROM
dhs_data_tables."REC21" r21
INNER JOIN
dhs_data_tables."REC01" r01
ON
	r21.surveyid=r01.surveyid
	AND
	r21.caseid=r01.caseid
LEFT OUTER JOIN
dhs_data_locations.dhs_cluster_locs locs
ON
	r01.surveyid::INTEGER=locs.surveyid
	AND
	v001::INTEGER=locs.dhsclust
WHERE 
-- just skip surveys with non-standard calendars for now as we don't need them at present
r21.surveyid not in ('10', '86', '202', '268', '356', '400', '472', '561', '585', -- nepal 
				 '147', '248', '359', '478', '551' -- ethiopia
				 '348', '471', '543', '568' -- afghanistan
				 );
				