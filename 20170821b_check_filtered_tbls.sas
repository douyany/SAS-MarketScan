options symbolgen;
options mlogic ;
*options minoperator;

/* filename: 
u:\folderlocation
20170821_check_filtered_tbls.sas

Date created:
August 31, 2017

Now that the cohort tables are pulled,
This do-file pulls out the specific records for those procedures from the tables, for the enrolid that had the procedure of interest

When checking for the various procedures and diagnoses in the lists,
will want to keep the date of the event
the 0/1 (no / yes) for which event of interest

Will have to check
*icd-9 diagnoses
*cpt procedures
*icd-9 procedures

*/




***read in the other libnames:;
libname crosdir "E:\folderlocation";
libname project "E:\folderlocation";


***load other needed formats;
%include 'e:\theotherneededfiles.sas';

%include 'X:\listofprocanddiagsofinterest.sas';
/*

***this one will apply specifically to the age at the time of the procedure
 
**age < 18;
***from clarification on August 31, 2017;
***do include the 18-year-olds;
if age<18 then delete;
*/



%macro applyrestrictions(whichage);
%put Adding the Restrictions;
%put Delete off obs without enrolid;
**keep only females;
**sex is a character field;
if sex='1' then delete;

***as a limit, the youngest anyone can be at the earliest part of the history;
***at twelve months prior to procedure is 17 years;
***will remove the people who are younger than 17 years;
if age<&whichage then delete;
***will need to have additional filter on the main cohort;
***to make sure that patient is over 18 at the time of procedure of interest;

***delete obs without enrolid;
if enrolid=. then delete;

%mend;



%macro codetheprocs(whichproccat, whichstopnum, isefftable);

%put Adding the particular Proc codes;
%put _local_;


%let whichprocslot=1;
***start n at 1;

%if &isefftable=1 %then %do;
***will set proctyp as "" to not get error message;
**from Users Guide: All procedure codes on the Facility Header Table ;
***use the ICD-9-CM procedure coding system.;
	proctyp="*";
%end;


%do %while (&whichprocslot <= &whichstopnum);


***for each of the procedure codes of interest;
***go up to n;



***check for CPT procedure in procedure codes;
***CPT codes;
%local i next_code;
%let i=1;
%do %while (%scan(&&&whichproccat.cpt, &i) ne );
*input next_code $10;
	%let next_code = %scan(&&&whichproccat.cpt, &i);
		%put checking inside first i loop;
		%put the CPT next procedure is &next_code;
	***whether has that procedure;
	if proc&whichprocslot.="&next_code" and proctyp="" then has&whichproccat.proc=1;
	if proc&whichprocslot.="&next_code" and proctyp="1" then  has&whichproccat.proc=1;

*drop next_code;
	%let i=%eval(&i + 1);
%end;	


**ICD-9 codes;
%local j next_code;
%let j=1;
%do %while (%scan(&&&whichproccat.icdp, &j) ne  );
*input next_code $10;
	%let next_code = %scan(&&&whichproccat.icdp, &j);
	
	%put the ICD-9 next procedure is &next_code;
		
	if compress(proc&whichprocslot.)="&next_code" and proctyp="" then has&whichproccat.proc=1;
	if compress(proc&whichprocslot.)="&next_code" and proctyp="*" then has&whichproccat.proc=1;
	
*drop next_code;	
	%let j=%eval(&j + 1);
%end;	


** move to the next proc in that table;
%let whichprocslot=%eval(&whichprocslot+1); 

** end for the whichprocslot loop;
%end;	

***close the proc macro;
%mend;





%macro codethediags(whichdiagcat, whichstopnum);

%put Checking for particular diagnosis codes;
%put _local_;

%let whichdxslot=1; 
**start n at 1;

%do %while (&whichdxslot <= &whichstopnum);

	%local k next_code;

	%let k=1;
	%do %while (%scan(&&&whichdiagcat.icdd, &k) ne );
		%let next_code = %scan(&&&whichdiagcat.icdd, &k);
		%put next_code is &next_code;		
		***info about using pctquote:;
		**https://v8doc.sas.com/sashtml/macro/z14quote.htm;
		
		*if %quote(compress(dx&whichdxslot.))=&next_code and checkvar=newvar then has&whichdiagcat.diag=1;
		if compress(dx&whichdxslot.)="&next_code" then has&whichdiagcat.diag=1;		
		***for the one just checking dx1;
		***only needs to run for when whichdxslot equals one;
		***checking that diagnosis occurs in dx1;
		***have a specific var for checking that aspect;
		*%if &whichdxslot=1 %then %do;
		*if compress(dx1)=%str(&next_code) and checkvar=newvar then dx1&whichdiagcat.diag=1;
		*%end;
		%let k=%eval(&k + 1);
	%end;	/* close loop for k */		
	
/* move to the next dx in that table */
%let whichdxslot=%eval(&whichdxslot+1); 


%end; /* close loop for whichdxslot (the loop of dx) */		

***close the diags macro;
%mend ;








%macro codeinorder(whichaspect, whichage, hasproclist, hasdiaglist, isefftable, maxprocnum, maxdiagnum);

%put running the code in order;
%put _local_;

%applyrestrictions(&whichage);

***add the new var;
has&whichaspect.proc=0;


%if &hasproclist=1 %then %do;
	%codetheprocs(&whichaspect, &maxprocnum, &isefftable);
