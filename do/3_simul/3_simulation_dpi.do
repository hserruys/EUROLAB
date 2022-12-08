*********************************************************************************
* 3_simulation_dpi.do															*
*																				*
* Executes EUROMOD for counterfactual income files								*
* Last update 11-03-21 B.P.														*
*********************************************************************************

set trace off
capture log close
log using "${outlog}/3_simulation_dpi_${country}_${year}_${choices}ch.log",replace
di in r "3_simulation_dpi is running: $S_TIME  $S_DATE"

do 11_programs

*Variables to be renamed and also added to the global variables_to_keep
local keepvars="ils_dispy ils_origy ils_origrepy ils_earns ils_sicee ils_sicdy ils_sicse ils_sicer ils_sicot ils_ben ils_tax"
if "$country" == "it" {
	global keepvars="`keepvars' bunct02_s"	
}
else if "$country" == "cz"|"$country" == "ro"|"$country" == "pl"|"$country" == "be"{
	global keepvars="`keepvars' bun_s"	
}
else if "$country" == "lv"{
	global keepvars="`keepvars' bun00_s"	
}
else if "$country" == "lu"{
	global keepvars="`keepvars' bunss_s"	
}
else if "$country" == "mt"{
	global keepvars="`keepvars' bunctnm_s"	
}
else {
	global keepvars="`keepvars' bunct_s"	
}


*Set variables to keep before merging files
global variables_to_keep="idhh idperson strata1 psu1 dag dgn dec dwt drgn* dcz dct les lhw lse yemmy  lhw* choice* yemmy* flex* ed_* age* numch* pold* hhsize sec_m sec_f emp_stat_f emp_stat_m $keepvars"

