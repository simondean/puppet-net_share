net_share {'PuppetTest':
  ensure        => present,
  path          => 'c:\puppet_test',
  remark        => 'PuppetTest',
  maximumusers  => unlimited,
  cache         => none,
  permissions   => ["host\\PuppetTest,full", "host\\PuppetTest2,full"],
}
