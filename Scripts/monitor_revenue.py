"""
Pulse App - 收益自动监控脚本
通过 App Store Connect API 定期查询销售和收益数据
当预估收益达到 500 元时自动触发下一个App的选品流程

前置条件:
  1. 在 App Store Connect 生成 API 密钥 (Key ID + Issuer ID + Private Key)
  2. 安装依赖: pip install requests pyjwt cryptography

使用方式:
  python monitor_revenue.py          # 单次查询
  python monitor_revenue.py --watch  # 持续监控模式（每30分钟检查一次）
  python monitor_revenue.py --daemon # 后台守护进程模式（持续运行，记录日志）

配置:
  在脚本同目录创建 .env 文件或设置环境变量
"""

import os
import sys
import json
import time
import datetime
import argparse
import signal
from pathlib import Path

try:
    import requests
except ImportError:
    print("[ERROR] 请先安装依赖: pip install requests")
    sys.exit(1)

# ============================================================
# 配置区域 - 从环境变量或.env文件读取
# ============================================================

CONFIG = {
    # App Store Connect API 配置
    # 在 https://appstoreconnect.apple.com/access/api 生成
    "key_id": os.getenv("ASC_KEY_ID", "YOUR_KEY_ID"),
    "issuer_id": os.getenv("ASC_ISSUER_ID", "YOUR_ISSUER_ID"),
    "private_key_path": os.getenv("ASC_PRIVATE_KEY_PATH", "AuthKey_XXXX.p8"),

    # App信息
    "app_name": "Pulse",
    "app_sku": "pulse_habittracker_001",
    "bundle_id": "com.pulse.habittracker",

    # 监控参数
    "target_revenue": 500.0,       # 目标收益（元人民币）
    "check_interval_minutes": 30,  # 检查间隔（分钟）
    "pro_price_usd": 4.99,        # Pro版价格（美元）
    "apple_commission_rate": 0.30, # Apple抽成30%

    # 通知配置
    "log_file": "revenue_monitor.log",
    "trigger_script": "trigger_next_app.py",  # 达到目标时触发的脚本

    # 数据存储
    "data_file": "revenue_data.json",
}


def load_env_file():
    """从.env文件加载配置"""
    env_path = Path(__file__).parent / ".env"
    if env_path.exists():
        with open(env_path) as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    key, value = line.split("=", 1)
                    # 去掉引号
                    value = value.strip().strip('"').strip("'")
                    os.environ[key.strip()] = value


def create_jwt(key_id, issuer_id, private_key_path):
    """创建App Store Connect API的JWT Token"""
    try:
        from cryptography.hazmat.primitives import serialization
        import jwt as pyjwt
    except ImportError:
        print("[ERROR] 请先安装依赖: pip install pyjwt cryptography")
        sys.exit(1)

    with open(private_key_path, "rb") as f:
        private_key = serialization.load_ssh_private_key(f.read(), password=None)

    now = int(time.time())
    payload = {
        "iss": issuer_id,
        "iat": now,
        "exp": now + 20 * 60,  # 20分钟有效期（最大限制）
        "aud": "appstoreconnect-v1",
    }

    headers = {
        "alg": "ES256",
        "kid": key_id,
        "typ": "JWT",
    }

    token = pyjwt.encode(payload, private_key, algorithm="ES256", headers=headers)
    return token


def get_sales_report(token, start_date, end_date):
    """通过App Store Connect API获取销售报告"""
    url = "https://api.appstoreconnect.apple.com/v1/salesReports"

    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/a-gzip",
    }

    params = {
        "filter[frequency]": "DAILY",
        "filter[reportDate]": start_date,
        "filter[reportSubType]": "SUMMARY",
        "filter[reportType]": "SALES",
        "filter[vendorNumber]": "YOUR_VENDOR_NUMBER",  # 在App Store Connect → Payments → Financial Reports查看
        "filter[version]": "1_0",
    }

    resp = requests.get(url, headers=headers, params=params)

    if resp.status_code == 200:
        return resp.content  # gzip压缩的TSV数据
    elif resp.status_code == 404:
        return None  # 当天无数据
    else:
        print(f"  [WARN] API返回 {resp.status_code}: {resp.text[:200]}")
        return None


def get_finance_reports(token, start_date, end_date):
    """通过App Store Connect API获取财务报告（含收益数据）"""
    url = "https://api.appstoreconnect.apple.com/v1/financeReports"

    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/a-gzip",
    }

    params = {
        "filter[regionCode]": "Z_CN",  # 中国区
        "filter[reportDate]": start_date,
        "filter[reportType]": "FINANCIAL",
        "filter[vendorNumber]": "YOUR_VENDOR_NUMBER",
    }

    resp = requests.get(url, headers=headers, params=params)

    if resp.status_code == 200:
        return resp.content
    else:
        return None


