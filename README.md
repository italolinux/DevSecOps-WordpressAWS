# DevSecOps-WordpressAWS
Este projeto tem como objetivo implementar uma arquitetura escalável e tolerante a falhas para a plataforma WordPress na AWS, utilizando serviços gerenciados para garantir alta disponibilidade, desempenho e resiliência.

<img width="936" height="411" alt="undefined" src="https://github.com/user-attachments/assets/a2944bd5-9e23-424b-a320-21d1e8569bc5" />


🛠️ Tecnologias e Serviços AWS Utilizados

* Docker

* Shell Script

* Wordpress
  
* Amazon EC2

* Auto Scaling Group

* Application Load Balancer (ALB)

* Amazon RDS (MySQL/MariaDB)

* Amazon EFS

* VPC, Subnets, Route Tables, Internet Gateway, NAT Gateway

* Security Groups

# Etapa 1 Criação e Configuração da VPC
VPC é como criar sua própria rede privada e isolada dentro da nuvem da AWS. É similar a ter um data center virtual onde você pode controlar totalmente: Endereçamento IP, Sub-redes, Rotas, Segurança (Security Groups e NACLs).
  
<img width="1615" height="719" alt="Captura de tela 2025-09-23 142807" src="https://github.com/user-attachments/assets/ad99013c-040f-4406-b734-e9409a1bc284" />

* Nome: *projectWordpress*

* CIDR Block: ``` 10.0.0.0/16 ```- Esta é a faixa de IPs

## Estrutura de Subnets

*  AZs: 2 zonas de disponibilidade (us-east-1a e us-east-1b)

*  Subnets públicas: 2 (uma em cada AZ) - para recursos que precisam de internet

*  Subnets privadas: 4 (duas em cada AZ) - para recursos protegidos

*  Nat gateways : none (criarei à parte)
