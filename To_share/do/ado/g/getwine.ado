/*
 * program getwine
 *
 * checks OS, on unix systems returns "wine" in global $wine
 *
 */

program getwine
    version 13
    
    if "`c(os)'" == "Unix" {
    	global wine "wine"
    	global file_ext "png"
	}
    else {
    	global wine ""
    	global file_ext "pdf"
    }

end

**
