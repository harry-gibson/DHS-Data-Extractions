-- THIS QUERY WAS USED IN NOVEMBER/DECEMBER 2018 TO GENERATE ONE VERSION OF AN EXTRACTION FOR LUCY
-- HOWEVER WE THEN ABANANDONED IT IN FAVOUR OF A VERSION BASED OFF THE HH SCHEDULE TABLE, FOR COMPATIBILITY WITH THE
-- EARLIER (2016/17) EXTRACTION THAT UNDERPINNED THE PLOS MED STUDY. EXTRACTING FROM THE CHILD-LEVEL TABLES AS DONE HERE
-- RESULTED IN A DIFFERENT NUMBER OF RECORDS, PRESUMABLY AS THERE MAY BE CHILDREN WHO EXIST (AND ARE DOCUMENTED IN HH
-- SCHEDULE) BUT WHOSE MOTHERS DID NOT RESPOND TO THE SURVEY; ALSO A NUMBER OF SURVEYS DO NOT HAVE DATA FOR THE CHILD
-- LEVEL TABLES AT ALL.

SELECT
-- cluster type identifiers
r01_mums.surveyid AS surveynum
, r01_mums.v000 AS v000_ccode_phase
, locs.dhscc AS dhs_countrycode
, r01_mums.v001 AS v001_cluster_id
, locs.dhsid AS cluster_id_full
, locs.latnum AS latitude
, locs.longnum AS longitude
-- woman/individual type identifiers
, r01_mums.caseid AS woman_caseid
, r01_mums.v002 AS v002_hh_num
, r01_mums.v006 AS v006_interview_mth
, r01_mums.v007 AS v007_interview_yr
, r01_mums.v008 AS v008_interview_cmc
-- child type identifiers
,  r21_kids.bord AS bord_birth_order
, r21_kids.b16 AS b16_child_hh_line_num
, r21_kids.b4 AS b4_child_sex
-- child info
, (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs
    WHERE col_name='B4' AND surveyid=r21_kids.surveyid AND value=b4  AND value_type='ExplicitValue' ) AS b4_desc_child_sex
, (r01_mums.v008::Integer - r21_kids.b3::Integer) AS v008_child_age_calc_months
, r21_kids.b8 AS b8_child_age
-- mother info
, r11_mums_info.v106 AS v106_mother_highest_ed_lvl
, (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs
    WHERE col_name='V106' AND surveyid=r21_kids.surveyid AND value=v106 AND value_type='ExplicitValue') AS v106_desc_mother_highest_ed_lvl
-- highest ed yr should just be a number but requested to add description
, r11_mums_info.v107 AS v107_mother_highest_ed_yr
, (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs
    WHERE col_name='V107' AND surveyid=r21_kids.surveyid AND value=v107 AND value_type='ExplicitValue') AS v107_desc_mother_highest_ed_yr
-- child health info
-- Note all should be straightforward yes/no but as there seem to be at least some with
-- slight variations like "according to mother" then have added desc for all
, (r43_health.h1) AS h1_has_health_card
, (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs
    WHERE col_name='H1' and surveyid=r21_kids.surveyid AND value=h1 AND value_type='ExplicitValue') AS h1_desc_has_health_card
, COALESCE(r43_health.h11, r4a_health.h11) AS h11_had_diarrhea_recently
,  (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs v
    WHERE col_name='H11' AND v.surveyid=r21_kids.surveyid
          AND value=COALESCE(r43_health.h11, r4a_health.h11)
          AND value_type='ExplicitValue')
    AS h11_desc_had_diarrhea_recently
, COALESCE(r43_health.h22, r4a_health.h22) AS h22_had_fever_recently
,  (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs v
    WHERE col_name='H22' AND v.surveyid=r21_kids.surveyid
          AND value=COALESCE(r43_health.h22, r4a_health.h22)
          AND value_type='ExplicitValue')
    AS hml22_desc_had_fever_recently
, COALESCE(r43_health.h31, r4a_health.h31) AS h31_had_cough_recently
, (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs v
    WHERE col_name='H31' AND v.surveyid=r21_kids.surveyid
          AND value=COALESCE(r43_health.h31, r4a_health.h31)
          AND value_type='ExplicitValue')
    AS hml31_desc_had_cough_recently
, COALESCE(r4a_health.h31b, r4a_health.h31b) AS h31b_short_rapid_breaths
, (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs v
    WHERE col_name='H31B' AND v.surveyid=r21_kids.surveyid
          AND value=COALESCE(r43_health.h31b, r4a_health.h31b)
          AND value_type='ExplicitValue')
    AS hml31b_desc_short_rapid_breaths
-- TODO check r95.S646 and r95.S533 for specific surveys
, COALESCE(r4a_health.h31c, r4a_health.h31c) AS h31c_problem_in_chest
,  (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs v
    WHERE col_name='H31C' AND v.surveyid=r21_kids.surveyid
          AND value=COALESCE(r43_health.h31c, r4a_health.h31c)
          AND value_type='ExplicitValue')
    AS hml31c_desc_problem_in_chest

