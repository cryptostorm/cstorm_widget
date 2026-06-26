package PostConnect;

use strict;
use warnings;
use Exporter qw(import);

use Tkx;
use Digest::SHA qw(sha256_hex);
use JSON::PP qw(decode_json);
use Time::HiRes qw(time);

our @EXPORT_OK = qw(
    start_post_connect_checks
);

use constant POSTCONNECT_DEBUG => 0;

sub _dbg {
    return unless POSTCONNECT_DEBUG;

    my ($msg) = @_;
    $msg = '' unless defined $msg;

    my $ts = sprintf('%.3f', time);
    print STDERR "[PostConnect $ts] $msg\n";
}

sub start_post_connect_checks {
    my (%args) = @_;

    my $state   = $args{state}   or die "start_post_connect_checks: missing state";
    my $on_done = $args{on_done};

	if ($state->{runtime}->{post_connect_check_running}) {
        _dbg("already running; skipping");
        return 0;
    }

    eval { Tkx::package_require('http'); 1 }
        or do {
            _finish($state, {
                latest_version => -1,
                upgrade        => 0,
                node_update_ok => 0,
                error          => "Tcl http package unavailable: $@",
            }, $on_done);
            return 0;
        };

    my $base_url     = $args{base_url}     || 'http://10.31.33.7';
    my $servers_file = $args{servers_file} || $state->{app}->{serversfile} || '..\\user\\latest_list.json';
    my $hash_file    = $args{hash_file}    || '..\\user\\list_hash.txt';
    my $version      = $args{version}      || $state->{app}->{version} || '0';
	
	_dbg("current_version=$version");
	
	$state->{runtime}->{post_connect_check_running} = 1;
    $state->{runtime}->{post_connect_check_done}    = 0;
    $state->{runtime}->{post_connect_check_result}  = undef;

    my $ctx = {
        state        => $state,
        on_done      => $on_done,
        base_url     => $base_url,
        servers_file => $servers_file,
        hash_file    => $hash_file,
        version      => $version,
        result       => {
            latest_version => -1,
            upgrade        => 0,
            node_update_ok => 0,
            error          => '',
        },
    };

    _fetch(
        "$base_url/latest.txt",
        sub {
            my ($ok, $body, $err) = @_;
			
			_dbg("latest.txt result ok=$ok err=" . ($err // ''));

			if ($ok && defined($body)) {
    			_dbg("latest.txt body=" . _short($body));
			}

            if ($ok && defined($body) && $body =~ /LATEST:([0-9.]+)/) {
                $ctx->{result}->{latest_version} = $1;
                _dbg("latest_version=$1");

                if (_version_gt($1, $version)) {
                    $ctx->{result}->{upgrade} = 1;
                    _dbg("upgrade available");
                }
                else {
                    _dbg("no upgrade available");
                }
            }
            else {
                _dbg("latest version not found in latest.txt");
            }

            _check_node_hash($ctx);
        },
    );

    return 1;
}

sub _check_node_hash {
    my ($ctx) = @_;

    _fetch(
        "$ctx->{base_url}/list_hash.txt",
        sub {
            my ($ok, $body, $err) = @_;
			
			_dbg("list_hash.txt result ok=$ok err=" . ($err // ''));

            if ($ok && defined($body)) {
                _dbg("list_hash.txt body=" . _short($body));
            }

            if (!$ok) {
                $ctx->{result}->{error} = $err || 'could not fetch list_hash.txt';
                _finish($ctx->{state}, $ctx->{result}, $ctx->{on_done});
                return;
            }

            my $remote_hash_line = $body // '';
            $remote_hash_line =~ s/\r?\n\z//;

            my ($remote_hash) = split /\s+/, $remote_hash_line, 2;
			
			_dbg("remote_hash=" . ($remote_hash // '<undef>'));

            if (!$remote_hash || $remote_hash !~ /\A[a-fA-F0-9]{64}\z/) {
                $ctx->{result}->{error} = 'invalid list_hash.txt format';
                _finish($ctx->{state}, $ctx->{result}, $ctx->{on_done});
                return;
            }

            my $local_hash = '';
            if (-e $ctx->{servers_file}) {
                my $local_json = eval { _read_raw($ctx->{servers_file}) };
                $local_hash = sha256_hex($local_json) if defined $local_json;
            }
			
			_dbg("local_hash=" . ($local_hash || '<none>'));

            if ($local_hash && lc($local_hash) eq lc($remote_hash)) {
                $ctx->{result}->{node_update_ok} = 1;
				_dbg("node list already current");
                _finish($ctx->{state}, $ctx->{result}, $ctx->{on_done});
                return;
            }

            _fetch_new_node_list($ctx, $remote_hash, $remote_hash_line);
        },
    );
}

sub _fetch_new_node_list {
    my ($ctx, $remote_hash, $remote_hash_line) = @_;

    _fetch(
        "$ctx->{base_url}/latest_list.json",
        sub {
            my ($ok, $body, $err) = @_;
			
			_dbg("latest_list.json result ok=$ok err=" . ($err // ''));
			_dbg("latest_list.json bytes=" . (defined($body) ? length($body) : 0));

            if (!$ok) {
                $ctx->{result}->{error} = $err || 'could not fetch latest_list.json';
                _finish($ctx->{state}, $ctx->{result}, $ctx->{on_done});
                return;
            }

            my $downloaded_hash = sha256_hex($body // '');
			
			_dbg("downloaded_hash=$downloaded_hash");

            if (lc($downloaded_hash) ne lc($remote_hash)) {
                $ctx->{result}->{error} = 'latest_list.json hash mismatch';
				_dbg("node list differs; fetching latest_list.json");
                _finish($ctx->{state}, $ctx->{result}, $ctx->{on_done});
                return;
            }

            eval { decode_json($body); 1 }
                or do {
                    $ctx->{result}->{error} = "latest_list.json invalid JSON: $@";
                    _finish($ctx->{state}, $ctx->{result}, $ctx->{on_done});
                    return;
                };

            eval {
                _write_raw($ctx->{servers_file}, $body);
                _write_raw($ctx->{hash_file}, $remote_hash_line . "\n");
                1;
            } or do {
                $ctx->{result}->{error} = "could not write updated node list: $@";
                _finish($ctx->{state}, $ctx->{result}, $ctx->{on_done});
                return;
            };

            $ctx->{result}->{node_update_ok} = 1;
            _finish($ctx->{state}, $ctx->{result}, $ctx->{on_done});
        },
    );
}

sub _fetch {
    my ($url, $cb) = @_;

    my $token;

    eval {
        $token = Tkx::http__geturl(
            $url,
            -timeout => 7000,
            -headers => [
                'User-Agent' => 'Cryptostorm client',
            ],
            -command => sub {
                my ($tok) = @_;

                my $status = eval { Tkx::http__status($tok) } || 'error';
                my $ncode  = eval { Tkx::http__ncode($tok)  } || 0;
                my $data   = eval { Tkx::http__data($tok)   };

                eval { Tkx::http__cleanup($tok); };
                
				_dbg("HTTP DONE $url status=$status ncode=$ncode bytes=" . (defined($data) ? length($data) : 0));
				
                if ($status eq 'ok' && $ncode >= 200 && $ncode < 300) {
                    $cb->(1, $data, '');
                }
                else {
                    $cb->(0, undef, "HTTP fetch failed for $url: status=$status ncode=$ncode");
                }
            },
        );

        1;
    } or do {
        my $err = $@ || 'unknown http error';
        eval { Tkx::http__cleanup($token) if $token; };
        $cb->(0, undef, $err);
    };
}

sub _finish {
    my ($state, $result, $on_done) = @_;
	
	_dbg(
        "finish latest_version="
        . ($result->{latest_version} // '<undef>')
        . " upgrade="
        . ($result->{upgrade} // '<undef>')
        . " node_update_ok="
        . ($result->{node_update_ok} // '<undef>')
        . " error="
        . ($result->{error} // '')
    );

    $state->{runtime}->{post_connect_check_running} = 0;
    $state->{runtime}->{post_connect_check_done}    = 1;
    $state->{runtime}->{post_connect_check_result}  = $result;

    $state->{runtime}->{latest_version} = $result->{latest_version} // -1;
    $state->{runtime}->{upgrade}        = $result->{upgrade} ? 1 : 0;

    $on_done->($result) if $on_done;

    return 1;
}

sub _version_gt {
    my ($a, $b) = @_;

    my @a = split /\./, $a // 0;
    my @b = split /\./, $b // 0;

    my $n = @a > @b ? @a : @b;

    for my $i (0 .. $n - 1) {
        my $aa = 0 + ($a[$i] // 0);
        my $bb = 0 + ($b[$i] // 0);

        return 1 if $aa > $bb;
        return 0 if $aa < $bb;
    }

    return 0;
}

sub _read_raw {
    my ($path) = @_;

    open my $fh, '<:raw', $path or die "read $path: $!";
    local $/;
    my $data = <$fh>;
    close $fh;

    return $data;
}

sub _write_raw {
    my ($path, $data) = @_;

    open my $fh, '>:raw', $path or die "write $path: $!";
    print {$fh} $data;
    close $fh;

    return 1;
}

sub _short {
    my ($s) = @_;
    $s = '' unless defined $s;
    $s =~ s/[\r\n]+/ /g;
    return length($s) > 180 ? substr($s, 0, 180) . '...' : $s;
}

1;
