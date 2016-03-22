class Repositext
  class Services

    # This service provides text extraction from PDF documents. It manages a
    # jruby server process that wraps Apache PDFBox and communicates with the
    # server via TCP sockets.
    #
    # See this code for usage:
    #  * Repositext::Cli::Validate#validate_pdf_export and
    #  * Repositext::Validation::Validator::PdfExportConsistency
    #
    class ExtractTextFromPdf

      # @param port [Integer, optional] the TCP port the server listens to
      def initialize(port=1206)
        @port = port
      end

      # Extracts text contents of pdf_file_name.
      # @param pdf_file_name [String] absolute path to the PDF to extract text from.
      def extract(pdf_file_name)
        # Connect to jruby extract_text_from_pdf server
        Socket.tcp('localhost', @port) do |connection|
          connection.write("EXTRACT_TEXT #{ pdf_file_name }")
          connection.close_write # send EOF
          r = connection.read
          r.force_encoding(Encoding::UTF_8)
          r
        end
      end

      # Starts the server. Tries up to 5 times to connect to the server to make
      # sure it runs (with exponential backoff).
      def start
        puts "Starting PDF text extraction server"

        mrr = MultiRubyRunner.new
        server_root_path = File.expand_path("../../../../servers/extract_text_from_pdf", __FILE__)
        child_pid = mrr.execute_command_in_directory(
          "#{ File.join(server_root_path, "bin/extract-text-from-pdf") } --port #{ @port }",
          server_root_path,
          { blocking: false }
        )

        # Wait until server is ready
        connection_attempt = 0
        max_attempts = 5

        begin
          connection_attempt += 1
          if connection_attempt <= 5
            puts " - connecting (#{ connection_attempt } of #{ max_attempts })"
            # try to connect to server
            Socket.tcp('localhost', @port) do |connection|
              connection.write('PING')
              connection.close
            end
            puts " - success"
          else
            # We've exceeded number of attempts, exit
            puts "Exceeded #{ max_attempts } attempts to connect to PDF text extraction server, giving up."
            exit
          end
        rescue Errno::ECONNREFUSED => e
          # Exponential backoff
          sleep(2**connection_attempt)
          retry
        end

      end

      # Stops the server.
      def stop
        puts "Stopping PDF text extraction server"
        begin
          Socket.tcp('localhost', @port) do |connection|
            connection.write('TERMINATE')
            connection.close # send EOF
            puts " - stopped"
          end
        rescue Errno::ECONNREFUSED => e
          puts " - Server was stopped already"
        end
      end

    end
  end
end
