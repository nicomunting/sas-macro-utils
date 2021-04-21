/**
	\file       smu_drop_empty_rows.sas

	\brief      Drop all rows from a dataset that only have missing values. 
	\details
	Macro that takes a data set as an input, determines which rows have only
	missing values and drops these observations (i.e., records or rows). This can 
	be useful in case of loading an Excel-file.

	\author     Nico Munting
	\date       2021
	\copyright  MIT License
	\version    SAS 9.4
	        
	\param[in]  input_ds  Input data set
	\param[out] output_ds  Output data view that no longer contains the rows 
		that only have missing values. 
	\param[out] create_view  [Optional] Creates the output data set as a view. 
		YES or NO (default).

*/ /** \cond */ 

%macro smu_drop_empty_rows(input_ds=, output_ds=, create_view=NO); 

	proc contents 
		data=&input_ds. 
		out=ds_contents(keep=NAME TYPE VARNUM LABEL) 
		noprint
	; 
	run;

	data _null_;
		set ds_contents nobs=n_vars end=last;

		if last then do; 
			call symput('n_vars', left(put(n_vars,8.)));
		end; 
	run;

	data &output_ds. %if "&create_view." = "YES" %then / view=&output_ds.; ;
		set &input_ds.; 
		if cmiss(of _all_) < &n_vars.;
	run; 

	proc datasets library=work nolist; 
		delete ds_contents; 
	quit; 
	
%mend smu_drop_empty_rows; 

/** \endcond */
