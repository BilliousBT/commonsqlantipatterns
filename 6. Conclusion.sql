/****Synopsis****/

/*

There are many ways to write queries and there are some pretty large "GOTCHA"s where the way you write the query causes the SQL Engine to generate poor query plans

This includes:

* Ignoring Indexes
* Misusing Indexes
* Poor Plan Estimates
* Serialization

In most cases it is simply a matter of being aware of these common issues and keeping them in mind when writing TSQL.

* Pay attention to DATA TYPES
* Write SARGable queries
* AVOID User-defined Functions
* Get a new keyboard if the # key is broken  (seriously never use @tables)   (Paraphrasing Erik here)
* Remmember that INDEXES are important in JOINs as well as WHERE  (and ORDER BY)

Check your query plans for the little yellow exclaimation points.  If you find one, then your query can
probably be written in a better way.

*/

/*Clean Up Session*/