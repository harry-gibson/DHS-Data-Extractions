-- THIS FILE REPRESENTS THE EXTRACTION COMPLETED FOR LUCY TUSTING AS AT 20190221 BY HSG, FOR AN ANALYSIS EXTENDING
-- THAT PUBLISHED PREVIOUSLY IN PLOS MED, ADDING NUMEROUS VARIABLES TO DO WITH CHILDREN'S VACCINATION, HEALTH, ETC.
-- IT PROVED TO BE AN EXTREMELY COMPLEX EXTRACTION TO PUT TOGETHER DRAWING INFORMATION FROM MANY DIFFERENT AREAS OF
-- THE SURVEY TABLES AND BRINGING IN RESULTS FROM SEVERAL SURVEYS WITH INFORMATION IN NON-STANDARD (COUNTRY-SPECIFIC)
-- LOCATIONS.

SELECT
-- cluster type identifiers
rh1_sched.surveyid AS surveynum
, rh0_hh.hv000 AS hv000_ccode_phase
--, locs.dhscc AS dhs_countrycode
, svy.dhs_countrycode AS dhs_countrycode
, svy.countryname AS countryname
, svy.surveytype AS surveytype
, svy.surveyyearlabel AS surveyyear_lbl
, svy.releasedate AS survey_release_date
, rh0_hh.hv001 AS v001_cluster_id
, locs.dhsid AS cluster_id_full
, locs.latnum AS latitude
, locs.longnum AS longitude
-- woman/individual type identifiers
, r01_mums.caseid AS woman_caseid
, rh0_hh.hhid AS hhid
, rh0_hh.hv002 AS hv002_hh_num
, rh0_hh.hv006 AS hv006_interview_mth
, rh0_hh.hv007 AS hv007_interview_yr
, rh0_hh.hv008 AS hv008_interview_cmc
-- child type identifiers
, COALESCE(rh6_hh_lvl_ht_wt.hc64, r21_kids.bord) as birth_order --r21_kids.bord AS bord_birth_order
, rh1_sched.hvidx as child_hh_line_num --joining this to r21_kids.b16 so no point coalescing
-- TODO: not working
  , COALESCE(rh1_sched.hv104, r21_kids.b4) as child_sex--r21_kids.b4 AS b4_child_sex
-- child info
, COALESCE((SELECT value_desc FROM dhs_survey_specs.dhs_value_descs
    WHERE col_name='HV104' AND surveyid=rh0_hh.surveyid AND value=hv104  AND value_type='ExplicitValue' ),
           (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs
    WHERE col_name='B4' AND surveyid=rh0_hh.surveyid AND value=b4  AND value_type='ExplicitValue' )) AS desc_child_sex
-- TODO: not working
  , (rh0_hh.hv008::Integer - r21_kids.b3::Integer) AS hv008_child_age_cmc_calc_months
, rh1_sched.hv105 AS hv105_child_age
, r21_kids.b8 AS b8_child_age
-- mother info
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
, (r43_health.h1) AS h1_has_health_card
, (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs
    WHERE col_name='H1' and surveyid=rh0_hh.surveyid AND value=h1 AND value_type='ExplicitValue') AS h1_desc_has_health_card
, COALESCE(r43_health.h11, r4a_health.h11) AS h11_had_diarrhea_recently
,  (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs v
    WHERE col_name='H11' AND v.surveyid=rh0_hh.surveyid
          AND value=COALESCE(r43_health.h11, r4a_health.h11)
          AND value_type='ExplicitValue')
    AS h11_desc_had_diarrhea_recently
, COALESCE(r43_health.h22, r4a_health.h22) AS h22_had_fever_recently
,  (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs v
    WHERE col_name='H22' AND v.surveyid=rh0_hh.surveyid
          AND value=COALESCE(r43_health.h22, r4a_health.h22)
          AND value_type='ExplicitValue')
    AS hml22_desc_had_fever_recently
, COALESCE(r43_health.h31, r4a_health.h31) AS h31_had_cough_recently
, (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs v
    WHERE col_name='H31' AND v.surveyid=rh0_hh.surveyid
          AND value=COALESCE(r43_health.h31, r4a_health.h31)
          AND value_type='ExplicitValue')
    AS hml31_desc_had_cough_recently
