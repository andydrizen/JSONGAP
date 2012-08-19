JSONGAP
=======

A simple JSON parser for GAP.

Licence
-------

GNU GENERAL PUBLIC LICENSE, Version 3

Installation
------------

GAP v4.5.5 and the [Strings Package](https://github.com/andydrizen/Strings/)


To initialise the JSONGAP Package, put the JSON folder in the pkg directory of your GAP 
root and in GAP type:

`gap> LoadPackage("JSONGAP");`

Alternatively, you can download the source to any/folder/you/like/JSONGAP and then run GAP with

`gap -l 'path/to/your/GAP4r5r5/bin/;any/folder/you/like/;'`

Quick Start
-----------

### JSONStringify( rec() )

Returns a JSON string of your rec().

### JSONStringifyToPath( rec(), path )
		
Outputs a JSON version of your rec() to the specified path. 

For example,

    gap> JSONStringify( rec( blocks := [ [ 1, 4, 7 ], [ 1, 5, 8 ] ], improper := false, tSubsetStructure := rec( lambdas := [ 1, 0 ] ) ) , "~/Desktop/example1.js");

will yield the following string in the file stated:

    {"blocks":[ [ 1, 4, 7 ], [ 1, 5, 8 ] ], "improper":false, "tSubsetStructure":{"lambdas":[ 1, 0 ]}}
		
### JSONParse( jsonString )
		
Converts a JSON string to a rec(). For safety, you might to only use this function on strings that were created with JSONStringify

### JSONParseFromPath( jsonString, path )

Read the contents of the file given in path as a string and convert it to a record. For example,

    gap> JSONParse("~/Desktop/example1.js");

will return:

    rec( blocks := [ [ 1, 4, 7 ], [ 1, 5, 8 ] ], improper := false, tSubsetStructure := rec( lambdas := [ 1, 0 ] ) )
	

Advanced Features
-----------------

### GAP:// Prefix for Groups

Suppose that you have the following record:

    rec(myGroup:=Group([(1,2)(3,4)]));

If, when converting to a JSON string we obtained:

	{"myGroup":"Group([(1,2)(3,4)])");
	
we have to ensure that GAP doesn't parse this back to a string, like so:

    rec(myGroup:="Group([(1,2)(3,4)])");
    
Therefore, when using JSONStringify, any GAP Groups are preceded by `GAP://`. This indicates to the JSONParse function that what follows must be evaluated.

    gap> myRec:=rec(myGroup:=Group([(1,2)(3,4)]));;
    gap> jsonString:=JSONStringify(myRec);
    "{\"myGroup\":\"GAP://Group( [ (1,2)(3,4) ] )\"}"
    gap> JSONParse(jsonString);
	rec( myGroup := Group([ (1,2)(3,4) ]) )


