################################################################################
# DesignMC/lib/JSON.g                                           Andy L. Drizen
#                                                                   26/02/2011
# File overview:
# 
# This is a VERY BASIC JSON interpreter. If you make a JSON object using it,
# then you probably won't have an issue reading it. As GAP hates floating point
# numbers, any JSON object containing a float will make the parser fail - 
# to avoid this issue, turn your floats in to string.
#
################################################################################

CreateJSONStringFromRecord:=function( input )
	local names,item, str,i,tmp;
	names:=RecNames(input);
	str:="{";
	for item in [1..Size(names)] do
		str:=Concatenation(str, "\"",names[item],"\"");
		str:=Concatenation(str, ":");
		if IsRecord(input.(names[item])) then
			str:=Concatenation(str, CreateJSONStringFromRecord(input.(names[item])) );
		else
			if IsList(input.(names[item])) or IsBool(input.(names[item])) or IsInt(input.(names[item])) then
				str:=Concatenation(str, String(input.(names[item])) );
			else
				str:=Concatenation(str, "\"",String(input.(names[item])) ,"\"");
			fi;
		fi;

		if item < Size(names) then
			str:=Concatenation(str, ", ");
		fi;
	od;
	str:=Concatenation(str, "}");
	return str;
end;

CreateRecordFromJSONString:=function( str )
	local s,result,pos,recname,recvalue,q,k,tmp_rec,m;
	pos:=2;
	result:=rec();
	recname:="";
	str:=ReplacedString(str, "\n", "");
	str:=ReplacedString(str, "\t", "");
	s:=Size(str);
	while pos < s do
		if str[pos] = '\"' then
			q:=SubstringIndexInString(str, ['\"'], pos+1);
			if recname = "" then
				recname:=Substring(str, pos+1, q-pos-2);
			else
			
				# I need to parse this string if
				# it should be prased (e.g. if the string is
				# "Group([()])" then I want to parse it.
				#
				# However, I can't find a try/catch system
				# in GAP and EvalString will crash the 
				# program if the string shouldn't have been
				# parsed...
			
				result.(recname):=Substring(str, pos+1, q-pos-2);
				recname:="";
			fi;
			pos:=q+1;
			continue;
		fi;
		if str[pos] = ':' then
		
			if SubstringIndexInString(str, ",", pos) > -1 then
				# this ISN'T the last element
				k:=SubstringIndexInString(str, ",", pos+1);
			else
				# this IS the last element
				k:=SubstringIndexInString(str, "}", pos+1);
			fi;
		
			if 	(SubstringIndexInString(str, "[", pos) = -1 or
				SubstringIndexInString(str, "[", pos) > k) and
				(SubstringIndexInString(str, "{", pos) = -1 or
				SubstringIndexInString(str, "{", pos) > k) and
				(SubstringIndexInString(str, "\"", pos) = -1 or
				SubstringIndexInString(str, "\"", pos) > k)
				then
				
				# in this situation, we've just seen a colon and we're not defining an array, string 
				# or dictionary so we put everything between here and the next comma (excluding 
				# whitespace) in to the rec under the tmp_str name.
				
				q:=k;
				recvalue:=Substring(str, pos+1, q-pos-2);
				NormalizeWhitespace(recvalue);
				result.(recname):=EvalString(recvalue);
				recname:="";
				pos:=q+1;
				continue;
			fi;
		fi;
		if str[pos] = '[' then
			q:=FindMatchingBracket(Substring(str, pos, s), '[', ']');
			recvalue:=Substring(str, pos, q-1);
			
			# now parse this list for records.
			k:=SubstringIndexInString(recvalue, "{", 0);
			
			while k >- 1 do
				m:=FindMatchingBracket(Substring(recvalue, k, Size(recvalue)), '{', '}');
				tmp_rec:=CreateRecordFromJSONString(Substring(recvalue, k, m ));
				recvalue:=Concatenation(Substring(recvalue, 1, k-2), String(tmp_rec), Substring(recvalue, m+k, Size(recvalue))) ;
				k:=SubstringIndexInString(recvalue, "{", 0);
			od;
			
			result.(recname):=EvalString(recvalue);
			recname:="";
			pos:=pos+q;
			continue;
		fi;
		if str[pos] = '{' then
			q:=FindMatchingBracket(Substring(str, pos, s), '{', '}');
			recvalue:=CreateRecordFromJSONString(Substring(str, pos, q-1));
			result.(recname):=recvalue;
			recname:="";
			pos:=pos+q;
			continue;
		fi;
		pos:=pos+1;
	od;
	return result;
end;

JSONStringify:=function( input, path )
	local out;
	out:=OutputTextFile(path, false);
	SetPrintFormattingStatus(out, false);
	PrintTo(out, CreateJSONStringFromRecord(input));
end;

JSONParse:=function( path )
	local result,input;
	input:=InputTextFile(path);
	result:=CreateRecordFromJSONString( ReadAll(input) );
	return result;
end;
