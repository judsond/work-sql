USE [Test]
GO

/****** Object:  StoredProcedure [dbo].[stprc_cyto_qc_conf_mdacc]    Script Date: 2/26/2018 10:19:28 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO



CREATE PROCEDURE [dbo].[stprc_cyto_qc_conf_mdacc]

 

 AS

/*	Template version: 	1.0
	Primary Author: 		Judson Dunn
	Requestor: 		Marilyn Dawlett
	Date Created:	8/16/2010
	Purpose: 		Create a report to show cyto and bx cases for monthly QC
	Dependent Reports:	Hematopathology Correlation
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
  pat.last_name patient_last_name,
  pmrn.med_rec_no,
  cyto.created_date cyto_created,
  cyto.accession_no cyto_acc,
  cyto_spec.description + ' ' + cast(coalesce(ar1.finding, ar1.finding_text) AS varchar(8000)) cyto_dx,
  cyto_employee.full_name cyto_employee,
  bx.created_date bx_created,
  bx.accession_no bx_acc,
  coalesce(ar2.finding, ar2.finding_text) bx_dx,
  bx_employee.full_name bx_employee

from accession_2 cyto
join accession_2 bx on bx.patient_id = cyto.patient_id
join patient_mrn_2 pmrn on cyto.patient_mrn_id = pmrn.id and bx.patient_mrn_id = pmrn.id
join acc_results ar1 on ar1.acc_id = cyto.id 
join acc_results ar2 on ar2.acc_id = bx.id
join path_rpt_heading prh1 on ar1.heading_id = prh1.id and prh1.type = 'D'
join path_rpt_heading prh2 on ar2.heading_id = prh2.id and prh2.type = 'D'
join patient_name_2 pat on pat.patient_id = cyto.patient_id
	and pat.row_version = (select max(row_version) from patient_name_2 pmax where pmax.patient_id = pat.patient_id)

join acc_process_step bx_aps on bx.current_status_id = bx_aps.id
join personnel_2 bx_employee on bx_aps.assigned_to_id = bx_employee.id
join personnel_other_data pod on bx_aps.assigned_to_id = pod.personnel_id
join data_tmplt_field dtf on pod.tmplt_id = dtf.tmplt_id and pod.field_id = dtf.field_id and dtf.name = 'Department'
join acc_process_step cyto_aps on cyto.current_status_id = cyto_aps.id
join personnel_2 cyto_employee on cyto_aps.assigned_to_id = cyto_employee.id
join acc_specimen cyto_spec on cyto.primary_specimen_id = cyto_spec.id

where cyto.acc_type_id in (111,115) --US FNA, Deep FNA
and bx.acc_type_id = 1 -- Surgical Biopsy
and (
	(contains(ar1.*,'lymphoma OR leukemia OR lymphoproliferative OR flow OR hodgkin OR "atypical lymphoid" OR "plasma cell" OR "myeloma"'))
	OR
	(contains(ar2.*,'lymphoma OR leukemia OR lymphoproliferative OR flow OR hodgkin OR "atypical lymphoid" OR "plasma cell" OR "myeloma"'))
	)
and abs(datediff(d,cyto.created_date,bx.created_date)) <= 3
and pod.val = 'Hemepath'
and cyto.status_final = 'Y'
and bx.status_final = 'Y'


order by cyto.created_date

END

GO


