program get_income_variables

//                                                          
//                                                                          
//   /$$$$$$                                                                
//  |_  $$_/                                                                
//    | $$   /$$$$$$$   /$$$$$$$  /$$$$$$  /$$$$$$/$$$$   /$$$$$$   /$$$$$$$
//    | $$  | $$__  $$ /$$_____/ /$$__  $$| $$_  $$_  $$ /$$__  $$ /$$_____/
//    | $$  | $$  \ $$| $$      | $$  \ $$| $$ \ $$ \ $$| $$$$$$$$|  $$$$$$ 
//    | $$  | $$  | $$| $$      | $$  | $$| $$ | $$ | $$| $$_____/ \____  $$
//   /$$$$$$| $$  | $$|  $$$$$$$|  $$$$$$/| $$ | $$ | $$|  $$$$$$$ /$$$$$$$/
//  |______/|__/  |__/ \_______/ \______/ |__/ |__/ |__/ \_______/|_______/ 
//                                                                          
//                                                                          
//       
        
    global income_vars ""
    global yse_vars ""
    global yem_vars ""
    global capital_vars ""
    global pen_vars ""
	global pdi_vars ""
    global bun_vars ""
	global bsa_vars "" 
	global bhl_vars "" 
	global bed_vars "" 
    global shockincs  ""
	global psu_vars "" 
	global bma_vars ""
	global yse_evaded ""

	if "${country}" == "at"{
        local income_vars "yem yemxp yse"
        local yse_vars "yse"
		gen yemxp_neg = -yemxp
        local yem_vars "yem yemxp_neg"
		gen xmp_neg = -xmp
		local capital_vars "yiy ypp01 ypp02 ypr ypt xmp_neg  yemot yot"
        local pen_vars "poa00 poacs poaot powpt"
		local psu_vars "psu bac01"
		local pdi_vars "bdi"
		gen pdimy = bdimy
		local bhl_vars "bhlot bacot bac00 bhl00"
        local bun_vars "buntr bunot buncm"
		local bsa_vars "bsa"
		local bed_vars "bed"
		local bma_vars "bma"
    }

		else if "${country}" == "be" {
        local income_vars "yem yse"
        local yse_vars "yse"
        local yem_vars "yem"
		gen xmp_neg = -xmp
		local capital_vars "yiy ypp01 ypp02 ypr ypt xmp_neg  yemot yot"
        local pen_vars "poa byr"
		local psu_vars "psu"
		local pdi_vars "pdi pdida "
		local bhl_vars "phl"
        local bun_vars "bun"
		local bsa_vars "bsa" 
		local bed_vars "bed"
		local bma_vars "bma bfapl"
		
   }
	
		else if "${country}" == "bg"{
        local income_vars "yem01 yse yempv"
        local yse_vars "yse"
        local yem_vars "yem01 yempv"
		gen xmp_neg = -xmp
		local capital_vars "yiy ypp01 ypp02 ypr ypt xmp_neg  yemot yot"
        local pen_vars "poa00 poamt"
		local psu_vars "psu"
		local pdi_vars "pdi00 pdinc pdiuc"
		local bhl_vars "bhl"
        local bun_vars "bunct bunot"
		local bsa_vars "bsa00 bsaht bsaot bsacm" 
		local edu_vars "bed"
		local bma_vars "bma bchplrs" /* noy ye here*/
		
    }

		else if "${country}" == "cy"{
        local income_vars "yem yse"
        local yse_vars "yse"
        local yem_vars "yem"
		gen xmp_neg = -xmp
		local capital_vars "yiy ypr ypt ypp xmp_neg yot"
        local pen_vars "poasp poatx poant"
		local psu_vars "psuwd psuot psuor"
		local pdi_vars "pdi"
		local bhl_vars "bhl"
        local bun_vars "bunct bunot"
		local bsa_vars "bsa" 
		local edu_vars "bedsl"
		local bma_vars "bma"
    }
	
		else if "${country}" == "cz"{
        local income_vars "yem yse"
        local yse_vars "yse"
        local yem_vars "yem"
		gen xmp_neg = -xmp
		local capital_vars "yiy ypr ypt ypp xmp_neg yot"
        local pen_vars "poa"
		local psu_vars "psu"
		local pdi_vars "pdi"
		local bhl_vars "bhl"
        local bun_vars "bunct bunot"
		local bsa_vars "bsa" 
		local edu_vars "bed"
		local bma_vars "bmact"
    }
	
		else if "${country}" == "de" {
        local income_vars "yem yse"
        local yse_vars "yse"
        local yem_vars "yem"
		gen xmp_neg = - xmp
		local capital_vars "yiy	ypr	ypt	xmp_neg	yot"
        local pen_vars "poass	poacs	poapu	poa00	poaps	poaab	poadi	poawr byr"
		local psu_vars "psuor psuwd"
		local pdi_vars "pdiss	pdica	pdi00	pdiot	pdiwr"
		local bhl_vars "bhl"
        local bun_vars "ysv	bunct	bunnc	bunot	buntr	bunls"
		local bsa_vars "bsa00 bsaoa	bsapu	bsaot" 
		local bed_vars "bed"
		local bma_vars "bma"
    }
		
		else if "${country}" == "dk" {
        local income_vars "yem yse"
        local yse_vars "yse"
        local yem_vars "yem"
		gen xmp_neg = -xmp
		local capital_vars "yiy ypp ypr ypt xmp_neg  yot"
        local pen_vars "poa00 poa01 poa02 poa03 poaot ypp"
		local psu_vars "psu"
		local pdi_vars "pdi"
		local bhl_vars "bhl"
        local bun_vars "bunct bunot bsa bsaot pyr bhtuc"
		local bsa_vars "bsaot" 
		local bed_vars "bed"
		local bma_vars "bma" /* not yet*/
    }
	
		else if "${country}" == "ee"{
		*gen yemabnt_neg = -yemabnt
        local income_vars "yem yse"
        local yse_vars "yse"
        local yem_vars "yem"
		gen xmp_neg = -xmp
		local capital_vars "yiy ypp yprro yprrt ypt xmp_neg  yot"
        local pen_vars "poa00 poaab"
		local psu_vars "psu"
		local pdi_vars "pdi pdida"
		local bhl_vars "bhl"
        local bun_vars "buntr bunnc bunct"
		local bsa_vars "bsals" 
		local bed_vars "bed"
		local bma_vars "bmaab bmact bmapr"
    }
	
		else if "${country}" == "el"{
        local income_vars "yemre yemnr ysere ysenr"
        local yse_vars "ysere ysenr"
        local yem_vars "yemre yemnr"
		gen xmp_neg = -xmpam - xmpot 
		local capital_vars "yiy ypp yprro yprrt ypt xmp_neg  yot"
        local pen_vars "poa00 poacm poaot"
		local psu_vars "psuor psuwd"
		local pdi_vars "bdi pdi"
		local bhl_vars "bhl bmact"
        local bun_vars "bunot"
		local bsa_vars "bsa" 
		local bed_vars "bed"
		local bma_vars "bmact"
    }
 
		else if "${country}" == "es"{
        local income_vars "yem yse"
        local yse_vars "yse"
        local yem_vars "yem"
		gen xmp_neg = -xmp
		local capital_vars "yiy ypr ypp ypt yot xmp_neg"
        local pen_vars "poa00 poacm poanc" /*poaot*/
		local pdi_vars "pdi00 pdinc pdicm"
		local bhl_vars "bhl00 bhlot"
        local bun_vars "bunct bunnc bunot"
		local bsa_vars "bsa" 
		local psu_vars "psuot psuwd00 psuwdcm" 
		local bed_vars "bed"
		local bma_vars "bma"
    }

 	  else if ("${country}" == "fi"){
	    local income_vars "yem yse"
        local yse_vars "yse00 yse01"  
        local yem_vars "yem"
		gen xmp_neg = -xmp
		local capital_vars "yiy ypr ypp ypt yot xmp_neg"
        local pen_vars "poaca poa00"
		local psu_vars "psu"
		local pdi_vars "pdida pdica pdi00 bhl00 bhlot"
		local bhl_vars "bhl00 bhlot"
        local bun_vars "bunnc bunct bunmt bunot"
		local bsa_vars "bsa00 bsaot" 
		local bed_vars "bed00 bedot"
		local bma_vars "bma"
    }

 		else if "${country}" == "fr"{
        local income_vars "yem00 yemxp yse"
        local yse_vars "yse"
        local yem_vars "yem00 yemxp"
		gen xmp_neg = -xmp
		local capital_vars "yiy ypr ypp ypt yot xmp_neg"
        local pen_vars "poa00"
		local psu_vars "psu"
		local pdi_vars "pdi00 bdi"
		local bhl_vars "bhl"
        local bun_vars "bunct bunmt"
		local bsa_vars "bsaot bsa00" 
		local bed_vars "bed"
		local bma_vars "bma"
    }
	
		else if "${country}" == "hr" {
        local income_vars "yem yse yemtx ysere00 ysere01 ysere02"
        local yse_vars "ysere00 ysere01 ysere02"
        local yem_vars "yemtx kfbtx"
		gen xmp_neg = -xmp00-xmpam
		local capital_vars "yiy ypr ypp ypt yot xmp_neg"
        local pen_vars "poa boa"
		local psu_vars "psu bsu"
		local pdi_vars "bdi"
		local bhl_vars "bhl"
        local bun_vars "bunct bunot"
		local bsa_vars "bsa00 bsaot" 
		local bed_vars "bed"
		local bma_vars "bma"
    }
		
		else if "${country}" == "hu"{
        local income_vars "yem yse"
        local yse_vars "yse"
        local yem_vars "yem"
		gen xmp_neg = -xmp
		local capital_vars "yiy ypr ypt ypp xmp_neg yot"
        local pen_vars "poa"
		local psu_vars "psu"
		local pdi_vars "pdi"
		local bhl_vars "bhl phl"
		local sick_vars "bhl"
        local bun_vars "bun"
		local bsa_vars "bsa" 
		local edu_vars "bed"
		local bma_vars "bma"
    }
	
		else if "${country}" == "ie" {
        local income_vars "yem yse"
        local yse_vars "yse"
        local yem_vars "yem"
		gen xmp_neg = -xmp
		local capital_vars "yiy ypr ypt ypp xmp_neg yot"
        local pen_vars "poa"
		local psu_vars "psu"
		local pdi_vars "pdi"
		local bhl_vars "bhl"
		local bun_vars "bun"
		local bsa_vars "bsa" 
		local edu_vars "bed"
		local bma_vars "bma"
    }

		else if "${country}" == "it" {
        local income_vars "yem yemtj yemnt yemxp yempv yse yseib yseil"
        local yse_vars "yse yseib yseil"
		local yse_evaded "ysenr"
        local yem_vars "yem yemtj yemxp yemnt yempv"
		gen xmp_neg = -xmp
		local capital_vars "yiy ypr ypt ypp xmp_neg yot"
        local pen_vars "poa poamt"
		local psu_vars "psu"
		local pdi_vars "pdi"
		local bhl_vars "phl"
        local bun_vars "bunct01 bunct02 bunst yunsv"
		local bsa_vars "bsa00"
		local bed_vars "bed"
		local bma_vars "bmase bmals"
		gen bunctmy = bunctmy02
		*gen bunmy = bunctmy02
		gen bun = bunct02
}
		
		else if "${country}" == "lt"{
        local income_vars "yem yse"
        local yse_vars "yse"
        local yem_vars "yem"
		gen xmp_neg = -xmp
		local capital_vars "yiy ypr ypt ypp xmp_neg yot"
        local pen_vars "boa "
		local psu_vars "bsu"
		local pdi_vars "bdi"
		local bhl_vars "bhl"
        local bun_vars "bun byr yunsv"
		local bsa_vars "bsals" 
		local bed_vars "bed"
		local bma_vars "bma"
    }
	
	else if "${country}" == "lu"{
        local income_vars "yem yse"
        local yse_vars "yse"
        local yem_vars "yem"
		gen xmp_neg = -xmp
		local capital_vars "yiy ypr ypt ypp xmp_neg yot"
        local pen_vars "poacc poaxp"
		local psu_vars "psups psupu psupups"
		local pdi_vars "pdi00 bca01 bca02 bdisv bacpm"
		local bhl_vars "bhl"
        local bun_vars "byr ysv"
		local bsa_vars "bsaot" 
		local bed_vars "bched02 bched03"
		local bma_vars "bmawk bfapl bmaba"
		
    }

	
		else if "${country}" == "lv"{
        local income_vars "yem yse"
        local yse_vars "yse"
        local yem_vars "yem"
		gen xmp_neg = -xmp
		local capital_vars "yiy ypr ypt ypp xmp_neg yot"
        local pen_vars "poass poatx"
		local psu_vars "psuss psutx"
		local pdi_vars "pdint pdiss pditx"
		local bhl_vars "bhl"
        local bun_vars "bun00 bunot"
		local bsa_vars "bsamm bsafu bsaot" 
		local bed_vars "bed"
		local bma_vars "bma"
    }
		
		else if "${country}" == "mt"{
        local income_vars "yem00 yemls yse"
        local yse_vars "yse"
        local yem_vars "yem00 yemls"
		gen xmp_neg = -xmp
		local capital_vars "yiy ypr ypt ypp xmp_neg yot"
        local pen_vars "boanc boamt poanm"
		local psu_vars "psu"
		local pdi_vars "pdi00 pdibl pdimb"
		local bhl_vars "bhlmt bhl00 bma"
        local bun_vars "bunctnm bunctmt bunncmt bunls bhl00"
		local bsa_vars "bsa" 
		local bed_vars "bed"
		local bma_vars "bma"
    }
   	
		else if "${country}" == "nl"{
        local income_vars "yem yse"
        local yse_vars "yse"
        local yem_vars "yem"
		gen xmp_neg = -xmp
		local capital_vars "yiy ypr ypt ypp xmp_neg yot"
        local pen_vars "poa00 poacm"
		local psu_vars "psu"
		local pdi_vars "pdi pdida "
		local bhl_vars "bhl"
        local bun_vars "bunct bunst"
		local bsa_vars "bsa00 bsaot bched" 
		local edu_vars "bed"
		local bma_vars "bcbma01 bcbma02"
    }
	
		
		else if "${country}" == "pl"{
        local income_vars "yem yempj yemtj yse"
        local yse_vars "yse"
        local yem_vars "yem yempj yemtj"
		gen xmp_neg = -xmp
		local capital_vars "yiy ypr ypt ypp xmp_neg yot"
		local pen_vars "poa00 poaab poafr poaot pyr"
		local psu_vars "psuor psu00 psuot"
		local pdi_vars "pdi00 pdinw"
		local bhl_vars "bhl"
        local bun_vars "bun"
		local bsa_vars "bsaot bsapm bsapmot bsatm bsatmpb" 
		local bed_vars "bed"
		local bma_vars "bma"
    }
    
	
		else if "${country}" == "pt"{
        local income_vars "yem yse"
        local yse_vars "yse"
        local yem_vars "yem"
		gen xmp_neg = -xmp
		local capital_vars "yiy ypr ypt ypp xmp_neg yot"
        local pen_vars "poact poanc"
		local psu_vars "psu"
		local pdi_vars "pdi"
		local bhl_vars "bhl"
        local bun_vars "bun"
		local bsa_vars "bsa" 
		local bed_vars "bed"
		local bma_vars "bma"
    }
   
	
		else if "${country}" == "ro"{
        local income_vars "yem yse"
        local yse_vars "yse"
        local yem_vars "yem"
		gen xmp_neg = -xmp
		local capital_vars "yiy ypr ypt ypp xmp_neg yot"
        local pen_vars "poa"
		local psu_vars "psu"
		local pdi_vars "pdi00 bdi"
		local bhl_vars "bhl"
        local bun_vars "yunsv"
		local bsa_vars "bsa" 
		local bed_vars "bed"
		local bma_vars "bma"
    }

		else if "${country}" == "se"{
        local income_vars "yem yse"
        local yse_vars "yse"
        local yem_vars "yem"
		gen xmp_neg = -xmp
		local capital_vars "yiy ypr ypt ypp xmp_neg yot"
        local pen_vars "poa"
		local psu_vars "psu"
		local pdi_vars "pdi"
		local bhl_vars "bhl bpl"
        local bun_vars "bun"
		local bsa_vars "bsa" 
		local edu_vars "bed"
		local bma_vars "bma"
    }
	
		else if "${country}" == "si"{
        local income_vars "yem yse"
        local yse_vars "yse"
        local yem_vars "yemtx yemnt yaj"
		local capital_vars "yiy"
        local pen_vars "poa00 pls psact"
		local psu_vars "psu00"
		local pdi_vars "bdi"
		 capture gen pdimy = bdimy
		local pdi_vars "pdi00 bdica bdixp bdirw"
		local bhl_vars "bhl bmact"
        local bun_vars "bunct"
		local bsa_vars "bsa00 bsacm bsaot bsapm" 
		local bed_vars "bed"
		local bma_vars "bmact"
    }

		else if "${country}" == "sk" {
        local income_vars "yemwg yemtj yemaj yemot yemab yse"
        local yse_vars "yse"
        local yem_vars "yemwg yemtj yemaj yemot yemab"
		gen xmp_neg = -xmp
		local capital_vars "yiy ypr ypt ypp xmp_neg yot"
        local pen_vars "poa"
		local psu_vars "psu"
		local pdi_vars "pdi pdida "
		local bhl_vars "bhl"
        local bun_vars "bun"
		local bsa_vars "bsa" 
		local bed_vars "bed"
		local bma_vars "bma"
    }
	 else if ("${country}" == "uk")  {
        local income_vars "yem yse" 
        local yse_vars "yse"
        local yem_vars "yem"
		gen xmp_neg = -xmp
		local capital_vars "yiy ypr ypt ypp xmp_neg yot"
		local pdi_vars "bdisc  bdimb  bdiscwa bdimbwa bdict01  bdict02 bdiw bcrdi bdisv"
		local psu_vars "bsuwd"
		local bhl_vars "bhlwk"
        local pen_vars "boawr boactcm boact00"
        local bun_vars "buntr"
		local bsa_vars "bsa"
		local bed_vars "bedes bedsl"
		local bma_vars "bmaer bmana"

        // maybe:
        replace lhw = lhw00 // lhw00 = work as employee
        generate yemmy = liwwh
        generate ysemy = liwwh
		
    }
    else {
        local income_vars ""
        local yse_vars ""
        local yem_vars ""
        local capital_vars ""
        local pension_vars ""
        local bun_vars ""
		local bma_vars ""
    }

    global income_vars "`income_vars'"
    global yse_vars "`yse_vars'"
    global yem_vars "`yem_vars'"
    global capital_vars "`capital_vars'"
    global pen_vars "`pen_vars'"
	global pdi_vars "`pdi_vars'"
	*global origy_vars "`origy_vars'"
    global bun_vars "`bun_vars'"
	global bsa_vars "`bsa_vars'"
	global bhl_vars "`bhl_vars'"
	global bed_vars "`bed_vars'"
	global psu_vars "`psu_vars'"
	global bma_vars "`bma_vars'"
	global yse_evaded "`yse_evaded'"
    global shockincs "`income_vars' `capital_vars'"
  

end


	
	
**
