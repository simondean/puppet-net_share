puppet-net_share
================

Puppet module for configuring Windows network shares.

Note: When making changes to a share, the module will first destroy the share and then recreate it. This is due to a limitation with the “net share” command where permissions cannot be removed from an existing share.

The module is available from: http://forge.puppetlabs.com/simondean/net_share


## Pre-requisites

- Windows
- Puppet installed via the Windows Installer
- On Windows Server, the File Sharing role needs to be enabled


## Example Usage

```puppet
      net_share {'PuppetTest':
        ensure        => present,
        path          => 'c:\puppet_test',
        remark        => 'PuppetTest',
        maximumusers  => unlimited,
        cache         => none,
        permissions   => ["${hostname}\\PuppetTest,full", "${hostname}\\PuppetTest2,full"],
      }
```


## Tested on:

- Tested against the Windows installer version of Puppet on Windows 7 64bit. 

If using the rake build scipt, you need to use Ruby 1.9.2


## Copyright

Copyright (c) 2012 Simon Dean. See LICENSE for details.
