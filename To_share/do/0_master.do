*********************************************************************************
* File 0_master.do																*
* Contains settings and paths.										        	*
* Last update: 11/03/21	B.P.													*						
*********************************************************************************

*- Initialize 
set trace off
clear all
adopath + "./ado"
adopath + "./lib"
adopath + "."
version 16

statainit
getwine

/********************************************************************************
Read parameters from the excel file and generate local and global macros
*********************************************************************************/
import excel "configuration.xlsm", sheet("Arguments") cellrange(C6:E46) firstrow  case(lower) allstring clear
local n=_N
forvalues i=1/`n'{
	local macro_name=local_macro[`i']
	if "`macro_name'"!=""{
		local `macro_name'=value[`i']		//Create local macros
		local parameter=parameter[`i']
		global `parameter'="``macro_name''"		//Create global macros
		di in r "`parameter'=$`parameter'"		
	}
}

******** SET OTHER GLOBAL PARAMETERS ************************************************
global update_excel_systems = 1

// Own Stata uprating (uprateit)
global account "hicp"

// Countries / Filenames
global ryear    = substr("${new_reforms}",1,4)
global year    = substr("${filenames}",4,4) //survey year
global pyear = $year - 1		//income year
global filenames_count  : list sizeof global(filenames)

if ${PREPAREDATA} == 1 global run_baseline_income_year = 1
else global run_baseline_income_year = 0

di in r "$ryear"
di in r "$new_reforms"
di in r "$reforms"

//Sectors and number of sectors
global NumberOfSectors=${SECTORS}
global EmplStatus=${EMPL_STATUS}

//Set number of STATA instances to be used to merge and append datasets
global split_number_STATA=8
global split_number_EM=8

// Bootstrap locals and preparations
global reps = 50 //100  // Number of BS repetitions
global bs   = 0
global dist "EMP"   // Distribution

// Color and file extension of graphs
global scheme s1mono //s1mono vg_s2m
global ext "$file_ext"  // pdf (Win) or png (Unix)
global max_dude_iter 10
global coefrand "none"   // all = cons and l1, l2
                        // cons = cons
                        // none = none

*- Reforms
*- base: baseline. Incomes are left unchanged
*- m: Male income increased by 1 percent
*- f: Female income increased by 1 percent
*- i: Capital income increased by 1 percent
*- new_pol: New policy

* For estimation of utilities and calculation of elasticities*
* global reforms "base m f" 
* when policy effects of new reform are to be assessed 
global reform_pred ""
foreach initial_ref in $reforms{

	if "`initial_ref'" == "base"{
		global reform_pred "p${ryear}_`initial_ref'"					
	}
	else if "`initial_ref'" == "new"  {
		 foreach new_ref in $new_reforms{
			global reform_pred "${reform_pred} p`new_ref'"
		}
	}
	display in r "reform_pred: ${reform_pred}"
}

***** SET PATHS AND CREATE FOLDERS ********************************* 
global required_ados_ssc "matsave estwrite outtex sencode"
global required_ados_net "lslogit grc1leg clogitp selmlog"
install_required_ados

set seed 882750845

datewfmt

make_folders	//If they don't exist

global path_init="`path_init'"
cd "${path_init}"

*- Paths 
global path_EMoutput	"../data/EMoutput/"
global path_EMinput		"../data/EMinput/" 
global path_XMLParam 	"${EM_G2}/XMLParam/Countries/"
global path_SILC_data 	"R:\B2\05 - Databases\06 - EU SILC\EU-SILC - Cross_merged_data\Cross"
global EM_G2exe         "C:\Program Files\EUROMOD\Executable"
global EM_dofiles       "${path_init}/"
global path_LS          "../data/"
global path_LSscen      "${path_LS}/LSscenarios/"
global path_results     "../data/results/"
global path_results2share     "../results/"
global outlog           "../log/"
global path_stata		"${stataVersion}StataMP-64.exe" //stataVersion global is defined automatically in statainit ado file


****** RUN LOOP *****************************************************************

