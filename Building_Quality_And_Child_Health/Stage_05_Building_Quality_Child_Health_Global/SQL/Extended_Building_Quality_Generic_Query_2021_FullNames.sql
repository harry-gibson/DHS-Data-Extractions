-- Create the building-quality extraction for Lucy Tusting, using SQL to extract the descriptions from the metadata tables, 
-- rather than the previous approach of using an FME schemamapper to create the recoded value descriptions.

-- As before it's the users responsibility to check first that the column names remain constant across surveys e.g. that hv211 always means motorbike

-- It's intended that this SQL should be run via the FME workbench in the same folder which will rename the columns created by the query 
-- to include various special characters and match Lucy's required output format. The SQL is embedded in the workbench, so this file is just a backup.
SELECT
r0.hhid AS "HHID = Case Identification"
, '{COUNTRYNAME}' AS "CountryName"
, '{DHS_CC}' AS "DHS_CountryCode"        
, r0.surveyid AS "SurveyNum" 
, '{SVY_TYPE}' AS "SurveyType"       
, '{SVY_YR}' AS "SurveyYear"
-- , --country
-- , -- survey type
-- , -- survey year
, r0.hv000 as "HV000 = Country code and phase"
, r0.hv001 as "HV001 = Cluster number"
, locs.latnum as latitude 
, locs.longnum as longitude
, r0.hv002 as "HV002 = Household number"
, r0.hv005 as "HV005 = Household sample weight (6 decimals)"
, r0.hv009 as "HV009 = Number of household members"

-- Recoding vars
, (SELECT (value_desc) from dhs_survey_specs.dhs_value_descs where col_name='HV025' AND surveyid=r0.surveyid AND value=hv025 AND value_type='ExplicitValue') as "HV025 | Type of place of residence"
, r0.hv025 as "HV025 = Type of place of residence"

-- The value spec for this var in one of the surveys is slightly weird and includes a range as well as explicit labelled values
, (SELECT (value_desc) from dhs_survey_specs.dhs_value_descs where col_name='HV201' AND surveyid=r0.surveyid AND value=hv201 AND value_type='ExplicitValue') as "HV201 | Source of drinking water"
, r2.hv201 as "HV201 = Source of drinking water"

, (SELECT (value_desc) from dhs_survey_specs.dhs_value_descs where col_name='HV205' AND surveyid=r0.surveyid AND value=hv205 AND value_type='ExplicitValue') as "HV205 | Type of toilet facility"
, r2.hv205 as "HV205 = Type of toilet facility"

, (SELECT (value_desc) from dhs_survey_specs.dhs_value_descs where col_name='HV213' AND surveyid=r0.surveyid AND value=hv213 AND value_type='ExplicitValue') as "HV213 | Main floor material"
, r2.hv213 as "HV213 = Main floor material"

, (SELECT (value_desc) from dhs_survey_specs.dhs_value_descs where col_name='HV214' AND surveyid=r0.surveyid AND value=hv214 AND value_type='ExplicitValue') as "HV214 | Main wall material"
, r2.hv214 as "HV214 = Main wall material"

, (SELECT (value_desc) from dhs_survey_specs.dhs_value_descs where col_name='HV215' AND surveyid=r0.surveyid AND value=hv215 AND value_type='ExplicitValue') as "HV215 | Main roof material"
, r2.hv215 as "HV215 = Main roof material"

--, (SELECT value_desc from dhs_survey_specs.dhs_value_descs where col_name='HV216' AND surveyid=r0.surveyid AND value=hv216) as hv216_desc_nbedrooms
, r2.hv216 as "HV216 = Number of rooms used for sleeping"

, r2.hv221 as "HV221 = Has telephone (land-line)"

, r2.hv226 as "HV226 = Type of cooking fuel"
, (SELECT (value_desc) from dhs_survey_specs.dhs_value_descs where col_name='HV226' AND surveyid=r0.surveyid AND value=hv226 AND value_type='ExplicitValue') as "HV226 | Type of cooking fuel"

, r2.hv243a as "HV243A = Has mobile telephone"
, r2.hv243b as "HV243B = Has watch"
, r2.hv243c as "HV243C = Has animal-drawn cart"
, r2.hv243d as "HV243D = NA - Has boat with a motor"
, r2.hv244 as "HV244 = Owns land usable for agriculture"
, r2.hv245 as "HV245 = Hectares of agricultural land (1 decimal)"
, r2.hv247 as "HV247 = Has bank account"

, (SELECT (value_desc) from dhs_survey_specs.dhs_value_descs where col_name='HV270' AND surveyid=r0.surveyid AND value=hv270 AND value_type='ExplicitValue') as "HV270 | Wealth index"
, r2.hv270 as "HV270 = Wealth index"
, r2.hv271 as "HV271 = Wealth index factor score (5 decimals)"

, r0.hv014 as "HV014 = Number Under 5s"

, (SELECT (value_desc) from dhs_survey_specs.dhs_value_descs where col_name='HV026' AND surveyid=r0.surveyid AND value=hv026 AND value_type='ExplicitValue') as "HV026 | Place of Residence"
, r0.hv026 as "HV026 = Place of Residence"

