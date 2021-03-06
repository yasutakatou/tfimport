# tfimport
This is a tool that wraps commands to assist **"terraform import"**.

## v1.1

(1) WAFv2 applied to CloudFront (2) Region Environment  support.

## v1.2

The version of "AWS Provider" can now be fixed.

## v1.3

support **WAFclassic**.

## v1.4

support **Iam Policy** and **IAM Role**.

## v1.5

support **ListenerRule**, and Supports multiple execution of **peco**.<br>
<br>
note) "ListenerRule" does not support "CLI Mode".

## v1.6

support **secretsmanager**.

## v1.7

support **ECS Autoscale**.

## v2.0

Added the ability to import **multiple resources at once**.<br>
<br>
note) Implemented with the added definition of **MultiListenerRule**.

## v3.0

Support **Mac OS**<br>
Support **S3 Lifecycle and Versioning**<br>
Support **datadog monitor** , and Switching import resources<br>

At any rate, if you specify this, it will work on **Mac OS**.<br>

```
export TFIMPORTSEDOPTION=".bak"
```

## v3.1

support **Bucket ACL**, and **multiple S3 Resources**.

# Solution

 Now that DevOps has advanced, is there anything like this?<br>
I've created the infrastructure, so please "terraform import" it. It's a pain in the ass to get used to.<br>
Read the documentation from the official site every time.<br>
**This is Toil!**<br>
This tool was created with the hope that anyone can import it easily.

# Feature
- You can choose which resources to import **interactively**.
- Can save configuration information in **batches**.
- **Multiple resources** can be imported at once.
- It runs in the Bash ecosystem, so it is **OS-independent**.

# Require

 This tool needs to be able to execute the following commands.<br>
You just need to place the shell script and definition files on a linux server and it will work.

- [AWS CLI](https://aws.amazon.com/jp/cli/)
- [terraform](https://www.terraform.io/downloads)
- [peco](https://github.com/peco/peco)
- [jq](https://stedolan.github.io/jq/)
- [cURL](https://curl.se/)
- **Bash** and standard unix environment (Standard Linux commands like "grep".)

and, Set the credentials in the environment variable as in the **setup of AWS CLI**.<br>

```
$ export AWS_ACCESS_KEY_ID=xxxxxxxxxxxxxxxxxxxx
$ export AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

# Usecase
## Interactive mode

If you run it **without any arguments**, you will be in the mode of selecting the resource you want to import from the menu.

```
./tfimport.sh
```

![2](https://user-images.githubusercontent.com/22161385/152686788-26159ede-bd37-48a8-824c-474ecb9b26e7.gif)

note) Select by peco, so you can refine your search with peco.

## CLI mode

When you specify a **service name and target resource**, the selection screen does not appear, and it works in batch mode.

```
./tfimport.sh (Service:) (Target:)
```

![3](https://user-images.githubusercontent.com/22161385/152705942-447834d6-f43f-48cd-a482-07c5420093d2.gif)

note) You can save infrastructure definitions for batch processing. Definitions can be compared to detect changes.

# config file

The configuration file consists of **tilde(~) spread value**. It consists of a resource name, a refine command, and a search command.<br>

```
(1) ~ (2) ~ (3) ~ (4) ~ (5)
```

- (1) Define **Service:** Name
- (2) AWS Resource Define (This is the name of the definition written in the **Terraform document**)
- (3) Define a command to list the **target resources**. The list will be **passed to peco**.
- (4) Export **Name** Define (Define the **directory name for output**. If you define it with @@@@, the file name will be complicated, so specify the definition name)
- (5) Execute the refinement command based on the output of **"(3)"**

note) **"@@@@" is a special character** and **"(3)"** command string will be replaced.<br>
  aws s3 ls s3://@@@@/test <- "@@@@" is **converted at the output of "(3)"**.

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
ElastiCahe ~ aws_elasticache_replication_group ~ aws elasticache describe-replication-groups | jq -r ".ReplicationGroups[].ReplicationGroupId" ~ ~
```

## Multiple resources

Resources that have the **same target can be imported at once**.<br>
Define the same thing for the **service name**, and after the second line, write a special definition in **"(3)"** to replace the selection in the first line.<br>
With this feature, imports that use the **same reference ID can be extracted at once**.

example)

```
ELB ~ aws_lb ~ aws elbv2 describe-load-balancers | jq -r ".LoadBalancers[].LoadBalancerArn" | tr -d "\"" ~ echo "@@@@" | cut -d / -f 3 ~  ~
ELB ~ aws_lb_listener ~ aws elbv2 describe-listeners --load-balancer-arn @@@@ | jq -r ".Listeners[].ListenerArn" | head -1 ~ ~
ELB ~ aws_lb_target_group ~ aws elbv2 describe-listeners --load-balancer-arn @@@@ | jq -r ".Listeners[].DefaultActions[].TargetGroupArn" | head -1 ~ ~
```

note) A will be **replaced after the second line** as follows.<br>
aws_lb_listener ~ aws elbv2 describe-listeners --load-balancer-arn **@@@@** <- **"@@@@"** is aws_lb ~ aws elbv2 describe-load-balancers | jq -r ".LoadBalancers[].LoadBalancerArn" | tr -d "\""<br>
aws_lb_target_group ~ aws elbv2 describe-listeners --load-balancer-arn **@@@@** | jq -r ".Listeners[].DefaultActions[].TargetGroupArn" | head -1 <- **"@@@@"** is aws_lb ~ aws elbv2 describe-load-balancers | jq -r ".LoadBalancers[].LoadBalancerArn" | tr -d "\""<br>

## Multiple import

Import multiple resources **at once**. "ALB Listener" rules that had to be imported one at a time, such as A rules, can now be imported at once.

example) 

```
MultiListenerRule ~ aws_lb_listener_rule ~ aws elbv2 describe-listeners --load-balancer-arn @@@@ | jq -r ".Listeners[].ListenerArn" | head -1 ~ ~ @@MULTI@@ aws elbv2 describe-rules --listener-arn @@@@ | jq -r ".Rules[].RuleArn"
```

note) Definitions that contain the special character A will have their output **imported line by line, one at a time**.

## datadog monitor

**datadog monitor** can import. To do so, get **datadog API Key** and **datadog APPLICATION Key** from the **control panel of datadog** and **rewrite the config**.

- DD-API-KEY : datadog API Key
- DD-APPLICATION-KEY : datadog APPLICATION Key

```
???datadog.ini
???-H "DD-API-KEY: ???DD-API-KEY???" -H "DD-APPLICATION-KEY: ???DD-APPLICATION-KEY???" 
???datadog.provider
  api_key = "???DD-API-KEY???"
  app_key = "???DD-APPLICATION-KEY???"
```

and, set TFIMPORTENV.

```
export TFIMPORTENV=datadog
```

# options

Options should be set as environment variables using **"export"** command.<br>
Here is an example of switching to **datadog**.<br>

```
export TFIMPORTENV=datadog
```

- TFIMPORTENV

Switches the resource to be **imported**.<br>
note) **.ini file** and **provider.tf** are set to the names specified. Default is **aws**.<br>

