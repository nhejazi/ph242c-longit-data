/* 
 * Longitudinal Project -- BUILD data
 */

capture log close
clear all
use estimation_sample, clear
log using longitudinal2.log, text replace

***
*** Fix Variable Labels
***
label var semester "Semester"
label var pre "Test Score at Start of Semester"
label var post "Test Score at End of Semester"
label var baseline "Test Score at Initial Enrollment"
label var treat "# Sessions per Semester"
label var tot_treat "# Sessions Total"
label var nSemester "# Semesters Since Enrollment"
label var grade "Grade"
label var female "Female"
label var english "Native English Speaker"
label var par_gs "Parent Went to Grad School"
label var sed "Socioeconomically Disadvantaged"

***
*** Data Exploration
***

* overall missingness patterns
misstable summ *, all

* longitudinal missingness patterns
xtset sid semester
xtdescribe


***
*** Exploratory Modeling
*** (using OLS to figure out which 
***  controls to include)
***

* Full model, with everything, and grade/treatment interaction
regress post pre c.treat##ib3.grade ///
			 i.race female english par_gs sed ///
			 if treatCat == 2 & MISS == 0
est store big

* Joint tests of categoricals, and interactions
testparm i.grade
testparm i.grade#c.treat
testparm i.race

* Reduced model, without race and grade/treatment interaction
regress post pre c.treat ib3.grade ///
			 female english par_gs sed ///
			 if treatCat == 2 & MISS == 0
est store mid

regress post pre if treatCat == 2 & MISS == 0
est store small

* Compare the results
est table small mid big, stats(rmse r2 aic bic)
*** Model "mid" is favored by AIC, with rmse
*** and R^2 almost identical to "big", but
*** with (a lot) fewer parameters

* We therefore proceed with the mean structure
* from "mid", with different covariance structures.




***
*** Longitudinal Modeling
***

* We try GEE with Exchangeable correlation
xtgee post pre c.treat ib3.grade ///
			 female english par_gs sed ///
			 if treatCat == 2 & MISS == 0, ///
			 corr(exch) 
est store model1a

* Robustifying the SE's makes a difference
xtgee post pre c.treat ib3.grade ///
			 female english par_gs sed ///
			 if treatCat == 2 & MISS == 0, ///
			 corr(exch) vce(robust)
est store model1b

* Random intercept model, in order to look at
* the proportion of residual variance
* at the person vs. occasion levels
xtreg post pre c.treat ib3.grade ///
			 female english par_gs sed ///
			 if treatCat == 2 & MISS == 0
est store model1c

* Robustifying the SE's makes some difference
xtreg post pre c.treat ib3.grade ///
			 female english par_gs sed ///
			 if treatCat == 2 & MISS == 0, ///
			 vce(robust)
est store model1d

* Compare the results
est table model1*, se p


***
*** Gain-Score Modeling
***
gen gain = post-pre
xtgee gain c.treat ib3.grade ///
			 female english par_gs sed ///
			 if treatCat == 2 & MISS == 0, ///
			 corr(exch) 
est store model2a
xtgee gain c.treat ib3.grade ///
			 female english par_gs sed ///
			 if treatCat == 2 & MISS == 0, ///
			 corr(exch) vce(robust)
est store model2b
xtreg gain c.treat ib3.grade ///
			 female english par_gs sed ///
			 if treatCat == 2 & MISS == 0
est store model2c

* Compare the results
est table model1* model2*
*** Modeling the gain score doesn't seem to help
*** The same coefficients are (non)significant
*** in both cases.  Gain score modeling is equivalent
*** to constraining the coeffcient of "pre" to 1.0
*** (it's already farily close), and imposing this 
*** constraint just biases the estimates of some of
*** the other coefficients that are correlated with
*** "pre".


***
*** Cross-Sectional (Historical) Modeling
***
regress post_n baseline ///
 			 if treatCat == 2 & MISS == 0 & kid_tag, ///
			 vce(robust)
est store history1

regress post_n baseline nSemester ///
 			 if treatCat == 2 & MISS == 0 & kid_tag, ///
			 vce(robust)
est store history2

regress post_n baseline tot_treat nSemester ///
			 female english par_gs sed ///
 			 if treatCat == 2 & MISS == 0 & kid_tag
est store history3a

regress post_n baseline tot_treat nSemester ///
			 female english par_gs sed ///
 			 if treatCat == 2 & MISS == 0 & kid_tag, ///
			 vce(robust)
est store history3b



* Compare SE's, significance, stats
est table history*, se p stats(rmse r2 aic bic)



*** 
*** Compare coefficients across our "best" models
***
est table model1b model1d history3b, se
mat list r(coef)
log close

*** 
*** Presentation Tables
***
label var treat "\# Sessions per Semester"
label var tot_treat "\# Sessions Total"
label var nSemester "\# Semesters Since Enrollment"
esttab model1b model1d history3b using ../results.tex, 			///
	replace booktabs											///
	b("%9.2f") se("%9.2f") star label 							///
	mtitles("Dynamic (GEE)" "Dynamic (RI)" "Cross-sectional")	///
	note("Robust standard errors in parentheses")				///
	nobaselevels order(pre baseline treat tot_treat nSemester)	///
	rename(_cons "(Intercept)")									///
	varlabels(,blist(0.grade "Grade Level \\ \qquad "			///
					 1.grade "\qquad " 2.grade "\qquad "		///
					 4.grade "\qquad " 5.grade "\qquad "))		///
	refcat(4.grade "\qquad 3") wide legend nogaps lines 		///
	scalars(N "N_g Groups" "rho $\rho$") 						///
	sfmt("%9.0f" "%9.0f" "%9.3f")

***
*** Graphics
***
* Generage a printable, xtset-able grade+semester variable
* only for the treated students.
unique sid if tot_treat > 0
local num_stu = `r(sum)'
tempvar grd grd_tag
gen `grd' = 2*grade + mod(semester-1,2) if grade < . & tot_treat > 0
label var `grd' "Grade"
label define `grd' 0 "K" 1 "K" 2 "1" 3 "1"  4 "2"  5 "2" ///
				 6 "3" 7 "3" 8 "4" 9 "4" 10 "5" 11 "5", replace
label values `grd' `grd'
egen `grd_tag' = tag(sid `grd')
replace `grd' = . if `grd_tag' == 0
* plot the graph
xtset sid `grd'
xtline post if tot_treat > 0, overlay legend(off) 			///
			ylabel(-1(1)7) 									///
			xlabel(0(2)11, valuelabel) xticks(1(2)11)		///
			title("Observed Growth Trajectories")			///
			subtitle("Fall 2011 - Spring 2015")				///
			ysize(4) xsize(5.5) name(xtline, replace)		///
			note("Includes `num_stu' students who received any tutoring")
graph export "../figures/xtline.pdf", as(pdf) replace 		///
			name(xtline) 
* restore stuff (tempvars are automatically dropped)
xtset sid semester

