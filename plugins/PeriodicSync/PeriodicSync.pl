package MT::Plugin::PeriodicSync;
use strict;
use warnings;
use utf8;

use base qw( MT::Plugin );

my $plugin = __PACKAGE__->new(
    {   name    => 'PeriodicSync',
        id      => 'PeriodicSync',
        version => 0.07,

        author_name => 'Six Apart Ltd.',
        author_link => 'https://www.sixapart.jp',
        plugin_link => 'https://github.com/movabletype/mt-plugin-periodic-sync',
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
            list_properties => { sync_setting => \&_list_props, },

            applications => {
                cms => {
                    callbacks => {
                        'template_source.cfg_contents_sync' =>
                            '$PeriodicSync::PeriodicSync::CMS::add_form',
                        'template_param.cfg_contents_sync' =>
                            '$PeriodicSync::PeriodicSync::CMS::load_param',
                        'cms_pre_save.sync_setting' =>
                            '$PeriodicSync::PeriodicSync::CMS::check_param',
                        'cms_post_save.sync_setting' =>
                            '$PeriodicSync::PeriodicSync::CMS::save_param',
                    },
                },
            },
        },
    }
);
MT->add_plugin($plugin);

sub _list_props {
    return +{
        sync_period => {
            label     => '定期配信間隔',
            order     => 300,
            display   => 'default',
            bulk_html => sub {
                my $prop = shift;
                my ($objs) = @_;

                my $blog_id = MT->app->blog ? MT->app->blog->id : 0;
                my $scope   = "blog:$blog_id";

                my @periods;
                for my $obj (@$objs) {
                    my $sync_period_status
                        = $plugin->get_config_value( 'sync_period_status',
                        $scope, $obj->id );
                    my $sync_period
                        = $plugin->get_config_value( 'sync_period', $scope,
                        $obj->id );

                    push @periods,
                        (
                        $sync_period_status
                        ? "$sync_period 時間"
                        : '(定期配信しない)'
                        );
                }

                return @periods;
            },
        },
    };
}

sub get_config_value {
    my $this = shift;
    my ( $var, $scope, $setting_id ) = @_;

    my $hash = $this->SUPER::get_config_value( $var, $scope );

    if ( !$this->_multiple_sync ) {
        return $hash;
    }

    if ( ref $hash ne 'HASH' ) {
        $this->_initialize_setting($scope);
        $hash = $this->SUPER::get_config_value( $var, $scope );
    }

    if ( $setting_id && exists $hash->{$setting_id} ) {
        return $hash->{$setting_id};
    }
    else {
        return $this->_defaults->{$var};
    }
}

sub get_config_value_from_job {
    my ( $this, $var, $job ) = @_;

    my ( $scope, $setting_id );
    if ( $this->_multiple_sync ) {
        my $sync_setting = $this->get_sync_setting($job);
        $scope      = 'blog:' . $sync_setting->blog_id;
        $setting_id = $sync_setting->id;
    }
    else {
        $scope = 'blog:' . $job->uniqkey;
    }

    return $this->get_config_value( $var, $scope, $setting_id );
}

sub set_config_value {
    my $this = shift;
    my ( $var, $val, $scope, $setting_id ) = @_;

    if ( !$this->_multiple_sync ) {
        return $this->SUPER::set_config_value(@_);
    }

    my $hash = $this->SUPER::get_config_value( $var, $scope );

    if ( ref $hash ne 'HASH' ) {
        $this->_initialize_setting($scope);
        $hash = $this->SUPER::get_config_value( $var, $scope );
    }

    $hash->{$setting_id} = $val;
    $this->SUPER::set_config_value( $var, $hash, $scope );
}

sub get_sync_setting {
    my ( $this, $job ) = @_;

    require MT::SyncSetting;

    if ( $this->_multiple_sync ) {
        return MT::SyncSetting->load( $job->uniqkey );
    }
    else {
        return MT::SyncSetting->load( { blog_id => $job->uniqkey } );
    }
}

sub _multiple_sync {
    my $sync = MT->component('Sync');
    return ( $sync && $sync->version >= 1.012 ) ? 1 : 0;
}

sub _defaults {
    my $this = shift;
    return $this->settings->defaults;
}

sub _initialize_setting {
    my ( $this, $scope ) = @_;
    my ($blog_id) = $scope =~ m/(\d+)$/;

    my $old_sync_period_status
        = $this->SUPER::get_config_value( 'sync_period_status', $scope );
    my $old_sync_period
        = $this->SUPER::get_config_value( 'sync_period', $scope );

    require MT::SyncSetting;
    my @settings    = MT::SyncSetting->load( { blog_id => $blog_id } );
    my @setting_ids = map { $_->id } @settings;

    my %sync_period_status_hash
        = map { $_ => $old_sync_period_status } @setting_ids;
    my %sync_period_hash = map { $_ => $old_sync_period } @setting_ids;

    $this->SUPER::set_config_value( 'sync_period_status',
        \%sync_period_status_hash, $scope );
    $this->SUPER::set_config_value( 'sync_period', \%sync_period_hash,
        $scope );
}

1;
