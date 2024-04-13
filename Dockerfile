# Use an official Python runtime as a parent image
FROM python:3.9-slim

# Set environment variables to ensure Python outputs all logs and output directly to the terminal without buffering
ENV PYTHONUNBUFFERED 1

# Set the working directory in the container
WORKDIR /usr/src/app

# Copy the local directory contents into the container
COPY . /usr/src/app

# Install any needed packages specified in requirements.txt
RUN pip install --upgrade pip && \
    pip install virtualenv && \
    virtualenv -p python3 /usr/src/venv && \
    . /usr/src/venv/bin/activate && \
    pip install -r jely/requirements.txt

# Copy settings template and update manually or with a script
# Note: For production, consider using environment variables or a configuration management tool instead of hardcoding
COPY jely/settings.py.txt jely/settings.py

# Make port 8000 available to the world outside this container
EXPOSE 8000

# Run database migrations
RUN . /usr/src/venv/bin/activate && \
    python jely/manage.py migrate

# Define command to start the server
CMD . /usr/src/venv/bin/activate && \
    python jely/manage.py runserver 0.0.0.0:8000

# Optionally include a health check (requires curl to be installed)
# HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
#    CMD curl -f http://localhost:8000/ || exit 1
