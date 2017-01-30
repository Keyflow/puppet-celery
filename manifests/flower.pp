class celery::flower(
  $version="latest",
  $ensure="running",
  $custom_defaults=undef,
) {

  if ! defined('python') {
    class { 'python':
      version => 'system',
      pip     => 'present',
      dev     => 'present',
    }
  } else {
    include 'python'
  }
  python::pip { 'flower':
    ensure  => $version,
    require => Class['python'],
  } ->
  service { "flower":
    hasrestart => true,
    ensure     => $ensure,
    require    => File['/etc/init.d/flower'],
  }

  file { "/etc/init.d/flower":
    ensure  => "present",
    content => template("celery/init.flower.sh"),
    mode    => "0755",
  }

  if $custom_defaults!=undef {
    file { "/etc/default/flower":
      ensure  => "present",
      content => template("celery/flower_defaults.sh.erb"),
      notify  => Service['flower'],
    }
  }
}
