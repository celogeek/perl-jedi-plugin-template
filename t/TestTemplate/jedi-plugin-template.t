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
};

done_testing;