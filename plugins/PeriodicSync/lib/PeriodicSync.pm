package PeriodicSync;
use strict;
use warnings;
use utf8;

use MT::Util qw( ts2epoch epoch2ts );
use MT::TheSchwartz::Job;

my $work;

sub override {
    if ( !MT->component('Sync') ) {
        return;
    }

    require MT::Worker::ContentsSync;
    $work = \&MT::Worker::ContentsSync::work;

    no warnings 'redefine';
    *MT::Worker::ContentsSync::work = \&_work;
}

sub _work {
    my ( $class, $job ) = @_;
    $work->( $class, $job );

    # Do nothing when an error occurs.
    if (MT::TheSchwartz::Job->exist(
            { funcid => $job->funcid, uniqkey => $job->uniqkey }
        )
        )
    {
        return;
    }

    my $plugin = MT->component('PeriodicSync');
    my $scope  = 'blog:' . $job->uniqkey;

    my $sync_period_status
        = $plugin->get_config_value( 'sync_period_status', $scope );
    my $sync_period = $plugin->get_config_value( 'sync_period', $scope );

    # Do nothing when sync_period is invalid.
    unless ( $sync_period_status
        && $sync_period
        && $sync_period =~ m/^\d+$/ )
    {
        return;
    }

    require MT::SyncSetting;
    my $sync_setting = MT::SyncSetting->load( { blog_id => $job->uniqkey } )
        or return;

    my $epoch = ts2epoch( undef, $sync_setting->schedule_date );
    $epoch += $sync_period * 60 * 60;
    my $ts = epoch2ts( undef, $epoch );

    # Update mt_sync_setting record.
    $sync_setting->schedule_date($ts);
    $sync_setting->save or die $sync_setting->errstr;

    # Create mt_ts_job record.
    $job->run_after($epoch);
    $job->save or die $job->errstr;

    return;
}

1;
