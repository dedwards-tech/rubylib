require "net/ssh"
require "net/scp"

require_relative 'credentials'
require_relative 'shell_exec'

class SshCredential
  include UserLoginCredential

  def initialize(server_ip:nil, user_name:nil, user_pwd:nil, user_group:nil)
    # initialize the credential structure
    user_login
    # add server_ip to the credential structure
    credential.merge!( { :server_ip => nil } )

    if server_ip.nil? or user_name.nil? or user_pwd.nil?
      unless server_ip.nil?
        set_server_ip(server_ip)
      end
      unless user_name.nil? or user_pwd.nil?
        set_user_login(user_name, user_pwd, user_group)
      end
    else
      set_ssh(server_ip, user_name, user_pwd, user_group)
    end
  end

  def chk_ssh_credential
    if server_ip.nil?
      raise ArgumentError, 'ERR: server_ip is NOT set, and required.'
    end

    if user_name.nil? or user_pwd.nil?
      raise ArgumentError, 'ERR: user_name and user_pwd are NOT set, and required.'
    end
  end

  def set_server_ip(server_ip)
    credential.merge!( { :server_ip  => server_ip } )
  end

  def set_ssh(server_ip, user_name, user_pwd, user_group=nil)
    set_server_ip(server_ip)
    set_user_login(user_name, user_pwd, user_group)
  end

  def server_ip
    credential.fetch(:server_ip, nil)
  end

  def to_s
    "ip: #{server_ip}, user name: #{user_name}(#{user_group})"
  end
end

module SshExecHelper
  include CommonConsoleVars
  include ShellExec

  def timeout
    @timeout ||= 2 * 60
  end

  def ssh_connect(ssh_credential, **opts)
    @timeout  = opts.fetch(:timeout,  timeout)
    @verbose  = opts.fetch(:dry_run,  dryrun)
    @use_sudo = opts.fetch(:use_sudo, use_sudo)
    begin
      @session = Net::SSH.start(ssh_credential.server_ip,
                                ssh_credential.user_name,
                                password:ssh_credential.user_pwd,
                                timeout:timeout,
                                verbose:is_verbose)
    rescue => ex
      @session = nil
      puts("ERR: cannot connect SSH to host #{server_ip}, response: #{ex.to_s}")
    end

    # create an ssh based cmd exec context
    cmd_exec(cmd_exec:new_ssh_shell(opts))
  end

  def ssh_disconnect
    @session.close() unless @session.nil?
    @session = nil
  end

  def session
    @session
  end

  def ssh_owner_ug
    "#{user_name}:#{user_group}"
  end

  def ssh_ugw_perm
    '0755'
  end

  def new_ssh_shell(**opts)
    _new_proc(opts) do |cmd_str|
      puts(" -> SSH: #{cmd_str}") if verbose
      $stdout.flush
      exit_code  = 0
      output     = ''
      rem_cmd    = 'sudo ' + cmd_str if use_sudo
      unless dryrun
        session.exec(rem_cmd) do |ch, stream, data|
          exit_code  = 1 if stream == :stderr
          output    += data
        end
        # now let the session do its thing while we wait!
        session.loop
      end
      [ output, exit_code ]
    end
  end
end

class LinuxExecRemoteSsh
  include SshExecHelper
  attr_reader :version

  def initialize(ssh_credential, **opts)
    if ssh_credential.is_a?(SshCredential)
      ssh_credential.chk_credential
      ssh_connect(ssh_credential, opts)
    end

    # get the kernel version
    ret_str, exit_code = _exec("uname -a")
    if exit_code == 0
      @version = ret_str.strip.chomp
    else
      @version = 'unknown'
    end
  end

  # use the _exec(cmd_str) method to invoke remote ssh requests!
end
