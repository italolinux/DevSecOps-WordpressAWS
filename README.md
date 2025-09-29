# DevSecOps-WordpressAWS
Este projeto tem como objetivo implementar uma arquitetura escalável e tolerante a falhas para a plataforma WordPress na AWS, utilizando serviços gerenciados para garantir alta disponibilidade, desempenho e resiliência.

<img width="936" height="411" alt="undefined" src="https://github.com/user-attachments/assets/a2944bd5-9e23-424b-a320-21d1e8569bc5" />


🛠️ Tecnologias e Serviços AWS Utilizados

* Docker.

* Shell Script.

* Wordpress.
  
* Amazon EC2.

* Auto Scaling Group.

* Application Load Balancer (ALB).

* Amazon RDS (MySQL).

* Amazon EFS.

* VPC, Subnets, Route Tables, Internet Gateway, NAT Gateway.

* Security Groups.

# Etapa 1 Criação e Configuração da VPC
VPC é como criar sua própria rede privada e isolada dentro da nuvem da AWS. É similar a ter um data center virtual onde você pode controlar totalmente: Endereçamento IP, Sub-redes, Rotas, Segurança (Security Groups e NACLs).
  
<img width="1615" height="719" alt="Captura de tela 2025-09-23 142807" src="https://github.com/user-attachments/assets/ad99013c-040f-4406-b734-e9409a1bc284" />

* Nome: ``` projectWordpress ```.

* CIDR Block: ``` 10.0.0.0/16 ```- Esta é a faixa de IPs.
  
## Estrutura de Subnets

*  AZs: 2 zonas de disponibilidade (us-east-1a e us-east-1b).

*  Subnets públicas: 2 (uma em cada AZ) - para recursos que precisam de internet.

*  Subnets privadas: 4 (duas em cada AZ) - para recursos protegidos.

*  Nat gateways : none (criarei à parte).

*  DNS resolution: Habilitado (permite resolução de nomes).

*  DNS hostnames: Desabilitado.

## Configuração NAT gateway

Um NAT gateway é um serviço de Network Address Translation (NAT – Conversão de endereços de rede). Você pode usar um gateway NAT para que as instâncias em uma sub-rede privada possam se conectar a serviços fora da VPC, mas os serviços externos não podem iniciar uma conexão com essas instâncias.

<img width="1886" height="724" alt="Captura de tela 2025-09-28 132459" src="https://github.com/user-attachments/assets/18327d63-6b72-416f-b04d-5fab377da5e5" />

* Name: ``` nat-gateway-zone1a ```.

* Subnet: ``` projetoWordpress-subnet-public1-us-east-1a ```.

* Connectivity type: Public (as instâncias em sub-redes privadas podem se conectar à Internet por meio de um gateway NAT público, mas não podem receber conexões de entrada não solicitadas da internet).

* Elastic IP : Você pode alocar e criar um automaticamente clicando no botão **Allocate Elastic IP**, ou indo na VPC em elastic Ips e criando à parte.

Como vamos precisar de 2 NAT gateways, só fazer os mesmos passos.

* Name: ``` nat-gateway-zone1b ```.

* Subnet: ``` projetoWordpress-subnet-public2-us-east-1b ```.

* Connectivity type: Public.

*  Elastic IP: Allocate Elastic IP.

### Editando as tabelas de rotas

Em VPC, na opção de tabelas de rotas(Route tables), Você precisa adiconar os NAT gateways as sub redes privadas.

<img width="1892" height="605" alt="Captura de tela 2025-09-28 141012" src="https://github.com/user-attachments/assets/2b6abb49-4636-48d5-bab1-8be5433f14bc" />

Selecionando a **projetoWordpress-rtb-private1-us-east-1a** na opção routes e edit routes e adicionamos a saída para internet (0.0.0.0/0) escolhemos a opção NAT gateway e atrelamos o nat-gateway-zone1a que criamos anteriormente.

Fazemos o mesmos passos para o **projetoWordpress-rtb-private2-us-east-1b** e adiciona a saída para internet para o nosso nat-gateway-zone1b.

# Etapa 2 Security Groups

Os Security Groups atuam como firewalls virtuais que controlam o tráfego de entrada e saída dos recursos AWS, aplicando o princípio do menor privilégio através de regras.

