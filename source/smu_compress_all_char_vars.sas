/**
	\file       smu_compress_all_char_vars.sas

	\author     Nico Munting
	\date       2018
	\copyright  MIT License
	\version    SAS 9.3

	\brief      Compress all characters variables in a dataset
	\details
	???
	        
	\param[in]  input_ds  Input data set
	\param[out] output_ds  Output data set (view) 
	\param[in]  compress_chars  [Optional] Characters to compress (2nd argument 
	            of compress function)
	\param[in]  compress_modifiers  Modifiers for compress function (3rd argument
	            of compress function). Default is to compress all non-printing characters
	            using ``'c'`` as the compress modifier.
	                       
*/ /** \cond */ 

%macro smu_compress_all_char_vars(
	input_ds=, 
	output_ds=,
	compress_chars=, 
	compress_modifiers='c' 
); 

	/* Compress all characters variables */
	data &output_ds.(drop=i) / view=&output_ds.; 
		set &input_ds.; 

		array char_vars _CHARACTER_; 

		* Loop through character variables and execute compress function for each one.  ;
		do i=1 to dim(char_vars); 
			char_vars[i] = compress(char_vars[i], &compress_chars., &compress_modifiers.);
		end; 
	run; 

%mend smu_compress_all_char_vars; 

/** \endcond */
