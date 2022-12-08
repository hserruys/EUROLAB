program emprep_inc

    args country

    if "`country'" == "" {
        di as error "No country specified."
    }
	
	if ("`country'") == "at" {
       capture replace replace yemtx = 0 if flex==1
	}
	
	if ("`country'") == "bg" {
       capture replace replace yem01 = yem if flex==1
	}
	
	if ("`country'") == "cy" {
        replace bfa = bfa - bma_all if flex==1
    }
	
    if ("`country'") == "de" {
        replace yemse = yem + yse
    }
    if ("`country'") == "el" {
        replace yemre = yem if flex ==1
        *replace yemnr = 0 if flex==1
		*replace ysenr = 0 if flex==1
		replace ysere = yse if flex==1
    }
    if ("`country'") == "ee" {
        replace yse   = ysera + ysena
		*replace yemabnt = 0 if flex ==1
    }
	
	    if ("`country'") == "fr" {
        replace yem00  = yem if flex ==1
		replace yemxp = 0 if flex ==1
    }
	    if ("`country'") == "fi" {
        capture replace yse00= 0 if flex ==1
		capture replace yse01= 0 if flex ==1
	        
    }
    // Correct Aggregates
    if ("`country'") == "it" {
	replace yseev = yse if flex_f==1 |flex_m ==1
        replace yiydv   = yiy  if flex==1
        replace yiyitdp = 0  if flex==1
        replace yiyitob = 0 if flex==1
        replace yiyitsb = 0 if flex==1
		replace yemtj = 0 if flex ==1
		replace yemxp = 0 if flex==1 
		replace yempv = 0 if flex==1
		replace bunctmy02 = bunctmy if flex ==1
		
    }
    if ("`country'") == "lv" {
        *replace yem00 == yem
    }
    if ("`country'") == "pl" {
        replace yse   = yseag + ysebs if flex==1
		*replace yem   = yempj + yemtj
    }
    if ("`country'") == "mt"{
        replace yem00 = yem
        *replace yem = yem00 + yemls
        *replace yem = 0
        replace yemls = 0 if flex==1
    }    
    if ("`country'") == "fr" {
       capture replace yem00 = yem if flex==1
       capture replace yem_hour = 0 if flex==1
       capture replace yemxp = 0 if flex==1
    }
    if ("`country'") == "dk" {
       
    }
	
	if ("`country'") == "hr" {
       replace yemtx = yem if flex ==1
	   replace kfbtx = 0 if flex==1
	   
	   sum yemtx yem kfbtx if flex ==1
    }
    if ("`country'") == "pl" {
       capture replace yempj = yem if flex==1
	   capture replace yemtj = 0 if flex==1
    }	
		
	
	if ("`country'") == "ro" |("`country'") == "ee"|("`country'") == "sk" {
        *replace bfa = bfa - bma_new if flex==1
    }
	
    if ("`country'") == "sk" {
        replace yemwg = yem if flex ==1 
		replace yemwg = 0 if flex ==1
		replace yemtj = 0 if flex ==1
		replace yemaj = 0 if flex ==1
		replace yemot = 0 if flex ==1
        replace yemab = 0 if flex ==1
    }
    if ("`country'") == "si" {
        capture replace yemtx = yem if flex ==1
        capture replace yemnt = 0 if flex ==1
		capture replace yaj = 0 if flex ==1
		capture replace yemaj = 0 if flex ==1
		        
    }
    /*


    if ${STABILIZER_MODE} == 1 {
    *local income_variables "yem `yvars'"
    *foreach income_variable in `income_variables' {
    * replace `income_variable' = 0.99 * `income_variable'
    *}

    if  "`country'" == "ie" | "`country'" == "lu" | "`country'" == "ro" {
    local income_vars "yem yse yiy ypt yprrt"
    }
    if "`country'" == "ee" | "`country'" == "el" | "`country'" == "lt"  {
    local income_vars "yem yse yiy ypt ypr yprrt"
    }
    else if "`country'" == "fi" local income_vars "yem yse00 yse01 yiy ypr"
    else if "`country'" == "it" local income_vars "yem yemtj yemxp yiy ypr yse yempv"
    else if "`country'" == "mt" local income_vars "yem yse yls yiy ypr"
    else if "`country'" == "pl" local income_vars "yem yseag ysebs yiy ypr"
    else if "`country'" == "uk" local income_vars "yem yse yot01 yiy ypr"
    else if "`country'" == "sk" local income_vars "yemwg yemcs yemtj yemaj yemot yse yiy ypr"
    else if "`country'" == "si" local income_vars "yemtx yemnt yse yaj yprrt yst yiy"
    else local income_vars "yem yse yiy ypr"

    * Use only labor income variables? -> yes
    local income_vars "yem `yvars'"

    foreach var of local income_vars {
    **foreach var of varlist yem `yvars' {
    /*
    if "`country'" == "lv" {
    replace `var' = `var' * 0.82
    }
    else if "`country'" == "lt" {
    replace `var' = `var' * 0.85
    }
    else if "`country'" == "ee" {
    replace `var' = `var' * 0.86
    }
    else if "`country'" == "fi" {
    replace `var' = `var' * 0.91
    }
    else if "`country'" == "si" {
    replace `var' = `var' * 0.92
    }
    else if "`country'" == "hu" {
    replace `var' = `var' * 0.93
    }
    else if "`country'" == "dk" |  "`country'" == "ro" {
    replace `var' = `var' * 0.94
    }
    else if "`country'" == "bg" | "`country'" == "de" | "`country'" == "cz" | "`country'" == "ie" | "`country'" == "it" | "`country'" == "lu" | "`country'" == "se" | "`country'" == "sk"  {
    replace `var' = `var' * 0.95 //0.95
    }
    else if "`country'" == "at" | "`country'" == "nl" | "`country'" == "es" | "`country'" == "uk" {
    replace `var' = `var' * 0.96
    }
    else if "`country'" == "be" | "`country'" == "fr" | "`country'" == "el" | "`country'" == "mt" | "`country'" == "pt" {
    replace `var' = `var' * 0.97
    }
    else if "`country'" == "cy" {
    replace `var' = `var' * 0.98
    }
    else if "`country'" == "pl" {
    replace `var' = `var' * 1.02
    }
    */

    replace `var' = `var' * 0.95  // 1 percent shock for all
    }
    ** Aggregate certain country specific variables so Euromod won't show errors.
    if ("`country'") == "de" {
    replace yemse = yem + yse
    }
    if ("`country'") == "si" {
    replace yemtx = yem
    }
    if ("`country'") == "sk" {
    *replace yem = yemwg + yemcs + yemtj + yemot + yemaj
    replace yemwg = yem
    replace yemcs = 0
    replace yemtj = 0
    replace yemot = 0
    replace yemaj = 0
    }  
    if ("`country'") == "nl" {  // bunct should be zero anyway?
    *replace bunct = bun
    }
    if ("`country'") == "it" {
    replace yiydv   = yiy 
    replace yiyitdp = 0 
    replace yiyitob = 0
    replace yiyitsb = 0
    }
    if ("`country'") == "pl" {
    replace yse   = yseag + ysebs
    *replace yempj = yem
    }
    if ("`country'") == "ee" {
    replace yse = ysera + ysena
    }



    outsheet `varlist' using "${path_LSscen}/1_EMinput/`country'_`year'_${choices}ch_baseline_shock.txt" , replace

    use "${path_EMinput}/`country'_`year'_${choices}ch_baseline_full.dta", clear

    * first, make them inactive:
    * change loc/lin
    quiet replace loc = -1 if lhw==0  & isadult==1 
    quiet replace lin = -1 if lhw==0  & isadult==1 
    * quiet replace lfs=-1 if lhw==0  & isadult==1 
    * set les to 7 (inactive) at zero hours
    quiet replace les=7 if lhw==0  & isadult==1 // & les!=5
    * NOTE: everybody is classified as inactive at zero hour

    noi foreach var of varlist /*`yvars'*/ yem {
    replace `var' = 0 if lhw == 0
    } 

    forvalues iteration = 1/2 {
    if `iteration' == 1 {
    preserve
    foreach var of local income_vars {
    replace  `var' = `var' * 1.03 // 0.99
    }
    }
    if `iteration' == 2 {
    restore
    foreach var of local income_vars {
    replace `var' = `var' * 0.95 * 1.03
    }
    }

    ** Aggregate certain country specific variables so Euromod won't show errors.
    if ("`country'") == "de" {
    replace yemse = yem + yse
    }
    if ("`country'") == "si" {
    replace yemtx = yem
    }
    if ("`country'") == "sk" {
    *replace yem = yemwg + yemcs + yemtj + yemot + yemaj
    replace yemwg = yem
    replace yemcs = 0
    replace yemtj = 0
    replace yemot = 0
    replace yemaj = 0
    }  
    if ("`country'") == "nl" {  // bunct should be zero anyway?
    *replace bunct = bun
    }
    if ("`country'") == "it" {
    replace yiydv   = yiy 
    replace yiyitdp = 0 
    replace yiyitob = 0
    replace yiyitsb = 0
    }
    if ("`country'") == "pl" {
    replace yse   = yseag + ysebs
    *replace yempj = yem
    }
    if ("`country'") == "ee" {
    replace yse = ysera + ysena
    }

    outsheet `varlist' /*alpha*/ using "${path_LSscen}/1_EMinput/`country'_`year'_${choices}ch_mtr`iteration'.txt" , replace
    }

    } // STABILIZER_MODE

    */

end

**
