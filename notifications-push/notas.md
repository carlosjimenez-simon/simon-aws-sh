Mira que estoy ejecutando rabbitMQ y sube bien. Pero lo que estoy tratando de hacer es que funcione con keycloak.
Sube, pero no me envia a la pantalla de Keycloak, sino que me saca su pantalla de login. La configuracon es asi.

sh-5.2$ sudo cat deploy-rabbit.sh 
#!/bin/bash

# 1. Ubicación
BASE_DIR="/opt/simon/rabbitmq"
cd $BASE_DIR

echo "----------------------------------------------------------"
echo "🚀 INICIANDO DESPLIEGUE DE RABBITMQ"
echo "----------------------------------------------------------"

# 2. Obtener la IP Privada real desde los metadatos de AWS
# Primero pedimos el Token (Seguridad IMDSv2)
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
export RABBIT_HOSTNAME=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-hostname)

# 3. Impresión para validación manual
echo "📍 HOSTNAME DETECTADO POR AWS: $RABBIT_HOSTNAME"
echo "👉 Compare este valor con el 'Private IP address' en su consola de EC2."
echo "----------------------------------------------------------"


# 3. Recuperar el JSON del Secret Manager
echo "🔐 Recuperando secretos desde AWS..."
SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id dev/push-notifications/rabbit --query SecretString --output text --region us-east-1)

# 4. Extraer variables del JSON (usando los nombres exactos de su imagen)
export RABBIT_USER=$(echo $SECRET_JSON | jq -r .rabbitmq_username)
export RABBIT_PASS=$(echo $SECRET_JSON | jq -r .rabbitmq_password)
export ERLANG_COOKIE=$(echo $SECRET_JSON | jq -r .erlang_cookie)

echo "📍 Hostname: $RABBIT_HOSTNAME"
echo "👤 Usuario: $RABBIT_USER"
echo "✅ Datos cargados correctamente."


# 5. Reiniciar el servicio
echo "🛑 Bajando contenedores existentes..."
sudo -E docker-compose down --remove-orphans

echo "⚡ Levantando RabbitMQ Server..."
sudo -E docker-compose up -d

# 6. Confirmación final
echo "----------------------------------------------------------"
if [ "$(sudo docker ps -q -f name=rabbitmq_server)" ]; then
    echo "✅ TODO MELO: RabbitMQ corriendo con Hostname: $RABBIT_HOSTNAME"
else
    echo "❌ ERROR: El contenedor no subió. Revise 'docker logs rabbitmq_server'"
fi
echo "----------------------------------------------------------"
sh-5.2$ sudo cat docker-compose.yml 
services:
  rabbitmq:
    image: rabbitmq:3.12-management-alpine
    container_name: rabbitmq_server
    restart: always
    hostname: ${RABBIT_HOSTNAME}
    environment:
      - RABBITMQ_DEFAULT_USER=${RABBIT_USER}
      - RABBITMQ_DEFAULT_PASS=${RABBIT_PASS}
      - RABBITMQ_ERLANG_COOKIE=${ERLANG_COOKIE}
      - RABBITMQ_USE_LONGNAME=true
      - RABBITMQ_NODENAME=rabbit@${RABBIT_HOSTNAME}
      # CONFIGURACIÓN OAUTH2 (Backend)
      - RABBITMQ_AUTH_BACKENDS=rabbit_auth_backend_oauth2,internal
      - RABBITMQ_AUTH_OAUTH2_RESOURCE_SERVER_ID=rabbit-server
      - RABBITMQ_AUTH_OAUTH2_JWKS_URL=http://internal-sm-dev-refactor-apigw-lb-1085759648.us-east-1.elb.amazonaws.com:8080/realms/NotificationsPush/protocol/openid-connect/certs
      - RABBITMQ_AUTH_OAUTH2_ISSUER=http://internal-sm-dev-refactor-apigw-lb-1085759648.us-east-1.elb.amazonaws.com:8080/realms/NotificationsPush
      # CONFIGURACIÓN DEL CLUSTER Y RELAJACIÓN DE SEGURIDAD (CSP)
      - RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS=-rabbit cluster_formation_strategy rabbit_peer_discovery_aws -rabbit peer_discovery_backend aws -rabbit cluster_formation_aws_region "us-east-1" -rabbit cluster_formation_aws_tag_key "iam-rabbit-mq-tag-key" -rabbit cluster_formation_aws_tag_value "iam-rabbit-mq-tag-value"
    ports:
      - "5672:5672"
      - "15672:15672"
      - "4369:4369"
      - "25672:25672"
    volumes:
      - ./config/rabbitmq.conf:/etc/rabbitmq/rabbitmq.conf:ro
      - ./config/enabled_plugins:/etc/rabbitmq/enabled_plugins:ro
      - rabbitmq_data:/var/lib/rabbitmq/mnesia/

