require_relative '../lib/netcrack.rb'
require 'minitest/autorun'
require 'socket'

class TestNetcrack < MiniTest::Test
    def setup
        @host = '127.0.0.1'
        @port = 5000
        inp = File.open("test/input", "r")
        @server = Netcrack::Server.new(@port, {input: inp})
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

    def test_server_verifies_protocol
        sock = TCPSocket.new(@host, @port)
        sock.gets # skip the banner
        sock.puts("BAD COMMAND")
        answer = sock.gets.chomp
        assert(sock.eof?) # closes connection on bad command
        sock.close
        assert_equal(answer, "Protocol mismatch");
    end

    def test_server_returns_input_on_more_command
        sock = TCPSocket.new(@host, @port)
        sock.gets # skip the banner
        sock.puts("MORE")
        sock.puts("3") # number of lines required
        lines = [sock.gets, sock.gets, sock.gets]
        assert(sock.eof?) # closes connection after the answer
        sock.close
        assert_equal(lines[0], "LOREM\n")
        assert_equal(lines[1], "IPSUM\n")
        assert_equal(lines[2], "DOLOR\n")
    end

    def teardown
        @server.shutdown
        @server_thr.join
    end
end

# vim:ts=4:sw=0:et:
