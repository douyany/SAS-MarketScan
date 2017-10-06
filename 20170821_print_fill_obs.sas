/* filename: 
u:\folderlocation
20170821_print_fill_obs.sas

Date created:
September 19, 2017

Putting together the information that goes into the shell tables

*/

options symbolgen;
options mlogic ;

***read in the other libnames:;
libname crosdire "E:\folderlocationone";
libname crosdirx "X:\folderlocation";
libname project "E:\folderlocation";

proc format;
value yesnolbl 0="No"
	1="Yes";
run;	

/* Table 1: Patient Characteristics */
title "Table 1: Patient Characteristics";
proc means data=crosdirx.hvpengui56 mean stddev min max;
run;

/* Table 2: Utilization of preoperative imaging before procedure of interest */
title "Table 2: without age restrictions";
***without age restriction (all as one group);
proc means data=crosdirx.hvpengui56 mean stddev min max;
run;

title "Table 2: with age restrictions";
***with age restrictions;
proc means data=crosdirx.hvpengui56 mean stddev min max;
run;
