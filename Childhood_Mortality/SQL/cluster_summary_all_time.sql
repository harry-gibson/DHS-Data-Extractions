-- Estimate childhood mortality for neonatal (age < 1 month); infant (age < 12 months); and 
-- under-5 (age < 60 months) age bands.
-- Values are for "all time" i.e. the denominators are all children who have ever been born,
-- there is no "start of window" cutoff, and the "end of window" is the survey date. The
-- results will therefore generally be higher than the published DHS five and ten year mortality
-- figures, because childhood mortality is generally decreasing over time, and they will be more
-- different in countries where the decrease is greater (e.g. Senegal) than in countries where the
-- trend is flatter (e.g. DRC).

-- Children are counted fully in the denominator whose birthday was at least 60 months
-- before survey date for U5, etc, whilst those who have not yet reached this age are
-- counted as half. The numerator is counted from the same criteria except that the child
-- must have also have died by the cutoff age. (These fractions are taken from the DHS
-- calculations of child mortality).

-- DHS ALL-TIME CHILDHOOD MORTALITY
WITH 
consts as (SELECT
				60 AS max_age_u5,
			   	12 AS max_age_inf,
			   	1 AS max_age_nn
),
mort as (SELECT 
	surveyid, clusterid, lat, lon,

	-- Under-5
	-- Denominator: all children who were born at least 60 months before survey
	--              count as 1; all those born later count as 0.5
	SUM (
		CASE WHEN 
			v008_int_cmc - b3_dob_cmc >= consts.max_age_u5 
			--	OR
			--b7_death_age_months < consts.max_age_u5
			THEN sample_wt::FLOAT/1000000
		    WHEN
		    v008_int_cmc - b3_dob_cmc  < consts.max_age_u5
		        THEN  sample_wt::FLOAT/2000000
			ELSE 0 END
		) as denom_u5,
	-- Numerator: all children who were born at least 60 months before survey
    --			  and have died at < 60 months age count as 1; all those born
    --            later and have died (at < 60 months, implicitly) count as 0.5
	SUM (
		CASE WHEN 
			v008_int_cmc - b3_dob_cmc >= consts.max_age_u5
			--	OR
			--b7_death_age_months < consts.max_age_u5
				AND b5_is_alive=0 AND b7_death_age_months < consts.max_age_u5
			THEN sample_wt::FLOAT/1000000
		    WHEN
		    v008_int_cmc - b3_dob_cmc  < consts.max_age_u5
		        AND b5_is_alive=0 AND b7_death_age_months < consts.max_age_u5
		    THEN sample_wt::FLOAT/2000000
			ELSE 0 END
		) AS num_u5,

    -- U5 whole units only
	-- Denominator: all children who were born at least 60 months before survey
	--  			plus those who were born later but have died
	SUM (
		CASE WHEN
			v008_int_cmc - b3_dob_cmc >= consts.max_age_u5
				OR
			b7_death_age_months < consts.max_age_u5
			THEN sample_wt::FLOAT/1000000
			ELSE 0 END
		) as denom_u5_whole,
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
		) AS num_u5_whole,

    -- Infant
	-- Denominator: all children who were born at least 12 months before survey
	--              count as 1; all those born later count as 0.5
	SUM (
		CASE WHEN
			v008_int_cmc - b3_dob_cmc >= consts.max_age_inf
			--	OR
			--b7_death_age_months < consts.max_age_inf
			THEN sample_wt::FLOAT/1000000
		    WHEN
		    v008_int_cmc - b3_dob_cmc  < consts.max_age_inf
		        THEN  sample_wt::FLOAT/2000000
			ELSE 0 END
		) as denom_inf,
	-- Numerator: all children who were born at least 60 months before survey
    --			  and have died at < 60 months age count as 1; all those born
    --            later and have died (at < 60 months, implicitly) count as 0.5
	SUM (
		CASE WHEN
			v008_int_cmc - b3_dob_cmc >= consts.max_age_inf
			--	OR
			--b7_death_age_months < consts.max_age_u5
				AND b5_is_alive=0 AND b7_death_age_months < consts.max_age_inf
			THEN sample_wt::FLOAT/1000000
		    WHEN
		    v008_int_cmc - b3_dob_cmc  < consts.max_age_inf
		        AND b5_is_alive=0 AND b7_death_age_months < consts.max_age_inf
		    THEN sample_wt::FLOAT/2000000
			ELSE 0 END
		) AS num_inf,

	-- Infant whole units only
	-- Denominator: all children who were born at least 12 months before survey 
	--  			plus those who were born later but have died
	SUM (
		CASE WHEN 
			v008_int_cmc - b3_dob_cmc >= consts.max_age_inf 
				OR  
			b7_death_age_months < consts.max_age_inf
			THEN sample_wt::FLOAT/1000000 
			ELSE 0 END
		) as denom_inf_whole,
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
		) AS num_inf_whole,

	-- Neonatal
	-- Denominator: all children who were born at least 1 month before survey
	--              count as 1; all those born later count as 0.5
	SUM (
		CASE WHEN
			v008_int_cmc - b3_dob_cmc >= consts.max_age_nn
			--	OR
			--b7_death_age_months < consts.max_age_u5
			THEN sample_wt::FLOAT/1000000
		    WHEN
		    v008_int_cmc - b3_dob_cmc  < consts.max_age_nn
		        THEN  sample_wt::FLOAT/2000000
			ELSE 0 END
		) as denom_nn,
	-- Numerator: all children who were born at least 60 months before survey
    --			  and have died at < 60 months age count as 1; all those born
    --            later and have died (at < 60 months, implicitly) count as 0.5
	SUM (
		CASE WHEN
			v008_int_cmc - b3_dob_cmc >= consts.max_age_nn
			--	OR
			--b7_death_age_months < consts.max_age_u5
				AND b5_is_alive=0 AND b7_death_age_months < consts.max_age_nn
			THEN sample_wt::FLOAT/1000000
		    WHEN
		    v008_int_cmc - b3_dob_cmc  < consts.max_age_nn
		        AND b5_is_alive=0 AND b7_death_age_months < consts.max_age_nn
		    THEN sample_wt::FLOAT/2000000
			ELSE 0 END
		) AS num_nn,

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
		) as denom_nn_whole,
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
		) AS num_nn_whole,

	-- weighted total children in group		
	SUM (sample_wt::FLOAT/1000000) AS tot,
	-- unweighted total children in group
	count(*) AS nrows
	FROM dhs_data_summary.child_mortality_raw, consts
	GROUP BY surveyid, clusterid, lat, lon
)

SELECT surveyid, clusterid, lat, lon,
    tot AS total_children_wt,
	CASE WHEN denom_u5>0 THEN num_u5 / denom_u5 ELSE null END AS mort_u5,
    --CASE WHEN denom_u5_whole>0 THEN num_u5_whole / denom_u5_whole ELSE null END AS mort_u5_1,
	CASE WHEN denom_inf>0 THEN num_inf / denom_inf ELSE null END AS mort_inf,
    --CASE WHEN denom_inf_whole>0 THEN num_inf_wh  ole / denom_inf_whole ELSE null END AS mort_inf_1,
	CASE WHEN denom_nn>0 THEN num_nn / denom_nn ELSE null END AS mort_nn
    --CASE WHEN denom_nn_whole>0 THEN num_nn_whole / denom_nn_whole ELSE null END AS mort_nn_1

	FROM mort
WHERE denom_u5 != 0
ORDER BY surveyid::INTEGER, clusterid::INTEGER