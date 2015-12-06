use "C:\Users\jmason888\Desktop\BUILD11_14_wide.dta", clear
lab def semester 1 "Fall 2011" 2 "Spring 2012" ///
			     3 "Fall 2012" 4 "Spring 2013" ///
				 5 "Fall 2013" 6 "Spring 2014" ///
				 7 "Fall 2015" 8 "Spring 2015"
ren grade11 grade_S1
gen grade_S2 = grade_S1
ren grade12 grade_S3
gen grade_S4 = grade_S3
ren grade13 grade_S5
gen grade_S6 = grade_S5
ren grade14 grade_S7
gen grade_S8 = grade_S7

drop buildgroup*
* school?

* fall 2011 (S1)
gen pre_S1  = .   // ren RIntv11_1 pre_S1
gen post_S1 = .  //  ren RIntv11_2 post_S1
ren fallSessions11 treat_S1

* spring 2012 (S2)
gen pre_S2 = post_S1
ren RIntv11_3 post_S2
ren sprSessions11  treat_S2

drop sumSessions12 

* fall 2012 (S3)
ren RIntv12_1 pre_S3
ren RIntv12_2 post_S3
ren fallSessions12 treat_S3

* spring 2013 (S4)
gen pre_S4 = post_S3
ren RIntv12_3 post_S4
ren sprSessions12 treat_S4

* fall 2013 (S5)
ren RIntv13_1 pre_S5
ren RIntv13_2 post_S5
ren fallSessions13 treat_S5

* spring 2014 (S6)
gen pre_S6 = post_S5
ren RIntv13_3 post_S6
ren sprSessions13 treat_S6

* fall 2014 (S7)
ren RIntv14_1 pre_S7
ren RIntv14_2 post_S7
ren fallsessions14 treat_S7

* spring 2015 (S8)
gen pre_S8 = post_S7
ren RIntv14_3 post_S8
ren sprsessions14 treat_S8





*** get more data here, then add to the above
ren eng_prof13 eng_prof_S5
gen eng_prof_S6 = eng_prof_S5
ren eng_prof14 eng_prof_S7
gen eng_prof_S8 = eng_prof_S7

ren sped13 sped_S5
gen sped_S6 = sped_S5
ren sped14 sped_S7
gen sped_S8 = sped_S7

ren school13 school_S5
gen school_S6 = school_S5
ren school14 school_S7
gen school_S8 = school_S7




drop RLevel*
drop RProf*
drop R??spani*
drop CST*
drop spr_SES13  
drop sumSite12 sum13_riskG sumSessions*
drop tutoring14 
drop tid14

drop if tutsite14 == 2
drop build_busd14 build_cbo14 tutsite14
drop testedspanish14 source

replace race13 = race14 if race13 == .
ren race13 race
drop race14

replace female13 = female14 if female13 == .
ren female13 female
drop female14

replace primlang13 = primlang14  if primlang13  == .
ren primlang13  primlang
drop primlang14

ren sed14 sed
ren parened13 pared

order sid race female pared primlang sed ///
	grade_S* treat_S* pre_S* post_S* ///
	eng_prof_S* sped_S* school_S*

reshape long grade_S treat_S pre_S post_S ///
	eng_prof_S sped_S school_S, ///
	i(sid) j(semester)

lab values semester semester

ren grade_S grade
ren treat_S treat
ren pre_S pre
ren post_S post
ren eng_prof_S eng_prof
ren sped_S sped
ren school_S school

egen treatCat = cut(treat), at(0,1,5,1000) icodes 
lab def treatCat 0 "Non-participant" 1 "Backup Student" ///
				 2 "Regular Participant"
lab val treatCat treatCat




**
** Drop observations with no pretest
**
drop if pre == .
drop if post == .
replace treatCat = 0 if treat==.
replace treat=0 if treat==.

sort sid semester
by sid: gen baseline = pre[1]
egen nSemester = count(sid), by(sid)
