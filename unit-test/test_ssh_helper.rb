require 'test/unit'
require_relative File.join('..', 'ssh_helper')

class UnitTest_SshConnectBase < Test::Unit::TestCase
  class SshConnectionTest
    include SshHelper

    def initialize
      @test_ip   = '192.168.2.100'
      @test_user = 'jenkins'
      @test_pwd  = '123456'

      set_ssh(@test_ip, @test_user, @test_pwd)
      set_verbose(true)
    end
  end

  def test_1_sshconn_login
    puts("test case #{__method__.to_s} - exec")

    ssh_conn    = SshConnectionTest.new
    ssh_session = nil
    assert_nothing_raised "ssh_connect raised an exception." do
      ssh_session = ssh_conn.ssh_connect
    end
    assert_not_nil(ssh_session, "ssh_connect returned nil session object.")
  end

  def test_2_ssh_conn_execute
    puts("test case #{__method__.to_s} - exec")

    ssh_conn    = SshConnectionTest.new
    ssh_session = ssh_conn.ssh_connect
    assert_not_nil(ssh_session, "ssh_connect returned nil session object.")

    # TODO: add remote connection execute ls in home dir
    output, exit_code = ssh_conn.ssh_exec('ls -al')
    assert_equal(exit_code, 0, "ssh_exec returned exit code #{exit_code}.")
    assert_block("output did not contain '..' folder reference") do
      output.include?('..')
    end
  end
end