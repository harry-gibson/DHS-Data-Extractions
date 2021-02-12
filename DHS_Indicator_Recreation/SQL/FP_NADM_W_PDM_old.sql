-- FP_NADM_W_PDM
-- Demand for family planning that is satisfied by modern methods
-- Denominator is all married women who are either using modern or traditional 
-- 	contraception or who have an unmet need for it
-- Numerator is married women who are using modern contraception

-- I cannot make the absolute figures match those in the API for any survey, they are often
-- different by a factor of 2 or more. However the percentage figures do all match to within 0.1%!
-- So I reckon something is wrong with the data in the API.


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
		r51_mge.v501::Integer in (1,2) -- married or in union
		--True
		AND 
		(
			r32_cont.v364::Integer in (1,2) -- using modern OR other contraception
			--OR
			--r32_cont.v312::Integer BETWEEN 1 and 20 --in (1,2,3,4,5,6,7,11,13,14,15,17,18,19)  
			OR
			r61_fert.v626a::Integer in (1,2) -- has unmet need for contraception
		)
	THEN 1 ELSE 0 END) as Denom_NonWt

-- DENOMINATOR (WEIGHTED)
, SUM(
	CASE WHEN 
		r51_mge.v501::Integer in (1,2) -- married
		AND 
			(r32_cont.v364::Integer in (1,2) -- using modern OR other contraception
			--OR
			--r32_cont.v312::Integer BETWEEN 1 and 20 --in (1,2,3,4,5,6,7,11,13,14,15,17,18,19)  
			OR
			r61_fert.v626a::Integer in (1,2) -- has unmet need for contraception
			)
	THEN r01_wmn.v005::Float / 1000000 ELSE 0 END) as Denom_Wt

-- NUMERATOR (UNWEIGHTED)	
, SUM(
	CASE WHEN 
		r51_mge.v501::Integer in (1,2)
		AND
			-- married and using modern contraception
			(r32_cont.v364::Integer in (1)
			--OR
			--r32_cont.v312::Integer in (1,2,3,4,5,6,7,11,13,14,15,17,18,19)  
			)
	THEN 1 ELSE 0 END) as Num_NonWt
	
-- NUMERATOR (WEIGHTED)	
, SUM(	
	CASE WHEN 
		r51_mge.v501::Integer in (1,2)
		AND
			-- married and using modern contraception
			(r32_cont.v364::Integer in (1)
			--OR
			--r32_cont.v312::Integer in (1,2,3,4,5,6,7,11,13,14,15,17,18,19)  
			)
	THEN r01_wmn.v005::Float / 1000000 ELSE 0 END) as Num_Wt

FROM
dhs_data_tables."REC01" r01_wmn
LEFT OUTER JOIN 
	dhs_data_tables."REC61" r61_fert
	ON r01_wmn.surveyid = r61_fert.surveyid AND r01_wmn.caseid = r61_fert.caseid
LEFT OUTER JOIN 
	dhs_data_tables."REC32" r32_cont
	ON r01_wmn.surveyid = r32_cont.surveyid AND r01_wmn.caseid = r32_cont.caseid
LEFT OUTER JOIN 
	dhs_data_tables."REC51" r51_mge
	ON r01_wmn.surveyid = r51_mge.surveyid AND r01_wmn.caseid = r51_mge.caseid

INNER JOIN
	dhs_data_tables."RECH0" h0
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
	
GROUP BY h0.hv001
ORDER BY h0.hv001::Integer

--)clust