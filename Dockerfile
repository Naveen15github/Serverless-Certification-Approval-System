# Stage 1: Build dependencies
FROM public.ecr.aws/lambda/python:3.11 AS builder

# Install dependencies into a temporary directory
COPY requirements.txt .
RUN pip install -r requirements.txt --target /var/task/

# Stage 2: Final image
FROM public.ecr.aws/lambda/python:3.11

# Copy dependencies from builder stage
COPY --from=builder /var/task/ /var/task/

# Copy all function code
COPY submit_request.py /var/task/
COPY notify_manager.py /var/task/
COPY handle_approval.py /var/task/
COPY check_status.py /var/task/

# Default command (will be overridden by Terraform for each specific Lambda function)
CMD ["submit_request.lambda_handler"]
