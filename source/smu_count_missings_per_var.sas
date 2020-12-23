/**
	\file       smu_count_missings_per_var.sas

	\brief      Count number of missing values for each column or variable. 
	\details
	Macro to count the number of missing records for each variable or column in 
	an input data set. 
	The output is a data set with the count of missing and non-missing records 
	for each variable in the input data set. 

	This macro is based on the idea presented in the following NESUG article: 
	Calculating Missing Value Counts - Loren Lidsky (NESUG 1993 Proceedings)
	https://lexjansen.com/nesug/nesug93/NESUG93033.pdf
	
	\author     Nico Munting
	\date       2018 - 2020
	\copyright  MIT License
	\version    SAS 9.3
	        
	\param[in]  input_ds  Input data set containing the variables of which missings
	            need to be counted. 
	\param[out] output_ds  Output data set containing the count of missing per variable. 

*/ /** \cond */ 

%macro smu_count_missings_per_var(input_ds=, output_ds=);

	proc contents 
		data=&input_ds. 
		out=ds_contents(keep=NAME TYPE VARNUM LABEL) 
		noprint
	; 
	run;

	proc sort data=ds_contents; 
		by VARNUM;
	run;

	%let n_vars = 0;

	data _null_;
		set ds_contents nobs=n_vars end=last;

		if TYPE = 1 then n_num_vars + 1;
		else if TYPE = 2 then n_char_vars + 1; 

		if last then do; 
			call symput('n_vars', left(put(n_vars,8.)));
			call symput('n_num_vars', left(put(n_num_vars,8.)));
			call symput('n_char_vars', left(put(n_char_vars,8.)));
		end; 
	run;

	data &output_ds.;
		set &input_ds. end=last;

		%if &n_vars. > 0 %then %do;
			%if &n_num_vars. > 0 %then array num_vars [*] _numeric_; ;
			%if &n_char_vars. > 0 %then array char_vars [*] _character_; ; 
			array count [&n_vars.];

			dsid = open("&input_ds."); 

			%if &n_num_vars. > 0 %then %do;
				%* Loop over all numeric vars and count the missings. ; 
				do num_iter = 1 to dim(num_vars);
					num_var_nm = vname(num_vars[num_iter]); 
					num_var_no = varnum(dsid, num_var_nm); 
					if missing(num_vars[num_iter]) then count[num_var_no] + 1;
				end;
			%end;
			%if &n_char_vars. > 0 %then %do;
				%* Loop over all character vars and count the missings. ; 
				do char_iter = 1 to dim(char_vars);
					char_var_nm = vname(char_vars[char_iter]); 
					char_var_no = varnum(dsid, char_var_nm); 
					if missing(char_vars[char_iter]) then count[char_var_no] + 1;
				end;
			%end;

			rc = close(dsid); 

			%* Get total observations using observation number instead of nobs-option 
			  on set-statement as the latter does not work with views. ; 
			totobs = _n_; 

			if last then do var_iter = 1 to &n_vars.; 
				set ds_contents point=var_iter;
				MISSING_NO = sum(count[var_iter], 0);
				NON_MISSING_NO = totobs - MISSING_NO;
				MISSING_PCT = (MISSING_NO / totobs) * 100;

				output;
			end;

		%end; 
		%else %do; 
			%* In case there are no variables to check, output empty data set. ;
			if 0 then set ds_contents;
			length MISSING_NO NON_MISSING_NO MISSING_PCT 8.;
			stop;
		%end; 

		keep NAME LABEL MISSING_NO NON_MISSING_NO MISSING_PCT;
	run;

	proc datasets library=work nolist; 
		delete ds_contents; 
	quit; 

%mend smu_count_missings_per_var;

/** \endcond */
