program trim_mtr
    
    args var

    egen min_`var' = pctile(`var') , p(3)
    egen max_`var' = pctile(`var') , p(97)

    replace `var' = . ///
        if ( `var' < min_`var' | `var' > max_`var')

    drop min_`var' max_`var'

end

**
