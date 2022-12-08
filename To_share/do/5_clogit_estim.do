*********************************************************************************
* 5_clogit_estim.do																*
*																				*
* Specify Covariates for the estimation and estimates utility function for the	* 
* different household types.													*
* Last Update: 11/11/2021 E.N.													*
*********************************************************************************

capture log close


log using "${outlog}/clogit_ch_${country}_${year}.log",replace

//Merge dataset with sampling design					
use "${path_LSscen}/0_fullsample/${country}_${year}_${choices}ch_originalsample.dta" , clear
	
merge m:1  idper using "${path_LS}/baseline/${country}_${year}_${choices}ch_baseline_full.dta"
	
svyset psu1 [pw=dwt],strata(strata1)


local ref_exp = "p${pyear}_base" 
			
foreach ref in `ref_exp'{ 
	quiet gen ils_sic_`ref' = ils_sicee_`ref' + ils_sicse_`ref'+ ils_sicer_`ref' + ils_sicot_`ref'
	local var_inc "dispy tax ben sic"
		foreach var in `var_inc'{ 

		gen `var'_stat_`ref' = (ils_`var'_`ref')  
		}
	quiet gen net_expend_stat_`ref' = tax_stat_`ref' + sic_stat_`ref' - ben_stat_`ref'  	
}

capture	keep idper idhh *stat*  psu1 strata1
		
sort idper

merge idper using "${path_LSscen}/3_LS/${country}_${year}_${choices}ch_LS.dta"


// consumption variable, for estimation
foreach s of local sex {
    replace age_`s'  =  age_`s' / 10
    replace age2_`s' = age2_`s' / 100
}
*keep if flex_hh == 1|flex_hh == 2|flex_hh == 3 
** Loop HH type
  
drop consum
gen consum = .
gen p_p${pyear}_base  = 0
local py $policyyears

foreach var of varlist consum hhsize leis_m leis_f age_m age_f age2_m age2_f numch{
	gen consum_`var' = .
}

/*
gen unconstraint_pt = (reason_pt==4|reason_pt==5|reason_pt==6)
gen  d_p_m_unconst =  unconstraint_pt*d_p_m
gen  d_p_f_unconst =  unconstraint_pt*d_p_f*/

local sex "m f"
foreach g of local sex {

	*gen d_p_`g'_unconst = d_p_`g'*unconstraint_pt 

	 if "`g'" == "m" {
        local gender "Male"
    }
		 if "`g'" == "f" {
        local gender "Female"
    }
	
	label var d_in_`g' "In-work dummy  `gender' "
	label var d_p_`g' "Part-time dummy - `gender'"
	label var d_f_`g' "Full-time dummy - `gender'"
	label var d_o_`g' "Over-time dummy - `gender'"
	label var d_un_`g' "Unemployment dummy - `gender'"
	label var d_un_`g' "Unemployment dummy - `gender'"
	*label var d_p_`g'_unconst "Voluntary Part-time - `gender'"


	if ${EmplStatus} ==2 {

		label var emp_2_`g' "Self-employed dummy - `gender'"
		label var d_in_1_2_`g' "In-work dummy x Self-employed in sector 1 - `gender'"
		label var d_p_1_2_`g' "Part-time dummy x Self-employed in sector 1 - `gender'"
		label var d_f_1_2_`g' "Full-time dummy x Selef-employed in sector 1 - `gender'"
	}
	
	label var leis_`g' "Leisure - `gender'"
	label var leis_leis_`g' "Leisure square - `gender'"
	label var leis_age_`g' "Leisure x age - `gender'"
	label var leis_age2_`g' "Leisure x age square - `gender'"
	label var leis_numch_`g' "Leisure x #children - `gender'"
	label var leis_numch3_`g' "Leisure x #children < 3 year - `gender'"
	label var leis_numch36_`g' "Leisure x #children 3-6 year - `gender'"
	label var leis_mortgage_`g' "Leisure x Mortgage - `gender'"
	label var leis_migrant_`g' "Leisure x Migrant - `gender'"
	label var consum_leis_`g' "Net income x Leisure - `gender'"
}

label var consum "Net income"
label var consum_consum "Net income square"
label var consum_hhsize "Net income x household size"
label var consum_consum "Net income square"
label var leis_m_f "Leisure Male x Leisure Female"

