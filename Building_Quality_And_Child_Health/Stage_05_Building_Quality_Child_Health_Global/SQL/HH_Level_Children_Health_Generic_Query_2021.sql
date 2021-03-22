-- THIS FILE REPRESENTS THE EXTRACTION COMPLETED FOR LUCY TUSTING AS AT 20190221 BY HSG, FOR AN ANALYSIS EXTENDING
-- THAT PUBLISHED PREVIOUSLY IN PLOS MED, ADDING NUMEROUS VARIABLES TO DO WITH CHILDREN'S VACCINATION, HEALTH, ETC.
-- IT PROVED TO BE AN EXTREMELY COMPLEX EXTRACTION TO PUT TOGETHER DRAWING INFORMATION FROM MANY DIFFERENT AREAS OF
-- THE SURVEY TABLES AND BRINGING IN RESULTS FROM SEVERAL SURVEYS WITH INFORMATION IN NON-STANDARD (COUNTRY-SPECIFIC)
-- LOCATIONS.

SELECT
-- survey and cluster identifiers
rh1_sched.surveyid AS surveyid
, svy.surveyyear AS surveyyear
, svy.surveyyearlabel AS surveyyear_lbl
, svy.releasedate AS survey_release_date
, svy.surveytype AS surveytype
, rh0_hh.hv000 AS hv000_ccode_phase
, svy.dhs_countrycode AS dhs_countrycode
, svy.countryname AS countryname
, rh0_hh.hv001 AS v001_cluster_id
, locs.dhsid AS cluster_id_full
, locs.latnum AS latitude
, locs.longnum AS longitude
-- household / individual identifiers
, rh0_hh.hhid AS hhid
, rh0_hh.hv002 AS hv002_hh_num
, rh0_hh.hv006 AS hv006_interview_mth
, rh0_hh.hv007 AS hv007_interview_yr
, rh0_hh.hv008 AS hv008_interview_cmc

-- child type identifiers
, rh1_sched.hvidx as child_hh_line_num --joining this to r21_kids.b16 so no point coalescing
, COALESCE(rh6_hh_lvl_ht_wt.hc64, r21_kids.bord) as birth_order --r21_kids.bord AS bord_birth_order
, COALESCE(rh1_sched.hv104, r21_kids.b4) as child_sex
, COALESCE((SELECT value_desc FROM dhs_survey_specs.dhs_value_descs
    WHERE col_name='HV104' AND surveyid=rh0_hh.surveyid AND value=hv104  AND value_type='ExplicitValue' ),
           (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs
    WHERE col_name='B4' AND surveyid=rh0_hh.surveyid AND value=b4  AND value_type='ExplicitValue' )) AS desc_child_sex
, r21_kids.b8 AS b8_child_age
, rh1_sched.hv105 AS hv105_child_age
-- TODO: not working
--, (rh0_hh.hv008::Integer - r21_kids.b3::Integer) AS hv008_child_age_cmc_calc_months
, r21_kids.b0 AS b0_child_is_twin -- 2021 Addition

-- mother info
-- this block can only be found in the mother-respondent level tables, so won't be present in all rows of this hh-level
-- dataset
, r01_mums.caseid AS mother_caseid
, r01_mums.v045b AS v045b_mothers_iview_lang -- 2021 Addition
, (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs -- 2021 Addition
    WHERE col_name='V045B' and surveyid=rh0_hh.surveyid AND value=v045b AND value_type='ExplicitValue') AS v045b_desc_mothers_iview_lang
, r01_mums.v045c AS v045c_mothers_native_lang -- 2021 Addition
, (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs -- 2021 Addition
    WHERE col_name='V045C' and surveyid=rh0_hh.surveyid AND value=v045c AND value_type='ExplicitValue') AS v045c_desc_mothers_native_lang
, r11_mums_info.v130 AS v130_religion -- 2021 Addition
, (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs
    WHERE col_name='V130' and surveyid=rh0_hh.surveyid AND value=v130 AND value_type='ExplicitValue') AS v130_desc_religion
, r11_mums_info.v131 AS ethnicity -- 2021 Addition
, (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs
    WHERE col_name='V131' and surveyid=rh0_hh.surveyid AND value=v131 AND value_type='ExplicitValue') AS v131_desc_ethnicity

