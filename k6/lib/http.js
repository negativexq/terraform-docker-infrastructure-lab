import http from "k6/http";

export const BASE_URL = __ENV.K6_BASE_URL || "http://terraform-docker-lab-development-nginx:80";

export function get(path, params = {}) {
  return http.get(BASE_URL + path, params);
}
