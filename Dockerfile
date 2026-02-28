# Multi-stage Dockerfile for NER Classification Pipeline
# Stage 1: Build Python environment
FROM python:3.9-slim as python-builder

WORKDIR /build

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    make \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python packages
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# Stage 2: Build R environment
FROM rocker/r-ver:4.3 as r-builder

# Install R package dependencies
RUN install2.r --error --deps TRUE \
    tidyverse \
    knitr \
    rmarkdown \
    DT \
    plotly \
    scales \
    jsonlite \
    yaml \
    kableExtra \
    reticulate

# Stage 3: Final production image
FROM python:3.9-slim

LABEL maintainer="your.email@example.com"
LABEL description="NER Classification Pipeline with MLOps"
LABEL version="1.0"

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    # R runtime
    r-base \
    r-base-dev \
    # Pandoc for R Markdown
    pandoc \
    pandoc-citeproc \
    # System utilities
    curl \
    wget \
    git \
    # Fonts for reports
    fonts-liberation \
    # Cleanup
    && rm -rf /var/lib/apt/lists/*

# Create app user (non-root)
RUN useradd -m -u 1000 appuser && \
    mkdir -p /app /data /models /reports && \
    chown -R appuser:appuser /app /data /models /reports

# Set working directory
WORKDIR /app

# Copy Python packages from builder
COPY --from=python-builder /root/.local /home/appuser/.local

# Copy R libraries from builder
COPY --from=r-builder /usr/local/lib/R/site-library /usr/local/lib/R/site-library

# Copy application code
COPY --chown=appuser:appuser src/ ./src/
COPY --chown=appuser:appuser scripts/ ./scripts/
COPY --chown=appuser:appuser models/ ./models/
COPY --chown=appuser:appuser reports/ ./reports/
COPY --chown=appuser:appuser requirements.txt .

# Create necessary directories
RUN mkdir -p data/raw data/processed mlruns

# Switch to app user
USER appuser

# Add local bin to PATH
ENV PATH=/home/appuser/.local/bin:$PATH

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import src.python.ner_classifier; print('OK')" || exit 1

# Default command
CMD ["python", "-m", "src.python.train_model", "data/sample_transactions.csv"]

# Expose ports
# 8000 for FastAPI
# 5000 for MLflow UI
EXPOSE 8000 5000

# Volume mounts for persistence
VOLUME ["/app/data", "/app/models", "/app/mlruns", "/app/reports"]

# Metadata
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

LABEL org.opencontainers.image.created=$BUILD_DATE \
      org.opencontainers.image.revision=$VCS_REF \
      org.opencontainers.image.version=$VERSION \
      org.opencontainers.image.title="NER Classification Pipeline" \
      org.opencontainers.image.description="Automated transaction classification with MLOps" \
      org.opencontainers.image.source="https://github.com/yourusername/Local_NER"