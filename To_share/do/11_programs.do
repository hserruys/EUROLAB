*********************************************************************************
* 11_programs.do                               									*  
*																				*
* Includes the programs that will be used later									*
* Date: 29 June 2018  															*
* Updated: June 2021  															*                             
*																				*
* Content:																		*
* 1. writePolicyDatasetSystem													*
* 2. writePolicyDatasetData														*
* 3. writePolicyDataset															*
* 4. createFolder																*
* 5. isFile																		*
* 6. removeFolders																*
*********************************************************************************

capture program drop writePolicyDatasetSystem
program writePolicyDatasetSystem

	local number_of_lines = 0
	file open emconfig using "${path_XMLParam}/${country}/${country}_DataConfig.xml", read text
	file read emconfig line
	while r(eof) == 0{
		local number_of_lines = `number_of_lines' + 1
		file read emconfig line
	}
	local number_of_lines = `number_of_lines' + 1
	file close emconfig
	
	import excel "${path_EMinput}\other\EUROMOD_Policy_Dataset_Compatibility.xlsx", sheet("ID") firstrow allstring clear
	capture drop dataset datasetid
	tostring *, replace
	list
	
	file open emconfig using "${path_XMLParam}/${country}/${country}_DataConfig.xml", read text
	file read emconfig line
	
	local DBSystemConfig_found = 0
	local systemId_found = 0
	
	local file_l = 0
	local i = 0
	while `file_l' < `number_of_lines'{
		
		local i = `i'+1
		local file_l = `file_l' + 1
		//display "i: `i'"
	
		// Read file line by line and save content into local line
		file read emconfig line
		
		//display "Line:`i' `line'"

		// Save length of the line
		local len : length local line
		
		// Find first non-space digit
		local n = 1
		local continue = 1
		local startchar = 1
		local endchar = 1
		

		while (`n' < `len') & (`continue') == 1 {
			local char = substr("`line'", `n', 1)
			
			if "`char'" == "<" { 
				local continue = 0
			}
			local n = `n' + 1
			local startchar = `n'
		}
			
		local continue = 1
		local numberChars = 0
		while (`n' < `len') & (`continue') == 1 {
			local char = substr("`line'", `n', 1)
			
			if "`char'" == ">" { 
				local continue = 0
			}
			else{
				local numberChars = `numberChars' + 1 
			}
			
			local n = `n' + 1
			
		}
			
		// Extract the first "word"
		local tag = substr("`line'", `startchar', `numberChars')
		local startcount = `startchar' + `numberChars' + 1
		
		//display "i: `i' . tag: `tag'"
		*display "Check tag name"
		if "`tag'" == "DBSystemConfig" {

			local DBSystemConfig_found = 1
			//display "DBSystemConfig_found in line `i'"

		}
		
		if "`tag'" == "SystemID" & (`DBSystemConfig_found') == 1{
			local systemId_found = 1
			//display "System id found in line `i'"
			local foundYear = 0
			local continue = 1
			local numberChars = 0
			local n = `startcount'
			while (`n' < `len') & (`continue') == 1 {
				local char = substr("`line'", `n', 1)
			
				if "`char'" == "<" { 
					local continue = 0
				}
				else{
					local numberChars = `numberChars' + 1 
				}
			
				local n = `n' + 1
			
			}
			
			local systemId = substr("`line'", `startcount', `numberChars')
			//display "systemId: `systemId'"
		}
		

		if "`tag'" == "SystemName" & (`systemId_found') == 1{
		
			local foundYear = 0
			local continue = 1
			local numberChars = 0
			local n = `startcount'
			while (`n' < `len') & (`continue') == 1 {
				local char = substr("`line'", `n', 1)
			
				if "`char'" == "<" { 
					local continue = 0
				}
				else{
					local numberChars = `numberChars' + 1 
				}
			
				local n = `n' + 1
			
			}
			
			local systemName = substr("`line'", `startcount', `numberChars')
			local systemName_lower = lower("`systemName'")
			local systemId_found = 0
			local DBSystemConfig_found = 0
			
			//display "`systemName'"
			//display "`systemId'"
			capture drop if psystem == "`systemName'"
			capture drop if psystem == "`systemName_lower'"
			capture drop if psystemid == "`systemId'"
			
			
			set obs `=_N+1'
			local N = _N
			//display "N: `N'"
			replace psystem="`systemName_lower'" in `N'
			replace psystemid = "`systemId'" in `N'
			

		}

		
	}
	
	// Close files
	file close emconfig
	drop if psystem == ""
	list
	export excel using "${path_EMinput}\other\EUROMOD_Policy_Dataset_Compatibility.xlsx", sheet("ID") sheetmodify cell(C1) firstrow(variables)
	display "End of system id search"
	//display "Number of lines: `number_of_lines'"

end

capture program drop writePolicyDatasetData
program writePolicyDatasetData

	local number_of_lines = 0
	file open emconfig using "${path_XMLParam}/${country}/${country}_DataConfig.xml", read text
	file read emconfig line
	while r(eof) == 0{
		local number_of_lines = `number_of_lines' + 1
		file read emconfig line
	}
	local number_of_lines = `number_of_lines' + 1
	file close emconfig
	
	import excel "${path_EMinput}\other\EUROMOD_Policy_Dataset_Compatibility.xlsx", sheet("ID") firstrow allstring clear
	capture drop psystem psystemid

	tostring *, replace
	
	file open emconfig using "${path_XMLParam}/${country}/${country}_DataConfig.xml", read text
	file read emconfig line
	
	local DatabaseConfig_found = 0
	local dataId_found = 0
	
	local file_l = 0
	local i = 0
	while `file_l' < `number_of_lines'{
		
		local i = `i'+1
		local file_l = `file_l' + 1
	
		// Read file line by line and save content into local line
		file read emconfig line
		
		//display "Line:`i' `line'"

		// Save length of the line
		local len : length local line
		
		// Find first non-space digit
		local n = 1
		local continue = 1
		local startchar = 1
		local endchar = 1
		

		while (`n' < `len') & (`continue') == 1 {
			local char = substr("`line'", `n', 1)
			
			if "`char'" == "<" { 
				local continue = 0
			}
			local n = `n' + 1
			local startchar = `n'
		}
			
		local continue = 1
		local numberChars = 0
		while (`n' < `len') & (`continue') == 1 {
			local char = substr("`line'", `n', 1)
			
			if "`char'" == ">" { 
				local continue = 0
			}
			else{
				local numberChars = `numberChars' + 1 
			}
			
			local n = `n' + 1
			
		}
			
		// Extract the first "word"
		local tag = substr("`line'", `startchar', `numberChars')
		local startcount = `startchar' + `numberChars' + 1
		
		if "`tag'" == "DataBase" {

			local DatabaseConfig_found = 1

		}
		
		if "`tag'" == "ID" & (`DatabaseConfig_found') == 1{
			local dataId_found = 1

			local continue = 1
			local numberChars = 0
			local n = `startcount'
			while (`n' < `len') & (`continue') == 1 {
				local char = substr("`line'", `n', 1)
			
				if "`char'" == "<" { 
					local continue = 0
				}
				else{
					local numberChars = `numberChars' + 1 
				}
			
				local n = `n' + 1
			
			}
			
			local dataId = substr("`line'", `startcount', `numberChars')
		}
		
		if "`tag'" == "Name" & (`dataId_found') == 1{
		
			local continue = 1
			local numberChars = 0
			local n = `startcount'
			while (`n' < `len') & (`continue') == 1 {
				local char = substr("`line'", `n', 1)
			
				if "`char'" == "<" { 
					local continue = 0
				}
				else{
					local numberChars = `numberChars' + 1 
				}
			
				local n = `n' + 1
			
			}
			
			local dataName = substr("`line'", `startcount', `numberChars')
			local dataId_found = 0
			local DatabaseConfig_found = 0
			
			local dataName_lower = lower("`dataName'")
			capture drop if dataset == "`dataName'"
			capture drop if dataset == "`dataName_lower'"
			capture drop if datasetid == "`dataId'"
			local N = _N
			set obs `=_N+1'
			local N = _N
			
			replace dataset="`dataName_lower'" in `N'
			replace datasetid = "`dataId'" in `N'

			list
			
		}

		
	}
	
	// Close files
	file close emconfig
	drop if dataset == ""
	export excel using "${path_EMinput}\other\EUROMOD_Policy_Dataset_Compatibility.xlsx", sheet("ID") sheetmodify cell(A1) firstrow(variables)
	display "Number of lines: `number_of_lines'"

end

capture program drop writePolicyDataset
program writePolicyDataset
	preserve
	writePolicyDatasetSystem
	writePolicyDatasetData
	restore
end

*-----------Create Folder to save results ------------------------------
capture program drop createFolder
program createFolder

	local output_path="`1'"
	local folderName="`2'"
	
	local isFolder: dir "`output_path'" dirs "`folderName'"

	if `"`isFolder'"'!=""{
		display in red "Folder `folderName' already exists"
		if regexm("`folderName'","temp_folder"){
			local temp_list:dir "`output_path'/`folderName'" files "*"
			//Remove auxiliary txt files used as flag in merge_CF_level1.do
			foreach file in `temp_list'{
				erase "`output_path'/`folderName'/`file'"
			}
		}
	}
	else{ 
		mkdir "`output_path'/`folderName'"
		display in red "Folder `folderName' will be created"
	}
	
end

*--------- Verify if file exists -------------------------------
capture program drop isFile
program isFile

	local FileName="`1'"
	local folder="`2'"

	capture findfile "`FileName'", path("`folder'") 
	matrix isfile = J(1,1,.)
	if _rc==0{
		//display in red "File `FileName' already exists"	
		mat isfile[1,1]=1
	}
	else{
		//display in red "File `FileName' has to be created"
		mat isfile[1,1]=0
	}
end

*--------- Delete auxiliary files and folders created in 3_simulation_dpi ----------------------------
capture program drop removeFolders
program removeFolders 

//Remove auxiliary folders from EMinput	
local folders:dir "${path_EMinput}/modified" dirs "*", respectcase
foreach folder in `folders'{
	//di in r "folder `folder'"
	local files:dir "${path_EMinput}/modified/`folder'" files "*" 
	foreach file in `files'{
		capture erase "${path_EMinput}/modified/`folder'/`file'"
	}
	capture rmdir "${path_EMinput}/modified/`folder'"
}

local folders:dir "${path_EMinput}/" dirs "*", respectcase
local temp="original other modified"
local folders: list folders - temp
foreach folder in `folders'{
	local files:dir "${path_EMinput}/`folder'" files "*" 
	foreach file in `files'{
		capture erase "${path_EMinput}/`folder'/`file'"
	}
	capture rmdir "${path_EMinput}/`folder'"
}

//Remove auxiliary folders from EMoutput
local folders:dir "${path_EMoutput}/modified" dirs "*", respectcase
foreach folder in `folders'{
	local files:dir "${path_EMoutput}/modified/`folder'" files "*"
	foreach file in `files'{
		capture erase "${path_EMoutput}/modified/`folder'/`file'"
	}
	capture rmdir "${path_EMoutput}/modified/`folder'"
}

//Remove Euromod log files from EMoutput
local files:dir "${path_EMoutput}/modified/" files "*EUROMOD_Log*"
foreach file in `files'{
	capture erase "${path_EMoutput}/modified/`file'"
}

//Remove datasets from 1_counterfactuals
local files:dir "${path_LSscen}/1_counterfactuals/" files "*.dta"
foreach file in `files'{
	capture erase "${path_LSscen}/1_counterfactuals/`file'"
}
/*local files:dir "${path_LSscen}/1_counterfactuals/" files "*.txt"
foreach file in `files'{
	capture erase "${path_LSscen}/1_counterfactuals/`file'"
}*/

//Remove datasets from 2_postEM_appended
local files:dir "${path_LSscen}/2_postEM_appended/" files "*_f*_*.dta"
foreach file in `files'{
	capture erase "${path_LSscen}/2_postEM_appended/`file'"
}
	
local temp:dir . files "3a_merge_CF*.log"
foreach file in `temp'{
	capture erase "`file'"
}

local temp:dir . files "3b_merge_CF*.log"
foreach file in `temp'{
	capture erase "`file'"
}

local temp:dir . files "1a_create_input_data*.log"
foreach file in `temp'{
	capture erase "`file'"
}

capture erase "all_globals.dta"
capture erase "all_globals_preparedata.dta"
capture erase "globals_preparedata.dta"
capture erase "1_preparedata.dta"

end

	
		
