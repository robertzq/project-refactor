import math

# ==========================================
# 1. 核心模型定义 (The Soul & Formulas)
# ==========================================

class Character:
    def __init__(self, name, p_fin, p_pride, p_sens, entropy, base_exec, traits=None):
        self.name = name
        self.p_fin = p_fin        # 家境 (0-10)
        self.p_pride = p_pride    # 自尊 (0-10)
        self.p_sens = p_sens      # 敏感度 (0.8-1.5)
        self.entropy = entropy    # 熵 (视野)
        self.base_exec = base_exec # 基础执行力
        self.traits = traits if traits else []
        
        # 动态状态
        self.current_anxiety = 0
        self.breakdown_limit = 80 * self.base_exec

    def get_boldness(self):
        """公式 3.1: 胆量"""
        return (self.p_fin * 0.4) + (self.p_pride * 0.6)

    def get_efficiency(self):
        """公式 3.3: 动态执行效率"""
        boldness = self.get_boldness()
        mu = 1.0 # 修正系数
        curses = []

        # 1. 安逸诅咒
        if self.p_fin > 7 and self.current_anxiety < 30:
            mu *= 0.7
            curses.append("安逸(0.7)")
        
        # 2. 胆怯诅咒
        if boldness < 4:
            mu *= 0.8
            curses.append("胆怯(0.8)")
            
        # 3. 惊慌卷王 (需配合特质)
        if self.current_anxiety > 80 and "背水一战" in self.traits:
            mu *= 1.2
            curses.append("卷王(1.2)")

        efficiency = self.base_exec * mu
        return efficiency, curses

    def calculate_stress(self, event_type, base_stress, is_working=False):
        """公式 3.2: 焦虑增长"""
        
        # Step 1: 原始压力 (Omega)
        omega = base_stress
        formula_log = ""

        if event_type == "MONEY":
            # 钱越多，减伤越高
            reduction = self.p_fin * 2.0
            omega = base_stress - reduction
            formula_log = f"[{base_stress} - ({self.p_fin}*2.0)]"
        
        elif event_type == "EGO":
            # 自尊越高，增伤越高
            amplification = self.p_pride * 0.5
            omega = base_stress + amplification
            formula_log = f"[{base_stress} + ({self.p_pride}*0.5)]"
        
        else: # GENERAL
            omega = base_stress
            formula_log = f"[{base_stress}]"

        # Step 2: 避难所修正 (Refuge)
        refuge_bonus = 0
        if is_working and self.p_fin < 3:
            refuge_bonus = 5
            formula_log += " - Refuge(5)"
        
        # Step 3: 最终计算
        # 压力不能为负数 (max 0)
        raw_val = max(0, omega - refuge_bonus)
        final_delta = raw_val * self.p_sens
        
        formula_log += f" * Sens({self.p_sens})"

        return round(final_delta, 2), formula_log

# ==========================================
# 2. 测试数据准备 (Test Data)
# ==========================================

# 定义 6 种典型+极限的角色模版
archetypes = [
    # 标准模版
    Character("小镇做题家", p_fin=2, p_pride=6, p_sens=1.2, entropy=3, base_exec=1.2, traits=["背水一战"]),
    Character("落魄书香",   p_fin=4, p_pride=9, p_sens=1.4, entropy=7, base_exec=0.9),
    Character("野蛮生长",   p_fin=3, p_pride=1, p_sens=0.9, entropy=5, base_exec=1.0),
    Character("温室花朵",   p_fin=9, p_pride=5, p_sens=1.0, entropy=4, base_exec=0.8, traits=["退路"]),
    
    # 极限边界测试
    Character("【边界】真神", p_fin=10, p_pride=0, p_sens=0.8, entropy=10, base_exec=1.2), # 最抗压
    Character("【边界】地狱", p_fin=0,  p_pride=10, p_sens=1.5, entropy=0,  base_exec=0.8), # 最脆弱
]

# 定义典型的压力事件
scenarios = [
    {"name": "奶茶洒了",      "type": "MONEY", "stress": 15, "desc": "微小金钱损失"},
    {"name": "电脑坏了",      "type": "MONEY", "stress": 50, "desc": "重大金钱损失"},
    {"name": "被导师骂",      "type": "EGO",   "stress": 20, "desc": "自尊打击"},
    {"name": "当众出丑",      "type": "EGO",   "stress": 60, "desc": "毁灭性社死"},
    {"name": "赶Deadline",    "type": "GEN",   "stress": 30, "desc": "一般性焦虑"},
]

# ==========================================
# 3. 批量运行引擎 (The Engine)
# ==========================================

def run_simulation():
    print(f"{'角色':<10} | {'胆量':<4} | {'效率':<4} | {'崩溃阈值':<6} | {'场景':<10} | {'类型':<5} | {'原始':<4} | {'最终伤害':<8} | {'状态'}")
    print("-" * 110)

    for char in archetypes:
        # 1. 基础面板计算
        boldness = char.get_boldness()
        eff, curses = char.get_efficiency()
        limit = char.breakdown_limit
        
        # 格式化 Curse 显示
        curse_str = ",".join(curses) if curses else "正常"
        
        # 2. 遍历所有场景
        for scene in scenarios:
            delta, log = char.calculate_stress(scene["type"], scene["stress"])
            
            # 3. 模拟穷人打工避难所 (如果是Money事件且穷，模拟一次打工状态)
            refuge_delta = 0
            refuge_text = ""
            if char.p_fin < 3 and scene["type"] == "MONEY":
                r_delta, _ = char.calculate_stress(scene["type"], scene["stress"], is_working=True)
                refuge_text = f" (打工时:{r_delta})"

            # 4. 判定是否暴毙
            status = "存活"
            if delta > limit * 0.5: status = "重伤"
            if delta >= limit: status = "【崩溃】"
            if delta == 0: status = "免疫"

            # 5. 打印一行结果
            print(f"{char.name:<10} | {boldness:<4.1f} | {eff:<4.2f} | {limit:<8.0f} | {scene['name']:<10} | {scene['type']:<5} | {scene['stress']:<4} | {delta:<8}{refuge_text} | {status} {curse_str}")
        
        print("-" * 110)

if __name__ == "__main__":
    run_simulation()
