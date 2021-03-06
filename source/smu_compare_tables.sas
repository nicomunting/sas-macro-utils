/**
	\file       smu_compare_tables.sas

	\brief      Compare two tables based on PROC COMPARE
	\details    
	Macro to make the use of PROC COMPARE easier. 
	- Sorting of the base and compare data sets on the ID variables
	  is taken care of. 
	- Variables can be easily excluded instead of exhaustively listing 
	  all variables that do need comparison. 
	- A summary data set is created, or appended to, that contains the 
	  information provided by the PROC COMPARE return code. This makes 
	  it easy to judge the outcome for a large number of data sets at
	  a glance. 
	See https://github.com/nicomunting/sas-macro-utils for more detailed 
	examples. 

	\author     Nico Munting
	\date       2019 - 2020
	\copyright  MIT License
	\version    SAS 9.4

	\param[in]  base_ds  Base data set for PROC COMPARE
	\param[in]  compare_ds  Compare data set for PROC COMPARE
	\param[out] prefix  Prefix used for output data sets. 
	\param[in]  out_options  [Optional] Output options used for PROC COMPARE. Default
	            is <tt>outall outnoequal</tt>. Do not forget to use macro quoting 
	            to avoid syntax errors. 
	\param[in]  id_vars  [Optional] ID variables used in PROC COMPARE.
	\param[in]  exclude_vars  [Optional] Variables to exclude from comparison. 
	\param[in]  compare_options  [Optional] Additional options to use for PROC COMPARE. 
	            For example <tt>\%str(method=absolute criteria=0.0000001 maxprint=(50, 5000))</tt>. 
	            Do not forget to use macro quoting to avoid syntax errors. 
	\param[out] summary_ds  [Optional] Name of output data set to which summarized 
	            results will be appended. 

*/ /** \cond */ 

