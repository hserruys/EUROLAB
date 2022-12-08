*********************************************************************************
* 7_predict.do																	*
*																				*
* Takes estimates of ls estimation and predicts expected hours from there		*
* Last Update: 15/07/2021 E.N.													*
********************************************************************************* 
  
capture log close
set more off
set trace off
log using "${outlog}/7_predict_${country}_${year}_${choices}ch.log",replace

use "${path_LSscen}/4_pred/${country}_${year}_${choices}ch_pred_LS.dta", clear 

capture drop *expe*  
svyset psu1 [pw=dwt],strata(strata1)

 
foreach s in "m" "f" {
    quiet gen part_`s' = d_p_`s'
	quiet gen  full_`s' = d_f_`s' 
    quiet gen over_`s' = d_o_`s' 
    quiet gen inwork_`s' = d_in_`s' 
	quiet gen unemp_`s' = d_un_`s' 
	quiet gen inactiv_`s' = d_out_`s'  
	*quiet gen h_`s' = lhw_`s'
}
			
foreach ref in $reform_pred{
	di in r "`ref'"
	cap quiet  gen p_`ref' = 0
	gen  cons_`ref' =.
}


bys idperson: gen n =_n
gen dwt_family = hhsize * dwt
tempname dwt_sum_inflex
sum dwt_family if flex_hh == 0 & n == 1
scalar dwt_sum_inflex = r(sum)
generate dwt_prob = 0
replace dwt_prob = dwt_family if flex_hh == 0

