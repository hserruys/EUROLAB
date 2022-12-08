*********************************************************************************
* 4_output.do																	*
*																				*
* Takes EM output dataset with all HH types and split into Singlem, singlef and	*
* couples file. Aggregate to HH level.											*
* Last Update: 15/07/2021 E.N.													*
*********************************************************************************

capture log close
log using "${outlog}/4_output_${country}_${year}_${choices}ch.log",replace
use "${path_LSscen}/2_postEM_appended/${country}_${year}_${choices}ch.dta", clear

keep idhh idper flex* dgn* dwt hhsize numch* dag migrant mortgage lhw_f lhw_m lhw_f_norand lhw_m_norand sec_f sec_m emp_stat_f emp_stat_m les ils_* lhw ed_* lhw_choice hhtype age* bun* *_g employee selfemployed hourly_wage  hourly_MW oecd_equiv_scale hc0*


drop if (lhw_m_norand == 5 & emp_stat_m != 0) & flex_m ==1


if "$country" == "it" {
	global keepvars="ils_dispy ils_origy ils_origrepy ils_earns ils_sicdy ils_sicee ils_sicse ils_sicer ils_sicot ils_ben ils_tax bunct02_s"	
}
if "$country" == "cy" {
	global keepvars="ils_dispy ils_origy ils_origrepy ils_earns ils_sicdy ils_sicee ils_sicse ils_sicer ils_sicot ils_ben ils_tax bunct_s"	
}
else{
	global keepvars="ils_dispy ils_origy ils_origrepy ils_earns ils_sicee ils_sicdy ils_sicse ils_sicer ils_sicot ils_ben ils_tax bun*_s"
}   

format idperson %12.0f 

set seed 670334520	

foreach ref in $new_reforms {

     if strpos("$reforms", "new") == 0{
		di in r "there are no reforms" 
	 }   
     
	if strpos("$reforms", "new") != 0 {
		di in r "there are reforms"
	
		foreach var in $keepvars{
			rename `var'_p`ref'_new `var'_p`ref'	
		}
					
				 	 
		global reform_pred ""
		
		foreach initial_ref in $reforms{
		
			if "`initial_ref'" == "base"{
				global reform_pred "p${ryear}_`initial_ref'"
				*if "$country" == "uk" global ref_index = "p${year}_`initial_ref' p${ryear}_`initial_ref'"
				 global ref_index = "p${pyear}_`initial_ref' p${ryear}_`initial_ref'"  
					
			}
			else if "`initial_ref'" == "new"  {
				 foreach new_ref in $new_reforms{
					global reform_pred "${reform_pred} p`new_ref'"
					global ref_index = "${ref_index} p`new_ref'"
				}
			}
			else {
				*if "$country" == "uk"   global ref_index = "${ref_index} p${year}_`initial_ref'" 
				global ref_index = "${ref_index} p${pyear}_`initial_ref'"  
			}
			display in r "reform_pred: ${reform_pred}"
			display in r "ref_index: ${ref_index}"
		}
	}
}


foreach ref in $ref_index {
	gen ils_sic_`ref' = 0
	foreach var in "ils_sicee" "ils_sicse" "ils_sicer" "ils_sicot"{
		quiet replace ils_sic_`ref' = ils_sic_`ref' + `var'_`ref'
		drop `var'_`ref'
	}
}

//RENAMING 
foreach ref in $ref_index {
	quiet rename bun*_`ref' bun_`ref'
}

 		/*
if $UNEMPLOYMENT_CHOICE == 1{
	foreach var of varlist ils_dispy*{
		quiet replace `var' = `var' - bun_all + bun_all/(65-dag) if lhw ==0  
	}
}*/



