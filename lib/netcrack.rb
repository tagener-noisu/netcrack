require 'thread'
require 'socket'

module Netcrack

VERSION = "0.1.0"

class Server
    def initialize(port, options = {})
        default_opts = {
            verbose: false,
            input: $stdin,
            err: $stderr
        }
        options.merge!(default_opts) { |k, new, default| new || default }

        @alive = false
        @port = port
        @verbose = options[:verbose]
        @input = options[:input]
        @err = options[:err]
        @input_mutex = Mutex.new
    end

    def start
        @tcp = TCPServer.new(@port)
        log("Server started at port #{@port}")
        @alive = true

        loop do
            begin
                client = @tcp.accept
            rescue IOError
                raise if @alive
                return
            end
            Thread.new(client) { |c|
                log("Connection from: #{c.peeraddr(false)[3]}")
                c.puts(banner)
                input = c.gets
                log("  #{input}")
                if (input)
                    process(input.chomp, c)
                end
                c.close
                log("Connection closed by server")
            }
        end
    end

    def alive?
        @alive
    end

    def shutdown
        @alive = false
        @tcp.close
    end

    private

    def log(msg)
        if (@verbose)
            @err.puts(msg)
        end
    end

    def banner
        "netcrack #{VERSION}"
    end

    def process(input, client)
        if (input == "MORE")
            print_more(client)
            return
        end
        log("Protocol mismatch")
        client.puts("Protocol mismatch")
    end

    def print_more(client)
        count = client.gets.chomp.to_i
        if (@input.eof?)
            client.puts("DONE")
            log("  DONE")
            return
        end

        buf = []
        @input_mutex.synchronize {
            count.times {
                buf << @input.gets
                break if (@input.eof?)
            }
        }
        buf.each { |line|
            client.puts(line)
        }
    end
end

class Client
    def initialize(host, port, options = {})
        default_opts = {
            ppr: 100_000,
            verbose: false,
            output: $stdout,
            err: $stderr
        }
        options.merge!(default_opts) { |k, new, default| new || default }

        @host = host
        @port = port
        @ppr = options[:ppr]
        @verbose = options[:verbose]
        @output = options[:output]
        @err = options[:err]
    end

    def start
        loop do
            @socket = connect
            if (!@socket)
                return
            end

            @socket.puts("MORE")
            @socket.puts(@ppr)
            input = @socket.gets.chomp
            if (input == "DONE")
                @err.puts("Done.")
                shutdown
                return
            else
                @output.puts(input)
            end
            while (!@socket.eof?)
                @output.puts(@socket.gets)
            end
        end
    end

    def connect
        socket = TCPSocket.new(@host, @port)
        log("Conected to #{@host}:#{@port}")
        valid = verify_protocol(socket)
        if (!valid)
            @err.puts("Protocol mismatch")
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
            @err.puts(msg)
        end
    end

    def verify_protocol(socket)
        banner = socket.gets.chomp
        log("  #{banner}")
        if (banner.match(/^netcrack/))
            return true
        end
        return false
    end
end

end

# vim:ts=4:sw=0:sts=4:et:
