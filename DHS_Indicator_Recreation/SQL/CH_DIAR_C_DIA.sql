-- CH_DIAR_C_DIA
-- Percentage of children aged under 5 who have had diarrhoea in last 2 weeks

-- Denominator is all children aged 0-59 months who are alive
-- Numerator is all children aged 0-59 months who are alive and have had the shits

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
		-- Might be better to put select 1 and weight in a CTE and then join that and sum it here
		-- but this way is pretty fast
		(r01_wmn.v008::Integer - r21_kids.b3::Integer ) < 60
		AND 
		r21_kids.b5::Integer = 1
	THEN 1 ELSE 0 END) as Denom_NonWt

-- DENOMINATOR (WEIGHTED)
, SUM(
	CASE WHEN 
		(r01_wmn.v008::Integer - r21_kids.b3::Integer ) < 60
		AND 
		r21_kids.b5::Integer = 1
	THEN r01_wmn.v005::Float / 1000000 ELSE 0 END) as Denom_Wt

-- NUMERATOR (UNWEIGHTED)	
, SUM(
	CASE WHEN 
		(r01_wmn.v008::Integer - r21_kids.b3::Integer ) < 60
		AND 
		r21_kids.b5::Integer = 1
		AND
		r43.h11::Integer BETWEEN 1 and 2 --inclusive
	THEN 1 ELSE 0 END) as Num_NonWt
	
-- NUMERATOR (WEIGHTED)	
, SUM(	
	CASE WHEN 
		(r01_wmn.v008::Integer - r21_kids.b3::Integer ) < 60
		AND 
		r21_kids.b5::Integer = 1
		AND
		r43.h11::Integer BETWEEN 1 and 2 --inclusive
	THEN r01_wmn.v005::Float / 1000000 ELSE 0 END) as Num_Wt

FROM
-- this indicator is coded in terms of children so we can either specify the children as the 
-- leftmost table (as done here) or we could group the children into women with a subquery
dhs_data_tables."REC21" r21_kids
INNER JOIN 
	dhs_data_tables."REC01" r01_wmn
	ON r21_kids.surveyid = r01_wmn.surveyid and r21_kids.caseid = r01_wmn.caseid
LEFT OUTER JOIN
	dhs_data_tables."REC43" r43
	ON r21_kids.surveyid = r43.surveyid and r21_kids.caseid = r43.caseid and r21_kids.bidx = r43.hidx
LEFT OUTER JOIN 
	dhs_data_tables."REC95" r95
	ON r21_kids.surveyid = r95.surveyid and r21_kids.caseid = r95.caseid and r21_kids.bidx = r95.idx95

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

WHERE h0.surveyid= '438' -- '{SURVEYID}'
-- tried putting denominator filter clause here but it breaks indexing and makes query v slow
--AND (r01_wmn.v008::Integer - r21_kids.b3::Integer )between 12 and 23
--AND r21_kids.b5::Integer = 1
GROUP BY h0.hv001
ORDER BY h0.hv001::Integer

--)clust