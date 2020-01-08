require_relative File.join('.', 'ssh_helper')

module ScpHelper
  include SshHelper

  def scp_connect(opts={})
    begin
      @scp_session ||= Net::SCP.new(ssh_connect(opts))
    rescue => ex
      @scp_session = nil
      puts("ERR: cannot establish SCP session with host #{server_ip}, response #{ex.to_s}")
    end
    @scp_session
  end

  def scp_disconnect
    # AFIK nothing to close for scp session but we need to nullify the scp session
    @scp_session = nil unless @scp_session.nil?
    ssh_disconnect
  end

  # set remote file ownership and permissions with proper print outs (verbose) and dry-run support.
  def scp_set_folder_perms(remote_folder)
    # set proper permissions for remote host (allowing for client override)
    puts(" -> setting remote ownership on host #{server_ip} folder #{remote_folder}") if is_verbose or is_dryrun
    $stdout.flush
    output, exit_code1 = ssh_exec("chown -R #{ssh_owner_ug} #{remote_folder}")
    puts("ERR: #{output}") unless exit_code == 0

    output, exit_code2 = ssh_exec("chmod -R #{ssh_ugw_perm} #{remote_folder}")
    puts("ERR: #{output}") unless exit_code == 0
    (exit_code1 == 0) and (exit_code2 == 0)
  end

  def scp_set_file_perms(remote_file)
    # set proper permissions for remote host (allowing for client override)
    puts(" -> setting remote ownership on host #{server_ip} file #{remote_file}") if verbose or dryrun
    $stdout.flush
    output, exit_code1 = ssh_exec("chown #{ssh_owner_ug} #{remote_file}")
    puts("ERR: #{output}") unless exit_code == 0

    output, exit_code2 = ssh_exec("chmod #{ssh_ugw_perm} #{remote_file}")
    puts("ERR: #{output}") unless exit_code == 0
    (exit_code1 == 0) and (exit_code2 == 0)
  end

  def scp_dir_exist?(remote_dir)
    cmd_str = "if [ -d \"#{remote_dir}\" ]; then echo 1; else echo 0; fi"
    output, exit_code = ssh_exec(cmd_str)
    if exit_code == 0
      result = output.strip().chomp().to_s == '1'
    else
      result = false
    end
    result
  end

  def scp_file_exist?(remote_file)
    cmd_str = "if [ -f \"#{remote_file}\" ]; then echo 1; else echo 0; fi"
    output, exit_code = ssh_exec(cmd_str)
    if exit_code == 0
      result = output.strip().chomp().to_s == '1'
    else
      result = false
    end
    result
  end

  def scp_mkdir_p(remote_folder)
    output, exit_code = ssh_exec("mkdir -p #{remote_folder}")
    puts("ERR: #{output}") unless exit_code == 0
    scp_set_folder_perms(remote_folder)
    exit_code == 0
  end

  # NOTE: this function only supports transfer to a remote folder, it does NOT support renaming of the
  #       file on the target.
  def scp_upload(src_file, remote_folder)
    scp_connect
    success = false
    unless @scp_session.nil? or is_dryrun
      begin
        scp_mkdir_p(remote_folder) unless scp_dir_exist?(remote_folder)
        rem_file = File.join(remote_folder, File.basename(src_file)).to_s
        @scp_session.upload!(src_file, rem_file)
        # some files don't take permissions of their parent folder, not sure why!
        # forcing file permissions as well!
        scp_set_file_perms(rem_file)
        success = true
      rescue => ex
        puts("ERR: failed to upload #{src_file} to remote #{remote_folder}: response #{ex.to_s}")
        $stdout.flush
      end
      ssh_disconnect
    end
    success
  end

  def scp_download(remote_file, local_folder, local_perm='0755')
    scp_connect
    success = false
    unless @scp_session.nil? or is_dryrun
      begin
        FileUtils.mkdir_p(local_folder, :mode => local_perm) unless Dir.exist?(local_folder)
        @scp_session.download!(remote_file, local_folder)
        success = true
      rescue => ex
        puts("ERR: download #{remote_file} failed, host #{server_ip} response: #{ex.to_s}")
        $stdout.flush
      end
    end
    ssh_disconnect
    success
  end
end