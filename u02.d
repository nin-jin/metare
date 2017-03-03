module metare;
import std.typecons;
import std.conv;
import std.string;
import std.stdio;

void main(string[] args)
{
//CALL u02 AAA3BB YZ abc 1,2,14 ...
	static const string RE="A*\\dB+\\sX?\\w\\x5A+\\s*[a-fq]+\\s*(\\d,)+.*";
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
			alias atom=compile_class!re;
		} else static if(re[0] == '(') {
			alias atom=compile_atom!re;
		} else static if(re[0] == '.') {
			alias atom=compile_anychar!re;
		} else {
			alias atom=compile_char!re;
		}


		alias re1=compile_quant!(atom, re[atom.skip..$]);
		alias re2=join!(re1, compile!(re[re1.skip..$]));

		static const size_t skip=re2.skip;
		alias match=re2.match;

	} else {
		static const size_t skip=0;
		alias match=test_empty!(re);
	}
}


// not used
//template recurse(alias term, string re)
//{
//	static if(re.length) {
//		alias re0=compile!re;
//		alias re1=join!(term, re0);
//		static const size_t skip=re1.skip;
//		alias match=re1.match;
//	} else {
//		static const size_t skip=0;
//		alias match=test_empty!(re);
//	}
//}


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
	static assert(re[0] == '\\', "escaped: invalid call");
	static assert(re.length > 1, "escaped: stray backslash");
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


template extract_until(string s, char terminator)
{
	static assert(s.length, "missing terminator");
	static if(s[0] == terminator) {
		static const length=0;
	} else {
		static const length=1+extract_until!(s[1..$], terminator).length;
	}
}


template compile_class(string re)
{
//pragma(msg, "character class: "~re);
	static const skip=2+extract_until!(re[1..$], ']').length;
	alias match=compile_range!(re[1..skip-1]).match;
}


template compile_atom(string re)
{
//pragma(msg, "atom: "~re);
	static const skip=2+extract_until!(re[1..$], ')').length;
	alias match=compile!(re[1..skip-1]).match;
}


template compile_range(string re)
{
	static if(re.length  == 0) {
		static const skip=0;
		alias match=test_false!(0);
	} else static if(re.length > 2 && re[1] == '-') {
		static const skip=3;
		alias match=either_of!(
			  test_range!(re[0],re[2])
			, compile_range!(re[skip..$])
			).match;
	} else {
		static const skip=1;
		alias match=either_of!(
			  test_range!(re[0],re[0])
			, compile_range!(re[skip..$])
			).match;
	}
}

template compile_anychar(string re)
{
	static const skip=1;
	alias match=test_any!1;
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
	//static const size_t skip=re1.skip+re2.skip;
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


Match test_range(char left, char right)(string s)
{
	if(s.length) {
		if(s[0] >= left && s[0] <= right)
			return Match(1,1);
	}
	return Match(0,0);
}


Match test_empty(string re)(string s)
{
	static assert(re.length == 0, "test_empty(): invalid call");
	return Match(1,0);
}

Match test_true(int length)(string s)
{
	return Match(1,length);
}

Match test_any(int length)(string s)
{
	return (s.length >= length)? Match(1,length) : Match(0, s.length);
}

Match test_false(int length)(string s)
{
	return Match(0,length);
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
	auto m1=re1(s);
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





