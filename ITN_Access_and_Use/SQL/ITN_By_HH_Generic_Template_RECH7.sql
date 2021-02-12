--Select from the household-level subqueries but don't aggregate (hh level output)
SELECT 
	h0.hv001 as ClusterID
	, h0.hhid as HHID
	, h0.hv006 as interview_month
	, h0.hv007 as interview_year
	, h0.hv005 as hh_sample_wt
	-- use aggregation on the lat/lon to save another subquery / group clause; the value is always the same per cluster though.
	, COALESCE ((locs.latitude)::text, 'NA') as latitude
	, COALESCE ((locs.longitude)::text, 'NA') as longitude
	, CASE WHEN (locs.latitude) IS NULL THEN 'NA' ELSE 'GPS' END as location_src
	-- n children under 5 (the nets table gives "corrected age" rather than just age - use this rather than schedule count
		--, sum(sched.n_u5_sched) as n_pop_u5
	, COALESCE(person_nets.n_u5_nettbl, 0) as n_pop_u5
	-- n children under 5 slept under ITN
	, COALESCE(person_nets.n_u5_under_itn, 0) as n_u5_under_itn
	-- n pregnant women total
	, COALESCE(person_nets.n_preg_tot, 0) as n_preg_tot
	-- n pregnant women slept under ITN
	, COALESCE(person_nets.n_preg_under_itn, 0) as n_preg_under_itn
	-- n individuals that slept last night (de facto)
	, (h0.hv013::Integer) as n_defacto_pop
	-- n de facto that slept under ITN
	, COALESCE(person_nets.n_tot_under_itn, 0) as n_slept_under_itn
	-- n households
		-- this gives the actual number of hh in the cluster :
	--, count(distinct h0.hhid) as n_hh_tot
	-- however in our old data the n_hh is counted only as the number with any entries in the nets table,
	-- whether or not those entries related to ITN nets. So some houesholds with no ITNs would be counted (e.g.
	-- if they had some untreated nets and therefore entries in the table) whereas others would not.
	, COALESCE(person_nets.hh_with_net_tbl_entry, 0) as hh_has_entry_in_net_tbl
	, (h0.hv013::Float) as hh_size
	-- Use COALESCE on all fields extracted via outer joins, so our output shows 0 rather than blanks/nulls
	-- n ITNs
	, COALESCE((hh_nets.num_itn), 0) as n_itn
	-- n hh with ITNs
	, (CASE WHEN COALESCE(hh_nets.num_itn, 0) > 0 THEN 1 ELSE 0 END) as hh_has_itn
	-- n hh with >= 1 ITN per 2 ppl
		--, sum(CASE WHEN COALESCE(hh_nets.num_itn, 0) >= (CEIL(h0.hv013::Float / 2)) THEN 1 ELSE 0 END) as n_hh_with_enough_itn
	-- unclear if we want to count all houesholds or exclude empty ones? i.e. does a house with 0 ppl and 0 nets count as "enough nets"?
	, (CASE WHEN COALESCE(hh_nets.theoretical_net_capacity, 0) >= h0.hv013::Integer 
		OR h0.hv013::Integer is null THEN 1 ELSE 0 END) as hh_has_enough_itn
	, (CASE WHEN COALESCE(hh_nets.theoretical_net_capacity, 0) >= h0.hv013::Integer 
		AND h0.hv013::Integer > 0 THEN 1 ELSE 0 END) as occ_hh_has_enough_itn
	-- ITN capacity (2 people per ITN but capped at the actual hh pop)
	, (LEAST (
		COALESCE(hh_nets.theoretical_net_capacity, 0), 
		(h0.hv013::Integer)
		)
	  ) as itn_theoretical_capacity
	-- n ITNs used
	, COALESCE((hh_nets.n_itn_used),0) as n_itn_used
-- ** TO CHECK
	, COALESCE((hh_nets.n_conv_itn), 0) as n_conv_itn
	-- n LLINs - this seems to match
	, COALESCE((hh_nets.n_llin), 0) as n_llin
	-- n LLINs under 1 yr old
	, COALESCE((hh_nets.n_llin_1yr), 0) as n_llin_1yr
	-- n LLINs 1-2 yrs
	, COALESCE((hh_nets.n_llin_1_2yr), 0) as n_llin_1_2yr
	-- n LLINs 2-3 yrs
	, COALESCE((hh_nets.n_llin_2_3yr), 0) as n_llin_2_3yr
	-- n LLINs 3+ yrs
	, COALESCE ((hh_nets.n_llin_gt3yr), 0) as n_llin_gt3yr

FROM
	-- The main household table
	dhs_data_tables."RECH0" h0 
	-- Summarise household schedule (one row per individual) by household and join that
	LEFT OUTER JOIN 
		-- An inner join should actually be safe for the schedule
		-- Also I don't think we actually need any of the schedule vars after all
		(SELECT 
			hhid, surveyid
			, count (*) schedtot
			, sum(CASE WHEN hv105::Integer < 5 THEN 1 ELSE 0 END) n_u5_sched
			
		FROM 
			dhs_data_tables."RECH1" h1 
		GROUP BY h1.hhid, h1.surveyid
		) sched 
	ON
		h0.hhid = sched.hhid AND h0.surveyid = sched.surveyid

	-- Summarise net table (one row per net) by household and join that
	LEFT OUTER JOIN
		-- The nets table (data about individual nets, one row per net)
		-- Use an outer join because we care about all households even if they don't have nets
		(SELECT 
			hhid, surveyid
			, count(*) num_nets
			, SUM (CASE WHEN hml10::Integer = 1 THEN 1 ELSE 0 END) AS num_itn -- any type of net with valid treatment
			, SUM (CASE WHEN hml10::Integer = 1 THEN 2 ELSE 0 END) AS theoretical_net_capacity
			, SUM (CASE WHEN hml11::Integer <= 5 THEN (hml11::Integer) ELSE 0 END) AS n_slept_under_nets
			, SUM (CASE WHEN (hml21::Integer = 1 OR hml11::Integer BETWEEN 1 AND 5) and hml10::Integer = 1 
				THEN 1 ELSE 0 END) AS n_itn_used
				-- flagged as permanent treatment:
			, SUM (CASE WHEN hml6::Integer = 1 OR hml8::Integer = 2 THEN 1 ELSE 0 END) as n_llin
				-- "Conventional" ITN: see https://elifesciences.org/content/4/e09672#app1 para 2.3
				-- is when it's not permanent, but has  been bought or treated in last 12 months
			, SUM (CASE WHEN hml10::Integer = 1
				AND hml6::Integer <> 1 -- treatment other than permanent
				AND hml8::Integer <> 2 -- treatment other than permanent (alternative location)
					-- the timings may not be strictly necessary as the hml10 var seems to be only set 
					-- in agreement with these timing checks. Not sure if always the case, though.
				AND (COALESCE(hml.hml4::Integer <= 12, FALSE) -- bought within last 12 months
				OR COALESCE(hml.hml9::Integer <= 12, FALSE)) -- retreated within last 12 months
				THEN 1 ELSE 0 END) as n_conv_itn
			, SUM (CASE WHEN (hml.hml4::Integer <= 12  		AND (hml6::Integer = 1 OR hml8::Integer = 2)) 
				THEN 1 ELSE 0 END) as n_llin_1yr
			, SUM (CASE WHEN (hml.hml4::Integer BETWEEN 13 AND 24  	AND (hml6::Integer = 1 OR hml8::Integer = 2)) 
				THEN 1 ELSE 0 END) as n_llin_1_2yr
			, SUM (CASE WHEN (hml.hml4::Integer BETWEEN 25 AND 36  	AND (hml6::Integer = 1 OR hml8::Integer = 2)) 
				THEN 1 ELSE 0 END) as n_llin_2_3yr
			, SUM (CASE WHEN (hml.hml4::Integer > 36 		AND (hml6::Integer = 1 OR hml8::Integer = 2)) 
				THEN 1 ELSE 0 END) as n_llin_gt3yr
		FROM 		
			dhs_data_tables."RECH7" hml 
		GROUP BY hml.hhid, hml.surveyid
		) hh_nets
	ON
		hh_nets.hhid = h0.hhid AND hh_nets.surveyid = h0.surveyid

	-- Summarise people-under-nets table (one row per person who used a net) by hh and join that
	LEFT OUTER JOIN 
		-- The people-using-nets table (data about people and their net use, one row per person)
		-- Again we need to use an outer join, but effectively in our old data we didn't and only counted rows where 
		-- an entry was present in this table (even if that entry didn't answer net questions)
		(SELECT
			hhid, surveyid
			, 1 AS hh_with_net_tbl_entry
			, sum(CASE WHEN hml16::Integer < 5 THEN 1 ELSE 0 END) AS n_u5_nettbl
			, sum(CASE WHEN hml16::Integer < 5 AND hml12::Integer IN (1) THEN 1 ELSE 0 END) AS n_u5_under_itn
			, sum(CASE WHEN hml18::Integer = 1 THEN 1 ELSE 0 END) AS n_preg_tot
			, sum(CASE WHEN hml18::Integer = 1 AND hml12::Integer IN (1) THEN 1 ELSE 0 END) as n_preg_under_itn
			, sum(CASE WHEN hml12::Integer IN (1) THEN 1 ELSE 0 END) as n_tot_under_itn
		FROM
			dhs_data_tables."RECHMH" hmh
		GROUP BY hmh.hhid, hmh.surveyid
		) person_nets
	ON 
		h0.hhid = person_nets.hhid AND h0.surveyid = person_nets.surveyid

	-- Get the cluster loc data - one row per every cluster but we'll join at hh level and then re-summarise to cluster cos we're lazy
	LEFT OUTER JOIN 
		(SELECT 
			surveyid
			, dhsclust as clusterid
			, latnum as latitude
			, longnum as longitude
		FROM
			dhs_data_locations.dhs_cluster_locs
		) locs
	ON 
		h0.hv001::Integer = locs.clusterid AND h0.surveyid::Integer = locs.surveyid
	
WHERE 
	h0.surveyid = '{SURVEYID}'-- '{SURVEYID}'--'363'--425	
-- GROUP BY h0.hv001
ORDER BY h0.hv001::Integer, h0.hhid