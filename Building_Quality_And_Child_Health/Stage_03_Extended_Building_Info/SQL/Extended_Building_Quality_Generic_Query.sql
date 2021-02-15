-- Create the building-quality extraction for Lucy Tusting, using SQL to extract the descriptions from the metadata tables, 
-- rather than the previous approach of using an FME schemamapper to create the recoded value descriptions.

-- As before it's the users responsibility to check first that the column names remain constant across surveys e.g. that hv211 always means motorbike

-- It's intended that this SQL should be run via the FME workbench in the same folder which will rename the columns created by the query 
-- to include various special characters and match the required output format. The SQL is read from this file by the workbench.
SELECT
r0.surveyid
, r0.hhid
-- , --country
-- , -- survey type
-- , -- survey year
, r0.hv000 as "hv000_ccode_phase"
, r0.hv001 as "hv001_ClusterID"
, locs.latnum as latitude 
, locs.longnum as longitude
, r0.hv002 as "hv002_hhnum"
, r0.hv005 as "hv005_wt"
, r0.hv009 as "hv009_nmembers"
, r0.hv014 as "hv014_nunder5s"

-- Recoding vars
, r0.hv025 as "hv025_resid_type"
, (SELECT value_desc from dhs_survey_specs.dhs_value_descs where col_name='HV025' AND surveyid=r0.surveyid AND value=hv025 AND value_type='ExplicitValue') as hv025_desc_resid_type
, r0.hv026 as "hv026_resid_place"
, (SELECT value_desc from dhs_survey_specs.dhs_value_descs where col_name='HV026' AND surveyid=r0.surveyid AND value=hv026 AND value_type='ExplicitValue') as hv026_desc_resid_place

, r0.hv040 as "hv040_cluster_alt_m"

, r2.hv201 as "hv201_watersrc"
-- The value spec for this var in one of the surveys is slightly weird and includes a range as well as explicit labelled values
, (SELECT value_desc from dhs_survey_specs.dhs_value_descs where col_name='HV201' AND surveyid=r0.surveyid AND value=hv201 AND value_type='ExplicitValue') as hv201_desc_watersrc
, r2.hv204 as "hv204_mins_to_watersrc"
, r2.hv205 as "hv205_toilet"
, (SELECT max(value_desc) from dhs_survey_specs.dhs_value_descs where col_name='HV205' AND surveyid=r0.surveyid AND value=hv205 AND value_type='ExplicitValue') as hv205_desc_toilet
, r2.hv206 as "hv206_has_electric"
--, (SELECT value_desc from dhs_survey_specs.dhs_value_descs where col_name='HV206' AND surveyid=r0.surveyid AND value=hv206) as hv206_desc_electric
, r2.hv207 as "hv207_has_radio"
--, (SELECT value_desc from dhs_survey_specs.dhs_value_descs where col_name='HV207' AND surveyid=r0.surveyid AND value=hv207) as hv207_desc_radio
, r2.hv208 as "hv208_has_tv"
--, (SELECT value_desc from dhs_survey_specs.dhs_value_descs where col_name='HV208' AND surveyid=r0.surveyid AND value=hv208) as hv208_desc_tv
, r2.hv209 as "hv209_has_fridge"
--, (SELECT value_desc from dhs_survey_specs.dhs_value_descs where col_name='HV209' AND surveyid=r0.surveyid AND value=hv209) as hv209_desc_fridge
, r2.hv210 as "hv210_has_bike"
--, (SELECT value_desc from dhs_survey_specs.dhs_value_descs where col_name='HV210' AND surveyid=r0.surveyid AND value=hv210) as hv210_desc_bike
, r2.hv211 as "hv211_has_mbike"
--, (SELECT value_desc from dhs_survey_specs.dhs_value_descs where col_name='HV211' AND surveyid=r0.surveyid AND value=hv211) as hv211_desc_mbike
, r2.hv212 as "hv212_has_car"
--, (SELECT value_desc from dhs_survey_specs.dhs_value_descs where col_name='HV212' AND surveyid=r0.surveyid AND value=hv212) as hv212_desc_car
, r2.hv213 as "hv213_flooring"
, (SELECT value_desc from dhs_survey_specs.dhs_value_descs where col_name='HV213' AND surveyid=r0.surveyid AND value=hv213 AND value_type='ExplicitValue') as hv213_desc_flooring
, r2.hv214 as "hv214_walling"
, (SELECT max(value_desc) from dhs_survey_specs.dhs_value_descs where col_name='HV214' AND surveyid=r0.surveyid AND value=hv214 AND value_type='ExplicitValue') as hv214_desc_walling
, r2.hv215 as "hv215_roofing"
, (SELECT max(value_desc) from dhs_survey_specs.dhs_value_descs where col_name='HV215' AND surveyid=r0.surveyid AND value=hv215 AND value_type='ExplicitValue') as hv215_desc_roofing
, r2.hv216 as "hv216_nbedrooms"
--, (SELECT value_desc from dhs_survey_specs.dhs_value_descs where col_name='HV216' AND surveyid=r0.surveyid AND value=hv216) as hv216_desc_nbedrooms
, r2.hv219 as "hv219_hh_head_gender"
, (SELECT value_desc from dhs_survey_specs.dhs_value_descs where col_name='HV219' AND surveyid=r0.surveyid AND value=hv219 AND value_type='ExplicitValue') as hv219_desc_hh_head_gender

