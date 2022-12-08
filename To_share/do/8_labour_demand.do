*********************************************************************************
* 8_equilibrium_reform.do
*
* Edlira Narazani - 12-04-2021
* Labor Market equilibrium if Elasticities are finite.
* Labour market equilibrium reached through wages and dummy coefficient
 
* Compute the baseline labour supply as the total number of working hours predicted under the current system. Use this value to construct the baseline labour demand, assuming that the labour market is in equilibrium in the current situation. Similarly, compute the expected number of unemployment slots under the baseline system. 

* Estimate the parameters for tax function (corresponding to the reform) by regressing net household income on a set of explanatory variables. This set of variables includes gross income, gross square income and interactions of gross income with a range of socio-demographic characteristics (age, number of children and household size), as well as alternative specific dummies. The estimated tax parameters are used to convert the new gross income into net income (variable needed as an explanatory variable in the utility function) within the equilibrium algorithm. 

* Run the optimisation procedure  to find the value of the parameters v and u (see Section 3) that correspond to a new labour market equilibrium status under the reform. The new equilibrium is attained when the total number of jobs matches the total number of individuals willing to work. The same equality conditions hold for unemployment, so the available unemployment slots correspond to the expected number of unemployed. The iterated changes in the parameters v and u affect in-work and unemployment dummies’ coefficients (equation 5 and 9), wages (equation 7), total labour demand (equation 6) and unemployment slots (equation 9). 
*********************************************************************************
clear 
set seed 670334520

set trace off

capture log close
log using "${outlog}/equilibrium_${country}_${year}_${choices}ch.log",replace


//read all programs created for the equilibrium
quiet do 8_programs_equilibrium.do

***************************************************************************************************
*** STEP 1- RUN BASELINE MODEL to recover all scalars on demand side under the baseline
*** Table 1: scalar_E_base (C5), scalar_I_base (C6), scalar_U_base (C7)
*** Note, this step comes second to recover scalars of E, I and U under the baseline.
***************************************************************************************************
global counter_ld=0
gen cons = 0

