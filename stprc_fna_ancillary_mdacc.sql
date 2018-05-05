USE [Test]
GO

/****** Object:  StoredProcedure [dbo].[stprc_fna_ancillary_mdacc]    Script Date: 2/26/2018 10:20:48 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE PROCEDURE [dbo].[stprc_fna_ancillary_mdacc]

@start_date datetime,
@end_date datetime,
@performer varchar(50),
@casetype varchar(50)

AS

/*  Template version: 	1.0
	Primary Author: 	Judson Dunn
	Requestor: 			Marilyn Dawlett
	Date Created:		8/14/2013
	Purpose: 			Return data about FNA ancillary assessments
	Dependent Reports:	FNA Ancillary Assessment, FNA Ancillary Assessment Export
	Depends On: 		dbo.fnc_fix_dates_mdacc
	Date Last Modified: 
	Change - History: 	
*/
	
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET ANSI_NULLS OFF
SET CONCAT_NULL_YIELDS_NULL OFF
SET QUOTED_IDENTIFIER OFF

BEGIN
	
	set @start_date = dbo.fnc_fix_dates_mdacc('START DATE', @start_date)
	set @end_date = dbo.fnc_fix_dates_mdacc('END DATE', @end_date)
		
select
  a.accession_no,
  ct.name case_type,
  spec.collection_date,
  aod.val radiologist,
  aod2.val assessment,
  aod3.val rad_accession
  
from accession_2 a
join acc_specimen spec on a.primary_specimen_id = spec.id
join acc_type ct on ct.id = a.acc_type_id

join acc_other_data aod on aod.acc_id = a.id
join data_tmplt_field dtf on 
	aod.tmplt_id = dtf.tmplt_id and 
	aod.field_id = dtf.field_id and
	dtf.name = 'Performed by:'

left outer join acc_other_data aod2 ON aod2.acc_id = a.id
	and (convert(varchar, aod2.tmplt_id) + ':' + convert(varchar, aod2.field_id)) in
		(select convert(varchar, dtf2.tmplt_id) + ':' + convert(varchar, dtf2.field_id) from data_tmplt_field dtf2 where name = 'FNA Ancillary Assessment')
		
left outer join acc_other_data aod3 ON aod3.acc_id = a.id
	and (convert(varchar, aod3.tmplt_id) + ':' + convert(varchar, aod3.field_id)) in
		(select convert(varchar, dtf3.tmplt_id) + ':' + convert(varchar, dtf3.field_id) from data_tmplt_field dtf3 where name = 'Radiology Accession Number')

where spec.collection_date between @start_date and @end_date
and aod.val like @performer + '%'
and ct.name like @casetype + '%'

order by a.accession_no

END


GO


