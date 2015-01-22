class celery::server($venv="system-wide",
                     $proroot="",
                     $venvowner="root",
                     $requirements="/tmp/celery-requirements.txt",
                     $requirements_template="celery/requirements.txt",
                     $initd_template="celery/init.d.sh",
                     $defaults_template="celery/celery_defaults.sh.erb",
                     $broker_user="some_user",
                     $broker_vhost="some_vhost",
                     $broker_password="CHANGEME",
                     $broker_host="localhost",
                     $broker_port="5672",
                     $user="celery",
                     $usergroup="celery",
                     $concurrency = '8',
                     $pypath_appendage = '',
                     $extra_opts) {

  file { $requirements:
    ensure => "present",
    content => template($requirements_template),
  }

  file { "/etc/default/celeryd":
    ensure => "present",
    content => template($defaults_template),
  }

  file { "/etc/init.d/celeryd":
    ensure => "present",
    content => template($initd_template),
    mode => "0755",
  }
  
  #group { $usergroup:
  #  ensure => present
  #}

  #user { $user:
  #  ensure => present,
  #  gid    => $usergroup
  #} ->

  file { "/var/celery":
    ensure   => "directory",
    owner    => $user,
    require  => User[$user]
  }

  file { "/var/log/celery":
    ensure => "directory",
    owner  => $user
  }

  file { "/var/run/celery":
    ensure => "directory",
    owner  => $user
  }

  python::requirements { $requirements:
    virtualenv => $venv,
    owner => $venvowner,
    group => $venvowner,
  } ->
  service { "celeryd":
    hasrestart => true,
    ensure => "running",
    require => [File["/etc/init.d/celeryd"],
                File["/etc/default/celeryd"],
                File["/var/log/celery"],
                File["/var/run/celery"],
                Class["rabbitmq::service"], ],
  }
}
