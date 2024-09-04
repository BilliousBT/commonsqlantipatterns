/**************************************************************
Local Variables:
Literals vs Parameterised

"Local Variables are wierd" - Brent Ozar
**************************************************************
Literals get literal estimates
Local variables get... bad estimates
**************************************************************
Local Variables are "anonymised", not sniffed.
**************************************************************
Poor Estimates lead to poor plans and poor performance.

NB. No index for this query so it should be asking for a (BAD) one.
**************************************************************/
use AutoDealershipDemo;
go

/*Prep*/
/*Reticulating Splines*/
dbcc dropcleanbuffers;
checkpoint;
dbcc freeproccache with no_infomsgs;
set statistics io, time on;
go

/*Create Some Data Screw*/
select ModelName,Sold
     , count(*)
from dbo.InventoryFlat
group by ModelName,Sold;

delete from dbo.InventoryFlat
where ModelName = 'Land Cruiser'
      and PackageName <> 'Special Edition';

update dbo.InventoryFlat
set sold = case when ModelName = 'Land Cruiser' then 1 else 0 end;

select ModelName,Sold
     , count(*)
from dbo.InventoryFlat
group by ModelName,Sold;
go

/*Create Index*/
create index Sold on dbo.InventoryFlat (Sold);
drop index if exists IX_InventoryFlat_ModelName on dbo.InventoryFlat

/*SP uses a Literal Value*/
/*
Note we are using index hints here to force the index, so it doesn't just scan the PK
Please don't do this in production
*/
create or alter procedure dbo.LocalVariable_Literal
as

select ModelName
     , count(*)
from dbo.InventoryFlat with (index(Sold))
where Sold =1
group by ModelName;
go

/*SP uses a Local Variable*/
create or alter procedure dbo.LocalVariable_Local
as
declare @sold bit =1

select ModelName
     , count(*)
from dbo.InventoryFlat with (index(Sold))
where Sold =@sold
group by ModelName;
go

/*See how these compare*/

exec dbo.LocalVariable_Literal;
exec dbo.LocalVariable_Local;
go

/*And just to show that is isn't an issue with Parameters passed in*/
create or alter procedure dbo.LocalVariable_Parameter @sold bit
as

select ModelName
     , count(*)
from dbo.InventoryFlat with (index(Sold))
where Sold =@sold
group by ModelName;
go

exec dbo.LocalVariable_Literal;
exec dbo.LocalVariable_Parameter @sold =1;
go

/*Parameter Sniffing*/
exec dbo.LocalVariable_Parameter @sold =0;
go

/**************************************************************
LOCAL VARIABLE TAKEHOME:

Be very careful when debugging your Stored Procs by using Local Variables instead of Parameters. 
It isn't an accurate representation.

Poor Estimates lead to either:
 *Low Balling Resource usage leading to Spills to TempDb
 *High Balling Resource usage leading to excessive memory grants.

This does not always cause obvious issues, in particular if you have several other, 
non-local variable predicates that are highly selective, until it does.
***************************************************************/