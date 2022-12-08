/*
 * program datewfmt
 *
 * get the current date, format, and store in global date_string
 *
 * Author: Christian Wittneben
 */


program datewfmt
    version 13
    
    global date: display %td_CCYY_NN_DD date(c(current_date), "DMY")
    global date_string = subinstr(trim("${date}"), " " , "_", .)

end

**
