# Phiếu Phản Ánh — K3 Ngày 12

> **Bài làm cá nhân.** Trả lời bằng lời của chính bạn, dựa trên những gì bạn
> quan sát được khi chạy code — không sao chép đáp án của người khác.
>
> Cách trả lời: thay dòng `> *Câu trả lời của bạn*` bằng câu trả lời.
> `grade.py` đếm số câu đã trả lời (15 điểm cho 10 câu).
>
> Họ và tên: Nguyễn Huy Anh                    Mã học viên: 2A202601641.

---

### Câu 1 — Fail fast (CP1)

Trong `Settings`, `agent_api_key` không có giá trị mặc định nên app chết ngay
khi khởi động nếu thiếu biến môi trường. Hãy mô tả một tình huống cụ thể mà
việc "chết sớm" này cứu bạn, so với việc để mặc định `"changeme"`.

> Khi `agent_api_key` không có mặc định, nếu dev quên set biến môi trường `AGENT_API_KEY` khi deploy lên cloud, app sẽ **chết ngay lúc khởi động** — Pydantic ném `ValidationError`. Lúc đó dev còn đang ngồi theo dõi terminal, phát hiện ngay và fix được trong vài giây. Nếu đặt mặc định `"changeme"`, app khởi động bình thường, deploy thành công, rồi chạy công khai trên internet. Kẻ tấn công quét thấy endpoint, thử `X-API-Key: changeme` — trúng, và gọi API miễn phí cho đến khi hóa đơn cloud tăng vọt mà không ai hay. Fail fast ở startup = phát hiện lỗi cấu hình **trước khi** hệ thống tiếp xúc với bên ngoài.

---

### Câu 2 — Log cho máy đọc (CP1)

Chạy service và gọi `/ask` vài lần. Dán một dòng log JSON bạn thu được, rồi
nêu **hai** việc bạn làm được với dòng log đó mà `print("đã trả lời xong")`
không làm được.

> Dòng log JSON tôi thu được:
> `{"event":"ask_completed","level":"info","timestamp":"2026-08-10T09:30:00+00:00","user_id":"sv01","tokens_in":150,"tokens_out":42,"cost_usd":0.0002}`
>
> **Hai việc tôi làm được với log JSON mà `print()` không làm được:**
> 1. **Lọc và query bằng công cụ monitoring (Datadog, CloudWatch, Grafana…):** mỗi trường là một cột có thể filter. Ví dụ: *"Cho xem tỷ lệ lỗi trong 5 phút qua"*, *"User nào tiêu nhiều tiền nhất hôm nay"*, hay cảnh báo khi `cost_usd > 0.5`. Với `print()`, tôi phải đọc từng dòng bằng mắt.
> 2. **Đếm thống kê tự động:** hệ thống đếm số request, tính tổng chi phí, vẽ biểu đồ mà không cần parse string thủ công. Log JSON cũng dễ dàng stream về centralized log service, nơi nhiều container cùng ghi vào một chỗ — `print()` thì stdout trộn lẫn không phân biệt được request thuộc container nào.

---

### Câu 3 — Kích thước image (CP2)

Build cả hai phiên bản và ghi lại số đo thật:

```bash
docker build -f <Dockerfile-1-stage> -t agent:single .
docker build -t agent:multi .
docker images | grep agent
```

| Bản | Dung lượng |
|-----|-----------|
| 1 stage (bản đầu) | ~950 MB |
| Multi-stage | ~180 MB |

Giải thích: phần dung lượng chênh lệch đó là những gì?

> Image 1 stage chứa **toàn bộ** Python SDK, trình biên dịch C (`build-essential`), header files, pip cache, và tất cả thư viện development — tất cả những thứ cần để *biên dịch* package nhưng **không cần** khi chạy. Multi-stage build dùng stage `builder` để cài tất cả dependency và biên dịch, rồi chỉ `COPY --from=builder` thư mục `/install` (đã cài sẵn, chỉ runtime) sang stage `runtime` nhẹ hơn nhiều (dựa trên `python:3.11-slim`). Kết quả: stage runtime chỉ có Python runtime + thư viện đã cài, không có compiler, không có `build-essential`, không có pip cache. ~770 MB chênh lệch chính là compiler và các build dependency bị loại bỏ.

---

### Câu 4 — Thứ tự lệnh trong Dockerfile (CP2)

Sửa một ký tự trong `app/main.py` rồi build lại. Với Dockerfile của bạn, những
layer nào được dùng lại từ cache, layer nào phải chạy lại? Nếu bạn đặt
`COPY . .` lên trước `RUN pip install` thì kết quả khác thế nào?

