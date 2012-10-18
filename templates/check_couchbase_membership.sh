#!/bin/bash

export PATH=/opt/couchbase/bin:/usr/local/bin:$PATH

membership=$(
couchbase-cli server-info -c localhost -u admin -p "<%= scope.lookupvar('::couchbase_password') %>" \
| awk '/clusterMembership/ {print $2;}' | tr -d '",'
)

if [ -z "$membership" ]; then
    echo "UNKNOWN: error running couchbase-cli"
    exit 3
elif [ "$membership" = "active" ]; then
    echo "OK: active member of couchbase cluster"
    exit 0
fi

echo "CRITICAL: cluster membership is $membership, should be active. rebalance?"
exit 2
