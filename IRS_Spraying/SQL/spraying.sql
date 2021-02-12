-- RECH2.HV253 = '1'

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
, r0.hv024 as "hv024_regionid"
, regnames.value_desc as "hv024_region_name"
, r2.hv253 as "hv253_has_been_sprayed"

FROM dhs_data_tables."RECH0" r0
INNER JOIN
  dhs_data_tables."RECH2" r2
ON r0.surveyid = r2.surveyid AND r0.hhid = r2.hhid

LEFT OUTER JOIN
  dhs_data_locations.dhs_cluster_locs locs
  on r0.surveyid::INTEGER = locs.surveyid AND r0.hv001::INTEGER = locs.dhsclust

LEFT OUTER JOIN
  dhs_survey_specs.dhs_value_descs regnames
  on r0.surveyid = regnames.surveyid AND regnames.col_name='HV024' AND regnames.value = r0.hv024
WHERE r2.hv253 is not null
ORDER BY surveyid, hv001::INTEGER, hhid