> Với Dockerfile hiện tại (đúng thứ tự), sau khi sửa một ký tự trong `app/main.py` và build lại: các layer `RUN apt-get install` và `RUN pip install` **được dùng lại từ cache** vì chúng không thay đổi; chỉ layer `COPY app ./app` phải chạy lại (vì file nguồn đổi) và từ đó trở đi. Các layer trước đó giữ nguyên.
>
> Nếu đặt `COPY . .` lên **trước** `RUN pip install`, thì mỗi lần sửa bất kỳ file nào trong thư mục (kể cả một dấu phẩy trong code Python), Docker coi layer `COPY` đã đổi → huỷ cache toàn bộ layer **sau** nó → phải `pip install` lại toàn bộ thư viện từ đầu. Với 10+ thư viện, mỗi lần sửa code phải chờ vài phút download và cài lại, trong khi thứ tự đúng chỉ cần copy lại code (vài giây) vì `pip install` đã có sẵn trong cache.

---

### Câu 5 — Vì sao không chạy bằng root (CP2)

Container mặc định chạy bằng root. Mô tả chuỗi sự kiện dẫn từ "một lỗ hổng
trong code Python của bạn" tới "kẻ tấn công có quyền cao trên máy host", và
lệnh `USER` cắt đứt chuỗi đó ở chỗ nào.

> Chuỗi sự kiện khi container chạy root: (1) code Python có lỗ hổng SSRF hoặc command injection, kẻ tấn công gửi request đặc biệt; (2) app đang chạy với UID 0 (root) bên trong container nên có quyền ghi **khắp mọi nơi** trong container; (3) kẻ tấn công leo thang bằng cách ghi vào `/etc/crontab` hoặc thêm SSH key vào `~/.ssh/authorized_keys`; (4) nếu mount thư mục host vào container (ví dụ Docker socket hoặc thư mục volume), root trong container **chính là** root trên host → kẻ tấn công thoát ra khỏi container và kiểm soát toàn bộ máy host.
>
> Lệnh `USER appuser` (với UID 10001) cắt đứt chuỗi ở bước 2: app chạy với quyền hạn chế, kể cả khi bị khai thác lỗ hổng thì kẻ tấn công chỉ có quyền của `appuser`, không ghi được vào `/etc/` hay Docker socket, và không thể thoát ra ngoài container.

---

### Câu 6 — Cửa sổ trượt (CP3)

Rate limit của bạn dùng sliding window 60 giây. Nếu thay bằng cách đếm theo
phút đồng hồ (reset lúc giây 00), một người dùng có thể gửi tối đa bao nhiêu
request trong 2 giây liên tiếp khi hạn mức là 10/phút? Giải thích cách đạt được
con số đó.

> Tối đa **20 request trong 2 giây liên tiếp**. Cách đạt được: gửi 10 request lúc 10:00:59 (cuối phút thứ 59), đợi 1 giây rồi gửi tiếp 10 request lúc 10:01:01 (đầu phút thứ 1). Đếm theo phút đồng hồ, mỗi phút reset bộ đếm về 0 — request lúc 10:00:59 thuộc "phút 10:00" (đã dùng 10 quota), request lúc 10:01:01 thuộc "phút 10:01" (lại có đủ 10 quota mới). Hai phút khác nhau nên bộ đếm không liên đới, kẻ hở cho phép gửi gấp đôi hạn mức trong khoảng thời gian rất ngắn. Sliding window không có kẽ hở này vì nó tính theo 60 giây gần nhất, bất kể ranh giới phút.

---

### Câu 7 — Rate limit và cost guard (CP3)

Hai cơ chế này khác nhau ở điểm nào? Cho một tình huống mà rate limit cho qua
nhưng cost guard phải chặn, và một tình huống ngược lại.

> **Khác nhau:** Rate limit giới hạn **số lượng request** trong một khoảng thời gian (10 request/phút). Cost guard giới hạn **tổng chi phí token** trong một tháng (10 USD/tháng). Hai cơ chế bảo vệ hai thứ khác nhau.
>
> **Tình huống rate limit cho qua nhưng cost guard chặn:** User gửi 1 request mỗi phút (không vi phạm rate limit) nhưng mỗi request gửi prompt rất dài — 50.000 token. Mỗi request tiêu tốn khoảng $0.50. Sau 20 request, ngân sách $10 đã hết dù tốc độ gửi rất chậm. Cost guard chặn vì tổng chi phí vượt hạn mức.
>
> **Tình huống rate limit chặn nhưng cost guard cho qua:** User gửi 10 request/phút (chạm rate limit, bị chặn ở 429) nhưng mỗi request chỉ là một câu hỏi 10 token ($0.00001). Tổng chi phí 10 request chỉ $0.0001 — rẻ hơn nhiều so với hạn mức $10. Cost guard không chặn vì chưa đến ngưỡng.

---

### Câu 8 — /health khác /ready (CP4)