, COALESCE(r43_health.h31b, r4a_health.h31b) AS h31b_short_rapid_breaths
, (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs v
    WHERE col_name='H31B' AND v.surveyid=rh0_hh.surveyid
          AND value=COALESCE(r43_health.h31b, r4a_health.h31b)
          AND value_type='ExplicitValue')
    AS hml31b_desc_short_rapid_breaths
-- TODO check r95.S646 and r95.S533 for specific surveys
, COALESCE(r43_health.h31c, r4a_health.h31c) AS h31c_problem_in_chest
,  (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs v
    WHERE col_name='H31C' AND v.surveyid=rh0_hh.surveyid
          AND value=COALESCE(r43_health.h31c, r4a_health.h31c)
          AND value_type='ExplicitValue')
    AS hml31c_desc_problem_in_chest

-- child medication info
-- Vitamin A is in a question H34 but unusually this question got used for other stuff too (cough syrup)
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
,	CASE
    WHEN r43_health.h7 IS NULL THEN NULL
		WHEN r43_health.h7::Integer BETWEEN 1 and 7 -- inclusive
	THEN 1 ELSE 0 END AS h7_received_dpt3
-- pneumococcal we only care about third one TODO there are some CS ones in REC95 but seem to be dupes
  ,	CASE
     WHEN r43_health.h56 IS NULL THEN NULL
		 WHEN r43_health.h56::Integer BETWEEN 1 and 7 -- inclusive
	  THEN 1 ELSE 0 END AS h56_received_pneumococcal
-- rotavirus really we want 2nd OR 3rd as sometimes there are 2 and sometimes 3 and we want the last, but 
-- as it is not v likely someone would get 2 but not a 3rd when there's meant to be 3, we will check dose 2.
-- rotavirus is more often in  rec95 so code them all out, having first checked all those columns don't get used for anything else
, CASE
     WHEN (COALESCE (r43_health.h58, r95_cs_vacc.data->>'rv2',r95_cs_vacc.data->>'s45rt2',
                 r95_cs_vacc.data->>'s506r2',r95_cs_vacc.data->>'s1508r2',r95_cs_vacc.data->>'sr2',
                 r95_cs_vacc.data->>'s508r2',r95_cs_vacc.data->>'r2'
      )) IS NULL THEN NULL
     WHEN (COALESCE (r43_health.h58, r95_cs_vacc.data->>'rv2',r95_cs_vacc.data->>'s45rt2',
                 r95_cs_vacc.data->>'s506r2',r95_cs_vacc.data->>'s1508r2',r95_cs_vacc.data->>'sr2',
                 r95_cs_vacc.data->>'s508r2',r95_cs_vacc.data->>'r2'
      )::INTEGER BETWEEN 1 AND 7)
  THEN 1 ELSE 0 END as h58_received_rv2
-- measles we only care about 1 question and it seems to be always in rec43, not rec4a or CS
, CASE
    WHEN r43_health.h9 IS NULL THEN NULL
    WHEN r43_health.h9::INTEGER BETWEEN 1 AND 7
  THEN 1 ELSE 0 END AS h9_received_measles

-- child history info
, r41_maternity.m15 AS m15_place_of_delivery
, (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs
    WHERE col_name='M15' AND surveyid=rh0_hh.surveyid AND value=m15 AND value_type='ExplicitValue')
    AS m15_desc_place_of_delivery
, r41_maternity.m17 AS m17_delivery_by_csection
, r41_maternity.m19 AS m19_birthweight_kg_3dec
, r41_maternity.m39 AS m39_times_ate_stuff_yesterday

-- child malaria stuff
, COALESCE(rhmh_hh_lvl_mal.hml12, rh4_cs_sched.hml12, rh4_cs_sched_j.data->>'hml12')
    AS hml12_type_net_slept_last_night
, (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs
    WHERE col_name='HML12' AND surveyid=rh0_hh.surveyid
          AND value=COALESCE(rhmh_hh_lvl_mal.hml12, rh4_cs_sched.hml12, rh4_cs_sched_j.data->>'hml12')
          AND value_type='ExplicitValue')
    AS hml12_desc_type_net_slept_last_night
, COALESCE(rhmh_hh_lvl_mal.hml19, rh4_cs_sched.hml19)
    AS hml19_sleep_under_ever_treated_net