-- 2021 new mothers info, this block of questions are found in the hh level tables so should be more widely present
, rh5_hh_lvl_wmn_ht_wt.ha1 AS ha1_mothers_age_yrs -- 2021 Addition
, rh5_hh_lvl_wmn_ht_wt.ha3 AS ha3_mothers_ht_cm -- 2021 Addition
, rh5_hh_lvl_wmn_ht_wt.ha4 AS ha4_mothers_ht_age_pctile -- 2021 Addition
, rh5_hh_lvl_wmn_ht_wt.ha5 AS ha5_mothers_ht_age_stdev -- 2021 Addition
, rh5_hh_lvl_wmn_ht_wt.ha6 AS ha6_mothers_ht_age_pct_ref_med -- 2021 Addition

-- this block of questions about the mother are found in both hh level and individual level tables, coalesce to get whichever
-- is actually present, prioritising the hh level responses (but they ought to match)
-- hc61 alone returns c.740k rows and coalescing both returns c.1.1M
, COALESCE(rh6_hh_lvl_ht_wt.hc61, r11_mums_info.v106) AS hc61_mother_highest_ed_lvl
, COALESCE((SELECT value_desc FROM dhs_survey_specs.dhs_value_descs
    WHERE col_name='HC61' AND surveyid=rh0_hh.surveyid AND value=hc61 AND value_type='ExplicitValue'),
           (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs
    WHERE col_name='V106' AND surveyid=rh0_hh.surveyid AND value=v106 AND value_type='ExplicitValue')) AS hc61_desc_mother_highest_ed_lvl
-- highest ed yr should just be a number but requested to add description
, COALESCE(rh6_hh_lvl_ht_wt.hc62, r11_mums_info.v107) AS hc62_mother_highest_ed_yr
, COALESCE((SELECT value_desc FROM dhs_survey_specs.dhs_value_descs
    WHERE col_name='HC62' AND surveyid=rh0_hh.surveyid AND value=hc62 AND value_type='ExplicitValue'),
           (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs
    WHERE col_name='V107' AND surveyid=rh0_hh.surveyid AND value=v107 AND value_type='ExplicitValue')) AS hc62_desc_mother_highest_ed_yr

-- child health info
-- Note all should be straightforward yes/no but as there seem to be at least some with
-- slight variations like "according to mother" then have added desc for all
-- This block of questions are all in individual-level tables only but have moved from REC43 to REC4A in more recent surveys
, (r43_health.h1) AS h1_has_health_card
, (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs
    WHERE col_name='H1' and surveyid=rh0_hh.surveyid AND value=h1 AND value_type='ExplicitValue') AS h1_desc_has_health_card
, COALESCE(NULLIF(r43_health.h11,''), NULLIF(r4a_health.h11,'')) AS h11_had_diarrhea_recently
,  (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs v
    WHERE col_name='H11' AND v.surveyid=rh0_hh.surveyid
          AND value=COALESCE(NULLIF(r43_health.h11,''), NULLIF(r4a_health.h11,''))
          AND value_type='ExplicitValue')
    AS h11_desc_had_diarrhea_recently
, COALESCE(NULLIF(r43_health.h22,''), NULLIF(r4a_health.h22,'')) AS h22_had_fever_recently
     -- max aggregation on h22 to avoid a specific issue with svy 291 which has a screwed up valueset for that
,  (SELECT max(value_desc) FROM dhs_survey_specs.dhs_value_descs v
    WHERE col_name='H22' AND v.surveyid=rh0_hh.surveyid
          AND value=COALESCE(NULLIF(r43_health.h22,''), NULLIF(r4a_health.h22,''))
          AND value_type='ExplicitValue') 
    AS h22_desc_had_fever_recently
, COALESCE(NULLIF(r43_health.h31,''), NULLIF(r4a_health.h31,'')) AS h31_had_cough_recently
, (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs v
    WHERE col_name='H31' AND v.surveyid=rh0_hh.surveyid
          AND value=COALESCE(NULLIF(r43_health.h31,''), NULLIF(r4a_health.h31,''))
          AND value_type='ExplicitValue')
    AS h31_desc_had_cough_recently
