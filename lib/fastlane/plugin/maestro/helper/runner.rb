require 'fastlane_core/print_table'

HighLine.track_eof = false
module Fastlane
  module Maestro
    class Runner

      def self.run(options)
        # Check if maestro is installed
        if command?("maestro")
          # Get path to maestro binary
          maestro_path = `which maestro | xargs`.strip
        else
          UI.error("Maestro is not installed. Please run `bundle exec fastlane run maestro command:'install'`")
          return
        end
        command = [maestro_path]

        if options[:shard_all].to_i.positive?
          if !options[:device].to_s.empty?
            UI.important("Both `device` and `shard_all` are specified. Maestro will ignore `device` in favor of `--shard-all`.")
          end
        elsif !options[:device].to_s.empty?
          command.push("--device", options[:device])
        end

        command.push("test")

        # Flags with a value
        {
          config: "--config",
          debug_output: "--debug-output",
          exclude_tags: "--exclude-tags",
          report_type: "--format",
          include_tags: "--include-tags",
          output: "--output"
        }.each do |key, flag|
          value = options[key]
          next if value.nil? || value.empty?

          command.push(flag, value)

          # Make sure the directory exists for output files
          FileUtils.mkdir_p(File.dirname(value)) if [:debug_output, :output].include?(key)
        end

        # Boolean flags
        {
          continuous: "--continuous",
          flatten_debug_output: "--flatten-debug-output"
        }.each do |key, flag|
          value = options[key]

          next unless value

          command.push(flag)
        end

        # Shard flag
        shard_value = options[:shard_all]

        if !shard_value.nil? && !shard_value.is_a?(Integer)
          UI.user_error!("The `shard_all` parameter must be an integer, got '#{shard_value}' (#{shard_value.class})")
        end
        
        if shard_value.to_i.positive?
          command.push("--shard-all", shard_value.to_s)
        end

        unless options[:env_vars].nil? || options[:env_vars].empty?
          options[:env_vars].each do |key, value|
            command.push("-e", "#{key}=\"#{value}\"")
          end
        end

        command.push("#{options[:tests]}")
        command_string = command.join(" ")
        UI.message("Running command: #{command_string}")
        Dir.chdir(ENV["PWD"]) do
          # TODO: set exception based on parameter `failRun`
          system(command_string, out: $stdout, err: :out, exception: true)
        end
      end

      def self.run_deprecated(options)
        # TODO: add possibility to specify maestro path
        maestro_path = ENV["HOME"] + "/.maestro/bin/maestro"

        command = [maestro_path]

        unless options[:device].empty? || options[:device].nil?
          command.push("--device", options[:device])
        end

        command.push("test")

        unless options[:report_type].empty? || options[:report_type].nil?
          command.push("--format", options[:report_type])
        end
        unless options[:output].empty? || options[:output].nil?
          command.push("--output", options[:output])
          # Make sure that the output folder is available
          FileUtils.mkdir_p(File.dirname(options[:output]))
        end
        unless options[:env_vars].nil? || options[:env_vars].empty?
          options[:env_vars].each do |key, value|
            command.push("-e", "#{key}=#{value}")
          end
        end

        command.push("#{options[:tests]}")
        command_string = command.join(" ")
        UI.message("Running command: #{command_string}")
        Dir.chdir(ENV["PWD"]) do
          # TODO: set exception based on parameter `failRun`
          system(command_string, out: $stdout, err: :out, exception: true)
        end
      end

      def self.install
        system("curl -Ls 'https://get.maestro.mobile.dev' | bash", out: $stdout, err: :out, exception: true)
      end

      def self.download_samples
        maestro_path = ENV["HOME"] + "/.maestro/bin/maestro"
        Dir.chdir(ENV["PWD"]) do
          system("#{maestro_path} download-samples", out: $stdout, err: :out, exception: true)
        end
      end

      def self.run_generic(cmd, flags)
        maestro_path = ENV["HOME"] + "/.maestro/bin/maestro"
        command = [maestro_path]
        command.push(cmd)
        command.push(flags)
      end

      def self.command?(name)
        `which #{name}`
        $?.success?
      end
    end
  end
end
