# README: `rubylib`

Completed rev 0.10 1/24/2020 - unit tests functional but basic.  Need more use cases
  to round out the design and implementation but its working well at the moment.

I've refactored my common ruby coding scripts to make use of modules and added at least
the minimum unit test capabilities to all the scripts - they should be 1:1 with ruby 
files.  I've attempted to make shell execution extensible between local linux shell and
remote ssh shell so they appear seamless in their use model.  As such, refactoring included
the ssh and scp wrappers.

## Design Goals

* Use of modules to flatten class hierarchy, and simplify the extensibility of instance variables.
* Maximize re-use by removing use case assumptions and be very specific about module operations.

## Modules

* `credentials.rb` - defines a dictionary structure and set of helper methods around `@cred_items` instance variable.
    * `CredentialBase` - basic credential initializers and output generators for .json and string.
    * `UserLoginCredential` - extends dictionary to include basic user name, password login credentials.
* `shell_exec.rb` - common interface and base implementation of a shell factory.
    * `ShellExec` - module implementation for basic shell execution.
* `ssh_helper.rb` - basic ssh connectivity methods and session management module.
    * `SshHelper` - defines basic host and user login methods for connecting to a remote host, as well as
      remote host shell execution methods.
    * `SshCredential` - extends dictionary to include server address.
    * `SshExecHelper` - extend ShellExec to support shell execution over ssh.
* `scp_helper.rb` - basic SSH copy (SCP) module.
    * `ScpHelper` - basic SCP connect and file upload / download methods.
* `zip_helper.rb` - file compression helpers.
    * `ZipHelper` - wrapper around `rubyzip` for simplifying .zip file decompress.
* `timestamp_ns.rb` - floating point, accurate to the nanosecond time stamp conversion and math helper.
    * `TimestampNS` - Basic class for using string, integer, floating point and `Time` based time objects
    for the purpose of correlating timestamped data to events and being able to add, subtract time deltas.
    
### WORK IN PROGRESS    
    
* `linux_udevadm.rb` - udev admin manager helpers, for collecting udev device details.
    * `get_host_data.rb` - helper for collecting platform data collection simulation and re-use.
      STILL WIP - NEED TO TEST REMOTE GATHERING OF UDEV AND PCIE INFORMATION FOR UNIT TEST
* `nvmecli_helper.rb` - work in progress shell extensions for linux nvme-cli tools for parsing and using
   NVMe SSD's and collecting system information about their configuration details.
   STILL WIP - CONVERT TO USING SHELLEXEC AND DERIVATIVE IMPLEMENTATIONS
  
