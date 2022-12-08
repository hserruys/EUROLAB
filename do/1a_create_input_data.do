*********************************************************************************
* 1a_create_input_data.do														*
*																				*
* This file is used to parallelize the creation of input data for new reforms	* 
* Last update 11-03-21 B.P.														*
*********************************************************************************

//ARGUMENTS: Three multipliers, ref for reform, hour i, hour j, sector female, sector male, employment status female, employment status male
args multip_m multip_f multip_i ref i j sec_f sec_m empstat_f empstat_m
di in r "1a_create_input_data is running: $S_TIME  $S_DATE"
di in r "For combination: ref `ref' i `i' j `j' sec_f `sec_f' sec_m `sec_m' empstat_f `empstat_f' empstat_m `empstat_f'"
adopath + "./ado"
do 11_programs

clear
use "globals_preparedata.dta"
foreach label of varlist _all{	
	local `label'=`label'[1]
	display in red "`label' = ``label''"
}

use "1_preparedata",clear

get_income_variables

//Fixed Alternatives APPROACH - NOT USED ANY MORE
if `HOURS_DISTRIBUTION' ==0 {
	quiet  replace lhw = `i' if flex_f == 1
	quiet  replace lhw = `j' if flex_m == 1
}
else if `HOURS_DISTRIBUTION' ==1 { 		//Sampling Alternative Approach - NOT USED ANYMORE
	gen double random = int(`step'*runiform())  
	if `i' == 0 replace lhw = 0 if flex_f == 1
	if `j' == 0 replace lhw = 0 if flex_f == 1
	
	if `i' > 0 replace lhw = `i' - random  if flex_f == 1
	if `j' > 0 replace lhw = `j' - random  if flex_m == 1	
}
else if `HOURS_DISTRIBUTION'==2 {		// Sampling from Observed Distribution Approach
	qui replace lhw = ore_f`i' if flex_f ==1
	qui replace lhw = ore_m`j' if flex_m ==1					
}

//Replace the hours with the real hours if someone has taken this choice
qui replace lhw = lhw_choice if flex_f ==1 & `i'== choice_g
qui replace lhw = lhw_choice if flex_m ==1 & `j'== choice_g

//INACTIVITY ALTERNATIVE
if `i' == 0 | `j' == 0 {
										
	if `i' == 0 {
		di in r "Inactivity alternative - female" 
		local sex  = "f"
		local emp_stat_f = 0 
		local sector_f = 0 
		
		quiet replace loc = -1 if flex_`sex' ==1
		quiet  replace lindi = -1 if flex_`sex' ==1
		quiet   replace les =  7 if flex_`sex' ==1
					
		foreach var of varlist `original_months'{
			quiet replace `var'= 0 if flex_`sex' ==1
		}
		
		local zero_var "lnu yempv_a liwmy_a yem yse"
		
		if "`country'" == "it" | "`country'" == "ee" | "`country'" == "el" {
			global zero_var ="`zero_var' bunctmy"
		}      
		else{
			global zero_var = "`zero_var' bunmy"
		}       
		

		foreach var of varlist $zero_var {
			quiet replace `var'= 0 if flex_`sex' ==1
		} 
		if "`country'" == "it" {
			replace yseev = 0 if flex_`sex' ==1
		}
	}
	if `j' == 0 {
		di in r "Inactivity alternative - male"
		local sex  = "m"
		local emp_stat_m = 0
		local sector_m = 0
		
		quiet replace loc = -1 if flex_`sex' ==1
		quiet  replace lindi = -1 if flex_`sex' ==1
		quiet   replace les =  7 if flex_`sex' ==1
					
		foreach var of varlist `original_months'{
			quiet replace `var'= 0 if flex_`sex' ==1
		}
		if "`country'" == "it" | "`country'" == "ee" | "`country'" == "el"{
			global zero_var "lnu yempv_a liwmy_a bunctmy yem yse"
		}
		else {
			global zero_var "lnu yempv_a liwmy_a bunmy yem yse"
		}
		
		foreach var of varlist $zero_var {
			quiet replace `var'= 0 if flex_`sex' ==1
		} 
		if "`country'" == "it" {
			replace yseev = 0 if flex_`sex' ==1
		}
		*	assert les ==7 & (lnu  + yempv_a + liwmy_a) ==0  if flex_`sex' ==1
	}
}

