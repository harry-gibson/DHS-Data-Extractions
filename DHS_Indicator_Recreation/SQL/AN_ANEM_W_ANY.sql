--  AN_ANEM_W_ANY
-- Percentage of women aged 15-49 who are anaemic

-- This could in theory be calculated from the woman tables (v457) rather than the woman height-weight-haemoglobin HH tables
-- However it doesn't always seem to give same results because who knows. So, sticking with the hh-data version as that's 
-- what's done in the stata code.

-- Denominator is all women aged 15-49 who were defacto (slept there last night) and were measured and agreed to it 
-- Numerator is all of those, who also have mild/moderate/severe anaemia

--select sum(denom_nonwt) d_nw, sum(denom_wt) d_w, sum(num_wt) / sum(denom_wt) val from (

SELECT
-- PERMA-BUMPH - same for all indicator extractions
h0.hv001 as clusterid
-- there is 1:1 join between cluster id and locs.* but as we're doing it inside the individual-level query
-- i.e. pre-grouping (to avoid another nested query) we need to use an aggregate func here
, min(locs.latitude) as latitude
, min(locs.longitude) as longitude
, min(locs.dhsid) as dhsid
, min(locs.urban_rural) as urban_rural

-- DENOMINATOR (UNWEIGHTED)
, SUM(	
	CASE WHEN 
		h1.hv104::Integer = 2 -- Is a woman
		AND
		h5.ha1::Integer BETWEEN 15 and 49 -- Is aged between 15/49
		AND
		h0.hv042::Integer = 1 -- Household selected for haemoglobin
		AND
		h5.ha52::Integer = 1 -- Agreed to haemoglobin consent statement
		AND 
		h1.hv103::Integer = 1 -- Slept there last night (defacto)
		AND
		h5.ha55::Integer = 0 -- Was actually measured for haemoglobin, because 0 means yes, of course
	THEN 1 ELSE 0 END) as Denom_NonWt

-- DENOMINATOR (WEIGHTED)
, SUM(
	CASE WHEN 
		h1.hv104::Integer = 2 -- Is a woman
		AND
		h5.ha1::Integer BETWEEN 15 and 49 -- Is aged between 15/49
		AND
		h0.hv042::Integer = 1 -- Household selected for haemoglobin
		AND
		h5.ha52::Integer = 1 -- Agreed to haemoglobin consent statement
		AND 
		h1.hv103::Integer = 1 -- Slept there last night (defacto)
		AND
		h5.ha55::Integer = 0 -- Was actually measured for haemoglobin
	THEN h0.hv005::Float / 1000000 ELSE 0 END) as Denom_Wt

-- NUMERATOR (UNWEIGHTED)	
, SUM(
	CASE WHEN 
		h1.hv104::Integer = 2 -- Is a woman
		AND
		h5.ha1::Integer BETWEEN 15 and 49 -- Is aged between 15/49
		AND
		h0.hv042::Integer = 1 -- Household selected for haemoglobin
		AND
		h5.ha52::Integer = 1 -- Agreed to haemoglobin consent statement
		AND 
		h1.hv103::Integer = 1 -- Slept there last night (defacto)
		AND
		h5.ha55::Integer = 0 -- Was actually measured for haemoglobin
		AND 
		h5.ha57::Integer in (1,2,3) -- was anaemic!
	THEN 1 ELSE 0 END) as Num_NonWt
	
-- NUMERATOR (WEIGHTED)	
, SUM(	
	CASE WHEN 
		h1.hv104::Integer = 2 -- Is a woman
		AND
		h5.ha1::Integer BETWEEN 15 and 49 -- Is aged between 15/49
		AND
		h0.hv042::Integer = 1 -- Household selected for haemoglobin
		AND
		h5.ha52::Integer = 1 -- Agreed to haemoglobin consent statement
		AND 
		h1.hv103::Integer = 1 -- Slept there last night (defacto)
		AND
		h5.ha55::Integer = 0 -- Was actually measured for haemoglobin
		AND 
		h5.ha57::Integer in (1,2,3) -- was anaemic!
	THEN h0.hv005::Float / 1000000 ELSE 0 END) as Num_Wt

FROM
dhs_data_tables."RECH1" h1
LEFT OUTER JOIN 
	dhs_data_tables."RECH5" h5
	ON h1.surveyid = h5.surveyid AND h1.hhid = h5.hhid and h1.hvidx = h5.ha0
INNER JOIN -- we have to join to hh data to get the cluster id for grouping and location info
	dhs_data_tables."RECH0" h0
	-- dirty, but this is how it works
	ON h1.surveyid = h0.surveyid AND h1.hhid = h0.hhid
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
ON h0.hv001::Integer = locs.clusterid AND h0.surveyid::Integer = locs.surveyid

WHERE h0.surveyid='{SURVEYID}'
--WHERE h0.surveyid='437'	
GROUP BY h0.hv001
ORDER BY h0.hv001::Integer

--)clust