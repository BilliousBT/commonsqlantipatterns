/**************************************************************
SARGABILITY
"Search ARGument ABLE"
**************************************************************
Example Non-SARGables:  (JOIN or WHERE)
        function(column) = something
        column+column = something
        column + value = something
        value + column = something
        column = @something or @something is null
        column like '%something'
        column = case when...
**************************************************************
Why is this bad...
**************************************************************
        Increased CPU
        Index Scans
        Implicit Conversions
        Poor Cardinalisty Estimates
        Inappropriate Plan Choices
        Long Running Queries
**************************************************************/
use AutoDealershipDemo;
go
/*Prep - Remember to turn on Query Plans*/
dbcc dropcleanbuffers;
checkpoint;
dbcc freeproccache with no_infomsgs;
set statistics io, time on;
go

/*Drop Existing Index*/
drop index if exists IX_InventoryFlat_ModelName on dbo.InventoryFlat;
go

/*SARGable*/
create or alter procedure dbo.SARGable @model varchar(50)
as
select ModelName
     , InvoicePrice
     , MSRP
from dbo.InventoryFlat
where ModelName = @model;
go


/*NON-SARGable*/
/*Functions*/
create or alter procedure dbo.NonSARGable_Function @model varchar(50)
as
select ModelName
     , InvoicePrice
     , MSRP
from dbo.InventoryFlat
where upper(ModelName) = @model;;
go

/*
Missing Index Requests
*/
exec dbo.SARGable @model = 'RAV4';
exec dbo.NonSARGable_Function @model = 'RAV4';
go

/*Lets Create that Index*/
create nonclustered index IX_InventoryFlat_ModelName
on dbo.InventoryFlat (ModelName asc)
include (
            InvoicePrice
          , MSRP
        );
go

/*Run that again*/
exec dbo.SARGable @model = 'RAV4';
exec dbo.NonSARGable_Function @model = 'RAV4';
go


/*Like with leading wildcard*/
exec dbo.SARGable @model = 'RAV4';
select ModelName
     , InvoicePrice
     , MSRP
from dbo.InventoryFlat
where ModelName like '%AV4';

go

/*Case Statements*/
create or alter procedure dbo.NonSARGable_Case @model varchar(50)
as
select ModelName
     , InvoicePrice
     , MSRP
from dbo.InventoryFlat
where case
          when ModelName = 'foo' then
              'bar'
          else
              ModelName
      end = @model;
go

exec dbo.SARGable @model = 'RAV4';
exec dbo.NonSARGable_Case @model = 'RAV4';
go

/*StringManipulation*/
create or alter procedure dbo.NonSARGable_String @model varchar(50)
as
select ModelName
     , InvoicePrice
     , MSRP
from dbo.InventoryFlat
where '' + ModelName = @model;
go

exec dbo.SARGable @model = 'RAV4';
exec dbo.NonSARGable_String @model = 'RAV4';
go

/*Arithmatic*/
/*Note the same issues with CPU and Rows read.  The second query reads 20M rows for 1 record.*/
select InventoryFlatID
from dbo.InventoryFlat
where InventoryFlatID = 12;
select InventoryFlatID
from dbo.InventoryFlat
where InventoryFlatID - 1 = 11;
go

/*Optional Parameters*/
create or alter procedure dbo.NonSARGable_OptionalParameters1 @model varchar(50)
as
select ModelName
     , InvoicePrice
     , MSRP
from dbo.InventoryFlat
where ModelName = @model
      or @model is null;
go

create or alter procedure dbo.NonSARGable_OptionalParameters2 @model varchar(50)
as
select ModelName
     , InvoicePrice
     , MSRP
from dbo.InventoryFlat
where ModelName = isnull(@model, ModelName);
go


/*So how does this go...*/
exec dbo.SARGable @model = 'RAV4';
exec dbo.NonSARGable_OptionalParameters1 @model = 'RAV4';
exec dbo.NonSARGable_OptionalParameters2 @model = 'RAV4';

/*Cleanup*/

drop procedure if exists dbo.SARGable;
drop procedure if exists dbo.NonSARGable_OptionalParameters1;
drop procedure if exists dbo.NonSARGable_OptionalParameters2;
drop procedure if exists NonSARGable_String;
drop procedure if exists NonSARGable_Case;
drop procedure if exists NonSARGable_Function;

/**************************************************************
SARGABILITY TAKEHOME:

Make Predicates SARGable, even if you don't need to, unless you can't.
(make it a habit for when it does matter)

"Code is Culture" - Write good SQL, so newbies write good SQL

Can't stress this once enough TBH.  Do it... DO IT... DOOOO IIIITTT!
***************************************************************/