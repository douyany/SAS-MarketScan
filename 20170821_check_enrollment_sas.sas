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


***macro that Jeff has updated to include 2015 data;
%include 'e:\macroforenrollment.sas';

***create cohort2 that will have the list of enrolid's of interest;
***want to let the program add the enrollment info on those records,;
***rather than onto the hvproc file;



data crosdir.cohort2;
set crosdir.hvpengui_firstrow;
***add var for cohort entry date;
cohort_entry_dt=svcdate;
run;
***have xxx observations when requiring proc and diagnosis on same row;
***have xxx observations when requiring proc and diagnosis plus minus one day;


***run the macro for data;
%MS_ENROLLMENT(project.cohort2);



***finding patients who died;
***can check inpatient services table;
***see if dstatus is in 20 (died);
***or 40-42 (expired on a hospice claim);
proc sql;
create table crosdir.hvdeath as 
select enrolid, svcdate, count(enrolid) as deathclaim
from crosdir.cohort_s
where dstatus in ('20', '40', '41', '42')
group by enrolid, svcdate;
quit;



****add row numbering;
***added count variable using info from http://www.ats.ucla.edu/stat/sas/faq/enumerate.htm;
data crosdir.hvdeath_rows (drop=deathclaim);
set crosdir.hvdeath;
countrec+1;
by enrolid;
if first.enrolid then countrec=1;
run;


***make the information about that aspect of interest;
***wide rather than long;
***reshape to wide format;
***for arrival;
proc transpose data=crosdir.hvdeath_rows 
out=crosdir.hvdeath_wide (drop=_name_ _label_)
prefix=death_dt;
by enrolid;
id countrec;
var svcdate;
run;








***checking enrollment info;
data crosdir.hvpengui2 (keep=enrolid age svcdate enroll_12mo_bf_index_ind enroll_1mo_af_index_ind enroll_6mo_af_index_ind);
set project.cohort2;
****create variable for obs not having complete coverage during period of interest;
if enroll_12mo_bf_index_ind=. then delete;
****keep only those obs with incomplete coverage info or not having 3mo-post info;
***those obs will get flagged;
label enroll_12mo_bf_index_ind="Yes Has Enr through 12 mo before procedure of interest";
label enroll_6mo_af_index_ind="Yes Has Enr through 6 mo after procedure of interest";
run;


***only need one obs per enrolid date combination;
proc sql;
select enrolid, svcdate, count(enrolid) as count
from crosdir.hvpengui2
group by enrolid, svcdate
having count(enrolid)>1;
quit;
***no, no enrolid-date record combinations do appear more than once;
***no need to delete off these duplicates;