```
export TFIMPORTENV=datadog
```

- TFIMPORTPATH

With this definition, terraform and peco will be used in the **specified path**<br>

note) The default is the **current directory**.<br>

```
export TFIMPORTPATH=/usr/bin
```

- TFIMPORTSEDOPTION

Avoid failures due to differences in option specifications on **Mac OS** by specifying options in advance.<br>

```
export TFIMPORTSEDOPTION=".bak"
```

- TFIMPORTINI

Specifies the location of the **definition file**.<br>

note) The default is the **current directory**.<br>


```
export TFIMPORTPATH="~/test/tfimport.ini"
```

- TFIMPORTSED

Change **special characters**.<br>

note) The default is **"@@@@"**.<br>

```
export TFIMPORTSED="####"
```

- TFIMPORTINIT

Set this if you want to do **"terraform init"**.<br>

note) It is **not init** by default.<br>

```
export TFIMPORTINIT="yes"
```

- TFIMPORTREGION

Define the **region**.<br>

note) It is **ap-northeast-1** by default.<br>
note) If you want to **specify a global region such as CloudFront**, you will need to change this.<br>

```
export TFIMPORTREGION="us-east-1"
```

- TFIMPORTPROVIDER

Specify the version of "**AWS Provider**".

note) It is **>= 3.26.0** by default.<br>

```
export TFIMPORTPROVIDER="~> 3.74.2"
```

- TFIMPORTPECOSED

Change **special characters**.<br>

note) The default is **"@@PECO@@"**.<br>

```
export TFIMPORTPECOSED="##PECO##"
```

Used to select and narrow down the target resources as follows.

```
ListenerRule ~ aws_lb ~ aws elbv2 describe-load-balancers | jq -r ".LoadBalancers[].LoadBalancerArn" | tr -d "\"" ~ echo "@@@@" | cut -d / -f 3 ~  ~
ListenerRule ~ aws_lb_listener_rule ~ aws elbv2 describe-listeners --load-balancer-arn @@@@ | jq -r ".Listeners[].ListenerArn" | head -1 ~ ~ aws elbv2 describe-rules --listener-arn @@@@ | jq -r ".Rules[].RuleArn" | @@PECO@@
```

- TFIMPORTMULTIEXPORT

Change **special characters**.<br>

note) The default is **"@@MULTI@@"**.<br>

```
export TFIMPORTMULTIEXPORT="##MULTI##"
```

import multiple resources if they contain strings defined as follows.

```
LMultiListenerRule ~ aws_lb_listener_rule ~ aws elbv2 describe-listeners --load-balancer-arn @@@@ | jq -r ".Listeners[].ListenerArn" | head -1 ~ ~ @@MULTI@@ aws elbv2 describe-rules --listener-arn @@@@ | jq -r ".Rules[].RuleArn"
```

note) It works if it is defined at the beginning or at the end.

# license
MIT License
