requires 'perl', '5.036';
requires 'Moo';
requires 'Try::Tiny';
requires 'namespace::clean';
requires 'Scalar::Util';
requires 'Catalyst::Plugin::JSONRPC::Server';
requires 'Catalyst::Runtime', '5.90000';

on test => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Fatal';
    requires 'HTTP::Request::Common';
    requires 'JSON::MaybeXS';
};
