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

  def set_common_opts(**opts)
    @verbose  = opts.fetch(:verbose,  verbose)
    @dry_run  = opts.fetch(:dryrun,   dryrun)
    @use_sudo = opts.fetch(:use_sudo, use_sudo)
  end

  def copy_common_opts(**opts)
    {
      :verbose  => opts.fetch(:verbose,  verbose),
      :dry_run  => opts.fetch(:dryrun,   dryrun),
      :use_sudo => opts.fetch(:use_sudo, use_sudo),
    }
  end
end