, r0.hv040 as "HV040 = Cluster Altitude m"

, r2.hv204 as "HV204 = Mins to reach water source"
, r2.hv206 as "HV206 = Has electricity"
, r2.hv207 as "HV207 = Has radio"
, r2.hv208 as "HV208 = Has television"
, r2.hv209 as "HV209 = Has refrigerator"
, r2.hv210 as "HV210 = Has bicycle" 
, r2.hv211 as "HV211 = Has motorcycle/scooter"
, r2.hv212 as "HV212 = Has car/truck"

, r2.hv219 as "HV219 = Sex of household head"
, (SELECT (value_desc) from dhs_survey_specs.dhs_value_descs where col_name='HV219' AND surveyid=r0.surveyid AND value=hv219 AND value_type='ExplicitValue') as "HV219 | Sex of household head"

, r2.hv220 as "HV220 = Age of household head"
, r2.hv225 as "HV225 = Shares toilet"
, r2.hv238 as "HV238 = Number of households sharing toilet"

, r2.hv239 as "HV239 = Cooking appliance"
, (SELECT (value_desc) from dhs_survey_specs.dhs_value_descs where col_name='HV239' AND surveyid=r0.surveyid AND value=hv239 AND value_type='ExplicitValue') as "HV239 | Cooking appliance"
, (SELECT (value_desc) from dhs_survey_specs.dhs_value_descs where col_name='HV240' AND surveyid=r0.surveyid AND value=hv240 AND value_type='ExplicitValue') as "HV240 | Cooking ventilation"
, r2.hv240 as "HV240 = Cooking ventilation"
, r2.hv242 as "HV242 = Has separate kitchen"

, r2.hv252 as "HV252 = Frequency of Smoking Indoors"
, (SELECT (value_desc) from dhs_survey_specs.dhs_value_descs where col_name='HV252' AND surveyid=r0.surveyid AND value=hv252 AND value_type='ExplicitValue') as "HV252 | Frequency of Smoking Indoors"
, r2.hv253 as "HV253 = IRS in last 12 months"

, r1.hv106 as "HV106 = Highest Education Lvl HH Head Attained"
, (SELECT (value_desc) from dhs_survey_specs.dhs_value_descs where col_name='HV106' AND surveyid=r0.surveyid AND value=hv106 AND value_type='ExplicitValue') as "HV106 | Highest Education Lvl HH Head Attained"

, r1.hv109 as "HV109 = Education Lvl HH Head"
, (SELECT (value_desc) from dhs_survey_specs.dhs_value_descs where col_name='HV109' AND surveyid=r0.surveyid AND value=hv109 AND value_type='ExplicitValue') as "HV109 | Education Lvl HH Head"

, (SELECT (value_desc) from dhs_survey_specs.dhs_value_descs where col_name='HV115' AND surveyid=r0.surveyid AND value=hv115 AND value_type='ExplicitValue') as "HV115 | Marital Status of HH Head"
, r1.hv115 as "HV115 = Marital Status of HH Head"

, COALESCE(wmn_heads.wmn_occ_grp, partner_heads.partner_occ_grp) as "V717orV705 = Occupation Group of HH Head"
, COALESCE(
	(SELECT (value_desc) from dhs_survey_specs.dhs_value_descs where col_name='V717' AND surveyid=r0.surveyid AND value=wmn_occ_grp AND value_type='ExplicitValue')
	,  (SELECT (value_desc) from dhs_survey_specs.dhs_value_descs where col_name='V705' AND surveyid=r0.surveyid AND value=partner_occ_grp AND value_type='ExplicitValue') 
	) as "V717orV705 | Occupation Group of HH Head"

, COALESCE(wmn_heads.n_wmn_heads, partner_heads.n_partner_heads) as "Flag = N entries for HH Head Occ"
, CASE WHEN wmn_heads.wmn_is_head=1 THEN 'Woman' WHEN partner_heads.partner_is_head=1 THEN 'Partner' ELSE 'Unknown' END as "Flag2 = HH Head Occ Refers To"

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
	WHERE w11.v150 = '1' 
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
	-- this surveyid=356 hardcoding was unfortunately in the 2018 extraction!
	WHERE w11.v150 = '2' -- AND w01.surveyid::Integer=356
	GROUP BY w01.v001, w01.v002, w01.surveyid		
) partner_heads
ON r0.surveyid = partner_heads.surveyid AND r0.hv001 = partner_heads.v001 AND r0.hv002 = partner_heads.v002


LEFT OUTER JOIN
dhs_data_locations.dhs_cluster_locs locs
ON r0.surveyid::Integer = locs.surveyid AND r0.hv001::Integer = locs.dhsclust
WHERE 
-- SUBSTITUTE IN THE SURVEY ID MANUALLY (OR VIA FME)
-- surveyid IN (multiple ids) is far slower, even though explain plan still shows it hitting index
-- - not sure why. 
r0.surveyid = '{SURVEYID}' --in (282,323,330,332,337,338,395,399,437,451,473,481,484)
ORDER BY r0.surveyid, hv001::Integer, r0. hhid