, COALESCE(NULLIF(r43_health.h31b,''), NULLIF(r4a_health.h31b,'')) AS h31b_short_rapid_breaths
, (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs v
    WHERE col_name='H31B' AND v.surveyid=rh0_hh.surveyid
          AND value=COALESCE(NULLIF(r43_health.h31b,''), NULLIF(r4a_health.h31b,''))
          AND value_type='ExplicitValue')
    AS h31b_desc_short_rapid_breaths
-- TODO check r95.S646 and r95.S533 for specific surveys
, COALESCE(NULLIF(r43_health.h31c,''), NULLIF(r4a_health.h31c,'')) AS h31c_problem_in_chest
,  (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs v
    WHERE col_name='H31C' AND v.surveyid=rh0_hh.surveyid
          AND value=COALESCE(NULLIF(r43_health.h31c,''), NULLIF(r4a_health.h31c,''))
          AND value_type='ExplicitValue')
    AS h31c_desc_problem_in_chest

-- child medication info
-- Here it starts to get more complicated, with e.g. more variations in spelling, CS locations, etc

-- Vitamin A is in a question H34 but unusually this question got used for other stuff too (cough syrup)
-- so only use this question in surveys where it means vit a
, COALESCE(
    (CASE
                WHEN (r4a_health.surveyid IN
                      (SELECT DISTINCT surveyid
                       FROM dhs_survey_specs.dhs_table_specs_flat
                       WHERE name = 'H34'
                         AND label LIKE '%itamin A%'))
                    OR
                     (r43_health.surveyid IN
                      (SELECT DISTINCT surveyid
                       FROM dhs_survey_specs.dhs_table_specs_flat
                       WHERE name = 'H34'
                         AND label LIKE '%itamin A%'))
                    THEN
                    (COALESCE(NULLIF(r4a_health.h34,''), NULLIF(r43_health.h34,'')))
                ELSE NULL END
        )
    -- I found these two CS locations for Vit A, but actually these surveys don't have REC21.B16 so cannot
    -- be joined to the HH level data anyway, so commented out for now
    --,(CASE WHEN r94_cs_maternity.surveyid='61' THEN r94_cs_maternity.data->>'s460a' ELSE NULL END)
    --,(CASE WHEN r95_cs_vacc.surveyid='151' THEN r95_cs_vacc.data->>'s448' ELSE NULL END)
    ,NULL
    )
  AS h34_had_vitamin_a
-- DPT we only care about the third one, this time around
,	CASE
    WHEN NULLIF(r43_health.h7,'') IS NULL THEN NULL
		WHEN r43_health.h7::Integer BETWEEN 1 and 7 -- inclusive
	THEN 1 ELSE 0 END AS h7_received_dpt3
-- pneumococcal we only care about third one. NB there are some CS ones in REC95 but seem to be dupes
  ,	CASE
     WHEN NULLIF(r43_health.h56,'') IS NULL THEN NULL
		 WHEN r43_health.h56::Integer BETWEEN 1 and 7 -- inclusive
	  THEN 1 ELSE 0 END AS h56_received_pneumococcal
-- Rotavirus really we want 2nd OR 3rd as sometimes there are 2 and sometimes 3 and we want the last, but meh,
-- not v likely someone would get 2 but not a 3rd when there's meant to be 3
-- Rotavirus more commonly occurs in (CS) REC95, so code them all out, having first checked all those columns
-- don't get used for anything else (so not actually filtering to surveyids here)
, CASE
     WHEN (COALESCE (
            (NULLIF(r43_health.h58, '')),
            r95_cs_vacc_j.data->>'rv2', r95_cs_vacc_j.data->>'s45rt2',
            r95_cs_vacc_j.data->>'s506r2', r95_cs_vacc_j.data->>'s1508r2', r95_cs_vacc_j.data->>'sr2' ,
            r95_cs_vacc_j.data->>'s508r2', r95_cs_vacc_j.data->>'r2'
      )) IS NULL THEN NULL
     WHEN (COALESCE (
            (NULLIF(r43_health.h58, '')),
            r95_cs_vacc_j.data->>'rv2',r95_cs_vacc_j.data->>'s45rt2',
            r95_cs_vacc_j.data->>'s506r2',r95_cs_vacc_j.data->>'s1508r2',r95_cs_vacc_j.data->>'sr2',
            r95_cs_vacc_j.data->>'s508r2',r95_cs_vacc_j.data->>'r2'
      )::INTEGER BETWEEN 1 AND 7)
  THEN 1 ELSE 0 END as h58_received_rv2
