# Thông Tin Deploy — Checkpoint 5

> Điền file này sau khi deploy xong. `pytest tests/test_cp5.py` đọc file này
> để tìm địa chỉ service của bạn và gọi thử.
>
> **Chỉ ghi TÊN biến môi trường, tuyệt đối không dán giá trị API key vào đây.**
> Repo này công khai — dán khóa vào là mất khóa.

## Thông Tin Học Viên

| Mục | Nội dung |
|-----|----------|
| Họ và tên | Nguyen Huy Anh |
| Mã học viên | 2A202601641 |
| Repo | https://github.com/Hank2714/Day12-2A202601641-NguyenHuyAnh |

## Service

| Mục | Nội dung |
|-----|----------|
| Public URL | https://day12-agent-qmot.onrender.com |
| Platform | Render |
| Ngày deploy | 2026-08-10 |

## Biến Môi Trường Đã Set Trên Cloud

Ghi tên biến và **nguồn giá trị**, không ghi giá trị:

| Biến | Đã set | Ghi chú |
|------|--------|---------|
| `PORT` | ✅ | platform tự gán |
| `AGENT_API_KEY` | ✅ | đặt trong dashboard, không nằm trong repo |
| `REDIS_URL` | ✅ | Render Redis Add-on |
| `RATE_LIMIT_PER_MINUTE` | ✅ | 10 |
| `MONTHLY_BUDGET_USD` | ✅ | 10.0 |
| `LOG_LEVEL` | ✅ | INFO |

## Lệnh Kiểm Tra

```bash
# 1. Liveness
curl https://day12-agent-qmot.onrender.com/health

# 2. Readiness
curl https://day12-agent-qmot.onrender.com/ready

# 3. Không có API key → 401
curl -X POST https://day12-agent-qmot.onrender.com/ask \
  -H "Content-Type: application/json" \
  -d '{"question":"Hello"}'

# 4. Có API key → 200
curl -X POST https://day12-agent-qmot.onrender.com/ask \
  -H "Content-Type: application/json" \
  -H "X-API-Key: $AGENT_API_KEY" \
  -H "X-User-Id: sv-test" \
  -d '{"question":"Deploy là gì?"}'
```

## Kết Quả Chạy Thật

```
# /health
{"status":"ok","service":"day12-agent","version":"1.0.0"}

# /ready
{"status":"ready","redis":true}

# /ask (với API key)
{"answer":"...","user_id":"sv-test","history_length":1,...}
```

## Ảnh Chụp Màn Hình

- `screenshots/dashboard.png` — trang quản lý service trên Render
- `screenshots/health.png` — kết quả gọi `/health`
