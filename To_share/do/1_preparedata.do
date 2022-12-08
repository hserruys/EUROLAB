*****************************************************************************************
* 1_preparedata.do																		*
*																						*
* 1. Reads baseline data																*
* 2. Selects the LS flexible unit 														*
* 3. Performs imputaion of wage rates													*
* 4. Simulates counterfactual choices (hours, sectors, employment status and incomes)	*
* Last update 11-03-21 E.N. and B.P. 													*
*****************************************************************************************
set trace off
set seed 670334520
capture log close
global allvars ""
global shockincs ""

capture log close wage_estim
log using "${outlog}/1_preparedata_${country}_${year}_${choices}ch.log",replace
*******************************************************************
***************** INPUT DATA MERGED WITH OUTPUT DATA **************
*******************************************************************
di in r "1_preparedata started running: $S_TIME  $S_DATE"
if $INPUT_DATA == 1{
	quiet insheet using "${path_EMoutput}/${country}_${pyear}_std.txt", tab names clear double

	sum idhh
	tempfile udb
	save `udb'
	quiet insheet using "${path_EMinput}/original/${country}_${year}_${fil}.txt", clear
	sum idhh
	noisily cap unab allvars: _all
	global allvars "`allvars'" 
	merge 1:1 idper using `udb'
	drop _merge
}

*********************************************************************************
***************** SILC DATA MERGED WITH INPUT DATA AND OUTPUT DATA **************
*********************************************************************************
if $INPUT_DATA == 0{

	local name = "2021-11" 
				
	use "${path_SILC_data}\\${country}\\${year}\\${country}-SILC-${year}-version_`name'.dta",clear

		if "${country}" == "at" {

				gen double idperson_o = idperson
				local var_merge  "idperson_o"

			}
			else if "${country}" == "cz" {
			    
				format idperson %12.0f
				rename idperson idorigperson
				local var_merge "idorigperson"
				
			}
			else if "${country}" == "sk" {
			    
				gen double r_rb030 = idperson
				drop rb030
				noi merge 1:1 r_rb030 using "${path_EMinput}/C19_R_HIDMAP_JRC_SK"
				replace idperson = rb030
				format idperson %12.0f
				rename r_rb030 idorigperson 
				local var_merge "idperson"
				
			}
			else if "${country}" == "it" {
				
				di in r "here i am"
			    local name = "2020-11"
		use "${path_SILC_data}\\${country}\\${year}\\${country}-SILC-${year}-version_`name'.dta",clear

				local var_merge "idperson"
				
			}
			else {

				rename idperson idorigperson
				local var_merge "idorigperson"
				
			}
			
			
			
	local var_silc "rb031 rb230 pl060 pl100 pl073 py200g pl075 pl074 pl076 pl080 pl040 pl020 pl085 pl087 pl086 pl090 pl089 pl120 pb210 pb220* pl031 rb210"
			local var_adhoc "pt060* pt070* pt090* pt100*"
			capture keep idhh idperson `var_merge' `var_silc' `var_adhoc'
	tempfile udb
	*sort idhh idperson
	save `udb'
	
	quiet insheet using "${path_EMinput}/original/${country}_${year}_${fil}.txt", clear
	
	format idperson %12.0f

	di in r "Merging key variable is `var_merge'"
	
	noisily cap unab allvars: _all
	global allvars "`allvars'" 
	sort idhh idperson
	merge 1:1 `var_merge' using `udb'

	
	sum idhh if _merge == 1
	if r(N) > 0{
		di in r "wrong version"
		if "${country}" == "be"{
			keep if _merge ==3
		}
		else{
			continue,break
		}
	}
	else if r(N) == 0{
		di in r "The right UDB version for merging with inpu data is `name'"
		drop if _merge ==2
		drop _merge
	}
	
	if "${country}" == "cz"{
		rename idperson idperson_1
		rename idorigperson idperson 
		rename idperson_1 idorigperson
		format idperson %12.0f 
	}
	capture drop if _merge == 2
	capture drop _merge
	
capture gen dcb = 1 if pb210 == "LOC" 
replace dcb = 2 if pb210 == "EU" 
replace dcb = 3 if pb210 == "OTH" 

count if !(dcb >= 1 & dcb <= 3) 
display in y "No of observations with missing or invalid citizenship (dcz): " r(N) 
if r(N) > 0 noi display in r "MUST BE IMPUTED!"

tab dcb, m

* Missing values can be replaced by the citizenship of the mother

bysort idhh: egen temp_mode_dcb = mode(dcb), minmode
replace dcb = temp_mode_dcb if dcb == .

* Missing values are considered citizen of country of residence
replace dcb = 1 if dcb == .

if ${year} == 2019 {
	
* new country of birth
gen cob = pb210
replace cob = pt070 if pt070 != ustrupper("${country}")  
replace cob = ustrupper("${country}") if dcb == 1 
*replace dcb = 1 if dcb == .
replace cob =pb210  if missing(cob)
}

gen bornEU_ctz = dcz==1 & dcb ==2
gen bornnonEU_ctz = dcz==1 & dcb ==3
gen migrant_EU = dcz!=1 & dcb ==2
gen migrant_nonEU = dcz!=1 & dcb ==3



capture gen dyyrs = ${year} - rb031
replace dyyrs = 80 if missing(dyyrs)
replace dyyrs = 0 if dyyrs<0
}


save "${path_LSscen}/0_fullsample/${country}_${year}_${choices}ch_udb_input.dta" , replace
if ${year} < 2019 {
	
	use "${EM_dofiles}///sample_design.dta",clear
	if "${country}" == "lu"{
		keep if lower(country)=="$country" & year == 2016
	}
	if "${country}" == "uk"{
		keep if lower(country)=="$country" & year == 2015
	}
	if "${country}" != "uk" & "${country}" != "lu"{
		keep if lower(country)=="$country" & year == $year
	}
	
	tempfile sampling_design_$country
	save `sampling_design_$country', replace
	
	//Merge dataset with sampling design					
	use "${path_LSscen}/0_fullsample/${country}_${year}_${choices}ch_udb_input.dta" , clear
	*quiet insheet using "${path_EMinput}/original/${country}_${year}_${fil}.txt", clear
	sum idhh
	di "sampling_design `sampling_design_$country'"
	merge m:1  idhh using `sampling_design_$country'
	
	if country=="LU" & year==2016{
		assert _merge==3 | _merge==2
		if `r(N)'==190{		//Number of HH corresponding to International civil servants
			keep if _merge==3
			tab _merge
		}
		else{
			window stopbox stop "Number of HH corresponding to International civil servants is different than expected"
		}
	}
	else{
		keep if _merge==3
		tab _merge
		drop _merge
	}

****** Declare survey design for dataset (svyset) *********
*svyset psu1 [pw=dwt],strata(strata1)
}

if ${year} > 2018 {
	quiet insheet using "${path_EMinput}/original/${country}_${year}_${fil}.txt", clear
	capture keep idper dsr dsu01
	capture gen dsr=1
	tempfile sampling_design_$country
	save `sampling_design_$country', replace
	//Merge dataset with sampling design					
	use "${path_LSscen}/0_fullsample/${country}_${year}_${choices}ch_udb_input.dta" , clear
	
	merge m:1  idper using `sampling_design_$country'
	gen psu1 = dsu01
	gen strata1 = dsr 
	*svyset dsu01 [pw=dwt],strata(dsr)
	drop _merge

}


//variables from SILC data//

rename pl060 hrsmain // current period
rename pl100 hrssec // current period
egen monthft = rowtotal(pl073 pl075)
egen monthpt = rowtotal(pl074 pl076)
rename pl080 monthun // in income reference period
qui recode hrsmain hrssec monthft monthpt monthun  (.=0) 

*------------------------------------------------------------
* matrices and scalars
*------------------------------------------------------------
cap rename lhw_f lhw_flag

