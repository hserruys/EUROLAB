program install_required_ados

/*
// Pull necessary ado files from the SSC

cap ssc install matsave
cap ssc install estwrite
cap ssc install outtex

cap net install grc1leg

cap net from https://mloeffler.github.io/stata
cap net install lslogit
*/

    // Install from SSC
    foreach a of global required_ados_ssc {
        capture findfile `a'.ado        
        
        if _rc == 601 {
            ssc install `a'
        }
    } 

    // Install from Net / various
    foreach b of global required_ados_net {

        local from ""
        
        if "`b'" == "lslogit" {
            local from "net from https://mloeffler.github.io/stata"

            capture findfile "lib/l/llslogit.mlib"

            if _rc == 601 {
                local oldpath "`c(pwd)'"

                cd "lib/l"
                do llslogit
                cd "`oldpath'"
            }
        }
        if "`b'" == "grc1leg" local from "net from http://www.stata.com/users/vwiggins/"

        capture findfile `b'.ado

        if _rc == 601 {
            `from'
            net install `b'
        }
    }

end

