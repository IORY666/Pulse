"""
下一个App选品触发器
当Pulse收益达到500元时自动触发

此脚本由 monitor_revenue.py 在达到收益目标时调用
也可以在检测到 NEXT_APP_TRIGGER.txt 文件时手动运行
"""

import datetime
import json
import sys
from pathlib import Path


def main():
    print("=" * 60)
    print(" 下一个App选品触发器已激活")
    print("=" * 60)

    # 检查触发条件
    trigger_file = Path(__file__).parent.parent / "NEXT_APP_TRIGGER.txt"
    data_file = Path(__file__).parent / "revenue_data.json"

    if trigger_file.exists():
        with open(trigger_file) as f:
            print(f"\n触发文件内容:\n{f.read()}")

    if data_file.exists():
        with open(data_file) as f:
            revenue_history = json.load(f)
        print(f"\nPulse收益汇总:")
        print(f"  累计收益: ¥{revenue_history.get('cumulative_revenue', 0):.2f}")
        print(f"  Pro总销量: {revenue_history.get('total_pro_sales', 0)}份")
        print(f"  监控天数: {len(revenue_history.get('daily_records', []))}天")

    print("\n" + "=" * 60)
    print(" 需要手动操作:")
    print("=" * 60)
    print("")
    print(" 将以下内容发送给Claude:")
    print("")
    print(" ┌────────────────────────────────────────────────┐")
    print(" │ Pulse 收益已达 ¥500！请启动下一个App的选品    │")
    print(" │                                                │")
    print(" │ Pulse 经验总结：                               │")
    print(" │ - 选品：极简习惯打卡 + 硬付费墙模式           │")
    print(" │ - 变现：$4.99一次性买断                        │")
    print(" │ - 转化率：约12%（硬付费墙）                    │")
    print(" │ - 审核：待记录                                 │")
    print(" │                                                │")
    print(" │ 下一个App候选方向：                            │")
    print(" │ 1. 白噪音专注App（音频+离线+付费墙）           │")
    print(" │ 2. 隐私优先记账App（本地+CSV+付费墙）          │")
    print(" │ 3. 桌面小组件工坊（Widget+付费墙）             │")
    print(" └────────────────────────────────────────────────┘")

    # 生成选品上下文文件（供Claude读取）
    context_file = Path(__file__).parent.parent / "NEXT_APP_BRIEF.md"
    with open(context_file, "w", encoding="utf-8") as f:
        f.write(f"""# 下一个App选品上下文

## Pulse项目总结
- App名称：Pulse · 极简习惯打卡
- 变现模式：免费+$4.99一次性买断（硬付费墙，3个免费习惯后触发）
- 累计收益：¥{revenue_history.get('cumulative_revenue', 0):.2f}
- Pro销量：{revenue_history.get('total_pro_sales', 0)}份
- 开发周期：约2天编码
- Token消耗：约35-40元

## 经验教训
1. 硬付费墙（Hard Paywall）模式在2026年转化率远高于订阅模式（12% vs 2%）
2. 隐私优先 + 零数据收集是审核通过的关键优势
3. 精美Widget增加App价值感和主屏幕曝光
4. 纯Apple原生技术栈（SwiftUI+SwiftData+StoreKit2）降低维护成本

## 下一个App候选方向
1. **白噪音专注App** - 隐私优先，音频播放+定时器+付费墙，竞争适中
2. **极简记账App** - 隐私优先，CSV导出+付费墙，需求大但竞争也大
3. **Widget小组件工坊** - 付费墙+Widget包，低竞争但单价低

## 启动条件
- 当前资金池：¥500（原始启动资金已回笼）
- 下一个App预算：¥50 token消耗
- 目标：每个App的收益都达到¥500即启动下一个
""")

    print(f"\n[OK] 选品上下文已生成: {context_file}")
    print("[ACTION] 将上述方框中的内容粘贴发送给Claude即可启动下一个App选品")


if __name__ == "__main__":
    main()
