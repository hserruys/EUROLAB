*! version 2.10 06June2014 M. Araar Abdelkrim 

cap program drop  addDMenu2
program addDMenu2
                version 11.0
                args nfile lcom
                tempname fh
                local linenum = 0
				local stopa = 0
				cap findfile `nfile' 
                local dire `r(fn)'
                file open `fh' using `"`dire'"', read write
                file read `fh' line
                while r(eof)==0 & `stopa' != 1 {
                        local linenum = `linenum' + 1
                        if (`"`macval(line)'"'=="`lcom'") {
						local stopa = 1
						dis "The Stata command line `lcom' aready exists in the profile.do file."
						}
						
                        file read `fh' line
                }
			    if `stopa' == 0 {
				file write `fh' `"`lcom'"' _n
				dis "The Stata command line `lcom' was added in the profile.do file."
				}
                file close `fh'
end




cap program drop  addDMenu
program addDMenu
version 11.0
args nfile lcom
local mydir `c(pwd)'
local fl `nfile'
cap findfile `fl' 
local dire `r(fn)'
qui sysdir
if  ("`dire'"!="") {
addDMenu2 `fl' `lcom'
}
if  ("`dire'"=="") {
qui version
if  ("`c(os)'"=="Windows") {
qui sysdir
local mdr = subinstr("`c(sysdir_personal)'","/","\",.)
		if ("`mdr'"=="c:\ado\personal\") {
				cap cd c:/
				cap mkdir ado
				cap cd ado
				cap mkdir personal
				cap cd personal
				}		
	}	
	
cd `c(sysdir_personal)'
tempfile   myfile
qui file open  myfile   using "`fl'", write replace 
qui file write myfile `"`lcom'"' _n
qui file close  myfile
cap findfile `fl'
if  "`r(fn)'"!=""  {
dis "The file `fl' was added succefully."
}
}

capture {
window menu clear
findfile profile.do
do `r(fn)'
}

qui cd "`mydir'"
end