%end;

***add the new var;
has&whichaspect.diag=0;
dx1&whichaspect.diag=0;

%if &hasdiaglist=1 %then %do;
	%codethediags(&whichaspect, &maxdiagnum);
%end;	


***delete cases not having either procedure or the diagnosis;
if has&whichaspect.proc=0 & has&whichaspect.diag=0 then delete;

***end the code in order macro;
%mend;



***the macro to run the processing on each cohort table (f,i,o,s);
%macro runoncohtbl (whichaspect, whichage, hasproclist, hasdiaglist);
***check o table:;
data crosdir.filterfebr03_o (keep=enrolid svcdate 
has&whichaspect.proc has&whichaspect.diag dx1&whichaspect.diag 
 age    );
set crosdir.cohort_o;

%codeinorder(whichaspect=&whichaspect, whichage=&whichage, 
hasproclist=&hasproclist, hasdiaglist=&hasdiaglist, isefftable=0,
maxprocnum=1, maxdiagnum=4);

run;

**need to re-sort fields so that theyll be in the correct order;
***for the union;
data crosdir.filterfebr03_o;
retain enrolid svcdate 
has&whichaspect.proc has&whichaspect.diag dx1&whichaspect.diag 
 age    ;
set crosdir.filterfebr03_o;
run;

***run summary stats;
***source is not a numeric field;
proc means data=crosdir.filterfebr03_o;
run;

***check s table;
data crosdir.filterfebr03_s (keep=enrolid svcdate 
has&whichaspect.proc has&whichaspect.diag dx1&whichaspect.diag
 age    );
set crosdir.cohort_s;

%codeinorder(whichaspect=&whichaspect, whichage=&whichage,
hasproclist=&hasproclist, hasdiaglist=&hasdiaglist, isefftable=0,
maxprocnum=1, maxdiagnum=4);

run;

**need to re-sort fields so that theyll be in the correct order;
***for the union;
data crosdir.filterfebr03_s;
retain enrolid svcdate 
has&whichaspect.proc has&whichaspect.diag dx1&whichaspect.diag 
 age    ;
set crosdir.filterfebr03_s;
run;

***run summary stats;
***source is not a numeric field;
proc means data=crosdir.filterfebr03_s;
run;



***the facility header table;
***proctyp does not appear in facility header tbl;

***nine diagnoses;
data crosdir.filterfebr03_f (keep=enrolid svcdate 
has&whichaspect.proc has&whichaspect.diag dx1&whichaspect.diag 
 age    );
set crosdir.cohort_f;

%codeinorder(whichaspect=&whichaspect, whichage=&whichage,
hasproclist=&hasproclist, hasdiaglist=&hasdiaglist, isefftable=1,
maxprocnum=6, maxdiagnum=9);

run;


**need to re-sort fields so that theyll be in the correct order;
***for the union;
data crosdir.filterfebr03_f;
retain enrolid svcdate 
has&whichaspect.proc has&whichaspect.diag dx1&whichaspect.diag 
 age    ;
set crosdir.filterfebr03_f;
run;

***run summary stats;
***source is not a numeric field;
proc means data=crosdir.filterfebr03_f;
run;


***the inpatient admissions table;
***will skip using this table;
***will get information about inpatient procedures from Ess table;




***take the distinct dates of procedures between the three tables of f, o, s;
***take a union of the three tables;
****stack the rows from the F, I, O, S tables;
proc sql;
create table crosdir.hv&whichaspect as 
select sub.enrolid, sub.svcdate, max(sub.has&whichaspect.proc) as max&whichaspect.proc, max(sub.has&whichaspect.diag) as max&whichaspect.diag,
	max(sub.age) as age  
from
(
select * from crosdir.filterfebr03_o
union
select * from crosdir.filterfebr03_s
union
select * from crosdir.filterfebr03_f
) sub
group by sub.enrolid, sub.svcdate
order by  sub.enrolid, sub.svcdate
;
quit;



****add row numbering;
***added count variable using info from http://www.ats.ucla.edu/stat/sas/faq/enumerate.htm;
data crosdir.hv&whichaspect._rows;
set crosdir.hv&whichaspect;
countrec+1;
by enrolid;
if first.enrolid then countrec=1;
run;

***only want the first observation from each enrolid;
data crosdir.hv&whichaspect._firstrow  (drop=countrec);
set crosdir.hv&whichaspect._rows;
if countrec>1 then delete;
run;

***make the information about that aspect of interest;
***wide rather than long;
***reshape to wide format;
***for arrival;
proc transpose data=crosdir.hv&whichaspect._rows 
out=crosdir.hv&whichaspect._wide (drop=_name_ _label_)
prefix=&whichaspect._dt;
by enrolid;
id countrec;
var svcdate;
run;



***close the run on cohort table macro;
%mend runoncohtbl;

****;
****;
****end of macros;
****;
****;

***run the cohort table macro for patient procedure of interest;
***the procedure of interest;
***has CPT and ICD-9 proc codes;
***this aspect has a higher (stricter) age cut-off than the other aspects;
***this cut-off is at age 18;
***the other ones are more generous at age 17;
%runoncohtbl(whichaspect=pengui, whichage=18, hasproclist=1, hasdiaglist=0);

/* rest of the %runoncohtbl calls go here */