class celery::beat(
  $ensure="running",
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
    require => User["${user}"],
  }
}
