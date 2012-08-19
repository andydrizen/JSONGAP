JSONGAP
=======

A simple JSON parser for GAP.

Licence
-------

GNU GENERAL PUBLIC LICENSE, Version 3

Installation
------------

### Installation
		
GAP v4.5.5 and the [Strings Package](https://github.com/andydrizen/Strings/)


To initialise the JSONGAP Package, put the JSON folder in the pkg directory of your GAP 
root and in GAP type:

`gap> LoadPackage("JSONGAP");`

Alternatively, you can download the source to any/folder/you/like/JSONGAP and then run GAP with

`gap -l 'path/to/you/GAP4r5r5/bin/;any/folder/you/like/;'`

### Usage

## Quick Start

`JSONStringify( rec() )`

Returns a JSON string of your rec().

`JSONStringifyToPath( rec(), path )`
		
Outputs a JSON version of your rec() to the specified path. 

For example,

    gap> JSONStringify( rec( blocks := [ [ 1, 4, 7 ], [ 1, 5, 8 ] ], improper := false, tSubsetStructure := rec( lambdas := [ 1, 0 ] ) ) , "~/Desktop/example1.js");

will yield the following string in the file stated:

    {"blocks":[ [ 1, 4, 7 ], [ 1, 5, 8 ] ], "improper":false, "tSubsetStructure":{"lambdas":[ 1, 0 ]}}
		
`JSONParse( jsonString )`
		
Converts a JSON string to a rec(). For safety, you might to only use this function on strings that were created with JSONStringify

`JSONParseFromPath( jsonString, path )`

Read the contents of the file given in path as a string and convert it to a record. For example,

    gap> JSONParse("~/Desktop/example1.js");

will return:

    rec( blocks := [ [ 1, 4, 7 ], [ 1, 5, 8 ] ], improper := false, tSubsetStructure := rec( lambdas := [ 1, 0 ] ) )
	