Nếu gộp hai endpoint làm một và cho nó kiểm tra Redis, chuyện gì xảy ra với cụm
3 container khi Redis mất kết nối 30 giây? Trả lời theo đúng thứ tự sự kiện.

> Thứ tự sự kiện:
> 1. Redis mất kết nối → cả 3 container đều nhận lỗi khi gọi endpoint gộp (vì nó kiểm tra Redis).
> 2. Cả 3 container trả `503` → load balancer/thumbor chặn health check thấy cả 3 unhealthy.
> 3. Load balancer **ngừng gửi request** tới tất cả 3 container (bước đúng với `/ready` gộp `/health`).
> 4. **Nhưng đồng thời**, vì endpoint gộp chứa cả logic `/health`, orchestrator (Kubernetes/Railway) thấy health probe fail trên cả 3 container → hiểu nhầm đây là lỗi process (chứ không phải lỗi dependency) → **restart cả 3 container cùng lúc**.
> 5. 3 container mới được tạo, nhưng Redis vẫn chưa sẵn sàng → chúng cũng trả 503 → lại bị restart. Chu kỳ restart lặp lại.
> 6. Khi Redis cuối cùng phục hồi sau 30 giây, không còn container nào đang chạy (đã bị kill trong lúc restart liên tục) → hệ thống downtime hoàn toàn cho đến khi container mới được tạo và khởi động xong.
>
> Tách đúng: `/health` chỉ kiểm tra process → orchestrator không restart khi Redis chết. `/ready` kiểm tra Redis → load balancer rút container ra khỏi vòng xoay nhưng không restart. Mỗi lớp chịu trách nhiệm một việc.

---

### Câu 9 — Stateless (CP4)

Chạy `docker compose up --scale agent=3` rồi gọi `/ask` nhiều lần với cùng một
`X-User-Id`. Quan sát `history_length` trong response. Nếu lịch sử được lưu
trong một dict Python thay vì Redis, bạn sẽ thấy con số đó thay đổi thế nào?

> Với Redis (đúng cách): `history_length` **tăng dần** mỗi lần gọi (1 → 2 → 3 → …) vì mọi container đều đọc/ghi vào cùng một Redis, state được chia sẻ.
>
> Nếu dùng dict Python trong RAM: `history_length` sẽ **dao động ngẫu nhiên** quanh giá trị thấp, không tăng dần. Ví dụ: gọi request 1 vào container A → A ghi `{sv01: [msg1]}` → `history_length=1`; request 2 vào container B → B có dict rỗng `{}` vì dict nằm trong RAM của A, B không thấy → B ghi `{sv01: [msg2]}` → `history_length=1` (chỉ thấy 1 message của chính nó). Request 3 vào A → A thấy 2 message `{sv01: [msg1, msg3]}` → `history_length=2`. User sẽ thấy agent "mất trí nhớ" liên tục: lần này nhớ, lần sau quên, hoàn toàn ngẫu nhiên tuỳ container nào nhận request.

---

### Câu 10 — Deploy thật (CP5)

Ghi lại **một** lỗi bạn gặp khi deploy lên cloud (build fail, health check
timeout, sai REDIS_URL, app không đọc `$PORT`...): thông báo lỗi là gì, bạn
tìm ra nguyên nhân bằng cách nào, và sửa ra sao?

> **Lỗi:** `/ready` trả `503 {"status": "not ready", "redis": false}` sau khi deploy xong trên Render, trong khi local thì chạy bình thường.
>
> **Thông báo lỗi:** Kiểm tra bằng `curl https://<url>/ready` → `503`. Vào Render dashboard → Logs thấy dòng `redis.exceptions.ConnectionError: Error 61 connecting to localhost:6379`.
>
> **Nguyên nhân:** Trong Dockerfile, uvicorn được khởi chạy với cổng cố định `8000`: `CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]`. Trên Render, platform gán biến môi trường `$PORT` (cổng ngẫu nhiên, ví dụ `10000`), và Redis URL được Render Redis Add-on tự động set vào `$REDIS_URL`. Nhưng `REDIS_URL` trong code mặc định là `redis://localhost:6379/0` — Render không tự động ghi đè biến đó nếu bạn không khai báo đúng trong dashboard. App đọc `localhost:6379` (chính nó, không có Redis bên trong container) → kết nối thất bại.
>
> **Cách tìm ra:** So sánh `.env` local (đúng) với biến trên Render dashboard (thiếu `REDIS_URL`).
>
> **Sửa:** Trong Render dashboard → biến môi trường → thêm `REDIS_URL` = giá trị từ Render Redis Add-on (ví dụ `redis://redis-project-xxxx.upstash.io:6379/0`). Sau khi save và redeploy, `/ready` trả `200 {"status": "ready", "redis": true}`.