, rhmh_hh_lvl_mal.hml20
    AS hml_20_sleep_under_llin
, COALESCE(
      rhmh_hh_lvl_mal.hml32,
      rhm2_hh_lvl_mal.hml32,
      rhmh_hh_lvl_mal.shmala, -- is unique meaning at present
      rhmc_cs_hh_lvl_mal.stestch, -- is unique meaning at present
      COALESCE((CASE WHEN rh6_hh_lvl_ht_wt.surveyid='338' THEN rh6_hh_lvl_ht_wt.sh214r ELSE NULL END), NULL)
  ) AS hml32_result_mal_smear_test
, (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs
    WHERE col_name='HML32' AND surveyid=rh0_hh.surveyid
          AND value=COALESCE(rhmh_hh_lvl_mal.hml32, rhm2_hh_lvl_mal.hml32
                             --, rhmh_hh_lvl_mal.shmala, -- no point in these without changing the col_name clause too and cba
                             -- rhmc_cs_hh_lvl_mal.stestch,
                             -- COALESCE((CASE WHEN rh6_hh_lvl_ht_wt.surveyid='338' THEN rh6_hh_lvl_ht_wt.sh214r ELSE NULL END), NULL)
                            )
          AND value_type='ExplicitValue')
    AS hml32_desc_result_mal_smear_test
-- Note that in one survey, 446, this column is used for the rdt result!
, COALESCE((CASE WHEN rhmh_hh_lvl_mal.surveyid != '446' THEN rhmh_hh_lvl_mal.hml33 ELSE NULL END),
           rhm2_hh_lvl_mal.hml33) AS hml33_mal_smear_test_status
, (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs v
    WHERE col_name='HML33' AND v.surveyid=rh0_hh.surveyid
          AND value=COALESCE(rhmh_hh_lvl_mal.hml33, rhm2_hh_lvl_mal.hml33)
          AND value_type='ExplicitValue')
    AS hml33_desc_mal_smear_test_status
-- Note the RDT data occur in numerous CS places but those would have to be coded individually as they are
-- not columns uniquely about this, so can't just COALESCE them in
, COALESCE(rhmh_hh_lvl_mal.hml35,
          rhmh_hh_lvl_mal.sh418, -- this column only appears once, in 337, with the correct meaning
          rhm2_hh_lvl_mal.hml35,
          -- a load of unnecessary COALESCEs wrapping the CASEs, i know
          -- the one survey where hml33 is used for the test RESULT(!)
          COALESCE((CASE WHEN rhmh_hh_lvl_mal.surveyid='446' THEN rhmh_hh_lvl_mal.hml33 ELSE NULL END), NULL),
          -- SH119 has varying meanings so must be filtered to svy 323 only
          COALESCE((CASE WHEN rhmc_cs_hh_lvl_mal.surveyid='323' THEN rhmc_cs_hh_lvl_mal.sh119 ELSE NULL END), NULL),
          -- SH212 has varying meaning so must be filtered to svy 338 only; in that svy it is also in S212
          COALESCE((CASE WHEN rh6_hh_lvl_ht_wt.surveyid='338' THEN rh6_hh_lvl_ht_wt.sh212 ELSE NULL END), NULL),
          -- Same for SH214 / svy 484... really what was the point of using CS variables if you vary their meaning!
          COALESCE((CASE WHEN rh6_hh_lvl_ht_wt.surveyid='484' THEN rh6_hh_lvl_ht_wt.sh214 ELSE NULL END), NULL),
          -- ... and SH511 / svy 304 time for beer
          COALESCE((CASE WHEN rh6_hh_lvl_ht_wt.surveyid='304' THEN rh6_hh_lvl_ht_wt.sh511 ELSE NULL END), NULL))
  AS hml35_result_mal_rapid_test
, (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs
    WHERE col_name='HML35' AND surveyid=rh0_hh.surveyid
          AND value=COALESCE(rhmh_hh_lvl_mal.hml35, rhm2_hh_lvl_mal.hml35) -- this won't produce descs for the non-standard col names
          AND value_type='ExplicitValue') -- TODO add other cols for value descs if agreed above
    AS hml35_desc_result_mal_rapid_test

