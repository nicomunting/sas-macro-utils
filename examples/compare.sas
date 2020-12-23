/** Create a copy of some SASHELP datasets with some changes **/

data work.airline; 
	set sashelp.airline; 
	where DATE ge '1jan1950'd;

	if DATE eq '1apr1950'd then AIR = 150;
	if DATE eq '1nov1959'd then AIR = 364; 

	format DATE DATE9. Region $3.; 
run;

data work.cars; 
	length Make $15.; 
	set sashelp.cars end=last; 
	drop Invoice; 
	where Model not contains 'S40' and Origin ne 'USA';

	format EngineSize 8.2; 
	label 
		MPG_City='Miles Per Gallon (City)' 
		MPG_Highway='Miles Per Gallon (Highway)'
	; 

	output; 

	if last then do; 
		Model = 'XC90';
		output; 
	end; 
run; 


/** Define name for data set that holds summary **/

%let result_ds = compare_summary; 

proc datasets lib=work nodetails nolist nowarn; 
	delete &result_ds.; 
quit; 


/** Execute comparisons **/

%smu_compare_tables(
	base_ds=sashelp.airline, compare_ds=work.airline, 
	prefix=air, id_vars=DATE, 
	summary_ds=&result_ds.
);
%smu_compare_tables(
	base_ds=sashelp.cars, compare_ds=work.cars, 
	prefix=cars, id_vars=Make Model Type DriveTrain Origin, 
	summary_ds=&result_ds.
);


/** Define format for color coding and print summary **/ 

/* Format for proc print of proc compare output codes */ 
proc format;
	value red 
		1 = red
	;
	value orange 
		1 = orange 
	; 
	value green 
		1 = green 
	; 
run;

/* Print summary output created by smu_compare_tables based on output codes 
   from proc compare */
proc print data=&result_ds. noobs label; 
	id base_ds compare_ds; 
	variables DSLABEL DSTYPE INFORMAT FORMAT LABEL / style={background=green.};
	variables LENGTH BASEVAR COMPVAR / style={background=orange.};
	variables BASEOBS COMPOBS BASEBY COMPBY VALUE TYPE BYVAR ERROR / style={background=red.};
run; 
