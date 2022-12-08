*********************************************************************************
* 7b_ls_bootstrap.do															*
*																				*
* Last Update: 06/10/2016 E.N.													*
********************************************************************************* 

use "${path_LSscen}/5_bootstrap/bs_results_${country}_${year}_ela.dta" ///
    , clear

local exportvars "str8(ct) double"
local exportvars_par "("${COUNTRY}")"

//gen con = "${country}"

foreach variable of varlist ela_* {
    sum `variable'
    gen se_`variable' = r(sd)
    local exportvars        "`exportvars'       se_`variable'"
    local exportvars_par    "`exportvars_par'  (se_`variable')"
}

if $conpos == 1 {
    postfile se_el `exportvars' ///
        using "${path_LSscen}/5_bootstrap/se_el.dta", replace
}

// post values
post      se_el `exportvars_par'

// close postfile on last run
if $conpos == $filenames_count {
    postclose se_el
}

**
