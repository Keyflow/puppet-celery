class celery::server($version='4.0.2',
                     $python_env="/usr",
                     $celery_env="/usr/local",
                     $proroot="",
                     $broker_prefix="amqp",
                     $broker_user=undef,
                     $broker_vhost=undef,
                     $broker_password=undef,
                     $broker_host="localhost",
                     $broker_port=undef,
                     $backend_prefix="amqp",
                     $backend_user=undef,
                     $backend_suffix=undef,
                     $backend_password=undef,
                     $backend_host="localhost",
                     $backend_port=undef,
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
    ensure => "running",
    require => [File["/etc/init.d/celeryd"],
                File["/etc/default/celeryd"],
                File["/var/log/celery"],
                File["/var/run/celery"],
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
 
  file { "${celeryconfig_dir}":
    ensure   => "directory",
    owner    => $user,
    group    => $group,
  } ->
  file { "${celeryconfig_dir}/celeryconfig.py":
    ensure  => "present",
    content => template("celery/celeryconfig.py"),
    owner   => $user,
    group   => $group,
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
