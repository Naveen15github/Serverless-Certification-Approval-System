# Serverless-Certification-Approval-System

![Alt text](https://github.com/Naveen15github/Serverless-Certification-Approval-System/blob/bb30a9c334b46065608fd2d82e11b629a57ce671/Gemini_Generated_Image_54rvq554rvq554rv.png)

A fully serverless, event-driven Certification Approval System built on AWS using **Step Functions, Lambda, DynamoDB, and API Gateway**.

This project demonstrates how to design and implement a **real-world asynchronous approval workflow** where human intervention (manager approval) is required before a process can proceed.

The entire architecture is implemented manually via AWS Console to deeply understand service integrations and IAM permissions.

---

## 🏗️ Architecture Overview
### Core Services Used

* **Amazon API Gateway** – Exposes HTTP endpoints
* **AWS Lambda** – Stateless compute for business logic
* **AWS Step Functions** – Orchestrates the approval workflow
* **Amazon DynamoDB** – Persistent storage for request tracking
* **AWS Identity and Access Management** – Secure service permissions

---

# 📌 Problem Statement

Organizations often require manager approval before reimbursing certification costs.

This system handles:

1. Submission of certification request
2. Workflow orchestration
3. Manager approval (async)
4. Status tracking
5. Persistent state management

The workflow pauses until the manager responds — demonstrating **callback pattern using task tokens** in Step Functions.

---

# 🔄 Workflow Execution Flow

1. User submits request → API Gateway
2. Lambda triggers Step Functions execution
3. Request stored in DynamoDB as `PENDING`
4. Manager notified with approval token
5. Workflow pauses
6. Manager approves/rejects
7. Workflow resumes
8. DynamoDB updated with final status
9. User checks status via API

---

# 🧠 Why Step Functions?

Unlike chaining Lambdas manually, Step Functions:

* Manages retries
* Handles wait states
* Tracks execution visually
* Supports callback pattern
* Maintains state machine logic clearly

This project uses a **Standard Workflow** (not Express) to support long-running approvals.

---

# 📂 Project Structure

```
.
├── src/
│   ├── submit_request.py
│   ├── notify_manager.py
│   ├── handle_approval.py
│   └── check_status.py
├── step-functions-definition.json
├── EXPLANATION.md
└── README.md
```

---

# 🛠️ Manual Deployment Guide (AWS Console)

---

## ✅ Step 1: Create DynamoDB Table

![Alt text](https://github.com/Naveen15github/Serverless-Certification-Approval-System/blob/bb30a9c334b46065608fd2d82e11b629a57ce671/Screenshot%20(447).png)

1. Open DynamoDB Console
2. Click **Create Table**
3. Table Name: `CertificationRequests`
4. Partition Key:

   * `requestId` (String)
5. Keep defaults
6. Create table

---

## ✅ Step 2: Create IAM Role for Lambda

![Alt text](https://github.com/Naveen15github/Serverless-Certification-Approval-System/blob/bb30a9c334b46065608fd2d82e11b629a57ce671/Screenshot%20(448).png)

Create role:

* Trusted Entity: Lambda
* Policies:

  * `AmazonDynamoDBFullAccess`
  * `AWSStepFunctionsFullAccess`
  * `CloudWatchLogsFullAccess`
* Role Name: `CertificationLambdaRole`

This role allows Lambda functions to:

* Write/read DynamoDB
* Start Step Function executions
* Send task success/failure callbacks
* Log to CloudWatch

---

## ✅ Step 3: Create Lambda Functions

![Alt text](https://github.com/Naveen15github/Serverless-Certification-Approval-System/blob/bb30a9c334b46065608fd2d82e11b629a57ce671/Screenshot%20(449).png)

Runtime: **Python 3.14**
Architecture: x86_64
Execution Role: `CertificationLambdaRole`

---

### 1️⃣ SubmitRequestFunction

* Stores request in DynamoDB
* Starts Step Functions execution
* Returns `requestId`

Environment Variable:

```
STATE_MACHINE_ARN = <Update After Step 4>
```

---

### 2️⃣ NotifyManagerFunction

* Logs approval task token
* Simulates sending email to manager
* Pauses workflow

---

### 3️⃣ HandleApprovalFunction

* Receives:

  * requestId
  * decision (APPROVED / REJECTED)
  * taskToken
* Calls:

  * `SendTaskSuccess`
* Updates DynamoDB

---

### 4️⃣ CheckStatusFunction

* Reads request status from DynamoDB

Environment Variable:

```
TABLE_NAME = CertificationRequests
```

---

## ✅ Step 4: Create Step Functions State Machine

![Alt text](
https://github.com/Naveen15github/Serverless-Certification-Approval-System/blob/bb30a9c334b46065608fd2d82e11b629a57ce671/Screenshot%20(450).png)

1. Open Step Functions
2. Create state machine
3. Type: **Standard**
4. Paste JSON from `step-functions-definition.json`
5. Replace placeholders:

   * `${DynamoDBTableName}`
   * `${NotifyManagerFunctionName}`
6. Name: `ApprovalStateMachine`
7. Create new execution role
8. Create

Copy the ARN.

---

## ✅ Step 5: Update SubmitRequest Lambda

Add environment variable:

```
STATE_MACHINE_ARN = arn:aws:states:region:account:stateMachine:ApprovalStateMachine
```

Save.

---

## ✅ Step 6: Create API Gateway

![Alt text](https://github.com/Naveen15github/Serverless-Certification-Approval-System/blob/bb30a9c334b46065608fd2d82e11b629a57ce671/Screenshot%20(451).png)

Create HTTP API:

Routes:

| Method | Path                 | Lambda                 |
| ------ | -------------------- | ---------------------- |
| POST   | /request             | SubmitRequestFunction  |
| POST   | /approval            | HandleApprovalFunction |
| GET    | /request/{requestId} | CheckStatusFunction    |

Deploy with `$default` stage.

Copy Invoke URL.

---

# 🧪 Testing the System

---

## 1️⃣ Submit Request

```bash
curl -X POST https://<API-URL>/request \
  -H "Content-Type: application/json" \
  -d '{"name":"Alice","course":"AWS Certified Developer","cost":150}'
```

Response:

```json
{
  "requestId": "uuid",
  "executionArn": "arn:..."
}
```

---

## 2️⃣ Check Logs for Token

Go to CloudWatch → NotifyManagerFunction logs

Copy:

```
APPROVAL TOKEN: <long-token>
```

---

## 3️⃣ Check Status

```bash
curl https://<API-URL>/request/<REQUEST-ID>
```

Response:

```json
{
  "status": "PENDING"
}
```

---

## 4️⃣ Approve Request

```bash
curl -X POST https://<API-URL>/approval \
  -H "Content-Type: application/json" \
  -d '{
    "requestId":"<REQUEST-ID>",
    "decision":"APPROVED",
    "taskToken":"<TOKEN>"
  }'
```

---

## 5️⃣ Verify Final Status

```bash
curl https://<API-URL>/request/<REQUEST-ID>
```

```json
{
  "status": "APPROVED"
}
```
![Alt text](https://github.com/Naveen15github/Serverless-Certification-Approval-System/blob/bb30a9c334b46065608fd2d82e11b629a57ce671/Screenshot%20(452).png)

---

# ⚠️ Common Issue

### ❌ Task Timed Out

Cause:

* Created **Express Workflow**

Fix:

* Use **Standard Workflow**
* Re-submit request

---

# 🎯 Key Technical Concepts Demonstrated

* Callback Pattern with Task Tokens
* State Machine Orchestration
* Asynchronous Workflows
* Serverless API Design
* IAM Role Design
* Event-driven Architecture
* Persistent State Tracking

---

# 📈 Production Improvements (Next Steps)

* Replace full-access IAM policies with least privilege
* Add SNS or SES for real email notifications
* Add authentication (Cognito / JWT)
* Add input validation
* Add cost limits and manager hierarchy
* Add CloudWatch alarms

---

# 📚 What This Project Proves

* I understand how AWS services integrate
* I can design asynchronous workflows
* I can manage IAM roles and permissions
* I can build production-style serverless systems
* I can debug Step Functions execution

This is not a tutorial clone —
It is a fully implemented, tested, and validated serverless workflow system.

**Built with AWS. Designed for real-world backend engineering.**
