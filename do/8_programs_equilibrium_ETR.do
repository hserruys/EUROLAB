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
capture program drop TAXFUNCTION
program define TAXFUNCTION
	set trace off
	version 17
	tempvar grossinc_new_f grossinc_new_m cons_tmp consum_iter U_dummy U_consum U_leis_m U_leis_f denom_c denom_m denom_f p_iter 
	tempvar I_m_couples I_f_couples E_f_couples E_m_couples U_m_couples U_f_couples
	tempvar I_m_singm I_f_singm E_f_singm E_m_singm U_m_singm U_f_singm
	tempvar I_m_singf I_f_singf E_m_singf E_f_singf U_m_singf U_f_singf
	tempvar E_m_temp E_f_temp I_m_temp I_f_temp U_m_temp U_f_temp
	tempvar cons_new cons_couples cons_singm cons_singf 
	tempvar  E_new U_new I_new 
		
	tempname v v1 d_in_m d_in_f demand_h_base demand_E_base demand_I_base demand_U_base cons_new cons yh
 quiet{
	scalar `v' = change[1,1]
	scalar `v1' = 1/(1+exp(`1'[1,1]))
	
	quiet generate `consum_iter' = .
	quiet gen `p_iter' = .
	quiet gen `cons_new' = .
	
	    // Loop over HH type
    foreach type in  "couples" "singm" "singf" {
		
		*quietly replace `consum_iter' = max(ils_dispy_p${ryear}_base_hh/ 4.333 , 0.01) `condition'
			
			quiet estread using "${path_results}/estimation/${country}_${year}_clogit_`type'_${choices}ch.sters"
			estimates restore clogit_`type'_${country}_${year}

			
		if "`type'" == "couples" {
			local sex "m f"
			local condition "if inlist(flex_hh, 1) & flex_m == 1"
			
			scalar `d_in_m'= _b[d_in_m] + `v' 
			scalar `d_in_f'= _b[d_in_f] + `v' 
			
			replace `consum_iter' = max(((earning_f+earning_m + unearned_m + unearned_f)*(1-`v1') + other_disp)/4.333,0.01) `condition' 
			
			
			sum `consum_iter'  consum `condition'
			
			if $UNEMPLOYMENT == 1 {
				quiet  gen double `U_dummy'= d_in_m*`d_in_m' + d_in_f*`d_in_f'  + d_un_m*_b[d_un_m] + d_un_f*_b[d_un_f]+ d_p_m*_b[d_p_m] + d_p_f*_b[d_p_f]+ d_f_m*_b[d_f_m] +  d_f_f*_b[d_f_f]+  d_o_f*_b[d_o_f]+  d_o_m*_b[d_o_m]  `condition'
			}
			if $UNEMPLOYMENT != 1 {
				quiet  gen double `U_dummy'= d_in_m*`d_in_m' + d_in_f*`d_in_f'  + d_p_m*_b[d_p_m] + d_p_f*_b[d_p_f]+ d_f_m*_b[d_f_m] +  d_f_f*_b[d_f_f] +  d_o_f*_b[d_o_f]+  d_o_m*_b[d_o_m]  `condition'
			}				
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
			
			replace `consum_iter' = max(((earning_`sex' + unearned_`sex')*(1-`v1') + other_disp)/4.333,0.01) `condition' 
			
			sum `consum_iter' consum `condition'

			if $UNEMPLOYMENT == 1 {
				quiet  gen double `U_dummy'= d_in_`sex'*`d_in_`sex'' +  d_un_`sex'*_b[d_un_`sex'] + d_p_`sex'*_b[d_p_`sex'] + d_f_`sex'*_b[d_f_`sex'] + d_o_`sex'*_b[d_o_`sex']  `condition'
			}
			if $UNEMPLOYMENT != 1 {
				quiet  gen double `U_dummy'= d_in_`sex'*`d_in_`sex'' +  d_p_`sex'*_b[d_p_`sex'] + d_f_`sex'*_b[d_f_`sex']+ d_o_`sex'*_b[d_o_`sex']   `condition'
			}						
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
			
			bys idhh: 	egen  `cons_`type'' = total(`consum_iter' * `p_iter')  `condition'
			replace `cons_new' = `cons_`type''  `condition'
	}
	
	
	foreach var in "E" "I" "U" {
		quietly gen ``var'_new' = .
		foreach g in "m" "f"{
			bysort idhh lhw_m_norand lhw_f_norand sec_m sec_f emp_stat_m emp_stat_f: egen double ``var'_`g'_temp' = total(``var'_`g'_couples')
			quietly	replace ``var'_new' = ``var'_`g'_temp' if flex_hh == 1 & flex_`g'==1
			quietly	replace ``var'_new' = ``var'_`g'_sing`g'' if flex_`g' ==1 & flex_hh!=1 
			
		}

	}			
	
		sum `cons_new' if ls==1 & (inlist(flex_hh, 1) & flex_m == 1) | (inlist(flex_hh, 2)& flex_f == 1)|(inlist(flex_hh, 3)&flex_f == 1)
		scalar `cons_new'=r(mean)
		
		sum cons if  ls==1 &  (inlist(flex_hh, 1) & flex_m == 1) | (inlist(flex_hh, 2)& flex_f == 1)|(inlist(flex_hh, 3)&flex_f == 1)
		scalar `cons'=r(mean)
		
	

	foreach var in "E" "I" "U"{
		replace ``var'_new' = ``var'_new'*dwt if ls == 1
		total ``var'_new' if ls == 1
		scalar demand_`var'_base = e(b)[1,1]
	}

	scalar total_base = demand_E_base+demand_I_base+demand_U_base
	scalar `yh'= -(`cons_new' -`cons')^2
	scalar list `yh'

	}
	scalar `2'=`yh'
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
	scalar `v1' = tax[1,1]

	quiet generate `consum_iter' = .
	quiet gen `p_iter' = .

	    // Loop over HH type
    foreach type in  "couples" "singm" "singf" {
			
			quiet estread using "${path_results}/estimation/${country}_${year}_clogit_`type'_${choices}ch.sters"
			estimates restore clogit_`type'_${country}_${year}

			
		if "`type'" == "couples" {
			local sex "m f"
			local condition "if inlist(flex_hh, 1) & flex_m == 1"
			
			scalar `d_in_m'= _b[d_in_m] + `v' 
			scalar `d_in_f'= _b[d_in_f] + `v' 
			
			replace `consum_iter' = max(((((earning_f+earning_m)*exp(-`v'/ld_ela) + unearned_m + unearned_f)*(1-`v1')) + other_disp)/4.333,0.01) `condition'

			
			sum `consum_iter'  consum `condition'
			
			if $UNEMPLOYMENT == 1 {
				quiet  gen double `U_dummy'= d_in_m*`d_in_m' + d_in_f*`d_in_f'  + d_un_m*_b[d_un_m] + d_un_f*_b[d_un_f]+ d_p_m*_b[d_p_m] + d_p_f*_b[d_p_f]+ d_f_m*_b[d_f_m] +  d_f_f*_b[d_f_f]+  d_o_f*_b[d_o_f]+  d_o_m*_b[d_o_m]  `condition'
			}
			if $UNEMPLOYMENT != 1 {
				quiet  gen double `U_dummy'= d_in_m*`d_in_m' + d_in_f*`d_in_f'  + d_p_m*_b[d_p_m] + d_p_f*_b[d_p_f]+ d_f_m*_b[d_f_m] +  d_f_f*_b[d_f_f] +  d_o_f*_b[d_o_f]+  d_o_m*_b[d_o_m]  `condition'
			}				
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
			
			replace `consum_iter' = max(((earning_`sex'*exp(-`v'/ld_ela) + unearned_`sex')*(1-`v1') + other_disp)/4.333,0.01) `condition'

						
			if $UNEMPLOYMENT == 1 {
				quiet  gen double `U_dummy'= d_in_`sex'*`d_in_`sex'' +  d_un_`sex'*_b[d_un_`sex'] + d_p_`sex'*_b[d_p_`sex'] + d_f_`sex'*_b[d_f_`sex'] + d_o_`sex'*_b[d_o_`sex']  `condition'
			}
			if $UNEMPLOYMENT != 1 {
				quiet  gen double `U_dummy'= d_in_`sex'*`d_in_`sex'' +  d_p_`sex'*_b[d_p_`sex'] + d_f_`sex'*_b[d_f_`sex']+ d_o_`sex'*_b[d_o_`sex']   `condition'
			}						
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
	scalar `v1' = tax[1,1]

	quiet generate `consum_iter' = .
	quiet gen `p_iter' = .
	quiet gen `cons_new' = .
	
	    // Loop over HH type
    foreach type in  "couples" "singm" "singf" {
		
		*quietly replace `consum_iter' = max(ils_dispy_p${ryear}_base_hh/ 4.333 , 0.01) `condition'
			
			quiet estread using "${path_results}/estimation/${country}_${year}_clogit_`type'_${choices}ch.sters"
			estimates restore clogit_`type'_${country}_${year}

			
		if "`type'" == "couples" {
			local sex "m f"
			local condition "if inlist(flex_hh, 1) & flex_m == 1"
			
			scalar `d_in_m'= _b[d_in_m] + `v' 
			scalar `d_in_f'= _b[d_in_f] + `v' 
			
			replace `consum_iter' = max((((earning_f+earning_m)*exp(-`v'/ld_ela) + unearned_m + unearned_f)*(1-`v1') + other_disp)/4.333,0.01) `condition'
						
						
			sum `consum_iter'  consum `condition'
			
			if $UNEMPLOYMENT == 1 {
				quiet  gen double `U_dummy'= d_in_m*`d_in_m' + d_in_f*`d_in_f'  + d_un_m*_b[d_un_m] + d_un_f*_b[d_un_f]+ d_p_m*_b[d_p_m] + d_p_f*_b[d_p_f]+ d_f_m*_b[d_f_m] +  d_f_f*_b[d_f_f]+  d_o_f*_b[d_o_f]+  d_o_m*_b[d_o_m]  `condition'
			}
			if $UNEMPLOYMENT != 1 {
				quiet  gen double `U_dummy'= d_in_m*`d_in_m' + d_in_f*`d_in_f'  + d_p_m*_b[d_p_m] + d_p_f*_b[d_p_f]+ d_f_m*_b[d_f_m] +  d_f_f*_b[d_f_f] +  d_o_f*_b[d_o_f]+  d_o_m*_b[d_o_m]  `condition'
			}				
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
			
			replace `consum_iter' = max(((earning_`sex'*exp(-`v'/ld_ela) + unearned_`sex')*(1-`v1') + other_disp)/4.333,0.01) `condition'

			if $UNEMPLOYMENT == 1 {
				quiet  gen double `U_dummy'= d_in_`sex'*`d_in_`sex'' +  d_un_`sex'*_b[d_un_`sex'] + d_p_`sex'*_b[d_p_`sex'] + d_f_`sex'*_b[d_f_`sex'] + d_o_`sex'*_b[d_o_`sex']  `condition'
			}
			if $UNEMPLOYMENT != 1 {
				quiet  gen double `U_dummy'= d_in_`sex'*`d_in_`sex'' +  d_p_`sex'*_b[d_p_`sex'] + d_f_`sex'*_b[d_f_`sex']+ d_o_`sex'*_b[d_o_`sex']   `condition'
			}						
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


/*

///Generates scalars of reform predictions
capture program drop REFORM
program define REFORM
	set trace off
	version 17
	tempvar grossinc_new_f grossinc_new_m cons_tmp consum_iter U_dummy U_consum U_leis_m U_leis_f nom denom_c denom_m denom_f p_iter tmp_h_m tmp_h_f h_m h_f h_m_temp h_f_temp tmp_E_m tmp_E_f E_m E_f tmp_U_m tmp_U_f U_m U_f tmp_I_m tmp_I_f I_m I_f h_new E_new U_new I_new E_m_temp I_m_temp U_m_temp E_f_temp I_f_temp U_f_temp sum_h_tot_new sum_I_tot_new sum_E_tot_new sum_U_tot_new  select

	tempname v d_in_m d_in_f demand_h_new demand_E_new demand_I_new demand_U_new

	scalar `v' = change[1,1]

	quiet generate `consum_iter' = .
	quiet gen `grossinc_new_f' = .
	quiet gen `grossinc_new_m' = .
	quiet gen `p_iter' = .

    // Loop over HH type
    foreach type in  "couples" "singm" "singf" {
				
				
		if "`type'" == "couples" {
			local sex "m f"
			local condition "if inlist(flex_hh, 1) & flex_m == 1"
	
			replace `grossinc_new_f' = earning_f*exp(`v')  + other_inc `condition'
			replace `grossinc_new_m' = earning_m*exp(`v')  + other_inc `condition' 

			quiet replace grossinc_f  = `grossinc_new_f' `condition'
			quiet replace grossinc_m  = `grossinc_new_m' `condition' 
			
			sum grossinc_f grossinc_m `condition' 
			cap estimates drop taxreg_`type'
			estread using "${path_results}/estimation/${country}_${year}_taxreg_`type'.sters"
			estimates restore taxreg_`type'
			
			predict `cons_tmp' `condition'
			quiet replace `consum_iter' = max(`cons_tmp'/ 4.333, 0.01) `condition' 
			quietly replace consum = max(ils_dispy_p${pyear}_base`hh'/ 4.333 , 0.01) `condition'
			
			sum `cons_tmp' netinc `condition' 
			drop `cons_tmp'
			
			quiet estread using "${path_results}/estimation/${country}_${year}_clogit_`type'_${choices}ch.sters"
			
			estimates restore clogit_`type'_${country}_${year}
			
			scalar `d_in_m'= _b[d_in_m] + `v'
			scalar `d_in_f'= _b[d_in_f]  + `v'

			if $UNEMPLOYMENT == 1 {
				quiet  gen double `U_dummy'= d_in_m*`d_in_m' + d_in_f*`d_in_f'  + d_un_m*_b[d_un_m] + d_un_f*_b[d_un_f]+ d_p_m*_b[d_p_m] + d_p_f*_b[d_p_f]+ d_f_m*_b[d_f_m] +  d_f_f*_b[d_f_f]  `condition'
			}
			if $UNEMPLOYMENT != 1 {
				quiet  gen double `U_dummy'= d_in_m*`d_in_m' + d_in_f*`d_in_f'  + d_p_m*_b[d_p_m] + d_p_f*_b[d_p_f]+ d_f_m*_b[d_f_m] +  d_f_f*_b[d_f_f]  `condition'
			}				
			quiet  gen double `U_consum' = `consum_iter' *(_b[consum] +`consum_iter'*_b[consum_consum] + leis_m*_b[consum_leis_m] + leis_f*_b[consum_leis_f] + hhsize*_b[consum_hhsize]) `condition'
			quiet  gen double `U_leis_m' = leis_m*_b[leis_m] + leis_leis_m*_b[leis_leis_m] + leis_age_m*_b[leis_age_m] + leis_age2_m*_b[leis_age2_m] + leis_numch_m*_b[leis_numch_m] + leis_numch3_m*_b[leis_numch3_m]+ leis_numch36_m*_b[leis_numch36_m] + leis_mortgage_m*_b[leis_mortgage_m] + leis_migrant_m*_b[leis_migrant_m] + leis_m_f*_b[leis_m_f]  `condition'
			
			quiet  gen double `U_leis_f' = leis_f*_b[leis_f] + leis_leis_f*_b[leis_leis_f] + leis_age_f*_b[leis_age_f] + leis_age2_f*_b[leis_age2_f] + leis_numch_f*_b[leis_numch_f] + leis_numch3_f*_b[leis_numch3_f] + leis_numch36_f*_b[leis_numch36_f] + leis_mortgage_f*_b[leis_mortgage_f] + leis_migrant_f*_b[leis_migrant_f] `condition'
			quiet  gen double `nom' = 	exp(`U_dummy' + `U_consum' + `U_leis_m'+ `U_leis_f') `condition'
			bysort idperson: egen double `denom_c'=sum(`nom') `condition'
			quiet  replace `p_iter' = `nom'/`denom_c' `condition' //new probabilities
			drop `U_dummy'
		}
			
		if "`type'" != "couples" {
			
			if "`type'" == "singf" {
				local sex "f"
				local condition "if inlist(flex_hh, 2,4)"
			}
		
			if "`type'" == "singm" {
				local sex "m"
				local condition "if inlist(flex_hh, 3,5)"
			}
		
			cap estimates drop taxreg_`type'
			
			quiet  replace `grossinc_new_`sex'' = earning_`sex'*exp(`v') + other_inc  `condition' 
			quiet replace grossinc_`sex'  = `grossinc_new_`sex'' `condition' 
			estread using "${path_results}/estimation/${country}_${year}_taxreg_`type'.sters"
			estimates restore taxreg_`type'
			predict `cons_tmp' `condition' 
			quiet replace `consum_iter' = max(`cons_tmp'/ 4.333, 0.01) `condition'
			
			drop `cons_tmp'
			quiet estread using "${path_results}/estimation/${country}_${year}_clogit_`type'_${choices}ch.sters"
			estimates restore clogit_`type'_${country}_${year}

			
			//CHANGE OF dummies coeficcients BASED ON PARAMETER V
			scalar `d_in_`sex''= _b[d_in_`sex'] + `v' 
			if $UNEMPLOYMENT == 1 {
				quiet  gen double `U_dummy'= d_in_`sex'*`d_in_`sex'' +  d_un_`sex'*_b[d_un_`sex'] + d_p_`sex'*_b[d_p_`sex'] + d_f_`sex'*_b[d_f_`sex']  `condition'
			}
			if $UNEMPLOYMENT != 1 {
				quiet  gen double `U_dummy'= d_in_`sex'*`d_in_`sex'' +  d_p_`sex'*_b[d_p_`sex'] + d_f_`sex'*_b[d_f_`sex']  `condition'
			}						
			quiet  replace `U_consum' = `consum_iter'*(_b[consum] + `consum_iter'*_b[consum_consum] + leis_`sex'*_b[consum_leis_`sex'] + hhsize *_b[consum_hhsize]) `condition'
									
			quiet  replace `U_leis_`sex'' = leis_`sex'*_b[leis_`sex'] + leis_leis_`sex'*_b[leis_leis_`sex'] + leis_age_`sex'*_b[leis_age_`sex'] + leis_age2_`sex'*_b[leis_age2_`sex'] + leis_numch_`sex'*_b[leis_numch_`sex'] + leis_numch3_`sex'*_b[leis_numch3_`sex']+ leis_numch36_`sex'*_b[leis_numch36_`sex'] + leis_mortgage_`sex'*_b[leis_mortgage_`sex'] + leis_migrant_`sex'*_b[leis_migrant_`sex']  `condition'
			quiet  replace `nom' = 	exp(`U_dummy' + `U_consum' + `U_leis_`sex'') `condition'
			
			bysort idperson: egen double `denom_`sex''=sum(`nom') `condition'
			quiet  replace `p_iter' = `nom'/`denom_`sex'' `condition' //new probabilities
			drop `U_dummy'		
		}	
	}
	
	foreach g in "m" "f"{
		gen `tmp_h_`g'' = `p_iter' * lhw_`g' if lhw_`g'_norand!=5
        bys idperson: egen `h_`g'' = total(`tmp_h_`g'') 
		bys idhh lhw_f_norand lhw_m_norand sec_f sec_m emp_stat_f emp_stat_m: egen `h_`g'_temp' = total(`h_`g'')
		replace `h_`g'' = `h_`g'_temp'
				
		foreach var in "E" "I" "U"{
			quiet  gen `tmp_`var'_`g'' = `p_iter' * d_`var'_`g'
			bys idperson:  egen ``var'_`g'' = total(`tmp_`var'_`g'')
			bys idhh lhw_f_norand lhw_m_norand sec_f sec_m emp_stat_f emp_stat_m: egen ``var'_`g'_temp' = total(``var'_`g'')
			replace ``var'_`g'' = ``var'_`g'_temp'
		}
	}
		
	preserve
	
	local condition "ls == 1"
	keep if `condition' 

	foreach var in "h" "E" "I" "U"{
		quiet gen ``var'_new' = ``var'_f'*dwt if flex_f == 1
		quiet  replace ``var'_new' = ``var'_m'*dwt if flex_m == 1
		total ``var'_new'
		scalar demand_`var'_new = e(b)[1,1]
		di in r "demand_`var'_new"
		scalar list demand_`var'_new
	}

	scalar total_new = demand_E_new+demand_I_new+demand_U_new
	scalar list total_new
	restore 
end


/*
///Finds values of parameters v and u under EQUILIBRIUM conditions
capture program drop EQUILIBRIUM
program define EQUILIBRIUM
	set trace off
	version 17
	tempvar grossinc_new_f grossinc_new_m cons_tmp consum_iter U_dummy U_consum U_leis_m U_leis_f nom denom_c denom_m denom_f p_iter tmp_E_m tmp_E_f E_m E_f tmp_U_m tmp_U_f U_m U_f tmp_I_m tmp_I_f I_m I_f E_m_temp I_m_temp U_m_temp E_f_temp I_f_temp U_f_temp E_new U_new I_new sum_I_tot_new sum_E_tot_new sum_U_tot_new

	tempname v d_in_m d_in_f d_un_m d_un_f supply_E_new supply_I_new supply_U_new demand_E_new yh

	quiet{
		scalar `v' = `1'[1,1]
		*scalar `u' = `1'[1,2]

		quiet generate `consum_iter' = .
		quiet gen `grossinc_new_f' = .
		quiet gen `grossinc_new_m' = .
		quiet gen `p_iter' = .

				
		// Loop over HH type
		foreach type in  "couples" "singm" "singf" {
					
			if "`type'" == "couples" {
				local sex "m f"
				local condition "if inlist(flex_hh, 1) & flex_m == 1"

				replace `grossinc_new_f' = earning_f*exp(-`v'/ld_ela)  + other_inc `condition' 
				replace `grossinc_new_m' = earning_m*exp(-`v'/ld_ela)  + other_inc `condition' 
				
				quiet replace grossinc_f  = `grossinc_new_f' `condition'
				quiet replace grossinc_m  = `grossinc_new_m' `condition' 

				cap estimates drop taxreg_`type'
				estread using "${path_results}/estimation/${country}_${year}_taxreg_`type'.sters"
				estimates restore taxreg_`type'
				
				predict `cons_tmp' `condition'
				quiet replace `consum_iter' = max(`cons_tmp'/ 4.333, 0.01) `condition' 
				drop `cons_tmp'
		
				quiet estread using "${path_results}/estimation/${country}_${year}_clogit_`type'_${choices}ch.sters"
				estimates restore clogit_`type'_${country}_${year}
				
				//CHANGE OF dummies coeficcients BASED ON PARAMETER v
			scalar `d_in_m'= _b[d_in_m] + `v'
			scalar `d_in_f'= _b[d_in_f]  + `v'
				

				if $UNEMPLOYMENT == 1 {
					scalar `d_un_m'= _b[d_un_m] 
					scalar `d_un_f'= _b[d_un_f] 
					quiet  gen double `U_dummy'= d_in_m*`d_in_m' + d_in_f*`d_in_f'+ d_un_m*`d_un_m' + d_un_f*`d_un_m' + d_p_m*_b[d_p_m] + d_p_f*_b[d_p_f] + d_f_m*_b[d_f_m] +  d_f_f*_b[d_f_f]  `condition'
				}		
				if $UNEMPLOYMENT != 1 {
					quiet  gen double `U_dummy'= d_in_m*`d_in_m' + d_in_f*`d_in_f'+ d_p_m*_b[d_p_m] + d_p_f*_b[d_p_f] + d_f_m*_b[d_f_m] +  d_f_f*_b[d_f_f]  `condition'
				}
				quiet  gen double `U_consum' = `consum_iter' *(_b[consum] +`consum_iter' *_b[consum_consum] + leis_m*_b[consum_leis_m] + leis_f*_b[consum_leis_f] + hhsize*_b[consum_hhsize]) `condition'
				quiet  gen double `U_leis_m' = leis_m*_b[leis_m] + leis_leis_m*_b[leis_leis_m] + leis_age_m*_b[leis_age_m] + leis_age2_m*_b[leis_age2_m] + leis_numch_m*_b[leis_numch_m] + leis_numch3_m*_b[leis_numch3_m]+ leis_numch36_m*_b[leis_numch36_m] + leis_mortgage_m*_b[leis_mortgage_m] + leis_migrant_m*_b[leis_migrant_m] + leis_m_f*_b[leis_m_f]  `condition'
				quiet  gen double `U_leis_f' = leis_f*_b[leis_f] + leis_leis_f*_b[leis_leis_f] + leis_age_f*_b[leis_age_f] + leis_age2_f*_b[leis_age2_f] + leis_numch_f*_b[leis_numch_f] + leis_numch3_f*_b[leis_numch3_f] + leis_numch36_f*_b[leis_numch36_f] + leis_mortgage_f*_b[leis_mortgage_f] + leis_migrant_f*_b[leis_migrant_f] `condition'
				quiet  gen double `nom' = 	exp(`U_dummy' + `U_consum' + `U_leis_m'+ `U_leis_f') `condition'
				bysort idperson: egen double `denom_c'=sum(`nom') `condition'
				quiet  replace `p_iter' = `nom'/`denom_c' `condition' //new probabilities
			}
				
			if "`type'" != "couples" {
				
				if "`type'" == "singf" {
					local sex "f"
					local condition "if inlist(flex_hh, 2,4)"
				}
			
				if "`type'" == "singm" {
					local sex "m"
					local condition "if inlist(flex_hh, 3,5)"
				}
			
				cap estimates drop taxreg_`type'
				
				quiet  replace `grossinc_new_`sex'' = earning_`sex'*exp(`v') + other_inc  `condition' 
				quiet replace grossinc_`sex'  = `grossinc_new_`sex'' `condition' 
				
				estread using "${path_results}/estimation/${country}_${year}_taxreg_`type'.sters"
				estimates restore taxreg_`type'
				predict `cons_tmp' `condition' 
				quiet replace `consum_iter' = max(`cons_tmp'/ 4.333, 0.01) `condition'
				
				drop `cons_tmp'
			
				quiet estread using "${path_results}/estimation/${country}_${year}_clogit_`type'_${choices}ch.sters"
				estimates restore clogit_`type'_${country}_${year}

				//CHANGE OF dummies coeficcients BASED ON PARAMETER V and u
				scalar `d_in_`sex''= _b[d_in_`sex'] + `v' 
				if $UNEMPLOYMENT == 1 {
					scalar `d_un_`sex''= _b[d_un_`sex']
					quiet  replace `U_dummy'= d_in_`sex'*`d_in_`sex'' + d_un_`sex'*`d_un_`sex'' + d_p_`sex'*_b[d_p_`sex'] + d_f_`sex'*_b[d_f_`sex']  `condition'
				}				
				if $UNEMPLOYMENT != 1 {
					quiet  replace `U_dummy'= d_in_`sex'*`d_in_`sex'' + d_p_`sex'*_b[d_p_`sex'] + d_f_`sex'*_b[d_f_`sex']  `condition'
				}			
				quiet  replace `U_consum' = `consum_iter'*(_b[consum] + `consum_iter'*_b[consum_consum] + leis_`sex'*_b[consum_leis_`sex'] + hhsize *_b[consum_hhsize]) `condition'
										
				quiet  replace `U_leis_`sex'' = leis_`sex'*_b[leis_`sex'] + leis_leis_`sex'*_b[leis_leis_`sex'] + leis_age_`sex'*_b[leis_age_`sex'] + leis_age2_`sex'*_b[leis_age2_`sex'] + leis_numch_`sex'*_b[leis_numch_`sex'] + leis_numch3_`sex'*_b[leis_numch3_`sex']+ leis_numch36_`sex'*_b[leis_numch36_`sex'] + leis_mortgage_`sex'*_b[leis_mortgage_`sex'] + leis_migrant_`sex'*_b[leis_migrant_`sex']  `condition'
				quiet  replace `nom' = 	exp(`U_dummy' + `U_consum' + `U_leis_`sex'') `condition'
				
				bysort idperson: egen double `denom_`sex''=sum(`nom') `condition'
				quiet  replace `p_iter' = `nom'/`denom_`sex'' `condition' //new probabilities
				*drop `U_dummy'
			}	
		}
			
		local sex "m f"
		foreach g of local sex {
			foreach var in "E" "I" "U"{
				// Create expected vars
				quiet  gen double `tmp_`var'_`g'' = `p_iter' * d_`var'_`g'
				bys idperson:  egen double ``var'_`g'' = total(`tmp_`var'_`g'') 
				bys idhh lhw_f_norand lhw_m_norand sec_f sec_m emp_stat_f emp_stat_m: egen double ``var'_`g'_temp' = total(``var'_`g'')
				replace ``var'_`g'' = ``var'_`g'_temp'
			}
		}
		
		preserve
		keep if ls ==1
		
		foreach var in "E" "I" "U"{
			quiet gen ``var'_new' = ``var'_f'*dwt if flex_f == 1 
			quiet  replace ``var'_new' = ``var'_m'*dwt if flex_m == 1 
			total ``var'_new'
			scalar `supply_`var'_new' = e(b)[1,1]
		}
				
		//calculation of new labour demand - total number of hours
		scalar `demand_E_new' = demand_E_base*(exp(`v'))
		*scalar `demand_E_new' = demand_E_base*(exp(-ld_ela*`v')) 
		scalar `yh'= -((`demand_E_new'-`supply_E_new')^2 )/1E+7
		*scalar `yh'= -(`demand_E_new'-`supply_E_new')^2 - (-demand_U_base+`supply_U_new')^2
	}
	
	scalar `2'=`yh' 
	restore 
end
*/
