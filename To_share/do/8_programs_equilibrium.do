*********************************************************************************
* 8_programs_equilibrium.do														
*		
* Contains programs used at 8_labour_demand.do file
* 																		
* 1-BASELINE programm is used to generate scalars related to the total of employment, unemployment and inactivity under the baseline.
* This is necessary because we should use the same procedure (tax regressions and utility parameters) to recover these scalars as under the reform or shock
*
* 2-EQUILIBRIUM program is used to find the values of parameters v and u under EQUILIBRIUM conditions.
*
* 3. REFORM program is used to generate scalars of reform predictions.
*
* Last Update: 04/07/2022 E.N.	
********************************************************************************* 

/// Generates scalars of baseline predictions and the tax function
capture program drop BASELINE
program define BASELINE
	set trace off
	version 17
	tempvar grossinc_new_f grossinc_new_m cons_tmp consum_iter U_dummy U_consum U_leis_m U_leis_f denom_c denom_m denom_f p_iter 
	tempvar I_m_couples I_f_couples E_f_couples E_m_couples U_m_couples U_f_couples
	tempvar I_m_singm I_f_singm E_f_singm E_m_singm U_m_singm U_f_singm
	tempvar I_m_singf I_f_singf E_m_singf E_f_singf U_m_singf U_f_singf
	tempvar E_m_temp E_f_temp I_m_temp I_f_temp U_m_temp U_f_temp
	tempvar cons_new cons_couples cons_singm cons_singf 
	tempvar  E_new U_new I_new 
		
	tempname v d_in_m d_in_f demand_h_base demand_E_base demand_I_base demand_U_base cons_new1 cons1 cons_new2 cons2 cons_new3 cons3 yh
 {
	scalar `v' = change[1,1]
	*scalar `v1' = exp(`1'[1,1])/(1+exp(`1'[1,1]))

	quiet generate `consum_iter' = .
	quiet gen `p_iter' = .
	quiet gen `cons_new' = .
	
	    // Loop over HH type
    foreach type in  "couples" "singm" "singf" {

			
			quiet estread using "${path_results}/estimation/${country}_${year}_clogit_`type'_${choices}ch.sters"
			estimates restore clogit_`type'_${country}_${year}
		
		replace `consum_iter' = max((dispy_flex*(1+`v') + other_disp)/4.333,0.01) `condition'
			
		if "`type'" == "couples" {
			local sex "m f"
			local condition "if inlist(flex_hh, 1) & flex_m == 1"
			
			scalar `d_in_m'= _b[d_in_m] + `v' 
			scalar `d_in_f'= _b[d_in_f] + `v' 
			
			scalar list `d_in_m'
			scalar list `d_in_f'
			
			sum `consum_iter'  consum `condition'
			
			/*if $UNEMPLOYMENT == 1 {
				quiet  gen double `U_dummy'= d_in_m*`d_in_m' + d_in_f*`d_in_f'  + d_un_m*_b[d_un_m] + d_un_f*_b[d_un_f]+ d_p_m*_b[d_p_m] + d_p_f*_b[d_p_f]+ d_f_m*_b[d_f_m] +  d_f_f*_b[d_f_f]+  d_o_f*_b[d_o_f]+  d_o_m*_b[d_o_m]  `condition'
			}*/
			*if $UNEMPLOYMENT != 1 {
				quiet  gen double `U_dummy'= d_in_m*`d_in_m' + d_in_f*`d_in_f'  + d_p_m*_b[d_p_m] + d_p_f*_b[d_p_f]+ d_f_m*_b[d_f_m] +  d_f_f*_b[d_f_f] +  d_o_f*_b[d_o_f]+  d_o_m*_b[d_o_m]  `condition'
			*}				
			quiet  gen double `U_consum' = `consum_iter' *(_b[consum] +`consum_iter'*_b[consum_consum] + leis_m*_b[consum_leis_m] + leis_f*_b[consum_leis_f] + hhsize*_b[consum_hhsize]) `condition'
			
			quiet  gen double `U_leis_m' = leis_m*_b[leis_m] + leis_leis_m*_b[leis_leis_m] + leis_age_m*_b[leis_age_m] + leis_age2_m*_b[leis_age2_m] + leis_numch_m*_b[leis_numch_m] + leis_numch3_m*_b[leis_numch3_m]+ leis_numch36_m*_b[leis_numch36_m] + leis_mortgage_m*_b[leis_mortgage_m] + leis_migrant_m*_b[leis_migrant_m] + leis_m_f*_b[leis_m_f]  `condition'
			
		quiet  gen double `U_leis_f' = leis_f*_b[leis_f] + leis_leis_f*_b[leis_leis_f] + leis_age_f*_b[leis_age_f] + leis_age2_f*_b[leis_age2_f] + leis_numch_f*_b[leis_numch_f] + leis_numch3_f*_b[leis_numch3_f] + leis_numch36_f*_b[leis_numch36_f] + leis_mortgage_f*_b[leis_mortgage_f] + leis_migrant_f*_b[leis_migrant_f] `condition'

			egen double `denom_c'  = total(exp(`U_dummy' + `U_consum' + `U_leis_m'+ `U_leis_f')) `condition',by(idperson) 
			quiet  replace `p_iter' = exp(`U_dummy' + `U_consum' + `U_leis_m'+ `U_leis_f')/`denom_c' `condition' //new probabilities
			sum  `p_iter' p_p${ryear}_base  `condition'
			drop `U_dummy'
		}
			
		if "`type'" != "couples" {
			
			if "`type'" == "singf" {
				local sex "f"
				local condition "if inlist(flex_hh, 2)"
			}
		
			if "`type'" == "singm" {
				local sex "m"
				local condition "if inlist(flex_hh, 3)"
			}
			
			scalar `d_in_`sex''= _b[d_in_`sex'] + `v' 
			
			*replace `consum_iter' = max(((dispy_`sex')*(1+`v') + other_disp)/4.333,0.01) `condition'
			
			sum `consum_iter' consum `condition'

			/*if $UNEMPLOYMENT == 1 {
				quiet  gen double `U_dummy'= d_in_`sex'*`d_in_`sex'' +  d_un_`sex'*_b[d_un_`sex'] + d_p_`sex'*_b[d_p_`sex'] + d_f_`sex'*_b[d_f_`sex'] + d_o_`sex'*_b[d_o_`sex']  `condition'
			}*/
			*if $UNEMPLOYMENT != 1 {
				quiet  gen double `U_dummy'= d_in_`sex'*`d_in_`sex'' +  d_p_`sex'*_b[d_p_`sex'] + d_f_`sex'*_b[d_f_`sex']+ d_o_`sex'*_b[d_o_`sex']   `condition'
			*}						
			quiet  replace `U_consum' = `consum_iter'*(_b[consum] + `consum_iter'*_b[consum_consum] + leis_`sex'*_b[consum_leis_`sex'] + hhsize *_b[consum_hhsize]) `condition'
									
			quiet  replace `U_leis_`sex'' = leis_`sex'*_b[leis_`sex'] + leis_leis_`sex'*_b[leis_leis_`sex'] + leis_age_`sex'*_b[leis_age_`sex'] + leis_age2_`sex'*_b[leis_age2_`sex'] + leis_numch_`sex'*_b[leis_numch_`sex'] + leis_numch3_`sex'*_b[leis_numch3_`sex']+ leis_numch36_`sex'*_b[leis_numch36_`sex'] + leis_mortgage_`sex'*_b[leis_mortgage_`sex'] + leis_migrant_`sex'*_b[leis_migrant_`sex']  `condition'
			
			egen double `denom_`sex''  = total(exp(`U_dummy' + `U_consum' + `U_leis_`sex'')) `condition',by(idperson) 
			quiet  replace `p_iter' = exp(`U_dummy' + `U_consum' + `U_leis_`sex'')/`denom_`sex'' `condition' //new probabilities
			sum  `p_iter' p_p${ryear}_base  `condition'
			drop `U_dummy'		
		}	
			
			foreach g in "m" "f"{
				foreach var in "E" "I" "U" {
					if "`var'" != "h" {
						bys idhh: 	egen  ``var'_`g'_`type'' = total(d_`var'_`g' * `p_iter')  `condition'
					}
					if "`var'" == "h" {
						bys idhh: 	egen ``var'_`g'_`type'' = total(`var'_`g' * `p_iter')  `condition' & `var'_`g'>5
					}
				}			
			}
			

	}
	
	
	foreach var in "E" "I" "U" {
		quietly gen ``var'_new' = .
		foreach g in "m" "f"{
			bysort idhh lhw_m_norand lhw_f_norand sec_m sec_f emp_stat_m emp_stat_f: egen double ``var'_`g'_temp' = total(``var'_`g'_couples')
			quietly	replace ``var'_new' = ``var'_`g'_temp' if flex_hh == 1 & flex_`g'==1
			quietly	replace ``var'_new' = ``var'_`g'_sing`g'' if flex_`g' ==1 & flex_hh!=1 
			
		}

	}			
	
	foreach var in "E" "I" "U"{
		replace ``var'_new' = ``var'_new'*dwt if ls == 1
		total ``var'_new' if ls == 1
		scalar demand_`var'_base = e(b)[1,1]
	}

	scalar total_base = demand_E_base+demand_I_base+demand_U_base
	scalar list demand_E_base
	}

end


capture program drop EQUILIBRIUM
program define EQUILIBRIUM
	set trace off
	version 17
	tempvar grossinc_new_f grossinc_new_m cons_tmp consum_iter U_dummy U_consum U_leis_m U_leis_f denom_c denom_m denom_f p_iter 
	tempvar I_m_couples I_f_couples E_f_couples E_m_couples U_m_couples U_f_couples
	tempvar I_m_singm I_f_singm E_f_singm E_m_singm U_m_singm U_f_singm
	tempvar I_m_singf I_f_singf E_m_singf E_f_singf U_m_singf U_f_singf
	tempvar E_m_temp E_f_temp I_m_temp I_f_temp U_m_temp U_f_temp
	tempvar cons_new cons_couples cons_singm cons_singf 
	tempvar  E_new U_new I_new 
		
	tempname v v0 v1 d_in_m d_in_f demand_h_base demand_E_base demand_I_base demand_U_base supply_E_new supply_U_new supply_I_new demand_E_new yh
quiet{
	scalar `v' = `1'[1,1]
	*scalar `v0' = tax[1,1]
	*scalar `v1' = tax[1,2]

	quiet generate `consum_iter' = .
	quiet gen `p_iter' = .

	    // Loop over HH type
    foreach type in  "couples" "singm" "singf" {
			
			quiet estread using "${path_results}/estimation/${country}_${year}_clogit_`type'_${choices}ch.sters"
			estimates restore clogit_`type'_${country}_${year}
			
			replace `consum_iter' = max((dispy_flex*exp(-`v'/ld_ela) + other_disp)/4.333,0.01) `condition'
			
		if "`type'" == "couples" {
			local sex "m f"
			local condition "if inlist(flex_hh, 1) & flex_m == 1"
			
			scalar `d_in_m'= _b[d_in_m] + `v' 
			scalar `d_in_f'= _b[d_in_f] + `v' 

			*replace `consum_iter' = max(((dispy_f+dispy_m)*(1+`v') + other_disp)/4.333,0.01) `condition'
			
			sum `consum_iter'  consum `condition'
			
			/*if $UNEMPLOYMENT == 1 {
				quiet  gen double `U_dummy'= d_in_m*`d_in_m' + d_in_f*`d_in_f'  + d_un_m*_b[d_un_m] + d_un_f*_b[d_un_f]+ d_p_m*_b[d_p_m] + d_p_f*_b[d_p_f]+ d_f_m*_b[d_f_m] +  d_f_f*_b[d_f_f]+  d_o_f*_b[d_o_f]+  d_o_m*_b[d_o_m]  `condition'
			}*/
			*if $UNEMPLOYMENT != 1 {
				quiet  gen double `U_dummy'= d_in_m*`d_in_m' + d_in_f*`d_in_f'  + d_p_m*_b[d_p_m] + d_p_f*_b[d_p_f]+ d_f_m*_b[d_f_m] +  d_f_f*_b[d_f_f] +  d_o_f*_b[d_o_f]+  d_o_m*_b[d_o_m]  `condition'
			*}				
			quiet  gen double `U_consum' = `consum_iter' *(_b[consum] +`consum_iter'*_b[consum_consum] + leis_m*_b[consum_leis_m] + leis_f*_b[consum_leis_f] + hhsize*_b[consum_hhsize]) `condition'
			quiet  gen double `U_leis_m' = leis_m*_b[leis_m] + leis_leis_m*_b[leis_leis_m] + leis_age_m*_b[leis_age_m] + leis_age2_m*_b[leis_age2_m] + leis_numch_m*_b[leis_numch_m] + leis_numch3_m*_b[leis_numch3_m]+ leis_numch36_m*_b[leis_numch36_m] + leis_mortgage_m*_b[leis_mortgage_m] + leis_migrant_m*_b[leis_migrant_m] + leis_m_f*_b[leis_m_f]  `condition'
			
			quiet  gen double `U_leis_f' = leis_f*_b[leis_f] + leis_leis_f*_b[leis_leis_f] + leis_age_f*_b[leis_age_f] + leis_age2_f*_b[leis_age2_f] + leis_numch_f*_b[leis_numch_f] + leis_numch3_f*_b[leis_numch3_f] + leis_numch36_f*_b[leis_numch36_f] + leis_mortgage_f*_b[leis_mortgage_f] + leis_migrant_f*_b[leis_migrant_f] `condition'

			egen double `denom_c'  = total(exp(`U_dummy' + `U_consum' + `U_leis_m'+ `U_leis_f')) `condition',by(idperson) 
			quiet  replace `p_iter' = exp(`U_dummy' + `U_consum' + `U_leis_m'+ `U_leis_f')/`denom_c' `condition' //new probabilities
			sum  `p_iter' p_p${ryear}_base  `condition'
			drop `U_dummy'
		}
			
		if "`type'" != "couples" {
			
			if "`type'" == "singf" {
				local sex "f"
				local condition "if inlist(flex_hh, 2)"
			}
		
			if "`type'" == "singm" {
				local sex "m"
				local condition "if inlist(flex_hh, 3)"
			}
			
			scalar `d_in_`sex''= _b[d_in_`sex'] + `v' 
			
			*replace `consum_iter' = max(((dispy_`sex')*(1+`v') + other_disp)/4.333,0.01) `condition'
			/*if $UNEMPLOYMENT == 1 {
				quiet  gen double `U_dummy'= d_in_`sex'*`d_in_`sex'' +  d_un_`sex'*_b[d_un_`sex'] + d_p_`sex'*_b[d_p_`sex'] + d_f_`sex'*_b[d_f_`sex'] + d_o_`sex'*_b[d_o_`sex']  `condition'
			}*/
			*if $UNEMPLOYMENT != 1 {
				quiet  gen double `U_dummy'= d_in_`sex'*`d_in_`sex'' +  d_p_`sex'*_b[d_p_`sex'] + d_f_`sex'*_b[d_f_`sex']+ d_o_`sex'*_b[d_o_`sex']   `condition'
			*}						
			quiet  replace `U_consum' = `consum_iter'*(_b[consum] + `consum_iter'*_b[consum_consum] + leis_`sex'*_b[consum_leis_`sex'] + hhsize *_b[consum_hhsize]) `condition'
									
			quiet  replace `U_leis_`sex'' = leis_`sex'*_b[leis_`sex'] + leis_leis_`sex'*_b[leis_leis_`sex'] + leis_age_`sex'*_b[leis_age_`sex'] + leis_age2_`sex'*_b[leis_age2_`sex'] + leis_numch_`sex'*_b[leis_numch_`sex'] + leis_numch3_`sex'*_b[leis_numch3_`sex']+ leis_numch36_`sex'*_b[leis_numch36_`sex'] + leis_mortgage_`sex'*_b[leis_mortgage_`sex'] + leis_migrant_`sex'*_b[leis_migrant_`sex']  `condition'
			
			egen double `denom_`sex''  = total(exp(`U_dummy' + `U_consum' + `U_leis_`sex'')) `condition',by(idperson) 
			quiet  replace `p_iter' = exp(`U_dummy' + `U_consum' + `U_leis_`sex'')/`denom_`sex'' `condition' //new probabilities
			sum  `p_iter' p_p${ryear}_base  `condition'
			drop `U_dummy'		
		}	
			
			foreach g in "m" "f"{
				foreach var in "E" "I" "U" {
					if "`var'" != "h" {
						bys idhh: 	egen  ``var'_`g'_`type'' = total(d_`var'_`g' * `p_iter')  `condition'
					}
					if "`var'" == "h" {
						bys idhh: 	egen ``var'_`g'_`type'' = total(`var'_`g' * `p_iter')  `condition' & `var'_`g'>5
					}
				}			
			}

	}

	
	foreach var in "E" "I" "U" {
		quietly gen ``var'_new' = .
		foreach g in "m" "f"{
			bysort idhh lhw_m_norand lhw_f_norand sec_m sec_f emp_stat_m emp_stat_f: egen double ``var'_`g'_temp' = total(``var'_`g'_couples')
			quietly	replace ``var'_new' = ``var'_`g'_temp' if flex_hh == 1 & flex_`g'==1
			quietly	replace ``var'_new' = ``var'_`g'_sing`g'' if flex_`g' ==1 & flex_hh!=1 
			
		}

	}			
	
	
	foreach var in "E" "I" "U"{
		replace ``var'_new' = ``var'_new'*dwt if ls == 1
		total ``var'_new' if ls == 1
		scalar `supply_`var'_new' = e(b)[1,1]
	}
		
	scalar `demand_E_new' = demand_E_orig*(exp(`v'))
	scalar `yh'= -((`demand_E_new'-`supply_E_new')^2 )
	
	}
	scalar `2'=`yh'