tempname pop
tempname emp
tempname ina
tempname npart
tempname popmat

sum dwt
scalar `pop' = r(sum)

sum dwt if inlist(les, 1, 2, 3, 5)
scalar `emp' = r(sum)

sum dwt if inlist(les, 7)
scalar `ina' = r(sum)

sum dwt if !(inlist(les,0,1,2,3,4,5,6,7,8))
scalar `npart' = r(sum)

mat popmat_temp = (`pop', `emp', `ina', `npart')
mat rownames popmat_temp = "${country}"
mat colnames popmat_temp = "pop" "emp" "ina" "npart"

mat npop_$country = `pop'
matsave npop_$country, saving path("${path_results}/population/") replace

foreach px in "pop" "emp" "ina" "npart" {
	tempname n`px'_file
		file open `n`px'_file' using "${path_results}/population/scalars/n`px'_$country", write text replace
	file write `n`px'_file' "`=``px'''" _n
	file close `n`px'_file'  
}

if $conpos == 1 {
	mat popmat = popmat_temp
	matsave popmat, saving path("${path_results}/population/") replace
}
else {
	matload popmat, overwrite saving path("${path_results}/population/")
	mat popmat = popmat \ popmat_temp
	matsave popmat, saving path("${path_results}/population/") replace
}


quiet sort   idperson
qui replace dag = 0 if dag < 0

noisily cap unab bunvars_log: bun* bsa*
noisily cap unab yvars_log: yem* yse*
noisily cap unab pvars_log: poa* pdi* ps* bsu* boa*
noisily cap unab capvars_log: yi* yp* yo*
	 

*------------------------------------------------------------
* get income variables
*------------------------------------------------------------
				 
// get country and year specific income variables
get_income_variables

foreach nam1 in $yem_vars $yse_vars $capital_vars $pdi_vars $bhl_vars $bun_vars $bsa_vars $psu_vars $pen_vars $bma_vars{
	foreach nam2 in `nam1'{
		capture gen `nam2' = 0
	}
}

// disability income
quiet egen pdi_all = rowtotal($pdi_vars)  
// sickness and maternity benefit
quiet egen bhl_all = rowtotal($bhl_vars)  
// Employment income
quiet egen y_yem = rowtotal($yem_vars)
// Self-employment income
quiet egen y_yse = rowtotal($yse_vars)
// Unemployment benefits
quiet egen bun_all = rowtotal($bun_vars) 
// Social Assistance benefits
quiet egen bsa_all = rowtotal($bsa_vars) 
// Pensions
quiet egen poa_all = rowtotal($pen_vars)
// Pensions
quiet egen psu_all = rowtotal($psu_vars)
// Pensions
quiet gen pen = psu_all + poa_all + pdi_all + bhl_all 
// maternity income
quiet egen bma_all = rowtotal($bma_vars)  

*quiet bys idhh: gen hhsize = _N
// Capital
quiet egen capital = rowtotal($capital_vars)  



*------------------------------------------------------------
* Earning variables
*------------------------------------------------------------
foreach var of varlist $yse_vars {
	replace `var' = 0 if `var'<0
}
replace yse = 0 if yse < 0
		
// All employment and selfemployment income
quiet egen y = rowtotal($income_vars) 

// Economic Status
quiet generate employee     = 0
quiet generate selfemployed = 0
quiet generate unemployed   = 0
quiet generate retired      = 0
quiet generate student      = 0
quiet generate inactive     = 0
quiet generate disable      = 0
quiet generate benefiter   = 0
quiet generate sick   = 0
quiet generate pensioner      = 0
quiet gen military = 0
quiet gen carer = 0
gen solo_self = 0
gen other = 0
gen unemployed_ben = 0
gen unmatched = 0

// mean (positive) labor income in the population
quiet egen lab   = mean(y) if y > 0
quiet egen labym = mean(lab) 



/*capture sum py200g 
	if r(N) > 0{
	gen emp_income = py200g
	replace emp_income = yem if emp_income ==.
	}
	else{
	gen emp_income = y_yem
	}
*/	
gen emp_income = y_yem
gen selfemp_income = y_yse	

		
if "${country}" == "it"{
	replace yseev = 0 if yseev < 0 
	*replace yseev = 0 if bma_all>0
	*replace ysenr = 0 if bma_all>0
	gen evas = ysenr / yse
	gen precar_income = yemtj
	gen earns = emp_income + precar_income + selfemp_income 			
	gen earnstype = 0 if earns == 0 // to identify employee or self-employed for later assignment of yem or yse
	replace earnstype = 1 if emp_income >= selfemp_income & emp_income >= precar_income & earns > 0 //"employed"
	replace earnstype = 2 if selfemp_income > emp_income & selfemp_income >= precar_income & earns > 0 //"self employed"
	replace earnstype = 3 if precar_income > emp_income & precar_income > selfemp_income & earns > 0 //"self employed"
}
else {
	gen earns = emp_income + selfemp_income  
	gen earnstype = 0 if earns == 0 // to identify employee or self-employed for later assignment of yem or yse
	replace earnstype = 1 if emp_income >= selfemp_income & earns > 0 //"employed"
	replace earnstype = 2 if selfemp_income > emp_income & earns > 0 //"self employed"
}


*-----------------------------------------------
* Definition of flexible units per household
*-----------------------------------------------
*Age Interval
gen agemain = (dag >= $MIN_AGE & dag <=$MAX_AGE) 
gen couple = (idpartner > 0)	

tempfile partner
save  `partner'
keep idpartner agemain pen
rename idpartner idperson
rename agemain agepartner
rename pen penpartner
merge idperson using `partner', sort uniqusing
drop if _merge == 1
drop _m

lab def couplelab 0 "No" 1 "Yes"
lab val couple couplelab 

lab def agelab 0 "Not in working age" 1 "Working age"
*lab val dag agelab 

noi tab dag couple

// presence of dependent individuals by HH
gen  old70 = (dag >= 70 | retired + disable > 0) & (yem + yse) < labym / 10
quiet bys idhh: egen pold = max(old70)
quiet bys idhh: egen nold = sum(old)

preserve
import excel "SMW.xlsx", firstrow clear
keep if co=="$country" 
local SMW = SMW2019[1]
di "`SMW'"
restore

// Coverting variables to monthly values
gen monthly_MW = `SMW' 
gen hourly_MW = `SMW'/(40*4.34) 
	
*************************************************************************
*********************** timing of LS- survey week versus income year ****
*************************************************************************
replace yemmy =  pl073 + pl074
replace ysemy =  pl075 + pl076	
replace yemmy = 0 if yemmy == . 
replace ysemy = 0 if ysemy == . 

gen yem_new = (y_yem *12) / yemmy
replace yem_new = 0 if yem_new ==.
gen yse_new = (y_yse *12) / ysemy
replace yse_new = 0 if yse_new ==.

*-----------------------------------------------------------------------
* Hours worked, earnings and computaion of hourly wage
*-----------------------------------------------------------------------
/*PL073: Number of months spent at full-time work as employee 
	PL074: Number of months spent at part-time work as employee 
	PL075: Number of months spent at full-time work as self-employed (including family worker) 
	PL076: Number of months spent at part-time work as self-employed (including family worker) */
gen month_ft_2 = pl073
gen month_ft_3 = pl075
gen month_pt_2 = pl074
gen month_pt_3 = pl076

gen dgn_m = (dgn == 1)
gen dgn_f = (dgn == 0)

gen hours = hrsmain + hrssec
gen totmonthsFTPT = monthft + monthpt
gen unstable = (monthft>0) & (monthpt >0)

//Adjustment of hours
gen adjusted_hours = hours