volumes:
  rabbitmq_data:
sh-5.2$ sudo cat ./config/rabbitmq.conf 
loopback_users.guest = false
listeners.tcp.default = 5672
management.tcp.port = 15672

# --- CONFIGURACIÓN OAUTH2 ---
management.oauth_enabled = true
management.oauth_client_id = rabbit-server
# Volvemos a provider_url pero SIN el /auth al final, que es como el plugin lo reconstruye
management.oauth_provider_url = http://internal-sm-dev-refactor-apigw-lb-1085759648.us-east-1.elb.amazonaws.com:8080/realms/NotificationsPush

# --- RELAJAR CSP (Solo la política) ---
management.csp.policy = script-src 'self' 'unsafe-eval' 'unsafe-inline'; object-src 'self'; connect-src 'self' http://internal-sm-dev-refactor-apigw-lb-1085759648.us-east-1.elb.amazonaws.com:8080
sh-5.2$ 



El log que me arroja es este

sh-5.2$ sudo docker ps
CONTAINER ID   IMAGE                             COMMAND                  CREATED         STATUS         PORTS                                                                                                                                                                                                                      NAMES
eb803c2dc71e   rabbitmq:3.12-management-alpine   "docker-entrypoint.s…"   5 minutes ago   Up 5 minutes   0.0.0.0:4369->4369/tcp, :::4369->4369/tcp, 5671/tcp, 0.0.0.0:5672->5672/tcp, :::5672->5672/tcp, 15671/tcp, 0.0.0.0:15672->15672/tcp, :::15672->15672/tcp, 0.0.0.0:25672->25672/tcp, :::25672->25672/tcp, 15691-15692/tcp   rabbitmq_server
sh-5.2$ sudo docker logs rabbitmq_server
2026-02-24 20:32:54.957356+00:00 [warning] <0.131.0> Overriding Erlang cookie using the value set in the environment
2026-02-24 20:32:56.019827+00:00 [notice] <0.44.0> Application syslog exited with reason: stopped
2026-02-24 20:32:56.019898+00:00 [notice] <0.229.0> Logging: switching to configured handler(s); following messages may not be visible in this log output
2026-02-24 20:32:56.020292+00:00 [notice] <0.229.0> Logging: configured log handlers are now ACTIVE
2026-02-24 20:32:56.121894+00:00 [info] <0.229.0> ra: starting system quorum_queues
2026-02-24 20:32:56.121959+00:00 [info] <0.229.0> starting Ra system: quorum_queues in directory: /var/lib/rabbitmq/mnesia/rabbit@ip-10-20-11-113.ec2.internal/quorum/rabbit@ip-10-20-11-113.ec2.internal
2026-02-24 20:32:56.152501+00:00 [info] <0.260.0> ra system 'quorum_queues' running pre init for 0 registered servers
2026-02-24 20:32:56.157333+00:00 [info] <0.261.0> ra: meta data store initialised for system quorum_queues. 0 record(s) recovered
2026-02-24 20:32:56.164320+00:00 [notice] <0.266.0> WAL: ra_log_wal init, open tbls: ra_log_open_mem_tables, closed tbls: ra_log_closed_mem_tables
2026-02-24 20:32:56.169358+00:00 [info] <0.229.0> ra: starting system coordination
2026-02-24 20:32:56.169391+00:00 [info] <0.229.0> starting Ra system: coordination in directory: /var/lib/rabbitmq/mnesia/rabbit@ip-10-20-11-113.ec2.internal/coordination/rabbit@ip-10-20-11-113.ec2.internal
2026-02-24 20:32:56.170204+00:00 [info] <0.273.0> ra system 'coordination' running pre init for 0 registered servers
2026-02-24 20:32:56.170635+00:00 [info] <0.274.0> ra: meta data store initialised for system coordination. 0 record(s) recovered
2026-02-24 20:32:56.170747+00:00 [notice] <0.279.0> WAL: ra_coordination_log_wal init, open tbls: ra_coordination_log_open_mem_tables, closed tbls: ra_coordination_log_closed_mem_tables
2026-02-24 20:32:56.173541+00:00 [info] <0.229.0> 
2026-02-24 20:32:56.173541+00:00 [info] <0.229.0>  Starting RabbitMQ 3.12.14 on Erlang 25.3.2.15 [jit]
2026-02-24 20:32:56.173541+00:00 [info] <0.229.0>  Copyright (c) 2007-2024 Broadcom Inc and/or its subsidiaries
2026-02-24 20:32:56.173541+00:00 [info] <0.229.0>  Licensed under the MPL 2.0. Website: https://rabbitmq.com
2026-02-24 20:32:56.173581+00:00 [error] <0.229.0> This release series has reached end of life and is no longer supported. Please visit https://rabbitmq.com/versions.html to learn more and upgrade

  ##  ##      RabbitMQ 3.12.14
  ##  ##
  ##########  Copyright (c) 2007-2024 Broadcom Inc and/or its subsidiaries
  ######  ##
  ##########  Licensed under the MPL 2.0. Website: https://rabbitmq.com

  Erlang:      25.3.2.15 [jit]
  TLS Library: OpenSSL - OpenSSL 3.1.7 3 Sep 2024
  Release series support status: out of support

  Doc guides:  https://rabbitmq.com/documentation.html
  Support:     https://rabbitmq.com/contact.html
  Tutorials:   https://rabbitmq.com/getstarted.html
  Monitoring:  https://rabbitmq.com/monitoring.html

  Logs: <stdout>

  Config file(s): /etc/rabbitmq/rabbitmq.conf
                  /etc/rabbitmq/conf.d/10-defaults.conf

  Starting broker...2026-02-24 20:32:56.178771+00:00 [info] <0.229.0> 
