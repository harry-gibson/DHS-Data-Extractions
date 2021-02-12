-- CN_NUTS_C_HA2
-- Percentage of children under age five years stunted (below -2 SD of height-for-age according to the WHO

-- Child's age in months is calculated using the measurement and birth dates from RECH6, as shown in the stata 
-- code, in a subquery. However using the field "HC1 = Child's age in months" gives the same results at least
-- on Kenya 2014 survey.

-- Returns denominators which are always slightly over the expected values from
-- the DHS API (e.g. http://api.dhsprogram.com/rest/dhs/data/CN_NUTS_C_HA2?f=html&surveyIds=EG2014DHS)
-- and the corresponding proportional values also do not match the API results.

--select sum(denom_nonwt) d_nw, sum(denom_wt) d_w, sum(num_wt) / sum(denom_wt) val from (

SELECT 
h0.hv001 as clusterid
, min(locs.latitude) as latitude
, min(locs.longitude) as longitude
, min(locs.dhsid) as dhsid
, min(locs.urban_rural) as urban_rural

,SUM(
	CASE WHEN 
		--h6.hc1::Integer < 60 
		agemonths < 60
		AND 
		h6.hc70::Integer < 9996 -- Non-measured children are not included in denom!
		AND
		h1.hv103::Integer = 1
	THEN 1 ELSE 0
	END
) as denom_nonwt

,SUM(
	CASE WHEN 
		--h6.hc1::Integer < 60 
		agemonths < 60
		AND
		h6.hc70::Integer < 9996 -- Non-measured children are not included in denom!
		AND 
		h1.hv103::Integer = 1
	THEN h0.hv005::Float / 1000000	ELSE 0	END
) as denom_wt

,SUM(
	CASE WHEN 
		--h6.hc1::Integer < 60 
		agemonths < 60
		AND
		h6.hc70::Integer < 9996 -- redundant, obviously
		AND 
		h1.hv103::Integer = 1
		AND hc70::Integer < -200
	THEN 1 ELSE 0 END
) as num_nonwt

,SUM(
	CASE WHEN 
		--h6.hc1::Integer < 60 
		agemonths < 60
		AND
		h6.hc70::Integer < 9996
		AND 
		h1.hv103::Integer = 1
		AND hc70::Integer < -200
	THEN h0.hv005::Float / 1000000	ELSE 0	END	
) as num_wt

FROM

dhs_data_tables."RECH1" h1
INNER JOIN
	( SELECT 
		surveyid
		, hhid
		, hc0
		, hc1
		, hc70
		, (DATE_PART('year', h6_with_dates.dom) - DATE_PART('year', h6_with_dates.dob)) * 12 +
			(DATE_PART('month', h6_with_dates.dom) - DATE_PART('month', h6_with_dates.dob)) AS agemonths
		
		
		FROM (
			SELECT 
			surveyid
			, hhid
			, hc0
			, hc1
			, hc70
			, TO_DATE(hc17 || '/' || hc18 || '/' || hc19, 'dd/mm/yy') AS dom
			, TO_DATE(
					CASE
					WHEN hc16::Integer > 31 THEN
						'15'
					ELSE
						hc16
					END || '/' || hc30 || '/' || hc31, 'dd/mm/yy'
				) AS dob
			
			FROM dhs_data_tables."RECH6"
		) h6_with_dates
	) h6
	ON h6.surveyid = h1.surveyid AND h6.hhid = h1.hhid aND h6.hc0 = h1.hvidx
INNER JOIN
	dhs_data_tables."RECH0" h0
	ON h0.surveyid = h1.surveyid AND h0.hhid = h1.hhid
LEFT OUTER JOIN
	(SELECT
		surveyid
		, dhsclust as clusterid
		, latnum as latitude
		, longnum as longitude
		, dhsid as dhsid
		, urban_rura as urban_rural
	FROM
		dhs_data_locations.dhs_cluster_locs
	) locs
	ON h0.hv001::Integer = locs.clusterid 
	AND h0.surveyid::Integer = locs.surveyid
	
--WHERE h0.surveyid = '451' 
WHERE h0.surveyid = '{SURVEYID}' 
GROUP BY h0.hv001
ORDER BY h0.hv001::Integer

--) clust