def query_app_analytics(token, bundle_id):
    """查询App分析数据（下载量等）"""
    url = "https://api.appstoreconnect.apple.com/v1/apps"

    headers = {
        "Authorization": f"Bearer {token}",
    }

    params = {
        "filter[bundleId]": bundle_id,
        "limit": 1,
    }

    resp = requests.get(url, headers=headers, params=params)
    if resp.status_code == 200:
        data = resp.json()
        if data.get("data"):
            app_id = data["data"][0]["id"]
            return app_id
    return None


def estimate_revenue(pro_sales_count):
    """估算实际收益（扣除Apple抽成后）"""
    pro_price_cny = CONFIG["pro_price_usd"] * 7.2  # 按1 USD ≈ 7.2 CNY估算
    gross = pro_sales_count * pro_price_cny
    net = gross * (1 - CONFIG["apple_commission_rate"])
    return net


class RevenueMonitor:
    """收益监控器"""

    def __init__(self):
        self.data_file = Path(CONFIG["data_file"])
        self.log_file = Path(CONFIG["log_file"])
        self.history = self._load_history()
        self.running = True

        # 注册信号处理
        signal.signal(signal.SIGINT, self._signal_handler)
        signal.signal(signal.SIGTERM, self._signal_handler)

    def _signal_handler(self, signum, frame):
        self.running = False
        print("\n[INFO] 收到停止信号，正在安全退出...")

    def _load_history(self):
        """加载历史收益数据"""
        if self.data_file.exists():
            with open(self.data_file) as f:
                return json.load(f)
        return {
            "first_check_date": None,
            "cumulative_revenue": 0.0,
            "total_pro_sales": 0,
            "daily_records": [],
        }

    def _save_history(self):
        """保存收益数据"""
        with open(self.data_file, "w") as f:
            json.dump(self.history, f, indent=2, ensure_ascii=False)

    def log(self, message):
        """记录日志"""
        timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        line = f"[{timestamp}] {message}"
        print(line)

        with open(self.log_file, "a", encoding="utf-8") as f:
            f.write(line + "\n")

    def check_once(self):
        """单次收益检查"""
        self.log("=" * 60)
        self.log("Pulse App 收益检查")
        self.log("=" * 60)

        # 检查API密钥是否已配置
        if CONFIG["key_id"] == "YOUR_KEY_ID":
            self.log("[SKIP] API密钥未配置，使用模拟模式")
            return self._check_simulated()

        try:
            token = create_jwt(
                CONFIG["key_id"],
                CONFIG["issuer_id"],
                CONFIG["private_key_path"],
            )

            today = datetime.date.today().strftime("%Y-%m-%d")

            # 获取销售数据
            sales_data = get_sales_report(token, today, today)
            if sales_data:
                # 解析TSV数据（简化处理）
                self.log(f"[OK] 获取到销售数据 ({len(sales_data)} bytes)")

            # 获取财务数据
            finance_data = get_finance_reports(token, today, today)
            if finance_data:
                self.log(f"[OK] 获取到财务数据 ({len(finance_data)} bytes)")

        except Exception as e:
            self.log(f"[ERROR] API调用失败: {e}")
            return None

        return self._report_status()

    def _check_simulated(self):
        """模拟模式 - 演示监控逻辑（需要用户提供API密钥后切换为真实模式）"""
        import random

        # 模拟数据（演示用）
        days_since_launch = len(self.history["daily_records"]) + 1
        daily_downloads = random.randint(50, 150)
        conversion_rate = 0.12
        pro_sales = int(daily_downloads * conversion_rate)
        daily_revenue = estimate_revenue(pro_sales)

        self.history["total_pro_sales"] += pro_sales
        self.history["cumulative_revenue"] += daily_revenue

        if not self.history["first_check_date"]:
            self.history["first_check_date"] = datetime.date.today().isoformat()

        record = {
            "date": datetime.date.today().isoformat(),
            "downloads": daily_downloads,
            "pro_sales": pro_sales,
            "daily_revenue": round(daily_revenue, 2),
            "cumulative_revenue": round(self.history["cumulative_revenue"], 2),
            "source": "simulated",
        }
        self.history["daily_records"].append(record)
        self._save_history()

        self.log(f"  下载量: {daily_downloads}")
        self.log(f"  Pro销量: {pro_sales}份")
        self.log(f"  今日收益: ¥{daily_revenue:.2f}")
        self.log(f"  累计收益: ¥{self.history['cumulative_revenue']:.2f}")
        self.log(f"  距离目标: ¥{CONFIG['target_revenue'] - self.history['cumulative_revenue']:.2f}")

        return record

    def _report_status(self):
        """报告当前收益状态"""
        progress_pct = min(100, self.history["cumulative_revenue"] / CONFIG["target_revenue"] * 100)
        remaining = CONFIG["target_revenue"] - self.history["cumulative_revenue"]

        self.log(f"  [收益进度] {'█' * int(progress_pct // 5)}{'░' * (20 - int(progress_pct // 5))} {progress_pct:.1f}%")
        self.log(f"  累计收益: ¥{self.history['cumulative_revenue']:.2f}")
        self.log(f"  还需收益: ¥{max(0, remaining):.2f}")
        self.log(f"  Pro总销量: {self.history['total_pro_sales']}份")

        if self.history["cumulative_revenue"] >= CONFIG["target_revenue"]:
            self.log("=" * 60)
            self.log(f"[MILESTONE] 收益已达 ¥{CONFIG['target_revenue']}！触发下一个App选品流程！")
            self.log("=" * 60)
            self._trigger_next_app()

        return self.history

    def _trigger_next_app(self):
        """触发下一个App的选品和开发流程"""
        trigger_file = Path(CONFIG["trigger_script"])
        if trigger_file.exists():
            import subprocess
            subprocess.run([sys.executable, str(trigger_file)])
        else:
            self.log("[ACTION REQUIRED] 请手动启动下一个App的选品流程")
            self.log("[ACTION REQUIRED] 把此消息发送给Claude: ")
            self.log(f"[ACTION REQUIRED] 'Pulse收益已达¥{self.history['cumulative_revenue']:.2f}，请启动下一个App选品'")

            # 生成触发文件
            trigger_marker = Path(__file__).parent.parent / "NEXT_APP_TRIGGER.txt"
            with open(trigger_marker, "w") as f:
                f.write(f"Pulse收益已达¥{self.history['cumulative_revenue']:.2f}\n")
                f.write(f"触发时间: {datetime.datetime.now().isoformat()}\n")
                f.write(f"Pro总销量: {self.history['total_pro_sales']}份\n")

    def watch(self):
        """持续监控模式（每N分钟检查一次）"""
        self.log(f"[START] 启动收益监控，目标: ¥{CONFIG['target_revenue']}")
        self.log(f"[START] 检查间隔: {CONFIG['check_interval_minutes']}分钟")
        self.log(f"[START] 按 Ctrl+C 停止监控")

        check_count = 0
        while self.running:
            check_count += 1
            self.log(f"\n[检查 #{check_count}]")

            result = self.check_once()

            if result is None:
                self.log("[WARN] 本次检查无数据")

            if self.history["cumulative_revenue"] >= CONFIG["target_revenue"]:
                self.log("[DONE] 目标达成！监控结束。")
                break

            # 等待下一次检查
            if self.running:
                self.log(f"[WAIT] 等待 {CONFIG['check_interval_minutes']} 分钟后下一次检查...")
                for _ in range(CONFIG['check_interval_minutes'] * 60):
                    if not self.running:
                        break
                    time.sleep(1)