end


capture program drop RESULTS
program define RESULTS
	set trace off
	version 17
	tempvar grossinc_new_f grossinc_new_m cons_tmp consum_iter U_dummy U_consum U_leis_m U_leis_f denom_c denom_m denom_f p_iter 
	tempvar I_m_couples I_f_couples E_f_couples E_m_couples U_m_couples U_f_couples
	tempvar I_m_singm I_f_singm E_f_singm E_m_singm U_m_singm U_f_singm
	tempvar I_m_singf I_f_singf E_m_singf E_f_singf U_m_singf U_f_singf
	tempvar E_m_temp E_f_temp I_m_temp I_f_temp U_m_temp U_f_temp
	tempvar cons_new cons_couples cons_singm cons_singf 
	tempvar  E_new U_new I_new 
		
	tempname v v0 v1 d_in_m d_in_f demand_h_base demand_E_new demand_I_new demand_U_new 
quiet {
	scalar `v' = change[1,1]

	quiet generate `consum_iter' = .
	quiet gen `p_iter' = .
	quiet gen `cons_new' = .
	
	    // Loop over HH type
    foreach type in  "couples" "singm" "singf" {
	    
		replace `consum_iter' = max((dispy_flex*exp(-`v'/ld_ela) + other_disp)/4.333,0.01) `condition'
		
			quiet estread using "${path_results}/estimation/${country}_${year}_clogit_`type'_${choices}ch.sters"
			estimates restore clogit_`type'_${country}_${year}

			
		if "`type'" == "couples" {
			local sex "m f"
			local condition "if inlist(flex_hh, 1) & flex_m == 1"
			
			scalar `d_in_m'= _b[d_in_m] + `v' 
			scalar `d_in_f'= _b[d_in_f] + `v' 
			
			
			/*if $UNEMPLOYMENT == 1 {
				quiet  gen double `U_dummy'= d_in_m*`d_in_m' + d_in_f*`d_in_f'  + d_un_m*_b[d_un_m] + d_un_f*_b[d_un_f]+ d_p_m*_b[d_p_m] + d_p_f*_b[d_p_f]+ d_f_m*_b[d_f_m] +  d_f_f*_b[d_f_f]+  d_o_f*_b[d_o_f]+  d_o_m*_b[d_o_m]  `condition'
			}*/
			*if $UNEMPLOYMENT != 1 {
				quiet  gen double `U_dummy'= d_in_m*`d_in_m' + d_in_f*`d_in_f'  + d_p_m*_b[d_p_m] + d_p_f*_b[d_p_f]+ d_f_m*_b[d_f_m] +  d_f_f*_b[d_f_f] +  d_o_f*_b[d_o_f]+  d_o_m*_b[d_o_m]  `condition'
			*}				
			quiet  gen double `U_consum' = `consum_iter' *(_b[consum] +`consum_iter'*_b[consum_consum] + leis_m*_b[consum_leis_m] + leis_f*_b[consum_leis_f] + hhsize*_b[consum_hhsize]) `condition'
			quiet  gen double `U_leis_m' = leis_m*_b[leis_m] + leis_leis_m*_b[leis_leis_m] + leis_age_m*_b[leis_age_m] + leis_age2_m*_b[leis_age2_m] + leis_numch_m*_b[leis_numch_m] + leis_numch3_m*_b[leis_numch3_m]+ leis_numch36_m*_b[leis_numch36_m] + leis_mortgage_m*_b[leis_mortgage_m] + leis_migrant_m*_b[leis_migrant_m] + leis_m_f*_b[leis_m_f]  `condition'
			
			quiet  gen double `U_leis_f' = leis_f*_b[leis_f] + leis_leis_f*_b[leis_leis_f] + leis_age_f*_b[leis_age_f] + leis_age2_f*_b[leis_age2_f] + leis_numch_f*_b[leis_numch_f] + leis_numch3_f*_b[leis_numch3_f] + leis_numch36_f*_b[leis_numch36_f] + leis_mortgage_f*_b[leis_mortgage_f] + leis_migrant_f*_b[leis_migrant_f] `condition'

			egen double `denom_c'  = total(exp(`U_dummy' + `U_consum' + `U_leis_m'+ `U_leis_f')) `condition',by(idperson) 
			quiet  replace `p_iter' = exp(`U_dummy' + `U_consum' + `U_leis_m'+ `U_leis_f')/`denom_c' `condition' //new probabilities
			sum  `p_iter' p_p${ryear}_base  `condition'
			drop `U_dummy'
		}
			
		if "`type'" != "couples" {
			
			if "`type'" == "singf" {
				local sex "f"
				local condition "if inlist(flex_hh, 2)"
			}
		
			if "`type'" == "singm" {
				local sex "m"
				local condition "if inlist(flex_hh, 3)"
			}
			
			scalar `d_in_`sex''= _b[d_in_`sex'] + `v' 
			
			*replace `consum_iter' = max(((dispy_`sex')*(1+`v') + other_disp)/4.333,0.01) `condition'
			

			/*if $UNEMPLOYMENT == 1 {
				quiet  gen double `U_dummy'= d_in_`sex'*`d_in_`sex'' +  d_un_`sex'*_b[d_un_`sex'] + d_p_`sex'*_b[d_p_`sex'] + d_f_`sex'*_b[d_f_`sex'] + d_o_`sex'*_b[d_o_`sex']  `condition'
			}*/
			*if $UNEMPLOYMENT != 1 {
				quiet  gen double `U_dummy'= d_in_`sex'*`d_in_`sex'' +  d_p_`sex'*_b[d_p_`sex'] + d_f_`sex'*_b[d_f_`sex']+ d_o_`sex'*_b[d_o_`sex']   `condition'
		*	}						
			quiet  replace `U_consum' = `consum_iter'*(_b[consum] + `consum_iter'*_b[consum_consum] + leis_`sex'*_b[consum_leis_`sex'] + hhsize *_b[consum_hhsize]) `condition'
									
			quiet  replace `U_leis_`sex'' = leis_`sex'*_b[leis_`sex'] + leis_leis_`sex'*_b[leis_leis_`sex'] + leis_age_`sex'*_b[leis_age_`sex'] + leis_age2_`sex'*_b[leis_age2_`sex'] + leis_numch_`sex'*_b[leis_numch_`sex'] + leis_numch3_`sex'*_b[leis_numch3_`sex']+ leis_numch36_`sex'*_b[leis_numch36_`sex'] + leis_mortgage_`sex'*_b[leis_mortgage_`sex'] + leis_migrant_`sex'*_b[leis_migrant_`sex']  `condition'
			
			egen double `denom_`sex''  = total(exp(`U_dummy' + `U_consum' + `U_leis_`sex'')) `condition',by(idperson) 
			quiet  replace `p_iter' = exp(`U_dummy' + `U_consum' + `U_leis_`sex'')/`denom_`sex'' `condition' //new probabilities
			sum  `p_iter' p_p${ryear}_base  `condition'
			drop `U_dummy'		
		}	
			
			foreach g in "m" "f"{
				foreach var in "E" "I" "U" {
					if "`var'" != "h" {
						bys idhh: 	egen  ``var'_`g'_`type'' = total(d_`var'_`g' * `p_iter')  `condition'
					}
					if "`var'" == "h" {
						bys idhh: 	egen ``var'_`g'_`type'' = total(`var'_`g' * `p_iter')  `condition' & `var'_`g'>5
					}
				}			
			}
			
	}
	
	
	foreach var in "E" "I" "U" {
		quietly gen ``var'_new' = .
		foreach g in "m" "f"{
			bysort idhh lhw_m_norand lhw_f_norand sec_m sec_f emp_stat_m emp_stat_f: egen double ``var'_`g'_temp' = total(``var'_`g'_couples')
			quietly	replace ``var'_new' = ``var'_`g'_temp' if flex_hh == 1 & flex_`g'==1
			quietly	replace ``var'_new' = ``var'_`g'_sing`g'' if flex_`g' ==1 & flex_hh!=1 
			
		}

	}			
	
	
	foreach var in "E" "I" "U"{
		replace ``var'_new' = ``var'_new'*dwt if ls == 1
		total ``var'_new' if ls == 1
		scalar demand_`var'_new = e(b)[1,1]
		di in r "demand_`var'_new"
		scalar list demand_`var'_new
	}
		
	scalar total_new = demand_E_new+demand_I_new+demand_U_new
	scalar list total_new
	
	}

end

