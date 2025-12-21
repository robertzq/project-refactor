import math

class AdvancedStudent:
    def __init__(self, name, fin_security, pride, base_execution):
        self.name = name
        self.fin_security = fin_security
        self.pride = pride
        self.base_execution = base_execution # 初始天赋
        
        self.anxiety = 20.0 # 初始焦虑
        self.settlement = 0.0

    @property
    def boldness(self):
        # 胆量由家境和心气共同决定
        return (self.fin_security * 0.4) + (self.pride * 0.6)

    @property
    def current_execution_efficiency(self):
        # 计算当前的真实执行效率
        efficiency = self.base_execution
        
        # 1. 富人的“安逸诅咒”
        # 如果很有钱(>7) 且 焦虑很低(<30)，容易分心
        if self.fin_security > 7 and self.anxiety < 30:
            efficiency *= 0.7 # 分心，效率打7折
            # print(f"  [Debug] {self.name} 太安逸了，正在刷手机摸鱼...")
        
        # 2. 穷人的“胆怯诅咒”
        # 如果胆量太低(<4)，做事畏手畏脚
        if self.boldness < 4:
            efficiency *= 0.8 # 胆怯，效率打8折
            # print(f"  [Debug] {self.name} 害怕问蠢问题，效率降低...")
            
        return efficiency

    def calculate_threshold(self):
        # 阈值依然受基础执行力影响，代表韧性
        return 80 * self.base_execution

    def rest_in_dorm(self):
        """在宿舍休息"""
        if self.fin_security < 3:
            # 穷人休息会有负罪感
            self.anxiety += 5 
            action_log = "躺在床上但这让你感到内疚 (焦虑+5)"
        else:
            # 富人休息就是休息
            self.anxiety = max(0, self.anxiety - 15)
            action_log = "舒服地睡了一觉 (焦虑-15)"
        
        print(f"[{self.name}] {action_log} | 当前焦虑: {self.anxiety:.1f}")

    def work_in_lab(self):
        """去实验室学习"""
        threshold = self.calculate_threshold()
        efficiency = self.current_execution_efficiency
        
        # 基础压力
        stress = 10 
        
        # 穷人因为把学习当避难所，压力会减轻
        if self.fin_security < 3:
            stress -= 5 # 学习本身能缓解一部分压力
            
        # 计算焦虑增加 (简化版公式)
        # 穷人敏感度高(1.5)，富人敏感度低(0.9)
        sensitivity = 1.5 if self.fin_security < 3 else 0.9
        delta_anxiety = stress * sensitivity
        
        self.anxiety += delta_anxiety
        
        # 判定
        if self.anxiety < threshold:
            # 成功坚持
            gain = 10 * efficiency
            self.settlement += gain
            
            # 【核心修正】：穷人学习成功后，焦虑反而会回落，因为获得了安全感
            if self.fin_security < 3:
                self.anxiety = max(0, self.anxiety - 8) # 巨大的心理安慰
                msg = "在代码中找到了平静 (焦虑回落)"
            else:
                msg = "完成了一天的学习"
                
            status = f"✅ {msg} | 沉淀+{gain:.1f}"
        else:
            status = "❌ 心态崩了，无法专注"
            
        # 钳制
        self.anxiety = min(100, self.anxiety)
        print(f"[{self.name}] 去实验室: 焦虑+{delta_anxiety:.1f} -> {self.anxiety:.1f}/{threshold:.1f} | {status} (效率 {efficiency:.0%})")

# --- 模拟对比 ---

# 1. 胆怯的穷人 (低心气，高敏感) -> 应该很难积累
timid_poor = AdvancedStudent(name="胆怯贫寒", fin_security=0, pride=2, base_execution=1.0)

# 2. 有心气的穷人 (高心气，把学习当救命稻草) -> 应该爆发力极强
proud_poor = AdvancedStudent(name="傲骨贫寒", fin_security=0, pride=9, base_execution=1.2)

# 3. 安逸的富人 (高家境，低焦虑) -> 应该效率低下
distracted_rich = AdvancedStudent(name="安逸富人", fin_security=10, pride=5, base_execution=1.0)

print("=== 第1回合：大家都去实验室 ===")
timid_poor.work_in_lab()
proud_poor.work_in_lab()
distracted_rich.work_in_lab()

print("\n=== 第2回合：大家都回宿舍休息 ===")
timid_poor.rest_in_dorm()
proud_poor.rest_in_dorm()
distracted_rich.rest_in_dorm()

print("\n=== 第3回合：再次去实验室 (富人开始分心了) ===")
timid_poor.work_in_lab()
proud_poor.work_in_lab()
distracted_rich.work_in_lab()