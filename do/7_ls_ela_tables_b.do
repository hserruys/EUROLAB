*********************************************************************************
* 7_ls_ela_tables do file 														*
*																				*
* Generates labour elasticity tables in an excel file 							*
* Last update 04/07/2022 B.P.													*
*********************************************************************************

use "${path_LSscen}/7_aggregate/${country}_${choices}_ela.dta",clear
set trace off
//Define mata function to write tables
capture mata mata drop write_tables()
mata:

function write_tables(){

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
prefix=tokens(st_local("mat_list"))  //Prefix of matrices calculated in build_ela_matrix "edu_","age_","ch_","MW_","mig_","inc_"
sections_mat=J(cols(prefix),1,NULL)
tmat=J(cols(prefix),3,NULL)
var_rows=J(cols(prefix),1,.)

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
	
	var_rows[i,1]=rows(*pmat[1,1])
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
	
	//Matrices for cathegorical variables and section i
	for (j=1;j<=cols(prefix);j++){ 
		if (j==1){
			tmat_all=(*tmat[j,i])
		}
		else{
			tmat_all=(tmat_all\*tmat[j,i])
		}	
	}
	sections_mat[i,1]=&tmat_all		
	b.put_number(row_i,4,*sections_mat[i,1])	//Write matrices per section i - all, men, women
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
	//Horizontal
	row_j=row_i+var_rows[1,1]
	rows_horizontal_line=(row_i-2,row_i,row_j)	
	for (j=2;j<=rows(var_rows);j++){ 
		row_j=row_j+var_rows[j,1]
		rows_horizontal_line=(rows_horizontal_line,row_j)
	}
	rows_horizontal_line=(rows_horizontal_line,row_j-1)	//Rows to draw horizontal lines
	cols_horizontal_line=(2,12)			//Cols to draw horizontal lines
	
	//Vertical
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

//Pogram to calculate labour elasticities
capture program drop build_ela_matrix
program build_ela_matrix,rclass
	
	local cathegorical_varlist= "`1'" 	//Categorical variables "edu age_group ch_group MW_earner migrant income_group"
	local condition = "`2'"
	local cond_tab = "`3'"
	local i = `4'
	local j = `5'
	local final_var=wordcount("`cathegorical_varlist'")	//last variable in cathegorical_varlist. Total is obtained from last item 
	local var_counter=1
	local mat_list=""
	
	foreach by_var in `cathegorical_varlist'{
		local mat_name=substr("`by_var'",1,3)
		//set matrices names
		if regexm("`mat_name'","_"){
			local mat_name="`mat_name'"
		}
		else{
			local mat_name="`mat_name'_"
		}
		local mat_list="`mat_list' `mat_name'"
		local mat_name="`mat_name'`i'`j'"
		
		//get levels of cathegorical variable
		cap levelsof `by_var', local(var_values) 
		local first_value=word("`var_values'",1)	
		
		//Calculate mean
		tabstat ela_tot_own ela_ext_own ela_int_own [aw = dwt] `condition' & `cond_tab',stat(mean) by(`by_var') save
		
		//Write results into matrix in the right order (considering possible missing values due to conditions)
		local counter = 1
		foreach k in `var_values'{
			cap local aux="`r(name`counter')'"
			if "`aux'"==""{
				mat temp=J(1,3,.)
			}
			else{
				if r(name`counter')=="`k'"{
					mat temp=r(Stat`counter')
					local ++counter
				}
				else{
					mat temp=J(1,3,.)
				}
			}
			if `k'==`first_value'{
				mat `mat_name'=temp			
			}
			else{
				mat `mat_name'=(`mat_name'\temp)
			}
		}
		
		if `var_counter'==`final_var'{
			mat `mat_name'=(`mat_name'\r(StatTotal))	//Total is only allocated in the last element of the matrix
		}
		local ++var_counter
		*mat list `mat_name'	
	}
	return local mat_list "`mat_list'"
end	

//Calculations for the different categories
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
		
		* Calculate elasticities matrices
		local cathegorical_varlist="edu age_group ch_group MW_earner migrant income_group"
		build_ela_matrix "`cathegorical_varlist'" "`condition'" "`cond_tab'" `i' `j'
		
	}	
}	
local mat_list=r(mat_list)

//Call mata function to write tables
mata:write_tables()
cap copy "4-LS_elasticities.xlsx" "${path_results2share}/${country}_${year}_${choices}ch/4-LS_elasticities.xlsx", replace
rm "4-LS_elasticities.xlsx"

**** End of file 7_ls_ela_tables.do ****
