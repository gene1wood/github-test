#!/usr/bin/ruby

require "socket"

class CouchbaseStats
    def initialize(bucket)
        @bucket = bucket
    end

    def get_stats
        cmd = "/opt/couchbase/bin/cbstats localhost:11210 all #{@bucket}"
        stats = {}
        IO.popen(cmd) do |cbstats|
            cbstats.each do |line|
                var, val = line.chomp.split(':')
                stats[var.strip] = val.strip
            end
        end

        return stats
    end
end

bucket = ARGV[0] || "default"
previous = {}
mapping = {
    "cmd_get" => "couchbase.#{bucket}.command.get",
    "cmd_set" => "couchbase.#{bucket}.command.set",
    "cmd_flush" => "couchbase.#{bucket}.command.flush",
    "incr_misses" => "couchbase.#{bucket}.command.incr_misses",
    "incr_hits" => "couchbase.#{bucket}.command.incr_hits",
    "decr_misses" => "couchbase.#{bucket}.command.decr_misses",
    "decr_hits" => "couchbase.#{bucket}.command.decr_hits",
    "delete_misses" => "couchbase.#{bucket}.command.delete_misses",
    "delete_hits" => "couchbase.#{bucket}.command.delete_hits",
    "mem_used" => "couchbase.#{bucket}.memory.mem_used",
    "curr_items" => "couchbase.#{bucket}.memory.curr_items",
    "curr_items_tot" => "couchbase.#{bucket}.memory.curr_items_tot",
    "bytes_read" => "couchbase.#{bucket}.bytes.read",
    "bytes_written" => "couchbase.#{bucket}.bytes.written",
    "ep_queue_size" => "couchbase.#{bucket}.ep.queue_size",
    "ep_flusher_todo" => "couchbase.#{bucket}.ep.flusher_todo",
}
counters = ["cmd_get", "cmd_set", "cmd_flush", "incr_misses", "incr_hits",
            "decr_misses", "decr_hits", "delete_misses", "delete_hits",
            "bytes_read", "bytes_written"]
timers = ["mem_used", "curr_items", "curr_items_tot",
          "ep_queue_size", "ep_flusher_todo"]
cbstats = CouchbaseStats.new("sync")
statsd_updates = []
udp = UDPSocket.new
$stdout.sync = true

loop do
    stats = cbstats.get_stats

    counters.each do |c|
        if not stats[c]
            $stderr.puts "skipping counter stat #{c}, not found"
            next
        end
        if previous[c]
            incr = stats[c].to_i - previous[c].to_i
            name = mapping[c] || c
            statsd_updates << "#{name}:#{incr}|c"
        end
        previous[c] = stats[c].to_i
    end

    timers.each do |c|
        if not stats[c]
            $stderr.puts "skipping timer stat #{c}, not found"
            next
        end

        name = mapping[c] || c
        statsd_updates << "#{name}:#{stats[c].to_i}|ms"
    end

    statsd_updates.each do |update|
        puts update
        udp.send(update, 0, "localhost", 8125)
    end
    statsd_updates = []
    sleep(5)
end