// Loop over HH type
foreach type in "singf" "singm" "couples"  {
	{

		replace consum = 0

		if "`type'" == "singf" {
			*preserve
			local minusg "m"
			local sex "f"
			local condition ""
			local hh "_hh"
			local condition "if inlist(flex_hh, 2) & flex_f == 1"
			local hstring "" 
			
			if $HOURS_DISTRIBUTION == 0 {
				  local hstring = string(lhw_f) /*in case of fixed hours alternatives*/
			}
			
			if $HOURS_DISTRIBUTION == 1 {
				  local hstring = string(choice_hour_f) /*in case of random hours alternatives*/
			}
			
			local max_scale 0.8
			local draw_cols 4
			local simfit_type "Single Women"

		}
		if "`type'" == "singm" {
			*preserve
			local minusg "f"
			local sex "m"
			local condition "" 
			local hh "_hh"
			local condition "if inlist(flex_hh, 3) & flex_m == 1"
			local hstring "" 
			if $HOURS_DISTRIBUTION == 0 {
				 local hstring = string(lhw_m) /*in case of fixed hours alternatives*/
			}
			
			else {
				  local hstring = string(choice_hour_m) /*in case of random hours alternatives*/
			}
			local max_scale 0.8
			local draw_cols 4
			local simfit_type "Single Men"

		}
		if "`type'" == "couples"{
			*preserve
			local minusg ""
			local sex "m f"
			local condition ""
			local hh "_hh"
			local condition "if inlist(flex_hh, 1) & flex_m ==1"
			local hstring ""
			if $HOURS_DISTRIBUTION == 0 {
				  local hstring = "F" + string(lhw_f) + "  " + "M" + string(lhw_m) /*in case of fixed hours alternatives*/
			}
			
			else {
				  local hstring = "F" + string(choice_hour_f) + "  " + "M" + string(choice_hour_m) /*in case of random hours alternatives*/
			}

			local max_scale 0.6
			local draw_cols 3
			local simfit_type "Couples"		
		}
		local minusg ""

		local reforms = subinstr("${reforms}","`minusg'","",1)
		
		di in r "`reforms'"
		local new_ref = subinstr("$reform_pred","p${ryear}_base","",.)
		di in r "`new_ref'"
			
		local hh "_hh"

		estread using "${path_results}/estimation/${country}_${year}_clogit_`type'_${choices}ch.sters"
		estimates restore clogit_`type'_${country}_${year}
			
		//in this loop we 	calculate choice probabilities
		
		foreach ref in $reform_pred{
			di "condition: `condition'"

			// Reset consumption for prediction
			quiet  replace consum = max(ils_dispy_`ref'`hh' / 4.333, 0.01)  `condition'
			
			foreach var of varlist consum hhsize leis_m leis_f{
				quiet  replace consum_`var' = `var'* consum `condition' 
			}
			predict p_`ref'_temp `condition'
			bysort idhh lhw_m_norand lhw_f_norand sec_m sec_f emp_stat_m emp_stat_f:  egen p_`ref'_max = total(p_`ref'_temp) `condition'
			replace p_`ref' = p_`ref'_max `condition'
			drop p_`ref'_max	p_`ref'_temp 	
			

			
			capture drop cons_`type'
			bys idhh: 	egen  cons_`type' = total(consum * p_`ref')  `condition'
			replace cons_`ref' = cons_`type'  `condition'
			drop cons_`type'
		}
		
		//PREDICTED LABOUR SUPPLY
			
		egen N_`type' = count(ls) `condition' & ls ==1
		sum N_`type'
		
		replace dwt_prob = p_p${ryear}_base * dwt * hhsize  `condition'
		*replace dwt_prob = p_p${ryear}_base * dwt `condition'
		sum dwt_prob `condition'

		global var_ls "part full over h inwork unemp inactiv"
		
		foreach ref in $reform_pred {
			foreach s in `sex' { 
				foreach var in $var_ls {
					if "`var'" != "h" {
						bys idhh: 	egen `var'_`s'_`ref'_`type' = total(`var'_`s' * p_`ref')  `condition'
					}
					if "`var'" == "h" {
						bys idhh: 	egen `var'_`s'_`ref'_`type' = total(`var'_`s' * p_`ref')  `condition'
					}
				}			
			}
		}

		// PREDICTED household monetary variable 
		local var_inc "dispy tax sic ben"

		foreach ref in $reform_pred{ 
			foreach var in `var_inc'{ 
				//here i generate the income concept at household level
				bys idhh: egen `var'_`ref'_`type' = total(ils_`var'_`ref'_hh * p_`ref')  `condition'
			}

			gen expend_`ref'_`type' = 12*ben_`ref'_`type'   `condition'
			gen revenue_`ref'_`type' = 12*(tax_`ref'_`type'  +sic_`ref'_`type' ) `condition'
			gen net_expend_`ref'_`type' = revenue_`ref'_`type' - expend_`ref'_`type'   `condition'
			sum net_expend_`ref'_`type' `condition'
		}
				
		foreach ref in `new_ref'{
			foreach var in `var_inc'{ 
				//here i genarate the income concept at household level
				bys idhh: egen `var'_nb_`ref'_`type' = total(ils_`var'_`ref'_hh * p_p${ryear}_base)  `condition'
			}
		
			gen expend_nb_`ref'_`type' = 12*ben_nb_`ref'_`type'   `condition'
			gen revenue_nb_`ref'_`type' = 12*(tax_nb_`ref'_`type'  +sic_nb_`ref'_`type' ) `condition'
			gen net_expend_nb_`ref'_`type' = revenue_nb_`ref'_`type' - expend_nb_`ref'_`type'   `condition'
			sum net_expend_nb_`ref'_`type' `condition'
		}
		
		***************************************************************************************

		*restore
		tempname dwt_sum_`type'
		sum dwt_prob `condition'
		scalar dwt_sum_`type' = r(sum)
		scalar list
	}
	

}


save "${path_LSscen}/4_pred/${country}_${year}_${choices}ch_pred_LD.dta", replace

gen hhtype_ls = (inlist(flex_hh,2,4,6))*"singf" ///
                + (flex_hh==1)*"couples" ///
                + (inlist(flex_hh,3,5,7))*"singm" ///
                + (flex_hh==0)*"inflex" 

gen edstring = "H"*edc_H + "M"*edc_M + "L"*edc_L


scalar summedtypes ///
     = dwt_sum_singf + dwt_sum_couples + dwt_sum_singm + dwt_sum_inflex


foreach type in "singf" "couples" "singm" "inflex" {
    scalar `type'_share = dwt_sum_`type' / summedtypes    
}

