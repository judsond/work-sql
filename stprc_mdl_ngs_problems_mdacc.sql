USE [Test]
GO

/****** Object:  StoredProcedure [dbo].[stprc_mdl_ngs_problems_mdacc]    Script Date: 2/26/2018 10:28:17 AM ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO





CREATE PROCEDURE [dbo].[stprc_mdl_ngs_problems_mdacc]

AS

/*  Version: 	1
	Primary Author: 	Judson Dunn
	Requestor: 			Cindy Lewing
	Date Created:		2015-01-05
	Purpose: 			Report to display wrong number NGS order cases
	Dependent Reports:	Custom reports / MDL / NGS Gene Number Problems
	Depends On: 		
	Date Last Modified: 
	
  */



SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET ANSI_NULLS OFF
SET CONCAT_NULL_YIELDS_NULL OFF
SET QUOTED_IDENTIFIER OFF

begin
	
select
  a.id acc_id,
  a.accession_no,
  lp.code panel,
  lp.description,
  0 genes

into #ngs

from accession_2 a
join acc_order ao on ao.acc_id = a.id
join lab_procedure lp on ao.procedure_id = lp.id

where lp.code in ('MDCMS53MSPLUS','MDCMS50ITPLUS','MDCMS28MSPLUS','MDCMS11','MDCMS28MS','MDCMS50IT','MDCMS53MS') 
-- this should be a list of all the NGS primary orders
and a.created_date between '1/1/2015' and getdate()
--and a.accession_no = 'M-15-000001'

declare @acc_id int, @genes int
declare gene_insert cursor for
  select acc_id from #ngs
open gene_insert

	fetch next from gene_insert into @acc_id

	while @@fetch_status = 0
	begin
	  select @genes = count(o.id)
	  from acc_order o
	  join lab_procedure l on o.procedure_id = l.id
	  where o.acc_id = @acc_id
	  and l.code like 'xmdc%t' -- just counting the technical orders as proxy for genes
	  group by acc_id

	  update #ngs
	  set genes = isnull(@genes,0) where acc_id = @acc_id
      set @genes = 0
	  fetch next from gene_insert into @acc_id
	end
close gene_insert
deallocate gene_insert


select * from #ngs
where (panel in ('MDCMS53MSPLUS','MDCMS50ITPLUS','MDCMS28MSPLUS') and genes > 0) -- new panels or research
       OR (panel in ('MDCMS11','MDCMS28MS','MDCMS50IT','MDCMS53MS') and genes > 4)
order by accession_no
drop table #ngs

end





GO


