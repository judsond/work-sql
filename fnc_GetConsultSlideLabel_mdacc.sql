USE [Test]
GO

/****** Object:  UserDefinedFunction [dbo].[fnc_GetConsultSlideLabel_mdacc]    Script Date: 2/26/2018 10:11:44 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO






CREATE function [dbo].[fnc_GetConsultSlideLabel_mdacc] (@slide_id int)
returns varchar(20)
as
/*
	AUTHOR:  		Judson Dunn
	DATE:			11/9/2016
	TASK:			Function to return consult block label given a slide ID, like fnc_GetSlideLabel_mdacc.
	DEPENDENT REPORTS:	PathStation reprint label form

*/
begin	

declare @label varchar (20)
	
select  @label = coalesce(sp.consult_accession_no,'') + ' ' + coalesce (b.consult_label,'') + ' ' + coalesce (s.consult_label,'')
from 
	acc_slide s (nolock)
	LEFT OUTER JOIN acc_specimen sp (nolock) ON sp.id = s.acc_specimen_id
	LEFT OUTER JOIN acc_order o (nolock) ON o.id = s.acc_order_id
	LEFT OUTER JOIN acc_block b (nolock) ON (o.source_rec_type = 'B') AND (b.id = o.source_rec_id)
WHERE s.id = @slide_id

return @label

END






GO


