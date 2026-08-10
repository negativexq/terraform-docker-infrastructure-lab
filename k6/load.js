import { check } from "k6";
import { get } from "./lib/http.js";

const p95LimitMs = Number(__ENV.K6_P95_LIMIT_MS || 1000);
const peakVus = Number(__ENV.K6_LOAD_PEAK_VUS || 10);
const rampSeconds = Number(__ENV.K6_LOAD_RAMP_SECONDS || 15);
const steadySeconds = Number(__ENV.K6_LOAD_STEADY_SECONDS || 30);

export const options = {
  stages: [
    { duration: rampSeconds + "s", target: peakVus },
    { duration: steadySeconds + "s", target: peakVus },
    { duration: rampSeconds + "s", target: 0 },
  ],
  thresholds: {
    http_req_failed: ["rate<" + (__ENV.K6_ERROR_RATE_LIMIT || 0.01)],
    http_req_duration: ["p(95)<" + p95LimitMs],
  },
};

export default function () {
  const response = get(__ENV.K6_LOAD_PATH || "/health");
  check(response, {
    "load request returns 200": (result) => result.status === 200,
  });
}
