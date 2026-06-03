from __future__ import annotations

import time
import uuid
from collections import defaultdict, deque

from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import JSONResponse


class SecurityMiddleware(BaseHTTPMiddleware):
    def __init__(
        self,
        app,
        max_requests: int = 120,
        window_seconds: int = 60,
    ):
        super().__init__(app)
        self.max_requests = max_requests
        self.window_seconds = window_seconds
        self.requests: dict[str, deque[float]] = defaultdict(deque)

    async def dispatch(self, request: Request, call_next):
        start_time = time.perf_counter()
        request_id = str(uuid.uuid4())

        client_host = (
            request.client.host
            if request.client
            else "unknown"
        )

        now = time.time()
        bucket = self.requests[client_host]

        while bucket and now - bucket[0] > self.window_seconds:
            bucket.popleft()

        if len(bucket) >= self.max_requests:
            return JSONResponse(
                status_code=429,
                content={
                    "detail": "Demasiadas solicitudes. Intenta nuevamente en unos segundos.",
                    "request_id": request_id,
                },
                headers={
                    "X-Request-ID": request_id,
                },
            )

        bucket.append(now)

        try:
            response = await call_next(request)
        except Exception:
            raise
        finally:
            duration = time.perf_counter() - start_time
            print(
                "[REQUEST]",
                f"id={request_id}",
                f"ip={client_host}",
                f"method={request.method}",
                f"path={request.url.path}",
                f"duration={duration:.3f}s",
            )

        response.headers["X-Request-ID"] = request_id
        response.headers["X-Process-Time"] = f"{time.perf_counter() - start_time:.3f}"

        return response
