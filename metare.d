module metare;
import std.conv;
import std.string;
import std.stdio;


unittest
{
	alias NUMBER=compile!"\\d+";
	assert(NUMBER.match("1234") == Match(true, 4));


}




template compile(string re)
{
//pragma(msg, "compiling "~re);
	static if(re.length) {
		// parse escaped sequences
		static if(re[0] == '\\') {
			alias atom=compile_escape!re;

		// parse character class
		} else static if(re[0] == '[') {
			alias atom=compile_class!re;

		// parse atom
		} else static if(re[0] == '(') {
			alias atom=compile_atom!re;

		// parse dot
		} else static if(re[0] == '.') {
			alias atom=compile_anychar!re;

		// parse regular literals
		} else {
			alias atom=compile_char!re;
		}

		// pase predicate (if any) *+?
		alias quant=compile_quant!(atom, re[atom.skip..$]);
		alias result=both_of!(quant, compile!(re[quant.skip..$]));

		static const size_t skip=result.skip;
		alias match=result.match;

	} else {
		static const size_t skip=0;
		// end of regular expression
		alias match=test_empty!(re);
	}
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
	// any other sequence is converted to the character itself
		static const size_t skip=2;
		alias match=test_char!(re[1..$]);
	}
}


// misc., return length of literal up the to terminator
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
//pragma(msg, "char.class: "~re);
	static const skip=2+extract_until!(re[1..$], ']').length;
	alias match=compile_range!(re[1..skip-1]).match;
}


template compile_atom(string re)
{
//pragma(msg, "atom: "~re);
	static const skip=2+extract_until!(re[1..$], ')').length;
	alias match=compile!(re[1..skip-1]).match;
}


// parse literal 'a-zA0-5' to union of range tests a-z || A-A || 0-5
template compile_range(string re)
{
	static if(re.length  == 0) {
		// end of match, return Match(false,0)
		static const skip=0;
		alias match=test_false!(0);
	} else static if(re.length > 2 && re[1] == '-') {
		// true range
		static const skip=3;
		alias match=either_of!(
			  test_range!(re[0],re[2])
			, compile_range!(re[skip..$])
			).match;
	} else {
		// degenerated range: 'X-X'
		static const skip=1;
		alias match=either_of!(
			  test_range!(re[0],re[0])
			, compile_range!(re[skip..$])
			).match;
	}
}

// match any character (dot)
template compile_anychar(string re)
{
	static const skip=1;
	alias match=test_any!1;
}



// modify previous (term) regex with one of *+? predicates, or none
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
			// no predicate, return term
			static const size_t skip=term.skip;
			alias match=term.match;
		}
	} else {
		// no predicate, end of regex, also return term
		static const size_t skip=term.skip;
		alias match=term.match;
	}
}



// convert \xNN hex expression to character and match it
template compile_hex(string re)
{
	static assert (re.length >= 2);
	alias match=test_char!(hexString!(re[0..2]));
}


// match both expressions
template both_of(alias re1, alias re2)
{
	static const size_t skip=re1.skip+re2.skip;
	alias match=test_join!(re1,re2);
}


// match either of expressions
template either_of(alias re1, alias re2)
{
	alias match=test_either!(re1,re2);
}


/***********************************************************************/
/** runtime calls ******************************************************/

// result of match: success and mathed length
// in case the success == false, the length is matched portion (points to first unmatched char)
struct Match
{
	bool _success;
	ulong length;

	bool opCast(T : bool)() const { return _success; }
}





// match single character
Match test_char(string re)(string s)
{
	static if(re.length) {
		if(s.length && s[0] == re[0])
			return Match(1,1);
	}
	return Match(0,0);
}


// match single digit
Match test_digit(string re)(string s)
{
	return (s.length && s[0] >= '0' && s[0] <= '9')? Match(1,1) : Match(0,0);
}


// match any of space 
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


// match any of word characters 
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


// match range 
Match test_range(char left, char right)(string s)
{
	if(s.length) {
		if(s[0] >= left && s[0] <= right)
			return Match(1,1);
	}
	return Match(0,0);
}


// match at the end of regex
Match test_empty(string re)(string s)
{
	static assert(re.length == 0, "test_empty(): invalid call");
	return Match(1,0);
}

// always match, return requested chars to skip
Match test_true(int length)(string s)
{
	return Match(1,length);
}

// never match, return requested chars to skip
Match test_false(int length)(string s)
{
	return Match(0,length);
}

// always match if sufficient input length, return available chars
Match test_any(int length)(string s)
{
	return (s.length >= length)? Match(1,length) : Match(0, s.length);
}

// match both of expressions, return matched length
Match test_join(alias re1, alias re2)(string s) {
	auto m1=re1.match(s);
	if(m1) {
		auto m2=re2.match(s[m1.length..$]);
		return Match(m1 && m2, m1.length+m2.length);
	}
	return m1;
}


// match either of expressions, mathed length is not specified
Match test_either(alias re1, alias re2)(string s) {
	auto m1=re1(s);
	return m1? m1 : re2.match(s);
}


// match any number of repetition of the expression
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

// conditionally match the expression, always match but matched length is different
Match zero_or_one(alias term)(string s)
{
	Match r=term.match(s);
	if(r) return r;

	return Match(1,0);
}

// match at least one repetition of the expression
Match one_or_more(alias term)(string s)
{
	Match r=term.match(s);
	if(!r) return r;

	Match n=term.match(s[r.length..$]);
	while(n) {
		r.length+=n.length;
		n=term.match(s[r.length..$]);
	}
	return r;
}





