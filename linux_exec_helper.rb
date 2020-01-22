require_relative 'shell_exec'

class LinuxExecHelper
  include ShellExec
  attr_reader :version

  def initialize(**opts)
    # default is to create a local shell exec, you must pass one in if you
    # want some other connection type - like ssh
    new_shell(verbose:true, dryrun:false, use_sudo:true, **opts)

    # get the kernel version
    ret_str, exit_code = cmd_exec("uname -a")
    if exit_code == 0
      @version = ret_str.strip.chomp
    else
      @version = 'unknown'
    end
  end
end