## Application Load balancer
Este Security Group serve como o primeiro filtro de segurança da arquitetura, gerenciando exclusivamente o tráfego entre a internet e o Application Load Balancer (ALB). Ele atua como uma barreira inicial que define quais protocolos e portas externos podem acessar a camada de balanceamento, assegurando que apenas conexões legítimas e autorizadas sejam encaminhadas para as instâncias EC2 internas, antes mesmo que o tráfego alcance a infraestrutura privada da aplicação.

* Na barra de pesquisa do console, digite por "EC2".

* No painel da EC2 vá em "Rede e segurança" depois em "Security groups".

* Depois clique em "Criar Grupo de Segurança"

* Insira o nome do grupo de segurança.

* Adicione alguma descrição para não se perder.

* Selecione a VPC que você criou.

<img width="1886" height="492" alt="Captura de tela 2025-09-28 153932" src="https://github.com/user-attachments/assets/babb2a48-31fe-46e9-b761-3b0660675a9f" />

Adicione a seguinte regra de entrada: 

* Tipo: HTTP.

* Protocolo: TCP.

* Intervalos de portas: 80.

* Origem: Qualquer lugar-IPv4 (0.0.0.0/0).

* Regras de saída: Você pode manter a regra padrão (Todo o tráfego para 0.0.0.0/0). O Load Balancer precisa dessa regra para encaminhar o tráfego para as instâncias EC2.

* Clique em "Criar grupo de segurança".

## Bastion host
O Security Group do Bastion Host funciona como um acesso administrativo fortificado para a rede privada, sendo configurado com regras extremamente restritivas que permitem exclusivamente conexões SSH de endereços IP previamente autorizados. Diferente do ALB que gerencia tráfego público, este servidor atua como um "ponto de pulo" seguro, proporcionando aos administradores um acesso controlado às instâncias EC2 localizadas nas subnets privadas, mantendo o isolamento da infraestrutura interna.

<img width="1900" height="537" alt="Captura de tela 2025-09-28 155753" src="https://github.com/user-attachments/assets/fad875de-3777-421d-951f-828d5a0eaad7" />

Adicione a seguinte regra de entrada: 

* Tipo: SSH.

* Protocolo: TCP.

* Intervalos de portas: 22.

* Origem: Meu IP.

A opção "Meu IP" é uma medida de segurança fundamental para um Bastion Host, garantindo que apenas conexões SSH originadas do seu endereço IP atual sejam permitidas. Esta configuração bloqueia tentativas de acesso não autorizadas de qualquer outra origem, reduzindo drasticamente a superfície de ataque. É essencial atualizar esta regra sempre que houver mudança de rede para manter o acesso administrativo sem comprometer a segurança.

## EC2
Este Security Group é responsável por proteger as instâncias EC2 que executam a aplicação WordPress em contêineres Docker. Suas regras foram meticulosamente definidas para assegurar que apenas o tráfego legitimamente necessário, originado de fontes previamente validadas dentro da arquitetura, consiga acessar os servidores da aplicação, mantendo o ambiente isolado e seguro.

Aqui foram adicionadas duas regras de entrada:

1° Regra:

* Tipo: HTTP.
  
* Intervalos de portas: 80.
  
* Origem: Exclusivamente do Security Group do Application Load Balancer (loadBalancer-sg).

2° Regra:

* Tipo: SSH.

* Intervalo de portas: 22.

* Origem: Exclusivamente do Security Group do Bastion Host(bastion-host-sg).

* Regras de saída: Você pode manter a regra padrão.

## RDS (Relational Database Service)
O Security Group do RDS foi projetado para assegurar a proteção do banco de dados MySQL que suporta a aplicação WordPress. Sua configuração tem como princípio a restrição máxima de acesso, permitindo conexões na porta do banco de dados exclusivamente a partir das instâncias EC2 previamente autorizadas, garantindo assim o isolamento completo do banco de dados contra acessos externos não autorizados.

<img width="1899" height="524" alt="Captura de tela 2025-09-28 164629" src="https://github.com/user-attachments/assets/65fd122d-8343-408d-8d60-88f2d6535af9" />

Regras de Entrada :

* Tipo: MYSQL/Aurora.

* Protocolo: TCP.

