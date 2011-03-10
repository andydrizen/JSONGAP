################################################################################
# JSONGAP/lib/JSON.g                                            Andy L. Drizen
#                                                                   26/02/2011
# File overview:
# 
# This is a basic JSON interpreter. Remember GAP hates floating point
# numbers, any JSON object containing a float will make the parser fail - 
# to avoid this issue, turn your floats in to string.
#
################################################################################

# we put this prototype here so that ParseStringRecordtoJSON doesn't complain.
CreateJSONStringFromRecord:=function() end;

ParseStringRecordtoJSON:=function(s)
	local i,l,str;
	
	# RECORDS
	if IsRecord(s) then
		return CreateJSONStringFromRecord(s);
	fi;
	
	# LISTS (but not strings)
	if IsList(s) and not IsString(s) or (IsString(s) and Size(s)=0 and not ViewString(s)="") then
		l:=[];
		for i in s do
			Add(l,EvalString(ParseStringRecordtoJSON(i)));
		od;
		return String(l);
	fi;
	
	# STRINGS
	if IsString(s) then
		s:=str_replace(['\"'], ['\\','\"'],s);
		return Concatenation("\"",String(s),"\"");
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

ParseStringJSONtoRecord:=function( i )
	i:=str_replace(['\\','\"'],['\"'],i);
	if substr(i,1,6)="GAP://" then
		return EvalString(substr(i,7,Size(i)+1 ) );
	fi;
	return i;
end;

ParseListJSONtoRecord:=function(l)
	local i,result,tmp,tmp2;
	result:=[];
	if IsString(l) then
		l:=EvalString(l);
	fi;
	for i in l do
	
		# RECORDS (we've already parsed these by the time we get here.)
		if IsRecord(i) then
			Add(result, i);
			continue;
		fi;
		
		# LISTS (but not strings)
		if IsList(i) and not(IsString(i) or ViewString(i)="") then
			tmp:=ParseListJSONtoRecord(i);
			Add(result, tmp);
			continue;
		fi;
		
		# STRINGS
		if IsString(i) then
			Add(result, ParseStringJSONtoRecord(i));
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

CreateJSONStringFromRecord:=function( input )
	local names,item, str,i,tmp;
	names:=RecNames(input);
	str:="{";
	for item in [1..Size(names)] do
		str:=Concatenation(str, "\"",names[item],"\"");
		str:=Concatenation(str, ":");
		str:=Concatenation(str,  ParseStringRecordtoJSON(input.(names[item])));
		if item < Size(names) then
			str:=Concatenation(str, ", ");
		fi;
	od;
	str:=Concatenation(str, "}");
	return str;
end;

CreateRecordFromJSONString:=function( str )
	local s,result,pos,recname,recvalue,q,k,tmp_rec,m,flag;
	pos:=2;
	result:=rec();
	recname:="";
	str:=ReplacedString(str, "\n", "");
	str:=ReplacedString(str, "\t", "");
	s:=Size(str);
	while pos < s do
		if str[pos] = '\"' then
			flag:=false;
			q:=strpos(str, ['\"'], pos);
			while flag = false do
				if not [str[q-1]]=['\\'] then
					flag:=true;
				else
					q:=strpos(str, ['\"'], q);
				fi;
			od;
			if recname = "" then
				recname:=substr(str, pos+1, q-pos-1);
			else
				result.(recname):=ParseStringJSONtoRecord(substr(str, pos+1, q-pos-1));
				recname:="";
			fi;
			pos:=q+1;
			continue;
		fi;
		if str[pos] = ':' then
		
			if strpos(str, ",", pos) > -1 then
				# this ISN'T the last element
				k:=strpos(str, ",", pos+1);
			else
				# this IS the last element
				k:=strpos(str, "}", pos+1);
			fi;
		
			if 	(strpos(str, "[", pos) = -1 or
				strpos(str, "[", pos) > k) and
				(strpos(str, "{", pos) = -1 or
				strpos(str, "{", pos) > k) and
				(strpos(str, "\"", pos) = -1 or
				strpos(str, "\"", pos) > k)
				then
				
				# in this situation, we've just seen a colon and we're not defining an array, string 
				# or dictionary so we put everything between here and the next comma (excluding 
				# whitespace) in to the rec under the tmp_str name.
				
				q:=k;
				recvalue:=substr(str, pos+1, q-pos-1);
				NormalizeWhitespace(recvalue);
				result.(recname):=EvalString(recvalue);
				recname:="";
				pos:=q+1;
				continue;
			fi;
		fi;
		if str[pos] = '[' then
			q:=FindMatchingBracket(substr(str, pos, s+1), '[', ']');
			recvalue:=substr(str, pos, q);
			
			# now parse this list for records.
			k:=strpos(recvalue, "{", 0);
			
			while k >- 1 do
				m:=FindMatchingBracket(substr(recvalue, k, Size(recvalue)+1), '{', '}');
				tmp_rec:=CreateRecordFromJSONString(substr(recvalue, k, m+1 ));
				recvalue:=Concatenation(substr(recvalue, 1, k-1), String(tmp_rec), substr(recvalue, m+k, Size(recvalue)+1)) ;
				k:=strpos(recvalue, "{", 0);
			od;
			
			result.(recname):=ParseListJSONtoRecord(recvalue);

			recname:="";
			pos:=pos+q;
			continue;
		fi;
		if str[pos] = '{' then
			q:=FindMatchingBracket(substr(str, pos, s+1), '{', '}');
			recvalue:=CreateRecordFromJSONString(substr(str, pos, q));
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
