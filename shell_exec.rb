require 'open3'
require_relative 'common_console_vars'

module ShellExec
  include CommonConsoleVars

  def _new_proc(**opts, &block)
    raise ArgumentError("ERR: block required when using ShellExec::_new_proc()") unless block_given?
    Proc.new do |cmd_str|
      unless cmd_str.nil?
        unless cmd_str == ''
          yield(cmd_str)
        end
      end
    end
  end

  def bin_output
    @bin_output ||= false
  end

  def cmd_exec(**opts)
    # First call to this must contain a valid implementation of _new_proc
    @cmd_exec ||= opts[:cmd_exec]
  end

  def _exec(cmd_str, **opts)
    @verbose    = opts.fetch(:verbose, verbose)
    @bin_output = opts.fetch(:binaryoutput, bin_output)
    cmd_exec(opts).call(cmd_str)
  end

  def new_shell(**opts)
    @verbose    = opts.fetch(:verbose, verbose)
    _new_proc(opts) do |cmd_str|
      puts(" -> #{cmd_str}") if verbose
      begin
        $stdout.flush
        $stderr.flush
        stdin, stdout, stderr, wait_thr = Open3.popen3(cmd_str)
        exit_code  = wait_thr.value.exitstatus
        if bin_output
          out_data = stdout.read
        else
          out_data = stdout.gets(nil)
        end

        if verbose
          if exit_code == 0
            puts("#{out_data}") unless bin_output
          else
            puts("ERR: #{exit_code}, #{stderr.gets(nil)}")
          end
        end
        stdout.close
        stderr.close
      rescue Exception => ex
        out_data  = ex.message
        exit_code = 2
      end

      $stdout.flush
      $stderr.flush
      [ out_data, exit_code ]
    end
  end
end