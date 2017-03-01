import std.stdio;
import regex;

void main()
{
    auto exp = &regexMatch!("[a-z]*\\s*\\w*");
    writefln("matches: %s", exp("hello    world"));
}
