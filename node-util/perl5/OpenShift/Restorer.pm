package OpenShift::Restorer;

use strict;
use warnings FATAL => 'all';

use Apache2::RequestRec ();
use Apache2::Log;
use APR::Table ();

use Apache2::Const -compile => qw(FORBIDDEN REDIRECT);

# Validate the uuid.  If validation fails, log an error and return 403
# Forbidden.  If validation succeeds, restore the application and
# redirect to it.
sub handler {
  my $r = shift;

  my (undef,$uuid,undef) = split '/', $r->path_info;
  if (not $uuid =~ /^[0-9a-fA-F]{24,32}$/) {
    $r->log_error("Invalid uuid $uuid given to restorer");

    return Apache2::Const::FORBIDDEN;
  } else {
    system('/usr/sbin/oo-restorer-wrapper.sh', $uuid);
    sleep 2;

    my $schema = $r->subprocess_env('https') ? 'https://' : 'http://';
    my $host = $r->hostname;
    my $path = $r->path_info;
    $path =~ s|\Q/$uuid\E||g;
    my $location = $schema . $host . $path;
    $r->headers_out->set(Location => $location);

    return Apache2::Const::REDIRECT
  }
}

1;
