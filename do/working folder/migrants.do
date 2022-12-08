*********************************************************************************
***************** SILC DATA MERGED WITH INPUT DATA AND OUTPUT DATA **************
*********************************************************************************
global path_SILC_data 	"R:\B2\05 - Databases\06 - EU SILC\EU-SILC - Cross_merged_data\Cross"
global path_EMinput	 "R:\B2\01 - Households\10 - Labour supply model\02 - Working area\02 - Model\EUROLAB\data\EMinput"
global year = "2019"

/*
cd "${path_EMinput}/original"
local allfiles : dir . files "*.txt"

qui foreach file of local allfiles {
	di in r "`file'"
	local country=substr("`file'", 1,10)
	local cnt = substr("`file'",1,2)
	local year = substr("`file'",4,7)
	local fil = substr("`file'",9,10)
	*di in r "fil"
	
    local CNT = upper("`cnt'")	
	*noi di "`country'"
	noi di "`cnt'"
	*noi di "`CNT'"
	local clist_dups `clist_dups' `country'	
	*local ylist_dups `ylist_dups' `year'
	local CNTlist `CNTlist' `CNT'	
}

*/
local allfiles : dir . files "*.txt"
foreach file of local allfiles {

di "`file'"
 global country = substr("`file'",1,2)
 
	local name = "2020-11"
	if "${country}" == "fi"|"${country}" == "pt"|"${country}" == "ee" local name = "pre-release" 
	if "${country}" == "hu"|"${country}" == "ie"|"${country}" == "pl" local name = "2018-04"
			
	use "${path_SILC_data}\\${country}\\${year}\\${country}-SILC-${year}-version_`name'.dta",clear

	if "${country}" == "es"{
		gen idorigperson = idperson
		local var_merge "idorigperson"
	}
	else if "${country}" == "at" {
		gen double idperson_o = idperson
		local var_merge  "idperson_o"
	}		
	else if "${country}" == "it" {
		use "${path_SILC_data}\\${country}\\${year}\\${country}-SILC${year}-01a.dta",clear
		local var_merge  "idperson"
	}	
	else if "${country}" == "cz"{
		format idperson %12.0f 
		rename idperson idorigperson
		local var_merge  "idorigperson"
	}
		
	else {
		local var_merge  "idperson"
	}
	
	local var_care "rb070 rb080 hb060 hb050 rb080 rb070 rl010 rl020 rl030 rl040 rl050 rl060 rl070"/*hc050  hc060*/
	local var_silc "rb031 rb230 pl060 pl100 pl073 pl075 pl074 pl076 pl080 pl040 pl020 pl085 pl087 pl086 pl090 pl089 pl120"

	keep idhh idperson `var_merge' `var_care' `var_silc' 
	
	tempfile udb
	*sort idhh idperson
	save `udb'
	di in r "${path_EMinput}"
	quiet insheet using "${path_EMinput}/original/`file'", clear
	
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
}


