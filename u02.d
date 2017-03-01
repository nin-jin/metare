module metare;
import std.typecons;
import std.stdio;

void main(string[] arg)
{
	//static const string RE="ABC";
	static const string RE="A*";
	alias re1=compile_char!RE;
	//alias re2=compile_char!(RE[re1.skip..$]);
	//alias re=join!(re1,re2);
	alias re=compile_quant!(re1, RE[re1.skip..$]);
	
	foreach(s; arg[1..$])
		writeln(s,": ", re.match(s));
}



template Compile(string re)
{
	auto Compile(string s) {
		return join(compile_char!re, Compile!(re[]));
	}
}




struct Match
{
	bool _success;
	ulong _length;

	bool opCast(T : bool)() const { return _success; }
	@property auto length() const { return _length; }
}












template compile_char(string re)
{
	static const size_t skip=1;
	alias match=test_char!re;
}


template compile_quant(alias term, string re)
{
	static if(re.length) {
		static if(re[0] == '*') {
			static const size_t skip=term.skip+1;
			alias match=zero_or_more!term;
		} else static if(re[0] == '+') {
			static const size_t skip=term.skip+1;
			alias match=one_or_more!term;
		} else static if(re[0] == '?') {
			static const size_t skip=term.skip+1;
			alias match=zero_or_one!term;
		}

	} else {
		static const size_t skip=term.skip;
		alias match=term.match;
	}
}



template join(alias re1, alias re2)
{
	static size_t skip=re1.skip+re2.skip;
	Match join(string s) {
		auto m1=re1.match(s);
		if(m1) {
			auto m2=re2.match(s[m1.length..$]);
			return Match(m1 && m2, m1.length+m2.length);
		}
		return Match(0, 0);
	}
}





Match test_char(string re)(string s)
{
	static if(re.length) {
		if(s.length && s[0] == re[0])
			return Match(1,1);
	}
	return Match(0,0);
}


Match zero_or_more(alias term)(string s)
{
	auto r=Match(1,0);
	Match n=term.match(s);
	while(n) {
		r._length+=n.length;
		n=term.match(s[r.length..$]);
	}
	return r;
}

Match zero_or_one(alias term)(string s)
{
	Match r=term.match(s);
	if(r) return r;

	return Match(1,0);
}

Match one_or_more(alias term)(string s)
{
	Match r=term.match(s);
	if(!r) return r;

	Match n=term.match(s[r.length..$]);
	while(n) {
		r._length+=n.length;
		n=term.match(s[r.length..$]);
	}
	return r;
}





