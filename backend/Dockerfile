# Use an official Python runtime as a parent image
FROM python:3.10-slim

# Set the working directory in the container
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . /app

# Install dependencies from the requirements.txt file
RUN pip install --no-cache-dir -r requirements.txt

# Install additional system dependencies (e.g., curl or build tools) if needed
# RUN apt-get update && apt-get install -y build-essential

# Expose the port FastAPI will run on
EXPOSE 8000

# Set environment variables
ENV GROQ_API_KEY=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

# Run the application with uvicorn
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
