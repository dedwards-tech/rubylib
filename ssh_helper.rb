require "net/ssh"
require "net/scp"

require_relative File.join('.', 'credentials')
require_relative File.join('.', 'console_utils')

module SshHelper
  include SshCredential
  include ConsoleUtils

  def ssh_connect(opts={})
    begin
      @session ||= Net::SSH.start(server_ip, user_name,
                                  password:user_pwd,
                                  timeout:opts.fetch(:timeout, 2 * 60),
                                  verbose:is_verbose)
    rescue => ex
      @session = nil
      puts("ERR: cannot connect SSH to host #{server_ip}, response: #{ex.to_s}")
    end
    @session
  end

  def ssh_disconnect
    @session.close() unless @session.nil?
    @session = nil
  end

  def ssh_owner_ug
    "#{user_name}:#{user_group}"
  end

  def ssh_ugw_perm
    '0755'
  end

  def ssh_exec(remote_cmd_str, opts={})
    ssh_connect(opts)
    use_sudo = opts.fetch(:sudo, false)

    puts(" + #{remote_cmd_str}") if is_verbose or is_dryrun
    $stdout.flush
    exit_code      = 0
    output         = ''
    remote_cmd_str = 'sudo ' + remote_cmd_str if use_sudo
    unless is_dryrun
      @session.exec(remote_cmd_str) do |ch, stream, data|
        exit_code  = 1 if stream == :stderr
        output    += data
      end
      # now let the session do its thing while we wait!
      @session.loop
    end
    [ output, exit_code ]
  end
end