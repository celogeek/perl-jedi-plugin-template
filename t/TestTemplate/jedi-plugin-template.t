#!perl
use Test::Most 'die';
use HTTP::Request::Common;
use Plack::Test;
use Jedi;

my $jedi = Jedi->new();
$jedi->road('/', 't::TestTemplate::App');

test_psgi $jedi->start, sub {
	my $cb = shift;
	{
		my $res = $cb->(GET '/');
		is $res->code, 200, 'index ok';
		is $res->content, 'OK', '... content also';
	}
	{
		my $res = $cb->(GET '/?layout=test.tt');
		is $res->code, 200, 'index ok';
		is $res->content, 'OK', '... content also';
	}
	{
		my $res = $cb->(GET '/?layout=main.tt');
		is $res->code, 200, 'index ok';
		is $res->content, 'AROUND:OK:DNUORA', '... content also';
	}
	{
		my $res = $cb->(GET '/mainlayout');
		is $res->code, 200, 'index ok';
		is $res->content, 'AROUND:OK:DNUORA', '... content also';
	}	
	{
		my $res = $cb->(GET '/');
		is $res->code, 200, 'index ok';
		is $res->content, 'AROUND:OK:DNUORA', '... content also';
	}
	{
		my $res = $cb->(GET '/error');
		is $res->code, 500, 'error to get the template';
		like $res->content, qr{file\serror.*error.tt:\snot\sfound}x, '... content also';
	}

};

done_testing;