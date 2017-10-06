# SAS-MarketScan
templates for running analysis of MarketScan claims files

project readme:

Check for which records have this procedure, without the other exclusion 

criteria:

Run:
20170821_timeline_query_sas.sas
to get the enrolid's with records having the procedure


20170821_code_from_malk_sas
to get the full set of records for the enrolid's with procedure of interests

Run:
20170821b_check_filtered_tbls.sas
create one data table for each aspect of interest
*for some aspects, only want first obs.
*for some aspects, only want all obs. (and will create a wide array)


20170821_check_enrollment_sas.sas
***continuous coverage requirement for patients


20170821_merge_files_sas.sas<--merge the set of enrolid's procedures with the 

other characteristics

20170821_print_fill_obs.sas
now that the fill information is added to the file,
calculate the information for the shell tables
