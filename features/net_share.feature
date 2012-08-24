Feature: Network Shares
  In order to automate the configuration of network shares
  As an ops practitioner
  I want to use Puppet to manage network shares

  Background:
    Given a user called "PuppetTest"
    Given a user called "PuppetTest2"
    Given a directory called "c:\puppet_test"
    Given a directory called "c:\puppet_test2"

  Scenario: No changes when present
    Given a net_share called "PuppetTest"
    And its "path" property is set to "c:\puppet_test"
    And its "remark" property is set to "PuppetTest"
    And its "maximumusers" property is set to "unlimited"
    And its "cache" property is set to "none"
    And its "permissions" property is set to "PuppetTest,full;PuppetTest2,full"
    And that's it
    Given the manifest
    """
      net_share {'PuppetTest':
        ensure        => present,
        path          => 'c:\puppet_test',
        remark        => 'PuppetTest',
        maximumusers  => unlimited,
        cache         => none,
        permissions   => ["${hostname}\\PuppetTest,full", "${hostname}\\PuppetTest2,full"],
      }
      """
    When puppet applies the manifest
    Then puppet has not made changes
    And puppet has not changed the "PuppetTest" net_share
    And puppet has left its "path" property set to "c:\puppet_test"
    And puppet has left its "remark" property set to "PuppetTest"
    And puppet has left its "maximumusers" property set to "unlimited"
    And puppet has left its "cache" property set to "none"
    And puppet has left its "permissions" property matching "^[^\\]+\\PuppetTest,full;[^\\]+\\PuppetTest2,full$"

  Scenario: No changes when present, case-insensitive
    Given a net_share called "PuppetTest"
    And its "path" property is set to "c:\puppet_test"
    And its "permissions" property is set to "PuppetTest,full;PuppetTest2,full"
    And that's it
    Given the manifest
    """
      net_share {'PuppetTest':
        ensure        => present,
        path          => 'c:\puppet_test',
        permissions   => ["${hostname}\\puppetTEST,full", "${hostname}\\PUPPETtest2,full"],
      }
      """
    When puppet applies the manifest
    Then puppet has not made changes
    And puppet has not changed the "PuppetTest" net_share
    And puppet has left its "path" property set to "c:\puppet_test"
    And puppet has left its "permissions" property matching "^[^\\]+\\PuppetTest,full;[^\\]+\\PuppetTest2,full$"

  Scenario: No changes when absent
    Given no net_share called "PuppetTest"
    Given the manifest
    """
      net_share {'PuppetTest':
        ensure        => absent,
      }
      """
    When puppet applies the manifest
    Then puppet has not made changes
    And puppet has not created the "PuppetTest" net_share

  Scenario: Create
    Given no net_share called "PuppetTest"
    Given the manifest
    """
      net_share {'PuppetTest':
        ensure        => present,
        path          => 'c:\puppet_test',
        remark        => 'PuppetTest',
        maximumusers  => unlimited,
        cache         => none,
        permissions   => ["${hostname}\\PuppetTest,full", "${hostname}\\PuppetTest2,full"],
      }
      """
    When puppet applies the manifest
    Then puppet has made changes
    And puppet has created the "PuppetTest" net_share
    And puppet has set its "path" property to "c:\puppet_test"
    And puppet has set its "remark" property to "PuppetTest"
    And puppet has set its "maximumusers" property to "unlimited"
    And puppet has set its "cache" property to "none"
    And puppet has set its "permissions" property to match "^[^\\]+\\PuppetTest,full;[^\\]+\\PuppetTest2,full$"

  Scenario: Create with minimum properties
    Given no net_share called "PuppetTest"
    Given the manifest
    """
      net_share {'PuppetTest':
        ensure        => present,
        path          => 'c:\puppet_test',
      }
      """
    When puppet applies the manifest
    Then puppet has made changes
    And puppet has created the "PuppetTest" net_share
    And puppet has set its "path" property to "c:\puppet_test"
    And puppet has set its "remark" property to ""
    And puppet has set its "maximumusers" property to "unlimited"
    And puppet has set its "cache" property to "manual"
    And puppet has set its "permissions" property to match "^Everyone,read$"

  Scenario: Delete
    Given a net_share called "PuppetTest"
    And its "path" property is set to "c:\puppet_test"
    And its "remark" property is set to "PuppetTest"
    And its "maximumusers" property is set to "unlimited"
    And its "cache" property is set to "none"
    And its "permissions" property is set to "PuppetTest,full;PuppetTest2,full"
    And that's it
    Given the manifest
    """
      net_share {'PuppetTest':
        ensure        => absent,
      }
      """
    When puppet applies the manifest
    Then puppet has made changes
    And puppet has deleted the "PuppetTest" net_share

  Scenario: Reconfigure
    Given a net_share called "PuppetTest"
    And its "path" property is set to "c:\puppet_test"
    And its "remark" property is set to "PuppetTest"
    And its "maximumusers" property is set to "unlimited"
    And its "cache" property is set to "none"
    And its "permissions" property is set to "PuppetTest,full;PuppetTest2,full"
    And that's it
    Given the manifest
    """
      net_share {'PuppetTest':
        ensure        => present,
        path          => 'c:\puppet_test2',
        remark        => 'PuppetTest2',
        maximumusers  => 1,
        cache         => manual,
        permissions   => ["${hostname}\\PuppetTest,full"],
      }
      """
    When puppet applies the manifest
    Then puppet has made changes
    And puppet has changed the "PuppetTest" net_share
    And puppet has changed its "path" property to "c:\puppet_test2"
    And puppet has changed its "remark" property to "PuppetTest2"
    And puppet has changed its "maximumusers" property to "1"
    And puppet has changed its "cache" property to "manual"
    And puppet has changed its "permissions" property to match "^[^\\]+\\PuppetTest,full$"
