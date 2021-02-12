-- ED_LITR_M_LIT

-- Percentage of men aged 15-49 who are literate

-- Denominator is all men aged 15-49
-- Numerator is all men aged 15-49 who are literate
-- Note that "literate" includes "able to read only parts of sentence" as well as "able to read whole sentence", 
-- as deduced from checking against API data, whereas Clara's code only selects the latter value

--select sum(denom_nonwt) d_nw, sum(denom_wt) d_w, sum(num_wt) / sum(denom_wt) val from (

SELECT
-- PERMA-BUMPH - same for all indicator extractions
m1.mv001 as clusterid
-- there is 1:1 join between cluster id and locs.* but as we're doing it inside the individual-level query
-- i.e. pre-grouping (to avoid another nested query) we need to use an aggregate func here
, min(locs.latitude) as latitude
, min(locs.longitude) as longitude
, min(locs.dhsid) as dhsid
, min(locs.urban_rural) as urban_rural

-- DENOMINATOR (UNWEIGHTED)
, SUM(	
	CASE WHEN 
		m1.mv012::Integer BETWEEN 15 and 49 -- this is probably always true but may be survey dependent
	THEN 1 ELSE 0 END) as Denom_NonWt

-- DENOMINATOR (WEIGHTED)
, SUM(
	CASE WHEN 
		m1.mv012::Integer BETWEEN 15 and 49
	THEN m1.mv005::Float / 1000000 ELSE 0 END) as Denom_Wt

-- NUMERATOR (UNWEIGHTED)	
, SUM(
	CASE WHEN 
		m1.mv012::Integer BETWEEN 15 and 49
		AND
		(m11.mv155::Integer in (1,2)
		OR
		m11.mv106::Integer in (2,3))
	THEN 1 ELSE 0 END) as Num_NonWt
	
-- NUMERATOR (WEIGHTED)	
, SUM(	
	CASE WHEN 
		m1.mv012::Integer BETWEEN 15 and 49
		AND
		(m11.mv155::Integer in (1,2)
		OR
		m11.mv106::Integer in (2,3))
	THEN m1.mv005::Float / 1000000 ELSE 0 END) as Num_Wt

FROM
dhs_data_tables."MREC01" m1
LEFT OUTER JOIN 
	dhs_data_tables."MREC11" m11
	ON m1.surveyid = m11.surveyid AND m1.mcaseid = m11.mcaseid
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
ON m1.mv001::Integer = locs.clusterid AND m1.surveyid::Integer = locs.surveyid

WHERE m1.surveyid='{SURVEYID}'
	
GROUP BY m1.mv001
ORDER BY m1.mv001::Integer

--)clust