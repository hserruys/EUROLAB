local current_path_to_run = "`c(pwd)'"	// Set the directory
cd ..
local current_path_to_run = "`c(pwd)'"

* Remove EUROMOD input (it is a copy from the original EUROMOD project set by the user)
cd "`current_path_to_run'\data\EMinput\"
local directories: dir "`workdir'" dirs "**"

foreach directory of local directories {
	display "`directory'"
	cd "`current_path_to_run'\data\EMinput/`directory'"
	local datafiles: dir "`workdir'" files "*.*"
	foreach datafile of local datafiles {
		display "`datafile'"
		capture rm `datafile'
	}
}

* Remove used EUROMOD output
cd "`current_path_to_run'\data\EMoutput\modified\"
local directories: dir "`workdir'" dirs "**"

foreach directory of local directories {
	display "`directory'"
	cd "`current_path_to_run'\data\EMoutput\modified/`directory'"
	local datafiles: dir "`workdir'" files "*.*"
	foreach datafile of local datafiles {
		display "`datafile'"
		capture rm `datafile'
	}
}

cd "`current_path_to_run'\data\EMoutput\
local datafiles: dir "`workdir'" files "*.*"
foreach datafile of local datafiles {
	display "`datafile'"
	capture rm `datafile'
}

* Remove files in baseline
cd "`current_path_to_run'\data\baseline\
local datafiles: dir "`workdir'" files "*.*"
foreach datafile of local datafiles {
	display "`datafile'"
	capture rm `datafile'
}

* Remove log files
cd "`current_path_to_run'\log\
local datafiles: dir "`workdir'" files "*.*"
foreach datafile of local datafiles {
	display "`datafile'"
	capture rm `datafile'
}

* Remove files in LSscenarios except 3_LS and 4_pred
cd "`current_path_to_run'\data\LSscenarios"
local directories: dir "`workdir'" dirs "**"
local aux= "3_ls 4_pred"
local directories: list directories - aux
foreach directory of local directories {
	display "`directory'"
	cd "`current_path_to_run'\data\LSscenarios/`directory'"
	local datafiles: dir "`workdir'" files "*.*"
	foreach datafile of local datafiles {
		display "`datafile'"
		capture rm `datafile'
	}
}

/*
cd "`current_path_to_run'\results"
local directories: dir "`workdir'" dirs "**"
foreach directory of local directories {
	display "`directory'"
	cd "`current_path_to_run'\results/`directory'"
	local datafiles: dir "`workdir'" files "*.*"
	foreach datafile of local datafiles {
		display "`datafile'"
		capture rm `datafile'
	}
}

cd "`current_path_to_run'\results\population\scalars\"
local datafiles: dir "`workdir'" files "*.*"

foreach datafile of local datafiles {
	display "`datafile'"
    capture rm `datafile'
}
*/

exit