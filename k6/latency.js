import { Trend } from "k6/metrics";
import { check } from "k6";
import { get } from "./lib/http.js";

const controlledLatency = new Trend("controlled_latency_ms");
const delayMs = Number(__ENV.K6_DELAY_MS || 750);

export const options = {
  vus: Number(__ENV.K6_LATENCY_VUS || 5),
  duration: __ENV.K6_LATENCY_DURATION || "75s",
  thresholds: {
    http_req_failed: ["rate<0.01"],
    http_req_duration: ["p(95)<" + Number(__ENV.K6_LATENCY_MAX_P95_MS || 2000)],
    controlled_latency_ms: ["p(95)>" + Number(__ENV.K6_LATENCY_ALARM_P95_MS || 500)],
  },
};

export default function () {
  const response = get("/_test/latency?delay_ms=" + delayMs);
  controlledLatency.add(response.timings.duration);
  check(response, {
    "controlled latency returns 200": (result) => result.status === 200,
  });
}
