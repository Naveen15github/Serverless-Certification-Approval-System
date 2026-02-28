# Frontend Setup and Testing Guide

This directory contains the user interface for the Serverless Certification Approval System. It is built using **React** equipped with **Vite** and features a modern, glassmorphism aesthetic.

The frontend provides two distinct views:

1. **Employee Portal**: For submitting new certification requests and checking their status.
2. **Manager Dashboard**: For reviewing requests using a Request ID and Task Token.

## Prerequisites

- **Node.js**: Ensure Node.js (version 16 or newer) is installed on your machine.
- **npm** or **yarn** package manager.
- An actively deployed backend (the API Gateway URL).

---

## Setup Instructions

### 1. Configure the API Endpoint

Before running the application, you must point it to your deployed AWS API Gateway endpoint.

1. Open `/src/EmployeePortal.jsx` and look for:
   ```javascript
   const API_URL = "https://YOUR_API_ID.execute-api.<region-id>.amazonaws.com";
   ```
2. Open `/src/ManagerPortal.jsx` and look for:
   ```javascript
   const API_URL = "https://YOUR_API_ID.execute-api.<region-id>.amazonaws.com";
   ```
   Replace the placeholder URLs with the actual `api_gateway_endpoint` outputted by your Terraform deployment.

### 2. Install Dependencies

Open your terminal, navigate to the `frontend` folder, and run:

```bash
npm install
```

### 3. Run the Development Server

Start the frontend application locally using Vite:

```bash
npm run dev
```

By default, the application will run at [http://localhost:5173/](http://localhost:5173/).

---

## Workflow Testing Guide

Here is how you can use the web interface to test the entire application end-to-end:

### Test 1: Employee Submission

1. Open the application in your browser and log into the **Employee Portal**.
2. Click **Submit New Request**.
3. Fill in a Name, Course Name, and Cost.
4. Click **Submit**.
5. _Success!_ A popup will give you a generated **Request ID**. Securely copy this ID as you will need it for the next steps.

### Test 2: Status Checking

1. Still in the Employee Portal, click **Check Request Status**.
2. Paste your Request ID into the field.
3. Click the search button.
4. The system should return your request details with a status of **PENDING**.

### Test 3: Manager Approval

_Note: Because we are testing locally, retrieving the Task Token necessitates looking at the backend logs. In a production system setting, this "approval link" containing the token would usually be emailed directly to the manager._

1. Using the AWS CLI, check the logs for your `NotifyManager` lambda to find your task token:
   ```bash
   aws logs filter-log-events --log-group-name /aws/lambda/cert-approval-NotifyManager-dev --region ap-south-1 --profile <your aws profile> --filter-pattern '"YOUR_REQUEST_ID_HERE"'
   ```
2. Find the message that says `APPROVAL TOKEN: AQCU...` and carefully copy the massive string.
3. In the React app, navigate to the **Manager Dashboard**.
4. Paste the **Request ID**.
5. Paste the **Task Token**.
6. Select **Approve**.
7. _Success!_ The UI will let you know the request was handled properly.
8. **Final Check**: Return to the **Employee Portal**, check your status again, and confirm it now reads **APPROVED**.

---

## Screenshots of the Frontend Application

**Employee Submit Request Portal**
![Employee Submit Portal](<your-github-url>/SCR-20260226-mdfc.png)

**Manager Approval Dashboard**
![Manager Approval](<your-github-url>/SCR-20260226-knyy.png)

**Successful Manager Approval**
![Approval Success](<your-github-url>/SCR-20260226-knxj.png)
