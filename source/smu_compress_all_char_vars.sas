/**
	\file       smu_compress_all_char_vars.sas

	\brief      Compress all characters variables in a data set
	\details
	Apply the compress function to all character variables in a data set. This can
	be useful to: 
	- remove all non-printing characters from a data set as this can lead to weird
	  behaviour.
	- be sure that a delimiter character does not exist in the data before exporting
	  to a delimited file. 

	\author     Nico Munting
	\date       2018
	\copyright  MIT License
	\version    SAS 9.3

	\param[in]  input_ds  Input data set
	\param[out] output_ds  Output data view 
	\param[in]  compress_chars  [Optional] Characters to compress (2nd argument 
	            of compress function)
	\param[in]  compress_modifiers  Modifiers for compress function (3rd argument
	            of compress function). Default is to compress all non-printing characters
	            using ``'c'`` as the compress modifier.
	\param[out] create_view  [Optional] Creates the output data set as a view. 
		YES or NO (default).
	
	\todo Gracefully handle data sets without character variables. 

*/ /** \cond */ 

%macro smu_compress_all_char_vars(
	input_ds=, 
	output_ds=,
	compress_chars=, 
	compress_modifiers='c',
	create_view=NO 
); 

	%* Compress all characters variables. ;
	data &output_ds.(drop=i) %if "&create_view." = "YES" %then / view=&output_ds.; ;
		set &input_ds.; 

		array char_vars _CHARACTER_; 

		%* Loop through character variables and execute compress function for each one.  ;
		do i=1 to dim(char_vars); 
			char_vars[i] = compress(char_vars[i], &compress_chars., &compress_modifiers.);
		end; 
	run; 

%mend smu_compress_all_char_vars; 

/** \endcond */
