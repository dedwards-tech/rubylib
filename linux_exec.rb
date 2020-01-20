require 'open3'

module ShellExec
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

  def cmd_exec(**opts)
    if opts.fetch(:cmd_exec, nil).nil?
      # default initializer is a local shell when no :cmd_exec passed in.
      @cmd_exec ||= new_shell(opts)
    else
      # caller is passing a new exec object in, use it, for multi-threading control
      # or to switch out to an ssh remote connection.
      @cmd_exec = opts[:cmd_exec]
    end
    @cmd_exec
  end

  def _exec(cmd_str, **opts)
    cmd_exec(opts).call(cmd_str)
  end

  def new_shell(**opts)
    verbose    = opts.fetch(:verbose, true)
    bin_output = opts.fetch(:binaryoutput, false)
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


class LinuxExecHelper
  include ShellExec
  attr_reader :version

  def initialize(**opts)
    # default is to create a local shell exec, you must pass one in if you
    # want some other connection type - like ssh
    cmd_exec(opts)

    # get the kernel version
    ret_str, exit_code = _exec("uname -a")
    if exit_code == 0
      @version = ret_str.strip.chomp
    else
      @version = 'unknown'
    end
  end
end

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