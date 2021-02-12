-- RH_DELP_C_DHF

-- Percentage of all live births in the last 5 years that were delivered at a healthcare facility.
-- Note there was some discussion over whether this was indeed the correct definition or if it 
-- should be percentage of most-recent births in the last 5 years that were DHF.

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
		r21_kids.b8::Integer < 5 -- aged under 5 
		OR 
		r21_kids.b5::Integer = 0 -- or dead
		THEN 1 ELSE 0 END) as Denom_NonWt

-- DENOMINATOR (WEIGHTED)
, SUM(
	CASE WHEN 
		-- This should actually be redundant with an INNER join on the maternity table as that
		-- should by definition be one entry for each birth in last 5 years. 
		r21_kids.b8::Integer < 5 
		OR 
		r21_kids.b5::Integer = 0
	THEN r01_wmn.v005::Float / 1000000 ELSE 0 END) as Denom_Wt

-- NUMERATOR (UNWEIGHTED)	
, SUM(
	CASE WHEN 
		(r21_kids.b8::Integer < 5 OR r21_kids.b5::Integer = 0)
		AND
		r41.m15::Integer BETWEEN 13 AND 47
	THEN 1 ELSE 0 END) as Num_NonWt
	
-- NUMERATOR (WEIGHTED)	
, SUM(	
	CASE WHEN 
	(r21_kids.b8::Integer < 5 OR r21_kids.b5::Integer = 0)
	AND
		r41.m15::Integer BETWEEN 13 AND 47
	THEN r01_wmn.v005::Float / 1000000 ELSE 0 END) as Num_Wt

FROM
-- this indicator is coded in terms of children so we can either specify the children as the 
-- leftmost table (as done here) or we could group the children into women with a subquery
dhs_data_tables."REC21" r21_kids
INNER JOIN 
	dhs_data_tables."REC01" r01_wmn
	ON r21_kids.surveyid = r01_wmn.surveyid and r21_kids.caseid = r01_wmn.caseid
INNER JOIN -- inner join to get only ones with entries in maternity table (= alive and less than 5)
	dhs_data_tables."REC41" r41
	ON r21_kids.surveyid = r41.surveyid and r21_kids.caseid = r41.caseid and r21_kids.bidx = r41.midx

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
-- tried putting denominator filter clause here but it breaks indexing and makes query v slow
--AND (r01_wmn.v008::Integer - r21_kids.b3::Integer )between 12 and 23
--AND r21_kids.b5::Integer = 1
GROUP BY h0.hv001
ORDER BY h0.hv001::Integer

--)clust