require 'test/unit'
require_relative File.join('..', 'ssh_helper')

class UnitTest_SshHelper < Test::Unit::TestCase
  def ssh_cred_jenkins
    @ssh_cred_jenkins ||= SshCredential.new(server_ip:'localhost', user_name:'jenkins', user_pwd:'123456')
  end

  def test_ssh_init_and_execute
    puts("test case #{__method__.to_s} - exec")

    ssh_session = nil
    assert_nothing_raised "new ssh connection raised an exception." do
      ssh_session = LinuxExecRemoteSsh.new(ssh_cred_jenkins, verbose:false)
    end
    output, exit_code = ssh_session.cmd_exec('ls -al', verbose:true)
    assert_equal(0, exit_code, "ERR: simple cmd returned exit code #{exit_code}")
    assert_not_equal('', output)
  end
end