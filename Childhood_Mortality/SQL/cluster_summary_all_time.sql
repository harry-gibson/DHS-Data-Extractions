-- Estimate childhood mortality for neonatal (age < 1 month); infant (age < 12 months); and 
-- under-5 (age < 60 months) age bands.
-- Values are for "all time" i.e. the denominators are all children who have ever been born 
-- whose birthday was at least 60 months before survey date for U5, etc. NB this is a simplification 
-- as it excludes children who are alive but have not yet reached the max age for the interval from the
-- denominator calculation (The DHS method allocates them a risk of 0.5, which doesn't seem a
-- lot better!)

-- DHS ALL-TIME CHILDHOOD MORTALITY
WITH 
consts as (SELECT 
				60 AS max_age_u5,
			   	12 AS max_age_inf,
			   	1 AS max_age_nn
),
mort as (SELECT 
	surveyid, clusterid, lat, lon,

	-- U5
	-- Denominator: all children who were born at least 60 months before survey 
	--  			plus those who were born later but have died
	SUM (
		CASE WHEN 
			v008_int_cmc - b3_dob_cmc >= consts.max_age_u5 
				OR  
			b7_death_age_months < consts.max_age_u5
			THEN sample_wt::FLOAT/1000000
			ELSE 0 END
		) as denom_u5,
	-- Numerator: of all children who were born at least 60 months before survey 
    --			  plus those who were born later but have died, those who have died 
	--			  at < 60 months age
	SUM (
		CASE WHEN 
			(v008_int_cmc - b3_dob_cmc >= consts.max_age_u5
				OR  
			b7_death_age_months < consts.max_age_u5)
				AND b5_is_alive=0 AND b7_death_age_months < consts.max_age_u5
			THEN sample_wt::FLOAT/1000000 
			ELSE 0 END
		) AS num_u5,
	
	-- Infant
	-- Denominator: all children who were born at least 12 months before survey 
	--  			plus those who were born later but have died
	SUM (
		CASE WHEN 
			v008_int_cmc - b3_dob_cmc >= consts.max_age_inf 
				OR  
			b7_death_age_months < consts.max_age_inf
			THEN sample_wt::FLOAT/1000000 
			ELSE 0 END
		) as denom_inf,
	-- Numerator: of all children who were born at least 12 months before survey 
    --			  plus those who were born later but have died, those who have died 
	--			  at < 12 months age
	SUM (
		CASE WHEN 
			(v008_int_cmc - b3_dob_cmc >= consts.max_age_inf 
				OR
			b7_death_age_months < consts.max_age_inf)
				AND b5_is_alive=0 AND b7_death_age_months < consts.max_age_inf
			THEN sample_wt::FLOAT/1000000 
			ELSE 0 END
		) AS num_inf,

	-- Neonatal	
	-- Denominator: all children who were born at least 1 month before survey 
	--  			plus those who were born later but have died
	SUM (
		CASE WHEN 
			(v008_int_cmc - b3_dob_cmc >= consts.max_age_nn 
				OR
			b7_death_age_months < consts.max_age_inf)
			THEN sample_wt::FLOAT/1000000 
			ELSE 0 END
		) as denom_nn,
	-- Numerator: of all children who were born at least 1 month before survey 
    --			  plus those who were born later but have died, those who have died 
	--			  at < 1 months age
	SUM (
		CASE WHEN 
			(v008_int_cmc - b3_dob_cmc >= consts.max_age_nn 
				OR
			b7_death_age_months < consts.max_age_nn)
				AND b5_is_alive=0 AND b7_death_age_months < consts.max_age_nn
			THEN sample_wt::FLOAT/1000000 
			ELSE 0 END
		) AS num_nn,

	-- weighted total children in group		
	SUM (sample_wt::FLOAT/1000000) AS tot,
	-- unweighted total children in group
	count(*) AS nrows
	FROM dhs_data_summary.child_mortality_raw, consts
	GROUP BY surveyid, clusterid, lat, lon
)

SELECT surveyid, clusterid, lat, lon,
	CASE WHEN denom_u5>0 THEN num_u5 / denom_u5 ELSE null END AS mort_u5,
	CASE WHEN denom_inf>0 THEN num_inf / denom_inf ELSE null END AS mort_inf,
	CASE WHEN denom_nn>0 THEN num_nn / denom_nn ELSE null END AS mort_nn
	FROM mort
WHERE denom_u5 != 0
ORDER BY surveyid::INTEGER, clusterid::INTEGER