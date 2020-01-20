module CommonConsoleVars
  def verbose
    @verbose ||= false
  end

  def dryrun
    @dryrun ||= false
  end

  def use_sudo
    @use_sudo ||= false
  end

  def is_verbose
    verbose == true
  end

  def is_dryrun
    dryrun == true
  end

  def is_sudo
    use_sudo == true
  end
end