foreach choices of numlist `num_hours' {

	display "choices: `choices'"
    
    global hours `choices'
	global choices `choices'
	
	global min_hour "5"
	global search_hour "5"
	
	if ${hours} == 3 {
		global step "17"
    }
	else if ${hours} == 4 {
		global step "13"
    }
	else if ${hours} == 5{
		global step "10"
    }		
	else if ${hours} == 6{
		global step "8"
    }		

	global max_hour = ${hours}*${step}+${min_hour}
	
	global pos_hours = ""
	
	local min_interval = $min_hour + $step

	forvalues h = `min_interval'($step)${max_hour}{
		
		global pos_hours "$pos_hours `h'"
	}
	if $UNEMPLOYMENT == 1 	global hours "0 $search_hour $pos_hours"
	if $UNEMPLOYMENT == 0   global hours "0 $pos_hours"
	
	di in r $pos_hours
	di in r $hours

    foreach filename in $filenames {
        
		global filename "`filename'"
        global conpos : list posof "${filename}" in global(filenames)

        global country = substr("${filename}",1,2)
        global COUNTRY = upper("${country}")
        global year    = substr("${filename}",4,4)
        global fil     = substr("${filename}",9,2)
		cap mkdir "${path_results2share}/${country}_${year}_${choices}ch"
		
		if "$country" == "uk" global pyear = $year 		//income year coincides with survey year
		
		//Copy input data from EUROMOD folder to /data/EMinput/
		cap copy "${EM_G2}/Input/${country}_${year}_${fil}.txt" "${path_EMinput}/original/${country}_${year}_${fil}.txt",replace
		if _rc != 0 {
			window stopbox stop "ERROR: Input data ${EM_G2}/${country}_${year}_${fil}.txt not found."
		}
		cap copy "${EM_G2}/Input/${country}_${year}_${fil}.txt" "${path_EMinput}/modified/${country}_${year}_${fil}.txt",replace
		

		///The baseline for the income year needs to be run and stored in \data\EMoutput
		
		if ($run_baseline_income_year == 1){

			display "Running baseline income year"
			display "pyear: ${pyear}"
			display "policyyears: ${policyyears}"
			global policyyears = "${pyear}"
			display "policyyears: ${policyyears}"
			global path_XMLParam_policy "${path_XMLParam}"
			display "path_XMLParam_policy: ${path_XMLParam_policy}"
			
			capture copy "${path_EMoutput}\modified/${country}_${pyear}_std.txt" "${path_EMoutput}\modified/${country}_${pyear}_std_previous.txt"
			cap rm "${path_EMoutput}\modified/${country}_${pyear}_std.txt"
			
			global is_baseline = 1
			display in red "shell start /min "" ${EM_G2exe}/EM_ExecutableCaller.exe " "-emPath " "${EM_G2} " "-sys " "${country}_${pyear} " "-data " "`filename' " "-outPath " "${path_EMoutput}\modified " "-dataPath " "${path_EMinput}\modified " "-noTranslate"
			
			// Run EUROMOD simulation
			shell "${EM_G2exe}/EM_ExecutableCaller.exe" "-emPath" "${EM_G2}" "-sys" "${country}_${pyear}" "-data" "`filename'" "-outPath" "${path_EMoutput}\modified" "-dataPath" "${path_EMinput}\modified" "-noTranslate"
			
			global is_baseline = 0
			capture rm "${path_EMoutput}/${country}_${pyear}_std.txt"
			
			capture findfile "${country}_${pyear}_std.txt", path("${path_EMoutput}\modified") 
			while _rc !=0 {
				sleep 500
				capture findfile "${country}_${pyear}_std.txt", path("${path_EMoutput}\modified")
			}

			copy "${path_EMoutput}\modified/${country}_${pyear}_std.txt" "${path_EMoutput}/${country}_${pyear}_std.txt"
			rm "${path_EMoutput}\modified/${country}_${pyear}_std.txt"
			capture copy "${path_EMoutput}\modified/${country}_${pyear}_std_previous.txt" "${path_EMoutput}\modified/${country}_${pyear}_std.txt" 
			capture rm "${path_EMoutput}\modified/${country}_${pyear}_std_previous.txt"
			
			global policyyears = ""
			global path_XMLParam_policy = ""
			display "policyyears: ${policyyears}"
			display "path_XMLParam_policy: ${path_XMLParam_policy}"
			
			global run_baseline_income_year = 0
		}
		else{
			display "baseline income year is not going to be run again"
		}
			

		global predyear ""
		
        // Stores countries that have been processed in a session
        // in an alphabetically sorted global
        if $conpos == 1 global proc_con "${COUNTRY}"
        else global proc_con "${proc_con} ${COUNTRY}"

        if $conpos == $filenames_count {
            global proc_con_alpha : list sort    global(proc_con)
            global proc_con_count : list sizeof  global(proc_con_alpha)
        }

  
 		
       // Check if bootstrap weights exist for country-year
        capture findfile bs_${country}_${year}.dta, path("../data/bootstrap_weights/")
        if _rc == 601 global NEW_BS_WEIGHTS = 1
		
        if $BOOTSTRAP == 1 & $NEW_BS_WEIGHTS==1 {
            quiet insheet using "${path_EMinput}/original/${country}_${year}_${fil}.txt", clear

            // Generate Bootstrap weights for this dataset
            keep idperson
            quiet sort idperson

            gen  wt0  = 1
          
            forval bs = 1/$reps {
                gen wt`bs' = .
                bsample, cluster(idperson) weight(wt`bs')
                sort idperson
            }  // forval bs 
            save "../data/bootstrap_weights/bs_${country}_${year}.dta", replace
        } // IF BOOTSTRAP

        // Which Do-files to execute
        if ${PREPAREDATA}    == 1 do "${EM_dofiles}/1_preparedata.do"  
        if ${SIMULATION_DPI} == 1 do "${EM_dofiles}/3_simulation_dpi.do"
        if ${OUTPUT}         == 1 do "${EM_dofiles}/4_output.do"

        if $BOOTSTRAP == 1 {
            forval bs = 0/$reps {
                global bs = `bs'

                noi di ""
                noi di in r "Bootstrapping replication #$bs out of $reps."
                noi di ""

                if ${LS_ESTIM} == 1 do "${EM_dofiles}/5_clogit_estim.do"
				if ${LS_PRED}  == 1 do "${EM_dofiles}/7_predict.do"
                if ${LS_ELAST} == 1 do "${EM_dofiles}/7_ls_ela.do"
				if ${LS_DEMAND} == 1 do "${EM_dofiles}/8_labour_demand.do"
            }
        }
        else {
            if ${LS_ESTIM} == 1 do "${EM_dofiles}/5_clogit_estim.do"
            if ${LS_PRED}  == 1 do "${EM_dofiles}/7_predict.do"
            if ${LS_ELAST} == 1 do "${EM_dofiles}/7_ls_ela.do"
			if ${LS_DEMAND} == 1 do "${EM_dofiles}/8_labour_demand.do"
        }

      //if ${CALC_BS_SE} == 1 do "${EM_dofiles}/7b_ls_bootstrap.do"

        *if ${ITR} == 1 do "${EM_dofiles}/8_itr_measures.do"
   }

	//if ${GRAPHS} == 1 do "${EM_dofiles}/10_graphs.do"
	
}

exit

*End of 0_master.do file
