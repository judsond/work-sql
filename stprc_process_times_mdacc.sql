USE [Test]
GO

/****** Object:  StoredProcedure [dbo].[stprc_process_times_mdacc]    Script Date: 2/26/2018 10:22:06 AM ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[stprc_process_times_mdacc]

 	
 		@start_date datetime, @end_date datetime, @order_code varchar(20), @acc_cat varchar(1)

 AS

/*	Template version: 	1.0
	Primary Author: 		Judson Dunn
	Requestor: 		Marilyn Dawlett, Charisse Acosta, Louise Huck
	Date Created:		8/28/2007
	Purpose: 		Create a custom report to list the cases with the duration from order/accession until order is complete.
	Dependent Reports:	Process Time Analysis
	Depends On: 		dbo.fnc_fix_dates_mdacc, dbo.fnc_CalcWeekDaysBetweenDates_mdacc
	Date Last Modified: 	2/22/2008
	Change - History: 		2/22/2008 jmd changed some joins so cytology can see things not assigned.
	
  */

if @acc_cat = ''
	set @acc_cat = '%'



SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET ANSI_NULLS OFF
SET CONCAT_NULL_YIELDS_NULL OFF
SET QUOTED_IDENTIFIER OFF

BEGIN

-- fixing dates
		set 	@start_date = dbo.fnc_fix_dates_mdacc('START DATE', @start_date)
		set	@end_date = dbo.fnc_fix_dates_mdacc('END DATE', @end_date)
		
-- query

select	aspec.collection_date,
		a.created_date accession_created,
		ao.completed_date,
		datediff(mi, ao.created_date, ao.completed_date) / 60.0 as duration,
		dbo.fnc_CalcWeekDaysBetweenDates_mdacc(aspec.collection_date, ao.completed_date) as duration_between_col_and_comp,
		lo.description,
		lo.code,
		a.accession_no,
		pmrn.med_rec_no,
		p2.full_name

from acc_order ao
join lab_procedure lo on lo.id = ao.procedure_id
join accession_2 a on ao.acc_id = a.id
join acc_specimen aspec on aspec.acc_id = a.id
join patient_mrn_2 pmrn on a.patient_mrn_id = pmrn.id
right outer join acc_role_assignment ara on ara.acc_id = a.id --changed so cytology can see things not assigned, next 2 lines
left outer join personnel_2 p2 on p2.id = ara.assigned_to_id

where lo.code like @order_code + '%'
and a.created_date between @start_date and @end_date
and a.acc_catg like @acc_cat
order by a.created_date

end
GO


