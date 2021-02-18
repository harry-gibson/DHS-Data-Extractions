-- Cluster-level Malaria parasite rate (PR) data
-- This query generates PR at a cluster level with NO WEIGHTS based on MICROSCOPY DATA ONLY
--
-- Selects data in the format used internally by MAP for import to their PR database, 
-- matching the earlier manually-created Import Spreadsheets.
--
-- This version is for Microscopy data only. 
--
-- The destination database in MAP references each survey by a number of unique identifiers such as "Biblio ID". These 
-- are simply embedded in the query so as to be present in the output table it creates, as required downstream.
--
-- Notes on choices made in the implementation:
--  * Denominator in PR calculations is all children tested, not all children (would they test all children? surely not)
--  * Weights are not used, therefore aggregation to national rates would not be appropriate and would not match values
--    in report/API if attempted
--
--  USAGE
--  It's unwise to run this kind of extraction in bulk e.g. by just having the survey number and IDs as parameters,
--  as it relies on data being in specific places in the surveys,
--  which is usually ok in the most recent surveys but can't be guaranteed. So first check the survey spec tables
--  to ensure all the columns and values specified in this query are appropriate for the survey in question, for
--  example the RDT result being in hml35
--  Substitute in the correct country code and biblio id in the consts table at the top
--  Substitute in the correct numeric survey id
WITH consts AS
	-- just putting these here so they can be manually edited more easily: get this info manually.
		(SELECT
        491               AS dhs_survey_id
		  , '1000107874'::INTEGER 	AS biblio_src_id -- Internal MAP ID for this survey
      , 5680              AS universal_dhs_id -- Internal MAP ID for DHS data in general
		  , 'Benin'::text	AS country_name
		  , 'Microscopy'::text		    AS method -- for this version of the query
		)
