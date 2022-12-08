///Finds values of parameters v and u under EQUILIBRIUM conditions
capture program drop GUMBEL
program define GUMBEL
	set trace off
	version 17
	tempvar U_dummy U_consum U_leis_m try idtry U_leis_f U U_max nom denom_c denom_m denom_f p_iter lhw_pred_m lhw_pred_f U_max rand_m rand_f rand U_dif

	tempname v v_m v_f yh ore_m_p ore_f_p ore_m_z ore_f_z

	{
		gen `rand_m' = -ln(-ln(runiform()))
		*exp(-`v_m' -exp(-`v_m'))
		gen `rand_f' = -ln(-ln(runiform()))
		gen  `try' = 0
		*exp(-`v_f' -exp(-`v_f'))
		
		di in r "here is the error"
		sum `rand_m'
		quiet gen `p_iter' = .
		
		// Loop over HH type
		foreach type in  "couples" "singm" "singf" {
					
			if "`type'" == "couples" {
				local sex "m f"
				local condition "if inlist(flex_hh, 1) & flex_m == 1"

				quiet estread using "${path_results}/estimation/${country}_${year}_clogit_`type'_${choices}ch.sters"
				estimates restore clogit_`type'_${country}_${year}
				
		
				if "$country" == "lv"|"$country" == "cz" {
					scalar unconst_m  = 0 
					scalar unconst_f  = 0
				}
				else {
					scalar unconst_m  =  _b[d_p_m_unconst]  
					scalar unconst_f  =  _b[d_p_f_unconst]  
				}
				if $UNEMPLOYMENT == 1 {
					quiet  gen double `U_dummy'= d_in_m*`d_in_m' + d_in_f*`d_in_f'+ d_un_m*`d_un_m' + d_un_f*`d_un_m' + d_p_m*_b[d_p_m] + d_p_f*_b[d_p_f] + d_f_m*_b[d_f_m] +  d_f_f*_b[d_f_f]  `condition'
				}		
				if $UNEMPLOYMENT != 1 {
					quiet  gen double `U_dummy'= d_in_m*_b[d_in_m] + d_in_f*_b[d_in_f]+ d_p_m*_b[d_p_m] + d_p_f*_b[d_p_f] + d_f_m*_b[d_f_m] +  d_f_f*_b[d_f_f]  `condition'
				}
				quiet  gen double `U_consum' = consum *(_b[consum] + consum *_b[consum_consum] + leis_m*_b[consum_leis_m] + leis_f*_b[consum_leis_f] + hhsize*_b[consum_hhsize]) `condition'
				quiet  gen double `U_leis_m' = leis_m*_b[leis_m] + leis_leis_m*_b[leis_leis_m] + leis_age_m*_b[leis_age_m] + leis_age2_m*_b[leis_age2_m] + leis_numch_m*_b[leis_numch_m] + leis_numch3_m*_b[leis_numch3_m]+ leis_numch36_m*_b[leis_numch36_m] + leis_mortgage_m*_b[leis_mortgage_m] + leis_migrant_m*_b[leis_migrant_m] + leis_m_f*_b[leis_m_f]  `condition'
				quiet  gen double `U_leis_f' = leis_f*_b[leis_f] + leis_leis_f*_b[leis_leis_f] + leis_age_f*_b[leis_age_f] + leis_age2_f*_b[leis_age2_f] + leis_numch_f*_b[leis_numch_f] + leis_numch3_f*_b[leis_numch3_f] + leis_numch36_f*_b[leis_numch36_f] + leis_mortgage_f*_b[leis_mortgage_f] + leis_migrant_f*_b[leis_migrant_f] `condition'
				
				gen double `U'=`U_dummy' + `U_consum' + `U_leis_m'+ `U_leis_f' `condition'
				bys idper: egen `U_max' = max(`U')
				replace `try' = 1 `condition' & `U_max' > `U' & ls ==1
				bys idper:egen `idtry' = total(`try')
				tab `idtry'
				quiet  replace `U' = 	`U_dummy' + `U_consum' + `U_leis_`sex'' + `rand_m' + `rand_f' `condition' & `idtry'==1
			
				quiet  gen double `nom' = 	exp(`U') `condition'
				bysort idperson: egen double `denom_c'=sum(`nom') `condition'
				quiet  replace `p_iter' = `nom'/`denom_c' `condition' //new probabilities
				gen `U_dif' = `U_max' - `U' 
				drop `U_max' `idtry'
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
				
				quiet estread using "${path_results}/estimation/${country}_${year}_clogit_`type'_${choices}ch.sters"
				estimates restore clogit_`type'_${country}_${year}
				if "$country" == "lv"|"$country" == "cz" {
					scalar unconst_`sex'  = 0 
				}
				else {
					scalar unconst_m  =  _b[d_p_`sex'_unconst]  
				}
				
				//CHANGE OF dummies coeficcients BASED ON PARAMETER V and u
				
				if $UNEMPLOYMENT == 1 {
					quiet  replace `U_dummy'= d_in_`sex'*`d_in_`sex'' + d_un_`sex'*`d_un_`sex'' + d_p_`sex'*_b[d_p_`sex'] + d_f_`sex'*_b[d_f_`sex']  `condition'
				}				
				if $UNEMPLOYMENT != 1 {
					quiet  replace `U_dummy'= d_in_`sex'*_b[d_in_`sex'] + d_p_`sex'*_b[d_p_`sex'] + d_f_`sex'*_b[d_f_`sex']  `condition'
				}			
				quiet  replace `U_consum' = consum*(_b[consum] + consum*_b[consum_consum] + leis_`sex'*_b[consum_leis_`sex'] + hhsize *_b[consum_hhsize]) `condition'
										
				quiet  replace `U_leis_`sex'' = leis_`sex'*_b[leis_`sex'] + leis_leis_`sex'*_b[leis_leis_`sex'] + leis_age_`sex'*_b[leis_age_`sex'] + leis_age2_`sex'*_b[leis_age2_`sex'] + leis_numch_`sex'*_b[leis_numch_`sex'] + leis_numch3_`sex'*_b[leis_numch3_`sex']+ leis_numch36_`sex'*_b[leis_numch36_`sex'] + leis_mortgage_`sex'*_b[leis_mortgage_`sex'] + leis_migrant_`sex'*_b[leis_migrant_`sex']  `condition'
				
				replace `U'=`U_dummy' + `U_consum' + `U_leis_`sex'' `condition'
				bys idper: egen `U_max' = max(`U')
				replace `try' = 1 `condition' & `U_max' > `U' & ls ==1
				bys idper:egen `idtry' = total(`try')
				sum `U'  `condition' & `idtry'==1
				quiet  replace `U' = 	`U_dummy' + `U_consum' + `U_leis_`sex'' +  `rand_`sex'' `condition' & `idtry'==1
				sum `U'  `condition' & `idtry'==1
				quiet  replace `nom' = 	exp(`U') `condition'

				bysort idperson: egen double `denom_`sex''=sum(`nom') `condition'
				quiet  replace `p_iter' = `nom'/`denom_`sex'' `condition' //new probabilities
				replace `U_dif' = `U_max' - `U' 
				drop `U_max' `idtry'
			}	
		}
			
		local sex "m f"
		foreach g of local sex {
			bys idperson:  egen double `lhw_pred_`g'' = total(`p_iter' * lhw_`g') 
		}
		
	tabstat `lhw_pred_f' if flex_f==1 & ls ==1, by(choice_hour_f)  stat(mean n) save
	scalar `ore_f_z' = r(Stat1)[1,1]
	scalar `ore_f_p' = r(Stat4)[1,1]

	tabstat `lhw_pred_m' if flex_m==1  & ls ==1, by(choice_hour_m)   stat(mean n) save
	scalar `ore_m_z' = r(Stat1)[1,1]
	scalar `ore_m_p' = r(Stat4)[1,1]
	
	sum `U_dif' if ls ==1 
	}
	
end


///Finds values of parameters v and u under EQUILIBRIUM conditions
capture program drop EXTREME
program define EXTREME
	set trace off
	version 17
	tempvar rand U_dummy U_consum try idtry U_leis_m U_leis_f U U_max nom denom_c denom_m denom_f p_iter lhw_new_m lhw_new_f lhw_pred_m lhw_pred_f rand_m rand_f U_max 

	tempname v v_m v_f yh ore_m_p ore_f_p ore_m_z ore_f_z

	{
		scalar `v' = `1'[1,1]
		scalar `v_m' = `1'[1,2]
		scalar `v_f' = `1'[1,3]
		
		*gen `rand' = 2-`v'* ln(-ln(runiform()))
		gen `rand' = exp(-`v' -exp(-`v'))
		*gen `rand_m' = 1-`v_m'* ln(-ln(runiform()))
		gen `rand_m' = exp(-`v_m' -exp(-`v_m'))
		*gen `rand_f' = 1-`v_f'*ln(-ln(runiform()))
		gen `rand_f' = exp(-`v_f' -exp(-`v_f'))
	
	di in r "how error_m is distributed"
		sum `rand' `rand_m' `rand_f'
		quiet gen `p_iter' = .
		gen  `try' = 0
				
		// Loop over HH type
		foreach type in  "couples" "singm" "singf" {
					
			if "`type'" == "couples" {
				local sex "m f"
				local condition "if inlist(flex_hh, 1) & flex_m == 1"

				quiet estread using "${path_results}/estimation/${country}_${year}_clogit_`type'_${choices}ch.sters"
				estimates restore clogit_`type'_${country}_${year}
				
		
				if "$country" == "lv"|"$country" == "cz" {
					scalar unconst_m  = 0 
					scalar unconst_f  = 0
				}
				else {
					*scalar unconst_m  =  _b[d_p_m_unconst]  
					*scalar unconst_f  =  _b[d_p_f_unconst]  
				}
				if $UNEMPLOYMENT == 1 {
					quiet  gen double `U_dummy'= d_in_m*`d_in_m' + d_in_f*`d_in_f'+ d_un_m*`d_un_m' + d_un_f*`d_un_m' + d_p_m*_b[d_p_m] + d_p_f*_b[d_p_f] + d_f_m*_b[d_f_m] +  d_f_f*_b[d_f_f]  `condition'
				}		
				if $UNEMPLOYMENT != 1 {
					quiet  gen double `U_dummy'= d_in_m*_b[d_in_m] + d_in_f*_b[d_in_f]+ d_p_m*_b[d_p_m] + d_p_f*_b[d_p_f] + d_f_m*_b[d_f_m] +  d_f_f*_b[d_f_f]  `condition'
				}
				quiet  gen double `U_consum' = consum *(_b[consum] + consum *_b[consum_consum] + leis_m*_b[consum_leis_m] + leis_f*_b[consum_leis_f] + hhsize*_b[consum_hhsize]) `condition'
				quiet  gen double `U_leis_m' = leis_m*_b[leis_m] + leis_leis_m*_b[leis_leis_m] + leis_age_m*_b[leis_age_m] + leis_age2_m*_b[leis_age2_m] + leis_numch_m*_b[leis_numch_m] + leis_numch3_m*_b[leis_numch3_m]+ leis_numch36_m*_b[leis_numch36_m] + leis_mortgage_m*_b[leis_mortgage_m] + leis_migrant_m*_b[leis_migrant_m] + leis_m_f*_b[leis_m_f]  `condition'
				quiet  gen double `U_leis_f' = leis_f*_b[leis_f] + leis_leis_f*_b[leis_leis_f] + leis_age_f*_b[leis_age_f] + leis_age2_f*_b[leis_age2_f] + leis_numch_f*_b[leis_numch_f] + leis_numch3_f*_b[leis_numch3_f] + leis_numch36_f*_b[leis_numch36_f] + leis_mortgage_f*_b[leis_mortgage_f] + leis_migrant_f*_b[leis_migrant_f] `condition'
				
				
				gen double `U'=`U_dummy' + `U_consum' + `U_leis_m'+ `U_leis_f' `condition'
				bys idper: egen `U_max' = max(`U') `condition'
				replace `try' = 1 `condition' & `U_max' > `U' & ls ==1
				bys idper:egen `idtry' = total(`try') `condition'
				di in r "last check"
				count `condition' & `U_max' > `U' & ls ==1
				count `condition' & `U_max' < `U' & ls ==1
				quiet  replace `U' = `U_dummy' + `U_consum' + `U_leis_`sex'' + `rand' `condition' & `idtry'==1
			    count `condition' & `U_max' > `U' & ls ==1
				quiet  gen double `nom' = 	exp(`U') `condition'
				bysort idperson: egen double `denom_c'=sum(`nom') `condition'
				quiet  replace `p_iter' = `nom'/`denom_c' `condition' //new probabilities
				drop `U_max' `idtry'
				sum `p_iter' `condition'
						local sex "m f"
			foreach g of local sex {
			bys idperson:  egen double `lhw_new_`g'' = total(`p_iter' * lhw_`g')    `condition'
			gen `lhw_pred_`g'' = `lhw_new_`g''  `condition'
			drop `lhw_new_`g''

		}
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
				
				quiet estread using "${path_results}/estimation/${country}_${year}_clogit_`type'_${choices}ch.sters"
				estimates restore clogit_`type'_${country}_${year}
				if "$country" == "lv"|"$country" == "cz" {
					scalar unconst_`sex'  = 0 
				}
				else {
					*scalar unconst_m  =  _b[d_p_`sex'_unconst]  
				}
				
				//CHANGE OF dummies coeficcients BASED ON PARAMETER V and u
				
				if $UNEMPLOYMENT == 1 {
					quiet  replace `U_dummy'= d_in_`sex'*`d_in_`sex'' + d_un_`sex'*`d_un_`sex'' + d_p_`sex'*_b[d_p_`sex'] + d_f_`sex'*_b[d_f_`sex']  `condition'
				}				
				if $UNEMPLOYMENT != 1 {
					quiet  replace `U_dummy'= d_in_`sex'*_b[d_in_`sex'] + d_p_`sex'*_b[d_p_`sex'] + d_f_`sex'*_b[d_f_`sex']  `condition'
				}			
				quiet  replace `U_consum' = consum*(_b[consum] + consum*_b[consum_consum] + leis_`sex'*_b[consum_leis_`sex'] + hhsize *_b[consum_hhsize]) `condition'
										
				quiet  replace `U_leis_`sex'' = leis_`sex'*_b[leis_`sex'] + leis_leis_`sex'*_b[leis_leis_`sex'] + leis_age_`sex'*_b[leis_age_`sex'] + leis_age2_`sex'*_b[leis_age2_`sex'] + leis_numch_`sex'*_b[leis_numch_`sex'] + leis_numch3_`sex'*_b[leis_numch3_`sex']+ leis_numch36_`sex'*_b[leis_numch36_`sex'] + leis_mortgage_`sex'*_b[leis_mortgage_`sex'] + leis_migrant_`sex'*_b[leis_migrant_`sex']  `condition'
				
				replace `U'=`U_dummy' + `U_consum' + `U_leis_`sex'' `condition'
				bys idper: egen `U_max' = max(`U') `condition'
				replace `try' = 1 `condition' & `U_max' > `U' & ls ==1
				count `condition' & `U_max' > `U' & ls ==1
				bys idper:egen `idtry' = total(`try') `condition'
				sum `U'  `condition' & `idtry'==1
				quiet  replace `U' = 	`U_dummy' + `U_consum' + `U_leis_`sex'' +  `rand_`sex'' `condition' & `idtry'==1
				sum `U'  `condition' & `idtry'==1
				count `condition' & `U_max' > `U' & ls ==1
				bysort idperson: egen double `denom_`sex''=sum(`nom') `condition'
				quiet  replace `p_iter' = `nom'/`denom_`sex'' `condition' //new probabilities
				drop `U_max' `idtry'
				bys idperson:  egen double `lhw_new_`sex'' = total(`p_iter' * lhw_`sex')   `condition'
				replace `lhw_pred_`sex'' = `lhw_new_`sex'' `condition'
				drop `lhw_new_`sex''
				tabstat `lhw_pred_`sex'' `condition', by(choice_hour_`sex')  stat(mean n) save
			}	
		}
			
		
	tabstat `lhw_pred_f' if flex_f==1 & ls ==1, by(choice_hour_f)  stat(mean n) save
	scalar `ore_f_z' = r(Stat1)[1,1]
	scalar `ore_f_p' = r(Stat4)[1,1]

	tabstat `lhw_pred_m' if flex_m==1  & ls ==1, by(choice_hour_m)   stat(mean n) save
	scalar `ore_m_z' = r(Stat1)[1,1]
	scalar `ore_m_p' = r(Stat4)[1,1]
	
	*scalar `yh'= -r(mean)
	scalar `yh'= - -(`ore_m_z')^2-(`ore_f_z')^2
	*(`ore_f_p'-44)^2- (`ore_m_p'-44)^2
	
	scalar list `yh'

	}
	
	scalar `2'=`yh' 


end
