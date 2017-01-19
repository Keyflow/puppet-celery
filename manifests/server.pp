class celery::server($version='4.0.2',
                     $ensure='running',
                     $python_env="/usr",
                     $celery_env="/usr/local",
                     $proroot="",
                     $broker_prefix="amqp",
                     $broker_user=undef,
                     $broker_suffix=undef,
                     $broker_password=undef,
                     $broker_hosts=["localhost"],
                     $backend_prefix="amqp",
                     $backend_user=undef,
                     $backend_suffix=undef,
                     $backend_password=undef,
                     $backend_hosts=["localhost"],
                     $backend_url=undef,
                     $user="celery",
                     $group="celery",
                     $celeryconfig_dir = '/var/celery',
                     $concurrency = '8',
                     $pypath_appendage = '',
                     $environment_vars = {},
                     $celery_app = '',
                     $extra_opts='') {
  if ! defined('python') {
    class { 'python':
      version => 'system',
      pip     => 'present',
      dev     => 'present',
    }
  } else {
    include 'python'
  }
  python::pip { 'celery':
    ensure => $version,
    require => Class['python'],
  } ->
  service { "celeryd":
    hasrestart => true,
    ensure => $ensure,
    require => [File["/var/log/celery"],
                File["/var/run/celery"]
                ],
    subscribe => [File["/etc/init.d/celeryd"],
                  File["/etc/default/celeryd"],
                  File["${celeryconfig_dir}/celeryconfig.py"]
                  ],
  }

  file { "/etc/default/celeryd":
    ensure => "present",
    content => template("celery/celery_defaults.sh.erb"),
  }

  file { "/etc/init.d/celeryd":
    ensure => "present",
    content => template("celery/init.d.sh"),
    mode => "0755",
  }

  if ! defined( User["${user}"] ) {
    user { "${user}":
      ensure     => 'present',
      gid        => "${group}",
      managehome => true,
      require    => Class['python'],
    }
  }
  if ! defined( File["${celeryconfig_dir}"] ) {
    file { "${celeryconfig_dir}":
      ensure  => "directory",
      owner   => $user,
      group   => $group,
      require => User["${user}"],
    }
  }

  file { "${celeryconfig_dir}/celeryconfig.py":
    ensure  => "present",
    content => template("celery/celeryconfig.py"),
    owner   => $user,
    group   => $group,
    require => File["${celeryconfig_dir}"],
    mode    => '0640',
  }

  file { "/var/log/celery":
    ensure  => "directory",
    owner   => $user,
    group   => $group,
    require => User[$user],
  }

  file { "/var/run/celery":
    ensure  => "directory",
    owner   => $user,
    group   => $group,
    require => User[$user],
  }
}
