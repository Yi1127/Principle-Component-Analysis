   * ======================================================================================================================================
   * Title: Construct economic activity indicators by applying Principle Component Analysis (PCA)
   * Purpose: This .do file reduces a large set of high-frequency indicators to the smaller ones without major information loss by using weights (loadings) generated from PCA to compute principle components
   * Data input structure: High-frequency time series data in a wide format
   * Time frequency: Monthly
   * Time coverage: 2020m1-
   * Sample Country: India
   * Created on: 11/04/2020
   * Last updated on: September 2020
   * References: J.P.Morgan: https://markets.jpmorgan.com/research/email/rcfghfjn/QAxnMEkJ1lR1GvcT9gLv0Q/GPS-3424872-0
   *             Kaiser, 1960, The Application of Electronic Computers to Factor Analysis
   *             Abdi, 2010, Principal Component Analysis
   *=======================================================================================================================================
   
	clear all 
	set more off

	local projFolder "C:\Users\wb561795\OneDrive - WBG\Valerie's\Supply Side GDP SAR\Principle Components Analysis"
	local dataFolder "`projFolder'/STATA_input\Updated"
	local outputFolder "`projFolder'/STATA_ouput"

	capture log close
	log using "`outputFolder'/example", replace
     /*=======================================================================================================================================================================================================================================================**
                                                                                 STEP 1: Load the high-frequency time series data  (Note: Data was already transformed to the wide format before importing to Stata)
**========================================================================================================================================================================================================================================================*/	
	use "`dataFolder'/HF_IND_pcaanalysis_wide", clear                                                                         

 * Selected indicators
	local indicators                                                             ///
	electricityg_gwh                                                             /// electricity generation
	ewaybilltot_lcu                                                              /// e-way bill
	expnonoil_usd_mln                                                            /// export, non oil 
	impnonoil_usd_mln                                                            /// import, non oil
	ip_2010usd_sa                                                                /// Industrial Production, constant 2010 USD, sa 
	pmmanu_indx_nsa                                                              /// Manufacturing PMI, nsa
	petroleumcons_tonneth                                                        /// Petroleum consumption
	portcargo_tonnemln                                                           /// Port cargo traffic, tonne mln
	railfreight_tonnemn                                                          /// Railway Traffic (Container Service),Tonne mln
	crudesteelprod_tonneth                                                       /// Crude steel production, tonne thousand
	ipiconstr_2011                                                               /// Industrial Production Index: Infrastructure & Construction Goods
	carregistr_u_sa                                                              /// Car registrations
	pmserv_indx_nsa                                                              /// Service PMI, nsa
	aircargotraff_tonneth                                                        /// Air cargo traffic, tonne th
	airpassngtraff_p                                                             /// Air passenger traffic, person
	
	
  * explore the data                                                                                
	describe `indicators'
	corr `indicators'                                                            // the more corrrelated of the data, the better to apply the PCA

/*=======================================================================================================================================================================================================================================================**
                                                                                 STEP 2: Generate weights (loadings) by PCA
**========================================================================================================================================================================================================================================================*/
	
	* Determine the number of component
	pca `indicators', mineigen(1)                                                // select # components with eigenvalues greater than 1 based the eigenvalue-one criterion (Kaiser, 1960)                                                             
	screeplot, yline(1)                                                          // scree plot help examine if there is a "break" in the plot with remaining components explaining considerably less variation
	
	* Component rotations
	rotate, varimax blanks( .3)                                                  // to facilitate interpretation (Abdi, 2010)
	
    * Scatter plots of the loadings and score variables                          // ! only applicable to data with more than one component
	loadingplot                                                                  // plot loadings of indicators in the data
	local id date_m                                                              // ! change to your date variable
	scoreplot, mlabel(`id')                                                      // check the outliers of observations                                                                             
	
	
	* Estimate the principle-components loadings
	predict pc1 pc2, score                                                       // ! reduce or add additional variables according to the determined # of components
	return list
	mat A=r(scoef)
	mat list A
	
	local a=rowsof(A)
    local b=colsof(A)
	
	
	if (0==1){
		mat B=J(rowsof(A),colsof(A),0)
		mat list B
		
	   forvalues i =1/`a'{
	   forvalues j =1/`b'{
		   if abs(A[`i',`j'] < 0.3) {                                            // generate a new matrix B that only contains indicators with loadings greater than  .3 in each component                                    
		   mat B[`i',`j']=0
		}
		   else {
		   mat B[`i',`j']= A[`i',`j']
		   }
	   }
	   }
		mat list B	
	}
		
/*=======================================================================================================================================================================================================================================================**
                                                                                  STEP 3: Construct principle components (economic activity indicators)
**========================================================================================================================================================================================================================================================*/

     * compute principle components weighted by loadings	
		forvalues j=1/`b'{
		gen component`j'=0
		}
		
		  foreach var of varlist `indicators' {
			forvalues i = 1/`a' {
			forvalues j = 1/`b' {
			replace component`j'=component`j'+ `var'* A[`i',`j']
			}
			}
		  }

    * Indexed with January 2020 = 100
	 foreach var of varlist component* {
	 gen `var'_ind=(`var'/`var'[1])*100
	 
	 }
	
/*=======================================================================================================================================================================================================================================================**
                                                                                  STEP 4: Export the date and principle components to excel file
**========================================================================================================================================================================================================================================================*/
	
	keep date_m *ind
	export excel using "`outputFolder'/Principle components.xlsx", firstrow(variable) replace
	 
	 
	 
	log close

