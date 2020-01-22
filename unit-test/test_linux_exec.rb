require 'test/unit'
require_relative File.join('..', 'linux_exec_helper')

class UnitTest_LinuxExecHelper < Test::Unit::TestCase
  def test_1_local_shell
    loc_sh = LinuxExecHelper.new(verbose:true)
    assert_not_empty(loc_sh.version, "ERR: linux kernel version not initialized.")
  end

  def test_2_multi_process
    # TODO: create a multi-threaded application and execute multiple things at once
  end
end