foreach stat in 2 3{
	foreach s in m f{ 
		di in r "LS = `stat' and gender = `s'"
		sum hours if month_ft_`stat' == 12 & dag >= $MIN_AGE & dag <=$MAX_AGE & dgn_`s' == 1 & les == `stat'
		local ft_`stat'_`s' = r(mean)
		replace adjusted_hours = `ft_`stat'_`s'' if hours <30 & monthft>0 & monthft > monthpt & dgn_`s' == 1 & dag >= $MIN_AGE & dag <=$MAX_AGE & unstable ==0 & les == `stat'

		sum hours if month_pt_`stat' == 12 &  les == `stat' & dgn_`s' == 1
		local pt_`stat'_`s' = r(mean)
		replace adjusted_hours = `pt_`stat'_`s'' if hours >31 & monthpt>0 & monthft < monthpt & dgn_`s' == 1 & les == `stat' & unstable ==0

		*replace adjusted_hours = round(((`ft_`stat'_`s''*monthft + `pt_`stat'_`s''*monthpt)/12),1)  if unstable == 1
		
	}
}


if $FLEX_SELECT == 1 {
	//labour status based on les variable
	
	replace retired      = 1 if les == 4
	replace student      = 1 if les == 6 | les == 0
	replace disable      = 1 if les == 8 
	replace other 	 = 1 if les == 9
	gen out_of_labour = (retired + student + disable +other==1)
	
	replace employee     = 1 if les == 3 & yem_new > 0 & adjusted_hours >0
	*replace solo_self 	 = 1 if les ==2 & pl040 == 2 & yse_new >0 & adjusted_hours >0
	replace selfemployed = 1 if les ==2 & yse_new >0 & adjusted_hours >0
	replace unemployed = 1 if pl020 ==1 & out_of_labour ==0 & les==5
	replace inactive = 1 if pl020 ==2 & (out_of_labour + employee + selfemployed + unemployed== 0)
	
	// Ensure people have only one economic status
	gen working = employee + selfemployed 
	replace unmatched = 1 if working + unemployed + inactive + out_of_labour == 0   
	quiet gen overal = working + unemployed + inactive + out_of_labour + unmatched 
	assert overal == 1
}


if $FLEX_SELECT == 0 {
	//labour status based on income reference period
	replace retired  = 1 if pl085>0 & pl085!=. & pl085 > bunmy+monthun +yemmy + ysemy
	replace student = 1 if pl087 >0 & pl087!=. & pl087 > bunmy+monthun +yemmy + ysemy
	replace disable  = 1 if pl086 > 0 & pl086!=. & pl086 > bunmy+monthun +yemmy + ysemy
	gen out_of_labour = (retired + student + disable ==1)
	replace out_of_labour = 0 if pl090 > pl086 | pl090 > pl089

	replace inactive  =  1 if pl089 > 0  & pl089 !=. & pl089 > bunmy+monthun +yemmy + ysemy
	replace inactive = 1 if pl090 > 0  & pl090!=.
	replace inactive = 0 if out_of_labour == 1
	
	replace employee     = 1 if earnstype==1 & (pl073+pl074>0)
	replace employee = 0 if yemmy < bunmy + monthun 
	replace employee  = 0 if out_of_labour ==1|inactive ==1
	
	replace selfemployed = 1 if earnstype==2 & (pl075+pl076>0)
	replace selfemployed  = 0 if out_of_labour ==1 | inactive ==1
	replace selfemployed = 0 if ysemy < bunmy + monthun
	replace solo_self 	 = 1 if pl040 == 2 & selfemployed==1
	
	replace unemployed = 1 if monthun >0 | bunmy >0 
	replace unemployed = 0 if yem_new > monthly_MW & employee ==1
	replace employee = 0 if yem_new < monthly_MW & employee ==1
	replace unemployed = 0 if yse_new > monthly_MW & selfemployed ==1
	replace selfemployed = 0 if yse_new < monthly_MW & selfemployed ==1
	replace unemployed = 0 if out_of_labour ==1
	
	replace inactive = 0 if unemployed == 1
	
	// Ensure people have only one economic status
	gen working = employee + selfemployed 

	replace unmatched = 1 if working + unemployed + inactive + out_of_labour == 0   
	quiet gen overal = working + unemployed + inactive + out_of_labour + unmatched 
	assert overal == 1
}



*-----------------------------------------------------------------------
* Employment status and sectors
*-----------------------------------------------------------------------

gen LSstatus = 3	if inactive ==1 
replace LSstatus = 4 if unemployed ==1 
replace LSstatus = 1 if employee ==1
replace LSstatus = 2 if selfemployed ==1
replace LSstatus = 0 if LSstatus == .

lab def LSstatuslab 0 "out" 1 "employee" 2 "selfemployed" 3 "inactive" 4 "unemployed"
lab val LSstatus LSstatuslab 
tab LSstatus

*lab def lindi_lab 0 "none" 1 "Agriculture" 2 "Mine_manifac" 3 "Construction" 4 "Wholesale" 5 "Hotel_Rest" 6 "Trans_Com" 7 "Finance" 8 "Real_estate" 9 "Public_administ_def" 10 "Education" 11 "Health_socialwork" 12 "Other"
*lab val lindi lindi_lab 

// sector definition can changed
//for example public versus private
// regular work verus irregular
//
 
if "$SECTORS" == "1"{
	gen sector = 0
	replace sector =1 if lindi !=0
}

if "$SECTORS" == "2"{
	gen sector = 0
	replace sector = 1 if lindi >= 2 & lindi <= 5
	replace sector = 2 if lindi!=0 & (sector !=1)
}

tab sector 

*-----------------------------------------------------------------------
* Sample selection for wage equation 
*-----------------------------------------------------------------------
if $UNEMPLOYMENT == 1 {
	if "$EmplStatus" == "2"{
		quiet gen wage_subsample_m = ///
				  (employee == 1 | unemployed == 1 | selfemployed == 1 | inactive == 1) ///
				  & dgn == 1 & dag >= $MIN_AGE & dag <=$MAX_AGE
		quiet gen wage_subsample_f = ///
				  (employee == 1 | unemployed == 1 | selfemployed == 1 | inactive == 1) ///
				  & dgn == 0 & dag >= $MIN_AGE & dag <=$MAX_AGE
	}
	if "$EmplStatus" == "1"{ 
		quiet gen wage_subsample_m = ///
				  (employee == 1 | unemployed == 1 | inactive == 1) ///
				  & dgn == 1 & dag >= $MIN_AGE & dag <=$MAX_AGE
		quiet gen wage_subsample_f = ///
				  (employee == 1 | unemployed == 1 | inactive == 1) ///
				  & dgn == 0 & dag >= $MIN_AGE & dag <=$MAX_AGE

	}
}
	
if $UNEMPLOYMENT == 0 {
	if "$EmplStatus" == "2"{
		quiet gen wage_subsample_m = ///
				  (employee == 1 | selfemployed == 1 | inactive == 1| unemployed == 1) ///
				  & dgn == 1 & dag >= $MIN_AGE & dag <=$MAX_AGE
		quiet gen wage_subsample_f = ///
				  (employee == 1 | selfemployed == 1 | inactive == 1| unemployed == 1) ///
				  & dgn == 0 & dag >= $MIN_AGE & dag <=$MAX_AGE
	}
	if "$EmplStatus" == "1"{ 
		quiet gen wage_subsample_m = ///
				  (employee == 1 | inactive == 1| unemployed == 1) ///
				  & dgn == 1 & dag >= $MIN_AGE & dag <=$MAX_AGE
		quiet gen wage_subsample_f = ///
				  (employee == 1 | inactive == 1| unemployed == 1) ///
				  & dgn == 0 & dag >= $MIN_AGE & dag <=$MAX_AGE
	}
}


