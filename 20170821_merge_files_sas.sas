/* filename: 
u:\folderlocation
20170821_merge_files_sas.sas

Date created:
September 19, 2017

Now that the tables for the individual aspects of interest are pulled,
This do-file checks those dates against the reference dates, for the enrolid that had the procedure of interest

When checking for the various procedures and diagnoses in the lists,
will want to keep the date of the event
the 0/1 (no / yes) for which event of interest


*/

options symbolgen;
options mlogic ;

***read in the other libnames:;
libname crosdir "E:\folderlocation";
libname project "E:\folderlocation";

proc format;
value yesnolbl 0="No"
	1="Yes";
run;	

***load other needed formats;
%include 'e:\theotherneededfiles.sas';

***listing out the num for the other procedures;
%macro checknumdates(whichfile);

***how many different dates are available for that aspect;
title "number of dates for this aspect: &whichfile";
proc print data=crosdir.hv&whichfile._wide (obs=1);
run;

%mend checknumdates; 


***info from http://support.sas.com/techsup/notes/v8/25/082.html;
***how to check if variable is present;
%macro varcheck(whichaspectfile);

***the initial (minimum amount of aspect vars in a dataset will be one);

***make whichmax a global var, so that it can be referenced in the other macro;
%global whichmax;
%let whichmax=1;
%let stillchecking=1;
%let theoneinquestion=2;

 %let dsid = %sysfunc(open(crosdir.hv&whichaspectfile._wide));
 
%do %while (&stillchecking > 0);
 
 %let stillchecking = %sysfunc(varnum(&dsid,&whichaspectfile._dt&theoneinquestion));

		***move to the next variable (in the counter) to test;
		***values were successful, so can increase;
		
		***otherwise would exit without increase;
		%if  &stillchecking>0 %then %do ;
		%let whichmax=%eval(&whichmax + 1);
		%let theoneinquestion=%eval(&theoneinquestion + 1);
		%end;

 %end;	/* close loop for stillchecking */		

 %put the last present value is &whichmax;
 
%let rc = %sysfunc(close(&dsid));
 




%mend varcheck;


***;
***this program doesnt work;
***will use output from proc means;
***;
***checking to see which variable is the last one to have non-missing values;
%macro lastwithnonmissvalues(newfilename, whichaspectfile);

***the initial (minimum amount of aspect vars in a dataset within the time window will be zero);
***is set to zero;
%let maxpresent=0;
%let stillchecking=1;
%let theoneinquestion=1;

 %let dsid = %sysfunc(open(crosdir.hv&newfilename));
 
%do %while (&stillchecking > 0);
 
 %let stillchecking = %sysfunc(n(&dsid,&whichaspectfile._gap&theoneinquestion));

		***move to the next variable (in the counter) to test;
		***values were successful, so can increase;
		
		***otherwise would exit without increase;
		%if  &stillchecking>0 %then %do ;
		%let maxpresent=%eval(&maxpresent + 1);
		%let theoneinquestion=%eval(&theoneinquestion + 1);
		%end;

 %end;	/* close loop for stillchecking */		

 %put the last variable with at least one non-missing observation is &maxpresent;
 
%let rc = %sysfunc(close(&dsid));
 




%mend lastwithnonmissvalues;









%macro addthataspect(whichexistingfile, whichaspectfile,
whichformalname,
checkforany, 
whichrefdate, startwindow, endwindow);

***find the maximum value of dates to check;
***call the varcheck macro;
%varcheck(&whichaspectfile);

***calculate the new value for the new file;
***it will be one higher than the current number;
%let newfilename=%eval(&whichexistingfile+1);
%put the old files number is &whichexistingfile;
%put the new files number will be &newfilename;

data crosdir.hvpengui&newfilename (drop=i filledyet changethisround);
merge crosdir.hvpengui&whichexistingfile (in=inhvproc)
crosdir.hv&whichaspectfile._wide;
by enrolid;

***get rid of the observations that are not already existing in the dataset;
***do not want extra enrolid to get added through the process of merging;
if inhvproc~=1 then delete;

***create the missing values for the daysgap array;
array createstayarray {&whichmax} &whichformalname._gap1-&whichformalname._gap&whichmax.;
do i=1 to &whichmax;
createstayarray(i)=.;
end;

***at first, set everyones whichslot to one;
whichslot=1;




***check aspect occurrence dates against date of interest;
***cycle through the dates;
array &whichaspectfile.array &whichaspectfile._dt1 - &whichaspectfile._dt&whichmax.;

do over &whichaspectfile.array;

***first start with every obs open to change;
***obs will change over to value of one, once has filled;
filledyet=0;
changethisround=0;

***create a var to signal to change

***start from the lowest slot and go to the max slot;
%let whichindicator=1;

%do %while (&whichindicator <= &whichmax);


***a cohesive var to indicate that this ob should change during this round;
if &startwindow<=&whichaspectfile.array - &whichrefdate<=&endwindow  
		and  whichslot=&whichindicator  
		and  filledyet=0 
		then 
		changethisround=1;

		***check if this date falls within the window of interest;