2026-02-24 20:32:56.178771+00:00 [info] <0.229.0>  node           : rabbit@ip-10-20-11-113.ec2.internal
2026-02-24 20:32:56.178771+00:00 [info] <0.229.0>  home dir       : /var/lib/rabbitmq
2026-02-24 20:32:56.178771+00:00 [info] <0.229.0>  config file(s) : /etc/rabbitmq/rabbitmq.conf
2026-02-24 20:32:56.178771+00:00 [info] <0.229.0>                 : /etc/rabbitmq/conf.d/10-defaults.conf
2026-02-24 20:32:56.178771+00:00 [info] <0.229.0>  cookie hash    : H49IcIacG8jXO4jLOzzajQ==
2026-02-24 20:32:56.178771+00:00 [info] <0.229.0>  log(s)         : <stdout>
2026-02-24 20:32:56.178771+00:00 [info] <0.229.0>  data dir       : /var/lib/rabbitmq/mnesia/rabbit@ip-10-20-11-113.ec2.internal
2026-02-24 20:32:57.984232+00:00 [info] <0.229.0> Running boot step pre_boot defined by app rabbit
2026-02-24 20:32:57.984290+00:00 [info] <0.229.0> Running boot step rabbit_global_counters defined by app rabbit
2026-02-24 20:32:57.984489+00:00 [info] <0.229.0> Running boot step rabbit_osiris_metrics defined by app rabbit
2026-02-24 20:32:57.984558+00:00 [info] <0.229.0> Running boot step rabbit_core_metrics defined by app rabbit
2026-02-24 20:32:57.984752+00:00 [info] <0.229.0> Running boot step rabbit_alarm defined by app rabbit
2026-02-24 20:32:57.987078+00:00 [info] <0.298.0> Memory high watermark set to 1527 MiB (1602050457 bytes) of 3819 MiB (4005126144 bytes) total
2026-02-24 20:32:57.989066+00:00 [info] <0.300.0> Enabling free disk space monitoring (disk free space: 260276531200, total memory: 4005126144)
2026-02-24 20:32:57.989110+00:00 [info] <0.300.0> Disk free limit set to 50MB
2026-02-24 20:32:57.989920+00:00 [info] <0.229.0> Running boot step code_server_cache defined by app rabbit
2026-02-24 20:32:57.989985+00:00 [info] <0.229.0> Running boot step file_handle_cache defined by app rabbit
2026-02-24 20:32:57.990142+00:00 [info] <0.303.0> Limiting to approx 32671 file handles (29401 sockets)
2026-02-24 20:32:57.990209+00:00 [info] <0.304.0> FHC read buffering: OFF
2026-02-24 20:32:57.990231+00:00 [info] <0.304.0> FHC write buffering: ON
2026-02-24 20:32:57.990496+00:00 [info] <0.229.0> Running boot step worker_pool defined by app rabbit
2026-02-24 20:32:57.990532+00:00 [info] <0.281.0> Will use 2 processes for default worker pool
2026-02-24 20:32:57.990556+00:00 [info] <0.281.0> Starting worker pool 'worker_pool' with 2 processes in it
2026-02-24 20:32:57.990709+00:00 [info] <0.229.0> Running boot step database defined by app rabbit
2026-02-24 20:32:57.991005+00:00 [info] <0.229.0> Node database directory at /var/lib/rabbitmq/mnesia/rabbit@ip-10-20-11-113.ec2.internal is empty. Assuming we need to join an existing cluster or initialise from scratch...
2026-02-24 20:32:57.991027+00:00 [info] <0.229.0> Configured peer discovery backend: rabbit_peer_discovery_classic_config
2026-02-24 20:32:57.991050+00:00 [info] <0.229.0> Will try to lock with peer discovery backend rabbit_peer_discovery_classic_config
2026-02-24 20:32:57.991092+00:00 [info] <0.229.0> All discovered existing cluster peers:
2026-02-24 20:32:57.991102+00:00 [info] <0.229.0> Discovered no peer nodes to cluster with. Some discovery backends can filter nodes out based on a readiness criteria. Enabling debug logging might help troubleshoot.
2026-02-24 20:32:57.992633+00:00 [notice] <0.44.0> Application mnesia exited with reason: stopped
2026-02-24 20:32:58.072543+00:00 [info] <0.229.0> Waiting for Mnesia tables for 30000 ms, 9 retries left
2026-02-24 20:32:58.072633+00:00 [info] <0.229.0> Successfully synced tables from a peer
2026-02-24 20:32:58.073090+00:00 [notice] <0.282.0> Feature flags: attempt to enable `stream_sac_coordinator_unblock_group`...
2026-02-24 20:32:58.093017+00:00 [notice] <0.282.0> Feature flags: `stream_sac_coordinator_unblock_group` enabled
2026-02-24 20:32:58.093166+00:00 [notice] <0.282.0> Feature flags: attempt to enable `restart_streams`...
2026-02-24 20:32:58.111755+00:00 [notice] <0.282.0> Feature flags: `restart_streams` enabled
2026-02-24 20:32:58.112070+00:00 [info] <0.229.0> Waiting for Mnesia tables for 30000 ms, 9 retries left
2026-02-24 20:32:58.112185+00:00 [info] <0.229.0> Successfully synced tables from a peer
2026-02-24 20:32:58.119705+00:00 [info] <0.229.0> Waiting for Mnesia tables for 30000 ms, 9 retries left
2026-02-24 20:32:58.119875+00:00 [info] <0.229.0> Successfully synced tables from a peer
2026-02-24 20:32:58.119915+00:00 [info] <0.229.0> Peer discovery backend rabbit_peer_discovery_classic_config does not support registration, skipping registration.
2026-02-24 20:32:58.120005+00:00 [info] <0.229.0> Will try to unlock with peer discovery backend rabbit_peer_discovery_classic_config
2026-02-24 20:32:58.120258+00:00 [info] <0.229.0> Running boot step tracking_metadata_store defined by app rabbit
2026-02-24 20:32:58.120362+00:00 [info] <0.479.0> Setting up a table for connection tracking on this node: tracked_connection
2026-02-24 20:32:58.120403+00:00 [info] <0.479.0> Setting up a table for per-vhost connection counting on this node: tracked_connection_per_vhost
2026-02-24 20:32:58.120478+00:00 [info] <0.479.0> Setting up a table for per-user connection counting on this node: tracked_connection_per_user
2026-02-24 20:32:58.120544+00:00 [info] <0.479.0> Setting up a table for channel tracking on this node: tracked_channel
2026-02-24 20:32:58.120637+00:00 [info] <0.479.0> Setting up a table for channel tracking on this node: tracked_channel_per_user
2026-02-24 20:32:58.120692+00:00 [info] <0.229.0> Running boot step networking_metadata_store defined by app rabbit
2026-02-24 20:32:58.120786+00:00 [info] <0.229.0> Running boot step feature_flags defined by app rabbit
2026-02-24 20:32:58.120891+00:00 [info] <0.229.0> Running boot step codec_correctness_check defined by app rabbit
2026-02-24 20:32:58.120916+00:00 [info] <0.229.0> Running boot step external_infrastructure defined by app rabbit
2026-02-24 20:32:58.120941+00:00 [info] <0.229.0> Running boot step rabbit_event defined by app rabbit
2026-02-24 20:32:58.121089+00:00 [info] <0.229.0> Running boot step rabbit_registry defined by app rabbit
2026-02-24 20:32:58.121195+00:00 [info] <0.229.0> Running boot step rabbit_auth_mechanism_amqplain defined by app rabbit
2026-02-24 20:32:58.121245+00:00 [info] <0.229.0> Running boot step rabbit_auth_mechanism_cr_demo defined by app rabbit
2026-02-24 20:32:58.121298+00:00 [info] <0.229.0> Running boot step rabbit_auth_mechanism_plain defined by app rabbit
2026-02-24 20:32:58.121374+00:00 [info] <0.229.0> Running boot step rabbit_exchange_type_direct defined by app rabbit
2026-02-24 20:32:58.121440+00:00 [info] <0.229.0> Running boot step rabbit_exchange_type_fanout defined by app rabbit
2026-02-24 20:32:58.121550+00:00 [info] <0.229.0> Running boot step rabbit_exchange_type_headers defined by app rabbit
2026-02-24 20:32:58.121655+00:00 [info] <0.229.0> Running boot step rabbit_exchange_type_topic defined by app rabbit
2026-02-24 20:32:58.121724+00:00 [info] <0.229.0> Running boot step rabbit_mirror_queue_mode_all defined by app rabbit
2026-02-24 20:32:58.121793+00:00 [info] <0.229.0> Running boot step rabbit_mirror_queue_mode_exactly defined by app rabbit
2026-02-24 20:32:58.121841+00:00 [info] <0.229.0> Running boot step rabbit_mirror_queue_mode_nodes defined by app rabbit
2026-02-24 20:32:58.121906+00:00 [info] <0.229.0> Running boot step rabbit_priority_queue defined by app rabbit
2026-02-24 20:32:58.121948+00:00 [info] <0.229.0> Priority queues enabled, real BQ is rabbit_variable_queue
2026-02-24 20:32:58.122038+00:00 [info] <0.229.0> Running boot step rabbit_queue_location_client_local defined by app rabbit
2026-02-24 20:32:58.122090+00:00 [info] <0.229.0> Running boot step rabbit_queue_location_min_masters defined by app rabbit
2026-02-24 20:32:58.122130+00:00 [info] <0.229.0> Running boot step rabbit_queue_location_random defined by app rabbit
2026-02-24 20:32:58.122183+00:00 [info] <0.229.0> Running boot step kernel_ready defined by app rabbit
2026-02-24 20:32:58.122200+00:00 [info] <0.229.0> Running boot step rabbit_sysmon_minder defined by app rabbit
2026-02-24 20:32:58.122338+00:00 [info] <0.229.0> Running boot step rabbit_epmd_monitor defined by app rabbit
2026-02-24 20:32:58.122850+00:00 [info] <0.487.0> epmd monitor knows us, inter-node communication (distribution) port: 25672
2026-02-24 20:32:58.123043+00:00 [info] <0.229.0> Running boot step guid_generator defined by app rabbit
2026-02-24 20:32:58.125232+00:00 [info] <0.229.0> Running boot step rabbit_node_monitor defined by app rabbit
2026-02-24 20:32:58.125475+00:00 [info] <0.491.0> Starting rabbit_node_monitor (in ignore mode)
2026-02-24 20:32:58.125621+00:00 [info] <0.229.0> Running boot step delegate_sup defined by app rabbit
2026-02-24 20:32:58.126025+00:00 [info] <0.229.0> Running boot step rabbit_memory_monitor defined by app rabbit
2026-02-24 20:32:58.126162+00:00 [info] <0.229.0> Running boot step rabbit_fifo_dlx_sup defined by app rabbit
2026-02-24 20:32:58.126205+00:00 [info] <0.229.0> Running boot step core_initialized defined by app rabbit
2026-02-24 20:32:58.126232+00:00 [info] <0.229.0> Running boot step rabbit_channel_tracking_handler defined by app rabbit
2026-02-24 20:32:58.126278+00:00 [info] <0.229.0> Running boot step rabbit_connection_tracking_handler defined by app rabbit
2026-02-24 20:32:58.126307+00:00 [info] <0.229.0> Running boot step rabbit_definitions_hashing defined by app rabbit
2026-02-24 20:32:58.126382+00:00 [info] <0.229.0> Running boot step rabbit_exchange_parameters defined by app rabbit
2026-02-24 20:32:58.126624+00:00 [info] <0.229.0> Running boot step rabbit_mirror_queue_misc defined by app rabbit
2026-02-24 20:32:58.126850+00:00 [info] <0.229.0> Running boot step rabbit_policies defined by app rabbit
2026-02-24 20:32:58.127072+00:00 [info] <0.229.0> Running boot step rabbit_policy defined by app rabbit
2026-02-24 20:32:58.127108+00:00 [info] <0.229.0> Running boot step rabbit_queue_location_validator defined by app rabbit
2026-02-24 20:32:58.127215+00:00 [info] <0.229.0> Running boot step rabbit_quorum_memory_manager defined by app rabbit
2026-02-24 20:32:58.127252+00:00 [info] <0.229.0> Running boot step rabbit_stream_coordinator defined by app rabbit
2026-02-24 20:32:58.127375+00:00 [info] <0.229.0> Running boot step rabbit_vhost_limit defined by app rabbit
2026-02-24 20:32:58.127450+00:00 [info] <0.229.0> Running boot step rabbit_mgmt_reset_handler defined by app rabbitmq_management
2026-02-24 20:32:58.127481+00:00 [info] <0.229.0> Running boot step rabbit_mgmt_db_handler defined by app rabbitmq_management_agent
2026-02-24 20:32:58.127531+00:00 [info] <0.229.0> Management plugin: using rates mode 'basic'
2026-02-24 20:32:58.127773+00:00 [info] <0.229.0> Running boot step recovery defined by app rabbit
2026-02-24 20:32:58.128326+00:00 [info] <0.229.0> Running boot step empty_db_check defined by app rabbit
2026-02-24 20:32:58.128363+00:00 [info] <0.229.0> Will seed default virtual host and user...
2026-02-24 20:32:58.128497+00:00 [info] <0.229.0> Adding vhost '/' (description: 'Default virtual host', tags: [])
2026-02-24 20:32:58.130867+00:00 [info] <0.229.0> Inserted a virtual host record {vhost,<<"/">>,[],
2026-02-24 20:32:58.130867+00:00 [info] <0.229.0>                                       #{description =>
2026-02-24 20:32:58.130867+00:00 [info] <0.229.0>                                             <<"Default virtual host">>,
2026-02-24 20:32:58.130867+00:00 [info] <0.229.0>                                         tags => []}}
2026-02-24 20:32:58.151331+00:00 [info] <0.536.0> Making sure data directory '/var/lib/rabbitmq/mnesia/rabbit@ip-10-20-11-113.ec2.internal/msg_stores/vhosts/628WB79CIFDYO9LJI6DKMI09L' for vhost '/' exists
2026-02-24 20:32:58.151975+00:00 [info] <0.536.0> Setting segment_entry_count for vhost '/' with 0 queues to '2048'
2026-02-24 20:32:58.155707+00:00 [info] <0.536.0> Starting message stores for vhost '/'
2026-02-24 20:32:58.155950+00:00 [info] <0.546.0> Message store "628WB79CIFDYO9LJI6DKMI09L/msg_store_transient": using rabbit_msg_store_ets_index to provide index
2026-02-24 20:32:58.156684+00:00 [info] <0.536.0> Started message store of type transient for vhost '/'
2026-02-24 20:32:58.156808+00:00 [info] <0.550.0> Message store "628WB79CIFDYO9LJI6DKMI09L/msg_store_persistent": using rabbit_msg_store_ets_index to provide index
2026-02-24 20:32:58.157200+00:00 [warning] <0.550.0> Message store "628WB79CIFDYO9LJI6DKMI09L/msg_store_persistent": rebuilding indices from scratch
2026-02-24 20:32:58.157800+00:00 [info] <0.536.0> Started message store of type persistent for vhost '/'
2026-02-24 20:32:58.157928+00:00 [info] <0.536.0> Recovering 0 queues of type rabbit_classic_queue took 5ms
2026-02-24 20:32:58.157976+00:00 [info] <0.536.0> Recovering 0 queues of type rabbit_quorum_queue took 0ms
2026-02-24 20:32:58.158023+00:00 [info] <0.536.0> Recovering 0 queues of type rabbit_stream_queue took 0ms
2026-02-24 20:32:58.161022+00:00 [info] <0.229.0> Created user 'admin'
2026-02-24 20:32:58.163238+00:00 [info] <0.229.0> Successfully set user tags for user 'admin' to [administrator]
2026-02-24 20:32:58.165407+00:00 [info] <0.229.0> Successfully set permissions for user 'admin' in virtual host '/' to '.*', '.*', '.*'
2026-02-24 20:32:58.165469+00:00 [info] <0.229.0> Running boot step rabbit_observer_cli defined by app rabbit
2026-02-24 20:32:58.165599+00:00 [info] <0.229.0> Running boot step rabbit_looking_glass defined by app rabbit
2026-02-24 20:32:58.165650+00:00 [info] <0.229.0> Running boot step rabbit_core_metrics_gc defined by app rabbit
2026-02-24 20:32:58.165813+00:00 [info] <0.229.0> Running boot step background_gc defined by app rabbit
2026-02-24 20:32:58.165930+00:00 [info] <0.229.0> Running boot step routing_ready defined by app rabbit
2026-02-24 20:32:58.165966+00:00 [info] <0.229.0> Running boot step pre_flight defined by app rabbit
2026-02-24 20:32:58.165982+00:00 [info] <0.229.0> Running boot step notify_cluster defined by app rabbit
2026-02-24 20:32:58.166053+00:00 [info] <0.229.0> Running boot step networking defined by app rabbit
2026-02-24 20:32:58.166094+00:00 [info] <0.229.0> Running boot step definition_import_worker_pool defined by app rabbit
2026-02-24 20:32:58.166145+00:00 [info] <0.281.0> Starting worker pool 'definition_import_pool' with 2 processes in it
2026-02-24 20:32:58.166562+00:00 [info] <0.229.0> Running boot step cluster_name defined by app rabbit
2026-02-24 20:32:58.166648+00:00 [info] <0.229.0> Initialising internal cluster ID to 'rabbitmq-cluster-id-67awSliNol2JrmLF4d5I6Q'
2026-02-24 20:32:58.169038+00:00 [info] <0.229.0> Running boot step direct_client defined by app rabbit
2026-02-24 20:32:58.169149+00:00 [info] <0.229.0> Running boot step rabbit_maintenance_mode_state defined by app rabbit
2026-02-24 20:32:58.169178+00:00 [info] <0.229.0> Creating table rabbit_node_maintenance_states for maintenance mode status
2026-02-24 20:32:58.172424+00:00 [info] <0.229.0> Running boot step rabbit_management_load_definitions defined by app rabbitmq_management
2026-02-24 20:32:58.172529+00:00 [info] <0.588.0> Resetting node maintenance status
2026-02-24 20:32:58.181923+00:00 [info] <0.647.0> Management plugin: HTTP (non-TLS) listener started on port 15672
2026-02-24 20:32:58.182117+00:00 [info] <0.675.0> Statistics database started.
2026-02-24 20:32:58.182205+00:00 [info] <0.674.0> Starting worker pool 'management_worker_pool' with 3 processes in it
2026-02-24 20:32:58.207602+00:00 [info] <0.696.0> Peer discovery: node cleanup is disabled
2026-02-24 20:32:58.207906+00:00 [info] <0.588.0> Ready to start client connection listeners
2026-02-24 20:32:58.209038+00:00 [info] <0.717.0> started TCP listener on [::]:5672
 completed with 6 plugins.
2026-02-24 20:32:58.252692+00:00 [info] <0.588.0> Server startup complete; 6 plugins started.
2026-02-24 20:32:58.252692+00:00 [info] <0.588.0>  * rabbitmq_peer_discovery_aws
2026-02-24 20:32:58.252692+00:00 [info] <0.588.0>  * rabbitmq_auth_backend_oauth2
2026-02-24 20:32:58.252692+00:00 [info] <0.588.0>  * rabbitmq_peer_discovery_common
2026-02-24 20:32:58.252692+00:00 [info] <0.588.0>  * rabbitmq_management
2026-02-24 20:32:58.252692+00:00 [info] <0.588.0>  * rabbitmq_management_agent
2026-02-24 20:32:58.252692+00:00 [info] <0.588.0>  * rabbitmq_web_dispatch
2026-02-24 20:32:58.373088+00:00 [info] <0.9.0> Time to start RabbitMQ: 4303131 us
sh-5.2$ 