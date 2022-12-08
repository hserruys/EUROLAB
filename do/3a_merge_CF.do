*********************************************************************************
* 3a_merge_CF.do																*
*																				*
* Appends and merges counterfactual income files								*
* Last update 11-03-21 B.P.														*
*********************************************************************************
di in r "START 3a_merge_CF: $S_TIME  $S_DATE"
args i ref sec_f empstat_f policyyears 	//i stands for hour, ref for reform
di in r "Args i `i' ref `ref' sec_f `sec_f' empstat_f `empstat_f' policyyears `policyyears'" 

clear
use "all_globals.dta"
keep hours RUN_EM country path_EMoutput path_EMinput choices path_LSscen year outlog keepvars
capture ds
local input_args "`r(varlist)'"	
foreach label in `input_args'{	
	//display in red "`label'"":"_skip(1)`label'
	local val=`label'[1]
	local `label' "`val'"
}

local firstp 1
local firstrun 1
local firstPolicy=word("`policyyears'",1) 

foreach j in `hours' {
//di in r "RUN EM  = `RUN_EM'"
	if `RUN_EM' == 1 { 
		di in r "START loop hours `i' and hours `j': $S_TIME  $S_DATE"
		local folder_list: dir "`path_EMoutput'\modified" dirs "`country'_`firstPolicy'_`choices'ch_f`i'_s`sec_f'_e`empstat_f'_m`j'*_`ref'"  
		local firstFolder = 1
		foreach folder in `folder_list' {
			local firstp = 1
			tempfile dataset_policyyear
			local counter=1
			foreach p in `policyyears' {
				if `firstp' != 1 {
					local counter = `counter'
					local previous_reform = word("`policyyears'",`counter')
					local folder=usubinstr("`folder'",strlower("`previous_reform'"),strlower("`p'"),1)
					local ++counter
				}
				di in r "insheet using `path_EMoutput'\modified/`folder'/`country'_`p'_std.txt"
				insheet using "`path_EMoutput'\modified/`folder'/`country'_`p'_std.txt", tab names clear double
				
				// Destring, just in case
				foreach var of varlist _all {
					cap replace `var' = subinstr(`var', ",", ".", 1)
					cap destring `var', replace
				}

				quiet compress
				local p_clear = substr("`p'", 1, 4)

				global keepvars_ref = ""
				foreach var of local keepvars {
					cap rename `var' `var'_p`p'_`ref'
					di in r "`var'_p`p'_`ref'"
					global keepvars_ref "`keepvars_ref' `var'_p`p'_`ref'"
				}
		
				*di in r	"$keepvars_ref"
	
				keep idhh idperson *_p`p'_`ref' lhw* dgn
	
				
				local empstat_m=usubstr("`folder'",ustrrpos("`folder'","_")-1,1)
				local sec_m=usubstr("`folder'",ustrrpos("`folder'","_")-4,1)
				
				quiet generate lhw_f_norand = `i'
				quiet generate lhw_m_norand = `j'

				generate int sec_f = `sec_f'
				generate int sec_m = `sec_m'

				generate int emp_stat_f = `empstat_f'
				generate int emp_stat_m = `empstat_m'
				di "generate sec_m = `sec_m'  generate emp_stat_m = `empstat_m'"
				gen lhw_f = lhw if dgn == 0
				gen lhw_m = lhw if dgn == 1
				
				sort idperson
				if `firstp' == 1 {
					di in r "first policy == 1"
					//Save as temporary file
					save `dataset_policyyear', replace
					local firstp = 0
				}
				else {					
					merge 1:1 idperson using `dataset_policyyear', nogenerate
					save `dataset_policyyear', replace
				}
			}	//End policyyears

			if `firstFolder'==1{
				save "`path_LSscen'/1_counterfactuals/`country'_`year'_`choices'ch_f`i'_s`sec_f'_e`empstat_f'_m`j'_`ref'.dta", replace
				local firstFolder 0
			}
			else{
				append using "`path_LSscen'/1_counterfactuals/`country'_`year'_`choices'ch_f`i'_s`sec_f'_e`empstat_f'_m`j'_`ref'.dta"
				sort idperson lhw_f_norand lhw_m_norand sec_f sec_m emp_stat_f emp_stat_m
				di "append using ``path_LSscen'/1_counterfactuals/`country'_`year'_`choices'ch_f`i'_s`sec_f'_e`empstat_f'_m`j'_`ref'.dta"
				save "`path_LSscen'/1_counterfactuals/`country'_`year'_`choices'ch_f`i'_s`sec_f'_e`empstat_f'_m`j'_`ref'.dta", replace
			}
		}	// End folder_list
	} 	//If RUN_EM=1
	else {
		use "`path_LSscen'/1_counterfactuals/`country'_`year'_`choices'ch_f`i'_s`sec_f'_e`empstat_f'_m`j'_`ref'.dta", clear
	}
	//di in r "FIRST RUN = `firstrun'"
	if `firstrun' == 1 {
		save "`path_LSscen'/2_postEM_appended/`country'_`year'_`choices'ch_f`i'_s`sec_f'_e`empstat_f'_`ref'.dta", replace
		local firstrun 0
	}
	else {
		append using "`path_LSscen'/2_postEM_appended/`country'_`year'_`choices'ch_f`i'_s`sec_f'_e`empstat_f'_`ref'.dta"
		sort idperson lhw_f_norand lhw_m_norand sec_f sec_m emp_stat_f emp_stat_m
		di "append using `path_LSscen'/2_postEM_appended/`country'_`year'_`choices'ch_f`i'_s`sec_f'_e`empstat_f'_`ref'.dta"
		save "`path_LSscen'/2_postEM_appended/`country'_`year'_`choices'ch_f`i'_s`sec_f'_e`empstat_f'_`ref'.dta", replace
	}  
}	//End j hours
tab sec_f
tab sec_m

//Copy file to be used only as a flag file
copy "run_stata.bat" "`path_EMinput'/temp_folder_hours_`ref'/temp_file_f`i'_s`sec_f'_e`empstat_f'_`ref'_`i'.txt"	

di in r "END 3a_merge_CF: $S_TIME  $S_DATE"
*End do file 3a_merge_CF