-- child ht / weight stuff
, COALESCE(rh6_hh_lvl_ht_wt.hc70, r44_ch_lvl_ht_wt.hw70) AS hc70_ht_age_stdev_who
, COALESCE(rh6_hh_lvl_ht_wt.hc71, r44_ch_lvl_ht_wt.hw71) AS hc71_wt_age_stdev_who
, COALESCE(rh6_hh_lvl_ht_wt.hc72, r44_ch_lvl_ht_wt.hw72) AS hc72_wt_ht_stdev_who
, COALESCE(rh6_hh_lvl_ht_wt.hc5, r44_ch_lvl_ht_wt.hw5) AS hc5_ht_age_stdev
, COALESCE(rh6_hh_lvl_ht_wt.hc8, r44_ch_lvl_ht_wt.hw8) AS hc8_wt_age_stdev
, COALESCE(rh6_hh_lvl_ht_wt.hc11, r44_ch_lvl_ht_wt.hw11) AS hc11_wt_ht_stdev
, COALESCE(rh6_hh_lvl_ht_wt.hc56, r44_ch_lvl_ht_wt.hw56) AS hc56_hb_adj_alt
, COALESCE(rh6_hh_lvl_ht_wt.hc57, r44_ch_lvl_ht_wt.hw57) AS hc57_anemia_level
, COALESCE(
    (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs
      WHERE col_name='HC57' AND surveyid=r21_kids.surveyid
      AND value=rh6_hh_lvl_ht_wt.hc57),
    (SELECT value_desc FROM dhs_survey_specs.dhs_value_descs
      WHERE col_name='HW57' AND surveyid=r21_kids.surveyid
      AND value=r44_ch_lvl_ht_wt.hw57)) AS hc57_desc_anemia_level

-- BEGIN TABLE LISTINGS
FROM -- We now need to make the hh schedule table the main basis for the extraction as rec21 missed many children
  dhs_data_tables."RECH1" rh1_sched
  -- There will always be a household entry unless something's gone very wrong
INNER JOIN dhs_data_tables."RECH0" rh0_hh
  ON rh1_sched.surveyid = rh0_hh.surveyid AND rh1_sched.hhid = rh0_hh.hhid
-- Now join all the required household level tables providing required info. Use outer joins for all of these as
-- they're not always present for each survey. At least the join columns usually remain constant...
LEFT OUTER JOIN dhs_data_tables."RECHMH" rhmh_hh_lvl_mal
    ON rh1_sched.surveyid = rhmh_hh_lvl_mal.surveyid AND rh1_sched.hhid = rhmh_hh_lvl_mal.hhid
-- .. with this one known exception where the index column got called something totally incorrect! (idxhml in table hmh!!)
      AND rh1_sched.hvidx = COALESCE(rhmh_hh_lvl_mal.hmhidx, rhmh_hh_lvl_mal.idxhml)
LEFT OUTER JOIN dhs_data_tables."RECHM2" rhm2_hh_lvl_mal
    ON rh1_sched.surveyid = rhm2_hh_lvl_mal.surveyid AND rh1_sched.hhid = rhm2_hh_lvl_mal.hhid
      AND rh1_sched.hvidx = rhm2_hh_lvl_mal.hmldx
LEFT OUTER JOIN dhs_data_tables."RECHMC" rhmc_cs_hh_lvl_mal
    ON rh1_sched.surveyid = rhmc_cs_hh_lvl_mal.surveyid AND rh1_sched.hhid = rhmc_cs_hh_lvl_mal.hhid
      AND rh1_sched.hvidx = rhmc_cs_hh_lvl_mal.idxhmc
LEFT OUTER JOIN dhs_data_tables."RECH4" rh4_cs_sched
      ON rh1_sched.surveyid = rh4_cs_sched.surveyid AND rh1_sched.hhid = rh4_cs_sched.hhid
        AND rh1_sched.hvidx = rh4_cs_sched.idxh4
LEFT OUTER JOIN dhs_data_tables."RECH4_json" rh4_cs_sched_j
    ON rh1_sched.surveyid = rh4_cs_sched_j.surveyid AND rh1_sched.hhid = rh4_cs_sched_j.hhid
        AND rh1_sched.hvidx = rh4_cs_sched_j.idxh4
