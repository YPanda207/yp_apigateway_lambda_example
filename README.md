# API Gateway → VPC Lambda Architecture
## Request flow step-by-step
- Let’s walk through what happens when someone hits your API:
1. Client sends HTTPS request to: https://abc123.execute-api.us-west-2.amazonaws.com/hello
2. API Gateway receives the request at the public endpoint:
    - Validates route (ANY /hello)
    - Runs auth (if configured: JWT, IAM, Lambda authorizer, etc.)
    - Prepares an event payload for Lambda
3. API Gateway → Lambda Service:
    - API Gateway calls the Lambda service (still not your VPC yet)
    - This is all within AWS’s own internal control plane
4. Lambda Service → ENI in your VPC:
    - Lambda service picks one of your configured subnets from subnet_ids
    - It ensures there is an ENI in that subnet with your security groups
    - It runs your code as if it were an instance inside that subnet
5. Lambda → other resources (inside VPC or via NAT):
    - If your Lambda calls RDS/Redis/etc. in the same VPC, traffic stays internal
    - If it calls the internet (e.g., external API), it follows:
        - Lambda ENI → Subnet Route Table → NAT Gateway → Internet Gateway → External Service
6. Response back to client:
    - Your Lambda returns a response to the Lambda service
    - Lambda service returns to API Gateway
    - API Gateway formats it as an HTTP response and sends back to the client
NOTE: At no point is your Lambda function directly exposed to the internet.
All internet exposure is at API Gateway, which then internally triggers Lambda.

---

## 🖤 Architecture Diagram (Dark Code Block)
This section shows how API Gateway interacts with a Lambda function that is deployed **inside a VPC**.  
The diagram is rendered inside a **dark-style code block** for readability in dark mode.
```txt
#######################################################################
#                  API Gateway → VPC Lambda Architecture              #
#                         (Dark Mode Code Block)                      #
#######################################################################

                    (Public Internet)
                           |
                     [ Client (Browser, Mobile) ]
                           |
                           v
                 +-------------------------+
                 |     API Gateway (HTTP) |
                 |  Public HTTPS Endpoint |
                 +-------------------------+
                           |
             (AWS internal network, NOT your VPC)
                           |
                           v
                 +-------------------------+
                 |      Lambda Service    |
                 +-------------------------+
                           |
                        (Invokes your Lambda
        via Elastic Network Interface(ENI) inside your VPC)
                           |
=================================================================
|                     Your VPC (10.0.0.0/16)                     |
|                                                                |
|   +---------------------------+                                |
|   |   Private Subnet A       |                                 |
|   |   (10.0.1.0/24)          |                                 |
|   |                          |                                 |
|   |   +-------------------+  |                                 |
|   |   |   VPC Lambda      |  |                                 |
|   |   |  (hello_vpc)      |  |                                 |
|   |   +-------------------+  |                                 |
|   |           |              |                                 |
|   |        [ ENI ]           |                                 |
|   +-----------|--------------+                                 |
|               |   (has IP in this subnet)                      |
|    +----------v-------------------------------+                |
|    |   Security Group (lambda_sg)             |                |
|    |   - inbound/outbound firewall rules      |                |
|    +---------------------------^--------------+                |
|                                |                               |
|                         Route Table                            |
|                                |                               |
|                    +-----------v-----------+                   |
|                    |       NAT Gateway     |                   |
|                    +-----------|-----------+                   |
|                                |                               |
|                          Internet Gateway                      |
=================================================================
# Key points:
- API Gateway is NOT inside your VPC.
- It’s a managed, public AWS service that exposes HTTPS endpoints.
- API Gateway talks to Lambda over the AWS internal network, not over the internet.
- Lambda, when configured with vpc_config { subnet_ids, security_group_ids }, gets an ENI inside your private subnet(s).

```

## Setting up the AWS/Terraform:
### Install Terraform:
    - brew tap hashicorp/tap
        - NOTE: 
            - Terraform is now under the BUSL license → so it cannot be in homebrew-core.
            - Therefore, to install Terraform officially on macOS, you must install from the vendor `tap`
    - brew install hashicorp/tap/terraform
    - To verify:
        - terraform -version
    - brew install tflint
        - cmd: tflint
        - NOTE:
            - This is for terraform linting
    - brew install tfsec
        - cmd: tfsec .
        - NOTE:
            - Terraform Security Scanner scans your code for security misconfigurations.
### Install AWS-CLI:
    - brew install awscli
    - aws --version
    - aws configure:
        - AWS Access Key ID (None)
        - AWS Secret Access Key (None)
        - Default region name (us-east-1)
        - Default output format (json)
        - NOTE:
            - This creates:
                - ~/.aws/credentials
                - ~/.aws/config
### Steps to run the terrafom:
    - Move to the directory where the infrastructure code is written:
    - Then run below cmd:
        - terraform init
        - terraform fmt
        - terraform validate
        - terraform plan
            - terraform plan -out=tfplan.out (OPTIONAL CMD)
            - terraform show tfplan.out
        - terraform apply tfplan.out (Optional if you are planning to actual deployment)
        - terraform destroy