-- measles is a bit easier, we only care about 1 question and it seems to be always in rec43, not rec4a or CS
, CASE
    WHEN NULLIF(r43_health.h9,'') IS NULL THEN NULL
    WHEN r43_health.h9::INTEGER BETWEEN 1 AND 7
  THEN 1 ELSE 0 END AS h9_received_measles

-- child birth history
-- 2021 changes: m15 and m17 no longer required
--, r41_maternity.m15 AS m15_place_of_delivery
--, (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs
--   WHERE col_name='M15' AND surveyid=rh0_hh.surveyid AND value=m15 AND value_type='ExplicitValue')
--   AS m15_desc_place_of_delivery
--, r41_maternity.m17 AS m17_delivery_by_csection
, r41_maternity.m19 AS m19_birthweight_kg_3dec
, r41_maternity.m39 AS m39_times_ate_stuff_yesterday

-- child malaria stuff - almost always found exclusively on the HH level side of things
, COALESCE(NULLIF(rhmh_hh_lvl_mal.hml12,''), rh4_cs_sched_j.data->>'hml12')
    AS hml12_type_net_slept_last_night
, (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs
    WHERE col_name='HML12' AND surveyid=rh0_hh.surveyid
          AND value=COALESCE(NULLIF(rhmh_hh_lvl_mal.hml12,''), rh4_cs_sched_j.data->>'hml12')
          AND value_type='ExplicitValue')
    AS hml12_desc_type_net_slept_last_night
, COALESCE(NULLIF(rhmh_hh_lvl_mal.hml19,''), rh4_cs_sched_j.data->>'hml19')
    AS hml19_sleep_under_ever_treated_net
, rhmh_hh_lvl_mal.hml20
    AS hml_20_sleep_under_llin
, COALESCE(
      NULLIF(rhmh_hh_lvl_mal.hml32,''),
      NULLIF(rhm2_hh_lvl_mal.hml32,''),
      NULLIF(rhmh_hh_lvl_mal.shmala,''), -- checked, is unique meaning at present so no surveyid filter
      NULLIF(rhmc_cs_hh_lvl_mal.stestch,''), -- checked, is unique meaning at present so no surveyid filter
      COALESCE((CASE WHEN rh6_hh_lvl_ht_wt.surveyid='338' THEN rh6_hh_lvl_ht_wt.sh214r ELSE NULL END), NULL)
  ) AS hml32_result_mal_smear_test
, (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs
    WHERE col_name='HML32' AND surveyid=rh0_hh.surveyid
          AND value=COALESCE(NULLIF(rhmh_hh_lvl_mal.hml32,''), NULLIF(rhm2_hh_lvl_mal.hml32,'')
                             --, rhmh_hh_lvl_mal.shmala,
                             -- rhmc_cs_hh_lvl_mal.stestch,
                             -- COALESCE((CASE WHEN rh6_hh_lvl_ht_wt.surveyid='338' THEN rh6_hh_lvl_ht_wt.sh214r ELSE NULL END), NULL)
                             -- no point in these without changing the col_name clause too and there's a limit to the patience
                            )
          AND value_type='ExplicitValue')
    AS hml32_desc_result_mal_smear_test
-- Note that in one survey, 446, they use this column for the rdt result! eyeroll...
, COALESCE((CASE WHEN rhmh_hh_lvl_mal.surveyid != '446' THEN NULLIF(rhmh_hh_lvl_mal.hml33,'') ELSE NULL END),
           NULLIF(rhm2_hh_lvl_mal.hml33,'')) AS hml33_mal_smear_test_status
, (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs v
    WHERE col_name='HML33' AND v.surveyid=rh0_hh.surveyid
          AND value=COALESCE(NULLIF(rhmh_hh_lvl_mal.hml33,''), NULLIF(rhm2_hh_lvl_mal.hml33,''))
          AND value_type='ExplicitValue')
    AS hml33_desc_mal_smear_test_status
