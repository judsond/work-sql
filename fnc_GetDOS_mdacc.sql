USE [Test]
GO

/****** Object:  UserDefinedFunction [dbo].[fnc_GetDOS_mdacc]    Script Date: 2/26/2018 10:11:25 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE function [dbo].[fnc_GetDOS_mdacc] (@charge_id int)

returns datetime

as
/*
	VERSION:		3
	AUTHOR:  		Judson Dunn
	DATE:			11/1/2013
	TASK:			Function to return date of service given charge id
	HISTORY:        Change the DOS on inside cases to be the collection date. jmd 2016-03-29
					Change the DOS on professional charges to be the sign-out date. jmd 2016-08-12
					Make the professional calculation not include sign-out dates after the transfer date for reporting jmd 2017-03-15
	
*/

BEGIN	

declare @chargedate datetime
declare @rectype varchar(1)
declare @dos datetime
declare @recv_date datetime
declare @col_date datetime
declare @fallback_r datetime
declare @fallback_c datetime
declare @type varchar(1)
declare @comptype varchar(1)
declare @accid int

select @rectype = ac.rec_type, @fallback_r = fb.recv_date, @fallback_c = fb.collection_date, @type = t.type, @comptype = ac.comp_type, @accid = a.id
from acc_charges ac
join accession_2 a on ac.acc_id = a.id
join acc_type t on a.acc_type_id = t.id
join acc_specimen fb on a.primary_specimen_id = fb.id
where ac.id = @charge_id

-- Professional

if @comptype = 'P'
begin
  select @dos = max(aps.completed_date)
  from acc_process_step aps
  join process_step ps on aps.step_id = ps.id
  join acc_charges pro_charge on pro_charge.id = @charge_id
  where aps.acc_id = @accid
  and aps.completed_date < isnull(pro_charge.xfer_billing_date,getdate())
  and ps.type = 'F'
end

-- Technical

if @comptype = 'T'
begin
	if @rectype in ('L','O') 
	begin
	  select @chargedate = charge_order.created_date, @recv_date = sp.recv_date, @col_date = sp.collection_date
	  from acc_order charge_order
	  join acc_charges charge on charge_order.id = charge.rec_id
		and charge_order.acc_id = charge.acc_id
	  join acc_specimen sp on charge_order.acc_specimen_id = sp.id
	  where charge.id = @charge_id
	end
	else if @rectype = 'S'
	begin
	  select @recv_date = sp.recv_date, @col_date = sp.collection_date
	  from acc_specimen sp
	  join acc_charges charge on charge.rec_id = sp.id
	  where charge.id = @charge_id
	end

	if @type = 'C' --consult type case
	  begin
		if @recv_date is null
			set @dos = @fallback_r --primary specimen receive date
		else if datediff(dd,@recv_date,@chargedate) > 30
			set @dos = @chargedate
		else
			set @dos = @recv_date
	  end
	else if @type = 'N' --normal (non-consult) case
	  begin
		if @col_date is null
			set @dos = @fallback_c --primary specimen collect date
		else if datediff(dd,@col_date,@chargedate) > 30
			set @dos = @chargedate
		else
			set @dos = @col_date
	  end
end


return @dos

END






GO


