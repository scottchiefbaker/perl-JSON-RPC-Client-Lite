(
	cat jsonrpc-client.pl; 
	echo; 
	echo "###################################"; 
	cat JSON/RPC/Client/Lite.pm
) | grep 'use JSON::RPC::Client::Lite;' -v