gen LSind =  wage_subsample_m ==1 |wage_subsample_f ==1 
replace LSind = 0 if sector ==0 & (employee == 1| selfemployed == 1)
replace LSind =0 if unemployed ==1 & adjusted_hours >0 
replace LSind =0 if inactive ==1 & adjusted_hours >0 

*-----------------------------------------------------------------------
* Identification of flexible unit: Main Earner and his/her partner**
*-----------------------------------------------------------------------

gsort idhh -LSind -couple -earns  -dag 
// added dummy for being in couple; //
//among those flexible, selected those in couple first 
bysort idhh: gen n= _n
gen MainEarn = n == 1 & LSind == 1
 
tempfile partner
save  `partner'
keep idpartner MainEarn
rename idpartner idperson
rename MainEarn MEpartner
merge idperson using `partner', sort uniqusing
drop if _merge == 1
drop _m

replace MEpartner = 0 if MEpartner == .
gen flex = MainEarn == 1 | MEpartner == 1

* Identification of flexible couple
gen LScouple = (flex == 1 & couple == 1)

noi di in y "Same sex couple"
bysort idhh LScouple: egen samesex =sum(dgn) if flex ==1
lab def samesexlab 1 "Different sex" 0 "Same sex - females" 2 "Same sex - males"
lab val samesex samesexlab 
noi tab samesex if LScouple == 1
replace flex=0 if samesex != 1 & LScouple == 1
*assert samesex == 1 if LScouple == 1
replace flex = 0 if LSind ==0


replace flex = 0 if adjusted_hours == 0 & (LSstatus == 1|LSstatus == 2)

*replace LSstatus = 1 if adjusted_hours > 0 & yem_new>0 & yem_new>yse_new 

*replace LSstatus = 2 if adjusted_hours > 0 & yse_new>0 & yse_new > yem_new
*replace sector = 0 if LSstatus == 3|LSstatus == 4 

*******************************Flexible household
	// Flexible Women
gen flex_f = (flex == 1 & dgn == 0)
gen flex_m = (flex == 1 &  dgn == 1)

// Number of potentially LS adjusting Households
sort idhh
quiet by idhh: egen n_lsflex = sum(flex)
quiet by idhh: egen n_lsflex_coup = sum(LScouple)
quiet by idhh: egen flex_ff = sum(flex_f)
quiet by idhh: egen flex_mm = sum(flex_m)

gen flex_hh = 0
replace flex_hh = 1 if n_lsflex == 2 
replace flex_hh = 2 if n_lsflex == 1 & n_lsflex_coup == 0 & flex_ff == 1  /* single female hh*/
replace flex_hh = 3 if n_lsflex == 1 & n_lsflex_coup == 0 & flex_mm == 1  /* single male hh*/

replace flex_hh = 4 if n_lsflex == 1 & flex_ff == 1 & n_lsflex_coup == 2/* semiflexible female hh*/
replace flex_hh = 5 if n_lsflex == 1 & flex_mm == 1 & n_lsflex_coup  == 2  /* semiflexible male hh*/
assert flex_f == 0 if dgn == 1
assert flex_m == 0 if dgn == 0
sum dwt if flex_hh > 0


bys idhh:egen check_flexhh = total(flex_hh)
bys idhh:gen N = _N
replace check_flexhh = check_flexhh/N
assert check_flexhh == flex_hh

tempname nflex
scalar `nflex' = r(sum)
tempname nflex_file

file open `nflex_file' using "${path_results}/population/scalars/nflex_$country", write text replace
file write `nflex_file' "`=`nflex''" _n
file close `nflex_file'  


replace earns = emp_income if employee ==1
replace earns = y_yse if selfemployed ==1
replace earns = 0 if (unemployed + inactive == 1)

gen hourly_wage = earns / (adjusted_hours*4.333) 

//hourlywage is missing for those who report zero hours (unemployed or inactive) or zero working months  
misstable summarize hourly_wage if flex==1

//hourlywage is zero for those who report zero income but positive hours and working months  
count if hourly_wage==0 & flex==1
*replace hourly_wage = min_wage if hourly_wage < min_wage & employee ==1

sum earns hourly_wage if wage_subsample_m ==1 & (hourly_wage !=0 & hourly_wage !=.)
sum earns hourly_wage if wage_subsample_f ==1 & (hourly_wage !=0 & hourly_wage !=.)

