class celery::beat(
  $ensure="running",
  $celerybeat_schedule_file="/var/run/celery/celerybeat-schedule",
  $custom_defaults={},
) {

  service { "celerybeat":
    hasrestart => true,
    ensure     => $ensure,
    subscribe  => [Class['celery::server'],
                   File['/etc/init.d/celerybeat'],
                   File['/etc/default/celerybeat']],
  }

  file { "/etc/init.d/celerybeat":
    ensure  => "present",
    content => template("celery/init.beat.sh"),
    mode    => "0755",
  }

  file { "/etc/default/celerybeat":
    ensure  => "present",
    content => template("celery/celerybeat_defaults.sh.erb"),
  }
}
