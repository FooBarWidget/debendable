# frozen_string_literal: true
require "optparse"
require_relative "../debendencies"
require_relative "version"

class Debendencies
  class CLI
    def initialize
      @options = {
        format: "oneline",
      }
    end

    def run
      option_parser.parse!
      require "json" if @options[:format] == "json"

      paths = ARGV
      if paths.empty?
        puts option_parser
        exit 1
      end

      debendencies = Debendencies.new(logger: get_logger)
      begin
        debendencies.scan(*paths)
        dependencies = debendencies.resolve
      rescue Error => e
        abort(e.message)
      end

      case @options[:format]
      when "oneline"
        puts dependencies.map { |d| d.name }.join(", ")
      when "multiline"
        dependencies.each do |dep|
          puts dep.to_s
        end
      when "json"
        puts JSON.generate(dependencies.map { |d| d.as_json })
      else
        puts "Invalid format: #{@options[:format]}"
        exit 1
      end
    end

    private

    def option_parser
      @option_parser ||= OptionParser.new do |opts|
        opts.banner = "Usage: debendencies <PATHS...>"

        opts.on("-f", "--format FORMAT", "Output format (oneline|multiline|json). Default: oneline") do |format|
          @options[:format] = format
        end

        opts.on("--verbose", "Show verbose output") do
          @options[:verbose] = true
        end

        opts.on("-h", "--help", "Show this help message") do
          puts opts
          exit
        end

        opts.on("--version", "Show version") do
          puts VERSION_STRING
          exit
        end
      end
    end

    def get_logger
      if @options[:verbose]
        require "logger"
        Logger.new(STDERR)
      end
    end
  end
end
