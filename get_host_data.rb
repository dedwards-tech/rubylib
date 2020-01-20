require 'json'
require_relative 'linux_exec_helper'
require_relative 'ssh_helper'

@command_list = [
    { :name => 'KERNEL_VERSION',   :cmd_str => 'uname -a' },
    { :name => 'LSPCI_VERSION',    :cmd_str => 'lspci --version' },
    { :name => 'LSPCI_DBDF_NVME',  :cmd_str => 'lspci -D | grep Non-' },
    { :name => 'LSPCI_D_VERBOSE',  :cmd_str => 'lspci -Dvvv' },
    { :name => 'NVME_DEV_NODES',   :cmd_str => 'find /dev -name nvme* -type c' },
    { :name => 'NVME_NS_NODES',    :cmd_str => 'find /dev -name nvme* -type b' },
    { :name => 'UDEVADM_VERSION',  :cmd_str => 'udevadm --version' },
    { :name => 'UDEVADM_INFO_Q_NVME', :cmd_str => 'udevadm info -q all -n {}', :deps => [ 'NVME_DEV_NODES' ] },
    { :name => 'UDEVADM_INFO_Q_DBDF', :cmd_str => 'udevadm info -q all -p /sys/bus/pci/devices/{}', :deps => [ 'LSPCI_DBDF_NVME' ] }
]

@commands_no_deps = [
    { :name => 'KERNEL_VERSION',   :cmd_str => 'uname -a' },
    { :name => 'LSPCI_VERSION',    :cmd_str => 'lspci --version' },
    { :name => 'LSPCI_DBDF_NVME',  :cmd_str => 'lspci -D | grep Non-' },
    { :name => 'LSPCI_D_VERBOSE',  :cmd_str => 'lspci -Dvvv' },
    { :name => 'NVME_DEV_NODES',   :cmd_str => 'find /dev -name nvme* -type c' },
    { :name => 'NVME_NS_NODES',    :cmd_str => 'find /dev -name nvme* -type b' },
    { :name => 'UDEVADM_VERSION',  :cmd_str => 'udevadm --version' },
]

def get_result(name)
  result = []
  @command_list.each do |cmd_data|
    if cmd_data[:name] == name
      result = cmd_data.fetch(:result, [])
    end
  end
  result
end

class JenkinsSshConnector
  include SshHelper

  def initialize(ip_address, verbose:false)
    test_ip   = ip_address
    test_user = 'jenkins'
    test_pwd  = '123456'

    set_ssh(test_ip, test_user, test_pwd)
    set_verbose(verbose)
  end
end

lin_ex = LinuxExecHelper.new(verbose:true)

@commands_no_deps.each do |cmd_data|
  cmd_name  = cmd_data[:name]
  cmd_str   = cmd_data[:cmd_str]
  deps      = cmd_data.fetch(:deps, nil)
  puts("*** Name: #{cmd_name} - cmd: #{cmd_str}")
  if deps
    # Command with input dependencies
    # NOTE: dependency results must be lists of things (an array)
    ret_result = []
    cmd_data.merge!({ :result => ret_result })
    get_result(deps).each do |result|
      # replace every occurrence of {} with the result
      # NOTE: only one string can be substituted
      this_cmd = cmd_str.gsub('{}', result)
      out_str, exit_code = lin_ex._exec(this_cmd)
      puts("*** OUT:\n#{out_str}")
      puts("")
      if exit_code == 0
        ret_result.push(out_str)
      end
    end
  else
    # Single command, no dependencies
    out_str, exit_code = lin_ex._exec(cmd_str)
    puts("*** OUT:\n#{out_str}")
    puts("")
    if exit_code == 0
      ret_result = out_str
      case cmd_name
      when 'LSPCI_VERSION'
        ret_result = out_str.split(' ').last
      when 'LSPCI_DBDF_NVME', 'NVME_DEV_NODES', 'NVME_NS_NODES'
        ret_result = out_str.split("\n")
      end
      cmd_data.merge!({ :out_raw => out_str, :result => ret_result })
    end
  end
end

puts(@commands_no_deps.to_json)