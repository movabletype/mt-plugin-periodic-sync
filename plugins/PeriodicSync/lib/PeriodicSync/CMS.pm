package PeriodicSync::CMS;
use strict;
use warnings;
use utf8;

# Add form elements to Contents Sync Settings screen.
sub add_form {
    my ( $cb, $app, $tmpl ) = @_;

    my $insert = quotemeta <<'__INSERT__';
      <div id="sync_date-field-msg-block" style="display: none;"></div>
__INSERT__
    my $mtml = <<'__MTML__';
      <div class="option"><input type="checkbox" id="sync-period-status" name="sync_period_status" value="1" <mt:if name="sync_period_status">checked="checked"</mt:if> /> <input type="text" id="sync-period" class="text num" name="sync_period" value="<mt:var name="sync_period">" /> 時間毎に実行する。</div>

<mt:setvarblock name="jq_js_include" append="1">
var changeSyncPeriodStatus = function() {
  if (jQuery('input#sync-period-status').is(':checked')) {
    jQuery('input#sync-period').removeAttr('disabled');
  } else {
    jQuery('input#sync-period').attr('disabled','disabled');
  }
};
jQuery(document).ready(changeSyncPeriodStatus);
jQuery('input#sync-period-status').change(changeSyncPeriodStatus);
</mt:setvarblock>
__MTML__
    $$tmpl =~ s/($insert)/$mtml$1/;
}

# Load parameters "sync_period_status" and "sync_period".
sub load_param {
    my ( $cb, $app, $param, $tmpl ) = @_;

    my $plugin     = MT->component('PeriodicSync');
    my $scope      = 'blog:' . $app->blog->id;
    my $setting_id = $app->param('id');

    $param->{sync_period_status}
        = $plugin->get_config_value( 'sync_period_status', $scope,
        $setting_id );
    $param->{sync_period}
        = $plugin->get_config_value( 'sync_period', $scope, $setting_id );

    return 1;
}

sub check_param {
    my ( $cb, $app, $sync_setting, $original ) = @_;

    my $sync_period_status = $app->param('sync_period_status') ? 1 : undef;
    my $sync_period = $app->param('sync_period');

    if ($sync_period_status) {
        unless ( $sync_period && $sync_period =~ m/^\d+$/ ) {
            return $app->error(
                'サーバー配信日時の配信間隔が不正です。1 以上の整数値を設定してください。'
            );
        }
    }

    return 1;
}

# Save parameters "sync_period_status" and "sync_period".
# An error occurs when "sync_period" is not positive integer.
sub save_param {
    my ( $cb, $app, $sync_setting, $original ) = @_;

    my $sync_period_status = $app->param('sync_period_status') ? 1 : undef;
    my $sync_period = $app->param('sync_period');

    my $plugin = MT->component('PeriodicSync');
    my $scope  = 'blog:' . $app->blog->id;

    $plugin->set_config_value( 'sync_period_status', $sync_period_status,
        $scope, $sync_setting->id );
    if ($sync_period_status) {
        $plugin->set_config_value( 'sync_period', $sync_period, $scope,
            $sync_setting->id );
    }
}

1;

