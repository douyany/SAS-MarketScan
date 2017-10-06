/* filename: 
u:\folderlocation
20170821_prep_drug_file_sas.sas

Date created:
September 28, 2017

Process the listing of chemo drugs and check them against the drug files
*/

***read in the other libnames:;
libname crosdir "E:\folderlocation";
libname project "E:\folderlocation";


***load other needed formats;
%include 'e:\theotherneededfiles.sas';

***proc import on the Excel file with drug names;
PROC IMPORT OUT= crosdir.drug_ofinterest DATAFILE= "U:\drugfile.xlsx" 
            DBMS=xlsx REPLACE;
     SHEET="Sheet1"; 
     GETNAMES=YES;
RUN;

***create format that matches the way the numbers appear in the MarketScan data;
***the numbers in MarketScan are eleven digit numbers;
data crosdir.drug_10digits;
set crosdir.drug_ofinterest;
***create substring that only uses the number portion;
length drugleft9 $9;
***locate place of first dash;
****format is xxxx-xxxx (length including dash is 9);
****will modify to 0xxxx-xxxx;
if lengthbefseconddash=9 and wherefirstdash=5 then drugleft9=cats('0',substr(ndclong, 1, 4),substr(ndclong, 6, 4));
****format is xxxxx-xxx (length including dash is 9);
****will modify to xxxxx-0xxx;
if lengthbefseconddash=9 and wherefirstdash=6 then drugleft9=cats(substr(ndclong, 1, 5),'0',substr(ndclong, 7, 3));
****format is xxxxx-xxxx (length including dash is 10);
****will not modify with any zeroes;
if lengthbefseconddash=10 and wherefirstdash=6 then drugleft9=cats(substr(ndclong, 1, 5),substr(ndclong, 7, 4));
if drugleft9=" " then drugleft9="";
if drugleft9="" then delete;
***chemo drug is Tamoxifen or Raloxifene;
hastamralox=0;
if index(drugname, "Tamoxifen")>0 then hastamralox=1;
if index(drugname, "Raloxifene")>0 then hastamralox=1;
label drugleft9="Entry in ndclong column adjusted to MktScan standards";
label lengthbefseconddash="Length of Entry in PRODUCTNDC column (including the hyphen)";
run;

proc freq data=crosdir.drug_10digits;
tables drugname*hastamralox / missing;
run;


proc freq data=crosdir.drug_10digits;
tables drugleft9 / out=crosdir.drug_ndcnottamralox;
where hastamralox=0;
run;

proc freq data=crosdir.drug_10digits;
tables drugleft9 / out=crosdir.drug_ndcyestamralox;
where hastamralox=1;
run;


***sort for merging  (not Tamoxifen and Raloxifene);
proc sort data=crosdir.drug_ndcnottamralox out=crosdir.drug_ndcnottamraloxsorted;
by drugleft9;
run;

***sort for merging;
proc sort data=crosdir.drug_ndcyestamralox out=crosdir.drug_ndcyestamraloxsorted;
by drugleft9;
run;

***run a filter on the drug table to get the drugs of interest;
data crosdir.cohort_dwith8;
set crosdir.cohort_d;
length drugleft9 $9;
drugleft9=substr(ndcnum,1,9);
run;

**sort by length 9;
proc sort data=crosdir.cohort_dwith8 out=crosdir.cohort_dwith8_sorted;
by drugleft9;
run;

***merge together the files (not Tamoxifen and Raloxifene);
DATA crosdir.cohort_dhaving9not (keep=enrolid svcdate );
merge crosdir.cohort_dwith8_sorted  (in=incohortd) crosdir.drug_ndcnottamraloxsorted (in=indruglist);
by drugleft9;
	if incohortd~=1 or indruglist~=1 then delete;
run;


***merge together the files (yes Tamoxifen and Raloxifene);
DATA crosdir.cohort_dhaving9yes (keep=enrolid svcdate );
merge crosdir.cohort_dwith8_sorted  (in=incohortd) crosdir.drug_ndcyestamraloxsorted (in=indruglist);
by drugleft9;
	if incohortd~=1 or indruglist~=1 then delete;
run;


***sort file in preparation for proc transpose (not Tamoxifen and Raloxifene);
proc sort data=crosdir.cohort_dhaving9not out=crosdir.cohort_dhaving9not_sorted;
by enrolid;
run;

***sort file in preparation for proc transpose (yes Tamoxifen and Raloxifene);
proc sort data=crosdir.cohort_dhaving9yes out=crosdir.cohort_dhaving9yes_sorted;
by enrolid;
run;


***number within the group: (not Tamoxifen and Raloxifene);
***added count variable using info from http://www.ats.ucla.edu/stat/sas/faq/enumerate.htm;
data crosdir.cohort_dwithgrpnot;
set crosdir.cohort_dhaving9not_sorted;
countrec+1;
by enrolid;
if first.enrolid then countrec=1;
run;


***number within the group: (yes Tamoxifen and Raloxifene);
***added count variable using info from http://www.ats.ucla.edu/stat/sas/faq/enumerate.htm;
data crosdir.cohort_dwithgrpyes;
set crosdir.cohort_dhaving9yes_sorted;
countrec+1;
by enrolid;
if first.enrolid then countrec=1;
run;

** (not Tamoxifen and Raloxifene);
proc transpose data=crosdir.cohort_dwithgrpnot 
out=crosdir.hvdrugnot_wide (drop=_name_ _label_)
prefix=drugnot_dt;
by enrolid;
id countrec;
var svcdate;
run;


*** (yes Tamoxifen and Raloxifene);
proc transpose data=crosdir.cohort_dwithgrpyes 
out=crosdir.hvdrugyes_wide (drop=_name_ _label_)
prefix=drugyes_dt;
by enrolid;
id countrec;
var svcdate;
run;