local min_interval = $min_hour
local max_interval = $max_hour-$step
	
if $UNEMPLOYMENT == 0{
label define alternatives 0 "Inactive"	
}	
if $UNEMPLOYMENT == 1{
label define alternatives 0 "Inactive" 5 "Unemployed"	
}	 

forvalues x = `min_interval'($step)`max_interval'{
		di in r "`x'"
		local lab_l = `x'
		local lab_h = `x'+$step
		local lab `"`lab_l' - `lab_h'"'
		di in r "`lab'"
		gen d_alt_m`x' = (lhw_m_norand==`x') 
		gen d_alt_f`x' = (lhw_f_norand==`x') 
	label define alternatives `lab_h' `"`lab'"', modify
}
	
label values lhw_m_norand alternatives
label values lhw_f_norand alternatives

foreach g in "m" "f" {				
	foreach name in "numch" "numch3" "numch36" "migrant" {
		generate d_`name'_`g' = d_in_`g'*`name'
    }
} 

/*education*/
cap gen edc_L = ed_low
cap gen edc_M = ed_middle
cap gen edc_H = ed_high

gen edu = 1 if edc_L==1
replace edu = 2 if edc_M ==1
replace edu = 3 if edc_H ==1

gen age_group = (dag > 17 & dag < 30 )
replace age_group = 3 if dag > 40
replace age_group = 2 if dag > 29 & dag < 41

gen ch_group = numch>0

foreach g in "m" "f"{
	quiet gen h_`g' = lhw_`g'
	replace h_`g' = 0  if lhw_`g'_norand <= 5
	gen d_E_`g' = d_in_`g'
	gen d_I_`g' = d_out_`g'
	gen d_U_`g' = d_un_`g'
	gen d_all_`g' = d_E_`g' +d_I_`g'+d_U_`g' 
	assert d_all_`g' ==1 if flex_`g'==1
}  

replace lhw_choice = 0 if choice_g == 0 &  lhw_choice !=0
keep if flex_hh>0 & flex_hh<4
label var ls "Observed Frequencies"

gen cons_base =.
 foreach type in "couples"  "singm"  "singf"  {

	*set trace on
	 if "`type'" == "couples" {
        local condition ""
        local hh "_hh"
		local genders = "m f"
        local condition "if inlist(flex_hh, 1) & flex_m ==1" 
		egen hstring_`type'= group(lhw_f_norand lhw_m_norand)
		*gen hstring_`type' = "F" + string(choice_hour_f) + "  " + "M" + string(choice_hour_m) /*in case of random hours alternatives*/
		*label variable hstring_`type' "high blood pressure"
    }
	
	if "`type'" == "singm" {
        local condition "" 
        local hh "_hh"
		local genders = "m"
		local name = "Single Men"
		local letter = "D"
        local condition "if inlist(flex_hh, 3) & flex_m == 1"
		egen hstring_`type'= group(lhw_m_norand)
		*gen hstring_`type' = string(choice_hour_m) /*in case of random hours alternatives*/
    }
	
	if "`type'" == "singf" {
        local condition ""
		local genders = "f"
		local name = "Single Women"
		local letter = "C"
        local hh "_hh"
        local condition "if inlist(flex_hh, 2) & flex_f == 1"
		egen hstring_`type'= group(lhw_f_norand)
		*gen hstring_`type' = string(choice_hour_f) /*in case of random hours alternatives*/
    }

	local py $policyyears
	di in r "ils_dispy_p${pyear}_base`hh'"
	
	quietly replace consum = max(ils_dispy_p${pyear}_base`hh'/ 4.333 , 0.01) `condition'
*leis_mother_`g' leis_father_`g' leis_ed_high_`g' leis_ed_middle_`g' leis_migrant_EU_`g'  leis_migrant_nonEU_`g'
	/*generation of leisure related variables*/
	foreach g in `genders'{
		local var_`g' "leis_`g' leis_leis_`g' leis_age_`g' leis_age2_`g'  leis_numch_`g' leis_numch3_`g' leis_numch36_`g' leis_migrant_`g' leis_mortgage_`g'"  
		if "$country" == "lv"|"$country" == "cz"  {
			local peaks_`g' = ""	
		}
		else {
			local peaks_`g' = "d_p_`g'_unconst"	
			local peaks_`g' = ""	
	
		}
		
		local peaks_`g' "`peaks_`g'' d_in_`g' d_p_`g' d_f_`g' d_o_`g'" 

		di in r `peaks_`g''
		if $UNEMPLOYMENT == 1 {
			*local peaks_`g' "`peaks_`g'' d_un_`g'"
		}
	} 

	foreach var of varlist consum hhsize leis_m leis_f{
		replace consum_`var' = `var'* consum 
	}
		
	if "`type'" == "couples" {
		display "`condition'"
		local consumption = "consum consum_consum consum_hhsize consum_leis_m consum_leis_f"

		local variables  "`peaks_m' `peaks_f'  `var_m' `var_f' leis_m_f `consumption'"  
		
		clogit ls `variables' `condition',group(idhh) 

*bootstrap, reps(5) cluster(idhh) or nodots seed(25654):  clogit ls `variables' `condition',group(idhh)
		estimates store clogit_`type'_${country}_${year}
		estwrite clogit_`type'_${country}_${year} using "${path_results}/estimation/${country}_${year}_clogit_`type'_${choices}ch.sters", replace
			
		predict p_`type' `condition'

		bys lhw_f_norand lhw_m_norand: sum p_`type' ls `condition' 
		*graph bar ls p_`type' `condition', over(hstring_`type', label(labsize(small) angle(90))) bargap(-30) title("${COUNTRY}") note("EUROMOD:  blablabla") saving("${outlog}/fit/simfit_`type'_${choices}ch_${country}.gph", replace)

		replace p_p${pyear}_base = p_`type' `condition'
		
		bys idper lhw_f_norand: egen p_`type'_f = total(p_`type') `condition'
		bys idper lhw_f_norand: egen ls_ff = total(ls) `condition'
		
		bys idper lhw_m_norand: egen p_`type'_m = total(p_`type') `condition'
		bys idper lhw_m_norand: egen ls_mm = total(ls) `condition'

		label var p_`type' "Predicted Probabilities"
		*bys lhw_f_norand: sum p_`type'_f ls_ff  `condition'
		asdoc by lhw_m_norand: sum p_`type'_m ls_mm  `condition', center col label title(\fs28 Table 2.A. The average of predicted probabilities and observed fractions across labour supply alternatives - Women in Couple) statistics(mean) dec(6) save(${path_results2share}/${country}_${year}_${choices}ch/2-Model Prediction.rtf)  replace
		*bys lhw_m_norand: sum p_`type'_m ls_mm  `condition'
		asdoc by lhw_f_norand: sum p_`type'_f ls_ff  `condition', center col label title(\fs28 Table 2.B. The average of predicted probabilities and observed fractions across labour supply alternatives -Men in Couple) statistics(mean) dec(6) save(${path_results2share}/${country}_${year}_${choices}ch/2-Model Prediction.rtf) append		
		
		drop p_`type' 
		quietly replace consum = max(ils_dispy_p${ryear}_base`hh'/ 4.333 , 0.01) `condition'
		predict p_`type' `condition'
		gen p_p${ryear}_base = p_`type'  `condition'
		drop ls_mm ls_ff 
	} 
  
	if "`type'" != "couples" {
		display "`condition'"
		count `condition'			
		local consumption "consum consum_consum consum_hhsize consum_leis_`genders'" 
		local variables "`peaks_`genders'' `var_`genders''  `consumption'"

		clogit ls `variables' `condition',group(idhh) 
		*bootstrap, reps(10) strata(idhh) or nodots seed(25654):  clogit ls `variables' `condition',group(idhh)
		estimates store clogit_`type'_${country}_${year}
		estwrite clogit_`type'_${country}_${year} using ///
			"${path_results}/estimation/${country}_${year}_clogit_`type'_${choices}ch.sters" ///
			, replace
			predict p_`type' `condition'
		replace p_p${pyear}_base = p_`type' `condition'

		
		
		*graph bar ls p_`type' `condition', over(hstring_`type', label(labsize(small) angle(90))) bargap(-30) title("${COUNTRY}") note("EUROMOD:  blablabla") saving("${outlog}/fit/simfit_`type'_${choices}ch_${country}.gph", replace)
	/*goodness of fit*/

		label var p_`type' "Predicted"
		
		bys idper lhw_`genders'_norand: egen p_`type'_`genders' = total(p_`type') `condition'
		bys idper lhw_`genders'_norand: egen ls_`genders'`genders' = total(ls) `condition'
		
		*bys lhw_f_norand: sum p_`type'_`genders' ls_`genders'`genders'  `condition'
		
		if "`type'" == "singm" {
		asdoc by lhw_f_norand: sum p_`type'_`genders' ls_`genders'`genders'  `condition', center col label title(\fs28 Table 2.`letter'. The average values of predicted probabilities and observed fractions across labour supply alternatives - `name') dec(6) statistics(mean) save(${path_results2share}/${country}_${year}_${choices}ch/2-Model Prediction.rtf) append
		}
		if "`type'" == "singf" {
		    asdoc by lhw_m_norand: sum p_`type'_`genders' ls_`genders'`genders'  `condition', center col label title(\fs28 Table 2.`letter'. The average values of predicted probabilities and observed fractions across labour supply alternatives - `name') dec(6) statistics(mean) save(${path_results2share}/${country}_${year}_${choices}ch/2-Model Prediction.rtf) append
		}
		
		/*
		egen ID_`genders'= group(lhw_`genders'_norand sec_`genders' emp_stat_`genders')
		asdoc by ID_`genders': sum p_`type' ls  `condition', center col label title(\fs28 Table 2.`letter'. The average of predicted probabilities and observed fractions across labour supply alternatives - `name') dec(6) statistics(mean) save(${path_results2share}/${country}_${year}_${choices}ch/2-Model Prediction.rtf) append*/
		drop p_`type' 
		quietly replace consum = max(ils_dispy_p${ryear}_base`hh'/ 4.333 , 0.01) `condition'
		predict p_`type' `condition'
		replace p_p${ryear}_base = p_`type'  `condition'
		
	}



	local var_ls = "h d_E d_I d_U"
			foreach s in `sex' { 
				foreach var in `var_ls' {
					if "`var'" != "h" {
						bys idhh: 	egen `var'_`s'_`type' = total(`var'_`s' * p_`type')  `condition'
					}
					if "`var'" == "h" {
						bys idhh: 	egen `var'_`s'_`type' = total(`var'_`s' * p_`type')  `condition'
					}
				}			
			}
		bys idhh: 	egen  cons_`type' = total(consum * p_p${ryear}_base)  `condition'
		replace cons_base = cons_`type'  `condition'
		
		
			
}




save "${path_LSscen}/4_pred/${country}_${year}_${choices}ch_pred_LS.dta", replace


local sex "m f"

	foreach name in `var_ls'{
		quietly gen `name'_base = .
		foreach s in `sex'{ 
			bysort idhh lhw_m_norand lhw_f_norand sec_m sec_f emp_stat_m emp_stat_f: egen double `name'_`s'_base = total(`name'_`s'_couples)
			quietly	replace `name'_base = `name'_`s'_base if flex_hh == 1 & flex_`s'==1
			quietly	replace `name'_base = `name'_`s'_sing`s' if flex_`s' ==1 & flex_hh!=1 
			
		}
	}			


keep if  ls ==1 & flex_hh >0 & flex_hh <4

foreach var in "d_E" "d_I" "d_U"{
	
		gen `var'_new = `var'_base * dwt 
		total `var'_new
		scalar demand_`var'_base = e(b)[1,1]
		di in r "demand_`var'_base"
		scalar list demand_`var'_base

}	

total dwt
scalar demand_tot_base = e(b)[1,1]
scalar list demand_tot_base

scalar demand_tot_base = demand_d_E_base+demand_d_I_base
scalar list demand_tot_base


label var ls "clogit dependent variable"
estout clogit_couples_${country}_${year} clogit_singf_${country}_${year} clogit_singm_${country}_${year}
esttab clogit_couples_${country}_${year} clogit_singf_${country}_${year} clogit_singm_${country}_${year} using "${path_results2share}/${country}_${year}_${choices}ch/2-Utility_parameters.rtf", replace label title({\b Table 1: Conditional Logit results })  nonumbers mtitles("Couples" "Single Women" "Single Men") scalars(N ll r2_p aic bic ) 


