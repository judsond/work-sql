USE [Test]
GO

/****** Object:  StoredProcedure [dbo].[stpc_assigned_case_list_code_problems_mdacc]    Script Date: 2/26/2018 10:12:24 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO




CREATE  PROCEDURE [dbo].[stpc_assigned_case_list_code_problems_mdacc] 
 AS
 /*	Template version: 	2
	Primary Author: 		Judson Dunn
	Requestor: 		LIS
	Date Created:		6/5/2014
	Purpose: 		Create a queue for cases that don't have the right ICD version post epic go-live
	Dependent Reports:	Epic Problem queue
	Depends On: 		
	Date Last Modified: 	
	Change - History: 		

    */

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
BEGIN  

DECLARE @ICD10date datetime
DECLARE @Epicdate datetime

EXEC  stp_get_appreg_node_value '\System Options\ICD Options\ICD Version effective date', @ICD10date out 
EXEC  stp_get_appreg_node_value '\MDACC\Epic\Epic GL Date', @Epicdate out 	

--select @icd10date

	SELECT 
	  a.id, 
	  a.accession_no,
	  a.created_date,
	  a.acc_catg category, 
	  d.name case_type,
	  dbo.fnc_getdos_mdacc(ac.id) DOS,
	  @ICD10date

	FROM 
	  acc_charges ac
	  left join acc_icd9 aicd on aicd.acc_id = ac.acc_id
	  join accession_2 a on ac.acc_id = a.id
	  join acc_type d on a.acc_type_id = d.id


	WHERE a.status_final = 'Y'
	and a.ok_to_bill = 'Y'
	and ac.xfer_billing_to <> 'D'
	and ac.xfer_billing_date is null
	and dbo.fnc_getdos_mdacc(ac.id) < @Epicdate and aicd.acc_id is null
	and ac.comp_type = 'P'
	    
	ORDER BY a.accession_no

END


GO


