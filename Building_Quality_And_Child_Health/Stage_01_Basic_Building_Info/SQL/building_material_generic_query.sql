-- we'll run this via FME which will then handle decoding the numeric material types into their descriptive
-- values. Eventually we'd want to do this in the SQL (cross join??)
SELECT
r0.surveyid 
, r0.hv001 as clusterid
, locs.latnum as latitude
, locs.longnum as longitude
, r0.hhid
, r0.hv002 as hh_num
, r0.hv005 as hh_weight
, r0.hv012 as hh_dejure_pop
, r0.hv013 as hh_defacto_pop
, r2.hv213 --as floor_material
, r2.hv214 --as wall_material
, r2.hv215 --as roof_material
FROM
dhs_data_tables."RECH0" r0
INNER JOIN 
dhs_data_tables."RECH2" r2
ON
r0.surveyid = r2.surveyid AND r0.hhid = r2.hhid
LEFT OUTER JOIN
dhs_data_locations.dhs_cluster_locs locs
ON r0.surveyid::Integer = locs.surveyid AND r0.hv001::Integer = locs.dhsclust
WHERE r0.surveyid = '363'
ORDER BY r0.surveyid::Integer, r0.hv001::Integer, hhid