SELECT
	NULL :: INT AS enl_id
	, NULL :: INT AS pm_id
	-- blank columns required by the downstream PR data importer 
  , NULL :: TEXT AS doi
	, NULL :: TEXT AS status
	, NULL :: TEXT AS author_name
	, NULL :: INT AS pub_year
	, NULL :: TEXT AS reason_for_exclusion
	, NULL :: TEXT AS reason_for_contacting
	, NULL :: TEXT AS follow_up
	, NULL :: TEXT AS follow_up_author_name
	, NULL :: TEXT AS email_address
	, NULL :: CHAR(1) AS has_been_contacted
  -- can we pre-populate this with something for DHS surveys?
	, NULL :: TEXT AS permissions
  	, min(consts.biblio_src_id) as source_id1
  	, min(consts.universal_dhs_id) as source_id2
	, NULL :: INT AS source_id3
  -- Older extracts used ISO3 but now this needs to be country name from which ISO3 will perversely be looked up,
  -- if it got spelled rite
	, min(consts.country_name) as country
	-- The provided adm1name from the DHS data, which is not necessarily an "offical" admin 1 name 
  , min(locs.adm1name) as admin1
  , NULL :: TEXT AS admin2
  , NULL :: TEXT AS admin3
	-- locs.dhs_id is like a fully-qualified version of numeric clusterid, but if we ever want to use this on surveys
  -- with no GPS info then let's use the numeric clusterid so we can at least tell what cluster each row represents
	, COALESCE(min(locs.dhsid), h0.hv001) as site_name
	, NULL :: DOUBLE PRECISION AS area_size
  -- this is the "fully qualified" clusterid from the locations table (if we have that) and always was so, but then
  -- site_name came along so this is maybe redundant now and only here for compatibility with downstream processing
	, COALESCE(min(locs.dhsid), h0.hv001) as dhs_id
	, 'POINT' as area_type
	, min(CASE
				WHEN locs.urban_rura = 'R' THEN 'RURAL'
				WHEN locs.urban_rura = 'U' THEN 'URBAN'
				ELSE ''
				END) as rural_urban
	, min(locs.latnum) as lat
	, min(locs.longnum) as long
	, min(CASE WHEN locs.latnum IS NULL THEN '' ELSE 'GPS' END) as latlong_source
	, NULL :: TEXT as site_notes
	, NULL :: INT AS aggregated_studies_count
	-- NB these date workings are as they were done in Excel pivot tables before this code was developed,
	-- so I have not changed for consistency.
	-- However it seems to me this would give the wrong answer for start / end dates if they spanned December
	-- one year to Jan the next. If so then we may wish to use CMC field instead.
	, min(h0.hv006::Integer) as month_start
	, min(h0.hv007::Integer) as year_start
	, max(h0.hv006::Integer) as month_end
	, max(h0.hv007::Integer) as year_end
	-- low age of the cluster is based on the children's age in months i.e. fractional years,
	-- so long as we have it, and if not then use the age in whole years
	, min(CASE WHEN hmh.hml16a IS NOT NULL
		THEN (ROUND(hmh.hml16a::numeric / 12, 2))
		ELSE (CASE WHEN hmh.hml16::numeric <= 96 THEN hmh.hml16::numeric ELSE NULL END)
		END
	) as lower_age
	-- upper age is based on the children's age in whole years which for each child is floor (int) of the real age and
	-- cluster upper age is the max of these.
	-- If there's only one child in the cluster or they are all the same age etc then this means the cluster upper age will
	-- be lower than (the floor of) the cluster lower age, which is in fractional years for each child and thus for the cluster.
	-- ... in which case we add 1 to the upper age in whole years...
	-- and both of those only apply where the values aren't null and are valid values.
	-- Obvious.... what? what? of course it is
	, (CASE WHEN max(CASE WHEN hmh.hml16::numeric <= 96 THEN hmh.hml16::numeric ELSE NULL END)
			>
			min(	CASE WHEN hmh.hml16a IS NOT NULL
				THEN (ROUND(hmh.hml16a::numeric / 12, 2)) ELSE 0
				END	)
		THEN max(CASE WHEN hmh.hml16::numeric <= 96 THEN hmh.hml16::numeric ELSE NULL END)
		ELSE max(CASE WHEN hmh.hml16::numeric <= 96 THEN hmh.hml16::numeric ELSE NULL END + 1)
	   END) as upper_age
	-- For the denominator, we have used inner join so we could just count rows, like this
	-- ,count(*) as examined
	-- but better to be sure in case a person has a row in this malaria table but only e.g. bednet questions were answered,
	-- and not malaria tests.
	, sum(CASE WHEN hmh.hml32 IS NOT NULL THEN 1 ELSE 0 END) as examined
	-- and all this for one row, get the actual test result. RDT always counts as Pf
	, sum(CASE WHEN (hmh.hml32 :: INTEGER = 1 AND hmh.hml32a :: INTEGER = 1) THEN 1 ELSE 0 END) as pf
  , sum(CASE WHEN (hmh.hml32 :: INTEGER = 1 AND hmh.hml32d :: INTEGER = 1) THEN 1 ELSE 0 END) as pv
  , sum(CASE WHEN (hmh.hml32 :: INTEGER = 1 AND hmh.hml32c :: INTEGER = 1) THEN 1 ELSE 0 END) as po
  , sum(CASE WHEN (hmh.hml32 :: INTEGER = 1 AND hmh.hml32b :: INTEGER = 1) THEN 1 ELSE 0 END) as pm
	-- afaik no DHS surveys ask about pk
	, '' as pk
	-- calculate rates as pos / examined.
	, sum(CASE WHEN (hmh.hml32 :: INTEGER = 1 AND hmh.hml32a :: INTEGER = 1)
			THEN 1.0 ELSE 0.0 END)
		/
		sum(CASE WHEN hmh.hml32 IS NOT NULL
			THEN 1
				ELSE 0 END)
		as pf_pr
	, sum(CASE WHEN (hmh.hml32 :: INTEGER = 1 AND hmh.hml32d :: INTEGER = 1)
			THEN 1.0
				ELSE 0.0 END)
		/
		sum(CASE WHEN hmh.hml32 IS NOT NULL
			THEN 1
				ELSE 0 END)
															AS pv_pr
  , sum(CASE WHEN (hmh.hml32 :: INTEGER = 1 AND hmh.hml32c :: INTEGER = 1)
			THEN 1.0
				ELSE 0.0 END)
		/
		sum(CASE WHEN hmh.hml32 IS NOT NULL
			THEN 1
				ELSE 0 END)
															AS po_pr
  , sum(CASE WHEN (hmh.hml32 :: INTEGER = 1 AND hmh.hml32b :: INTEGER = 1)
			THEN 1.0
				ELSE 0.0 END)
		/
		sum(CASE WHEN hmh.hml32 IS NOT NULL
			THEN 1
				ELSE 0 END)
															AS pm_pr
	, '' as pk_pr
	, min(consts.method) as method
	, NULL :: TEXT AS rdt_type
  , NULL :: TEXT AS pcr_type
  , NULL :: TEXT AS study_notes
  , NULL :: TEXT AS previous_year_enl_id

FROM
	-- for this extraction we're summarising data on individual children who got tested.
	-- we don't care about households and we don't care about children who weren't tested.
	-- so the malaria-by-person table is our left table and we can safely use an inner join
  -- to the household table, as all people are in a household
	dhs_data_tables."RECHMH" hmh
	INNER JOIN
		dhs_data_tables."RECH0" h0 ON
		hmh.hhid = h0.hhid AND hmh.surveyid = h0.surveyid
	-- not all surveys have gps / cluster info (although we will not at present be running this
  -- extraction for any surveys that do not)
  LEFT OUTER JOIN
  	dhs_data_locations.dhs_cluster_locs locs ON
		h0.hv001::Integer = locs.dhsclust AND h0.surveyid::Integer = locs.surveyid
	INNER JOIN
		consts
		ON 1 = 1
WHERE
	h0.surveyid::INTEGER = consts.dhs_survey_id
	and
	hmh.hml35 in ('0','1')
	-- and hmh.hml16a::INTEGER BETWEEN 0 and 60
GROUP BY h0.hv001
ORDER BY h0.hv001::Integer