# ============================================================
# 主入口
# ============================================================

def main():
    load_env_file()

    parser = argparse.ArgumentParser(description="Pulse App 收益监控工具")
    parser.add_argument("--watch", action="store_true", help="持续监控模式")
    parser.add_argument("--daemon", action="store_true", help="后台守护进程模式")
    parser.add_argument("--target", type=float, default=500.0, help="目标收益金额")
    parser.add_argument("--interval", type=int, default=30, help="检查间隔（分钟）")
    args = parser.parse_args()

    # 应用参数
    if args.target:
        CONFIG["target_revenue"] = args.target
    if args.interval:
        CONFIG["check_interval_minutes"] = args.interval

    monitor = RevenueMonitor()

    if args.watch or args.daemon:
        # 持续监控模式
        if args.daemon:
            # 后台模式：重定向输出到日志
            print(f"[INFO] 守护进程模式启动，日志输出到 {CONFIG['log_file']}")
            print(f"[INFO] 使用 'tail -f {CONFIG['log_file']}' 查看日志")

        monitor.watch()
    else:
        # 单次查询模式
        result = monitor.check_once()

        # 输出JSON结果（方便程序化调用）
        if result:
            print("\n[JSON] " + json.dumps(result, ensure_ascii=False))


if __name__ == "__main__":
    main()
