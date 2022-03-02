Before you begin, make sure you configure .aws/config and .aws/credentials file with aws_access_key_id and aws_secret_access_key
Run aws sts get-caller-identity and  aws iam get-user make sure user has enough IAM role to perform the operation.

git clone https://github.com/xiongye77/terraform-carsales-test.git

cd terraform-carsales-test

cd backend

terraform init

terraform apply -auto-approve  # this step will create terraform backend S3 backuet and Dynamodb, you will find result.log in your local directory, it is my job log. 
cd ..



make changes to variable.tf file, change demo_dns_zone variable to one your Route53 zone.

terraform init  # the default regin is Sydney ap-southeast-2 which defined in variables.tf file, all ami used for EC2/Bastion host are automatically get. Make sure spot instance bid price is enough. 

terraform apply -auto-approve  # this step will create all alb/ec2/ecs/RDS/bastion host/nat gateway/EFS/SSM/Secret manager....you will find result.log in your local directory, it is my job log. the output will be alb url 

check following url, they will point to different ECS target group and lambda function 
https://ssldemo.poc.csnglobal.net/carsales1/

https://ssldemo.poc.csnglobal.net/carsales2/

https://ssldemo.poc.csnglobal.net/lambda/

Remember to run terraform destroy later it will save your cost.
