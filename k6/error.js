import { Rate } from "k6/metrics";
import { check } from "k6";
import { get } from "./lib/http.js";

const controlledErrors = new Rate("controlled_error_rate");

export const options = {
  vus: Number(__ENV.K6_ERROR_VUS || 5),
  duration: __ENV.K6_ERROR_DURATION || "75s",
  thresholds: {
    http_req_failed: ["rate<1.01"],
    http_req_duration: ["p(95)<" + Number(__ENV.K6_ERROR_P95_LIMIT_MS || 2000)],
    controlled_error_rate: ["rate>0.90"],
  },
};

export default function () {
  const response = get(__ENV.K6_ERROR_PATH || "/_test/error");
  controlledErrors.add(response.status === 500);
  check(response, {
    "controlled error returns 500": (result) => result.status === 500,
  });
}
