/**************************************************************
Forced Serialization
Something prevents a query from using multiple threads when it probably should.
This will make some querys take WAY longer to execute
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

/*Set Parallization Thesholds unrealistically low*/
exec sys.sp_configure 'show advanced options', 1;
go
reconfigure with override;
go
exec sys.sp_configure 'cost threshold for parallelism', 5; /*Amusingly the default*/
go
reconfigure with override;
go

/*Create a Simple Parallel Query*/

select InventoryFlat.ModelName
     , Color.ColorName
	 ,count(*)
from dbo.InventoryFlat
    join Vehicle.Color
        on Color.ColorCode = InventoryFlat.ColorCode
group by
	 InventoryFlat.ModelName
     , Color.ColorName
go


/*
Introduce a Scalar User Defined Functions
*/


select InventoryFlat.ModelName
     , dbo.InitialCap(Color.ColorName) as ColorName
	 ,count(*)
from dbo.InventoryFlat
    join Vehicle.Color
        on Color.ColorCode = InventoryFlat.ColorCode
group by
	 InventoryFlat.ModelName
     , Color.ColorName
go


/*
Note that despite the Function only being in the SELECT it still prevents the query going Parallel
Also Note that the Functions doesn't appear in the Query Plan...
It also runs once per row...

Right click on the SELECT in the plan to see if it was blocked,  DOP = 0
*/

/*Table  Variables

"Only use a Table Variable if the # key on your keyboard is broken.  
No on second thoughts even then go buy a new keyboard and then run your query"
 -Erik Darling
 
*/


declare @brokenkey table
(
    ModelName varchar(50)
  , ColorName varchar(50)
  ,Totals int
);

insert into @brokenkey
(
    ModelName
  , ColorName
  ,Totals
)
select InventoryFlat.ModelName
     , Color.ColorName as ColorName
	 ,count(*)
from dbo.InventoryFlat
    join Vehicle.Color
        on Color.ColorCode = InventoryFlat.ColorCode
group by
	 InventoryFlat.ModelName
     , Color.ColorName

select ModelName
     , ColorName
	 ,totals
from @brokenkey;
go

/*Vs a Temporary Table*/
create table #ok
(
    ModelName varchar(50)
  , ColorName varchar(50)
  ,totals int
);

insert into #ok
(
    ModelName
  , ColorName
  ,totals
)
select InventoryFlat.ModelName
     , Color.ColorName as ColorName
	 ,count(*)
from dbo.InventoryFlat
    join Vehicle.Color
        on Color.ColorCode = InventoryFlat.ColorCode
group by
	 InventoryFlat.ModelName
     , Color.ColorName


select ModelName
     , ColorName
	 ,totals
from #ok;
go

/*Set the Parallelism Setting back to something sensible*/
exec sys.sp_configure 'cost threshold for parallelism', 50;
go
reconfigure with override;
go

/**************************************************************
FORCED SERIALIZATION TAKEHOME:
    Avoid Scalar User Defined Functions
    Don't use table variables
***************************************************************/

