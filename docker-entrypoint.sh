#!/bin/sh -e

wait_for_mysql(){
  mysql_host=`echo $1 | cut -d '/' -f 3 | cut -d '@' -f 2`
  wait_for_service $mysql_host '3306'
}

wait_for_rabbitmq(){
  rabbitmq_host=`echo $1 | cut -d '/' -f 3 | cut -d '@' -f 2`
  wait_for_service $rabbitmq_host '5672'
}

wait_for_kafka(){
  kafka_host=`echo $1 | cut -d '/' -f 3`
  wait_for_service $kafka_host '9092'
}

wait_for_service(){
  SERVICE=`echo $1 | grep ':' || echo $1:$2 `
  until nc -vz $SERVICE > /dev/null; do
    >&2 echo "$SERVICE is unavailable - sleeping"
    sleep 2
  done
  >&2 echo "$SERVICE is up"
}

wait_for_tcp(){
  # var should follow the follwing strructure "$service_name:$service_ip_env_var_name:$service_port_env_var_name"
  # for instance postgress:DATABASE_HOST:DATABASE_PORT

  for var in "$@"
  do
    service_name=`echo $var | cut -d ':' -f1`
    service_ip_var=`echo $var | cut -d ':' -f2`
    service_port_var=`echo $var | cut -d ':' -f3`
    
    service_ip=`printenv | grep $service_ip_var | cut -d '=' -f2-`
    service_port=`printenv | grep $service_port_var | cut -d '=' -f2-`

    if [ -z $service_ip ] || [ -z $service_port ]; then
      echo "skipping wait for $service_name due to missing configs"
    else
      wait_for_service $service_ip $service_port
    fi
  done
}

wait_for(){
  # var should follow the follwing strructure "$service_name:$service_url_env_var_name"
  # for instance rabbitmq:RABBITMQ_URL mysql:DATABASE_URL kafka:KAFKA_HOST

  for var in "$@"
  do
    service_name=`echo $var | cut -d ':' -f1`
    service_url_var=`echo $var | cut -d ':' -f2`
    service_url=`printenv | grep $service_url_var | cut -d '=' -f2-`
    if [ -z $service_url ]; then
      echo "skipping wait for $service_name due to missing configs"
    else
      case $service_name in
        mysql) wait_for_mysql $service_url ;;
        rabbitmq) wait_for_rabbitmq $service_url ;;
        kafka) wait_for_kafka $service_url ;;
      esac
    fi
  done
}

case $1 in
  wait_for)
    shift
    wait_for "$@"
  ;;

  wait_for_tcp)
    shift
    wait_for_tcp "$@"
  ;;

  *) exec "$@" ;;
esac

exit 0
