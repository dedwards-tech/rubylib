require 'test/unit'
require_relative File.join('..', 'linux_exec')

class UnitTest_LinuxExecHelper < Test::Unit::TestCase
  def test_1_local_shell
    loc_sh = LinuxExecHelper.new(verbose:true)
    assert_not_nil(loc_sh.cmd_exec, "ERR: cmd_exec not initialized.")
    assert_not_empty(loc_sh.version, "ERR: linux kernel version not initialized.")
  end

  def test_2_multi_process
  end
end