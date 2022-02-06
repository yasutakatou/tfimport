# tfimport (WIP)
This is a tool that wraps commands to assist import.

# Solution

Now that DevOps has advanced, is there anything like this?
I've created the infrastructure, so please "terraform import" it.
It's a pain in the ass to get used to. Read the documentation from the official site every time.
This is Toil.
This tool was created with the hope that anyone can import it easily.

# Feature
- You can choose which resources to import interactively.
- Can save configuration information in batches
- Multiple resources can be imported at once.

# Require

This tool needs to be able to execute the following commands.
You just need to place the shell script and definition files on a linux server and it will work.

- [AWS CLI](https://aws.amazon.com/jp/cli/)
- [terraform](https://www.terraform.io/downloads)
- [peco](https://github.com/peco/peco)
- [jq](https://stedolan.github.io/jq/)
- standard unix environment
 - noet) Standard Linux commands like "grep".

note) terraform and peco can be specified without a path.

# Usecase
## Interactive mode

If you run it without any arguments, you will be in the mode of selecting the resource you want to import from the menu.

```
./tfimport.sh
```

![2](https://user-images.githubusercontent.com/22161385/152686788-26159ede-bd37-48a8-824c-474ecb9b26e7.gif)

note) Select by peco, so you can refine your search with peco.

## CLI mode

When you specify a label and target resource, the selection screen does not appear, and it works in batch mode.

```
./tfimport.sh (target) (name)
```

![3](https://user-images.githubusercontent.com/22161385/152705942-447834d6-f43f-48cd-a482-07c5420093d2.gif)

# config file

The configuration file consists of **tilde(~) spread value**. It consists of a resource name, a refine command, and a search command.<br>

```
(1) ~ (2) ~ (3) ~ (4) ~ (5)
```

- (1) Define Name
- (2) AWS Resource Define
 - This is the name of the definition written in the Terraform document
- (3) Export Name Define
 - Define the directory name for output (If you define it with A, the file name will be complicated, so specify the definition name
- (4) Define a command to list the target resources. The list will be passed to peco.
- (5) Execute the refinement command based on the output of "(2)"

note) "@@@@" is a special character and "(2)" command string will be replaced.
  aws s3 ls s3://@@@@/test <- "@@@@" is converted at the output of "(2)".

example)

```
S3 ~ aws_s3_bucket ~ aws s3 ls | cut -d " " -f 3 ~ ~ 
EC2 ~ aws_instance ~ aws ec2 describe-instances --output text --query 'Reservations[*].Instances[].{Name: Tags[?Key==`Name`]|[0].Value}' ~ ~ if [[ "@@@@" == *i-* ]];then echo @@@@;else aws ec2 describe-instances --filters "Name=tag:Name,Values=@@@@" | jq -r ".Reservations[].Instances[].InstanceId" ;fi ~
CloudFront ~ aws_cloudfront_distribution ~ aws cloudfront list-distributions | jq -r ".DistributionList.Items[]|[.Id,.DomainName]|@csv" ~ ~ echo @@@@ | cut -d , -f 1 | tr -d "\""
RDS ~ aws_db_instance ~ aws rds describe-db-instances | jq -r ".DBInstances[].DBInstanceIdentifier" ~ ~
DynamoDB ~ aws_dynamodb_table ~ aws dynamodb list-tables | jq -r ".TableNames[]" ~ ~
Lambda ~ aws_lambda_function ~ aws lambda list-functions | jq -r ".Functions[].FunctionName" ~ ~
APIGatewayv2 ~ aws_apigatewayv2_api ~ aws apigatewayv2 get-apis | jq -r ".Items[]|[.Name,.ApiId]|@csv" ~ echo @@@@ | cut -d , -f 1 | tr -d "\"" ~ echo @@@@ | cut -d , -f 2 | tr -d "\"" ~
ECSCLuster ~ aws_ecs_cluster ~ aws ecs list-clusters | jq -r ".clusterArns[]" | cut -d / -f 2 ~ ~
CodeBuild ~ aws_codebuild_project ~ aws codebuild list-projects | jq -r ".projects[]" ~ ~
CodePipeline ~ aws_codepipeline ~ aws codepipeline list-pipelines | jq -r ".pipelines[]|[.name]|@csv" | tr -d "\"" ~ ~
CodeDeploy ~ aws_codedeploy_app ~ aws deploy list-applications | jq -r ".applications[]" ~ ~
ELB ~ aws_lb ~ aws elbv2 describe-load-balancers | jq -r ".LoadBalancers[].LoadBalancerArn" | tr -d "\"" ~ echo "@@@@" | cut -d / -f 3 ~  ~
ELB ~ aws_lb_listener ~ aws elbv2 describe-listeners --load-balancer-arn @@@@ | jq -r ".Listeners[].ListenerArn" | head -1 ~ ~
ELB ~ aws_lb_target_group ~ aws elbv2 describe-listeners --load-balancer-arn @@@@ | jq -r ".Listeners[].DefaultActions[].TargetGroupArn" | head -1 ~ ~
ElastiCahe ~ aws_elasticache_replication_group ~ aws elasticache describe-replication-groups | jq -r ".ReplicationGroups[].ReplicationGroupId" ~ ~
```

# options

Options should be set as environment variables using "Export" command.

- TFIMPORTPATH

```
TFIMPORTPATH
```

With this definition, terraform and peco will be used in the specified path
export TFIMPORTPATH+/usr/bin

- TFIMPORTINI

- TFIMPORTSED
- TFIMPORTINIT

# license
MIT License
