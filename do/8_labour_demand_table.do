*********************************************************************************
* 8_labour_demand_table do file 												*
*																				*
* Generates labour demand table in an excel file named  5-Equilibrium			*
* Last update 23/09/2021 B.P.													*
*********************************************************************************
args ref

capture mata mata drop write_tables()
mata:
function write_tables(){

workbook="5-Equilibrium"	//Name to create workbook
counter_ld=strtoreal(st_global("counter_ld"))
sheet=st_local("ref")

/*Create or load an existing Excel workbook*/ 
class xl scalar b
b=xl()
//Create workbook
if (counter_ld==1){
	b.create_book(workbook,sheet)
}
else{
	/*The workbook has to be loaded*/
	b.load_book(workbook)
	b.add_sheet(sheet)
}

b.set_mode("open")

//Set gridlines off
b.set_sheet_gridlines(sheet,"off")
b.set_sheet(sheet)

//Set initial row and column
row_i=2
col_i=2

//Set column width
b.set_column_width(col_i,col_i+14,16.5)
b.set_column_width(col_i+4,col_i+5,19)
//Set row height
b.set_row_height(row_i, row_i+7, 20)
b.set_row_height(row_i+1, row_i+1, 35)
//Set font for Reform label
b.set_font(row_i+1, col_i, "Calibri", 14)

//Labels and Title
reform=usubstr(sheet,6,ustrlen(sheet))
		
labels=J(7,6,"")
labels[1,1]="Table 1: % Changes in employment, unemployment and inactivity rate"
labels[2,1]=sprintf("%s %s","Reform", reform)
labels[3,2]="Baseline"
labels[3,3]="No Equilibrium" 
labels[3,4]="With Equilibrium"
labels[3,5]="No Equilibrium (%)" 
labels[3,6]="With Equilibrium (%)"
labels[4,1]="Employment"
labels[5,1]="Inactivity"
labels[6,1]="Unemployment"
labels[7,1]="v"

//Definitions
definitions=J(5,1,"")
definitions[1,1]= "* Definitions:"
definitions[2,1]="Employment = Total number of people in employment, only labour supply endogenous sample "
definitions[3,1]="Inactivity  = Total number of people in inactivity, only behavioural sample"
definitions[4,1]="Unemployment = Total number of people in unemployment, only behavioural sample."
definitions[5,1]="v = Parameter of percentage change in wages."

//Write labels and definitions
b.put_string(row_i,col_i,labels)
b.put_string(row_i+9,col_i,definitions)
		
//Write demand values
demand_values=st_matrix("demand_for_xls")

//Calculate relative values and express in %
for(i=1;i<=3;i++){
	demand_values[i,4]= (demand_values[i,2]/demand_values[i,1])-1
	demand_values[i,5]= (demand_values[i,3]/demand_values[i,1])-1
}

b.put_number(row_i+3,col_i+1,demand_values)
				
//Give format
b.set_font_bold((row_i,row_i+1), (col_i,col_i),"on")
b.set_font_bold((row_i+9,row_i+9), (col_i,col_i),"on")
b.set_font_underline((row_i,row_i), (col_i,col_i),"on")
b.set_font_italic((row_i+9,row_i+14), (col_i,col_i),"on")
b.set_font((row_i+9,row_i+14), (col_i,col_i), "Calibri", 10)

//Lines 
b.set_bottom_border((row_i+2,row_i+2),(col_i+1,col_i+5), "thin")
b.set_left_border((row_i+2,row_i+6),(col_i+1,col_i+1), "thin")
b.set_left_border((row_i+2,row_i+2),(col_i+2,col_i+2), "thin")
b.set_left_border((row_i+2,row_i+2),(col_i+4,col_i+4), "thin")

b.set_bottom_border((row_i+1,row_i+1),(col_i,col_i+5), "thick")
b.set_bottom_border((row_i+6,row_i+6),(col_i,col_i+5), "thick")
b.set_left_border((row_i+2,row_i+6),(col_i,col_i), "thick")
b.set_left_border((row_i+2,row_i+6),(col_i+6,col_i+6), "thick")

//Merge and wrap text
b.set_error_mode("off")
b.set_sheet_merge(sheet, (row_i,row_i), (col_i,col_i+5))
b.set_error_mode("on")
	
//Number format
b.set_number_format((row_i+3,row_i+5),(col_i+4,col_i+5),"percent_d2")

//Align titles
b.set_horizontal_align((row_i+2,row_i+2),(col_i+1,col_i+5),"right")

//Fill definitions box
b.set_fill_pattern((row_i+9,row_i+13), (col_i,col_i+4), "solid", ("242 242 242"))
	
b.close_book()

}

end

mata:write_tables()

