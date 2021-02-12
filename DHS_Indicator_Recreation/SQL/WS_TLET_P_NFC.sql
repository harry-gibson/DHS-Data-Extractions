-- WS_TLET_P_NFC
-- Bushpoopers: Percentage of dejure population living in households with main toilet facility being "no facility"

-- Denominator is dejure population of households
-- Numerator is dejure population of households that have no shitter

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
		-- obv this is redundant but i'm just copy-pasting sql here
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
		h2.hv205::Integer = 31
		
	THEN h0.hv012::Integer ELSE 0 END) as Num_NonWt
	
-- NUMERATOR (WEIGHTED)	
, SUM(	
	CASE WHEN 
		h2.hv205::Integer = 31
		
	THEN h0.hv012::Integer * (h0.hv005::Float / 1000000) ELSE 0 END) as Num_Wt

FROM
-- this indicator is coded in terms of children so we can either specify the children as the 
-- leftmost table (as done here) or we could group the children into women with a subquery
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
-- tried putting denominator filter clause here but it breaks indexing and makes query v slow
--and h0.hv2::Integer = 1
GROUP BY h0.hv001
ORDER BY h0.hv001::Integer

--)clust