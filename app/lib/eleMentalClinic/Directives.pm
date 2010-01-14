=head1 eleMentalClinic::Directives

mod_perl 2.x Directive configuration

=cut

package eleMentalClinic::Directives;

use strict;
use warnings;

use Apache2::CmdParms ();
use Apache2::Module ();
use Apache2::Directive ();
use Apache2::Const qw(OR_ALL EXEC_ON_READ TAKE3 OK);

Apache2::Module::add(__PACKAGE__, directives());

sub directives {
    [ 
        {
            name         => 'eMCVHost',
            func         => __PACKAGE__."::eMCVHost",
            req_override => Apache2::Const::OR_ALL,
            args_how     => Apache2::Const::TAKE3,
            errmsg       => 'eMCVHost ip:port host config_file',
        },
    ];
}

#
# This is just a macro for now, I intend to expand it as our needs change.
#
sub eMCVHost {
    my ($self, $parms, $ip_port, $hostname, $config_file) = @_;

    my $config = <<"EOF";   
<VirtualHost $ip_port>
    <Location />
        DirectoryIndex index.cgi 
        PerlSetVar config_path $config_file
        SetHandler modperl
        PerlHandler eleMentalClinic::Dispatch
    </Location>
    ErrorLog $hostname/error.log
    LogLevel warn
    CustomLog $hostname/access.log combined
</VirtualHost>
EOF

    $parms->add_config([split(/\n/, $config)]);
}

'eleMental'
