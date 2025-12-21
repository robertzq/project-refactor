# 游戏策划案：Project Refactor (重构人生)

**版本：** 3.0 (System Refactor)
**核心主旨：** 在熵增（混乱）的世界中，寻找负熵（秩序）的生存算法。

---

## 1. 灵魂架构：基础属性 (The Soul)

| 符号 | 属性名 | 变量名 | 范围 | 定义与作用 |
| :--- | :--- | :--- | :--- | :--- |
| **P_fin** | **经济安全感** | `fin_security` | 0~10 | **物质护盾**。抵消金钱焦虑。`<3` 为贫寒，`>7` 为富裕。 |
| **P_pride** | **心气/自尊** | `pride` | 0~10 | **精神杠杆**。决定胆量上限，也决定受辱时的伤害倍率。 |
| **P_sens** | **敏感度** | `sensitivity` | 0.8~1.5 | **感知增益**。焦虑放大器。 |
| **E_base** | **基础执行力** | `base_execution` | 0.8~1.2 | **硬件性能**。决定崩溃阈值上限。 |
| **T_rec** | **恢复策略** | `recovery_type` | 枚举 | **回血类型**。决定降焦虑手段 (社交/独处/探索)。 |

---

## 2. 身体机能：动态状态 (The Body)

| 符号 | 属性名 | 变量名 | 定义 |
| :--- | :--- | :--- | :--- |
| **A_t** | **当前焦虑** | `current_anxiety` | **HP**。超过阈值会导致崩溃。 |
| **AP_max** | **心力上限** | `max_ap` | **电池容量**。随长期状态动态浮动 (80~150)。 |
| **AP_cur** | **当前行动力** | `current_ap` | **当前电量**。每回合重置为 AP_max。 |
| **S_total** | **沉淀值** | `total_settlement` | **经验值**。结局判定的核心。 |

---

## 3. 意识博弈：隐性机制 (The Mind)

### 3.1 胆量 (Boldness)
$$
\text{Boldness} = (P_{fin} \times 0.4) + (P_{pride} \times 0.6)
$$

### 3.2 动态执行效率 (Efficiency, η)
$$
\eta = E_{base} \times \mu
$$
**修正系数 μ (Curses):**
* **0.7 (安逸诅咒):** 当 `P_fin > 7` 且 `Anxiety < 30`。
* **0.8 (胆怯诅咒):** 当 `Boldness < 4`。
* **1.2 (惊慌卷王):** 特殊状态。

### 3.3 崩溃阈值 (Breakdown Threshold)
$$
T_{limit} = 80 \times E_{base}
$$

---

## 4. 命运回响：循环系统 (The Cycles)

### 4.1 动态心力循环 (AP Elasticity)
月结时调整 `AP_max`：

* **过劳 (Burnout):** `Anxiety > Threshold` 持续 2 回合 $\rightarrow$ **AP_max - 10**。
* **心流 (Flow):** `Settlement Gain > 20` 且 `Anxiety < 60` $\rightarrow$ **AP_max + 5**。
* **生锈 (Rust):** `Settlement Gain < 5` 且 `Anxiety < 30` $\rightarrow$ **AP_max - 5**。

### 4.2 避难所机制 (Refuge)
仅针对贫寒玩家 (`P_fin < 3`)：
* **休息:** 焦虑 **+5** (负罪感)。
* **工作:** 焦虑 **-15** (避难所)。

---

## 5. 阶层分化：天赋树 (The Growth)

| 类型 | 特征 | 成本 | 曲线 | 备注 |
| :--- | :--- | :--- | :--- | :--- |
| **Type A (氪金型)** | 起步快，后期卷 | 金钱 (Money) | 对数 ($y=\ln x$) | 资金断裂则失效，后期高焦虑。 |
| **Type B (苦修型)** | 起步慢，后期神 | 时间 (AP) | 指数 ($y=e^x$) | 投入>1000AP 后触发开悟，大幅降焦虑。 |

---

## 6. 世界法则：事件结算 (Event Resolution)

焦虑增量 $\Delta A$ 计算公式：

**Step 1: 原始压力 (Raw Stress, Ω)**
$$
\Omega =
\begin{cases}
S_{base} - (P_{fin} \times 2.0) & \text{Money Event} \\
S_{base} + (P_{pride} \times 0.5) & \text{Ego Event} \\
S_{base} & \text{General Event}
\end{cases}
$$

**Step 2: 修正与放大**
$$
\Delta A = \max(0, \Omega - \text{RefugeBonus}) \times P_{sens} \times \text{EraFactor}
$$
* **RefugeBonus:** 穷人工作时为 5，否则为 0。
* **EraFactor:** 时代噪音系数 (默认 1.0)。