foreach ref in $new_reforms{ 
	use "${path_LSscen}/4_pred/${country}_${year}_${choices}ch_pred_LS.dta", clear 
	gen cons = 0
	keep if flex_hh < 4 & flex == 1
	*gen eq_dispy_p${ryear}_base = ils_dispy_p2021_base/oecd_equiv_scale  //obtain equivalised dpi by merged scale 
	*sumdist eq_dispy_p${ryear}_base [aw= dwt], ng(3) qgp(pct)
	*replace pct = 2 if pct > 2 & pct < 5
	*replace pct = 3 if pct ==5
	
	local baseline_ls = 1
	global counter_ld= $counter_ld + 1
	mat demand_for_xls=J(5,5,.) //auxiliary matrix for excel sheet (table 8.)
	if `baseline_ls' {

		// Tax regression and save estimation results
		foreach s in m f {
			gen grossinc_`s' = .
			gen dispy_`s' = .
			gen earning_`s' = . 
			gen unearned_`s' = .
			replace grossinc_`s' = ils_origy_p${ryear}_base  if flex_`s' == 1
			replace dispy_`s' = ils_dispy_p${ryear}_base  if flex_`s' == 1
			replace earning_`s' = ils_earns_p${ryear}_base if flex_`s' == 1 &  lhw_`s'_norand!=5 &  earning_`s' ==.
			replace earning_`s' = bun_p${ryear}_base if flex_`s' == 1 &  lhw_`s'_norand==5 &  earning_`s' ==.
			replace unearned_`s' = grossinc_`s'  - earning_`s' if flex_`s' == 1
		}

		
		foreach s in m f {
			foreach v in "grossinc" "earning" "dispy" "unearned"{
				bys idhh lhw_f_norand lhw_m_norand sec_f sec_m emp_stat_f emp_stat_m: egen `v'_`s'_temp = total(`v'_`s')
				replace `v'_`s' = `v'_`s'_temp
				drop `v'_`s'_temp
			}
		}

		
		gen other_disp = ils_dispy_p${ryear}_base_hh_other
		gen dispy_flex  = ils_dispy_p${ryear}_base_hh_flex
		
		*replace cons = cons_p${ryear}_base
	
		scalar ld_ela = 0
		mat change = (0,0)
		scalar s1 = 0
		BASELINE
		
		scalar list demand_E_base //cell B4
		scalar list demand_I_base //cell B5
		scalar list demand_U_base // cell B6

		mat demand_for_xls[1,1]=demand_E_base
		mat demand_for_xls[2,1]=demand_I_base
		mat demand_for_xls[3,1]=demand_U_base
		
		scalar demand_E_orig = demand_E_base 
		scalar demand_I_orig = demand_I_base
		scalar demand_U_orig = demand_U_base
	
		drop grossinc_* earning_*  dispy_* unearned* other_disp

	}
		
	////EFFECTS OF THE REFORM - WITHOUT DEMAND SIDE
	local baseline_ls = 0
	if `baseline_ls' == 0 {		
		foreach s in m f {
			gen grossinc_`s' = .
			gen dispy_`s' = .
			gen earning_`s' = . 
			gen unearned_`s' = .
			replace grossinc_`s' = ils_origy_p`ref'  if flex_`s' == 1
			replace dispy_`s' = ils_dispy_p`ref'  if flex_`s' == 1
			replace earning_`s' = ils_earns_p`ref' if flex_`s' == 1 &  lhw_`s'_norand!=5 &  earning_`s' ==.
			replace earning_`s' = bun_p`ref' if flex_`s' == 1 &  lhw_`s'_norand==5 &  earning_`s' ==.
			replace unearned_`s' = grossinc_`s'  - earning_`s' if flex_`s' == 1
		}

		// Tax regression and save estimation results
		foreach s in m f {
			foreach v in "grossinc" "earning" "dispy" "unearned"{
				bys idhh lhw_f_norand lhw_m_norand sec_f sec_m emp_stat_f emp_stat_m: egen `v'_`s'_temp = total(`v'_`s')
				replace `v'_`s' = `v'_`s'_temp
				drop `v'_`s'_temp
			}
		}
		
		gen other_disp = ils_dispy_p`ref'_hh_other
		gen dispy_flex  = ils_dispy_p`ref'_hh_flex
		
		*replace cons = cons_p`ref'
		
		
		scalar ld_ela = ${LD_ELA}
		mat change = (0,0)
		RESULTS

		scalar list demand_E_new //cell C4
		scalar list demand_I_new //cell C5
		scalar list demand_U_new // cell C6

		mat demand_for_xls[1,2]=demand_E_new
		mat demand_for_xls[2,2]=demand_I_new
		mat demand_for_xls[3,2]=demand_U_new

	}

	////EFFECTS OF THE REFORM - WITH DEMAND SIDE

	mat bindexk = (-0.006)

	///RUN AMOEBA ALGORITHM TO FIND THE NEW EQUAILIBRIUM WAGE
	amoeba EQUILIBRIUM bindexk yout bindex . 

	mat change = bindex[1,1]

	RESULTS

	scalar list demand_E_new //cell D4
	scalar list demand_I_new //cell D5
	scalar list demand_U_new // cell D6
	mat list bindex
	scalar v = -(1-exp(-bindex[1,1]/ld_ela))*100 //cell D7
	scalar u = -(1-exp(-bindex[1,2]/ld_ela))*100 //cell D8

	mat demand_for_xls[1,3]=demand_E_new
	mat demand_for_xls[2,3]=demand_I_new
	mat demand_for_xls[3,3]=demand_U_new
	mat demand_for_xls[4,5]=v
	mat demand_for_xls[5,5]=u

	quiet do 8_labour_demand_table "`ref'"
}

//Move Labour demand results to corresponding folder
cap copy "5-Equilibrium.xlsx" "${path_results2share}/${country}_${year}_${choices}ch/5-Equilibrium.xlsx", replace
rm "5-Equilibrium.xlsx"
cap log close