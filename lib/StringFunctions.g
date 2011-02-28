################################################################################
# JSONGAP/lib/StringFunctions.g                                 Andy L. Drizen
#                                                                   26/02/2011
# File overview:
#
# SubstringIndexInString
#
# Substring
#
# FindMatchingBracket
#
################################################################################

SubstringIndexInString:=function( haystack, needle, offset )
	local h,n,k, sh, sn;
	sh:=Size(haystack);
	sn:=Size(needle);
	for h in [1+offset..sh - sn+1] do
		k:=0;
		for n in [1..sn] do
			if needle[n] = haystack[h+n-1] then
				k:=k+1;
			fi;
		od;
		if k = sn then
			return h;
		fi;
	od;
	return -1;
end;

Substring:=function( str, start, length )
	local result, i,s;
	result:="";
	s:=Size(str);
	for i in [start..Minimum(start+length, s)] do
		Add(result, str[i]);
	od;
	return result;
end;

FindMatchingBracket:=function ( str, open, close )
	local offset,o,c;
	offset:=1;
	while offset < Size(str) do
		o:=SubstringIndexInString( str, [open], offset);
		c:=SubstringIndexInString( str, [close], offset);
		if 	o =-1 or c < o then
			return c;
		else
			offset:=o-1 + FindMatchingBracket(Substring(str,o, Size(str)), open, close );
		fi;
	od;
	return 0;
end;