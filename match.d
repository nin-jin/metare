import std.regex;
import std.stdio;


void main(string[] arg)
{
	auto rx=regex1(arg[1], "g");

	foreach(line; stdin.byLine) {
		foreach(match; matchAll(line, rx))
			write(" ", match);
		writeln();
	}
}