-- child medication info
-- Vitamin A is in a question H34 but unusually this question got used for other shit too (cough syrup)
-- so only use this question in surveys where it means vit a TODO this is not complete, there are various CS ones
, CASE
    WHEN (r4a_health.surveyid IN
                   (SELECT DISTINCT surveyid FROM dhs_survey_specs.dhs_table_specs_flat WHERE name = 'H34'
                    AND label LIKE '%itamin A%'))
         OR
        (r43_health.surveyid IN
                   (SELECT DISTINCT surveyid FROM dhs_survey_specs.dhs_table_specs_flat WHERE name = 'H34'
                    AND label LIKE '%itamin A%'))
    THEN
      (COALESCE(r4a_health.h34, r43_health.h34) )
    ELSE NULL END
  AS h34_had_vitamin_a
-- DPT we only care about the third one, this time around TODO check nonstandard locations
,	CASE WHEN
		r43_health.h7::Integer BETWEEN 1 and 7 -- inclusive
	THEN 1 ELSE 0 END AS h7_received_dpt3
-- pneumococcal we only care about third one TODO there are some CS ones in REC95 but seem to be dupes
  ,	CASE WHEN
		r43_health.h56::Integer BETWEEN 1 and 7 -- inclusive
	THEN 1 ELSE 0 END AS h56_received_pneumocoocal
-- rotavirus really we want 2nd OR 3rd as sometimes there are 2 and sometimes 3 and we want the last, but meh,
-- not v likely someone would get 2 but not a 3rd when there's meant to be 3
-- rotavirus is more often in  rec95 so code them all out, having first checked all those columns don't get used for anything else
, CASE WHEN
      (COALESCE (r43_health.h58, r95_cs_vacc.data->>'rv2',r95_cs_vacc.data->>'s45rt2',
                 r95_cs_vacc.data->>'s506r2',r95_cs_vacc.data->>'s1508r2',r95_cs_vacc.data->>'sr2',
                 r95_cs_vacc.data->>'s508r2',r95_cs_vacc.data->>'r2'
      )::INTEGER BETWEEN 1 AND 7)
  THEN 1 ELSE 0 END as h58_received_rv2
-- measles we only care about 1 question and it seems to be always in rec43, not rec4a or CS
, CASE WHEN r43_health.h9::INTEGER BETWEEN 1 AND 7 THEN 1 ELSE 0 END AS h9_received_measles

-- child history info
, r41_maternity.m15 AS m15_place_of_delivery
, (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs
    WHERE col_name='M15' AND surveyid=r21_kids.surveyid AND value=m15 AND value_type='ExplicitValue') m15_desc_place_of_delivery
, r41_maternity.m17 AS m17_delivery_by_csection
, r41_maternity.m19 AS m19_birthweight_kg_3dec
, r41_maternity.m39 AS m39_times_ate_stuff_yesterday

-- child malaria stuff
, COALESCE(rhmh_malaria_stuffs.hml19, rh4_cs_sched.hml19) AS hml19_sleep_under_ever_treated_net
, rhmh_malaria_stuffs.hml20 AS hml_20_sleep_under_llin
, COALESCE(rhmh_malaria_stuffs.hml32, rhm2_malaria_stuffs.hml32) AS hml32_result_mal_smear_test
, (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs
    WHERE col_name='HML32' AND surveyid=r21_kids.surveyid
          AND value=COALESCE(rhmh_malaria_stuffs.hml32, rhm2_malaria_stuffs.hml32)
          AND value_type='ExplicitValue')
    AS hml32_desc_result_mal_smear_test
-- TODO note that in one survey, 446, the absolute idiots use this column for the rdt result!
, COALESCE(rhmh_malaria_stuffs.hml33, rhm2_malaria_stuffs.hml33) AS hml33_mal_smear_test_status
, (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs v
    WHERE col_name='HML33' AND v.surveyid=r21_kids.surveyid
          AND value=COALESCE(rhmh_malaria_stuffs.hml33, rhm2_malaria_stuffs.hml33)
          AND value_type='ExplicitValue')
    AS hml33_desc_mal_smear_test_status
-- TODO the RDT data occur in numerous CS places but those would have to be coded individually as they are
-- not columns uniquely about this, so can't just COALESCE them in
, COALESCE(rhmh_malaria_stuffs.hml35, rhm2_malaria_stuffs.hml35) AS hml35_result_mal_rapid_test
, (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs
    WHERE col_name='HML35' AND surveyid=r21_kids.surveyid
          AND value=COALESCE(rhmh_malaria_stuffs.hml35, rhm2_malaria_stuffs.hml35)
          AND value_type='ExplicitValue')
    AS hml35_desc_result_mal_rapid_test

