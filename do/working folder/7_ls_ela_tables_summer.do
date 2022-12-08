*********************************************************************************
* 7_ls_ela_tables do file 														*
*																				*
* Generates labour elasticity tables in an excel file 							*
* Last update 08/05/2019 B.P.													*
*********************************************************************************

use "${path_LSscen}/7_aggregate/${country}_${choices}_ela.dta",clear
set trace off
//Define mata function to write tables
capture mata mata drop write_tables_b()
mata:

function write_tables_b(){

/*** Create and setup workbook to write tables ***/
workbook="4-LS_elasticities"		//Name to create workbook
sheetname="Elasticities"			//Name of sheet to write tables
Title_table1=sprintf("%s, %s","Table 1. Labour elasticities for All",st_global("country"))		//Title of table 1
Title_table2=sprintf("%s, %s","Table 2. Labour elasticities for Men",st_global("country"))		//Title of table 2
Title_table3=sprintf("%s, %s","Table 3. Labour elasticities for Woman",st_global("country"))	//Title of table 3

r0=6		//First line to write numerical values	 
space=6		//Space between each table
	
class xl scalar b	//Declare excel class for object b
b=xl()
 b.create_book(workbook,sheetname)		//Creates the workbook if it does not exist
//b.load_book(workbook)					//If workbook already exists uncomment this line and comment the line above
b.set_mode("open")						//Open workbook
b.set_sheet(sheetname)					//Set sheet to modify
b.set_missing("-")

//Set row height and column width
b.set_row_height(1, 500, 15)
b.set_column_width(2,12,23)
b.set_column_width(3,3,14)

//Set gridlines off
b.set_sheet_gridlines(sheetname,"off")


/*** Get matrices ***/

//Define pointer matrices
pmat=J(3,3,NULL)
prefix=("edu_","age_","ch_","MW_","Mig_","inc_")
sections_mat=J(cols(prefix),1,NULL)
tmat=J(cols(prefix),3,NULL)

//Get matrices and reshape them
for (i=1;i<=cols(prefix);i++){ //edu age ch MW Mig
	for (j=1;j<=3;j++){  //all men women
		for (k=1;k<=3;k++){	//all couples singles
			pmat[j,k]=&st_matrix(sprintf("%s%1.0f%1.0f",prefix[i],j,k))	
		}
		
	}
	qmat=(*pmat[1,1],*pmat[1,2],*pmat[1,3])
	rmat=(*pmat[2,1],*pmat[2,2],*pmat[2,3])
	smat=(*pmat[3,1],*pmat[3,2],*pmat[3,3])	
	
	qname=sprintf("%s_%1.0f","section",i)
	qarray = asarray_create()
	asarray(qarray, qname, qmat)
	tmat[i,1]=&asarray(qarray,qname) //all
	
	rname=sprintf("%s_%1.0f","rsection",i)
	rarray = asarray_create()
	asarray(rarray, rname, rmat)
	tmat[i,2]=&asarray(rarray,rname) //men
	
	sname=sprintf("%s_%1.0f","ssection",i)
	sarray = asarray_create()
	asarray(sarray, sname, smat)
	tmat[i,3]=&asarray(sarray,sname) //women
}

/*** Write tables ***/

//Set labels and titles
Labels_cols= (("Education"\""\""\"Age"\""\""\"Child"\""\"Minimum Wage Earner"\""\"Migrant"\""\"Income"\""\""\"Total"),("Low level"\"Middle level"\"High level"\"20-30"\"31-40"\"41-on"\"Yes"\"No"\"Yes"\"No"\"Yes"\"No"\"Low"\"Middle"\"High"\""))
Category=("All","Men","Women")
Titles=(Title_table1,Title_table2,Title_table3)

//Write labels and calculated matrices for the three categories
for (i=1;i<=3;i++){  //all men women
	
	Labels_rows= (("All","","","Couples","","","Singles","","")\("Total","Extensive","Intensive","Total","Extensive","Intensive","Total","Extensive","Intensive"))	
	row_i=r0			//Initial row for each table
	sections_mat[i,1]=&(*tmat[1,i]\*tmat[2,i]\*tmat[3,i]\*tmat[4,i]\*tmat[5,i]\*tmat[6,i]) //ADD HERE *tmat[5,i] IF YOU ADD A NEW VARIABLE
	b.put_number(row_i,4,*sections_mat[i,1])	//Write matrix
	
	b.put_string(row_i-3,2,Titles[i])			//Write titles
	b.put_string(row_i-2,4,Labels_rows)			//Write labels in table
	b.put_string(row_i,2,Labels_cols)
	
	r0=row_i+space+rows(*sections_mat[i,1])
	row_f=r0-space-1
	
	/*** Give format to table ***/
	
	//Merge cells
	b.set_sheet_merge(sheetname,(row_i-2,row_i-2),(4,6))		
	b.set_sheet_merge(sheetname,(row_i-2,row_i-2),(7,9))
	b.set_sheet_merge(sheetname,(row_i-2,row_i-2),(10,12))
	//Set bold labels and titles
	b.set_font_bold((row_i-3,row_i-1),(2,12),"on")
	b.set_font_bold(row_f,2,"on")
	//Set labels and titles alignment
	b.set_horizontal_align((row_i-2,row_i-2),(2,12),"center")
	b.set_horizontal_align((row_i-1,row_i-1),(2,12),"right")
	//Draw borders	
	rows_horizontal_line=(row_i-2,row_i,row_i+3,row_f-2,row_f,row_f+1)	//Rows to draw horizontal lines
	cols_horizontal_line=(2,12)			//Cols to draw horizontal lines
	rows_vertical_line=(row_i-2,row_f)	//Rows to draw vertical lines	
	cols_vertical_line=(1,3,6,9,12)		//Cols to draw vertical lines
	
	for (j=1;j<=cols(rows_horizontal_line);j++){ 
		b.set_top_border(rows_horizontal_line[j],cols_horizontal_line,"thin","black")	//Horizontal lines
	}
	for (j=1;j<=cols(cols_vertical_line);j++){
		b.set_right_border(rows_vertical_line,cols_vertical_line[j],"thin","black")	//Vertical lines
	}
	
}
//Set number format
b.set_number_format((2,row_f),(4,12),"0.000")
//Close book. This is when excel sheet is saved
b.close_book()

}
end

