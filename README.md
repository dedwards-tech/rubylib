# README: `rubylib`

This is my latest attempt to consoldate common ruby functions into modules and classes that 
are simple to use and extend.  I'm new to modules so go easy on me while I understand the
tradeoffs.

## Design Goals

* Use of modules to flatten class hierarchy, and simplify the extensibility of instance variables.
* Maximize re-use by removing use case assumptions and be very specific about module operations.

## Modules

* `credentials.rb` - defines a dictionary structure and set of helper methods around `@cred_items` instance variable.
    * `CredentialBase` - basic credential initializers and output generators for .json and string.
    * `UserLoginCredential` - extends dictionary to include basic user name, password login credentials.
    * `SshCredential` - extends dictionary to include server address.
* `ssh_helper.rb` - basic ssh connectivity methods and session management module.
    * `SshHelper` - defines basic host and user login methods for connecting to a remote host, as well as
      remote host shell execution methods.
* `scp_helper.rb` - basic SSH copy (SCP) module.
    * `ScpHelper` - basic SCP connect and file upload / download methods.
* `zip_helper.rb` - file compression helpers.
    * `ZipHelper` - wrapper around `rubyzip` for simplifying .zip file decompress.