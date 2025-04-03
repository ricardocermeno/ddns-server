#!/bin/sh

# Start lambdarpc in the background
/var/task/lambdarpc &

# Start dlv and keep it in the foreground
exec dlv --listen=:4000 --headless=true --api-version=2 --accept-multiclient exec /var/task/main --continue
