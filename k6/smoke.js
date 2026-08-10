import { check } from "k6";
import { get } from "./lib/http.js";

const p95LimitMs = Number(__ENV.K6_P95_LIMIT_MS || 1000);

export const options = {
  vus: Number(__ENV.K6_VUS || 1),
  duration: __ENV.K6_DURATION || "15s",
  thresholds: {
    http_req_failed: ["rate<" + (__ENV.K6_ERROR_RATE_LIMIT || 0.01)],
    http_req_duration: ["p(95)<" + p95LimitMs],
  },
};

export default function () {
  ["/", "/health", "/db-health"].forEach((path) => {
    const response = get(path);
    check(response, {
      [path + " returns 200"]: (result) => result.status === 200,
    });
  });
}
