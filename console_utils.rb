module ConsoleUtils
  def set_verbose(value=true)
    @verbose = value
  end

  def is_verbose
    @verbose ||= false
  end

  def set_dryrun(value=true)
    @dryrun = value
  end

  def is_dryrun
    @dryrun ||= false
  end
end