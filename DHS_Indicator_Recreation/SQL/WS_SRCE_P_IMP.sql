-- WS_SRCE_P_IMP
-- Percentage of dejure population who live in a house with an improved water source

-- Denominator is all dejure population
-- Numerator is all dejure population who live in a house with an improved water source.

-- Not sure how static the definition of "improved" really is!!

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
		-- it might seem better to move the the denominator test to a where clause in this query
		-- then just count rows here but that makes the query ~50* slower presumably as the indexes don't get hit

		True
	THEN h0.hv012::Integer ELSE 0 END) as Denom_NonWt

-- DENOMINATOR (WEIGHTED)
, SUM(
	CASE WHEN 
		True
	THEN h0.hv012::Integer * (h0.hv005::Float / 1000000) ELSE 0 END) as Denom_Wt

-- NUMERATOR (UNWEIGHTED)	
, SUM(
	CASE WHEN 
		(h2.hv201::Integer IN (11,12,13,14,21,31,41,51,71)
		OR 
		-- 72 (plastic bag of water) wasn't counted as modern at the time of the togo survey
		h2.hv201::Integer = 72 and not h0.surveyid::Integer = 328
		)
		
	THEN h0.hv012::Integer ELSE 0 END) as Num_NonWt
	
-- NUMERATOR (WEIGHTED)	
, SUM(	
	CASE WHEN 
		(h2.hv201::Integer IN (11,12,13,14,21,31,41,51,71)
		OR 
		-- 72 (plastic bag of water) wasn't counted as modern at the time of the togo survey
		h2.hv201::Integer = 72 and not h0.surveyid::Integer in (328,438)
		)
		
	THEN h0.hv012::Integer * (h0.hv005::Float / 1000000) ELSE 0 END) as Num_Wt

FROM
dhs_data_tables."RECH0" h0
INNER JOIN 
	dhs_data_tables."RECH2" h2
	ON h0.surveyid = h2.surveyid and h0.hhid = h2.hhid
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
--WHERE h0.surveyid='438'
GROUP BY h0.hv001
ORDER BY h0.hv001::Integer

--)clust