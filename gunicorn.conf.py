# Gunicorn configuration file
import multiprocessing
import os

# Server socket
bind = f"0.0.0.0:{os.getenv('PORT', '8000')}"
backlog = 2048

# Worker processes
workers = int(os.getenv('WEB_CONCURRENCY', multiprocessing.cpu_count() * 2 + 1))
worker_class = 'uvicorn.workers.UvicornWorker'
worker_connections = 1000
max_requests = 1000
max_requests_jitter = 50

# Timeout settings - CRITICAL FOR STARTUP
timeout = 300  # 5 minutes for worker initialization (increased from default 30s)
graceful_timeout = 30  # 30 seconds for graceful shutdown
keepalive = 5

# Logging
accesslog = '-'  # Log to stdout
errorlog = '-'   # Log to stderr
loglevel = 'info'
access_log_format = '%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s" %(D)s'

# Process naming
proc_name = 'engarde-api'

# Server mechanics
daemon = False
pidfile = None
umask = 0
user = None
group = None
tmp_upload_dir = None

# Preload app for faster worker spawning (use with caution if you have memory leaks)
preload_app = False  # Set to True after optimizing imports

# Worker lifecycle hooks
def on_starting(server):
    """Called just before the master process is initialized."""
    print("Master process starting...")

def on_reload(server):
    """Called to recycle workers during a reload."""
    print("Reloading workers...")

def when_ready(server):
    """Called just after the server is started."""
    print(f"Server is ready. Listening on: {bind}")

def worker_int(worker):
    """Called when a worker receives the SIGINT or SIGQUIT signal."""
    print(f"Worker {worker.pid} received INT/QUIT signal")

def worker_abort(worker):
    """Called when a worker receives the SIGABRT signal."""
    print(f"Worker {worker.pid} timed out and was aborted")
