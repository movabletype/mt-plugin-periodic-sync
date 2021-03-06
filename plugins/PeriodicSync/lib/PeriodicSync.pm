package PeriodicSync;
use strict;
use warnings;
use utf8;
use JSON;

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

    my $job_arg = $job->arg ? JSON::decode_json( $job->arg ) : {};
    return if ( $job_arg->{trigger} && $job_arg->{trigger} eq 'SyncNow' );

    # Do nothing when an error occurs.
    if (MT::TheSchwartz::Job->exist(
            { funcid => $job->funcid, uniqkey => $job->uniqkey }
        )
        )
    {
        return;
    }

    my $plugin = MT->component('PeriodicSync');
    my $sync_setting = $plugin->get_sync_setting($job) or return;
    my $sync_period_status
        = $plugin->get_config_value_from_job( 'sync_period_status', $job );
    my $sync_period
        = $plugin->get_config_value_from_job( 'sync_period', $job );

    # Do nothing when sync_period is invalid.
    unless ( $sync_period_status
        && $sync_period
        && $sync_period =~ m/^\d+$/ )
    {
        return;
    }

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