* Intervalo de portas: 3306.

* Origem: Exclusivamente vindo do security group da EC2(Ec2-sg).

* Regras de saída: Você pode manter a regra padrão.

## EFS(Elastic File System)
O Security Group do EFS foi desenvolvido para proteger o sistema de arquivos compartilhado que armazena os conteúdos persistentes do WordPress, como uploads de mídia e temas. Sua configuração garante que apenas as instâncias EC2 autorizadas possam montar e acessar o sistema de arquivos, mantendo os dados armazenados isolados e protegidos contra acessos não autorizados.

<img width="1889" height="509" alt="Captura de tela 2025-09-28 170837" src="https://github.com/user-attachments/assets/87f88841-9ba6-4f8a-8838-9cc2c838d53a" />

Adicione a seguinte regra de entrada: 

* Tipo: MYSQL/Aurora.

* Protocolo: TCP.

* Intervalo de portas: 3306.

* Origem: Exclusivamente vindo do security group da EC2(Ec2-sg).

* As regras de saída serão mantidas padrão.

# Etapa 3 Criação e configuração do RDS
O Amazon RDS será utilizado como banco de dados relacional gerenciado para garantir a persistência de dados essenciais do WordPress, como posts, usuários e configurações. Como serviço gerenciado, o RDS automatiza tarefas operacionais complexas incluindo provisionamento de infraestrutura, aplicação de patches de segurança e realização de backups, permitindo que possamos concentrar nossos esforços no desenvolvimento da aplicação rather do que na administração do banco de dados.

## Criação de Subnet group
O DB Subnet Group é um recurso de configuração fundamental para o Amazon RDS, responsável por definir um conjunto de sub-redes privadas dentro da VPC onde as instâncias de banco de dados podem ser implantadas. Esta configuração garante que o banco de dados opere na camada mais segura da arquitetura, completamente isolado do acesso direto à internet, enquanto mantém a capacidade de distribuição em múltiplas Zonas de Disponibilidade para garantir alta disponibilidade e resiliência. 
* Para configurá-lo, acesse o console da AWS e utilize a barra de pesquisa para localizar e selecionar o serviço RDS.

* Na página do RDS vá em "subnet groups" e depois clique em "Create DB subnet group".

<img width="1882" height="594" alt="Captura de tela 2025-09-28 172907" src="https://github.com/user-attachments/assets/2fad8eca-bd30-4a0f-973c-cb2d5f658cf2" />

* Nome: wordpress-subnet-group.
  
* Descrição: conectar o banco as duas zonas.
  
* VPC: projectWordpress-vpc.

<img width="1863" height="703" alt="Captura de tela 2025-09-28 172923" src="https://github.com/user-attachments/assets/2dc548d1-2264-4437-aead-d3493edf0c45" />

* Zonas de disponibilidade: Selecione as zonas **us-east-1a** e **us-east-1b**.
  
* Subnets: No casos escolhemos ``` projetoWordpress-subnet-private3-us-east-1a``` e ``` projetoWordpress-subnet-private4-us-east-1b ```.
  
* Clique em Create.

## Criação do RDS

Na página do RDS vá em "database" e depois clique em "Create database".

<img width="1892" height="751" alt="Captura de tela 2025-09-28 174809" src="https://github.com/user-attachments/assets/523f6da7-7071-4841-8e69-18a3183b180d" />

* Choose a database creation method: ``` Standard create ```.

* Engine options: ``` MySQL ```.

* Edition: ``` MySQL Community ```.

* Engine version: ``` MySQL 8.0.42 ```.

<img width="1700" height="737" alt="Captura de tela 2025-09-28 175356" src="https://github.com/user-attachments/assets/c2a4abe1-6349-44f4-8052-e425904e9161" />

* Templates: ``` Free tier  ```(escolhendo free tier, só deixa a opção single-AZ).

* Availability and durability: ``` Single-AZ DB instance deployment (1 instance) ```

<img width="1667" height="571" alt="Captura de tela 2025-09-28 180024" src="https://github.com/user-attachments/assets/77872df7-4d36-4e1d-baba-6e528f9c0ab4" />

Em Settings:

* Master username : ``` italo ```.

* Credentials management: ``` Self managed ```.

