require 'test/unit'
require_relative File.join('..', 'ssh_helper')

class UnitTest_SshCredential < Test::Unit::TestCase

  def test_1_ssh_credential_init_delayed
    puts("test case #{__method__.to_s} - exec")

    # test with initialization via set_ssh() method
    ssh_cred = SshCredential.new()

    # TODO: add chk_ssh_credential - it should raise an exception about server_ip missing

    ssh_cred.set_ssh('192.168.1.100', 'jenkins', '123456')
    assert_not_nil(ssh_cred.server_ip, "uninitialized server_ip key")
    assert_not_nil(ssh_cred.user_name, "uninitialized user_name key")
    assert_not_nil(ssh_cred.user_pwd, "uninitialized user_pwd key")
    assert_not_nil(ssh_cred.user_group, "uninitialized user_group key")

    assert_equal(ssh_cred.server_ip, '192.168.1.100', "Invalid server_ip value.")
    assert_equal(ssh_cred.user_name, 'jenkins', "Invalid user_name value.")
    assert_equal(ssh_cred.user_pwd, '123456', "Invalid user_pwd value.")
    assert_equal(ssh_cred.user_group, 'jenkins', "Invalid default user_group value.")
  end

  def test_2a_ssh_credential_init_new
    puts("test case #{__method__.to_s} - exec")

    # test with instance initializer using server_ip only
    ssh_cred = SshCredential.new(server_ip:'192.168.100')
    assert_not_nil(ssh_cred.server_ip, "uninitialized server_ip key")

    # TODO: add chk_ssh_credential - it should raise an exception about user_name / pwd missing

    ssh_cred.set_user_login('jenkins', '123456')
    assert_not_nil(ssh_cred.user_name, "uninitialized user_name key")
    assert_not_nil(ssh_cred.user_pwd, "uninitialized user_pwd key")
    assert_not_nil(ssh_cred.user_group, "uninitialized user_group key")

    assert_equal(ssh_cred.user_name, 'jenkins', "Invalid user_name value.")
    assert_equal(ssh_cred.user_pwd, '123456', "Invalid user_pwd value.")
    assert_equal(ssh_cred.user_group, 'jenkins', "Invalid default user_group value.")

    # this should NOT assert
    # TODO: add use of assert_not_raised
    ssh_cred.chk_ssh_credential
  end

  def test_2b_ssh_credential_init_new
    puts("test case #{__method__.to_s} - exec")

    # test with instance initializer using server_ip only
    ssh_cred = SshCredential.new(server_ip:'192.168.100', user_name:'jenkins', user_pwd:'123456')
    assert_not_nil(ssh_cred.server_ip, "uninitialized server_ip key")

    assert_equal(ssh_cred.user_name, 'jenkins', "Invalid user_name value.")
    assert_equal(ssh_cred.user_pwd, '123456', "Invalid user_pwd value.")
    assert_equal(ssh_cred.user_group, 'jenkins', "Invalid default user_group value.")

    # this should NOT assert
    # TODO: add use of assert_not_raised
    ssh_cred.chk_ssh_credential
  end

  def test_3_ssh_credential_from_hash
    puts("test case #{__method__.to_s} - exec")

    test_h = { :user_name => 'johnny', :user_pwd => '8675309', :server_ip => '192.168.1.102', :ignore_me => 'testing123' }
    ssh_cred = SshCredential.new()
    ssh_cred.from_h(test_h)
    assert_equal('192.168.1.102', ssh_cred.server_ip, "Invalid server_ip value.")
    assert_equal('johnny', ssh_cred.user_name, "Invalid user_name value.")
    assert_equal('8675309', ssh_cred.user_pwd, "Invalid user_pwd value.")
    assert_nil(ssh_cred.user_group, "Invalid default user_group value.")
    assert_nil(ssh_cred.credential.fetch(:ignore_me, nil), "Failed to ignore hash element :ignore_me.")
  end

  def test_4_ssh_credential_from_json
    puts("test case #{__method__.to_s} - exec")

    json_str = '{ "user_name": "joeblow", "user_pwd": "7654321", "user_group": "double", "server_ip": "192.168.1.101"}'
    ssh_cred = SshCredential.new()
    ssh_cred.from_json(json_str)
    assert_equal('192.168.1.101', ssh_cred.server_ip, "Invalid server_ip value.")
    assert_equal('joeblow', ssh_cred.user_name, "Invalid user_name value.")
    assert_equal('7654321', ssh_cred.user_pwd, "Invalid user_pwd value.")
    assert_equal('double',  ssh_cred.user_group, "Invalid default user_group value.")
  end

  def test_5_ssh_credential_to_json
    puts("test case #{__method__.to_s} - exec")

    ssh_cred = SshCredential.new()
    ssh_cred.set_ssh('192.168.1.103', 'dave', '2020vision', 'joeblow')
    json_str = ssh_cred.to_json
    assert_block("server_ip missing from json str.") { json_str.include?('192.168.1.103') }
    assert_block("user_name missing from json str.") { json_str.include?('dave') }
    assert_block("user_pwd missing from json str.") { json_str.include?('2020vision') }
    assert_block("user_group missing from json str.") { json_str.include?('joeblow') }
  end

  def test_6_ssh_credential_to_s
    puts("test case #{__method__.to_s} - exec")

    ssh_cred = SshCredential.new()
    ssh_cred.set_ssh('192.168.1.104', 'jenkins', '123456', 'appleseed')
    assert_block("to_s missing user_name") { ssh_cred.to_s.include?('jenkins') }
    assert_block("to_s missing user_group") { ssh_cred.to_s.include?('(appleseed)') }
    assert_block("to_s missing server_ip") { ssh_cred.to_s.include?('192.168.1.104') }
  end
end