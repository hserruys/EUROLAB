/// Generates scalars of baseline predictions
capture program drop TAXFUNCTION
program define TAXFUNCTION
	set trace off
	version 17
	tempvar consum_iter U_dummy U_consum U_leis_m U_leis_f denom_c denom_m denom_f p_iter 
	tempvar I_m_couples I_f_couples E_f_couples E_m_couples U_m_couples U_f_couples
	tempvar I_m_singm I_f_singm E_f_singm E_m_singm U_m_singm U_f_singm
	tempvar I_m_singf I_f_singf E_m_singf E_f_singf U_m_singf U_f_singf
	tempvar E_m_temp E_f_temp I_m_temp I_f_temp U_m_temp U_f_temp
	tempvar cons_new cons_couples cons_singm cons_singf 
	tempvar  E_new U_new I_new 
		
	tempname v v0 d_in_m d_in_f demand_h_base demand_E_base demand_I_base demand_U_base consum_new consum_base yh
{
	scalar `v' = change[1,1]
	scalar `v0' = `1'[1,1]

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
			
			replace `consum_iter' = max(((earning_f+earning_m + unearned_m + unearned_f)*exp(`v0'/(1+`v0')) + ils_dispy_p${ryear}_base_hh_other)/4.333,0.01) `condition'
			
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
			
			replace `consum_iter' = max(((earning_`sex' + unearned_`sex')*exp(`v0'/(1+`v0')) + ils_dispy_p${ryear}_base_hh_other)/4.333,0.01) `condition'
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
	scalar `consum_new'=r(mean)
	
	sum cons_base if ls==1 & (inlist(flex_hh, 1) & flex_m == 1) | (inlist(flex_hh, 2)& flex_f == 1)|(inlist(flex_hh, 3)&flex_f == 1)
	scalar `consum_base'=r(mean)
	
	foreach var in "E" "I" "U"{
		replace ``var'_new' = ``var'_new'*dwt if ls == 1
		total ``var'_new' if ls == 1
		scalar demand_`var'_base = e(b)[1,1]
		di in r "demand_`var'_base"
		scalar list demand_`var'_base
	}
		
	scalar total_base = demand_E_base+demand_I_base+demand_U_base
	scalar list total_base

	scalar `yh'= -(`consum_new'-`consum_base')^2
	}
	scalar `2'=`yh'
	scalar list `yh'
end

demand_E_base =   11986868
demand_I_base =  1712603.6