foreach s in m f{ 
    quiet{
	    
	

	foreach emp in 1(1)2 {
		local quant_top_m = 99.0
		local quant_top_f = 99.0

		local quant_bot_m = 1
		local quant_bot_f = 1

		di in r "`s'" 
		// calculate a "minimum productivity" (bottom 2% cutoff)among those in-work, to be used below 
		di in r "before trimming"
		sum hourly_wage if wage_subsample_`s' ==1 & (hourly_wage !=0 & hourly_wage !=.),d
	  
		egen mw_`s' = pctile(hourly_wage) ///
		if (wage_subsample_`s' == 1) & (hourly_wage>0), p(`quant_bot_`s'')
		egen minw10_`s' = mean(mw_`s') 
		gen  minw_`s' = minw10_`s'
		drop mw_`s'
		sum minw_`s'
		
		// calculate a "maximum productivity" (top 0.5% cutoff) among those in-work, to be used below
		egen tw_`s' = pctile(hourly_wage) ///
		if (wage_subsample_`s' == 1) & (hourly_wage>0), p(`quant_top_`s'')
		egen topw10_`s' = mean(tw_`s')
		gen  topw_`s' = topw10_`s'
		sum  topw_`s'
		replace hourly_wage = minw_`s' if (hourly_wage < minw_`s') & (dgn_`s' == 1) & wage_subsample_`s' ==1 & hourly_wage!=. & hourly_wage !=0
		replace hourly_wage = topw_`s' if (hourly_wage > topw_`s') & (dgn_`s' == 1) & wage_subsample_`s' ==1  & hourly_wage !=0 & hourly_wage !=.
		
		di in r "after trimming"
		sum hourly_wage if (dgn_`s' == 1) & wage_subsample_`s' ==1 & (hourly_wage !=0 & hourly_wage !=.),d
		drop tw_`s'
	}
	}
}

sum earns hourly_wage if wage_subsample_m ==1 & (hourly_wage !=0 & hourly_wage !=.)
sum earns hourly_wage if wage_subsample_f ==1 & (hourly_wage !=0 & hourly_wage !=.)


gen lnhourlywage  = ln(hourly_wage)


*=======================================================================
*            Prepare data for wage estimations
*=======================================================================


*-----------------------------------------
* Marital/cohabitation status
*-----------------------------------------
quietly gen married = (dms == 2)
gen married_out_hh = (married ==1 & idpartner ==0) 

*-----------------------------------------
* Children age groups
*-----------------------------------------
gen ch		= ((dag < 18) | (dag >= 18 & les == 6))
gen ch3		= (dag < 3)
gen ch36	= (dag >= 3 & dag < 6)
gen ch6p	= ((dag >= 6 & dag < 18) | (dag >= 18 & les == 6))
gen ch18p = ((dag >= 18 & idmother != 0 & idmother != .)|(dag < 18 & idfather != 0 & idfather != .))
gen ch014 = (dag <= 14)

*---------------------------------------------------
* Calculate the number of children in each age group
*---------------------------------------------------
sort idhh idperson
tempfile input
save `input'

foreach childgr of varlist ch* {
	noi di
	noi di in y "Children age group: `childgr'"

	keep if `childgr' == 1
	keep idhh idmother idfather dag 
	gen double temp_parent = idmother
	replace temp_parent = idfather if temp_parent == 0
	rename temp_parent idperson
	bysort idperson: gen num`childgr' = _N
	bysort idperson: egen youngage`childgr' = min(dag)
	duplicates drop idperson, force
	drop dag idmother idfather
	sort idhh idperson
	merge idhh idperson using `input', sort uniqusing

	drop if _m == 1
	drop _m
	recode num`childgr' (. = 0)
	save `input', replace

} // foreach childgr

sum youngage*
drop youngagech?* // keep only <youngagech>

*---------------------------------------------------------------------
* Assign to each partner the sum of the children of the other partner
*---------------------------------------------------------------------

foreach var of varlist youngage numch* {
	rename `var' p_`var'
} 

keep idhh idpartner p_youngage p_numch*
rename idpartner idperson
drop if idperson == 0
sort idhh idperson
merge idhh idperson using `input', sort uniqusing

drop if _m == 1
drop _m

replace youngagech = min(youngagech, p_youngagech)

foreach var of varlist numch* {
*	replace numch = 0 if numch == .
	assert `var' != .
	recode p_`var' (. = 0)
	replace `var' = `var' + p_`var'
} 

drop p_numch* p_youngagech
capture rename numch18p nchild18p
capture rename numch014 nchild014

	
*-----------------------------------------
* Age
*-----------------------------------------
gen age = dag
gen age2 = dag * dag


* Schooling
gen school = 0 if deh == 0
replace school = 5 if deh == 1
replace school = 8 if deh == 2
replace school = 13 if deh == 3 | deh == 4
replace school = 18 if deh == 5

*Experience
gen exp = dag - school - 6
replace exp=max(0,exp)
gen exp2 = exp^2

*Work history in years
replace liwwh = 0 if liwwh == -1 // never worked or younger than 16
replace liwwh = liwwh / 12
gen liwwh2 = liwwh^2

*Age
gen dag2 = dag^2


quiet generate ed_low =  inrange(deh,0,2)
quiet generate ed_middle =  inrange(deh,3,4)
quiet generate ed_high =  inrange(deh,5,6)

* adult 
quiet generate isadult = 0
quiet replace  isadult = 1 if dag >= $MIN_AGE & dag <=$MAX_AGE
quiet bys idhh: egen nadult = sum(isadult)

*-------------------------------------------------------------------------------
* Equivalence scale (square root of number of components)
*-------------------------------------------------------------------------------
bysort idhh: egen hhsize = count(idhh)
gen eq_scale = sqrt(hhsize)
gen oecd_equiv_scale = 1 + (nadult - 1 + nchild18p + nold)*0.5 + (nchild014)*0.3  
// 1 head + 0.5 every 15+ + 0.3 below

//HH position - fiscal effects
//couples households
generate hhtype = . 
replace  hhtype = 1 if flex_hh==1 // Couples 
replace  hhtype = 11 if flex_hh == 1 & numch >0 // Couple hh with children
replace  hhtype = 12 if flex_hh == 1 & numch ==0 //Couple hh without children
//single men households
replace  hhtype = 2 if flex_hh == 2  // single women 
replace  hhtype = 21 if flex_hh == 2 & numch >0 // single women with children
replace  hhtype = 22 if flex_hh == 2 & numch ==0 // single women without children
//single women households
replace  hhtype = 3 if flex_hh == 3  // single men 
replace  hhtype = 31 if flex_hh == 3 & numch >0 // single men with children
replace  hhtype = 32 if flex_hh == 3 & numch ==0 // single men without children
//sole parents 
*replace  hhtype = 23 if (flex_hh == 3|flex_hh == 2) & numch >0 // sole parents with children

//Women with unflexible partner 
replace  hhtype = 4 if flex_hh == 4  //Women with unflexible partner 
replace  hhtype = 41 if flex_hh == 4 & numch >0 // Women with unflexible partner  with children
replace  hhtype = 42 if flex_hh == 4 & numch ==0 // Women with unflexible partner  without children

//Men with unflexible partner 
replace  hhtype = 5 if flex_hh == 5  //Women with unflexible partner 
replace  hhtype = 51 if flex_hh == 5 & numch >0 // Women with unflexible partner  with children
replace  hhtype = 52 if flex_hh == 5 & numch ==0 // Women with unflexible partner  without children
replace  hhtype = 0 if flex_hh == 0

assert hhtype != .

capture label drop poslbl
label define poslbl 					///
	1 "Couples"     				 	/// 
	11 "Couples with children"       	///
	12 "Couples without children"       ///
	2 "Single women"      				/// 
	21 "Single women with children"     ///
	22 "Single women without children"  ///
	3 "Single men"     					/// 
	31 "Single men with children"       ///
	32 "Single men without children"    ///
	4 "Women with unflexible partner"      					/// 
	41 "Women with unflexible partner with children"       ///
	42 "Women with unflexible partne without children"       ///
	5 "Men with unflexible partner"      					/// 
	51 "Men with unflexible partner with children"       ///
	52 "Men with unflexible partne without children"       ///
	0 "Other" ///
	
label value hhtype poslbl
	
*-----------------------------------------------
* Variables related to migrant status
*-----------------------------------------------
generate citiz = (dcz == 1)
gen native = dcz ==1
gen migrant = dcz !=1
gen intra_eu = dcz ==2
gen extra_eu = dcz ==3
gen recent_migrant = (dyyrs < 6 & dyyrs > 0)
gen reason_pt = pl120

* (Regional) Unemployment rate by sex   //[TO DO]! replace the info below with the regional unemployment 
* rate by sex of your country (add one row for each region, if info available)
* Info from: http://appsso.eurostat.ec.europa.eu/nui/show.do?dataset=lfst_r_lfu3rt&lang=en

// Other Household income
quiet generate  other_y         =    (y+pen+bun_all+capital)
quiet bys idhh:  egen other_hh_y = sum(other_y)
gen other_earn      =    (other_hh_y - y) / 1000
gen eqoth_earn = other_earn / eq_scale
*gen eqoth_inc = oth_inc / eq_scale
*gen eqoth_earn_sq  = eqoth_earn * eqoth_earn
*gen eqoth_inc_sq = eqoth_inc * eqoth_inc

//other variable for self-employed///

gen managers = (loc==1)
gen technics = (loc>1&loc<5)
gen service = (loc>4&loc<8)
gen worker = loc>7 & loc <=9
*gen whitecollar = lcl == 2
gen civil= lcs==1
	

foreach gender in 1 0{
	forvalues emp=1/$EmplStatus{
		gen pre_level_`gender'_`emp'= 	monthly_MW
		foreach q  in "25" "50" "75" "90" "95" "99" "100"{

			gen level_`gender'_`emp'_`q'=.

			if "`q'"!="100"{		
				di in r "p(`q')"

				sum earns if LSind == 1 & dgn == `gender' & LSstatus == `emp' & earns>monthly_MW, d
				egen inc_level_`gender'_`emp'_`q'  = pctile(earns) ///
				if LSind == 1 & dgn == `gender' & LSstatus == `emp' & (earns>monthly_MW), p(`q')

				replace level_`gender'_`emp'_`q' = 1 if earns > pre_level_`gender'_`emp' & earns <= inc_level_`gender'_`emp'_`q' & (LSind == 1 & dgn == `gender') & LSstatus == `emp' 	
				
				replace pre_level_`gender'_`emp' = inc_level_`gender'_`emp'_`q' if LSind == 1 & dgn == `gender' & LSstatus == `emp' & (earns>monthly_MW)
		
							
			}

			if "`q'"=="100"{
				di in r "`q'"
				replace level_`gender'_`emp'_`q' = 1 if earns > pre_level_`gender'_`emp' & (LSind == 1 & dgn == `gender') & (earns>monthly_MW) & LSstatus == `emp' 
			}
		}
	}		
}

foreach q  in "25" "50" "75" "90" "95" "99" "100"{
	gen level_`q'= 0
	foreach gender in 1 0{
		forvalues emp=1/$EmplStatus{
			replace level_`q'= level_`gender'_`emp'_`q' if (LSind == 1 & dgn == `gender') & LSstatus == `emp' & level_`gender'_`emp'_`q' == 1
			drop level_`gender'_`emp'_`q'

		}
		
	}		
}