if `i' == 5 | `j' == 5 {
	
	if `i' == 5 {
		di in r "Unemployment alternative female"
		local sex  = "f"
		local emp_stat_f = 0 
		local sector_f = 0 
		
		replace lnu = 1 if flex_`sex' == 1
		replace les = 5 if flex_`sex' ==1
		quiet  replace lindi = -1 if flex_`sex' ==1
		quiet replace lowas = 1 if flex_`sex' ==1 //??
		quietly replace kfbcc = 0 if flex_`sex' ==1
		quietly replace kfb = 0 if flex_`sex' ==1

		replace liwmy_a = liwmy_orig if flex_`sex' ==1 
		if "${country}" == "pt" {
			replace liwmy01_a = liwmy_orig if flex_`sex' ==1 
		}
		replace lunmy = 12 if flex_`sex' ==1 
		replace yempv_a = yem_new if flex_`sex' ==1/*if yem is 0, no unemp benefit is received*/
		replace yempv_a = 0 if yempv_a ==.
		
		if "`country'" == "it" | "`country'" == "ee" | "`country'" == "el"{
			replace bunctmy = yemmy if bunctmy == 0 & flex_`sex' ==1
		}
		else {
			replace bunmy = yemmy if bunmy == 0 & flex_`sex' ==1
		}
		
		global zero_var "liwmy liwftmy liwptmy yemmy ysemy yse yem"
		foreach var of varlist $zero_var {
			quiet replace `var'= 0 if flex_`sex' ==1
		} 
		if "`country'" == "it" {
			replace yseev = 0 if flex_`sex' ==1
		}

	}
	if `j' == 5 {
		di in r "Unemployment alternative male"
		local sex  = "m"
		local emp_stat_m = 0
		local sector_m = 0
		
		replace lnu = 1 if flex_`sex' == 1
		replace les = 5 if flex_`sex' ==1
		quiet  replace lindi = -1 if flex_`sex' ==1
		quiet replace lowas = 1 if flex_`sex' ==1 //??
		quietly replace kfbcc = 0 if flex_`sex' ==1
		quietly replace kfb = 0 if flex_`sex' ==1

		global zero_var "liwmy liwftmy liwptmy yemmy ysemy yem yse"
		foreach var of varlist $zero_var {
			*quiet gen `var'_orig= `var'
			quiet replace `var'= 0 if flex_`sex' ==1
		}
		if "`country'" == "it" {
			replace yseev = 0 if flex_`sex' ==1
		}
		replace liwmy_a = liwmy_orig if flex_`sex' ==1 
		if "${country}" == "pt" {
			replace liwmy01_a = liwmy_orig if flex_`sex' ==1 
		}
		replace lunmy = 12 if flex_`sex' ==1 
		replace yempv_a = yem_new if flex_`sex' ==1
		replace yempv_a = 0 if yempv_a ==.
		if "`country'" == "it" | "`country'" == "ee" | "`country'" == "el"{
			replace bunctmy = yemmy if bunctmy == 0 & flex_`sex' ==1
		}
		else {
			replace bunmy = yemmy if bunmy == 0 & flex_`sex' ==1
		}
		
		assert les ==5 & lnu ==1 if flex_`sex' ==1

	}
}

if `i' > 5 | `j' > 5 {
								
	if `i' > 5 {
		di in r "Work alternative -female"
		local sex  = "f"
		local emp_stat_f = `empstat_f'
		local emp = `empstat_f'
		local sector_f = `sec_f' 
		local sect = `sec_f' 
		local multip = `multip_f'
		
		quiet replace lindi = 3 if `sect' == 1 & flex_`sex' == 1
		quiet replace lindi = 4 if `sect' == 2 & flex_`sex' == 1
		quiet replace lindi = 6 if `sect' == 3 & flex_`sex' == 1
		
		quiet replace les = 3 if  `emp' == 1 & flex_`sex' ==1
		quiet replace yemmy = 12 if flex_`sex' ==1 & yemmy==0 & `emp' == 1
		quiet replace yem = (p_hourly_`emp'_`sect')*lhw*4.333*`multip' 	if `emp' == 1 &  flex_`sex' ==1
		quiet replace yse = 0 	if `emp' == 1 &  flex_`sex' ==1
		quiet replace ysemy = 0 if flex_`sex' ==1 & `emp' == 1
		
		quiet replace les = 2 if  `emp' == 2 & flex_`sex' ==1
		quiet	replace ysemy = 12 if flex_`sex' ==1 & yemmy==0 & `emp' == 2
		quiet	replace yemmy = 0 if flex_`sex' ==1 & `emp' == 2
		quiet replace yse = (p_hourly_`emp'_`sect')*lhw*4.333*`multip' 	if `emp' == 2  &  flex_`sex' ==1
		quiet replace yem = 0 	if `emp' == 2 &  flex_`sex' ==1
		
		if "`country'" == "it" | "`country'" == "ee" | "`country'" == "el"{
			global zero_var "lunmy lnu yempv_a liwmy_a bunctmy"
		}
		else {
			global zero_var "lunmy lnu yempv_a liwmy_a bunmy"
		}

		foreach var of varlist $zero_var {
			quiet replace `var'= 0 if flex_`sex' ==1
		} 
		if "`country'" == "it" {
			replace yseev = 0 if flex_`sex' ==1
		}
	} 

	if `j' > 5 {
		di in r "Work alternative -male"
		local sex  = "m"
		local emp_stat_m = `empstat_m' 
		local sector_m = `sec_m'  
		local emp = `empstat_m'
		local sect = `sec_m' 
		local multip = `multip_m'
		
		quiet replace lindi = 3 if `sect' == 1 & flex_`sex' == 1
		quiet replace lindi = 4 if `sect' == 2 & flex_`sex' == 1
		quiet replace lindi = 6 if `sect' == 3 & flex_`sex' == 1
		quiet replace les = 3 if  `emp' == 1 & flex_`sex' ==1
		quiet replace yemmy = 12 if flex_`sex' ==1 & yemmy==0 & `emp' == 1
		quiet replace yem = (p_hourly_`emp'_`sect')*lhw*4.333*`multip' 	if `emp' == 1 &  flex_`sex' ==1
		quiet replace yse = 0 	if `emp' == 1 &  flex_`sex' ==1
		
		quiet replace les = 2 if  `emp' == 2 & flex_`sex' ==1
		quiet replace ysemy = 0 if flex_`sex' ==1 & `emp' == 1
		quiet	replace ysemy = 12 if flex_`sex' ==1 & yemmy==0 & `emp' == 2
		quiet	replace yemmy = 0 if flex_`sex' ==1 & `emp' == 2
		quiet replace yse = (p_hourly_`emp'_`sect')*lhw*4.333*`multip' 	if `emp' == 2  &  flex_`sex' ==1
		quiet replace yem = 0 	if `emp' == 2 &  flex_`sex' ==1
		
		if "`country'" == "it" | "`country'" == "ee" | "`country'" == "el"{
			global zero_var "lunmy lnu yempv_a liwmy_a bunctmy"
		}
		else {
			global zero_var "lunmy lnu yempv_a liwmy_a bunmy"
		}

		foreach var of varlist $zero_var {
			quiet replace `var'= 0 if flex_`sex' ==1
		} 	
		if "`country'" == "it" {
			replace yseev = 0 if flex_`sex' ==1
		}
	}								
}

	
quiet recode yem (. = 0)
quiet recode yse (. = 0)
*quiet recode yiy (. = 0)

emprep_inc `country'


format idperson %12.0f 

//macro list
di in r "Total number of input files=  `counter'"	

createFolder "`path_EMinput'\modified" "`country'_`year'_`choices'ch_f`i'_s`sector_f'_e`emp_stat_f'_m`j'_s`sector_m'_e`emp_stat_m'_`ref'"
								
global InFol_f`i'_s`sector_f'_e`emp_stat_f'_m`j'_s`sector_m'_e`emp_stat_m'_`ref'="`path_EMinput'\modified\\`country'_`year'_`choices'ch_f`i'_s`sector_f'_e`emp_stat_f'_m`j'_s`sector_m'_e`emp_stat_m'_`ref'"
								
outsheet `allvars' yempv_a liwmy_a lnu hhsize ed_* lhw_choice age* nch*  flex* choice using "${InFol_f`i'_s`sector_f'_e`emp_stat_f'_m`j'_s`sector_m'_e`emp_stat_m'_`ref'}/`filename'.txt",replace
	
//creation of input data for new reforms
if "`ref'" == "base" {
	createFolder "`path_EMinput'\modified" "`country'_`year'_`choices'ch_f`i'_s`sector_f'_e`emp_stat_f'_m`j'_s`sector_m'_e`emp_stat_m'_new"
	global InFol_f`i'_s`sector_f'_e`emp_stat_f'_m`j'_s`sector_m'_e`emp_stat_m'_new="`path_EMinput'\modified\\`country'_`year'_`choices'ch_f`i'_s`sector_f'_e`emp_stat_f'_m`j'_s`sector_m'_e`emp_stat_m'_new"

	outsheet `allvars' yempv_a liwmy_a lnu hhsize ed_* lhw_choice age* nch*  flex* choice using "${InFol_f`i'_s`sector_f'_e`emp_stat_f'_m`j'_s`sector_m'_e`emp_stat_m'_new}/`filename'.txt",replace		
}

//Used only as a flag file
copy "run_stata.bat" "`path_EMinput'/temp_folder_prepData/temp_ref`ref'_f`i'_s`sector_f'_e`emp_stat_f'_m`j'_s`sector_m'_e`emp_stat_m'.txt"	

di in r "END 1a_create_input_data: $S_TIME  $S_DATE"