, r2.hv220 as "hv220_hh_head_age"
, r2.hv221 as "hv221_hasphone"
, r2.hv225 as "hv225_sharestoilet"

, r2.hv226 as "hv226_cooking_fuel"
, (SELECT value_desc from dhs_survey_specs.dhs_value_descs where col_name='HV226' AND surveyid=r0.surveyid AND value=hv226 AND value_type='ExplicitValue') as hv226_desc_cooking_fuel
, r2.hv238 as "hv238_nhh_sharing_toilet"

, r2.hv239 as "hv239_cooking_appliance"
, (SELECT value_desc from dhs_survey_specs.dhs_value_descs where col_name='HV239' AND surveyid=r0.surveyid AND value=hv239 AND value_type='ExplicitValue') as hv239_desc_cooking_appliance
, r2.hv240 as "hv240_ventilation"
, (SELECT value_desc from dhs_survey_specs.dhs_value_descs where col_name='HV240' AND surveyid=r0.surveyid AND value=hv240 AND value_type='ExplicitValue') as hv240_desc_ventilation

, r2.hv242 as "hv242_has_separate_kitchen"
, r2.hv243a as "hv243a_hasmobile"
, r2.hv243b as "hv243b_haswatch"
, r2.hv243c as "hv243c_hashorsecart"
, r2.hv243d as "hv243d_hasmotorboat"
, r2.hv244 as "hv244_has_agri_land"
, r2.hv245 as "hv245_hect_agri_land_1dec"
, r2.hv247 as "hv247_has_bankacct"
, r2.hv270 as "hv270_wealthquint"
, (SELECT value_desc from dhs_survey_specs.dhs_value_descs where col_name='HV270' AND surveyid=r0.surveyid AND value=hv270 AND value_type='ExplicitValue') as hv270_desc_wealthquint
, r2.hv271 as "hv271_wealthscore"
, r1.hv106 as "hv106_head_ed_lvl"
, (SELECT value_desc from dhs_survey_specs.dhs_value_descs where col_name='HV106' AND surveyid=r0.surveyid AND value=hv106 AND value_type='ExplicitValue') as hv106_desc_head_ed_lvl
, r1.hv109 as "hv109_head_ed_attain"
, (SELECT value_desc from dhs_survey_specs.dhs_value_descs where col_name='HV109' AND surveyid=r0.surveyid AND value=hv109 AND value_type='ExplicitValue') as hv109_desc_head_ed_attain
, r1.hv115 as "hv115_head_marital_status"
, (SELECT value_desc from dhs_survey_specs.dhs_value_descs where col_name='HV115' AND surveyid=r0.surveyid AND value=hv115 AND value_type='ExplicitValue') as hv115_desc_head_marital
, COALESCE(wmn_heads.n_wmn_heads, partner_heads.n_partner_heads) as n_head_entries
, COALESCE(wmn_heads.wmn_occ_grp, partner_heads.partner_occ_grp) as head_occ_grp
, COALESCE(
	(SELECT value_desc from dhs_survey_specs.dhs_value_descs where col_name='V717' AND surveyid=r0.surveyid AND value=wmn_occ_grp AND value_type='ExplicitValue')
	,  (SELECT value_desc from dhs_survey_specs.dhs_value_descs where col_name='V705' AND surveyid=r0.surveyid AND value=partner_occ_grp AND value_type='ExplicitValue') 
	) as head_occ_grp_desc
