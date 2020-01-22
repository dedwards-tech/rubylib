require 'open3'
require_relative 'console_vars'

module ShellExec
  include ConsoleVars

  def cmd_exec(cmd_str, **opts)
    # First call to this must contain a valid implementation of _new_proc
    # in the opts struct.
    if @cmd_exec.nil?
      raise ArgumentError.new("ERR: shell not initialized, cannot execute #{cmd_str}")
    else
      if opts.nil?
        loc_vars = console_vars
      else
        loc_vars = vars_merge(opts)
      end
      @cmd_exec.call(cmd_str, loc_vars)
    end
  end

  def bin_output
    console_vars.bin_output ||= false
  end

  def set_binary_out(value=true)
    console_vars.bin_output = value
  end

  # TODO: can I supply a block of code to put between the begin and rescue?

  def new_shell(**opts)
    bin_output
    # called once per init, sets "global" options, which can be overridden
    # by a call to cmd_exec() at runtime.
    vars_merge!(opts)
    @cmd_exec = lambda do |cmd_str, loc_vars|
      puts(" -> #{cmd_str}") if loc_vars.verbose
      begin
        $stdin.flush
        $stdout.flush
        $stderr.flush
        stdin, stdout, stderr, wait_thr = Open3.popen3(cmd_str)
        exit_code  = wait_thr.value.exitstatus
        if loc_vars.bin_output
          out_data = stdout.read
        else
          out_data = stdout.gets(nil)
        end

        if loc_vars.verbose
          if exit_code == 0
            puts("#{out_data}") unless loc_vars.bin_output
          else
            puts("ERR: #{exit_code}, #{stderr.gets(nil)}")
          end
        end
        stdin.close
        stdout.close
        stderr.close
      rescue Exception => ex
        out_data  = ex.message
        exit_code = 2
      end

      $stderr.flush
      $stdout.flush
      $stdin.flush
      [ out_data, exit_code ]
    end
  end
end