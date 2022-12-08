*********************************************************************************
* 3b_merge_CF.do																*
*																				*
* Appends and merges counterfactual income files								*
* Last update 11-03-21 B.P.														*
*********************************************************************************
di in r "START 3b_merge_CF: $S_TIME  $S_DATE"
args ref  	//i stands for hour, ref for reform
di in r "Args ref `ref'" 

clear
use "all_globals.dta"
keep hours RUN_EM country path_EMoutput path_EMinput choices path_LSscen year outlog
capture ds
local input_args "`r(varlist)'"	
foreach label in `input_args'{	
	//display in red "`label'"":"_skip(1)`label'
	local val=`label'[1]
	local `label' "`val'"
}


local firsthour=1
di in r "START loop hours: $S_TIME  $S_DATE"
  
foreach i in `hours' {
	local files_list: dir "`path_LSscen'/2_postEM_appended/" files "`country'_`year'_`choices'ch_f`i'_*_`ref'.dta"
	local firstrun 1
	foreach file in `files_list' {
		//di "file      `path_LSscen'/2_postEM_appended/`file'"
		use "`path_LSscen'/2_postEM_appended/`file'", clear
		if `firstrun' == 1 {
			save "`path_LSscen'/2_postEM_appended/`country'_`year'_`choices'ch_f`i'_`ref'.dta", replace
			local firstrun=0
		}
		else {
			append using "`path_LSscen'/2_postEM_appended/`country'_`year'_`choices'ch_f`i'_`ref'.dta"
			sort idperson lhw_f_norand lhw_m_norand sec_f sec_m emp_stat_f emp_stat_m

			save "`path_LSscen'/2_postEM_appended/`country'_`year'_`choices'ch_f`i'_`ref'.dta", replace
		}
	}
	
	if `firsthour' == 1 {
		save "`path_LSscen'/2_postEM_appended/`country'_`year'_`choices'ch_`ref'.dta", replace
		local firsthour=0
	}
	else {
		append using "`path_LSscen'/2_postEM_appended/`country'_`year'_`choices'ch_`ref'.dta"
		sort idperson lhw_f_norand lhw_m_norand sec_f sec_m emp_stat_f emp_stat_m

		save "`path_LSscen'/2_postEM_appended/`country'_`year'_`choices'ch_`ref'.dta", replace
	}
}

//Copy file to be used only as a flag file
copy "run_stata.bat" "`path_EMinput'/temp_folder/temp_file_`ref'.txt"		

di in r "END 3b_merge_CF: $S_TIME  $S_DATE"
*End do file 3b_merge_CF