-- Note the RDT data occur in numerous CS places but those would have to be coded individually as they are
-- not columns uniquely about this, so can't just COALESCE them in but have to use a surveyid filter for each
-- affected survey. This is where it REALLY starts to get frustratingly tedious
, COALESCE(NULLIF(rhmh_hh_lvl_mal.hml35,''),
          NULLIF(rhmh_hh_lvl_mal.sh418,''), -- this column only appears once, in 337, with the correct meaning
          NULLIF(rhm2_hh_lvl_mal.hml35,''),
          -- a load of unnecessary COALESCEs wrapping the CASEs, i know
          -- the one survey where the _idiots_ use hml33 for the test result
          COALESCE((CASE WHEN rhmh_hh_lvl_mal.surveyid='446' THEN NULLIF(rhmh_hh_lvl_mal.hml33,'') ELSE NULL END), NULL),
          -- SH119 has varying meanings so must be filtered to svy 323 only
          -- Honestly what is the point of a country-specific non standard variable name if you re-use it to mean
          -- totally different things. Guys.
          COALESCE((CASE WHEN rhmc_cs_hh_lvl_mal.surveyid='323' THEN NULLIF(rhmc_cs_hh_lvl_mal.sh119,'') ELSE NULL END), NULL),
          -- SH212 has varying meaning so must be filtered to svy 338 only; in that svy it is also in S212
          COALESCE((CASE WHEN rh6_hh_lvl_ht_wt.surveyid='338' THEN NULLIF(rh6_hh_lvl_ht_wt.sh212,'') ELSE NULL END), NULL),
          -- Same for SH214 / svy 484... really do these people not think at all
          COALESCE((CASE WHEN rh6_hh_lvl_ht_wt.surveyid='484' THEN NULLIF(rh6_hh_lvl_ht_wt.sh214,'') ELSE NULL END), NULL),
          -- ... and SH511 / svy 304 hate hate hate them all how does an organisation this big get so dumb
          COALESCE((CASE WHEN rh6_hh_lvl_ht_wt.surveyid='304' THEN NULLIF(rh6_hh_lvl_ht_wt.sh511,'') ELSE NULL END), NULL))
  AS hml35_result_mal_rapid_test
-- this won't produce descs for the non-standard col names. I'm not typing all that shit out again
, (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs
    WHERE col_name='HML35' AND surveyid=rh0_hh.surveyid
          AND value=COALESCE(NULLIF(rhmh_hh_lvl_mal.hml35,''), NULLIF(rhm2_hh_lvl_mal.hml35,''))
          AND value_type='ExplicitValue')
    AS hml35_desc_result_mal_rapid_test

-- child ht / weight stuff
-- Back to some semblance of a sane, consistent schema
-- These variables are all present both in the HH-level table (RECH6) and the individual level
-- table REC44. As before, use both, prioritising HH-level in case of mismatch
, COALESCE(NULLIF(rh6_hh_lvl_ht_wt.hc2,''), NULLIF(r44_ch_lvl_ht_wt.hw2,'')) AS hc2_weight_kg -- 2021 Addition
, COALESCE(NULLIF(rh6_hh_lvl_ht_wt.hc3,''), NULLIF(r44_ch_lvl_ht_wt.hw3,'')) AS hc3_height_cm -- 2021 Addition
, COALESCE(NULLIF(rh6_hh_lvl_ht_wt.hc15,''), NULLIF(r44_ch_lvl_ht_wt.hw15,'')) AS hc15_lying_or_standing -- 2021 Addition
, COALESCE(
    (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs
      WHERE col_name='HC15' AND surveyid=rh6_hh_lvl_ht_wt.surveyid
      AND value=rh6_hh_lvl_ht_wt.hc15),
    (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs
      WHERE col_name='HW15' AND surveyid=r44_ch_lvl_ht_wt.surveyid
      AND value=r44_ch_lvl_ht_wt.hw15)) AS hc15_desc_lying_or_standing -- 2021 Addition
