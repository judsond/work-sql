USE [Test]
GO

/****** Object:  StoredProcedure [dbo].[stpc_ihc_charge_pro_mdacc]    Script Date: 2/26/2018 10:29:05 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[stpc_ihc_charge_pro_mdacc]
AS
/*
DATE:		12/18/2013
AUTHOR:		Judson Dunn
PURPOSE:	This STP will update the charges to change subsequent IHC charges to the 5466 code.
NOTES:		8/21/2014 - changed to also include 1205204 for BRAF jmd
            4/21/2016 - changed to epic charge codes jmd
*/
set nocount on

BEGIN

DECLARE @ihcupdate TABLE (charge_id int)
DECLARE @ihccodes TABLE (codes int)

insert @ihccodes select id from service_code where code in ('31000256','31000259')


INSERT @ihcupdate

--Get the list of charges that are eligible 
SELECT ac.id
FROM acc_charges ac (NOLOCK)

WHERE ac.xfer_billing_date is null
    AND ac.rec_type = 'L'  --The charge was generated by a stain on a slide
	AND ac.service_code_id in (select * from @ihccodes) --it's one of the service codes in the list above
	AND ac.comp_type = 'P' --professional



    UPDATE  acc_charges
	SET  
		 billing_code = '88341'
	FROM 	acc_charges ac 
	JOIN	@ihcupdate i on i.charge_id = ac.id 
	JOIN 	acc_order ao1 on ao1.id = ac.rec_id  
		and ac.rec_id <> (select min(ao2.id) 
		  from acc_order ao2 
	      where ao2.acc_specimen_id  = ao1.acc_specimen_id
		  and ao2.service_code_id in (select * from @ihccodes)  )  --and it's not the lowest in the group on that specimen
    WHERE billing_code in ('5465', '88342')

END

GO

