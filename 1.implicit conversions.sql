/*
**********************************************************************************
Implicit Conversions

This common SQL Performance issue occurs when SQL Server 
has to convert a data type on the fly 

**************************************************************
Why is this bad?
**************************************************************
This has a HIGH CPU cost.
**********************************************************************************
REMEMBER TO TURN ON EXEC PLANS
*/
use AutoDealershipDemo;
go

/*Prep*/
/*Reticulating Splines*/
dbcc dropcleanbuffers;
checkpoint;
dbcc freeproccache with no_infomsgs;
set statistics io, time on;
go

/*Make sure this index isn't there*/
drop index if exists IX_InventoryFlat_ModelName on dbo.InventoryFlat;
go

/*Create some simple Procedures.  
Note the param is a varchar/nvarchar*/

/*This one uses the right data type*/
create or alter procedure dbo.ImplicitConversion_Good @model varchar(50)
as
select ModelName
     , InvoicePrice
     , MSRP
from dbo.InventoryFlat
where ModelName = @model;
go

/*This one does not*/
create or alter procedure dbo.ImplicitConversion_Bad @model nvarchar(50)
as
select ModelName
     , InvoicePrice
     , MSRP
from dbo.InventoryFlat
where ModelName = @model;
go

/*
Missing Index Requests
Plan Warning
*/

exec dbo.ImplicitConversion_Good @model = 'RAV4';
exec dbo.ImplicitConversion_Bad @model = N'RAV4';
go

/*Lets add that index*/
/****** Object:  Index [IX_InventoryFlat_ModelName]    Script Date: 19/08/2024 20:23:14 ******/
create nonclustered index IX_InventoryFlat_ModelName
on dbo.InventoryFlat (ModelName asc)
include (
            InvoicePrice
          , MSRP
        );
go

/*Run again.  Seek v Scan*/
exec dbo.ImplicitConversion_Good @model = 'RAV4';
exec dbo.ImplicitConversion_Bad @model = 'RAV4';
go

/*What about explicit conversions?*/
/*Will this work?*/
create or alter procedure dbo.ImplicitConversion_CAST_Parameter @model nvarchar(50)
as
select ModelName
     , InvoicePrice
     , MSRP
from dbo.InventoryFlat
where ModelName = cast(@model as varchar(50));
go

/*What about this?*/
create or alter procedure dbo.ImplicitConversion_CAST_Column @model nvarchar(50)
as
select ModelName
     , InvoicePrice
     , MSRP
from dbo.InventoryFlat
where cast(ModelName as nvarchar(50)) = @model;
go

/*Explicit Conversions CAN help... but not in all cases*/

exec dbo.ImplicitConversion_Good @model = 'RAV4';
exec dbo.ImplicitConversion_CAST_Parameter @model = 'RAV4';

exec dbo.ImplicitConversion_Good @model = 'RAV4';
exec dbo.ImplicitConversion_CAST_Column @model = 'RAV4';
go

/*and not in JOINS*/
select if1.ModelName
     , if1.InvoicePrice
     , if1.MSRP
from dbo.InventoryFlat     as if1
    join dbo.InventoryFlat as if2
        on if1.ModelName = cast(if2.ModelName as nvarchar(50))
where if1.InventoryFlatID = 1;

select if1.ModelName
     , if1.InvoicePrice
     , if1.MSRP
from dbo.InventoryFlat     as if1
    join dbo.InventoryFlat as if2
        on if1.ModelName = if2.ModelName
where if1.InventoryFlatID = 1;

/*Cleanup*/
drop procedure if exists dbo.ImplicitConversion_CAST_Column;
drop procedure if exists dbo.ImplicitConversion_CAST_Parameter;
drop procedure if exists dbo.ImplicitConversion_Good;
drop procedure if exists dbo.ImplicitConversion_Bad;

go

/**************************************************************
IMPLICIT CONVERSION TAKE HOME:

Take this into account in Queries with Paramaters, Variables and Temp Tables
Design better tables (rofl)

Use Explicit Conversions where necessary, but this may cause additional overhead, some conversions are super expensive.

The cost of this is generally very high vs the effort needed to correct it.
Unless you have to redesign tables, that sucks.
**************************************************************/