, CASE WHEN wmn_heads.wmn_is_head=1 THEN 'Woman' WHEN partner_heads.partner_is_head=1 THEN 'Partner' ELSE 'Unknown' END as who_is_head

FROM 
dhs_data_tables."RECH0" r0
LEFT OUTER JOIN
dhs_data_tables."RECH2" r2
ON r0.surveyid = r2.surveyid AND r0.hhid = r2.hhid
LEFT OUTER JOIN
dhs_data_tables."RECH1" r1
ON r0.surveyid = r1.surveyid AND r0.hhid = r1.hhid AND r2.hv218 = r1.hvidx

LEFT  OUTER JOIN 
(
	SELECT 
	 w01.v001 
	,w01.v002 
	, w01.surveyid
	, count(*) as n_wmn_heads
	, max(w71.v717) as wmn_occ_grp
	, max(w11.v150::Integer) as wmn_is_head
	FROM dhs_data_tables."REC01" w01
	INNER JOIN dhs_data_tables."REC11" w11
	ON w01.caseid = w11.caseid AND w01.surveyid = w11.surveyid
	INNER JOIN dhs_data_tables."REC71" w71
	ON w01.caseid = w71.caseid AND w01.surveyid = w71.surveyid
	WHERE w11.v150::Integer = (1) 
	GROUP BY w01.v001, w01.v002, w01.surveyid		
) wmn_heads 
ON r0.surveyid = wmn_heads.surveyid AND r0.hv001 = wmn_heads.v001 AND r0.hv002 = wmn_heads.v002

LEFT OUTER JOIN
(
	SELECT 
	 w01.v001 
	,w01.v002 
	, w01.surveyid
	, count(*) as n_partner_heads
	, max(w71.v705) as partner_occ_grp
	, max(CASE WHEN w11.v150::Integer = 2 THEN 1 ELSE 0 END) as partner_is_head
	FROM dhs_data_tables."REC01" w01
	INNER JOIN dhs_data_tables."REC11" w11
	ON w01.caseid = w11.caseid AND w01.surveyid = w11.surveyid
	INNER JOIN dhs_data_tables."REC71" w71
	ON w01.caseid = w71.caseid AND w01.surveyid = w71.surveyid
	WHERE w11.v150::Integer = (2) AND w01.surveyid::Integer=356
	GROUP BY w01.v001, w01.v002, w01.surveyid		
) partner_heads
ON r0.surveyid = partner_heads.surveyid AND r0.hv001 = partner_heads.v001 AND r0.hv002 = partner_heads.v002


LEFT OUTER JOIN
dhs_data_locations.dhs_cluster_locs locs
ON r0.surveyid::Integer = locs.surveyid AND r0.hv001::Integer = locs.dhsclust
WHERE 
-- SUBSTITUTE IN THE SURVEY ID MANUALLY (OR VIA FME)
r0.surveyid::Integer = 505 --in (282,323,330,332,337,338,395,399,437,451,473,481,484) 
ORDER BY surveyid, hv001::Integer, hhid