local i=0
foreach table in "all" "men" "women" {
	local i=`i'+1
	local j=0
	//di in r "`table'" 
	if "`table'" == "all" {
		local cond_tab "inlist(flex,1)"
	}
		
	if "`table'" == "women" {
		local cond_tab "inlist(flex_f,1)"
	}

	if "`table'" == "men" {
		local cond_tab "inlist(flex_m,1)"
	}
		

	foreach type in "all" "couples" "singles" {
		local j=`j'+1
		//di in r "`type'"
		if "`type'" == "all" {
			local condition "if inlist(flex_hh,1,2,3,4,5)"
		}
		
		if "`type'" == "singles" {
			local condition "if inlist(flex_hh,2,3,4,5)"
		}

		if "`type'" == "couples"  {
			local condition "if inlist(flex_hh,1)"
		
		}
		
		//TOTAL MATRIX SHOULD BE ONLY AT THE END. EACH MATRIX SHOULD MATCH THE DIMENSION OF THE CATHEGORICAL VARIABLE
		tabstat ela_tot_own ela_ext_own ela_int_own [aw = dwt] `condition' & `cond_tab',stat(mean) by(edu) save nototal 
		di in r "edu_`i'`j'"
		mat edu_`i'`j'=(r(Stat1)\r(Stat2)\r(Stat3))
		mat list edu_`i'`j'
		
		tabstat ela_tot_own ela_ext_own ela_int_own [aw = dwt] `condition' & `cond_tab',stat(mean) by(age_group) save nototal 
		di in r "age_`i'`j'"
		mat age_`i'`j'=(r(Stat1)\r(Stat2)\r(Stat3))
		mat list age_`i'`j'
		
		tabstat ela_tot_own ela_ext_own ela_int_own [aw = dwt] `condition' & `cond_tab',stat(mean) by(ch_group) save 
		di in r "ch_`i'`j'"
		mat ch_`i'`j'=(r(Stat1)\r(Stat2)) 
		mat list ch_`i'`j'
		
		tabstat ela_tot_own ela_ext_own ela_int_own [aw = dwt] `condition' & `cond_tab',stat(mean) by(MW_earner) save 
		di in r "MW_`i'`j'"
		mat MW_`i'`j'=(r(Stat1)\r(Stat2))
		mat list MW_`i'`j'
		
		tabstat ela_tot_own ela_ext_own ela_int_own [aw = dwt] `condition' & `cond_tab',stat(mean) by(migrant) save 
		di in r "Mig_`i'`j'"
		mat Mig_`i'`j'=(r(Stat1)\r(Stat2))
		mat list Mig_`i'`j'
		
		tabstat ela_tot_own ela_ext_own ela_int_own [aw = dwt] `condition' & `cond_tab',stat(mean) by(income_group) save 
		di in r "inc_`i'`j'"
		mat inc_`i'`j'=(r(Stat1)\r(Stat2)\r(Stat3)\r(StatTotal))
		mat list inc_`i'`j'
		
	}	
}	

//Call mata function to write tables
mata:write_tables_b()
cap copy "4-LS_elasticities.xlsx" "${path_results2share}/${country}_${year}_${choices}ch/4-LS_elasticities.xlsx", replace
rm "4-LS_elasticities.xlsx"

**** End of file Tables.do ****