%macro smu_compare_tables(
	base_ds=,
	compare_ds=, 
	prefix=, 
	out_options=%str(outall outnoequal),
	id_vars=, /* Optional */
	exclude_vars=, /* Optional */ 
	compare_options=, /* Optional */
	summary_ds= /* Optional */ 
);

	%local base_sort_order comp_sort_order base_sorted comp_sorted; 

	/** Determine if sorting is required **/

	%if "&id_vars." ne "" %then %do; 

		proc contents data=&base_ds. out=work.smu_base_contents noprint; 
		proc contents data=&compare_ds. out=work.smu_comp_contents noprint; 
		run;

		proc sql noprint;
			select NAME into :base_sort_order separated by ' '
				from work.smu_base_contents
				where SORTEDBY is not null
				order by SORTEDBY
			; 
			select NAME into :comp_sort_order separated by ' ' 
				from work.smu_comp_contents
				where SORTEDBY is not null
				order by SORTEDBY
			; 
		quit;

		%let base_sorted = %eval(%symexist(base_sort_order) and "%left(%trim(%lowcase(&id_vars.)))" eq "%left(%trim(%lowcase(&base_sort_order.)))");
		%let comp_sorted = %eval(%symexist(comp_sort_order) and "%left(%trim(%lowcase(&id_vars.)))" eq "%left(%trim(%lowcase(&comp_sort_order.)))");
	%end;
	%else %do; 
		%let base_sorted = 1; 
		%let comp_sorted = 1;
	%end; 

	%if not &base_sorted. %then %do; 
		proc sort data=&base_ds. out=work.&prefix._before; 
			by &id_vars.; 
		run; 
	%end; 
	%if not &comp_sorted. %then %do; 
		proc sort data=&compare_ds. out=work.&prefix._after; 
			by &id_vars.; 
		run;
	%end; 


	/** Execute comparison **/
 
	title "Compare of %upcase(&base_ds.) with %upcase(&compare_ds.)"; 
	proc compare 
		%if not &base_sorted. %then base=work.&prefix._before(drop=&exclude_vars.); 
		%else base=&base_ds.(drop=&exclude_vars.);
		%if not &comp_sorted. %then compare=work.&prefix._after(drop=&exclude_vars.); 
		%else compare=&compare_ds.(drop=&exclude_vars.);
		out=&prefix._diff &out_options.
		listvar
		&compare_options.
	; 
		%if "&id_vars." ne "" %then id &id_vars.; ;
	run; 
	title; 


	/** Populate summary table if requested **/

	%if "&summary_ds." ne "" %then %do; 
		%let comp_sysinfo = &sysinfo.; 

		data work.smu_summary_new; 
			attrib
				base_ds length=$41 label='Base data set' 
				compare_ds length=$41 label='Compare data set'
				prefix length=$32 label='Output prefix used for data set'
				sysinfo length=8 label='PROC COMPARE return code'
				binary_sysinfo length=$16 label='PROC COMPARE return code in binary form'
				DSLABEL length=8 label='Data set labels differ'
				DSTYPE length=8 label='Data set types differ'
				INFORMAT length=8 label='Variable has different informat'
				FORMAT length=8 label='Variable has different format'
				LENGTH length=8 label='Variable has different length'
				LABEL length=8 label='Variable has different label'
				BASEOBS length=8 label='Base data set has observation not in comparison'
				COMPOBS length=8 label='Comparison data set has observation not in base'
				BASEBY length=8 label='Base data set has BY group not in comparison'
				COMPBY length=8 label='Comparison data set has BY group not in base'
				BASEVAR length=8 label='Base data set has variable not in comparison'
				COMPVAR length=8 label='Comparison data set has variable not in base'
				VALUE length=8 label='A value comparison was unequal'
				TYPE length=8 label='Conflicting variable types'
				BYVAR length=8 label='BY variables do not match'
				ERROR length=8 label='Fatal error: comparison not done'
			;

			base_ds = "&base_ds."; 
			compare_ds = "&compare_ds.";
			prefix = "&prefix."; 
			sysinfo = &comp_sysinfo; 
			binary_sysinfo = put(sysinfo, binary16.); 

			* Read out individual bits to get a proper view of the changes seen by PROC COMPARE. 
			  See SAS 9.4 PROC COMPARE documentation about the details of the return codes: 
			  https://documentation.sas.com/?docsetId=proc&docsetVersion=9.4&docsetTarget=n1jbbrf1tztya8n1tju77t35dej9.htm&locale=nl
			;
			%if "&id_vars." eq "" or (&base_sorted. and &comp_sorted.) %then %do;
				DSLABEL = substr(reverse(binary_sysinfo), 1, 1); 
				DSTYPE = substr(reverse(binary_sysinfo), 2, 1);
			%end; 
			INFORMAT = substr(reverse(binary_sysinfo), 3, 1);
			FORMAT = substr(reverse(binary_sysinfo), 4, 1);
			LENGTH = substr(reverse(binary_sysinfo), 5, 1);
			LABEL = substr(reverse(binary_sysinfo), 6, 1);
			BASEOBS = substr(reverse(binary_sysinfo), 7, 1);
			COMPOBS = substr(reverse(binary_sysinfo), 8, 1);
			BASEBY = substr(reverse(binary_sysinfo), 9, 1);
			COMPBY = substr(reverse(binary_sysinfo), 10, 1);
			BASEVAR = substr(reverse(binary_sysinfo), 11, 1);
			COMPVAR = substr(reverse(binary_sysinfo), 12, 1);
			VALUE = substr(reverse(binary_sysinfo), 13, 1);
			TYPE = substr(reverse(binary_sysinfo), 14, 1);
			BYVAR = substr(reverse(binary_sysinfo), 15, 1);
			ERROR = substr(reverse(binary_sysinfo), 16, 1);
		run; 

		proc append base=work.&summary_ds. data=work.smu_summary_new; 
		run;

	%end; 

	proc datasets lib=work nodetails nolist nowarn; 
		delete smu_summary_new smu_base_contents smu_comp_contents; 
	quit; 

%mend smu_compare_tables; 

/** \endcond */
