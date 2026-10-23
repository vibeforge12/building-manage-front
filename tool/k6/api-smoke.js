import http from 'k6/http';
import { check } from 'k6';
import { Rate, Trend } from 'k6/metrics';

const baseUrl = (__ENV.QUALITY_API_URL || '').replace(/\/$/, '');
const p95Limit = Number(__ENV.QUALITY_API_P95_MS || 500);
const errorRateLimit = Number(__ENV.QUALITY_API_ERROR_RATE_PERCENT || 1) / 100;

const apiDuration = new Trend('quality_api_duration', true);
const apiErrors = new Rate('quality_api_errors');

export const options = {
  scenarios: {
    health: {
      executor: 'constant-vus',
      vus: Number(__ENV.QUALITY_API_VUS || 10),
      duration: __ENV.QUALITY_API_DURATION || '30s',
    },
  },
  thresholds: {
    quality_api_duration: [`p(95)<${p95Limit}`],
    quality_api_errors: [`rate<${errorRateLimit}`],
  },
};

export default function () {
  const response = http.get(`${baseUrl}/api/v1/health`, {
    tags: { endpoint: 'health' },
  });
  const ok = check(response, {
    'health API returns 200': (result) => result.status === 200,
  });

  apiDuration.add(response.timings.duration);
  apiErrors.add(!ok);
}
