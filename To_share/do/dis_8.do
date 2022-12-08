
* ------------------------------------------------------------------------------
* GENERATE BENEFIT VARIABLES ACCORDING TO EM COUNTRY REPORTS and EM STRUCTURE
* ------------------------------------------------------------------------------

clear all
set more off

use EU27, clear 

*gen bmu = 0 // why is this?
*gen bmr = 0 // why is this?
keep country idhh idperson dag dgn dwt* dcz* dcb* pop bac* bca* bcc* bcb* bch* bcr* bdi* bed* ///
	bfa* bhl* bho* bht* bma* bml* /*bmu**/ boa* bpl* brv* bsa* bsu* bun* bwk* byr* p* ///
	/*bmr**/ bls* bot* bmt* btu* ils_benmt ils_bennt ils_pen t* ils_tax ils_sic*

local countries AT BE BG CY CZ DE DK EE EL ES FI FR HR HU ///
				IE IT LT LU LV MT NL PL PT RO SE SI SK
local countries NL	
local benefits bac bca bcc bcb bch bcr bdi bed bfa bhl bho bht bnew	bma bml bmu boa bpl brv bsa bsu bun bwk byr btin pdi psu
	
local pensions pcs pdi phl pmm poa psu pyr byr

local taxes tbs tcr thl tin tmu tpc tpi tpr tsc twl txc tyr
	
*egen bac_alt = rowtotal(bac*)	// can't it be done in this way?

foreach country of local countries { // create fully disaggregated benefits, pentions and taxes in each country
    
	noi di "********"
	noi di "Procesing `country'..."
	noi di "********"
	
	preserve 
	
	if "`c(username)'" == "delvahu" {
		use "R:\01 - Households\42 - Ukraine\2 - Working Area\ctz\do\table1-parameters.dta", clear
	}
	else {
	    use "R:\B2\01 - Households\42 - Ukraine\2 - Working Area\ctz\do\table1-parameters.dta", clear
	} // this loads a file containing the list of benefits, pensions and taxes 
	
	import excel "R:\B2\01 - Households\42 - Ukraine\2 - Working Area\ctz\do\income_list_2018.xlsx", sheet("`country'") firstrow clear
	
	*replace variable =  "btintcch_s" if variable == "tintcch_s" & countrycode == "AT" // why is this?
	rename A variable
	
	levelsof variable if ils_bennt ==1|ils_benmt ==1
	foreach level in `r(levels)' {
		di in r "`level'"
		gen `level' = 1
	}

	local benefits bac bca bcc bcb bch bcr bdi bed bfa bhl bho bht bnew	bma bml bmu boa bpl brv bsa bsu bun bwk byr btin pdi psu
	foreach j of local benefits {
	   * foreach level in `r(levels)' {
		    
		capture ds `j'*  
		local `j'_list `r(varlist)' 
		*usubstr(`r(varlist)',3,4)
		di in r "``j'_list'"
		capture drop `j'*
	}
	
	levelsof variable if ils_pen ==1
	foreach level in `r(levels)' {
		gen `level' = 1
	}
	
	local pensions pcs pdi phl pmm poa psu pyr
	foreach j of local pensions {
	    
		capture ds `j'*
		local `j'_list `r(varlist)'
		di in r "`j'_list"
		capture drop `j'*
		
	}
	
	local tax = "ils_tax ils_sicer ils_sicct ils_sicee ils_sicse ils_sicot"
	
	foreach var of local tax {
	    levelsof variable if `var'!=.
			foreach level in `r(levels)' {
			    
				capture confirm variable `level'
                if !_rc {
				    display in r "`level' exists"
                        drop `level'
                }
                else {
                      sum `var' if variable ==  "`level'" 
						gen `level' = r(mean)  
						sum `level'
                }


			}
	} 

	foreach j of local taxes {
 		capture ds `j'*
		local `j'_list `r(varlist)'
		di in r "``j'_list'"
	
	}
		
	restore
	
	gen btintcch_s = tintcch_s if country == "AT" // why is this?

	foreach b of local benefits {
		cap gen `b'_alt = 0
		cap gen `b'_temp = 0

		foreach j of local `b'_list {
		    di in r "`j'"
			replace `j' = 0 if `j' == .
			replace `b'_temp = `j' if country == "`country'"
			replace `b'_alt = `b'_alt + `b'_temp if country == "`country'"
			
		}
		
	}
			
	sum *_alt ils_ben* if country == "`country'"


	foreach p of local pensions {
	    
		cap gen `p'_alt = 0
		cap gen `p'_temp = 0
		
		foreach j of local `p'_list {
		    
			replace `j' = 0 if `j' ==.
			replace `p'_temp = `j' if country == "`country'"
			replace `p'_alt = `p'_alt + `p'_temp if country == "`country'"
			
		}
		
	}

	sum p*_alt ils_pen if country == "`country'"
	
	foreach t of local taxes {
	    
		cap gen `t'_alt = 0
		cap gen `t'_temp = 0
		
		foreach j of local `t'_list {
		    
			quiet replace `j' = 0 if `j' ==.
			quiet replace `t'_temp = `j' if country=="`country'"
			quiet replace `t'_alt = `t'_alt + `t'_temp if country=="`country'"
			
		}
		
	}

	sum t*_alt ils_tax ils_sic* if country == "`country'"

	drop *_temp

	/*
	becareful: BYR is a pesnion in three c
	.	tab country group if year ==2018 & version =="I3.0+"	&	variable	=="byr"

		group
		country  ils_bennt    ils_pen      Total
		
		Belgium          0          1          1 
		Germany          1          0          1 
		Lithuania          0          1          1 
		Luxembourg          0          1          1 
		
		Total          1          3          4 

		*/
}


