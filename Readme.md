# Explorer Terraform
This terraform allows us to easily deploy explorer on AWS. It is designed to assist you in creating infrastructure for various environments using *_locals.tf*. This terraform allows you to develop the following services.
- Redis
- RabbitMq
- Jenkins
- RDS ( Mysql / Postgres )
- EKS
- ECR
- VPC
- CodeBuild
- CodePipeline

### Perquisites
To set up the explorer, first configure your AWS cli with the credentials of the account you want to use.  
**aws configure --profile <account_id>**

In the **_provider.tf** file, change the *backend* section. Replace **<account_id>** with your AWS account ID.  
Create the bucket and DynamoDB in the region with the specified name.

**What does the backend do?**  
When we apply Terraform, a state file is generated that provides information about the resources created and their states. If the backend is not defined, the file is generated locally, and each user will have their own state file, which might cause problems when applying Terraform. With the backend setup, the state file is stored on S3, and all users share the same state file.  
Another issue we can face when two users run terraform apply simultaneously, can cause issue therefore, with backend there lock file is stored there and only one user at a time can run the terraform.

**NOTE :** Make sure to increase the cpu & elastic ip quotes in the specific region, else you will face with limit exceeded issue

### _locals.tf structure
The _locals.tf is the main file that handle deployment. It consists of:
- **name**          : name of your terraform file
- **environment**   : the environment will it be running at the moment
- **project_name**  : your project name
- **environments**  : all the environments that can be or deployed using the terraform

In environments, you define your environment name such as dev, stage, testnet or mainnet. You can copy paste the existing dev environment and edit values according to your need.  
All the variables description is added via comments in the file which will help you understand there use case.

### How to deploy
Copy paste dev map with the name of your environment you want to deploy.  
Replace **projectname** with you actually project name in lowercase.  
Replace **region** & **account_id** with the region you want to deploy the resources and the aws account id where they will be get deployed

**terraform init**

Edit the variables values according to your need

**terraform workspace new <environment_name>**

**terraform apply**

All you infrastructure will get provision in 20-30 mins

**NOTE :** VPC will not be created for dev & stage environments due to costing reasons. Also, ssh access will not be generated. Instead instances will be accessed with SSM

All the credentials generated will be stored in SSM Parameter store

If you choose codepipeline for deployment, Terraform will construct a codestar connection, but it will be in the pending state. You'll need to use the AWS Console to enable it using [documentation](https://docs.aws.amazon.com/dtconsole/latest/userguide/connections-update.html) 

### Post Installation Steps For EKS
After the infrastructure is deployed, you can install the necessary things in EKS using the ArgoCD application created. With the Applications, you can deploy
- ALB Ingress Controller
- Cluster Autoscaler
- External Secrets
- Grafana
- Loki
- Prometheus

### Additional
You can estimate the cost of the infrastructure to be deployed or already deployed by using infracost cli

**Install cli on Ubuntu / MacOs**  
curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh

Register on [*infracost.io*](https://infracost.io)  
login from cli  
**infracost auth login**

Generate plan file from terraform  
**terraform plan -out=plan.tfplan**

Get Cost Estimate  
**infracost breakdown --path plan.tfplan --show-skipped**