// Aggregate to HH income
foreach ref in $ref_index {
foreach var in ils_dispy ils_origy ils_earns ils_tax ils_ben bun ils_sic {

	bys idhh lhw_f_norand lhw_m_norand sec_f sec_m emp_stat_f emp_stat_m: egen `var'_`ref'_hh_flex = total(`var'_`ref') if flex==1
	bys idhh lhw_f_norand lhw_m_norand sec_f sec_m emp_stat_f emp_stat_m: egen `var'_`ref'_hh = total(`var'_`ref') 
	gen `var'_`ref'_hh_other = `var'_`ref'_hh - `var'_`ref'_hh_flex

}
}


*drop if flex==0
*recode lhw_m lhw_f (. = 0)

gen flex_hh_f=(inlist(flex_hh, 2, 4, 6))
gen flex_hh_m=(inlist(flex_hh, 3, 5, 7))


*drop if flex == 0 |flex==.

// drop redundant categories for singles
// this code is not necessary if counterfactual datasets dont exist for singles
foreach g in "m" "f" {
    bysort idperson lhw_`g'_norand sec_`g' emp_stat_`g' :gen index_single_`g' = _n
	drop if index_single_`g' > 1 & flex_hh_`g' ==1 
} 


drop lhw_f lhw_m


foreach x of varlist lhw ed_* lhw_choice age* {   
	foreach g in "m" "f" {
		gen `x'_`g' = 0
		replace `x'_`g' = `x' if flex_`g' == 1
		bysort idhh lhw_f_norand lhw_m_norand sec_f sec_m emp_stat_f emp_stat_m: egen `x'_`g'_min = total(`x'_`g')
		replace `x'_`g' = `x'_`g'_min
		drop `x'_`g'_min
	}
}


		
// HH types
// flex_f: flexible women, 
// flex_m: flexible men, 
// flex_hh:     1 = LS couple,  2 = LS single woman, 3 = LS single man
//                              4 =                 5 = 
//                              6 =                 7 = 
// 


*save "${path_LSscen}/2_postEM_appended/${country}_${year}_${choices}ch_full.dta", replace

/*
// this part should be programmed in the prepare_data do-file
preserve
    // Export not-flexible to append back later to make representative aggregation 
    keep if flex_hh == 0
    keep if (lhw_choice_f == lhw_f) & (lhw_choice_m == lhw_m)

save "${path_LSscen}/3_LS/${country}_${year}_${choices}ch_notflex.dta", replace
restore 
*/


tab flex_hh

*generate semiflex = (inlist(flex_hh, 4, 5))
//identification of the choice made


//generation of gender specific vars of observed choice
foreach g in "m" "f" {
	gen choice_hour_`g' = 0
	gen emp_status_`g' = 0
	gen sector_`g' = 0
	replace choice_hour_`g' = choice_g if flex_`g' == 1 
	replace emp_status_`g' = emp_status_g if flex_`g' == 1 
	replace sector_`g' = sec_g if flex_`g' == 1 
}


foreach x in "choice_hour" "sector" "emp_status"{    
	foreach g in "m" "f" {
		bysort idhh lhw_f_norand lhw_m_norand sec_f sec_m emp_stat_f emp_stat_m: egen `x'_`g'`g' = max(`x'_`g')
		replace `x'_`g' = `x'_`g'`g' if flex==1
	} 
}

foreach g in "m" "f" {
	gen ls_`g' = 0
	replace ls_`g' = 1 if choice_hour_`g' == lhw_`g'_norand & sec_`g' == sector_`g' & emp_stat_`g' == emp_status_`g' & flex ==1
}

gen ls = 0
replace ls =1 if ls_m ==1 & flex_hh_m == 1
replace ls =1 if ls_f ==1 & flex_hh_f == 1
replace ls = 1 if ls_m + ls_f ==2  & flex_hh ==1

sort idhh idperson ls_m ls_f
bysort idperson: egen check_ls=  total(ls)

assert check_ls==1 if flex ==1 & flex_hh !=0

bys idper lhw_m_norand lhw_f_norand: gen ls_x = sum(ls)

//samesex couples
bys idhh: egen checkchoi = total(choice_g) 

*drop if checkchoi == 0 & flex_hh ==1 /*to exclude samesex couples*/


quietly compress
cap mkdir $path_LSscen/3_LS

tempname totaltime
scalar `totaltime' = 80


// Generate Leisure time variable and hour dummies
foreach s in "m" "f" {
	*replace lhw_`s' = 0 if lhw_`s'_norand == 5
    gen leis_`s' = `totaltime' - lhw_`s'
	gen d_p_`s' = (inrange(lhw_`s', 10, 20))
	gen d_f_`s' = (inrange(lhw_`s', 25, 39))
    gen d_o_`s' = (inrange(lhw_`s', 40, 56))
    gen d_in_`s'   = (lhw_`s' >=  5)
	gen d_un_`s'   = (lhw_`s' >  0 & lhw_`s' <5)
	gen d_out_`s'   = (lhw_`s' ==  0)
}


// Generate sectoral dummies

foreach g in "m" "f" {
	forvalues sec = 1/${NumberOfSectors} {
		di "`sec'"
		gen sec_`sec'_`g' = (sec_`g' == `sec')
	}
}

// Generate empl status dummies
foreach g in "m" "f" {
	forvalues emp= 1/${EmplStatus}{
		gen emp_`emp'_`g' = emp_stat_`g' == `emp'
	}
}

// Generate interaction between hour dummies and sectors
foreach g in "m" "f" {
	forvalues sec= 1/${NumberOfSectors}{
		forvalues emp= 1/${EmplStatus}{
			gen dummy_`sec'_`emp'_`g' = sec_`sec'_`g' * emp_`emp'_`g'
			gen d_p_`sec'_`emp'_`g' = d_p_`g' * sec_`sec'_`g' * emp_`emp'_`g'
			gen d_f_`sec'_`emp'_`g' = d_f_`g' * sec_`sec'_`g' * emp_`emp'_`g'
			gen d_o_`sec'_`emp'_`g' = d_o_`g' * sec_`sec'_`g' * emp_`emp'_`g'
			gen d_in_`sec'_`emp'_`g' = d_in_`g' * sec_`sec'_`g' * emp_`emp'_`g'
		}
	}
}

*gen mother = idmother > 0
*gen father = idfather >0 


foreach g in "m" "f" {	
	foreach name in "numch" "numch3" "numch36" "numch6p" "migrant" "mortgage"{
		generate leis_`name'_`g' = leis_`g'*`name'
	}
} 

foreach g in "m" "f" {				
	foreach name in "leis" "age" "age2" "ed_high" "ed_middle" {
		generate leis_`name'_`g' = leis_`g'*`name'_`g'
    }
} 


gen leis_m_f = leis_m * leis_f

  
gen consum_${year} = 0



sort idperson

*save "C:\Users\NARAZANI\Desktop\data_adjusted.dta",replace
save "${path_LSscen}/3_LS/${country}_${year}_${choices}ch_LS.dta", replace

log close

*End of 4_output.do file