, COALESCE(NULLIF(rh6_hh_lvl_ht_wt.hc4,''), NULLIF(r44_ch_lvl_ht_wt.hw4,'')) AS hc4_ht_age_pctile -- 2021 Addition
--, COALESCE(rh6_hh_lvl_ht_wt.hc5, r44_ch_lvl_ht_wt.hw5) AS hc5_ht_age_stdev -- 2021 Addition
, COALESCE(NULLIF(rh6_hh_lvl_ht_wt.hc6,''), NULLIF(r44_ch_lvl_ht_wt.hw6,'')) AS hc6_ht_age_pct_ref_med -- 2021 Addition
, COALESCE(NULLIF(rh6_hh_lvl_ht_wt.hc7,''), NULLIF(r44_ch_lvl_ht_wt.hw7,'')) AS hc7_wt_age_pctile -- 2021 Addition
, COALESCE(NULLIF(rh6_hh_lvl_ht_wt.hc73,''), NULLIF(r44_ch_lvl_ht_wt.hw73,'')) AS hc73_bmi_stdev_who -- 2021 Addition
, COALESCE(NULLIF(rh6_hh_lvl_ht_wt.hc9, ''), NULLIF(r44_ch_lvl_ht_wt.hw9,'')) AS hc9_wt_age_pct_ref_med -- 2021 Addition
, COALESCE(NULLIF(rh6_hh_lvl_ht_wt.hc10,''), NULLIF(r44_ch_lvl_ht_wt.hw10,'')) AS hc10_wt_ht_pctile -- 2021 Addition
, COALESCE(NULLIF(rh6_hh_lvl_ht_wt.hc12,''), NULLIF(r44_ch_lvl_ht_wt.hw12,'')) AS hc12_wt_ht_pct_ref_med -- 2021 Addition

, COALESCE(NULLIF(rh6_hh_lvl_ht_wt.hc70,''), NULLIF(r44_ch_lvl_ht_wt.hw70,'')) AS hc70_ht_age_stdev_who
, COALESCE(NULLIF(rh6_hh_lvl_ht_wt.hc71,''), NULLIF(r44_ch_lvl_ht_wt.hw71,'')) AS hc71_wt_age_stdev_who
, COALESCE(NULLIF(rh6_hh_lvl_ht_wt.hc72,''), NULLIF(r44_ch_lvl_ht_wt.hw72,'')) AS hc72_wt_ht_stdev_who
, COALESCE(NULLIF(rh6_hh_lvl_ht_wt.hc5,''), NULLIF(r44_ch_lvl_ht_wt.hw5,'')) AS hc5_ht_age_stdev
, COALESCE(NULLIF(rh6_hh_lvl_ht_wt.hc8,''), NULLIF(r44_ch_lvl_ht_wt.hw8,'')) AS hc8_wt_age_stdev
, COALESCE(NULLIF(rh6_hh_lvl_ht_wt.hc11,''), NULLIF(r44_ch_lvl_ht_wt.hw11,'')) AS hc11_wt_ht_stdev
, COALESCE(NULLIF(rh6_hh_lvl_ht_wt.hc56,''), NULLIF(r44_ch_lvl_ht_wt.hw56,'')) AS hc56_hb_adj_alt
, COALESCE(NULLIF(rh6_hh_lvl_ht_wt.hc57,''), NULLIF(r44_ch_lvl_ht_wt.hw57,'')) AS hc57_anemia_level
, COALESCE(
    (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs
      WHERE col_name='HC57' AND surveyid=r21_kids.surveyid
      AND value=rh6_hh_lvl_ht_wt.hc57),
    (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs
      WHERE col_name='HW57' AND surveyid=r21_kids.surveyid
      AND value=r44_ch_lvl_ht_wt.hw57)) AS hc57_desc_anemia_level

-- END OF OUTPUT COLUMN SELECT CLAUSES
-- BEGIN TABLE JOIN LISTINGS
FROM
-- We need to make the hh schedule table the main basis for the extraction as using REC21 missed many children,
-- believed to be in cases where the mother (who is responsible for answering REC21 questions) maybe wasn't interviewed
-- but someone else in the HH was and answered those questions
  dhs_data_tables."RECH1" rh1_sched
-- Join all the other required tables to this, where possible

-- Household schedule
-- There will always be a household entry corresponding to a household schedule entry, unless something's gone very
-- wrong, so use INNER join for this
INNER JOIN dhs_data_tables."RECH0" rh0_hh
  ON rh1_sched.surveyid = rh0_hh.surveyid AND rh1_sched.hhid = rh0_hh.hhid

-- Now join all the required household level tables providing required info. Use LEFT OUTER joins for all of these as
-- they're not always present for each survey. At least the join columns _usually_ remain constant...

