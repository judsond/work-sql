USE [Test]
GO

/****** Object:  StoredProcedure [dbo].[stprc_cyto_dibreast_mdacc]    Script Date: 2/26/2018 10:19:02 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[stprc_cyto_dibreast_mdacc]

 AS

/*	Template version: 	1.0
	Primary Author: 	Judson Dunn
	Requestor: 			Marilyn Dawlett
	Date Created:		2015-01-30
	Purpose: 			Daily report to the DI Breast group about US Guided FNA cases finaled in the last 24 hours
	Dependent Reports:	
	Depends On: 		
	Date Last Modified: 
	Change - History: 	
	
  */



SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET ANSI_NULLS OFF
SET CONCAT_NULL_YIELDS_NULL OFF
SET QUOTED_IDENTIFIER OFF

BEGIN


select
  a.accession_no,
  mrn.med_rec_no,
  pat.full_name patient_name,
  spec.description spec_desc,
  spec.collection_date,
  aod2.val performed_by,
  aps.completed_date final

from accession_2 a
join patient_mrn_2 mrn on a.patient_mrn_id = mrn.id
join acc_specimen spec on a.primary_specimen_id = spec.id
join patient_name_2 pat on pat.patient_id = a.patient_id
  and pat.row_version = (select max(row_version) from patient_name_2 pmax where pmax.patient_id = pat.patient_id)
join acc_type ct on a.acc_type_id = ct.id
join acc_other_data aod on aod.acc_id = a.id
join data_tmplt_field dtf on 
	aod.tmplt_id = dtf.tmplt_id and 
	aod.field_id = dtf.field_id and
	dtf.name = 'Modality'
join acc_other_data aod2 on aod2.acc_id = a.id
join data_tmplt_field dtf2 on 
	aod2.tmplt_id = dtf2.tmplt_id and 
	aod2.field_id = dtf2.field_id and
	dtf2.name = 'Performed by:'
join acc_process_step aps on a.id = aps.acc_id and aps.step_id in (select id from process_step where type = 'F')

where ct.name = 'US FNA'
and aod.val = 'US Guided'
and aps.completed_date between dateadd(d,-1,getdate()) and getdate()

order by a.created_date

END




GO


