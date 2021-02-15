-- Create the building-quality extraction for Lucy Tusting, using SQL to extract the descriptions from the metadata tables, 
-- rather than the previous approach of using an FME schemamapper to create the recoded value descriptions.

-- As before it's the users responsibility to check first that the column names remain constant across surveys e.g. that hv211 always means motorbike

-- It's intended that this SQL should be run via the FME workbench in the same folder which will rename the columns created by the query 
-- to include various special characters and match the required output format. The SQL is read from this file by the workbench.
SELECT
w0.surveyid
, w0.caseid
-- , --country
-- , -- survey type
-- , -- survey year
, w0.v000 as "hv000_ccode_phase"
, w0.v001 as "hv001_ClusterID"
, locs.latnum as latitude 
, locs.longnum as longitude
, w0.v002 as "hv002_hhnum"
, w0.v005 as "hv005_wt"
, w1.v136 as "hv009_nmembers"
, w1.v137 as "hv014_nunder5s"

-- Recoding vars
, w1.v102 as "hv025_resid_type"
, (SELECT value_desc from dhs_survey_specs.dhs_value_descs where col_name='V102' AND surveyid=r0.surveyid AND value=v102) as hv025_desc_resid_type
, w1.v103 as "hv026_resid_place"
, (SELECT value_desc from dhs_survey_specs.dhs_value_descs where col_name='V103' AND surveyid=r0.surveyid AND value=v103) as hv026_desc_resid_place

, w0.v040 as "hv040_cluster_alt_m"

, w1.v113 as "hv201_watersrc"
-- The value spec for this var in one of the surveys is slightly weird and includes a range as well as explicit labelled values
, (SELECT value_desc from dhs_survey_specs.dhs_value_descs where col_name='V113' AND surveyid=r0.surveyid AND value=v113 AND value_type='ExplicitValue') as hv201_desc_watersrc
, w1.v115 as "hv204_mins_to_watersrc"
, w1.v116 as "hv205_toilet"
, (SELECT value_desc from dhs_survey_specs.dhs_value_descs where col_name='V116' AND surveyid=r0.surveyid AND value=v116) as hv205_desc_toilet
, w1.v119 as "hv206_has_electric"
, w1.v120 as "hv207_has_radio"
, w1.v121 as "hv208_has_tv"
, w1.v122 as "hv209_has_fridge"
, w1.v123 as "hv210_has_bike"
, w1.v124 as "hv211_has_mbike"
, w1.v125 as "hv212_has_car"
, w1.v127 as "hv213_flooring"
, (SELECT value_desc from dhs_survey_specs.dhs_value_descs where col_name='V127' AND surveyid=r0.surveyid AND value=v127) as hv213_desc_flooring
, w1.v128 as "hv214_walling"
, (SELECT value_desc from dhs_survey_specs.dhs_value_descs where col_name='V128' AND surveyid=r0.surveyid AND value=v128) as hv214_desc_walling
, r1.v129 as "hv215_roofing"
, (SELECT value_desc from dhs_survey_specs.dhs_value_descs where col_name='V129' AND surveyid=r0.surveyid AND value=v129) as hv215_desc_roofing

--, r2.hv216 as "hv216_nbedrooms"
--, (SELECT value_desc from dhs_survey_specs.dhs_value_descs where col_name='HV216' AND surveyid=r0.surveyid AND value=hv216) as hv216_desc_nbedrooms
--, r2.hv219 as "hv219_hh_head_gender"
--, (SELECT value_desc from dhs_survey_specs.dhs_value_descs where col_name='HV219' AND surveyid=r0.surveyid AND value=hv219) as hv219_desc_hh_head_gender

--, r2.hv220 as "hv220_hh_head_age"
--, r2.hv221 as "hv221_hasphone"
--, r2.hv225 as "hv225_sharestoilet"

--, r2.hv226 as "hv226_cooking_fuel"
--, (SELECT value_desc from dhs_survey_specs.dhs_value_descs where col_name='HV226' AND surveyid=r0.surveyid AND value=hv226) as hv226_desc_cooking_fuel
--, r2.hv238 as "hv238_nhh_sharing_toilet"

--, r2.hv239 as "hv239_cooking_appliance"
--, (SELECT value_desc from dhs_survey_specs.dhs_value_descs where col_name='HV239' AND surveyid=r0.surveyid AND value=hv239) as hv239_desc_cooking_appliance
--, r2.hv240 as "hv240_ventilation"
--, (SELECT value_desc from dhs_survey_specs.dhs_value_descs where col_name='HV240' AND surveyid=r0.surveyid AND value=hv240) as hv240_desc_ventilation

--, r2.hv242 as "hv242_has_separate_kitchen"
--, r2.hv243a as "hv243a_hasmobile"
--, r2.hv243b as "hv243b_haswatch"
--, r2.hv243c as "hv243c_hashorsecart"
--, r2.hv243d as "hv243d_hasmotorboat"
--, r2.hv244 as "hv244_has_agri_land"
--, r2.hv245 as "hv245_hect_agri_land_1dec"
--, r2.hv247 as "hv247_has_bankacct"
--, r2.hv270 as "hv270_wealthquint"
--, (SELECT value_desc from dhs_survey_specs.dhs_value_descs where col_name='HV270' AND surveyid=r0.surveyid AND value=hv270) as hv270_desc_wealthquint
--, v_hv270.value_desc as hv270_join
--, r2.hv271 as "hv271_wealthscore"

, r1.hv106 as "hv106_head_ed_lvl"
, (SELECT value_desc from dhs_survey_specs.dhs_value_descs where col_name='HV106' AND surveyid=r0.surveyid AND value=hv106) as hv106_desc_head_ed_lvl
, r1.hv109 as "hv109_head_ed_attain"
, (SELECT value_desc from dhs_survey_specs.dhs_value_descs where col_name='HV109' AND surveyid=r0.surveyid AND value=hv109) as hv109_desc_head_ed_attain
, r1.hv115 as "hv115_head_marital_status"
, (SELECT value_desc from dhs_survey_specs.dhs_value_descs where col_name='HV115' AND surveyid=r0.surveyid AND value=hv115) as hv115_desc_head_marital

FROM 
dhs_data_tables."REC01" r0
LEFT OUTER JOIN
dhs_data_tables."REC11" r1
ON r0.surveyid = r1.surveyid AND r0.caseid = r1.caseid
LEFT OUTER JOIN
dhs_data_locations.dhs_cluster_locs locs
ON r0.surveyid::Integer = locs.surveyid AND r0.v001::Integer = locs.dhsclust

WHERE 
-- SUBSTITUTE IN THE SURVEY ID MANUALLY (OR VIA FME)
r0.surveyid::Integer = 473 -- {SURVEYID} --in (282,323,330,332,337,338,395,399,437,451,473,481,484) 
ORDER BY surveyid, v001::Integer, caseid