quiet by idhh: egen wealth = sum(afc)
quiet gen afc_per_k = wealth / (oecd_equiv_scale * 1000)

capture gen regunp = 0 
do "${EM_dofiles}/unemployment.do" 
capture gen reg = 0
*do "${EM_dofiles}/capital.do" 

gen mdt = round((ddt - $pyear )/10000)
// Covariates 
*global wagex   "age age2 ed_middle ed_high married other_hh_y afc_per_k citiz" // reg

*qui log using $outlog/heckman/wage_estim_$country.log , replace text name(wage_estim)
gen mortgage = log(xhcmomi+0.00000001)


local levels = "level_50 level_75 level_90 level_95 level_99 level_100" 
global wagex   "age age2 ed_middle ed_high migrant regunp managers technics service worker civil `levels'  lfs" // reg
global selectx "ed_middle ed_high liwwh regunp numch3 numch36 numch6p couple mortgage eqoth_earn afc_per_k"

label var age "Age"
label var age2 "Age square"
label var ed_middle "Secondary education"
label var ed_high "Tertiary education"
label var migrant "Migrant"
label var liwwh "total Months in Employment"
label var  regunp "regional unemployment"
label var  numch3 "Number of children < 3 years"
label var  numch36 "Number of children [3-6] years"
label var  numch6p "Number of children > 6 years"
label var  couple "Couple"
label var  mortgage "Holding a Mortage"

svyset [pweight=dwt]
	
//WAGE PREDICTION WITH SECTORS DISTINCTION
local x = $NumberOfSectors 
local y = $EmplStatus

forvalues sec=1/$NumberOfSectors{
	forvalues emp=1/$EmplStatus{
		gen depvar_m_`emp'_`sec' = 1 if  LSstatus == `emp' & sector == `sec'
		local k=(`sec'-1)*`y'+`emp'
		qui rename depvar_m_`emp'_`sec' depvar_m`k'
	}
}

gen depvar_m = 0
local x_y= $NumberOfSectors*$EmplStatus 
forvalues i=1/`x_y'{
	replace depvar_m = `i' if depvar_m`i' == 1 
	gen p_hourly_`i' = .
	gen depvar_`i' = lnhourlywage if depvar_m ==`i' 
}

tab depvar_m

		
foreach gender in 0 1 {

//Wage_prediction = 1 is the Dagsvik Strom method, 2004
//Dagsvik JK, Str0m S. 2004. Sectoral labor supply, choice restrictions and functional form. Discussion papers, no. 388, Statistics Norway. http://www.ssb.no/publikasjoner/DP/pdf/dp388.pdf

	if ${WAGE_PREDICTION} == 1{	
		di in r "gender is equal to `gender'"		
		forvalues i=1/`x_y'{
			di in r `i' 
			mlogit depvar_m $selectx if LSind == 1 & dgn == `gender', baseoutcome(0)
			predict p`i' if e(sample), outcome(`i')
			gen neglnprob`i' = ln(p`i')* -1
			gen  pneglnprob`i' = p`i'*neglnprob`i'
			reg lnhourlywage $wagex pneglnprob`i' if LSind == 1 & dgn == `gender' & depvar_m==`i'
			predict wage`i',xb
			*replace wage`i' = wage`i'  - _b[pneglnprob`i']*pneglnprob`i'
			gen estimvar`i' = lnhourlywage - wage`i' if LSind == 1 & dgn == `gender'
			sum estimvar`i' if LSind == 1 & dgn == `gender'
			*gen variance`i' = r(Var)
			scalar m`i'=r(Var)
			matrix s`i'=m`i'
			drawnorm es_`i',mean(0) sd(s`i')
			replace p_hourly_`i' = exp(wage`i'+es_`i') if dgn == `gender'& LSind==1
			sum p_hourly_`i'  hourly_wage if dgn == `gender'& LSind==1
			drop p`i' neglnprob* pneglnprob* wage`i' estimvar`i' es_`i'
		}
	}
		

///wage prediction = 2 - regards to dmf(2) method
	if ${WAGE_PREDICTION} == 2 {	

		forvalues i=1/`x_y'{
			di in r "`i'"
			selmlog depvar_`i'  $wagex if LSind == 1 & dgn == `gender', select(depvar_m = $selectx)/*
			*/dmf(2)  gen(_s)
		
			forvalues s = 0(1)`x_y' {
				capture gen _m`s' = _s`s'
			}
		
			predict wage_`i' if dgn == `gender' & LSind==1,xb 
			replace p_hourly_`i' = exp(wage_`i') if dgn == `gender'& LSind==1
			sum p_hourly_`i' hourly_wage if hourly_wage >0 & LSind == 1 & dgn == `gender'
			capture drop _m* _s* wage_`i'
		}
	}



///wage prediction = 3 - regards to Durbin Mcfadden method
	if ${WAGE_PREDICTION} == 3 {	

		/*gen trnsp0=(p0*ln(p0))/(1-p0);
		> gen trnsp1=(p1*ln(p1))/(1-p1);
		> gen trnsp2=(p2*ln(p2))/(1-p2);
		> gen trnsp3=(p3*ln(p3))/(1-p3);
		> 
		> gen millsp1=3*ln(p1)+ trnsp0 +trnsp2 +trnsp3;
		> gen millsp2=3*ln(p2)+ trnsp0 +trnsp1 +trnsp3;
		> gen millsp3=3*ln(p3)+ trnsp0 +trnsp1 +trnsp2;*/
		forvalues i=1/`x_y'{
				di in r "`i'"
				selmlog depvar_`i'  $wagex if LSind == 1 & dgn == `gender', select(depvar_m = $selectx)/*
				*/dmf(0)  wls gen(_s)
				/*	[lee dmf(#) dhl(# [all]) showmlogit wls
					   bootstrap(number_of_replications [sample_size]) mloptions(mlogit
					   options) gen(variable generic name)]*/
				*estimates store wage_`gender'_`i'_${country}_${year}
				*estwrite wage_`gender'_`i'_${country}_${year} using "${path_results}/estimation/wage_`gender'_`i'_${country}_${year}.sters", replace
				
				forvalues s = 0(1)`x_y' {
					capture gen _m`s' = _s`s'
				}
			
				predict wage_`i' if dgn == `gender' & LSind==1,xb 
				replace p_hourly_`i' = exp(wage_`i') if dgn == `gender'& LSind==1
				sum p_hourly_`i' hourly_wage if LSind == 1 & dgn == `gender' & depvar_m == `i'
				capture drop _m* _s* wage_`i'
		}
	}

}

		
forvalues sec=1/$NumberOfSectors {
	forvalues emp=1/$EmplStatus{
		local k=(`sec'-1)*`y'+`emp'
		qui rename p_hourly_`k' p_hourly_`emp'_`sec' 
	}  
}

if ${ACTUAL_WAGE} == 1 {
	local x = $NumberOfSectors 
	local y = $EmplStatus
	forvalues sec=1/`x' {
		forvalues emp=1/`y' {
			
		replace p_hourly_`emp'_`sec' = hourly_wage if sector == `sec' & LSstatus == `emp' & hourly_wage !=. & flex ==1
		sum	hourly_wage p_hourly_`emp'_`sec' if sector == `sec' & LSstatus == `emp' & hourly_wage !=. & flex ==1
		gen yem_`emp'_`sec' = p_hourly_`emp'_`sec'*adjusted_hours*4.333
		}  
	}
}


local x = $NumberOfSectors 
local y = $EmplStatus
gen bad_predict = 0
forvalues sec=1/`x' {
	forvalues emp=1/`y' {
		
		gen p_monthly_`emp'_`sec' = p_hourly_`emp'_`sec'*adjusted_hours*4.333 if flex ==1 
		gen dif_`emp'_`sec' =  p_monthly_`emp'_`sec' - earns
		sum dif_`emp'_`sec' if sector == `sec' & LSstatus == `emp' & flex == 1, d
		replace bad_predict = 1 if dif_`emp'_`sec' < r(p10)
		
	}  
}