**************** Program to run EUROMOD simulations ****************************
capture program drop Simulations
program Simulations	
	local counter=0
	local multiplier=1
	local temp_count=0
	foreach ref in $reforms {

		di in r "Foreach `ref' full simulation"
		if "`ref'" == "base" & strpos("$reforms", "new") != 0  {
			global policyyears ="$pyear $ryear"
		}
		else if "`ref'" == "new" {
			global policyyears = "$new_reforms"
		}
		else {
			global policyyears = "$pyear"
		}
		
		global policyyear_count : list sizeof local(policyyears)
		global policyyears_all = "$policyyears"
		local policyyears_temp = "$policyyears"

		// Identify system_ids
		local aux_num=0
		foreach p of local policyyears_temp {
						
			// Run once for the full sample
			cap copy "${path_LSscen}/0_fullsample/${country}_${year}_${choices}ch_full.txt" "${path_EMinput}/modified/${filename}.txt", replace
			local cp_counter=0
			while _rc == 608{
				sleep 500
				cap copy "${path_LSscen}/0_fullsample/${country}_${year}_${choices}ch_full.txt" "${path_EMinput}/modified/${filename}.txt", replace
				di "cp_counter `cp_counter'"
				di _rc
				local ++ cp_counter
				if `cp_counter'==10{
					di in r "ERROR: File ${path_LSscen}/0_fullsample/${country}_${year}_${choices}ch_full.txt could not be copied. Please verify that file exists and run again."
					stop
				}
			}
			
			if `aux_num'==0{
				createFolder "${path_EMoutput}\modified" "${country}_${year}_${choices}ch_full_`ref'"
				local aux_num = 1
			}
			
			global Fol_`ref'_full="${path_EMoutput}\modified\\${country}_${year}_${choices}ch_full_`ref'"
			
			//shell runs EUROMOD simulations sequentially
			shell start /min "" "${EM_G2exe}/EM_ExecutableCaller.exe" "-emPath" "${EM_G2}" "-sys" "${country}_`p'" "-data" "${filename}" "-outPath" "${Fol_`ref'_full}" "-dataPath" "${path_EMinput}\modified" "-noTranslate" 
			
			display "shell ${EM_G2exe}/EM_ExecutableCaller.exe -emPath ${EM_G2} -sys ${country}_`p' -data ${filename} -outPath ${Fol_`ref'_full} -dataPath ${path_EMinput}\modified"
			display "After EUROMOD execution in Folder ${Fol_`ref'_full}: `p'"
			di in r "END: $S_TIME  $S_DATE"
		}
		
		if $RUN_COUNTERFACTUALS == 1 {
			foreach i in $hours {
				foreach j in $hours {
					forvalues sec_f = 1/${NumberOfSectors} {
						forvalues empstat_f = 1/${EmplStatus} {
							forvalues sec_m = 1/${NumberOfSectors} {
								forvalues empstat_m = 1/${EmplStatus} {
									di in r "Start counterfactual simulation for hours `i' and hours `j', sector_f `sector_f', emp_stat_f `emp_stat_f', sector_m `sector_m', emp_stat_m `emp_stat_m': $S_TIME  $S_DATE"	
									
									local RUN_EM = (${USEOLD}==0)         
 
									/// EXECUTE EUROMOD 
									if `RUN_EM' == 1 { 
									
										if (`i' == 0 | `i' == 5) & (`j' == 0 | `j' == 5){
											local emp_stat_f = 0 
											local sector_f = 0 
											local emp_stat_m = 0
											local sector_m = 0
										}
										else if `i' == 0 | `i' == 5 {
											local emp_stat_f = 0 
											local sector_f = 0 
											local emp_stat_m = `empstat_m'
											local sector_m = `sec_m'
										}
										else if `j' == 0 | `j' == 5 {
											local emp_stat_f = `empstat_f' 
											local sector_f = `sec_f'
											local emp_stat_m = 0
											local sector_m = 0
										}
										else{
											local emp_stat_f = `empstat_f' 
											local sector_f = `sec_f'
											local emp_stat_m = `empstat_m'
											local sector_m = `sec_m'
										}
										global RUN_EM = 1
										local firstp = 1									

										global InFol_f`i'_s`sector_f'_e`emp_stat_f'_m`j'_s`sector_m'_e`emp_stat_m'_`ref'="${path_EMinput}\modified\\${country}_${year}_${choices}ch_f`i'_s`sector_f'_e`emp_stat_f'_m`j'_s`sector_m'_e`emp_stat_m'_`ref'"
										//Confirm input data exists	before running EUROMOD							
										cap confirm file "${InFol_f`i'_s`sector_f'_e`emp_stat_f'_m`j'_s`sector_m'_e`emp_stat_m'_`ref'}/${filename}.txt"
										if _rc != 0 {
											di in r "ERROR: Input file not found in folder ${InFol_f`i'_s`sector_f'_e`emp_stat_f'_m`j'_s`sector_m'_e`emp_stat_m'_`ref'}. Please generate missing input data and run again."
											stop
										}
										
										local time_i=1
										foreach ps of local policyyears_temp {
											local ++counter
											timer on `time_i'
										
											createFolder "${path_EMoutput}\modified" "${country}_`ps'_${choices}ch_f`i'_s`sector_f'_e`emp_stat_f'_m`j'_s`sector_m'_e`emp_stat_m'_`ref'"
											
											di in r "${path_EMoutput}\modified" "${country}_`ps'_${choices}ch_f`i'_s`sector_f'_e`emp_stat_f'_m`j'_s`sector_m'_e`emp_stat_m'_`ref'"
											
											global EM_output_folder="${path_EMoutput}\modified\\${country}_`ps'_${choices}ch_f`i'_s`sector_f'_e`emp_stat_f'_m`j'_s`sector_m'_e`emp_stat_m'_`ref'"	
											
											//winexec runs EUROMOD simulations simultaneously
											winexec cmd /c start /min "" "${EM_G2exe}/EM_ExecutableCaller.exe" "-emPath" "${EM_G2}" "-sys" "${country}_`ps'" "-data" "${filename}" "-outPath" "${EM_output_folder}" "-dataPath" "${InFol_f`i'_s`sector_f'_e`emp_stat_f'_m`j'_s`sector_m'_e`emp_stat_m'_`ref'}" "-noTranslate"
											
											display "winexec ${EM_G2exe}/EM_ExecutableCaller.exe -emPath ${EM_G2} -sys ${country}_`ps' -data ${filename} -outPath ${EM_output_folder} -dataPath ${InFol_f`i'_s`sector_f'_e`emp_stat_f'_m`j'_s`sector_m'_e`emp_stat_m'_`ref'}"
										
											display "After EUROMOD counterfactual simulation: `p' counter `counter'"
											timer off `time_i'
											timer list `time_i'
											local ++time_i
											
											local temp_number=`multiplier'*$split_number_EM
											if `counter'==`temp_number'{
												sleep 500
												local temp_list:dir "${EM_output_folder}" files "*"
												local numfiles : word count `temp_list'
												local temp_counter=0
												while `numfiles'< 2 {
													local ++temp_counter
													if `temp_counter'<500{
														sleep 500
														local temp_list:dir "${EM_output_folder}" files "*"
														local numfiles : word count `temp_list'
													}
													else{
														capture window stopbox rusure "ERROR: EUROMOD failed to produce output. You can find more info about error in EUROMOD's log file (placed in the corresponding folder inside \data\EMoutput\modified).  Do you want to close STATA?"
														if _rc == 0 {
															exit, STATA clear
														}
														else{
															stop
														}
													}
												di "Looking for output file: attemp `temp_counter'/500"
												}
												local ++multiplier
											}
										}
										
										local ++temp_count
									}	//end RUN_EM 
									else{
										global RUN_EM = 0
									}
									if (`i' == 0 | `i' == 5) & (`j' == 0 | `j' == 5){
										continue, break
									}
									else if `j' == 0 | `j' == 5{
										continue, break
									}
								}	//ends empstat_m
								if (`i' == 0 | `i' == 5) & (`j' == 0 | `j' == 5){
									continue, break
								}
								else if `j' == 0 | `j' == 5{
									continue, break
								}
							}	//ends sec_m
							if (`i' == 0 | `i' == 5) & (`j' == 0 | `j' == 5){
								continue, break
							}
							else if `i' == 0 | `i' == 5 {
								continue, break
							}
						}	//ends empstat_f
						if (`i' == 0 | `i' == 5) & (`j' == 0 | `j' == 5){
							continue, break
						}
						else if `i' == 0 | `i' == 5 {
							continue, break
						}
					}	//ends sec_f
				}	//end j hours
			} 	//ends i hours
		}
	}	