-- Malaria: By household member
LEFT OUTER JOIN dhs_data_tables."RECHMH" rhmh_hh_lvl_mal
    ON rh1_sched.surveyid = rhmh_hh_lvl_mal.surveyid AND rh1_sched.hhid = rhmh_hh_lvl_mal.hhid
           -- two possibilities for line number in RECHMH, only one in use at any one time
      AND rh1_sched.hvidx = COALESCE(rhmh_hh_lvl_mal.hmhidx, rhmh_hh_lvl_mal.idxhml)

-- .. with this one known exception where the FUCKWOMBLES called the index column something totally incorrect
--LEFT OUTER JOIN dhs_data_tables."RECHMH" rhmh_hh_lvl_mal_231
--    ON rh1_sched.surveyid = rhmh_hh_lvl_mal_231.surveyid AND rh1_sched.hhid = rhmh_hh_lvl_mal_231.hhid
--      AND rh1_sched.hvidx = rhmh_hh_lvl_mal_231.idxhml -- idxhml? what tf?

-- Additional Malaria Variables (or Childrens Malaria Tests)
LEFT OUTER JOIN dhs_data_tables."RECHM2" rhm2_hh_lvl_mal
    ON rh1_sched.surveyid = rhm2_hh_lvl_mal.surveyid AND rh1_sched.hhid = rhm2_hh_lvl_mal.hhid
      AND rh1_sched.hvidx = rhm2_hh_lvl_mal.hmldx

-- Malaria: country specific variables; or Malaria table for children
LEFT OUTER JOIN dhs_data_tables."RECHMC" rhmc_cs_hh_lvl_mal
    ON rh1_sched.surveyid = rhmc_cs_hh_lvl_mal.surveyid AND rh1_sched.hhid = rhmc_cs_hh_lvl_mal.hhid
      AND rh1_sched.hvidx = rhmc_cs_hh_lvl_mal.idxhmc

-- Survey specific Household schedule variables. This table has been stored with a JSONB data field
LEFT OUTER JOIN dhs_data_tables."RECH4" rh4_cs_sched_j
    ON rh1_sched.surveyid = rh4_cs_sched_j.surveyid AND rh1_sched.hhid = rh4_cs_sched_j.hhid
        AND rh1_sched.hvidx = rh4_cs_sched_j.idxh4

-- Women Height/Weight/Haemoglobin
-- 2021 Addition
LEFT OUTER JOIN dhs_data_tables."RECH5" rh5_hh_lvl_wmn_ht_wt
      ON rh1_sched.surveyid = rh5_hh_lvl_wmn_ht_wt.surveyid AND rh1_sched.hhid = rh5_hh_lvl_wmn_ht_wt.hhid
        -- hv112 is the mother's line number reference in the schedule table, for schedule entries corresponding
        -- to children, which is the ones we're looking at
        AND rh1_sched.hv112 = rh5_hh_lvl_wmn_ht_wt.ha0

-- Children Height/Weight/Haemoglobin
LEFT OUTER JOIN dhs_data_tables."RECH6" rh6_hh_lvl_ht_wt
    ON rh1_sched.surveyid = rh6_hh_lvl_ht_wt.surveyid AND rh1_sched.hhid = rh6_hh_lvl_ht_wt.hhid
       AND rh1_sched.hvidx = rh6_hh_lvl_ht_wt.hc0


-- Now, we still need to join through to the child-level tables when possible as the health / vaccine info is only present
-- there, in REC43/REC4A. We need to go via REC21, the main child-level listing, to get the index into REC43/4A.
-- There are two main cases where this won't work. Either when the child-level info isn't present because a woman (mother)
-- seemingly wasn't interviewed; or (in earlier surveys) the necessary reference to the child's line number in the HH schedule
-- (in column REC21.B16) simply wasn't present, so there's no way to join the two sides of the survey.
--    (NB: In these cases it is still possible to join to the mother, whose line number is present in REC01.V003, but we can't
--    match the specific child (via BIDX or BORD) to anything on the HH schedule side)
-- Again as we use an outer join we still get the hh-level info even when the child-level info isn't present.

-- Reproduction (the basic index of children under 5 off which all the other child-level tables like REC43 hang via
-- CASEID and BIDX)
LEFT OUTER JOIN  dhs_data_tables."REC21" r21_kids
    ON rh1_sched.surveyid = r21_kids.surveyid
       AND rh1_sched.hhid = LEFT(r21_kids.caseid, -3) -- the risky-seeming bit, but no known issues so far...
       AND rh1_sched.hvidx=r21_kids.b16

