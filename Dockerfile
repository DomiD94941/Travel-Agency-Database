FROM gvenzl/oracle-xe:21-slim

# Set environment variables
ENV ORACLE_PASSWORD=admin
ENV ORACLE_DATABASE=XE
ENV ORACLE_USER=system

# Create data directory inside the container
RUN mkdir -p /opt/oracle/dane

# Copy SQL scripts and data if needed (optional)
# COPY ./main.sql /opt/oracle/scripts/startup/
# COPY ./dane /opt/oracle/dane

# Expose Oracle port
EXPOSE 1521

# Health check to ensure DB is up
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=5 \
  CMD echo 'SELECT 1 FROM DUAL;' | sqlplus -s system/admin@localhost/XEPDB1 || exit 1

# Start Oracle XE
CMD ["/bin/bash", "-c", "exec /usr/bin/startup.sh"]