import { check } from "k6";
import { get } from "./lib/http.js";

export const options = {
  vus: Number(__ENV.K6_DOWN_VUS || 1),
  duration: __ENV.K6_DOWN_DURATION || "45s",
  thresholds: {
    http_req_failed: ["rate<1.01"],
    http_req_duration: ["p(95)<" + Number(__ENV.K6_DOWN_P95_LIMIT_MS || 2000)],
  },
};

export default function () {
  const response = get("/health");
  check(response, {
    "down-test request completes": (result) => result.status >= 200,
  });
}