drop dgn
gen dgn =1 if dgn_m ==1
replace dgn =0  if dgn_f ==1

gen MW_earner = hourly_wage < hourly_MW & employee==1


*| (p_hourly_1_1 < hourly_MW)
quiet compress
sort idperson

gen les_origin = les

capture drop MEpartner agepartner penpartner youngagech10p youngagech610 youngagech6 youngagech6p youngagech36 youngagech3 youngagech hw_actual

//observed choice of hours	
gen lhw_choice = adjusted_hours 
replace lhw_choice = $max_hour  if lhw_choice>$max_hour
replace lhw_choice = $min_hour+1 if (lhw_choice <= $min_hour & lhw_choice > 0) & flex ==1 

*gen double choice = int((lhw_choice + $step - $initial_step )/($step ))+1 if flex ==1
gen double choice_g = $step * int((lhw_choice + $step - $min_hour -1)/ $step ) + $min_hour if lhw_choice!=0 & flex ==1
*replace choice_g = 0 if choice ==1 & flex ==1
replace choice_g = 0 if flex ==1 & LSstatus==0|LSstatus >2
replace choice_g = $max_hour if flex ==1 & choice_g > $max_hour

//observed choice of sector 
gen sec_g = 0
local x = $NumberOfSectors 
forvalues sec=1/`x' {
	replace sec_g  = sector if (sector == `sec')
}

//observed choice of sector 
gen emp_status_g = 0
local y = $EmplStatus
forvalues emp=1/`y' {
	replace emp_status_g  = LSstatus if (LSstatus == `emp')
}  


if ${UNEMPLOYMENT} == 1{
	replace choice_g = $search_hour if flex ==1 & unemployed ==1
	replace emp_status_g = 0 if choice_g < $min_hour
	replace sec_g = 0 if choice_g < $min_hour+1
}
else if ${UNEMPLOYMENT} == 0{
	replace emp_status_g = 0 if choice_g == 0
	replace sec_g = 0 if choice_g ==0
}
else{
	di in r "ERROR: Unemployment can only be 0 or 1. Please modify the value and run again."
}

*replace sec_g = 0 if LSstatus ==1|LSstatus ==2
assert sec_g >0 & emp_status_g > 0 if choice_g > 5 & flex ==1
assert sec_g ==0 & emp_status_g == 0 if choice_g <= 5 & flex ==1


gen dummy = . 

