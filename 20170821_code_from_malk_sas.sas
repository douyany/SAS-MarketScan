/* filename: 
u:\folderlocation
20170821_code_from_malk_sas.sas

Date created:
August 31, 2017

This do-file pulls out records from the tables, for the enrolid that had the procedure of interest


*/


libname timeline "E:\datalocation\";

***where files will get stored on x eventually;

%INCLUDE "X:\fileonx.sas";
libname crosdir "E:\folderlocation";
libname project "E:\folderlocation";



***create cohort tables;
%MS_COHORT_TABLES(crosdir.px_procofint_timeline)
 
***pull in age information from f table;

proc sql;
    create table coh_f as             
    select inpt.*,
            f.age
    from crosdir.cohort_f f inner 
join
crosdir.px_procofint_timeline inpt
on 
inpt.enrolid=f.enrolid
and   
inpt.date=f.svcdate
order
by enrolid,
date,
event;
quit;        

proc sql;
    create table coh_i as             
    select inpt.*,
            i.age
    from crosdir.cohort_i i inner 
join
crosdir.px_procofint_timeline inpt
on 
inpt.enrolid=i.enrolid
and   
i.admdate <= inpt.date <= i.disdate

order
by enrolid,
date,
event;
quit;   
 
proc sql;
    create table coh_o as             
    select inpt.*,
            o.age
    from crosdir.cohort_o o inner 
join
crosdir.px_procofint_timeline inpt
on 
inpt.enrolid=o.enrolid
and   
inpt.date=o.svcdate

order
by enrolid,
date,
event;
quit;           

proc sql;
    create table coh_s as             
    select inpt.*,
            s.age
    from crosdir.cohort_s s inner 
join
crosdir.px_procofint_timeline inpt
on 
inpt.enrolid=s.enrolid
and   
inpt.date=s.svcdate

order
by enrolid,
date,
event;
quit;        


data coh_fios;
set
coh_f
coh_i
coh_o
coh_s;
by
enrolid
date
event;
run;


***before running %MS_COHORT_TIMELINE, need to make sure that the cohort file exists;
***it needs to have that cohort name to be able to function in the macro;

***copy the crosdir.px_procofint_timeline file into a file with cohort name;
data crosdir.cohort;
set crosdir.px_procofint_timeline;
run;

%MS_COHORT_TIMELINE


