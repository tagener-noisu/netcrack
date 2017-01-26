require_relative '../lib/netcrack.rb'
require 'minitest/autorun'
require 'socket'

class TestNetcrack < MiniTest::Test
    def setup
        @host = '127.0.0.1'
        @port = 5000
        @server = Netcrack::Server.new(@port)
        @server_thr = Thread.new {
                @server.start
        }
        sleep(0.1) until (@server.alive?)
    end

    def test_server_returns_the_banner
        sock = TCPSocket.new(@host, @port)
        banner = sock.gets.chomp
        sock.close
        assert(banner.match(/^netcrack/))
    end

    def test_server_matches_protocol
        sock = TCPSocket.new(@host, @port)
        sock.gets # skip the banner
        sock.puts("BAD COMMAND")
        answer = sock.gets.chomp
        assert_equal(answer, "Protocol mismatch");
    end

    def teardown
        @server.shutdown
        @server_thr.join
    end
end

# vim:ts=4:sw=0:et:
