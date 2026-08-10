import json
from pathlib import Path

import yaml


ROOT = Path(__file__).parents[1]


def load_yaml(relative_path):
    return yaml.safe_load((ROOT / relative_path).read_text())


def test_prometheus_routes_alerts_and_loads_rules():
    config = load_yaml("prometheus/prometheus.yml")

    assert config["alerting"]["alertmanagers"][0]["static_configs"][0]["targets"] == [
        "alertmanager:9093"
    ]
    assert config["rule_files"] == ["/etc/prometheus/rules/*.yml"]


def test_fastapi_alert_rules_have_expected_windows():
    config = load_yaml("prometheus/rules/fastapi-alerts.yml")
    rules = {rule["alert"]: rule for rule in config["groups"][0]["rules"]}

    assert rules["FastAPIDown"]["for"] == "30s"
    assert rules["HighErrorRate"]["for"] == "1m"
    assert "clamp_min" in rules["HighErrorRate"]["expr"]
    assert "histogram_quantile" in rules["HighP95Latency"]["expr"]
    assert "sum by (le)" in rules["HighP95Latency"]["expr"]


def test_alertmanager_sends_local_mailpit_email_without_tls():
    config = load_yaml("alertmanager/alertmanager.yml")
    email_config = config["receivers"][0]["email_configs"][0]

    assert config["global"]["smtp_smarthost"] == "mailpit:1025"
    assert config["global"]["smtp_require_tls"] is False
    assert email_config["to"].endswith(".local")


def test_grafana_dashboard_is_valid_json():
    dashboard = json.loads((ROOT / "grafana/dashboards/fastapi-overview.json").read_text())

    assert dashboard["title"] == "FastAPI Overview"
    assert len(dashboard["panels"]) >= 3