end	


**************** RUN SIMULATIONS (FULL AND COUNTERFACTUALS) ********************
Simulations
********************************************************************************

di in r "Start merging fullsample: $S_TIME  $S_DATE"
local firstref 1
foreach ref in $reforms {
	
	di in r "Start merging full simulation `ref'"
	if "`ref'" == "base" & strpos("$reforms", "new") != 0  {
		global policyyears ="$pyear $ryear"
	}
	else if "`ref'" == "new" {
		global policyyears = "$new_reforms"
	}
	else {
		global policyyears = "$pyear"
	}

	display "global policyyears: $policyyears"
	
    local firstp = 1

    foreach p in $policyyears {
		sleep 500
        capture confirm file "${Fol_`ref'_full}\\${country}_`p'_std.txt"
		local temp_counter=0
        while _rc {
			local ++temp_counter
			if `temp_counter'<500{
				sleep 500
				capture confirm file "${Fol_`ref'_full}\\${country}_`p'_std.txt"
			}
			else{
				di in r "ERROR: File ${country}_`p'_std.txt was not found. Please check error in EUROMOD log file inside folder ${Fol_`ref'_full} and run 3_simulation_dpi again."
				stop
			}
			di "Looking for full sample output file: attemp `temp_counter'/500"
        }
		//di in r "merging full `temp_counter'"
		
		local var_list_to_include=""
        insheet using "${Fol_`ref'_full}\\${country}_`p'_std.txt", tab names clear double
		isid idperson
        cap drop lhw_?
        
        // Destring
        foreach var of varlist _all {
            cap replace `var' = subinstr(`var', ",", ".", 1)
            cap destring `var', replace
        }

        compress

        local p_clear = substr("`p'", 1, 4)
        
		di in r "`p'"
		di in r "`p_clear'"
		
		global keepvars_ref = ""
		foreach var of global keepvars {
            cap rename `var' `var'_p`p'_`ref'
			di in r "`var'_p`p'_`ref'"
			global keepvars_ref "${keepvars_ref} `var'_p`p'_`ref'"
        }
 	
		
		keep idhh idperson dwt $keepvars_ref

			
        sort idperson
		di in r "firstp `firstp'"
        if `firstp' == 1 {
            save "${path_LSscen}/0_fullsample/${country}_${year}_${choices}ch_fullsample_`ref'.dta", replace
			di in r "ch_fullsample_`ref'"
            local firstp = 0
        }
        else {
		capture drop _merge
            merge 1:1 idperson using "${path_LSscen}/0_fullsample/${country}_${year}_${choices}ch_fullsample_`ref'.dta",nogenerate
            save "${path_LSscen}/0_fullsample/${country}_${year}_${choices}ch_fullsample_`ref'.dta", replace
			*di in r "save ${path_LSscen}/0_fullsample/${country}_${year}_${choices}ch_fullsample_`ref'.dta, replace"
            }
    }
    if `firstref' == 1 {
        save "${path_LSscen}/0_fullsample/${country}_${year}_${choices}ch_originalsample.dta", replace
        local firstref 0
    }
    else {
        merge 1:1 idperson using "${path_LSscen}/0_fullsample/${country}_${year}_${choices}ch_originalsample.dta",nogenerate
        save "${path_LSscen}/0_fullsample/${country}_${year}_${choices}ch_originalsample.dta", replace
    }
}


********************************************************************************
di in r "RUN_COUNTERFACTUALS $RUN_COUNTERFACTUALS: $S_TIME  $S_DATE"
clear

local all_globals="hours country choices year path_EMinput path_EMoutput path_LSscen RUN_EM outlog keepvars EmplStatus NumberOfSectors"

set obs 1
foreach a of local all_globals {
	gen `a'="${`a'}" 
}
save "all_globals.dta",replace


