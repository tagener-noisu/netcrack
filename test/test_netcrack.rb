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
        until (@server.alive?)
            sleep 0.3
        end
    end

    def test_server_returns_the_banner
        sock = TCPSocket.new(@host, @port)
        banner = sock.gets.chomp
        sock.close
        assert(banner.match(/^netcrack/))
    end

    def teardown
        @server.shutdown
        @server_thr.join
    end
end

# vim:ts=4:sw=0:et:
