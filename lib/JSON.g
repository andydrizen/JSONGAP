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

#############################################################################
##
#F  EvalString2( <expr> ) . .modified version that doesn't crash if it fails.
##
_EVALSTRINGTMP2 := 0;
EvalString2:=function( s )
  local a, f, res;
  a := "_EVALSTRINGTMP2:=";
  Append(a, s);
  Add(a, ';');
  Unbind(_EVALSTRINGTMP2);
  f := InputTextString(a);
  Read(f);
  if not IsBound(_EVALSTRINGTMP2) then
    return s;
  fi;
  res := _EVALSTRINGTMP2;
  Unbind(_EVALSTRINGTMP2);
  return res;
end;
Unbind(_EVALSTRINGTMP2);

# we put this prototype here so that handleString doesn't complain.
CreateJSONStringFromRecord:=function() end;

handleString:=function(s)
	local i,l,str;
	
	Print();
	
	# RECORDS
	if IsRecord(s) then
		return CreateJSONStringFromRecord(s);
	fi;
	
	# LISTS (but not strings)
	if (not IsString(s) or Size(s)=0) and IsList(s) then
		l:=[];
		for i in s do
			Add(l,EvalString(handleString(i)));
		od;
		return String(l);
	fi;
	
	# STRINGS
	if IsString(s) then
		return Concatenation("\"",String(s),"\"" );
	fi;
	
	# BOOLS AND INTS
	if IsBool(s) or IsInt(s) then
		return String(s);
	fi;
	
	# GROUPS
	if IsGroup(s) then
		return Concatenation("\"GAP://",String(s),"\"" );
	fi;
	return "";
end;


CreateJSONStringFromRecord:=function( input )
	local names,item, str,i,tmp;
	names:=RecNames(input);
	str:="{";
	for item in [1..Size(names)] do
		str:=Concatenation(str, "\"",names[item],"\"");
		str:=Concatenation(str, ":");
		
		str:=Concatenation(str,  handleString(input.(names[item])));

		if item < Size(names) then
			str:=Concatenation(str, ", ");
		fi;
	od;
	str:=Concatenation(str, "}");
	return str;
end;

ParseString:=function( i )
	#Print("Got: ",i,"\n");
	if Substring(i,1,5)="GAP://" then
		#Print("It starts with GAP://, so I'm going to parse it ",Substring(i,7,Size(i) ),"\n");
		return EvalString2(Substring(i,7,Size(i) ) );
	fi;
	#Print("It doesn't start with GAP://, so no parsing.");
	return i;
end;

ParseList:=function(l)
	local i,result,tmp,tmp2;
	result:=[];
	if IsString(l) then
		l:=EvalString2(l);
	fi;
	for i in l do
	
		# RECORDS (we've already parsed these by the time we get here.)
		if IsRecord(i) then
			Add(result, i);
			continue;
		fi;
		
		# LISTS (but not strings)
		if IsList(i) and not IsString(i) then
			tmp:=ParseList(i);
			Add(result, tmp);
			continue;
		fi;
		
		# STRINGS
		if IsString(i) then
			Add(result, ParseString(i));
			continue;
		fi;
		
		# BOOLS AND INTS
		if IsBool(i) or IsInt(i) then
			Add(result, i);
			continue;
		fi;
	od;
	return result;
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
				result.(recname):=ParseString(Substring(str, pos+1, q-pos-2));
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
			
			result.(recname):=ParseList(recvalue);
			#result.(recname):=EvalString(recvalue);
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