***********************************************************************
if $RUN_COUNTERFACTUALS == 1 {
   
	createFolder "${path_EMinput}" "temp_folder"
	local hour_num=0
	local multiplier=1
	local expected_files=((wordcount("$hours")-2)*(${NumberOfSectors}*${EmplStatus}))+2
	di in r "NumberOfSectors ${NumberOfSectors} EmplStatus ${EmplStatus}"
	
    foreach ref in $reforms {
	
		di in r "start foreach `ref' "
		 if "`ref'" == "base" & strpos("$reforms", "new") != 0  {
			global policyyears ="$pyear $ryear"
		}
		else if "`ref'" == "new" {
			global policyyears = "$new_reforms"
		}
		else {
			global policyyears = "$pyear"
		}
		
		createFolder "${path_EMinput}" "temp_folder_hours_`ref'"
		di in r "policyyears $policyyears"
		local file_num=0
		foreach i in $hours {
			if (`i' == 0 | `i' == 5) {
				local start=0
			}
			else{
				local start=1
			}
			forvalues sec_f = `start'/${NumberOfSectors} {
				forvalues empstat_f = `start'/${EmplStatus} {	
					//Launch new STATA instance
					winexec "${path_stata}" "/e" "do" "3a_merge_CF" "`i'" "`ref'" "`sec_f'" "`empstat_f'" "$policyyears"
					
					if (`i' == 0 | `i' == 5){
						continue, break
					}
					
					local ++file_num
					local ++hour_num
					local temp_number_files=`multiplier'*$split_number_STATA
					
					if `hour_num'==`temp_number_files'{
						sleep 500
						local temp_list:dir "${path_EMinput}/temp_folder_hours_`ref'" files "*"
						local numfiles : word count `temp_list'
						local temp_counter=0
						while `numfiles'< `file_num' {
							local ++temp_counter
							if `temp_counter'<2500{	//Equivalent approx to 20 minutes wait
								sleep 500
								local temp_list:dir "${path_EMinput}/temp_folder_hours_`ref'" files "*"
								local numfiles : word count `temp_list'
							}
							else{ 
								capture window stopbox rusure "ERROR: STATA instance failed while merging output data. You can find more info about error in 3a_merge_CF log files in do folder.  Do you want to close STATA?"
								if _rc == 0 {
									exit, STATA clear
								}
								else{
									stop
								}
							}
							di "Merging output in 3a_merge_CF: attemp `temp_counter'/2500"
						}
						local ++multiplier
					}
				} //End empstat_f
				if (`i' == 0 | `i' == 5){
						continue, break
				}
			}	//End sec_f
		}	//End hours i
	} //End reforms

	di in r "Expected_files `expected_files'"
	foreach ref in $reforms {
		local temp_list:dir "${path_EMinput}/temp_folder_hours_`ref'" files "*"
		local numfiles : word count `temp_list'
		
		local temp_counter=0
		while `numfiles'< `expected_files'{
			local ++temp_counter
			if `temp_counter'<500{
				sleep 500
				local temp_list:dir "${path_EMinput}/temp_folder_hours_`ref'" files "*"
				local numfiles : word count `temp_list'
			}
			else{ 
				di in r "ERROR: STATA instance failed while merging output data in previous step. Number of files (`numfiles') is less than expected number of files (`expected_files'). Please find more info about error in 3a_merge_CF log files in do folder and run again"
				stop
			}
			di "Merging output in 3b_merge_CF: attemp `temp_counter'/500"
		}
		
		//Ready to continue (all dta files exist) - Launch STATA instances
		winexec "${path_stata}" "/e" "do" "3b_merge_CF" "`ref'"
	}
				
	local firstref=1
	local expected_ref=wordcount("$reforms")
	foreach ref in $reforms {
		*sleep 500
        capture confirm file "${path_EMinput}/temp_folder/temp_file_`ref'.txt"
		local temp_counter=0
        while _rc {
			local ++temp_counter
			if `temp_counter'<500{
                sleep 500
                capture confirm file "${path_EMinput}/temp_folder/temp_file_`ref'.txt"
			}
			else{ 
				di in r "ERROR: STATA instance failed while merging output data in previous step. File ${path_EMinput}/temp_folder/temp_file_`ref'.txt is not found. Please find more info about error in 3b_merge_CF log files in do folder and run again"
				stop
			}
			di "Merging output in 3c_merge_CF: attemp `temp_counter'/500"
        }
		//Ready to continue (all dta files exist)
		do 3c_merge_CF `ref' `firstref'
		local firstref=`firstref' + 1
	}
	
    merge m:1 idperson using "${path_LS}/baseline/${country}_${year}_${choices}ch_reduced_baseline.dta",nogenerate
    save "${path_LSscen}/2_postEM_appended/${country}_${year}_${choices}ch.dta", replace
	
} //End RUN_COUNTERFACTUALS

********************************************************************************
//Delete files and folders
removeFolders

di in r "END 3_simulation_dpi: $S_TIME  $S_DATE"
cap log close
*End of do file 3_simulation_dpi.do file


