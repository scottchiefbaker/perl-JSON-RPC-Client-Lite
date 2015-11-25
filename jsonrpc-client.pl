#!/usr/bin/perl

use JSON::RPC::Client::Lite;
use Getopt::Long;
use strict;
use warnings;

#use File::Basename;
#require(dirname($0) . "/JSON::RPC::Client::Lite.pm");

# Default URL
my $api_url = "http://www.perturb.org/api/json-rpc/";

###################################################################

my ($method);
my $params = "";
my $debug  = 0;

my $ok = GetOptions(
	"debug+"   => \$debug,
	"url=s"    => \$api_url,
	"method=s" => \$method,
	"params=s" => \$params,
);

# Raw called like echo_data(2,4,8)
if (!$method) {
	if ($ARGV[0] && $ARGV[0] =~ /([\w.]+)\((.*?)\)/) {
		$method = $1;
		$params = $2;
	}
}

if (!$method || !$api_url) {
	die(usage());
}

my $s = new JSON::RPC::Client::Lite($api_url,{debug => $debug});
my @params = split(",",$params);

if (!@params) {
	@params = undef;
}

###################################################################

# Raw call method
my $i = $s->_call($method,@params);

# Statically code the method name in your code (most readable), uses AUTOLOAD magic
# Note: requires params to be set to SOMETHING (even undef) for AUTOLOAD magic to work
#my $i = $s->peak->echo_data(@params);

if (!defined($i)) {
	my $status = $s->{response}->{status};
	print "*** Error decoding JSON ***\nHTTP Code: $status - Response:\n";
	print $s->{response}->{content} . "\n";

	exit(2);
}

out($i);

###################################################################

sub usage {
	return "$0 --method echo_data [--params \"2,4,6,eight\"] [--url http://domain.com/path/] [--debug]\n";
}

# Use Data::Dump::Color if available, else Data::Dumper
BEGIN {
    if(eval "require Data::Dump::Color; 1") {
		*out = \&Data::Dump::Color::dd;
    } else {
        require Data::Dumper;
		*out = sub {
			print Data::Dumper::Dumper(@_) . "\n"
		};
    }
}