* Master password: Podemos auto gerar ou definir uma própria, no meu caso eu auto gerei (Auto generate password). Lembre-se de verificar a senha ao final da criação clicando no botão **view Connection details** e guardar ela.

* Instance configuration : ``` Burstable classes (includes t classes) e db.t3.micro ```.

Em Storage: 

* Storage type: ``` General Purpose SSD (gp2) ```.

* Allocated storage: ``` 20 ``` .

<img width="1356" height="750" alt="Captura de tela 2025-09-28 181222" src="https://github.com/user-attachments/assets/f38a00cc-6b53-4a09-8bb0-423a7f88392f" />


Em Connectivity: 

* Compute resource: ``` Don’t connect to an EC2 compute resource. ```

* VPC : Selecinamos nossa VPC criada para o projeto.

* DB subnet group: Selecinamos nosso grupo de rede criado anteriormente no caso ```wordpress-subnet-group ```.

* Public Access : no

* Security Group:```Choose existing e rds-sg ```.

* Availability Zone: ```No preference. ```

* Database authentication: ``` Password authentication. ```

* Monitoring: ``` Database Insights - Standard. ```

*  Clique em **Additional configuration** para fazer a criação do banco de dados para o RDS.

Em Database options:

* Initial database name: ``` wordpressdb ```.

* DB parameter group: ``` default.mysql8.0. ```

* Option group: ``` default:mysql-8-0. ```

Como não vamos fazer mais nenhuma mudança nas configurações, clique em create database.

# Etapa 4 Criação do EFS
Amazon EFS (Elastic File System) é um serviço de armazenamento de arquivos em nuvem totalmente gerenciado que funciona como um sistema de arquivos de rede compartilhado na AWS. Ele oferece armazenamento elástico e altamente disponível, permitindo que múltiplas instâncias EC2 acessem simultaneamente o mesmo conjunto de arquivos. Esta capacidade é crucial para manter a consistência de dados em ambientes com várias instâncias, pois centraliza o armazenamento de arquivos da aplicação - como uploads de mídia, temas e plugins do WordPress - garantindo que todas as instâncias tenham acesso imediato às mesmas informações, eliminando problemas de sincronização e assegurando a integridade dos dados em arquiteturas distribuídas.

* No console da AWS, pesquise pelo serviço do EFS.

* Clique em "Create file system".

*  Clique em "Customize".

<img width="1561" height="672" alt="Captura de tela 2025-09-28 184114" src="https://github.com/user-attachments/assets/b29335fd-d348-4ec4-8915-16ebd9f018ec" />

* Nome: EFS-wordpress.

* File System Type: Regional.

* Automatic Backup: Enable automatic backups.

* Lifecycle Management: Transition into IA: 30 dias sem acesso e Transition into Archive: 90 dias sem acesso.

* Encryption: enable.

<img width="1209" height="445" alt="Captura de tela 2025-09-28 184024" src="https://github.com/user-attachments/assets/dcee7710-aa25-4486-9dec-7a94c25aef30" />

Em Performance Settings:

* Throughput Mode: Enhanced (Mais flexibilidade e maior throughput) e Elastic (Performance escala automaticamente com a carga de trabalho, paga apenas pelo throughput usado).

* Clique em "next".

### Network Access
Pontos de Acesso (Mount Targets): Para permitir que as instâncias na VPC se conectem ao EFS, os Mount Targets são criados automaticamente na criação do EFS. Cada Mount Target é uma "tomada de rede" com um endereço de IP, posicionada estrategicamente em nossas sub-redes privadas onde estão as EC2. Essa configuração garante o acesso seguro e de alta performance a partir da camada de aplicação.

<img width="1810" height="663" alt="Captura de tela 2025-09-28 184302" src="https://github.com/user-attachments/assets/72ce3b88-f7ae-453a-94b3-bd4d3e037a3f" />

* VPC: Selecionamos a projetoWordpress-vpc.

* Mount Targets Configuration, vamos precisar de 2 mounts targets um para cada zona.

1° Zona:

* Availability Zone: us-east-1a.

* Subnet ID: projetoWordpress-subnet-private3-us-east-1a.

* IP Address Type: IPv4-only.

* Security Groups: EFS-sg.

2° Zona:

* Availability Zone: us-east-1b.

