#!/bin/bash

# Aguarda 45 segundos para garantir que o sistema esteja totalmente inicializado
sleep 45

# Atualiza a lista de repositórios de pacotes
apt update -y

# Instala dependências necessárias para o sistema
apt install -y apt-transport-https ca-certificates curl software-properties-common nfs-common

# Configura o repositório oficial do Docker
# Cria diretório para armazenar chaves GPG
install -m 0755 -d /etc/apt/keyrings
# Baixa a chave GPG oficial do Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
# Define permissões de leitura para a chave
chmod a+r /etc/apt/keyrings/docker.asc

# Adiciona o repositório do Docker às fontes do apt
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# Atualiza a lista de pacotes novamente para incluir o repositório do Docker
apt update -y

# Instala o Docker Engine e componentes relacionados
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin

# Inicia o serviço do Docker
systemctl start docker
# Configura o Docker para iniciar automaticamente no boot
systemctl enable docker
# Adiciona o usuário ubuntu ao grupo docker para executar comandos sem sudo
usermod -a -G docker ubuntu 

# Instala o Docker Compose Plugin
apt install docker-compose-plugin -y

# Configuração do Amazon EFS (Elastic File System)
# Cria diretório para ponto de montagem do EFS
mkdir -p /mnt/efs
# Monta o sistema de arquivos EFS usando NFSv4
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport seu_EFS_id.efs.us-east-1.amazonaws.com:/ /mnt/efs
# Configura a montagem automática do EFS no boot adicionando ao fstab
echo "seu_EFS_id.efs.us-east-1.amazonaws.com:/ /mnt/efs nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,_netdev 0 0" >> /etc/fstab

# Configuração do WordPress
# Cria diretório para os arquivos do docker-compose
mkdir -p /home/ubuntu/wordpress
# Cria diretório para os arquivos do WordPress no EFS
mkdir -p /mnt/efs/html

# Cria arquivo de configuração do docker-compose para o WordPress
cat <<EOF > /home/ubuntu/wordpress/docker-compose.yaml
version: '3.8'
services:
  wordpress:
    image: wordpress:latest
    container_name: wordpress
    restart: always
    ports:
      - "80:80"
    environment:
      WORDPRESS_DB_HOST: "Seu endpoint do RDS"
      WORDPRESS_DB_USER: "Nome do Usuário"
      WORDPRESS_DB_PASSWORD: "Senha do usuário"
      WORDPRESS_DB_NAME: "Nome do banco"
    volumes:
      - /mnt/efs/html:/var/www/html/
EOF

# Define permissões corretas para o diretório do WordPress (usuário www-data)
sudo chown -R 33:33 /mnt/efs/html

# Inicia os containers do WordPress usando docker-compose
cd /home/ubuntu/wordpress
docker compose up -d
