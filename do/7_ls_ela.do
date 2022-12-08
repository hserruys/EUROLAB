*********************************************************************************
* 7_ls_ela.do																	*
*																				*
* 1. Hours prediction using elasticity shock income (1% DPI increase)			*
* 2. Calculates expected hours													*
* 3. Calculate labour supply elasticities (overall and for different subgroups)	*
* Last Update: 15/07/2021 E.N.													*
*********************************************************************************
capture log close
*log using "${outlog}/7_ls_ela_${country}_${year}_${choices}ch.log",replace

use "${path_LSscen}/4_pred/${country}_${year}_${choices}ch_pred_LS.dta", clear 

gen MW_earner = (hourly_wage < hourly_MW & hourly_wage>0)


foreach s in "m" "f" {
	quiet gen in_`s' = d_in_`s' 
	*quiet gen h_`s' = lhw_`s'
}

// Loop over HH type
foreach type in "couples" "singf" "singm" {

    if "`type'" == "singf" {
        local minusg "m"
        local sex "f"
        local hh "_hh"
        local condition "2"

        local condition "if inlist(flex_hh, `condition') & flex_f == 1"
    }
    else if "`type'" == "singm" {
        local minusg "f"
        local sex "m"
        local condition "3"
        local hh "_hh"
        local condition "if inlist(flex_hh, `condition') & flex_m == 1"
    }
    else {
        local minusg ""
        local sex "m f"

        local condition "1"
        local hh "_hh"

        local condition "if inlist(flex_hh, `condition') & flex_m == 1"
    }
    local minusg ""

    local reforms = subinstr("${reforms}","`minusg'","",1)
    local reforms = subinstr("`reforms'","new","",.)
    local reforms_m_f = subinstr("`reforms'","base","",.)

	di in r "`reforms'"

	// Replace code below in all files
    if $BOOTSTRAP == 1 {
        merge_bootstrap_weights

        replace dwt = dwt * wt$bs
        drop wt$bs
    }

    estread using "${path_results}/estimation/${country}_${year}_clogit_`type'_${choices}ch.sters"
	estimates restore clogit_`type'_${country}_${year}

	foreach ref of local reforms {
		cap quiet  gen p_`ref' = 0
		
		capture drop p_p${pyear}_`ref'
		gen p_p${pyear}_`ref' =.
	
		di "`reforms'"
		// Reset consumption for prediction
		if "$country" == "uk"{
			replace consum = max(ils_dispy_p${year}_`ref'`hh' / 4.333, 0.01) `condition'
		}
		else {
			replace consum = max(ils_dispy_p${pyear}_`ref'`hh' / 4.333, 0.01) `condition'
		}
		sum consum `condition'
		foreach var of varlist consum hhsize leis_m leis_f{
			replace consum_`var' = `var'* consum `condition' 
		}
	
		predict p_`ref'_temp `condition'
		bysort idhh lhw_m_norand lhw_f_norand sec_m sec_f emp_stat_m emp_stat_f:  egen p_`ref'_max = max(p_`ref'_temp) `condition'
		quiet  replace p_`ref' = p_`ref'_temp `condition'
		replace p_`ref' = p_`ref'_max if p_`ref' == .
		drop p_`ref'_temp p_`ref'_max 
				
		global var_ls "h in"
		foreach var in $var_ls {
			foreach s in `sex' { 
				bys idhh: 	egen `var'_`s'_`ref'_`type' = total(`var'_`s' * p_`ref')  `condition' 
		
				if "`type'" == "couples" {
					bysort idhh lhw_m_norand lhw_f_norand sec_m sec_f emp_stat_m emp_stat_f:  egen E_`var'_`s'_`ref' = total(`var'_`s'_`ref'_`type')  
				}
				if "`type'" != "couples" {
					replace E_`var'_`s'_`ref' = `var'_`s'_`ref'_`type'   `condition'
				}
			}		
		}

		bys idhh: egen disp_`ref'_`type' = total(p_`ref' * consum) `condition' 

		if "`type'" == "couples" {
				bysort idhh lhw_m_norand lhw_f_norand sec_m sec_f emp_stat_m emp_stat_f:  egen E_c_pred_`ref' = total(disp_`ref'_`type')  
		}
		if "`type'" != "couples" {
				replace E_c_pred_`ref' = disp_`ref'_`type'  `condition'
		}				
	}
}


// Keep only line of choice
keep if ls == 1
drop if selfemployed ==1
save "${path_LSscen}/4_pred/${country}_${year}_${choices}ch_ela_1.dta", replace

use "${path_LSscen}/4_pred/${country}_${year}_${choices}ch_ela_1.dta", clear

foreach var in "h" "in" "c"{
	gen E_`var'_own = .
	gen E_`var'_base = .
	gen E_`var'_cross = .

	local sex "m f"
	foreach g in `sex'{ 
		if "`g'" == "m"  local s = "f" 
		if "`g'" == "f"  local s = "m" 
		if "`var'" == "h"|"`var'" == "in" {
			replace E_`var'_own = E_`var'_`g'_`g' if flex_`g' == 1
			replace E_`var'_base = E_`var'_`g'_base if flex_`g' == 1 
			replace E_`var'_cross = E_`var'_`g'_`s' if flex_`g' == 1 		
		}
		if "`var'" == "c" {
			replace E_`var'_own = E_`var'_pred_`g' if flex_`g' == 1
			replace E_`var'_base = E_`var'_pred_base if flex_`g' == 1 
		}

		*replace net_change = (ils_dispy_p${pyear}_`g' - ils_dispy_p${pyear}_base) / ils_dispy_p${pyear}_base if flex_`g' == 1
	}
}


foreach marg in "tot" "ext" "int" {
	gen ela_`marg'_own = .
	gen ela_`marg'_cross = .
}

local sex "m f"
foreach g of local sex {
	replace ela_tot_own = ((E_h_own / E_h_base) - 1) * 100 if flex_`g' ==1
	replace ela_ext_own = ((E_in_own / E_in_base) - 1) * 100 if flex_`g' ==1
	replace ela_int_own = ela_tot_own - ela_ext_own if flex_`g' ==1 
}
						
local sex "m f"
foreach g of local sex {
	replace ela_tot_cross = ((E_h_cross / E_h_base) - 1) * 100 if flex_`g' ==1
	replace ela_ext_cross = ((E_in_cross / E_in_base) - 1) * 100 if flex_`g' ==1
	replace ela_int_cross = ela_tot_cross - ela_ext_own if flex_`g' ==1 
}

gen eq_dispy_base = E_c_base/oecd_equiv_scale  //obtain equivalised dpi by merged scale 
sumdist eq_dispy_base [aw= dwt], ng(5) qgp(pct)

gen income_group = 1 if  pct == 1 | pct ==2
replace income_group = 2 if pct > 2 & pct<5
replace income_group = 3 if pct == 5

count if migrant ==1
*replace migrant = MW_earner if r(N) < 50 

save "${path_LSscen}/7_aggregate/${country}_${choices}_ela.dta", replace

do 7_ls_ela_tables_b.do
