package JSON::RPC::Client::Lite;
use vars '$AUTOLOAD';
use HTTP::Tiny;
use JSON::PP;

sub new {
	my $class = shift();
	my $url   = shift();
	my $opts  = shift();

	my $attrs = {
		'agent'   => 'JSONRPC::Client::Lite',
		'timeout' => 3,
	};

	my $self  = {
		"version"     => 0.1,
		"api_url"     => $url,
		"opts"        => $opts,
		"http"        => HTTP::Tiny->new(%$attrs),
		"breadcrumbs" => [],
	};

	bless $self, $class;

    return $self;
}

sub _call {
	my ($self,$method,@params) = @_;

	my $url   = $self->{api_url};
	my $json  = $self->create_request($method,@params);
	my $debug = $self->{opts}->{debug};

	if ($debug) {
		print "RPC URL  : $url\n";
		print "Sending  : " . $json . "\n";
	}

	my $opts = {
		content => $json,
		headers => { 'Content-Type' => 'application/json;charset=UTF-8' },
	};

	my $resp      = $self->{http}->post($url,$opts);
	my $status    = $resp->{status};
	my $json_resp = $resp->{content};

	$self->{response} = $resp;

	if ($debug) {
		print "Received : " . $json_resp . "\n\n";
	}

	if ($status != 200) {
		return undef;
	}

	my $ret = {};
	eval {
		$ret = decode_json($json_resp);

		if ($ret->{result}) {
			$ret = $ret->{result};
		}
	};

	# There was an error with decoding the JSON
	if ($@) {
		print $@;
		return undef;
	}

	return $ret;
}

sub create_request {
	my ($self,$method,@params) = @_;

	my $hash = {
		"method"  => $method,
		"version" => 1.1,
		"id"      => 1,
		"params"  => \@params,
	};

	my $json = encode_json($hash);

	return $json;
}

sub AUTOLOAD {
	my $self   = shift;
	my $func   = $AUTOLOAD;
	my @params = @_;

	# Remove the class name, we just want the function that was called
	my $str = __PACKAGE__ . "::";
	$func =~ s/$str//;

	push(@{$self->{breadcrumbs}},$func);

	# If there are params it's the final function call
	if (@params) {
		my $method = join(".",@{$self->{breadcrumbs}});
		my $ret = $self->_call($method,@params);

		return $ret;
	}

	return $self;
}

sub curl_call {
	my ($self,$method,@params) = @_;

	my $json = $self->create_request($method,@params);
	my $url  = $self->{api_url};

	#curl -d '{"id":"json","method":"add","params":{"a":2,"b":3} }' -o - http://domain.com
	my $curl = "curl -d '$json' -o - $url";

	return $curl;
}

1;
