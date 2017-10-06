/* filename: 
u:\folderlocation
20170821_timeline_query_sas.sas

Date created:
August 31, 2017

This do-file pulls out records having the procedure of interest: procedure of interest

*/


libname timeline "E:\timelinelocation";



libname crosdir "E:\folderlocation";
libname project "E:\folderlocation";

proc sql;
	create	table	crosdir.px_procofint_timeline as
	select	DISTINCT *
	from	timeline.Px_timeline
	where	event in ('19318','8531','8532');
quit;