-- Child's health (in early surveys) / child's health and vaccinations (in later surveys) / child's vaccinations (only)
-- (in phase7+ surveys)
LEFT OUTER JOIN dhs_data_tables."REC43" r43_health
      ON r21_kids.surveyid = r43_health.surveyid AND r21_kids.caseid = r43_health.caseid
             AND r21_kids.bidx=r43_health.hidx

-- Child's health (other than vaccinations) in phase 7+
LEFT OUTER JOIN  dhs_data_tables."REC4A" r4a_health
      ON r21_kids.surveyid = r4a_health.surveyid AND r21_kids.caseid = r4a_health.caseid
             AND r21_kids.bidx = r4a_health.hidxa

-- the child-level children height and weight table, some of this info is also in hh-level tables i.e. RECH6;
-- we will use both to ensure we get from either location
LEFT OUTER JOIN dhs_data_tables."REC44" r44_ch_lvl_ht_wt
      ON r21_kids.surveyid = r44_ch_lvl_ht_wt.surveyid AND r21_kids.caseid = r44_ch_lvl_ht_wt.caseid
         AND r21_kids.bidx = r44_ch_lvl_ht_wt.hwidx

-- The individual level mother's table-  parent of the child, both literally and schematically, but can still do
-- an outer join for the type of use we're doing (but an inner join ought to be safe for this one)
LEFT OUTER JOIN dhs_data_tables."REC01" r01_mums
    ON r21_kids.surveyid = r01_mums.surveyid AND r21_kids.caseid = r01_mums.caseid

-- The individual level mother's extended data table-  parent of the child, both literally and schematically
-- (again an inner join ought to be safe for this one but stick with outer for consistency)
LEFT OUTER JOIN dhs_data_tables."REC11" r11_mums_info
    ON r21_kids.surveyid = r11_mums_info.surveyid AND r21_kids.caseid = r11_mums_info.caseid

-- the maternity table, i.e. about pregnancy and birth factors as relating to a specific child.
-- Sometimes need to join a CS table for this.
LEFT OUTER JOIN  dhs_data_tables."REC41" r41_maternity
      ON r21_kids.surveyid = r41_maternity.surveyid AND r21_kids.caseid = r41_maternity.caseid
         AND r21_kids.bidx=r41_maternity.midx

-- country-specific child's health / child's health and vaccinations. Stored as a JSONB data column
LEFT OUTER JOIN dhs_data_tables."REC95" r95_cs_vacc_j
      ON r21_kids.surveyid = r95_cs_vacc_j.surveyid AND r21_kids.caseid=r95_cs_vacc_j.caseid
             AND r21_kids.bidx = r95_cs_vacc_j.idx95

-- country-specific maternity
-- not using for now as svy61 is missing REC21.B16 anyway so can't join to output
--LEFT OUTER JOIN dhs_data_tables."REC94" r94_cs_maternity_j -- 2021 addition to get Vit A for svy 61
--     ON r21_kids.surveyid = r94_cs_maternity_j.surveyid AND r21_kids.caseid=r94_cs_maternity_j.caseid
--             AND r21_kids.bidx = r94_cs_maternity_j.idx94

-- the spatial table with the "GPS data" i.e. cluster locations. Has lat/lon in numeric fields as well as
-- an actual geometry field. NB as it was loaded from shapefiles directly it ended up with surveyid and cluster num
-- being proper integer datatypes so need a cast here
LEFT OUTER JOIN dhs_data_locations.dhs_cluster_locs locs
      ON rh0_hh.surveyid::INTEGER=locs.surveyid AND rh0_hh.hv001::INTEGER = locs.dhsclust

-- the survey metadata table, dumped from the DHS API survey listing
LEFT OUTER JOIN dhs_survey_specs.dhs_survey_listing svy
      ON rh0_hh.surveyid::INTEGER=svy.surveynum

-- we will run this query for one survey at a time
WHERE
  -- health data are only present for <5 but lucy wants all <= 5 even so
  rh1_sched.hv105::INTEGER <= 5
  AND rh0_hh.surveyid = '{SURVEYID}'