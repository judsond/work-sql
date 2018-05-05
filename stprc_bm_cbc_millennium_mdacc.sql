USE [Test]
GO

/****** Object:  StoredProcedure [dbo].[stprc_bm_cbc_millennium_mdacc]    Script Date: 2/26/2018 10:13:51 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[stprc_bm_cbc_millennium_mdacc]
(
     @acc_id int
)
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET ANSI_NULLS OFF
SET CONCAT_NULL_YIELDS_NULL OFF
SET QUOTED_IDENTIFIER OFF


/*	Template version: 	1.0
	Primary Author: 	Judson Dunn
	Requestor: 			Dr. Bueso-Ramos
	Date Created:		2015-09-23
	Purpose: 			pull Millennium PB diff data into powerpath patient report.
	Dependent Reports:	
	Depends On: 		
	Date Last Modified: 2017-03-09	
	Change - History: 	2017-03-09 - hl - added 'Complete Blood Count w/ Indices'.
						2015-12-29 - hl - added '.Complete Blood Count w/ Automated Differential' to accommodate change in Millennium.
						2015-12-22 - hl - added 'CBC' and '.CBC' to accommodate change in Millennium.	
*/

BEGIN

declare @mrn varchar(50)
declare @created datetime
declare @order_accession varchar(30)
declare @observation_time varchar(max)

-- get the MRN
select @mrn = mrn.med_rec_no, @created = a.created_date
from patient_mrn_2 mrn
join accession_2 a on a.patient_mrn_id = mrn.id and a.id = @acc_id

-- get the right accession
select @order_accession = (
  select top 1 macc.accession
  from [SPIDRA].[Millennium].[dbo].[OrdersByMRN] macc
  where macc.MRN = @mrn
  and macc.Name in ('Complete Blood Count w/ Automated Differential', '.Differential', 'CBC', '.CBC', '.Complete Blood Count w/ Automated Differential', 'Complete Blood Count w/ Indices')	-- added 'CBC' and '.CBC.' 12/22/2015, hl; added '.Complete Blood Count w/ Automated Differential' 12/29/2015, hl
																																															-- added 'Complete Blood Count w/ Indices' 03/09/2017, hl
  and macc.status in ('Final','Corrected')
  and macc.observationdatetime between DATEADD(dd,-7,@created) and @created
  order by macc.observationdatetime desc
  )

-- get observation time
select @observation_time = 'Observation date: ' + convert(char(10), O2.observationdatetime, 101)
from [SPIDRA].[Millennium].[dbo].[OrdersByMRN] O2
where O2.accession = @order_accession

-- get the result string
select cast(stuff((
SELECT 

', ' + rt.testname + ' ' + r.result  + isnull(r.units,'') + isnull(' ' + r.critical_flag,'') 
+ case when r.range = '' then '' else (' (' + r.range + ')') end

FROM [SPIDRA].[Millennium].[dbo].[OrdersByMRN] O with (nolock)
INNER JOIN [SPIDRA].[Millennium].[dbo].[tbl_Results] R with (nolock) ON O.TestID = R.fk_Transaction_id
INNER JOIN [SPIDRA].[Millennium].[dbo].[tbl_CERNER_Tests] RT with (nolock) ON R.fk_Result_Test_id = RT.pk_Test_ID
WHERE r.deleted <> 1
AND o.accession = @order_accession
--add
AND o.Name in ('Complete Blood Count w/ Automated Differential', '.Differential', 'CBC', '.CBC', '.Complete Blood Count w/ Automated Differential', 'Complete Blood Count w/ Indices')	-- added 'CBC' and '.CBC.' 12/22/2015, hl; added '.Complete Blood Count w/ Automated Differential' 12/29/2015, hl
																																														-- added 'Complete Blood Count w/ Indices' 03/09/2017, hl
AND o.status in ('Final','Corrected')
AND o.observationdatetime between DATEADD(dd,-7,@created) and @created
--end
ORDER BY O.code, R.pk_Result_ID -- changed code sort order to ascending. 12/29/2015, hl

for xml path ('')
),1,1,'') as varchar(max)) + @observation_time as result_string

END




GO


