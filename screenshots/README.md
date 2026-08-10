# Screenshots

Ảnh chụp màn hình bản deploy thực tế trên Render: https://day12-agent-qmot.onrender.com

## Xác minh Deploy

### Docker Compose Status
```
NAME                                         IMAGE                                          COMMAND                  SERVICE   CREATED          STATUS          PORTS
day12-2a202601641-nguyenhuyanh-redis-1       redis:7-alpine                                 "docker-entrypoint.s…"   redis     5 minutes ago   Up 2 minutes    0.0.0.0:6379->6379/tcp
day12-2a202601641-nguyenhuyanh-agent-1       day12-2a202601641-nguyenhuyanh-agent:latest   "sh -c 'uvicorn app.m…"   agent     5 minutes ago   Up 2 minutes    0.0.0.0:8000->8000/tcp
```

### Health Check
```
$ curl https://day12-agent-qmot.onrender.com/health
{"status":"ok","service":"day12-agent","version":"1.0.0"}
```

### Ready Check
```
$ curl https://day12-agent-qmot.onrender.com/ready
{"status":"ready","redis":true}
```

### /ask with API Key
```
$ curl -X POST https://day12-agent-qmot.onrender.com/ask \
    -H "X-API-Key: <AGENT_API_KEY>" \
    -H "X-User-Id: sv-test" \
    -d '{"question":"Test"}'
{"answer":"...","user_id":"sv-test","history_length":0,...}
```
