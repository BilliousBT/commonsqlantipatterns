/*
**********************************************************************************
Ignoring Indexes

Much like the index suggestion bot (Who Brent calls Clippy), most people are hyper-focused on the WHERE clauses for indexes, and end up missing indexes when JOINing tables

It's along worth noting that the missing index requests shown in the query plans are only the first one that is suggested and may not be the best one.

**************************************************************
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

create or alter procedure dbo.pr_WhiteRAV4
as
select InventoryFlat.ModelName
     , Color.ColorName
from dbo.InventoryFlat
    join Vehicle.Color
        on Color.ColorCode = InventoryFlat.ColorCode
where Color.ColorName = 'Super White'
      and InventoryFlat.ModelName = 'RAV4';

/*
Scanning Both tables, and a missing index request
Cost. 4800+ reads
*/
exec dbo.pr_WhiteRAV4;


/*But hey! lets add that Index, that is sure to help.... right? */
create index NowImJustPaperingOverCracks
on dbo.InventoryFlat (ModelName)
include (
          
      ColorCode
        );

/*Try Again*/
exec dbo.pr_WhiteRAV4;

/*Seeking on One, Scan the other, 47 reads*/

/*Now lets try this new suggested index.... */
create index CoveringIndex
on dbo.InventoryFlat (
                         ModelName
                       , ColorCode
                     )

/*Try Again*/
exec dbo.pr_WhiteRAV4;

/*A much better seek: 10 reads,*/

/*This is really common and is the source of a lot of our missing index requests*/

/*Clean-Up*/
drop index if exists NowImJustPaperingOverCracks on dbo.InventoryFlat;
drop index if exists CoveringIndex on dbo.InventoryFlat;
drop procedure if exists pr_WhiteRAV4;
go

/*
TAKE HOME

Indexes matter just as much for JOINs as well as WHERE

*/

