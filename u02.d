module metare;
import std.typecons;
import std.conv;
import std.string;
import std.stdio;

void main(string[] args)
{
	static const string RE="A*\\dB+\\sX?\\w\\x5A+\\s*[a-fq]";
	string arg=std.string.join(args[1..$], " ");
	alias re=compile!RE;
	
	writeln(arg,": ", re.match(arg));
}



template compile(string re)
{
//pragma(msg, "compiling "~re);
	static if(re.length) {
		static if(re[0] == '\\') {
			alias atom=compile_escape!re;
		} else static if(re[0] == '[') {
			alias atom=compile_class!(re[1..$]);
		} else {
			alias atom=compile_char!re;
		}
//pragma(msg, "  consumed "~to!string(atom.skip));


		alias re1=compile_quant!(atom, re[atom.skip..$]);
//pragma(msg, "  next "~re[re1.skip..$]);
		alias re2=join!(re1, compile!(re[re1.skip..$]));

		static const size_t skip=re2.skip;
		alias match=re2.match;

	} else {
		static const size_t skip=0;
		alias match=test_empty!(re);
	}
}


// not used
template recurse(alias term, string re)
{
	static if(re.length) {
		alias re0=compile!re;
		alias re1=join!(term, re0);
		static const size_t skip=re1.skip;
		alias match=re1.match;
	} else {
		static const size_t skip=0;
		alias match=test_empty!(re);
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
//pragma(msg, "compile char: "~re);
	static const size_t skip=1;
	alias match=test_char!re;
}


template compile_escape(string re)
{
//pragma(msg, "compile esc: "~re);
	static assert(re[0] == '\\', "test_escape(): invalid call");
	static assert(re.length > 1, "test_escape(): stray backslash");
	static if(re[1] == 'd') {
		static const size_t skip=2;
		alias match=test_digit!(re[1..$]);
	} else static if(re[1] == 's') {
		static const size_t skip=2;
		alias match=test_space!(re[1..$]);
	} else static if(re[1] == 'w') {
		static const size_t skip=2;
		alias match=test_word!(re[1..$]);
	} else static if(re[1] == 'x') {
		static const size_t skip=4;
		alias match=compile_hex!(re[2..$]).match;
	} else {
		static const size_t skip=2;
		alias match=test_char!(re[1..$]);
	}
}


XXX: NOT TERMINATED!!!!
template compile_class(string re)
{
pragma(msg, "character class: "~re);
	static assert(re.length && re[0] == '[', "invalid class expression");
	alias term=compile_range!(re);
	alias recurse=compile_class!(re[term.skip..$]);
	static const skip=1+term.skip+recurse.skip;
	alias match=either_of!(term, recurse);
}


template compile_range(string re)
{
	static assert(re.length, re~": character class is not terminated");
	static if(re.length && re[0] == ']') {
		static const skip=1;
		alias match=test_false!("");
	} else static if(re.length > 2 && re[1] == '-') {
		static const skip=3;
		alias match=test_range!(re[0..$],re[2..$]);
	} else {
		static const skip=1;
		alias match=test_range!(re[0..$],re[0..$]);
	}
}



template compile_quant(alias term, string re)
{
//pragma(msg, "compile quant: "~re~"  +"~to!string(term.skip));
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
		} else {
			static const size_t skip=term.skip;
			alias match=term.match;
		}
	} else {
		static const size_t skip=term.skip;
		alias match=term.match;
	}
//pragma(msg, "       quant: "~re~"  +"~to!string(term.skip));
}

template compile_hex(string re)
{
	static assert (re.length >= 2);
	alias match=test_char!(hexString!(re[0..2]));
}


template join(alias re1, alias re2)
{
	static const size_t skip=re1.skip+re2.skip;
	alias match=test_join!(re1,re2);
}


template either_of(alias re1, alias re2)
{
	static const size_t skip=re1.skip+re2.skip;
	alias match=test_either!(re1,re2);
}





Match test_char(string re)(string s)
{
	static if(re.length) {
		if(s.length && s[0] == re[0])
			return Match(1,1);
	}
	return Match(0,0);
}


Match test_digit(string re)(string s)
{
	return (s.length && s[0] >= '0' && s[0] <= '9')? Match(1,1) : Match(0,0);
}


Match test_space(string re)(string s)
{
	if(s.length) {
		if(
			   s[0] == ' '
			|| s[0] == '\t'
			|| s[0] == '\n'
			|| s[0] == '\r'
			|| s[0] == '\f'
		) return Match(1,1);
	}
	return Match(0,0);
}


Match test_word(string re)(string s)
{
	if(s.length) {
		if(
			   (s[0] >= 'A' && s[0] <= 'Z')
			|| (s[0] >= 'a' && s[0] <= 'z')
			|| s[0] == '_'
		) return Match(1,1);
	}
	return Match(0,0);
}


Match test_range(string re1, string re2)(string s)
{
writeln("test range: [", re1[0],"-", re2[0],"] <=> ", s[0]);
	if(s.length) {
		if(s[0] >= re1[0] && s[0] <= re2[0]) {
writeln("     range matched");
			return Match(1,1);
		}
	}
	return Match(0,0);
}


Match test_empty(string re)(string s)
{
	static assert(re.length == 0, "test_empty(): invalid call");
	return Match(1,0);
}

Match test_true(string re)(string s)
{
	return Match(1,0);
}

Match test_false(string re)(string s)
{
	return Match(0,0);
}


Match test_join(alias re1, alias re2)(string s) {
	auto m1=re1.match(s);
	if(m1) {
		auto m2=re2.match(s[m1.length..$]);
		return Match(m1 && m2, m1.length+m2.length);
	}
	return m1;
}


Match test_either(alias re1, alias re2)(string s) {
	auto m1=re1.match(s);
	return m1? m1 : re2.match(s);
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