foreach s in "L" "M" "H" {
	sum dwt_prob if edc_`s' == 1 & n == 1
	scalar dwt_sum_`s' = r(sum)
	*sum dwt_prob if edc_`s' == 1 & n == 1 & hh_recipient ==1
	*scalar dwt_sum_`s' = r(sum)
}


sum dwt_prob if n == 1
scalar dwt_sum = r(sum)
gen summedbyed = r(sum)

keep if ls == 1 

//the dummy all is to exclude flexible women in couple for not double counting these households in calculation. 
gen exclude = (flex_hh == 1& flex_f==1) 
bys idhh: gen idhh_index = _n
bys idhh:egen flex_hh_i = total(flex_hh)
gen new_sel =  (exclude == 0) | (flex_hh_i ==0 & idhh_index == 1)
//new_sel defines all households
gen all = flex_f ==1|flex_m==1

local sex "m f"
local var_ls = "h inwork unemp inactiv" 
		
local sex "m f"
foreach ref in $reform_pred{
	foreach name in $var_ls{
		quietly gen `name'_`ref' = .
		foreach s in `sex'{ 
			bys idhh: egen `name'_`s'_`ref' = total(`name'_`s'_`ref'_couples)
			drop `name'_`s'_`ref'_couples
			quietly	replace `name'_`ref' = `name'_`s'_`ref' if flex_hh == 1 & flex_`s'==1
			quietly	replace `name'_`ref' = `name'_`s'_`ref'_sing`s' if flex_`s' ==1 & flex_hh!=1 
			drop `name'_`s'_`ref'_sing`s'		
		}
	}			
}
					
local var_inc "dispy tax revenue expend net_expend"
foreach ref in $reform_pred{ 
	foreach var in `var_inc' { 
		quietly  gen `var'_`ref' = .
		quietly  replace  `var'_`ref' =  `var'_`ref'_couples
		drop `var'_`ref'_couples
		replace `var'_`ref' = `var'_`ref'_singm if `var'_`ref' == .  
		drop `var'_`ref'_singm
		replace `var'_`ref' = `var'_`ref'_singf if `var'_`ref' == . 
		drop `var'_`ref'_singf
		svy:total `var'_`ref'  if new_sel==1
		local `var'_`ref' = _b[`var'_`ref']
		di in r "``var'_`ref''"
	}
}
		
foreach ref in  `new_ref'{ 
	foreach var in `var_inc' { 
		quietly  gen `var'_nb_`ref' = .
		quietly  replace  `var'_nb_`ref' =  `var'_nb_`ref'_couples
		drop `var'_nb_`ref'_couples
		replace `var'_nb_`ref' = `var'_nb_`ref'_singm if `var'_nb_`ref' == .  
		drop `var'_nb_`ref'_singm
		replace `var'_nb_`ref' = `var'_nb_`ref'_singf if `var'_nb_`ref' == . 
		drop `var'_nb_`ref'_singf
		svy:total `var'_nb_`ref'  if new_sel==1
		local `var'_nb_`ref' = _b[`var'_nb_`ref']
		di in r "``var'_nb_`ref''"
	}
}


*------ Generate table 7_predict_template --------------------------------------
local filename="${path_results2share}/${country}_${year}_${choices}ch/3-Behavioral_effect_new_reform.xlsx"
copy "7_predict_template.xlsx" "`filename'", replace

