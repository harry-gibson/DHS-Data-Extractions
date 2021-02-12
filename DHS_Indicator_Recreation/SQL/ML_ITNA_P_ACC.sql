-- ML_ITNA_P_ACC
-- Percenttage of defacto population who had access to an ITN assuming each ITN could hold up to 2 ppl

-- Denominator is defacto household population (those who actually slept there)
-- Numerator is min of (2*num ITNs, defacto hh population)

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
		True -- this case statement is redundant of course, just copy-pasted from another query
	THEN h0.hv013::Integer ELSE 0 END) as Denom_NonWt

-- DENOMINATOR (WEIGHTED)
, SUM(
	CASE WHEN 
		True
	THEN h0.hv013::Integer * (h0.hv005::Float / 1000000) ELSE 0 END) as Denom_Wt

-- NUMERATOR (UNWEIGHTED)	
, SUM(
	-- if theoretical capacity is > hh defacto pop then use defacto pop
	LEAST (
		COALESCE(hh_nets.theoretical_net_capacity, 0),
		h0.hv013::Integer
	)) as Num_NonWt
	
-- NUMERATOR (WEIGHTED)	
, SUM(	
	LEAST (
		COALESCE(hh_nets.theoretical_net_capacity, 0),
		h0.hv013::Integer
	) * (h0.hv005::Float / 1000000) ) as Num_Wt

FROM
dhs_data_tables."RECH0" h0

LEFT OUTER JOIN 
	-- Subquery to total the ITN theoretical capacity per household (may be > the actual hh pop)
	-- Note the need for an outer join as we don't want to exclude (from the denominator) households
	-- with NO nets
	(SELECT
		hhid
		, surveyid
		, SUM (CASE WHEN hml10::Integer = 1 THEN 2 ELSE 0 END) AS theoretical_net_capacity
	FROM
		dhs_data_tables."RECHML" hml
	GROUP BY hml.hhid, hml.surveyid
	) hh_nets
	ON hh_nets.hhid = h0.hhid AND hh_nets.surveyid = h0.surveyid 

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
--WHERE h0.surveyid='465'
	
GROUP BY h0.hv001
ORDER BY h0.hv001::Integer

--)clust