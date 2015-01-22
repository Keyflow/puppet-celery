class celery::rabbitmq($user="some_user",
                       $vhost="some_vhost",
                       $password="CHANGEME") {

  class { '::rabbitmq':
    package_apt_pin => 900,
    # use this for the time being remove once working
    delete_guest_user => false,
  }

  rabbitmq_user { $user:
    admin    => true,
    password => $password,
    provider => 'rabbitmqctl',
  }

  rabbitmq_vhost { $vhost:
    ensure => present,
    provider => 'rabbitmqctl',
  }

  rabbitmq_user_permissions { "$user@$vhost":
    configure_permission => '.*',
    read_permission      => '.*',
    write_permission     => '.*',
    provider => 'rabbitmqctl',
  }
}
