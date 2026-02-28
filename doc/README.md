# Serverless Cert Approval End to End

This guide provides step-by-step instructions on how to manually create the Serverless Certification Approval System resources using the AWS Management Console UI.

## Architecture Overview

1. **DynamoDB**: Stores the certification requests.
2. **IAM Roles**: Provides permissions for Lambda and Step Functions.
3. **Lambda Functions (4)**: Compute functions to handle business logic.
4. **Step Functions**: Orchestrates the approval workflow.
5. **API Gateway**: Provides an HTTP endpoint to interact with the system.

_(Note: In the fully automated setup, the Lambda functions are containerized. For manual setup via the console, we assume you are deploying standard Python 3.11 `.zip` or inline code for simplicity)._

---

## Step 1: Create DynamoDB Table

1. Navigate to **DynamoDB** in the AWS Console.
2. Click **Create table**.
3. **Table name**: `cert-approval-requests-dev`
4. **Partition key**: `requestId` (String).
5. Leave settings as Default (or choose On-Demand Capacity).
6. Click **Create table**.

---

## Step 2: Create IAM Roles

We need two roles: one for Lambda and one for Step Functions.

### A. Lambda Execution Role

1. Navigate to **IAM** -> **Roles** -> **Create role**.
2. Select **AWS Service** -> **Lambda**.
3. Attach the following policies:
   - `AWSLambdaBasicExecutionRole` (for CloudWatch Logs).
4. Create the role and name it `cert-approval-lambda-role-dev`.
5. After creation, add an **Inline Policy** to allow DynamoDB access and Step Functions invocation:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "states:StartExecution",
           "states:SendTaskSuccess",
           "states:SendTaskFailure"
         ],
         "Resource": "*"
       },
       {
         "Effect": "Allow",
         "Action": [
           "dynamodb:PutItem",
           "dynamodb:GetItem",
           "dynamodb:UpdateItem"
         ],
         "Resource": "*"
       }
     ]
   }
   ```

### B. Step Functions Execution Role

1. Create another role. Select **AWS Service** -> **Step Functions**.
2. Name it `cert-approval-sfn-role-dev`.
3. Add an **Inline Policy** to allow it to invoke Lambda and update DynamoDB:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": ["lambda:InvokeFunction"],
         "Resource": "*"
       },
       {
         "Effect": "Allow",
         "Action": ["dynamodb:PutItem", "dynamodb:UpdateItem"],
         "Resource": "*"
       }
     ]
   }
   ```

---

## Step 3: Create Lambda Functions

You will create 4 functions. For each function:

1. Navigate to **Lambda** -> **Create function**.
2. **Author from scratch**.
3. **Runtime**: Python 3.11.
4. **Architecture**: x86_64.
5. **Execution role**: Use an existing role -> `cert-approval-lambda-role-dev`.
6. Click **Create function**.
7. Paste the code for each function into the inline editor and click **Deploy**.

Create the following four functions:

1. **`cert-approval-SubmitRequest-dev`**
   - _Environment Variables_: Need to set `STATE_MACHINE_ARN` later (after Step 4).
   - _Code_: Paste contents of `submit_request.py`.
2. **`cert-approval-NotifyManager-dev`**
   - _Code_: Paste contents of `notify_manager.py`.
3. **`cert-approval-HandleApproval-dev`**
   - _Code_: Paste contents of `handle_approval.py`.
4. **`cert-approval-CheckStatus-dev`**
   - _Environment Variables_: `TABLE_NAME` = `cert-approval-requests-dev`.
   - _Code_: Paste contents of `check_status.py`.

---

## Step 4: Create Step Functions State Machine

1. Navigate to **Step Functions** -> **State machines** -> **Create state machine**.
2. Choose **Blank**. Select the **Code** toggle.
3. Paste the Amazon States Language JSON definition. Make sure to replace the placeholder ARNs with the actual DynamoDB table ARN and Lambda function ARN (`cert-approval-NotifyManager-dev`):
   _(A sample definition matching our terraform/step_functions.tf should be used here, replacing `${aws_dynamodb_table.certification_requests.name}` with your actual table name, etc.)_
4. Click **Next**.
5. **State machine name**: `cert-approval-ApprovalStateMachine-dev`.
6. **Permissions**: Choose an existing role -> `cert-approval-sfn-role-dev`.
7. Click **Create state machine**.
8. **CRITICAL**: Copy the ARN of the State Machine you just created, go back to the `cert-approval-SubmitRequest-dev` Lambda function, and add an Environment Variable `STATE_MACHINE_ARN` with this value.

---

## Step 5: Configure API Gateway

1. Navigate to **API Gateway** -> **Create API**.
2. Choose **HTTP API**. Click **Build**.
3. **API name**: `cert-approval-api`.
4. Skip routes for now, click **Next** -> **Next** -> **Create**.
5. Once created, go to **Routes** and create three routes:
   - `POST /request`
   - `POST /approval`
   - `GET /status/{requestId}`
6. Go to **Integrations**:
   - For `POST /request`, attach an integration to the `cert-approval-SubmitRequest-dev` Lambda.
   - For `POST /approval`, attach an integration to the `cert-approval-HandleApproval-dev` Lambda.
   - For `GET /status/{requestId}`, attach an integration to the `cert-approval-CheckStatus-dev` Lambda.
     _(AWS API Gateway UI will prompt you to automatically grant permission to invoke the Lambda functions)._
7. The API is automatically deployed to the default stage. Note your **Invoke URL**.

---

## Step 6: How to Verify (End to End Testing)

### 1. Submit a Request

Use tools like Postman or `curl` using your API Gateway Invoke URL:

```bash
curl -X POST https://<API_ID>.execute-api.<REGION>.amazonaws.com/request \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","course":"AWS Certified Solutions Architect","cost":150}'
```

You should get a `requestId` back.

### 2. Verify DynamoDB

Check the **DynamoDB table** `cert-approval-requests-dev`. You should see an item with `status: PENDING`.

### 3. Retrieve Task Token

Check the **CloudWatch Logs** for the `cert-approval-NotifyManager-dev` Lambda function. It will print an `APPROVAL TOKEN: <long_string>`. Copy that token.

### 4. Approve the Request

Send a POST request to the `/approval` endpoint:

```bash
curl -X POST https://<API_ID>.execute-api.<REGION>.amazonaws.com/approval \
  -H "Content-Type: application/json" \
  -d '{"requestId":"<YOUR_REQUEST_ID>", "decision":"APPROVED", "taskToken":"<YOUR_TOKEN>"}'
```

### 5. Verify Final Status

Send a GET request to the `/status` endpoint:

```bash
curl https://<API_ID>.execute-api.<REGION>.amazonaws.com/status/<YOUR_REQUEST_ID>
```

The status should now be `APPROVED`.

**Congratulations! You have manually deployed and verified the entire Serverless application.**
