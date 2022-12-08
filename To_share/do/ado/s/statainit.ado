/* Program statainit
 * 
 * Set some initial stuff on Stata.
 *
 * (c) CruelChris 2016
 *
 */

program statainit

    set type double, permanently
    set more off, permanently
    set logtype text, permanently

    capture log close _all
    capture program drop _all
    capture macro drop _all
    capture graph drop _all
	capture rm "clean.log"

    set matsize 800
	
	//Get stata version
	cap sysdir
	global stataVersion ="`c(sysdir_stata)'"

end



**
