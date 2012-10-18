class couchbase::user {
    user {
        'couchbase':
            ensure  => present,
            comment => 'Couchbase',
            uid     => 459,
            gid     => 'couchbase',
            home    => '/opt/couchbase';
    }

    group {
        'couchbase':
            ensure => present;
    }
}