* Subnet ID: projetoWordpress-subnet-private4-us-east-1b.

* IP Address Type: IPv4-only.

* Security Groups: EFS-sg.

* Clique em "next" até criar o EFS.

# Etapa 5 Criação e configuração do Load Balancer
O Application Load Balancer (ALB) serve como o ponto de entrada principal da aplicação, gerenciando de forma eficiente e segura todo o tráfego proveniente da internet. Ele desempenha duas funções essenciais: distribui equilibradamente as solicitações dos usuários entre as instâncias EC2 saudáveis localizadas em diferentes Zonas de Disponibilidade, prevenindo sobrecarga em servidores individuais, e realiza verificações de saúde contínuas através de seu Target Group, monitorando a disponibilidade das instâncias via HTTP e redirecionando automaticamente o tráfego em caso de falhas. Como serviço intrinsicamente altamente disponível, implantado em múltiplas sub-redes públicas, garante a resiliência da aplicação mesmo diante de falhas completas em uma Zona de Disponibilidade.

* No console da EC2, no menu à esquerda, clique em "Load Balancers".

* Logo após clique em "create load balancer".

* Clique em "Create " na opção Application Load Balancer.

<img width="1779" height="423" alt="Captura de tela 2025-09-28 191302" src="https://github.com/user-attachments/assets/0b42613e-6753-47af-a06f-98e66242317e" />

* Nome: ALB-wordpress.

* Load Balancer Schema: Internet-facing (Para aplicações públicas acessíveis via internet).

* IP Address Type: IPv4.

<img width="1884" height="723" alt="Captura de tela 2025-09-28 191319" src="https://github.com/user-attachments/assets/40d7ba61-8635-4bc2-8241-fc9548ac6a0c" />

* VPC: projectWordpress-vpc

* Availability Zones: us-east-1a e us-east-1b.

* Subnets: subnet-public1-us-east-1a e subnet-public2-us-east-1b

* Security Group: loadBalancer-sg.

Agora precisamos criar um grupo de destino(target group), Os grupos de destino encaminham solicitações para destinos registrados individuais, como EC2 instâncias, usando o protocolo e o número da porta que você especificar.

* Em Listeners and Routing, clique em Create target group, abrirá outra janela para criar.

<img width="1915" height="787" alt="Captura de tela 2025-09-28 194745" src="https://github.com/user-attachments/assets/6c090fa0-561d-4c6e-a4f6-6ce7b566dbc1" />

* Target Type: Instances (Registrar instâncias por ID).

* Target Group Details:

  * Name: ec2-targetgroup.
    
  * Protocol: HTTP.

  * Port: 80.

<img width="1899" height="735" alt="Captura de tela 2025-09-28 195029" src="https://github.com/user-attachments/assets/cfffa8c8-e3a2-4b39-8004-fcfcbb3970cc" />

* IP address type: IPv4.

* VPC: projetoWordpress-vpc.

* Protocol version: HTTP1.

* Health Check Settings:
  * Protocol: HTTP ✅

  * Path: /wp-login.php

  * Port: traffic-port (usa a mesma porta do target group)

* Advanced Health Check:
  
  * Healthy threshold: 5

  * Unhealthy threshold: 2

  * Timeout: 5 seconds

  * Interval: 30 seconds

* para finalizar clique em "Create target group".

<img width="1756" height="716" alt="Captura de tela 2025-09-28 195108" src="https://github.com/user-attachments/assets/aa55f0d6-421a-47fa-9e90-598453008d80" />

* Protocol: HTTP
  
* Port: 80

* Forward to target group: ec2-targetgroup.

* Finalize clicando em "Create Load balancer".

# Etapa 6 Launch Template
O Launch Template atua como um modelo padronizado para a criação de instâncias EC2, definindo de forma abrangente todas as configurações base necessárias. Este recurso da AWS armazena um "projeto" completo do servidor, assegurando que cada nova instância provisionada pelo Auto Scaling Group mantenha consistência absoluta em suas características, desde especificações técnicas até scripts de inicialização. As informações a seguir detalham o processo de configuração deste componente fundamental.

* No painel da EC2, clique em "Modelos de execução".
  
* Depois clique em "Criar modelo de execução".

