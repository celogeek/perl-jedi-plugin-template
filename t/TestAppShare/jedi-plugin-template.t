#!perl
use Test::Most 'die';
use HTTP::Request::Common;
use Plack::Test;
use Jedi;
use IO::Uncompress::Gunzip qw/gunzip/;
use Path::Class;

my $jedi = Jedi->new();
$jedi->road('/', 't::TestApp::App');

test_psgi $jedi->start, sub {
	my $cb = shift;
	{
		my $res = $cb->(GET '/');
		is $res->code, 200, 'index ok';
		is $res->content, 'index', '... content also';
	}
	{
		my $res = $cb->(GET '/test');
		is $res->code, 200, 'all others ok';
		is $res->content, 'allothers', '... content also';
	}
	{
		my $res = $cb->(GET '/test.js');
		is $res->code, 200, 'public file ok';
		is $res->content, "{ 'test' : 'works !' }", 'public content ok';
		like $res->header('Content-Type'), qr{application/javascript}, 'content type is correct';
	}
	{
		my $res = $cb->(GET '/test.js', 'ACCEPT_ENCODING' => 'gzip');
		is $res->code, 200, 'public file ok';
		my $content = "";
		my $pack_content = $res->content;
		gunzip \$pack_content => \$content;
		is $content, "{ 'test' : 'works !' }", 'public content ok';
		like $res->header('Content-Type'), qr{application/javascript}, 'content type is correct';
	}
	{
		my $res = $cb->(GET '/sub/test.css');
		is $res->code, 200, 'public file ok';
		is $res->content, ".a { color : red ;}", 'public content ok';
		like $res->header('Content-Type'), qr{text/css}, 'content type is correct';
	}
};

done_testing;