***also has to meet condition of matching to this particular slot;
***and that this date has not yet been filled into one of the slots;
if changethisround=1 then 		
		&whichformalname._gap&whichindicator = &whichaspectfile.array-&whichrefdate;

****change the value for which indicator into the (n+1) value;
if changethisround=1 then 
		whichslot=whichslot+1;

***change over the filledyet variable, this obs will not be eligible for change;
***on the loop through the whichindicator values;
if changethisround=1 then 
		filledyet=1;

**then reset changethisround back to zero;
***so that it wont get activated in later loops;
changethisround=0;

%let whichindicator=%eval(&whichindicator + 1);
	%end;	/* close loop for whichindicator */		

***close out this array;
end;

***add variable for whether enrolid has _any_ values in this category;
***will check that the first var has a non-missing value;
***some particular day for event does exist;
hasany_&whichaspectfile=(&whichformalname._gap1~=.);
***run this data step to get this file;
run;

title "Checking Number of Dates for &whichaspectfile";
proc means data=crosdir.hvpengui&newfilename;
var &whichaspectfile._dt1 - &whichaspectfile._dt&whichmax
	&whichformalname._gap1 - &whichformalname._gap&whichmax.;
run;

***info from http://support.sas.com/documentation/cdl/en/sqlproc/63043/HTML/default/viewer.htm#p0xlnvl46zgqffn17piej7tewe7p.htm;


***when still wanting to check for all occurrences;
%if  &checkforany=0 %then %do ;

		****drop off the gap variables that are all missing values;
		****dont need to keep them;
		proc sql noprint;
		select max(whichslot)
		into :themaxdtnext
		from crosdir.hvpengui&newfilename;
		quit;

		****have found the highest value;
		%put Max whichslot value is &themaxdtnext;




		*****drop those obs where all obs are missing;
		data crosdir.hvpengui&newfilename (drop=&whichaspectfile._dt1 - 	&whichaspectfile._dt&whichmax 
			&whichformalname._gap%cmpres(&themaxdtnext) - &whichformalname._gap&whichmax.
			whichslot);
		set crosdir.hvpengui&newfilename ;
		run;
%end;


***when wanting to check for any occurrences;
%if  &checkforany=1 %then %do ;
		*****drop those obs where starting from 2nd var;
		***will only need the first var to check the status;
		data crosdir.hvpengui&newfilename (drop=&whichaspectfile._dt1 - 	&whichaspectfile._dt&whichmax 
			&whichformalname._gap2 - &whichformalname._gap&whichmax.
			whichslot);
		set crosdir.hvpengui&newfilename ;
		run;
%end;




***from https://amadeus.co.uk/sas-tips/deleting-macro-variables/;
***drop the whichmax global macro;
%symdel whichmax;


%mend addthataspect;



***remove obs that did have exclusion criteria;
%macro didhaveyes(whichexistingfile, whichformalname);

%let newfilename=%eval(&whichexistingfile+1);
%put the old files number is &whichexistingfile;
%put the new files number will be &newfilename;


data crosdir.hvpengui&newfilename;
set crosdir.hvpengui&whichexistingfile;
if &whichformalname._gap1~=. then delete;
run;

%mend didhaveyes;

***;
***;
***;
***end of macro definitions;
***;
***;
***;
***;
***;


***run the merge between the list of enrolids;
***and their first procedure of interest occurrences;
***with the enrollment information;
***dropping the obs without continuous enrollment;
***12 months prior to procedure of interest;
***6 months following procedure of interest;





***After adding the procedure, first event, age, and sex restrictions, there are 49,259 enrolids in the dataset.
***this number should not fluctuate over the course of the merges;


***check the deaths;
***would need to happen within 1 month window;
%addthataspect(whichexistingfile=2, 
	whichaspectfile=death, 
	whichformalname=died30,
	checkforany=1,
	whichrefdate=svcdate, 
	startwindow=0, endwindow=30);

data crosdir.hvpengui3 (rename=(hasany_death=hasany_death30));
set crosdir.hvpengui3 (drop=died30_gap1);
run;
	
***check the deaths;
***would need to happen within 6 month window;
%addthataspect(whichexistingfile=3, 
	whichaspectfile=death, 
	whichformalname=died183,
	checkforany=1,
	whichrefdate=svcdate, 
	startwindow=0, endwindow=183);

***have 3 obs where people died during the 30-day post-procedure of interest proc window;
***remove obs that do not have info for 30 days post-procedure and (who have exemption) were not people who died;
data crosdir.hvpengui5 (rename=(hasany_death=hasany_death183));
set crosdir.hvpengui4 (drop=died183_gap1);
if enroll_1mo_af_index_ind=. & hasany_death30=0 then delete;
run;
***after deletions, have 23688 obs.;

/* code omitted */

***drop observations where had any non-missing values for prior breast cancer;
***only need to check the first breast cancer var to see if there were non-missing values;
%didhaveyes(whichexistingfile=8, 
	whichformalname=aspectgoeshere);

/* code omitted */	