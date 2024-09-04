/*******************************************
INTRODUCTION.

This is to show common Anti-Patterns and to know what to look out for.... 
I'd prefer to take questions at the end of each "chapter".

How do I find all this stuff:   sp_BlitzCache can be used to find existing issues.
*******************************************/
/*Parallelism Stuff - Set to something vaguely sensible*/
/*Sticks finger in air to see which way wind blows*/
exec sys.sp_configure 'show advanced options', 1;
go
reconfigure with override;
go
exec sys.sp_configure 'max degree of parallelism', 4;
go
reconfigure with override;
go
exec sys.sp_configure 'cost threshold for parallelism', 50;
go
reconfigure with override;
go

/*
I am using Andy Yun's Autodealership database for this demo. 
    https://github.com/SQLBek

Other sources of inspiration:
    https://www.brentozar.com/
    https://littlekendra.com/
    https://erikdarling.com/

Further Reading:
    Grant and Hugo's book on Execution Plans: 
    https://www.red-gate.com/products/redgate-monitor/entrypage/execution-plans
*/

use AutoDealershipDemo;
go


	

/*Create a Function*/
create or alter function dbo.InitialCap
(
    @String varchar(8000)
)

/***************************************************************************************************

 Purpose:

 Capitalize any lower case alpha character which follows any non alpha character or single quote.

 Revision History:

 Rev 00 - 24 Feb 2010 - George Mastros - Initial concept

 http://blogs.lessthandot.com/index.php/DataMgmt/DBProgramming/sql-server-proper-case-function

 Rev 01 - 25 Sep 2010 - Jeff Moden

 - Redaction for personal use and added documentation.

 - Slight speed enhancement by adding additional COLLATE clauses that shouldn't have mattered

 - and the reduction of multiple SET statements to just 2 SELECT statements.

 - Add no-cap single-quote by single-quote to the filter.

***************************************************************************************************/

returns varchar(8000)
as
begin

    ----------------------------------------------------------------------------------------------------

    declare @Position int;

    --===== Update the first character no matter what and then find the next postion that we

    -- need to update. The collation here is essential to making this so simple.

    -- A-z is equivalent to the slower A-Z

    select @String   = stuff(lower(@String), 1, 1, upper(left(@String, 1)))collate Latin1_General_BIN
         , @Position = patindex('%[^A-Za-z''][a-z]%', @String collate Latin1_General_BIN);

    --===== Do the same thing over and over until we run out of places to capitalize.

    -- Note the reason for the speed here is that ONLY places that need capitalization

    -- are even considered for @Position using the speed of PATINDEX.

    while @Position > 0
        select @String
                         = stuff(@String, @Position, 2, upper(substring(@String, @Position, 2)))collate Latin1_General_BIN
             , @Position = patindex('%[^A-Za-z''][a-z]%', @String collate Latin1_General_BIN);

    ----------------------------------------------------------------------------------------------------

    return @String;

end;
go


