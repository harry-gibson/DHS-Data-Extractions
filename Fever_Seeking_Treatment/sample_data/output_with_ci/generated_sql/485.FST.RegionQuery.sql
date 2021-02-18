SELECT 
r01.v024 as region
, sum(1) as young_child
, sum(r01.v005::Float / 1000000) as young_child_wt
, sum(had_fever) had_fever
, sum(case when had_fever=1 THEN r01.v005::Float / 1000000 ELSE 0 END) as had_fever_wt
, sum(any_treat) any_treat
, sum(case when any_treat=1 THEN r01.v005::Float / 1000000 ELSE 0 END) as any_treat_wt
, sum(public_treat) public_treat
, sum(case when public_treat=1 THEN r01.v005::Float / 1000000 ELSE 0 END) as public_treat_wt
FROM
dhs_data_tables."REC21" r21
INNER JOIN
(SELECT
surveyid
, caseid
-- either HIDX or HIDXA depending on whether we are reading REC43 or REC4A
, HIDXA
, CASE WHEN tblfever.h22::Integer = 1 THEN 1 ELSE 0 END as had_fever
, CASE WHEN tblfever.h22::Integer = 1 AND (
 tblfever.h32s::Integer=1 OR tblfever.h32h::Integer=1 OR tblfever.h32g::Integer=1 OR tblfever.h32f::Integer=1 OR tblfever.h32d::Integer=1 OR tblfever.h32a::Integer=1 OR tblfever.h32e::Integer=1 OR tblfever.h32n::Integer=1 OR tblfever.h32t::Integer=1 OR tblfever.h32p::Integer=1 OR tblfever.h32o::Integer=1 OR tblfever.h32j::Integer=1 OR tblfever.h32k::Integer=1 OR tblfever.h32c::Integer=1 OR tblfever.h32b::Integer=1 OR tblfever.h32u::Integer=1 OR tblfever.h32m::Integer=1
) THEN 1 ELSE 0 END AS any_treat
, CASE WHEN tblfever.h22::Integer = 1 AND (
 tblfever.h32h::Integer=1 OR tblfever.h32g::Integer=1 OR tblfever.h32d::Integer=1 OR tblfever.h32a::Integer=1 OR tblfever.h32e::Integer=1 OR tblfever.h32n::Integer=1 OR tblfever.h32c::Integer=1 OR tblfever.h32b::Integer=1 OR tblfever.h32m::Integer=1
 ) THEN 1 ELSE 0 END AS public_treat
FROM dhs_data_tables."REC4A" tblfever
) fever
ON 
r21.surveyid = fever.surveyid AND r21.caseid = fever.caseid AND r21.BIDX = fever.HIDXA
INNER JOIN
dhs_data_tables."REC01" r01
ON r21.surveyid = r01.surveyid AND r21.caseid = r01.caseid
LEFT OUTER JOIN
dhs_data_locations.dhs_cluster_locs clust
ON r01.surveyid::Integer = clust.surveyid AND r01.v001::Integer = clust.dhsclust
WHERE r21.surveyid::Integer=485 AND r21.b5 ::Integer=1 AND r21.b8::Integer<=5
GROUP BY r01.surveyid, r01.v024
ORDER BY r01.surveyid::Integer, r01.v024::Integer