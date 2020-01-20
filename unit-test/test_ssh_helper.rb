require 'test/unit'
require_relative File.join('..', 'ssh_helper')

class UnitTest_SshConnectBase < Test::Unit::TestCase
  def ssh_cred
    @ssh_cred ||= SshCredential.new(server_ip:'192.168.2.100', user_name:'jenkins', user_pwd:'123456')
  end

  def test_ssh_init_and_execute
    puts("test case #{__method__.to_s} - exec")

    ssh_session = nil
    assert_nothing_raised "new ssh connection raised an exception." do
      ssh_session = LinuxExecRemoteSsh.new(ssh_cred, verbose:true)
    end
    output, exit_code = ssh_session._exec('ls -al')
    assert_equal(0, exit_code, "ERR: simple cmd returned exit code #{exit_code}")
    assert_not_equal('', output)
  end
end