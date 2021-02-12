-- FP_CUSM_W_MOD
-- Married women currently using any modern method of contraception


-- To match the API values I have selected women who are married OR "currently living with partner" (2)
-- This is contrary to what is in the stata code.

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
, SUM(  CASE WHEN 
            r51_mge.v501::Integer in (1,2) -- married
        THEN 1 ELSE 0 END) as denom_nonwt

-- DENOMINATOR (WEIGHTED)      
, SUM(  CASE WHEN 
            r51_mge.v501::Integer in (1,2) -- married
        THEN r01_wmn.v005::Float / 1000000 ELSE 0 END) as denom_wt
        
-- NUMERATOR (UNWEIGHTED)
, SUM(  CASE WHEN 
	    r51_mge.v501::Integer in (1,2) -- married
	    AND
            (r32_cont.v364::Integer = 1 -- using "modern method"
            OR -- what the stata code says is modern, prob survey dependent but it seems ok
            r32_cont.v312::Integer in (1,2,3,4,5,6,7,11,13,14,15,17,18,19)  
            )
        THEN 1 ELSE 0 END) as num_nonwt
        
 -- NUMERATOR (WEIGHTED)
, SUM(  CASE WHEN 
	    r51_mge.v501::Integer in (1,2) -- married
	    AND
            (r32_cont.v364::Integer = 1 -- using "modern method"
            OR -- what the stata code says is modern, prob survey dependent but it seems ok
            r32_cont.v312::Integer in (1,2,3,4,5,6,7,11,13,14,15,17,18,19)  
            )
        THEN r01_wmn.v005::Float / 1000000 ELSE 0 END) as num_wt
        
FROM
dhs_data_tables."REC01" r01_wmn
INNER JOIN 
	dhs_data_tables."REC32" r32_cont
	ON
	r01_wmn.surveyid = r32_cont.surveyid AND r01_wmn.caseid = r32_cont.caseid
INNER JOIN 
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
	
GROUP BY h0.hv001
ORDER BY h0.hv001::Integer

--)clust