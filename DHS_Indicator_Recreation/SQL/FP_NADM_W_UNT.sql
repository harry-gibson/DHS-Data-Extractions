-- FP_NADM_W_UNT
-- Unmet need for family planning

-- As with FP_CUSM_W_MOD I have selected "living with partner" as well as "married" women to match the API
-- values, contrary to what is in the stata code

--select sum(denom_nonwt) d_nw, sum(denom_wt) d_w, sum(num_wt) / sum(denom_wt) val from (
SELECT
-- PERMA-BUMPH - same for all indicator extractions
h0.hv001 as clusterid
-- there is 1:0-1 join between cluster id and locs.* but as we're doing it inside the individual-level query
-- i.e. pre-grouping (to avoid another nested query) we need to use an aggregate func here
, min(locs.latitude) as latitude
, min(locs.longitude) as longitude
, min(locs.dhsid) as dhsid
, min(locs.urban_rural) as urban_rural

-- DENOMINATOR (UNWEIGHTED)
, SUM(	
	CASE WHEN 
        -- unlike others this indicator is spec'd as "married OR in union". doesn't actually seem to make any difference though!
        r51_mge.v501::Integer in (1,2) 
        AND 
        r01_wmn.v012::Integer BETWEEN 15 and 49 -- this SHOULD be redundant, they are only in the table if they're in those ages
	THEN 1 ELSE 0 END) as Denom_NonWt

-- DENOMINATOR (WEIGHTED)    
, SUM(
    CASE WHEN 
        r51_mge.v501::Integer in (1,2)
        AND 
        r01_wmn.v012::Integer BETWEEN 15 and 49
	THEN r01_wmn.v005::Float / 1000000 ELSE 0 END) as Denom_Wt
    
-- NUMERATOR (UNWEIGHTED)
, SUM(
    CASE WHEN 
	r51_mge.v501::Integer in (1,2) 
        AND 
        r01_wmn.v012::Integer BETWEEN 15 and 49 
        AND
        -- From stata code provided: "unmet need for contraception definition 3" = "unmet need for spacing" or "unmet need for limiting"
        r61_fert.v626a::Integer in (1,2)
	THEN 1 ELSE 0 END) as Num_NonWt
    
 -- NUMERATOR (WEIGHTED)
, SUM(
    CASE WHEN 
	r51_mge.v501::Integer in (1,2) 
        AND 
        r01_wmn.v012::Integer BETWEEN 15 and 49 
        AND
        r61_fert.v626a::Integer in (1,2)
	THEN r01_wmn.v005::Float / 1000000 ELSE 0 END) as Num_Wt

FROM
dhs_data_tables."REC01" r01_wmn

LEFT OUTER JOIN 
	dhs_data_tables."REC51" r51_mge
	ON r01_wmn.surveyid = r51_mge.surveyid AND r01_wmn.caseid = r51_mge.caseid

LEFT OUTER JOIN 
	dhs_data_tables."REC61" r61_fert
	ON r01_wmn.surveyid = r61_fert.surveyid AND r01_wmn.caseid = r61_fert.caseid

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