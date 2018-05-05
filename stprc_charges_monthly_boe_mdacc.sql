USE [Test]
GO

/****** Object:  StoredProcedure [dbo].[stprc_charges_monthly_boe_mdacc]    Script Date: 2/26/2018 10:18:39 AM ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO



CREATE PROCEDURE [dbo].[stprc_charges_monthly_boe_mdacc]

/*  Template version: 	1.0
	Primary Author: 		Judson Dunn
	Requestor: 		Vivian Truong & Hollie Lampton
	Date Created:		8/12/2015
	Purpose: 		A monthly report from BOE to Vivian and Hollie with all the charges that transferred in the last month for billing reconciliation.
				
	Dependent Reports:	Montly Charges (BOE)
	Depends On: 		dbo.fnc_GetDOS_mdacc
	Date Last Modified: 	
	Change - History: 	
  */

AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET ANSI_NULLS OFF
SET CONCAT_NULL_YIELDS_NULL OFF
SET QUOTED_IDENTIFIER OFF

BEGIN

declare @startOfCurrentMonth datetime
declare @startOfLast datetime

set @startOfCurrentMonth = DATEADD(month, DATEDIFF(month, 0, CURRENT_TIMESTAMP), 0)
set @startOfLast = DATEADD(month, -1, @startOfCurrentMonth)

select
  a.accession_no,
  ctype.name case_type,
  refmd.code refmd_code,
  refmd.full_name ref_md_name,
  p.full_name billing_pathologist,
  assigned.full_name assigned_to,
  ac.description,
  ac.billing_code,
  ac.comp_type,
  dbo.fnc_GetDOS_mdacc(ac.id) DOS,
  ac.xfer_billing_date transfer_date

from acc_charges ac
join accession_2 a on ac.acc_id = a.id
join acc_type ctype on a.acc_type_id = ctype.id
join refmd_2 refmd on a.refmd_id = refmd.id
left outer join personnel_2 p on ac.billing_pathologist_id = p.id
join acc_process_step aps on a.current_status_id = aps.id
join personnel_2 assigned on aps.assigned_to_id = assigned.id


where ac.xfer_billing_date is not null
and ac.xfer_billing_date between @startOfLast and @startOfCurrentMonth

END


GO


