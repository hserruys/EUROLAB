*********************************************************************************
* 3c_merge_CF.do																*
*																				*
* Appends and merges counterfactual income files								*	
* Last update 11-03-21 B.P.														*
*********************************************************************************
di in r "START 3c_merge_CF: $S_TIME  $S_DATE"
args ref firstref		//ref for reform
di in r "args ref `ref' firstref `firstref'"
clear
use "all_globals.dta"
keep hours country choices path_LSscen year 
capture ds
local input_args "`r(varlist)'"	
foreach label in `input_args'{	
	//display in red "`label'"":"_skip(1)`label'
	local val=`label'[1]
	local `label' "`val'"
}

use "`path_LSscen'/2_postEM_appended/`country'_`year'_`choices'ch_`ref'.dta",clear

if `firstref' == 1 {
	save "`path_LSscen'/2_postEM_appended/`country'_`year'_`choices'ch.dta", replace
}
else {
	merge 1:1 idperson lhw_f_norand lhw_m_norand sec_f sec_m emp_stat_f emp_stat_m using "`path_LSscen'/2_postEM_appended/`country'_`year'_`choices'ch.dta",nogenerate
	save "`path_LSscen'/2_postEM_appended/`country'_`year'_`choices'ch.dta", replace
}

	
di in r "END 3c_merge_CF: $S_TIME  $S_DATE"

*End do file 3c_merge_CF