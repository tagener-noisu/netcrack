require 'socket'

module Netcrack

VERSION = "0.0.1"

class Server
    def initialize(port, input_stream, verbose =false)
        @port = port
        @input_stream = input_stream
        @verbose = verbose
    end

    def start
        @tcp = TCPServer.new(@port)
        log("Server started at port #{@port}")

        loop do
            @client = @tcp.accept
            log("Connection from: #{@client.addr[3]}")
            @client.puts(banner)
            input = @client.gets
            log("  #{input}")
            if (input)
                process(input.chomp)
            end
            @client.close
            log("Connection closed by server")
        end
    end

    def shutdown
        @tcp.close
    end

    private

    def log(msg)
        if (@verbose)
            $stderr.puts(msg)
        end
    end

    def banner
        "netcrack #{VERSION}"
    end

    def process(input)
        if (input == "MORE")
            print_more
        end
    end

    def print_more
        if ($stdin.eof?)
            @client.puts("DONE")
            log("  DONE")
            return
        end
        5.times do
            @client.puts($stdin.gets)
            return if ($stdin.eof?)
        end
    end
end

class Client
    def initialize(host, port, verbose =false)
        @host = host
        @port = port
        @verbose = verbose
    end

    def start
        loop do
            @socket = connect
            if (!@socket)
                shutdown
                return
            end

            @socket.puts("MORE")
            input = @socket.gets.chomp
            if (input == "DONE")
                $stderr.puts("Done.")
                shutdown
                return
            else
                puts(input)
            end
            while (!@socket.eof?)
                puts(@socket.gets)
            end
        end
    end

    def connect
        socket = TCPSocket.new(@host, @port)
        log("Conected to #{@host}:#{@port}")
        banner = socket.gets.chomp
        log("  #{banner}")
        if (!banner.match(/^netcrack/))
            $stderr.puts("Unsupported server. Aborting.")
            socket.close
            return nil
        end
        return socket
    end

    def shutdown
        @socket.close
    end

    private

    def log(msg)
        if (@verbose)
            $stderr.puts(msg)
        end
    end
end

end