stop
// pool benefits, pensions and taxes in larger groups

keep country idhh idperson dgn dwt* dcb* dcz pop dag ///
	ils_be* ils_pe* ils_tax* ils_sic* *_alt

merge m:1 country using deflator, nogen

replace deflator = 1 if missing(deflator) 

drop if idhh == .

local benefits bac bca bcc bch bcr bdi bed bfa bhl bho bht ///
	bma bml bmu boa bpl brv bsa bsu bun bwk byr btin
				
foreach i of local benefits {
    
    gen `i' = 0
	
	foreach f of local countries {
	    
		replace `i' = 12 * `i'_alt * deflator if country == "`f'"
		egen `i'_total = rowtotal(`i') if country == "`f'"
		replace `i' = `i'_total if country == "`f'"
		drop `i'_total
		
	}	
	
}

local pensions pcs pdi phl pmm poa psu pyr
foreach i of local pensions {
	
    gen `i' = 0
	
	foreach f of local countries {

		replace `i' = 12 * `i'_alt * deflator if country == "`f'"
		egen `i'_total = rowtotal(`i') if country == "`f'"
		replace `i' = `i'_total if country == "`f'"
		drop `i'_total
		
	}	
	
}

local taxes tbs tcr thl tin tmu tpc tpi tpr tsc twl txc tyr
foreach i of local taxes {
	
    gen `i' = 0
	
	foreach f of local countries {
		
		replace `i' = 12 * `i'_alt * deflator if country == "`f'"
		egen `i'_total = rowtotal(`i') if country == "`f'"
		replace `i' = `i'_total if country == "`f'"
		drop `i'_total
		
	}	
	
}

drop *_alt

// compare the sum of country specific benefits (generated above) with ils - MANY DIFFERENCES!!!

egen ben_all_alt = rowtotal(b*)
egen pen_all_alt = rowtotal(p*)
egen tax_all_alt = rowtotal(t*)

gen ben_all = 12*(ils_bennt + ils_benmt)*deflator
gen pen_all = 12*(ils_pen)*deflator
egen ils_sic = rowtotal(ils_sic*)
gen tax_sic_all = 12*(ils_tax + ils_sic)*deflator
gen tax_all = 12*(ils_tax)*deflator
gen sic_all = 12*(ils_sic)*deflator
drop ils_sic

drop deflator
compress
save EU27_bpt, replace	