if $HOURS_DISTRIBUTION == 2 {
	foreach c in $hours { 
		gen numero`c' = round(uniform()*1000) if flex == 1
	}

	**** UOMINI E DONNE DIVISO E SOLO SU LSind == 1 (aggiunto nel replace e nella generazione del numero'c')

	local j = $min_hour
	local f = `j'
	local k = `j' + $step
	foreach c in $pos_hours{ 
		gen ore_m`c' = .
		gen ore_f`c' = .
		forvalues i = `j'/`k' { 
			quietly count if (lhw_choice>=`j' & lhw_choice<=`i') & choice_g == `c' & flex == 1 & dgn == 1
			quietly replace dummy =(lhw_choice>=`j' & lhw_choice<=`i') & choice_g == `c' & flex == 1 & dgn == 1
			quietly sum dummy if (lhw_choice>=`f' & lhw_choice <=`k') & choice_g == `c' & flex == 1 & dgn == 1 [aw=dwt] 
			quietly replace ore_m`c' = `i' if(numero`c'<=r(mean)*1000) & r(mean)*1000 > 0 & ore_m`c' == . & flex == 1 & dgn==1
			quietly replace dummy =(lhw_choice>=`j' & lhw_choice<=`i') & choice_g == `c' & flex == 1 & dgn == 0
			quietly sum dummy if (lhw_choice >=`f' & lhw_choice <=`k') & choice_g == `c' & flex == 1 & dgn == 0 [aw=dwt] 
			quietly replace ore_f`c' = `i' if(numero`c'<=r(mean)*1000) & r(mean)*1000 > 0 & ore_f`c' == . & flex == 1 & dgn==0
		}
	
		local j = `j' + $step
		local k = `j' + $step
		local f = `j'
		quietly sum ore_f`c' if flex_f ==1
		quietly sum ore_m`c' if flex_m ==1
		quietly replace ore_f`c' = $max_hour if ore_f`c'>$max_hour & ore_f`c' == .
		quietly replace ore_m`c' = $max_hour if ore_m`c'>$max_hour & ore_m`c' == .
	}
}


gen ore_m0 = 0
gen ore_f0 = 0

if ${UNEMPLOYMENT} == 1{
	gen ore_m$search_hour = round(runiform(1,$search_hour)) if flex_m == 1
	gen ore_f$search_hour = round(runiform(1,$search_hour)) if flex_f == 1
}


*drop rb* pb*  py* hy*
drop numero* 
*drop xmp_neg-y

//for testing reasons we keep 30% of the sample for each houshold type
if ${TEST} == 1{
gen test = 0
	foreach i in "0" "1" "2" "3" "4" "5"{
		splitsample if flex_hh == `i' & n==1, generate(svar_`i',replace) split(30 70)
		replace  svar_`i' = 0 if  svar_`i' == 2 
		bysort idhh: egen  svar_`i'_tot = total( svar_`i')
		replace test = test + svar_`i'_tot
	} 
keep if test == 1
}




******* SUMMARY STATISTICS OF LS FLEXIBLE SAMPLE *********************
gen gender_couple = 1 if (dgn ==1 & couple==1) ==1
replace gender_couple = 2 if (dgn ==0 & couple==1) ==1
replace gender_couple = 3 if (dgn ==1 & couple==0) ==1
replace gender_couple = 4 if (dgn ==0 & couple==0) ==1

label define dgn_couple 1 "Married Men" 2 "Married Women" 3 "Single Men" 4 "Single Women"	
label value gender_couple dgn_couple

label var LSstatus "Labour Market Status"

asdoc tabulate LSstatus gender_couple if flex ==1 [aw=dwt], center col replace label title(\fs28 Table 1. Distribution of LS endogenous sample by employment status, gender and marital status) save(${path_results2share}/${country}_${year}_${choices}ch/1-Summary_statistics.rtf)

gen occ_ls = 1 if LSstatus == 1 & sec_g ==1
replace occ_ls = 2 if LSstatus == 1 & sec_g ==2
replace occ_ls = 3 if LSstatus == 2 & sec_g ==1
replace occ_ls = 4 if LSstatus == 2 & sec_g ==2
label define oc_ls 1 "Employee in non-essential sector" 2 "Selfemployed in non-essential sector" 3 "Employee in essential sector" 4 "Selfemployed in essential sector"	
label value occ_ls oc_ls

asdoc tabulate occ_ls gender_couple if flex ==1 [aw=dwt], center col label title(\fs28 Table 2. Distribution of LS endogenous sample by employment status, occupational sector, gender and marital status) save(${path_results2share}/${country}_${year}_${choices}ch/1-Summary_statistics.rtf) append


di in r "here is the new table"
asdoc by gender_couple: sum hours  if flex ==1 & hours>0, center col label title(\fs28 Table 3. Average working hours of LS endogenous sample by employment status, occupational sector, gender and marital status) save(${path_results2share}/${country}_${year}_${choices}ch/1-Summary_statistics.rtf) append 


gen mig_categ = 1 if migrant_EU==1
replace mig_categ = 2 if migrant_nonEU==1
replace mig_categ = 3 if bornEU_ctz==1
replace mig_categ = 4 if bornnonEU_ctz==1
label define mig 1 "EU migrant" 2 "Non-EU migrant" 3 "Born in EU but citizen" 4 "Born out EU but citizen"	
label value mig_categ mig
asdoc tabulate mig_categ if flex ==1 , center label title(\fs28 Table 4. Distribution of Migrants by country of birth and citizenship) save(${path_results2share}/${country}_${year}_${choices}ch/1-Summary_statistics.rtf) append


sort idhh idperson
format idperson %12.0f 

local allvars  $allvars strata1 psu1

format idperson %12.0f 
outsheet `allvars' using ///
    "${path_LSscen}/0_fullsample/${country}_${year}_${choices}ch_full.txt", replace 


save "${path_LS}/baseline/${country}_${year}_${choices}ch_baseline_full.dta", replace

capture keep `allvars' employee selfemployed age age2 school exp exp2 liwwh2 dag2 edprim edlsec edhsec edtert edlsec2 edhsec2 edtert2 solo_self unemployed inactive emp_income selfemp_income earns earnstype couple old70 pold ed_low ed_middle ed_high flex* hours LSstatus totmonthsFTPT hourly_wage married sector sec_g hhsize eq_scale oecd_equiv_scale hhpos citiz  mdt mortgage *choice* numch* emp_status_g LSstatus bunctmy cob bornEU_ctz bornnonEU_ctz migrant_EU migrant_nonEU dyyrs native migrant intra_eu extra_eu recent_migrant mig_categ hc030 hc040

save "${path_LS}/baseline/${country}_${year}_${choices}ch_reduced_baseline.dta", replace


do 11_programs
di in r "START counterfactuals 1_preparedata: $S_TIME  $S_DATE"
if $RUN_COUNTERFACTUALS == 1 {
	set trace off
	use "${path_LS}/baseline/${country}_${year}_${choices}ch_baseline_full.dta", clear
	keep if flex_hh != 0 

	gen p_hourly_0_0 = 0
	if "${country}" == "pt" gen liwmy01_a = 0 
	gen liwmy_a = 0
	gen lhwpv_a = 0
	gen yempv_a = 0
	gen lnu = 0
	
	*set to 0 all income components within each global only for flexible sample 
	foreach yvar in $yem_vars  $yse_vars {
	    	foreach yvar in $yem_vars $yse_vars $bun_vars $yse_evaded{
		sum  `yvar'  if flex_f ==1| flex_m ==1
		replace `yvar' = 0 if flex_f ==1| flex_m ==1
	}
	}

	if "$country" == "uk" global original_months "liwmy yemmy ysemy"
	else global original_months "liwmy liwftmy liwptmy yemmy ysemy"
	foreach var of varlist $original_months {
		quiet gen `var'_orig= `var'
		
	}
	
	
	global reform_no_new ""
	foreach refs in $reforms{
		if "`refs'" == "base"{
			global reform_no_new "`refs'"
		}
		else if "`refs'" == "m"{
			global reform_no_new "${reform_no_new} `refs'"
		}
		else if "`refs'" == "f"{
			global reform_no_new "${reform_no_new} `refs'"
		}
		display in r "input data reforms: ${reform_no_new}"
	}
					
	//List of global to pass to every new STATA instance (parallelisation)
	save "1_preparedata",replace
	
	local globals="HOURS_DISTRIBUTION step original_months country allvars path_EMinput year choices filename"
	
	clear
	set obs 1
	foreach a of local globals {
		gen `a'="${`a'}" 
	}
	save "globals_preparedata.dta",replace
		
	createFolder "${path_EMinput}" "temp_folder_prepData"
	local multiplier=1
	local counter=0
	foreach ref in $reform_no_new {

		if "`ref'" == "base" {
			local multip_m = 1
			local multip_f = 1
			local multip_i = 1
		}
		else if "`ref'" == "m"{
			local multip_m = 1.01
			local multip_f = 1
			local multip_i = 1
		}
		else if "`ref'" == "f" {
			local multip_m = 1
			local multip_f = 1.01
			local multip_i = 1
		}
		else {
			local multip_m = 1
			local multip_f = 1
			local multip_i = 1
		}
		
		foreach i in $hours {
			foreach j in $hours {
				forvalues sec_f = 1/${NumberOfSectors} {
					forvalues empstat_f = 1/${EmplStatus} {
						forvalues sec_m = 1/${NumberOfSectors} {
							forvalues empstat_m = 1/${EmplStatus} {
								local ++counter 
																							 
								//Launch new STATA instance
								di in r  "Create input data `counter': ref`ref'_f`i'_s`sec_f'_e`empstat_f'_m`j'_s`sec_m'_e`empstat_m'"
								
								di "winexec ${path_stata} /e do 1a_create_input_data `multip_m' `multip_f' `multip_i' `ref' `i' `j' `sec_f' `sec_m' `empstat_f' `empstat_m'"
								
								winexec "${path_stata}" "/e" "do" "1a_create_input_data" "`multip_m'" "`multip_f'" "`multip_i'" "`ref'" "`i'" "`j'" "`sec_f'" "`sec_m'" "`empstat_f'" "`empstat_m'" 
								
								//Look for input data files depending of split_number_STATA before launching more STATA instances. 
								local temp_number=`multiplier'*$split_number_STATA
																
								if `counter'==`temp_number'{
									sleep 500
									local temp_list:dir "${path_EMinput}/temp_folder_prepData/" files "*"
									local numfiles : word count `temp_list'
									local temp_counter=0
									while `numfiles'< `temp_number' {
										local ++temp_counter
										if `temp_counter'<50{
											sleep 500
											local temp_list:dir "${path_EMinput}/temp_folder_prepData/" files "*"
											local numfiles : word count `temp_list'
										}
										else{ 
											capture window stopbox rusure "ERROR: STATA instance failed to produce input. You can find more info about error in 1a_create_input_data log files in do folder.  Do you want to close STATA?"
											if _rc == 0 {
												exit, STATA clear
											}
											else{
												stop
											}
										}
										di "Looking for input file: attemp `temp_counter'/50"
									}
									local ++multiplier
								}
								
											
								if (`i' == 0 | `i' == 5) & (`j' == 0 | `j' == 5){
									continue, break
								}
								else if `j' == 0 | `j' == 5{
									continue, break
								}
							} //End of empstat_m
							if (`i' == 0 | `i' == 5) & (`j' == 0 | `j' == 5){
								continue, break
							}
							else if `j' == 0 | `j' == 5{
								continue, break
							}
						} //End of sec_m
						if (`i' == 0 | `i' == 5) & (`j' == 0 | `j' == 5){
							continue, break
						}
						else if `i' == 0 | `i' == 5 {
							continue, break
						}
					} //End of empstat_f
					if (`i' == 0 | `i' == 5) & (`j' == 0 | `j' == 5){
						continue, break
					}
					else if `i' == 0 | `i' == 5 {
						continue, break
					}
				} //End of sec_f
			} //End of j hours 
		} //End of i hours 
	} //End of Ref loop
	*bys idperson: gen count = _N
	*assert count ==1 
	*sort idhh idperson
}
cap rm "1_preparedata"
di in r "Total number of input files=  `counter'"
di in r "END 1_preparedata: $S_TIME  $S_DATE"
cap log close	
				
//UNEMPLOYMENT ALTERNATIVE
// eligibility conditions in euromod: (lnu > 0) & (liwmy_a >= (13*12/52)) & (lap00 = 0)
//only employees can receive this benefit - to be checked country by country
//accordingly we assume that lnu=1, liwmy_a equals liwmy.
//bunctmy02 is assumed to equal 12, this assumption should be changed 
//we assume that if unemployed has worked (liwmy months if liwmy>0
//we assume 12 months of unemployment if unempl months = 0 and this leads to overestimation of unemployment benefits for this samle compared to those who were unemployed_ben

* End of 1_preparedata.do file

	