package Catalyst::Plugin::MCP::Server;
use v5.36;
use Moo;
use Scalar::Util qw/blessed/;
use namespace::clean;

our $VERSION = '0.001';

has protocol_versions => (
    is      => 'ro',
    default => sub { ['2025-06-18'] },
);

has server_info => (
    is      => 'ro',
    default => sub { { name => 'mcp-server', version => '0.001' } },
);

has _providers => ( is => 'ro', default => sub { {} } );

my %ROLE_FOR_KIND = (
    resources => 'Catalyst::Plugin::MCP::Role::ResourceProvider',
    prompts   => 'Catalyst::Plugin::MCP::Role::PromptProvider',
    tools     => 'Catalyst::Plugin::MCP::Role::ToolProvider',
);

sub register_provider ( $self, $obj ) {
    die "MCP provider must be a blessed object\n" unless blessed $obj;
    my $matched = 0;
    for my $kind ( sort keys %ROLE_FOR_KIND ) {
        next unless $obj->DOES( $ROLE_FOR_KIND{$kind} );
        $self->_providers->{$kind} = $obj;
        $matched++;
    }
    die "MCP provider consumes none of the provider roles\n" unless $matched;
    return $self;
}

sub capabilities ( $self ) {
    my %caps;
    $caps{$_} = {} for keys %{ $self->_providers };
    return \%caps;
}

sub _negotiate_version ( $self, $requested ) {
    my @supported = @{ $self->protocol_versions };
    if ( defined $requested ) {
        return $requested if grep { $_ eq $requested } @supported;
    }
    return $supported[0];
}

sub _initialize ( $self, $params ) {
    my $requested = ref $params eq 'HASH' ? $params->{protocolVersion} : undef;
    return {
        protocolVersion => $self->_negotiate_version($requested),
        capabilities    => $self->capabilities,
        serverInfo      => $self->server_info,
    };
}

sub handlers ( $self ) {
    my %h = (
        'initialize'                => sub ($params) { $self->_initialize($params) },
        'ping'                      => sub ($params) { return {} },
        'notifications/initialized' => sub ($params) { return undef },
    );

    if ( $self->_providers->{resources} ) {
        $h{'resources/list'} =
            sub ($params) { $self->_resources_list($params) };
        $h{'resources/templates/list'} =
            sub ($params) { $self->_resources_templates($params) };
        $h{'resources/read'} =
            sub ($params) { $self->_resources_read($params) };
    }
    if ( $self->_providers->{prompts} ) {
        $h{'prompts/list'} = sub ($params) { $self->_prompts_list($params) };
        $h{'prompts/get'}  = sub ($params) { $self->_prompts_get($params) };
    }
    if ( $self->_providers->{tools} ) {
        $h{'tools/list'} = sub ($params) { $self->_tools_list($params) };
        $h{'tools/call'} = sub ($params) { $self->_tools_call($params) };
    }

    return \%h;
}

1;