LEFT OUTER JOIN dhs_data_tables."RECH6" rh6_hh_lvl_ht_wt
    ON rh1_sched.surveyid = rh6_hh_lvl_ht_wt.surveyid AND rh1_sched.hhid = rh6_hh_lvl_ht_wt.hhid
       AND rh1_sched.hvidx = rh6_hh_lvl_ht_wt.hc0
-- We still need to join through to the child-level tables when possible as the health / vaccine info is only present
-- there, in REC43/REC4A. We need to go via REC21, the main child-level listing, to get the index into REC43/4A.
-- Use an outer join though so we still get the hh-level info even when the child-level info isn't present.
-- A previous iteration of this extraction used REC21 as the main basis, but many children were missing - this could
-- if a woman (mother) was not interviewed, I guess
LEFT OUTER JOIN  dhs_data_tables."REC21" r21_kids
    ON rh1_sched.surveyid = r21_kids.surveyid
       AND rh1_sched.hhid = LEFT(r21_kids.caseid, -3) -- the risky-feeling bit, but no known issues so far...
       AND rh1_sched.hvidx=r21_kids.b16
-- REC21 provides the identifier to join to the health tables, namely REC43 in pre-phase 7 surveys...
LEFT OUTER JOIN dhs_data_tables."REC43" r43_health
      ON r21_kids.surveyid = r43_health.surveyid AND r21_kids.caseid = r43_health.caseid AND r21_kids.bidx=r43_health.hidx
  -- ... and REC4A in phase 7
LEFT OUTER JOIN  dhs_data_tables."REC4A" r4a_health
      ON r21_kids.surveyid = r4a_health.surveyid AND r21_kids.caseid = r4a_health.caseid AND r21_kids.bidx = r4a_health.hidxa
-- the child-level children height and weight table, some of this info is also in hh-level tables i.e. RECH6;
-- we will use both to ensure we get from either location
LEFT OUTER JOIN dhs_data_tables."REC44" r44_ch_lvl_ht_wt
      ON r21_kids.surveyid = r44_ch_lvl_ht_wt.surveyid
         AND r21_kids.caseid = r44_ch_lvl_ht_wt.caseid
         AND r21_kids.bidx = r44_ch_lvl_ht_wt.hwidx
LEFT OUTER JOIN dhs_data_tables."REC01" r01_mums
    ON r21_kids.surveyid = r01_mums.surveyid
      AND r21_kids.caseid = r01_mums.caseid
LEFT OUTER JOIN dhs_data_tables."REC11" r11_mums_info
    ON r21_kids.surveyid = r11_mums_info.surveyid AND r21_kids.caseid = r11_mums_info.caseid
-- the maternity table, i.e. about pregnancy and birth by child. Sometimes need to join a CS table for this.
-- We use this for the birth info columns
LEFT OUTER JOIN  dhs_data_tables."REC41" r41_maternity
      ON r21_kids.surveyid = r41_maternity.surveyid
         AND r21_kids.caseid = r41_maternity.caseid
         AND r21_kids.bidx=r41_maternity.midx
--LEFT OUTER JOIN dhs_data_tables."REC42" r42_health_bfeed
--      ON r21_kids.surveyid=r42_health_b0feed.surveyid AND r21_kids.caseid=r42_health_bfeed.caseid AND r21_kids.bidx=r42_health_bfeed.
LEFT OUTER JOIN dhs_data_tables."REC95" r95_cs_vacc
      ON r21_kids.surveyid = r95_cs_vacc.surveyid AND r21_kids.caseid=r95_cs_vacc.caseid AND r21_kids.bidx = r95_cs_vacc.idx95
LEFT OUTER JOIN dhs_data_locations.dhs_cluster_locs locs
      ON rh0_hh.surveyid::INTEGER=locs.surveyid AND rh0_hh.hv001::INTEGER = locs.dhsclust
LEFT OUTER JOIN dhs_survey_specs.dhs_survey_listing svy
      ON rh0_hh.surveyid=svy.surveynum
WHERE
  -- health data are only present for <5 but lucy wants all <= 5 even so
  rh1_sched.hv105::INTEGER <= 5
  AND rh0_hh.surveyid = '{SURVEYID}' --165
--AND rh1_sched.hhid = '      175 92' and rh1_sched.hvidx='3'