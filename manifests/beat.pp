class celery::beat(
  $ensure="running",
  $user="celery",
  $group="celery",
) {

  service { "celerybeat":
    hasrestart => true,
    ensure     => $ensure,
    subscribe  => [Class['celery::server'], File['/etc/init.d/celerybeat']],
  }

  file { "/etc/init.d/celerybeat":
    ensure  => "present",
    content => template("celery/init.beat.sh"),
    mode    => "0755",
    owner   => $user,
    group   => $group,
    require => User["${user}"],
  }
}
