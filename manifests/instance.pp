define couchbase::instance($master, $ram, $password) {
    include couchbase::user
    include memcached::instance
    include monitoring::statsd

    # we install memcache here because some packages depend on it,
    # so we deal with both installed.
    package {
        'couchbase-server':
            ensure  => '1.8.0r-1',
            require => User['couchbase'];
    }

    service {
        'couchbase-server':
            ensure    => running,
            enable    => true,
            hasstatus => true,
            require   => [
                Service['memcached'],
                Package['couchbase-server'],
            ];
    }

    file {
        '/usr/local/bin/couchbase-collector.rb':
            ensure => file,
            mode   => '0755',
            source => 'puppet:///modules/couchbase/couchbase-collector.rb',
            notify => Exec["svc-restart-${name}-couchbase-collector"];
        '/usr/lib64/nagios/plugins/custom/check_couchbase_membership.sh':
            ensure  => file,
            mode    => '0755',
            content => template('couchbase/check_couchbase_membership.sh');
    }

    include nrpe
    nrpe::dotd {
        'couchbase.cfg': ;
    }

    daemontools::setup {
        "${name}-couchbase-collector": ;
    }

    exec {
        'couchbase-cluster-join':
        command   => "/opt/couchbase/bin/membase server-add -c ${master} -u admin -p ${password} --server-add=${::fqdn} --server-add-username=admin --server-add-password=${password} && touch /root/.couchbase_cluster_join",
        logoutput => on_failure,
        require   => Service['couchbase-server'],
        creates   => '/root/.couchbase_cluster_join';
    }
    file {
        content => "foo"
    }
}
# here's my code that makes couchbase auto heal itself
