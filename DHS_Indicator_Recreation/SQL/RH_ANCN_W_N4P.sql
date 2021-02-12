-- RH_ANCN_4_N4P

-- Percentage of (all mothers who have had at least one live birth in the last 5 years) for
-- which (at least 4 antenatal care visits were received for at least one such birth)

-- We don't make any actual checks for the child's age: just whether they have an entry in the maternity table

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
		-- This should actually be redundant with an INNER join on the maternity table as that
		-- should by definition be one entry for each birth in last 5 years. 
		True
		THEN 1 ELSE 0 END) as Denom_NonWt

-- DENOMINATOR (WEIGHTED)
, SUM(
	CASE WHEN 
		-- This should actually be redundant with an INNER join on the maternity table as that
		-- should by definition be one entry for each birth in last 5 years. 
		True
	THEN r01_wmn.v005::Float / 1000000 ELSE 0 END) as Denom_Wt

-- NUMERATOR (UNWEIGHTED)	
, SUM(
	CASE WHEN 
		wmn_anc.anc_4plus = 1
	THEN 1 ELSE 0 END) as Num_NonWt
	
-- NUMERATOR (WEIGHTED)	
, SUM(	
	CASE WHEN 
		wmn_anc.anc_4plus = 1
	THEN r01_wmn.v005::Float / 1000000 ELSE 0 END) as Num_Wt

FROM
dhs_data_tables."REC01" r01_wmn
INNER JOIN 
	(SELECT 
		surveyid
		, caseid
		, MAX( CASE WHEN 
			r41.m14::Integer BETWEEN 4 AND 60 
			THEN 1 ELSE 0 END 
		) as anc_4plus
		FROM dhs_data_tables."REC41" r41 
		group by surveyid, caseid
	) wmn_anc
	ON wmn_anc.surveyid = r01_wmn.surveyid and wmn_anc.caseid = r01_wmn.caseid

INNER JOIN -- we have to join to hh data to get the cluster id for grouping and location info
	dhs_data_tables."RECH0" h0
	-- dirty, but this is how it works
	ON r01_wmn.surveyid = h0.surveyid AND LEFT(r01_wmn.caseid, -3) = h0.hhid
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
--WHERE h0.surveyid='451'
-- tried putting denominator filter clause here but it breaks indexing and makes query v slow
--AND (r01_wmn.v008::Integer - r21_kids.b3::Integer )between 12 and 23
--AND r21_kids.b5::Integer = 1
GROUP BY h0.hv001
ORDER BY h0.hv001::Integer

--)clust