module metare;
import std.typecons;
import std.stdio;

alias Match=Tuple!(bool, "good", size_t, "length");



template Compile(string pattern)
{
	auto Compile(string s) {
		return join(compile_char!pattern, Compile!(pattern[]));
	}
}










template compile_char(string pattern)
{
	static const size_t skip=1;
	alias match=test_char!pattern;
}

template join(alias re1, alias re2)
{
	static size_t skip=re1.skip+re2.skip;
	Match join(string s) {
		auto m1=re1.match(s);
		if(m1.good) {
			auto m2=re2.match(s[m1.length..$]);
			return Match(m1.good && m2.good, m1.length+m2.length);
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




void main(string[] arg)
{
	static const string ABC="ABC";
	alias re1=compile_char!ABC;
	alias re2=compile_char!(ABC[re1.skip..$]);
	
	foreach(s; arg[1..$])
		writeln(s,": ", join!(re1,re2)(s));
}







