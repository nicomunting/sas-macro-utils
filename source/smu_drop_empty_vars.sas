/**
	\file       smu_drop_empty_vars.sas

	\brief      Drop all variables from a dataset that only have missing values. 
	\details
	Macro that takes a data set as an input, determines which variables have no
	values at all and drops these variables. This can be useful when loading sparse
	data sets with a fixed structure that only have a couple of variables with data. 
	For example, an Excel-file.
	
	Depends on smu_count_missings_per_var.sas to determine variables that have no
	values.

	\author     Nico Munting
	\date       2018
	\copyright  MIT License
	\version    SAS 9.3
	        
	\param[in]  input_ds  Input data set
	\param[out] output_ds  Output data view that no longer contains the variables 
	            that only have missing values. 

*/ /** \cond */ 

%macro smu_drop_empty_vars(input_ds=, output_ds=); 

	%smu_count_missings_per_var(input_ds=&input_ds., output_ds=work.input_missing); 

	proc sql noprint; 
		select NAME into :non_empty_vars separated by ' '
			from work.input_missing
			where MISSING_PCT <> 100
		; 
	quit; 

	data &output_ds. / view=&output_ds.; 
		set &input_ds.; 
		keep &non_empty_vars.; 
	run; 

	proc datasets library=work nolist; 
		delete input_missing; 
	quit; 
	
%mend smu_drop_empty_vars; 

/** \endcond */
