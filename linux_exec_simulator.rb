require_relative 'shell_exec'

class LinuxExecSimulator
  include ShellExec
  attr_reader :version
  attr_reader :sim_data

  def initialize(**opts)
    # default is to create a local shell exec, you must pass one in if you
    # want some other connection type - like ssh
    cmd_exec(opts)

    @sim_data = opts.fetch(:sim_data, nil)
    raise ArgumentError("ERR: missing sim_data:{} for Linux exec simulator") if sim_data.nil?

    # get the kernel version
    ret_str, exit_code = _exec("uname -a")
    if exit_code == 0
      @version = ret_str.strip.chomp
    else
      @version = 'unknown'
    end
  end

  def _sim_lookup(cmd_str)
    ret_data = nil
    sim_data.each do |kvp|
      if kvp.keys.include?(cmd_str)
        ret_data = kvp.fetch(cmd_str, nil)
        break unless ret_data.nil?
      end
    end
    ret_data
  end

  def new_sim(**opts)
    verbose    = opts.fetch(:verbose, true)
    bin_output = opts.fetch(:binaryoutput, false)
    _new_proc(opts) do |cmd_str|
      puts(" -> #{cmd_str}") if verbose
      $stdout.flush

      out_data = _sim_lookup(cmd_str)
      if out_data.nil?
        exit_code = 1
      else
        exit_code = 0
      end

      if verbose
        if exit_code == 0
          puts("#{out_data}") unless bin_output
        else
          puts("ERR: #{exit_code}, simulator lookup for #{cmd_str} not found")
        end
      end
      $stdout.flush
      [ out_data, exit_code ]
    end
  end
end