<img width="1844" height="460" alt="Captura de tela 2025-09-28 204835" src="https://github.com/user-attachments/assets/58cde2cf-39a0-4979-bc39-48266a9c0f61" />

* Name: wordpress-template.
  
* Description: Template para Ec2 com wordpress.
  
<img width="1215" height="752" alt="Captura de tela 2025-09-28 204848" src="https://github.com/user-attachments/assets/f5f1843b-0d4f-4341-8884-2f904c429205" />

* Amazon Machine Image (AMI): Ubuntu Server 24.04 LTS.

* Instance Type: t2.micro.

<img width="1223" height="577" alt="Captura de tela 2025-09-28 204916" src="https://github.com/user-attachments/assets/cfd39894-1612-4d81-bb50-7a30ca8a678e" />

* Key pair name: Adicione sua chave para acessar as instâncias.

* Subnet: Don't include in launch template (definido no Auto Scaling).

* Availability Zone: Don't include (gerenciado pelo Auto Scaling).

* Security Group: ec2-sg.

No final de **Advanced details** na opção user data, adicione nosso **userdata.sh** o script criado realiza as seguintes tarefas:

* Atualiza o Sistema: Garante que o Ubuntu esteja com os pacotes mais recentes.
* Instala o Docker e o Docker Compose: Prepara o ambiente para rodar os contêineres.
* Monta o Sistema de Arquivos (EFS): Conecta a instância ao EFS para garantir que os arquivos do WordPress sejam persistentes e compartilhados.
* Cria o docker-compose.yml: Gera dinamicamente o arquivo de orquestração dos contêineres, inserindo as credenciais do banco de dados RDS.
* Inicia o Serviço: Executa o docker compose up -d para baixar a imagen e iniciar o container do WordPress.

* Clique em "Create Launch template".

# Etapa 7 Auto Scaling Group
O Auto Scaling Group é um serviço da AWS que automaticamente adiciona ou remove instâncias EC2 com base na demanda da sua aplicação. Pense nele como um "gerente inteligente" que controla o número de servidores em funcionamento.

* No console da EC2, no menu à esquerda, role até o final e clique em "Auto Scaling Groups".

<img width="1123" height="356" alt="Captura de tela 2025-09-28 210855" src="https://github.com/user-attachments/assets/4f0d3075-e8b3-42df-a101-1d0fee377817" />

* Auto Scaling group name: ASG-wordpress.

* Launch template: wordpress-template.

<img width="1145" height="555" alt="Captura de tela 2025-09-28 210942" src="https://github.com/user-attachments/assets/6de16fd8-7413-4b6d-9578-d812c30938c3" />

* VPC: projectWordpress-vpc.

* Availability Zones and Subnets: ```projectWordpress-subnet-private1-us-east-1a``` e ```projectWordpress-subnet-private2-us-east-1b```

* Availability Zone Distribution: Balanced best effort (Se falhar em uma AZ, tenta em outra AZ saudável).

<img width="1145" height="729" alt="Captura de tela 2025-09-28 211024" src="https://github.com/user-attachments/assets/c927db88-4bba-4f2f-90b0-b64b1a8d4ec9" />

* Load Balancing: Attach to an existing load balancer.

* Target Group Selection: ec2-targetgroup.

* VPC Lattice: No VPC Lattice service.

<img width="1089" height="757" alt="Captura de tela 2025-09-28 211107" src="https://github.com/user-attachments/assets/63759910-2d2b-4104-9e4b-7c8feb705040" />

* Desired capacity: 2 instâncias.

* Minimum capacity: 2 instâncias.

* Maximum capacity: 4 instâncias.

* Additional Capacity Settings: Default.

* Clique em "Create auto scaling group".

### Acessando a Aplicação
Para acessar a aplicação precisamos do DNS público do load balancer.

* No console da EC2, no menu à esquerda, clique em "Load Balancers".

* Selecione o Load balancer criado anteriormente.

* Em details procure o DNS público.

* No navegador cole o DNS lembrando de usar o **http://** antes de colar.

<img width="1877" height="952" alt="Captura de tela 2025-09-28 213146" src="https://github.com/user-attachments/assets/208bb091-7bb0-4cd0-83c5-2fb089501db6" />

**Observação**: O health check só vai dar íntegro depois que fizer as configurações do wordpress.