-- child ht / weight stuff
, COALESCE(rh6_ch_ht_wt_hb.hc70, r44_ht_wt.hw70) AS hc70_ht_age_stdev_who
, COALESCE(rh6_ch_ht_wt_hb.hc71, r44_ht_wt.hw71) AS hc71_wt_age_stdev_who
, COALESCE(rh6_ch_ht_Wt_hb.hc72, r44_ht_wt.hw72) AS hc72_wt_ht_stdev_who
, COALESCE(rh6_ch_ht_wt_hb.hc5, r44_ht_wt.hw5) AS hc5_ht_age_stdev
, COALESCE(rh6_ch_ht_wt_hb.hc8, r44_ht_wt.hw8) AS hc8_wt_age_stdev
, COALESCE(rh6_ch_ht_wt_hb.hc11, r44_ht_wt.hw11) AS hc11_wt_ht_stdev
, COALESCE(rh6_ch_ht_wt_hb.hc56, r44_ht_wt.hw56) AS hc56_hb_adj_alt
, COALESCE(rh6_ch_ht_wt_hb.hc57, r44_ht_wt.hw57) AS hc57_anemia_level
, COALESCE(
    (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs
      WHERE col_name='HC57' AND surveyid=r21_kids.surveyid
      AND value=rh6_ch_ht_wt_hb.hc57),
    (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs
      WHERE col_name='HW57' AND surveyid=r21_kids.surveyid
      AND value=r44_ht_wt.hw57)) AS hc57_desc_anemia_level
FROM
  dhs_data_tables."REC21" r21_kids
INNER JOIN dhs_data_tables."REC01" r01_mums
  ON r21_kids.surveyid = r01_mums.surveyid AND r21_kids.caseid = r01_mums.caseid
INNER JOIN dhs_data_tables."REC11" r11_mums_info
    ON r21_kids.surveyid = r11_mums_info.surveyid AND r21_kids.caseid = r11_mums_info.caseid
-- the two "normal" child's health tables, REC43 up to phase 6 then REC4A in phase 7
LEFT OUTER JOIN dhs_data_tables."REC43" r43_health
      ON r21_kids.surveyid = r43_health.surveyid AND r21_kids.caseid = r43_health.caseid AND r21_kids.bidx=r43_health.hidx
LEFT OUTER JOIN  dhs_data_tables."REC4A" r4a_health
      ON r21_kids.surveyid = r4a_health.surveyid AND r21_kids.caseid = r4a_health.caseid AND r21_kids.bidx = r4a_health.hidxa
-- the children's height and weight table, some of this is also in hh-level tables
LEFT OUTER JOIN dhs_data_tables."REC44" r44_ht_wt
      ON r21_kids.surveyid = r44_ht_wt.surveyid AND r21_kids.caseid = r44_ht_wt.caseid AND r21_kids.bidx = r44_ht_wt.hwidx
-- the maternity table, i.e. about pregnancy and birth by child. Sometimes need to join a CS table for this
LEFT OUTER JOIN  dhs_data_tables."REC41" r41_maternity
      ON r21_kids.surveyid = r41_maternity.surveyid AND r21_kids.caseid = r41_maternity.caseid AND r21_kids.bidx=r41_maternity.midx
--LEFT OUTER JOIN dhs_data_tables."REC42" r42_health_bfeed
--      ON r21_kids.surveyid=r42_health_bfeed.surveyid AND r21_kids.caseid=r42_health_bfeed.caseid AND r21_kids.bidx=r42_health_bfeed.
LEFT OUTER JOIN dhs_data_tables."REC95" r95_cs_vacc
      ON r21_kids.surveyid = r95_cs_vacc.surveyid AND r21_kids.caseid=r95_cs_vacc.caseid AND r21_kids.bidx = r95_cs_vacc.idx95
LEFT OUTER JOIN dhs_data_tables."RECHMH" rhmh_malaria_stuffs
    ON r21_kids.surveyid = rhmh_malaria_stuffs.surveyid AND LEFT(r21_kids.caseid, -3) = rhmh_malaria_stuffs.hhid
      AND r21_kids.b16 = rhmh_malaria_stuffs.hmhidx
LEFT OUTER JOIN dhs_data_tables."RECH4" rh4_cs_sched
      ON r21_kids.surveyid = rh4_cs_sched.surveyid AND LEFT(r21_kids.caseid, -3) = rh4_cs_sched.hhid
        AND r21_kids.b16 = rh4_cs_sched.idxh4
LEFT OUTER JOIN dhs_data_tables."RECHM2" rhm2_malaria_stuffs
    ON r21_kids.surveyid = rhm2_malaria_stuffs.surveyid AND LEFT(r21_kids.caseid, -3) = rhm2_malaria_stuffs.hhid
      AND r21_kids.b16 = rhm2_malaria_stuffs.hmldx
LEFT OUTER JOIN dhs_data_tables."RECH6" rh6_ch_ht_wt_hb
    ON r21_kids.surveyid = rh6_ch_ht_wt_hb.surveyid AND LEFT(r21_kids.caseid, -3) = rh6_ch_ht_wt_hb.hhid AND r21_kids.b16 = rh6_ch_ht_wt_hb.hc0
LEFT OUTER JOIN dhs_data_locations.dhs_cluster_locs locs
      ON r01_mums.surveyid::INTEGER=locs.surveyid AND r01_mums.v001::INTEGER = locs.dhsclust
WHERE
  -- health data are only present for <5 but lucy wants all <= 5 even so
  r21_kids.b8::INTEGER <= 5
  AND r21_kids.surveyid = '253' --ki,k, '{SURVEYID}'
