USE [Test]
GO

/****** Object:  StoredProcedure [dbo].[stpc_merge_emr_mdacc]    Script Date: 2/26/2018 10:13:08 AM ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO



CREATE PROCEDURE [dbo].[stpc_merge_emr_mdacc] 

		@badmrn varchar(20), @goodmrn varchar(20), @perform char(1) = 'N'

AS


/*  Template version: 	1.0
	Primary Author: 	Judson Dunn
	Date Created:		10/23/2014
	Purpose: 		    merge patients when we don't have the good mrn in powerpath and need to update the patient_cases table
	Date Last Modified: 	
	Change - History: 		
*/


BEGIN


--the intention is that you would run this first without the perform = 'Y', and confirm that it's the correct patient, mrn, destination, then add 'Y'
if @perform = 'N'
begin

  select name.full_name, 'merging to new mrn: ' + @goodmrn
  from patient_name_2 name
  join patient_mrn_2 mrn on mrn.patient_id = name.patient_id
  where mrn.med_rec_no = @badmrn

end
  

if @perform = 'Y'
begin
  update patient_cases
  set med_rec_no = @goodmrn
  where med_rec_no = @badmrn
  
  select 'MRN ' + @badmrn + ' was changed to ' + @goodmrn + '.' as Output_Line
end

END


GO


