package MT::Plugin::PeriodicSync;
use strict;
use warnings;
use utf8;

use base qw( MT::Plugin );

my $plugin = __PACKAGE__->new(
    {   name    => 'PeriodicSync',
        id      => 'PeriodicSync',
        version => 0.03,

        author_name => 'Masahiro Iuchi',
        author_link => 'https://github.com/masiuchi',
        plugin_link => 'https://github.com/masiuchi/mt-plugin-periodic-sync',
        description =>
            '<__trans phrase="Add periodic sync option to contents sync function.">',

        settings => {
            sync_period_status => {
                Default => undef,
                Scope   => 'blog',
            },
            sync_period => {
                Default => 24,
                Scope   => 'blog',
            },
        },

        init_app => '$PeriodicSync::PeriodicSync::override',

        registry => {
            applications => {
                cms => {
                    callbacks => {
                        'template_source.cfg_contents_sync' =>
                            '$PeriodicSync::PeriodicSync::CMS::add_form',
                        'template_param.cfg_contents_sync' =>
                            '$PeriodicSync::PeriodicSync::CMS::load_param',
                        'cms_pre_save.sync_setting' =>
                            '$PeriodicSync::PeriodicSync::CMS::save_param',
                    },
                },
            },
        },
    }
);
MT->add_plugin($plugin);

1;
