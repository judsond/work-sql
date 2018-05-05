USE [Test]
GO

/****** Object:  StoredProcedure [dbo].[stprc_breast_ihc_compare_mdacc]    Script Date: 2/26/2018 10:18:07 AM ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO



CREATE PROCEDURE [dbo].[stprc_breast_ihc_compare_mdacc]
	@start_date datetime,
	@end_date datetime,
	@comparison varchar(255)
AS

/*  Template version: 	1.0
	Primary Author: 	Judson Dunn
	Requestor: 			Dr. Middleton
	Date Created:		7/25/2012
	Purpose: 			Report to compare ER/PR results with diagnosis and grade.
	Dependent Reports:	
	Depends On: 		dbo.fnc_fix_dates_mdacc
	Date Last Modified: 
	
  */



SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET ANSI_NULLS OFF
SET CONCAT_NULL_YIELDS_NULL OFF
SET QUOTED_IDENTIFIER OFF

begin


	
-- fixing dates
set @start_date = dbo.fnc_fix_dates_mdacc('START DATE', @start_date)
set	@end_date = dbo.fnc_fix_dates_mdacc('END DATE', @end_date)

select 	we2.caption stain,
		we.caption results,
		weg2.caption grade_title,
		weg.caption grade,
		a2.accession_no,
		a2.patient_age
		
from acc_worksheet_result awr
join worksheet_element we on awr.worksheet_element_id = we.worksheet_element_id
join worksheet_element we2 on we.worksheet_element_parent_id = we2.worksheet_element_id

join acc_worksheet worksheet on awr.acc_worksheet_id = worksheet.acc_worksheet_id
join accession_2 a2 on worksheet.acc_id = a2.id

join acc_worksheet_result awr2 on awr2.acc_worksheet_id = awr.acc_worksheet_id
join worksheet_element weg on awr2.worksheet_element_id = weg.worksheet_element_id
join worksheet_element weg2 on weg.worksheet_element_parent_id = weg2.worksheet_element_id

where we2.caption in ('Estrogen Receptor Results','Progesterone Receptor Results')
and weg2.caption = @comparison
and a2.status_final = 'Y'
and a2.created_date between @start_date and @end_date

end





GO