*- Table 1: Total Revenue and Expenditures with behavioural and non behavioural labour supply responses		
//HHtype: Total, Couples (1), Single Women (2), Single men (3), Sole parents (23)	
gen main_hh =0
replace main_hh = 1 if hhtype ==11|hhtype ==12
replace main_hh = 2 if hhtype ==21|hhtype ==22
replace main_hh = 3 if hhtype ==31|hhtype ==32
replace main_hh = 4 if hhtype == 21|hhtype == 31

*- Define initial column and row to write results in excel sheet
local col_i=3				
local row_i=6				//To write values
local row_0=`row_i' - 2		//To write labels
local ref_col=1


*- Calculations and Results Table 1
putexcel set "`filename'", modify sheet("Tax and Transfers")
foreach ref in $reform_pred{ 

	*- Calculate total
	local var_inc "revenue expend net_expend"
	local counter=1
	mat M_total_`ref'=J(3,1,.)
	foreach var in `var_inc'{
		foreach type in "1" "2" "3" "4"{
			svy:total `var'_`ref'  if new_sel==1 & main_hh ==`type'
			scalar `var'_`ref'_`type' = _b[`var'_`ref']
			scalar list `var'_`ref'_`type'
			
			if `counter'==1{
				mat M_`ref'_`type'= `var'_`ref'_`type'
			}
			else{
				mat aux= `var'_`ref'_`type'
				mat M_`ref'_`type'=(M_`ref'_`type'\aux)
			}
		}
			
		svy:total `var'_`ref'  if new_sel==1 
		scalar `var'_`ref' = _b[`var'_`ref']
		local `var'_`ref' = _b[`var'_`ref']
		scalar list `var'_`ref'
		di in r "`var'_`ref'"
		mat M_total_`ref'[`counter',1]=`var'_`ref'
		local ++counter
	}
	
	mat M_`ref'=(M_total_`ref'\J(2,1,.)\M_`ref'_1\J(2,1,.)\M_`ref'_3\J(2,1,.)\M_`ref'_2\J(2,1,.)\M_`ref'_4)
	
	*- Write values in excel sheet 
	if regexm("`ref'","base") {
		local baseline_name="`ref'"
		local col_f=char(64 + `col_i')
		mat M_base=M_`ref'
		
		*- Write Abs. value and % Change
		putexcel `col_f'`row_i' = matrix(M_`ref')
		putexcel `col_f'`row_0' = "Baseline"
	}
	else{
		local ref_col=`ref_col' + 3
		local col_f=char(64 + `ref_col')
		mat M_diff=(M_`ref' - M_base)	//Absolute difference
		
		mat M_diff_percent=J(23,1,.)
		forvalues i = 1/23 {
			mat M_diff_percent[`i',1] = M_diff[`i',1]/M_base[`i',1] //% Difference
		}
		mat M_full=(M_`ref',M_diff_percent)

		*- Write Abs. value and % Change
		local ref_name="Reform " + substr("`ref'",7,strlen("`ref'")-6)
		di "ref_name= `ref_name'"
		quiet putexcel `col_f'`row_i' = matrix(M_full)
		quiet putexcel `col_f'`row_0' = "`ref_name'"
		local col_aux = char(64 + `ref_col' + 1)
		quiet putexcel `col_aux'`row_0' = "% Change after `ref_name'"
		quiet putexcel (`col_f'`row_0':`col_aux'`row_0'), border(bottom,double)
		quiet putexcel (`col_f'`row_0':`col_aux'`row_0'), border(top,thin)
		quiet putexcel (`col_f'29:`col_aux'29), border(bottom,thin)
	}
}

*- Table 2: Welfare and Efficiency Indicators 	
//Social Welfare	
//Gini index	
//Marginal Cost of Public Funds	 - MCPF
//Winners	

*- Calculations and Results Table 2
putexcel set "`filename'", modify sheet("Indicators")
local ref_col=`col_i'
foreach ref in $reform_pred{ 
	mat M_`ref'=J(4,1,.)
	gen eq_dispy_`ref' = dispy_`ref'/oecd_equiv_scale  //obtain equivalised dpi by merged scale 
	
	sum eq_dispy_`ref' [aw = dwt]
	scalar eq_dispy_m_`ref' = r(mean)
	
	ainequal eq_dispy_`ref'  [aw = dwt] if new_sel==1 , all
	scalar gini_`ref' = real(r(gini_1))  //Gini index
	scalar soc_`ref' = eq_dispy_m_`ref'*(1-gini_`ref') //Social Welfare
	*replace eq_dispy_base = eq_dispy_p${ryear}_base 
	gen double Win_dispy_`ref' = (eq_dispy_`ref' > eq_dispy_p${ryear}_base + 1) //Winners
	svy:mean Win_dispy_`ref'  if new_sel==1 
	matselrc r(table) aux,row(1)
	
	mat M_`ref'[1,1] = soc_`ref'
	mat M_`ref'[2,1] = gini_`ref'
	mat M_`ref'[4,1] = aux[1,1]
	
	if regexm("`ref'","base"){
		local col_f=char(64 + `col_i')
		mat M_base=M_`ref'
		
		*- Write Abs. value and % Change
		putexcel `col_f'`row_i' = matrix(M_`ref')
		putexcel `col_f'`row_0' = "Baseline"
	}
	else {
		scalar MCPF = 1 - (`net_expend_`ref''  -  `net_expend_`baseline_name'')/(`net_expend_nb_`ref''  -  `net_expend_`baseline_name'')
		scalar list MCPF
		mat M_`ref'[3,1] = MCPF

		local ++ref_col
		local col_f=char(64 + `ref_col')

		*- Write values
		local ref_name="Reform " + substr("`ref'",7,strlen("`ref'")-6)
		quiet putexcel `col_f'`row_i' = matrix(M_`ref')
		quiet putexcel `col_f'`row_0' = "`ref_name'"
		quiet putexcel (`col_f'`row_0':`col_f'`row_0'), border(bottom,double)
		quiet putexcel (`col_f'`row_0':`col_f'`row_0'), border(top,thin)
		quiet putexcel (`col_f'10:`col_f'10), border(bottom,thin)
	}
}


*- Calculations and results for Tables 3, 3.1, 3.2 and 4

//Table 3 : Labour supply changes at intensive and extensive margin
//Table 3.1 : Labour supply changes at intensive and extensive margin, employees
//Table 3.2 : Labour supply changes at intensive and extensive margin, selfemployed
//Table 4 : Labour supply changes at intensive and extensive margin, by decile

gen hh_f = 0
replace hh_f = 1 if hhtype ==11 & flex_f ==1 
replace hh_f = 2 if hhtype ==12 & flex_f ==1 
replace hh_f = 3 if hhtype ==21 & flex_f ==1 
replace hh_f = 4 if hhtype ==22 & flex_f ==1 

gen hh_m = 0
replace hh_m = 1 if hhtype ==11 & flex_m ==1 
replace hh_m = 2 if hhtype ==12 & flex_m ==1
replace hh_m = 3 if hhtype ==31 & flex_m ==1
replace hh_m = 4 if hhtype ==32 & flex_m ==1

local sex "m f"
sumdist eq_dispy_p${ryear}_base [aw= dwt], ng(5) qgp(pct)


if $EmplStatus == 1{
	local work_status "all employee byquintile"
	local sheet_name1="Labour supply"
	local sheet_name2="Labour supply - employee"
	local sheet_name3="Labour supply - income quintile"
}
if $EmplStatus == 2{
	local work_status "all employee selfemployed  byquintile"
	local sheet_name1="Labour supply"
	local sheet_name2="Labour supply - employee"
	local sheet_name3="Labour supply - selfemployed"
	local sheet_name4="Labour supply - income quintile"
}
local sheetnum=1


foreach status in `work_status'{
*set trace on
	di in r "*********`status'*************************"

	putexcel set "`filename'", modify sheet("`sheet_name`sheetnum''")
	local ++sheetnum
	local ref_col=1
	
	local counter_ref=1
	foreach ref in $reform_pred{ 
		
		
		if "`status'" == "byquintile"{
			local var_inc = "h inwork" 
		}
		else{
			local var_inc = "h inwork unemp inactiv" 
		}
		
		local first_inc=1
		foreach var in `var_inc'{
			local counter=1
			
			di in r "`var'"
			foreach s in `sex'{ 
				
				di in r "`counter_ref'"
				if `counter_ref'==1 & "`status'" != "byquintile"{
					capture confirm variable insobs_`s',exact
					if !_rc {
						di in r "inobs exists"
							quiet replace `var'_`ref' = 0 if insobs_`s' != .
							
				   }
					else{
						forvalues i =1/4 {
							sum hh_`s' if hh_`s'==`i' & `status'==1
							if r(N) == 0 {
								quiet insobs 1, after(_N) 
								quiet gen insobs_`s' = `i' if idhh == .
								quiet replace hh_`s' = insobs_`s' if insobs_`s' != . 
								
								quiet replace `status' = 1 if insobs_`s' != . 
								replace strata1 = 1 if insobs_`s' != .
								replace psu1 = 1 if insobs_`s' != .
								replace dwt = 1 if insobs_`s' != .
								quiet replace `var'_`ref' = 0 if insobs_`s' != .
						
							}
						}
					}
				}
				if `counter_ref'!=1 & "`status'" != "byquintile"{
					capture confirm variable insobs_`s',exact
					if !_rc {
						di in r "inobs exists"
							quiet replace `var'_`ref' = 0 if insobs_`s' != .
							
					}
					else {
						display "insobs does not exist"
					}

				}
			
				if "`status'"=="all"{
					svy: mean `var'_`ref',over(hh_`s') subpop(if hh_`s'>0)
				} 
				else if "`status'"=="byquintile"{
					svy:mean `var'_`ref' if flex_`s' ==1 , over(pct)
				}
				else{
					svy:mean `var'_`ref',over(hh_`s') subpop(if hh_`s'>0 & `status'==1)
					
				}
				matrix `var'_`ref'_hh = e(b)
				matrix `var'_`ref'_hh = `var'_`ref'_hh'
			
				if `counter'==1{				    
					mat M_`var'_`ref'= `var'_`ref'_hh
										
					if "`status'"=="all"{
					    
					    * Total by gender 1
						svy:mean `var'_`ref' if flex_`s' ==1
						scalar `var'_`ref' = _b[`var'_`ref']
						mat M_`var'_`ref'=(M_`var'_`ref' \ `var'_`ref')
					}
				}
				else{
					
					if "`status'"=="all"{
					    mat M_`var'_`ref'=(M_`var'_`ref' \ `var'_`ref'_hh)
						
						* Total by gender 2
						svy:mean `var'_`ref' if flex_`s' ==1
						scalar `var'_`ref' = _b[`var'_`ref']
						mat M_`var'_`ref'=(M_`var'_`ref' \ `var'_`ref')
						
						* Total all (whole population)
						svy:mean `var'_`ref'
						scalar `var'_`ref' = _b[`var'_`ref']
						mat M_`var'_`ref'=(M_`var'_`ref' \ `var'_`ref')
					}
					else{
						mat M_`var'_`ref'=(M_`var'_`ref' \ J(1,1,.) \ `var'_`ref'_hh)
					}
				}
				local ++counter
				
				if "`status'"=="all"{
					svy:mean `var'_`ref' if new_sel==1
				}
				else if "`status'"=="byquintile"{
					svy:mean `var'_`ref' if flex_`s' ==1 
					scalar `var'_`ref' = _b[`var'_`ref']
				}
				else{
					svy:mean `var'_`ref' if new_sel==1 & `status' ==1
				}
				matrix `var'_`ref' = _b[`var'_`ref']
			}
			
			*- Build matrix
			local aux_row=rowsof(`var'_`ref'_hh)
			if `first_inc'==1{
				mat M_`ref' = M_`var'_`ref'
				if "`status'"=="all"{
					matrix Matrix_lines=(`row_i' + `aux_row', `row_i' + 2* `aux_row' + 1, `row_i' + 2* `aux_row' + 2)
				}
			}
			else{
			    if "`status'"=="all"{
				    local row_aux=Matrix_lines[1,(`first_inc'-1)*3]+2
					matrix Matrix_lines=(Matrix_lines, `row_aux' + `aux_row', `row_aux' + 2* `aux_row' + 1, `row_aux' + 2* `aux_row' + 2)
				    mat M_`ref' = (M_`ref' \ J(1,1,.) \ M_`var'_`ref')
				}
				else{
				    mat M_`ref' = (M_`ref' \ J(2,1,.) \ M_`var'_`ref')
				}
			}
			local ++first_inc
		}

		//mat list M_`ref'
		
		*- Write matrix in excel sheet 
		
		local value_m=rowsof(M_`ref') //Number of rows to create difference matrix 
		
		//Row number to draw bottom line in table
		if "`status'"=="byquintile" | "`status'"=="all"{
			local value_n=`value_m' + 5	
		}
		else{
		    local value_n=`value_m' + 6	
		}
		
		if regexm("`ref'","base") {
			local baseline_name="`ref'"
			local col_f=char(64 + `col_i' + 1)
			mat M_base=M_`ref'
			
			*- Write Abs. value and % Change
			putexcel `col_f'`row_i' = matrix(M_`ref')
			putexcel `col_f'`row_0' = "Baseline"
		}
		else{
			local ref_col=`ref_col' + 3
			local col_f=char(64 + `ref_col' + 1)
			mat M_diff=(M_`ref' - M_base)	//Absolute difference
			mat M_diff_percent=J(`value_m',1,.)
			mat M_missing=J(`value_m',1,0)
			
			forvalues i = 1/`value_m' {
				mat M_diff_percent[`i',1] = M_diff[`i',1]/M_base[`i',1] //% Difference
				if M_base[`i',1]==0{
					mat M_missing[`i',1] = 1
				}
			}
			mat M_full=(M_`ref',M_diff_percent)

			*- Write Abs. value and % Change
			quiet putexcel `col_f'`row_i' = matrix(M_full)
			
			*- Format table
			local ref_name="Reform " + substr("`ref'",7,strlen("`ref'")-6)
			quiet putexcel `col_f'`row_0' = "`ref_name'"
			local col_aux=char(64 + `ref_col' + 2)
			quiet putexcel `col_aux'`row_0' = "% Change after `ref_name'"
			quiet putexcel (`col_f'`row_0':`col_aux'`row_0'), border(bottom,double)
			quiet putexcel (`col_f'`row_0':`col_aux'`row_0'), border(top,thin)
			quiet putexcel (`col_f'`value_n':`col_aux'`value_n'), border(bottom,thin)
			
			if "`status'"=="all"{
			    local aux_row=colsof(Matrix_lines)
				forvalues i = 1/`aux_row'{
				    local row_aux=Matrix_lines[1,`i']
				    quiet putexcel (`col_f'`row_aux':`col_aux'`row_aux'), border(bottom,thin)
				}
			}
			
			*- Set missing values to n/a
			forvalues i = 1/`value_m' {
				if M_missing[`i',1] == 1{
					local row_f = `row_i' + (`i'-1)
					quiet putexcel `col_aux'`row_f' = "n/a"
				}
			}
		}
		local ++counter_ref
	}
}

log close

* End of 7_predict.do file
