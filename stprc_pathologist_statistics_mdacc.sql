USE [Test]
GO

/****** Object:  StoredProcedure [dbo].[stprc_pathologist_statistics_mdacc]    Script Date: 2/26/2018 10:21:31 AM ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO






CREATE PROCEDURE [dbo].[stprc_pathologist_statistics_mdacc]

 	
 		@start datetime,
 		@end datetime

 AS

/*	Template version: 	1.0
	Primary Author: 		Judson Dunn
	Requestor: 		Dr. Routbort
	Date Created:		8/12/2011
	Purpose: 		Report different statistics by pathologist.
	Dependent Reports:	Pathology Cases to MDL
	Depends On: 		dbo.fnc_fix_dates_mdacc
	Date Last Modified: 	
	Change - History: 	
	
  */

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET ANSI_NULLS OFF
SET CONCAT_NULL_YIELDS_NULL OFF
SET QUOTED_IDENTIFIER OFF

BEGIN

		set @start = dbo.fnc_fix_dates_mdacc('START DATE', @start)
		set @end = dbo.fnc_fix_dates_mdacc('END DATE', @end)
		
/***************************************/
/***get pathologists names, materials***/
/***************************************/

select distinct
  path.full_name,
  path.id path_id,
  count(distinct sslide.id) as stained_slides,
  count(distinct block.id) as blocks

into #pathologists

from accession_2 a
join acc_role_assignment ara on ara.acc_id = a.id and ara.role_id = 2 --assigned pathologist
join personnel_2 path on ara.assigned_to_id = path.id
left outer join acc_slide sslide on sslide.acc_id = a.id and sslide.slide_type in ('S','A') --stained and antibody slides
left outer join acc_block block on block.acc_id = a.id

where a.created_date between @start and @end
and path.persnl_class_id = 'PT'

group by path.full_name, path.id

order by path.full_name



/******************************/
/***subspecialty case counts***/
/******************************/

select
  path.id path_id,
  isnull(aod.val,type.name) subspecialty,
  count(distinct a.id) case_count
  
into #subcounts

from accession_2 a
join acc_role_assignment ara on ara.acc_id = a.id and ara.role_id = 2 --assigned pathologist
join personnel_2 path on ara.assigned_to_id = path.id
left outer join acc_other_data aod ON aod.acc_id = a.id
and (convert(varchar, tmplt_id) + ':' + convert(varchar, field_id)) in 
(select convert(varchar, tmplt_id) + ':' + convert(varchar, field_id) from data_tmplt_field where name like '%SUBSPECIALTY%')
join acc_type type on type.id = a.acc_type_id

where a.created_date between @start and @end
and path.persnl_class_id = 'PT'

group by path.full_name, path.id, isnull(aod.val,type.name)

declare @subspecialty varchar(50), @pathID int, @ccount int
declare sub_adder cursor for
select distinct s1.subspecialty from #subcounts s1 order by subspecialty
open sub_adder
fetch next from sub_adder into @subspecialty

while @@fetch_status = 0
begin
  set @subspecialty = replace(replace(replace(@subspecialty,' ',''),'&',''),'-','')
  exec('alter table #pathologists add '+@subspecialty+' int default 0 not null')
  declare case_adder cursor for
  select path_id, case_count from #subcounts s2 where replace(replace(replace(s2.subspecialty,' ',''),'&',''),'-','') = @subspecialty
  open case_adder
  fetch next from case_adder into @pathID, @ccount
  while @@fetch_status = 0
  begin
    exec('update #pathologists set '+@subspecialty+' ='+@ccount+' where path_id = '+@pathID+'')
    fetch next from case_adder into @pathID, @ccount
  end
  close case_adder
  deallocate case_adder
  fetch next from sub_adder into @subspecialty
end
 


close sub_adder
deallocate sub_adder
drop table #subcounts

/*****************/
/***get charges***/
/*****************/

select
  isnull(chargepath.id, casepath.id) path_id,
  rtrim(left(sc.name,6)) cpt,
  count(ac.id) charges
  
into #charges
 
from acc_charges ac
join service_code sc on ac.service_code_id = sc.id
join accession_2 a on ac.acc_id = a.id
join acc_process_step aps on a.current_status_id = aps.id
left outer join personnel_2 chargepath on ac.billing_pathologist_id = chargepath.id
join personnel_2 casepath on aps.assigned_to_id = casepath.id

where a.created_date between @start and @end
and ac.comp_type = 'P' --professional only
and ac.ar_type = 'C' --charges, not adjustments

group by isnull(chargepath.id, casepath.id), rtrim(left(sc.name,6))


declare @cpt varchar(20), @pathID2 int, @chargecount int
declare cpt_adder cursor for
select distinct c1.cpt from #charges c1
open cpt_adder
fetch next from cpt_adder into @cpt

while @@fetch_status = 0
begin
  set @cpt = replace(replace(replace(@cpt,' ',''),'&',''),'-','')
  exec('alter table #pathologists add CPT'+@cpt+' int default 0 not null')
  declare charge_adder cursor for
  select path_id, charges from #charges c2 where replace(replace(replace(c2.cpt,' ',''),'&',''),'-','') = @cpt
  open charge_adder
  fetch next from charge_adder into @pathID2, @chargecount
  while @@fetch_status = 0
  begin
    exec('update #pathologists set CPT'+@cpt+' ='+@chargecount+' where path_id = '+@pathID2+'')
    fetch next from charge_adder into @pathID2, @chargecount
  end
  close charge_adder
  deallocate charge_adder
  fetch next from cpt_adder into @cpt
end

close cpt_adder
deallocate cpt_adder
drop table #charges

/********************/
/***select results***/
/********************/

alter table #pathologists drop column path_id
select * from #pathologists
drop table #pathologists

END





GO


