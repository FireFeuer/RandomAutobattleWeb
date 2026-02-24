import random
import time
from enum import Enum

class Rarity(Enum):
    COMMON = "common"
    RARE = "rare"
    EPIC = "epic"
    LEGENDARY = "legendary"

class AbilityType(Enum):
    DAMAGE = "damage"
    HEAL = "heal"
    SHIELD = "shield"
    STUN = "stun"
    BUFF = "buff"

class Ability:
    def __init__(self, name, name_ru, description, rarity, 
                 min_dmg=0, max_dmg=0, min_delay=2.0, max_delay=4.0, 
                 ability_type=AbilityType.DAMAGE, stackable=True, special_properties=None):
        self.name = name
        self.name_ru = name_ru
        self.description = description
        self.rarity = rarity
        self.min_dmg = min_dmg
        self.max_dmg = max_dmg
        self.base_min_delay = min_delay
        self.base_max_delay = max_delay
        self.ability_type = ability_type
        self.stackable = stackable
        self.special_properties = special_properties or {}

    def get_delay(self, speed_modifier=1.0):
        mn = self.base_min_delay / speed_modifier
        mx = self.base_max_delay / speed_modifier
        return random.uniform(mn, mx)
    
    @property
    def is_heal(self):
        """Возвращаем True, если тип способности — лечение. 
        Это исправит ошибку AttributeError."""
        return self.ability_type == AbilityType.HEAL
    
    def to_dict(self, stacks=1):
        # ЯВНО указываем is_heal на основе ability_type
        is_heal_value = (self.ability_type == AbilityType.HEAL)
        
        return {
            'id': self.name,           # Технический ID (например, "fireball")
            'name': self.name_ru,      # ОБЯЗАТЕЛЬНО для Flutter (заголовок)
            'name_ru': self.name_ru,   # Для совместимости
            'description': self.description,
            'rarity': self.rarity.value,
            'stackable': self.stackable,
            'is_heal': is_heal_value,
            'type': self.ability_type.value,
            'stats': self.get_stats_text(stacks)
        }

    def activate(self, attacker, target, match):
        import random
        from .models.activation_event import ActivationEvent, ActivationType

        # Расчет множителя на основе стаков (уровня)
        # В объекте, созданном в player.py, есть поле stack_count
        current_stacks = getattr(self, 'stack_count', 1)
        multiplier = 1.0 + (current_stacks - 1) * 0.5
        
        # Базовое значение из диапазона, умноженное на уровень
        raw_value = int(random.randint(self.min_dmg, self.max_dmg) * multiplier)
        
        event = None

        if self.ability_type == AbilityType.DAMAGE:
            actual_damage = raw_value
            was_crit = False
            
            # РАСЧЕТ КРИТА ЗДЕСЬ!
            crit_chance = 0.1  # Базовый шанс 10%
            
            # Проверяем, есть ли у атакующего способность berserker_strike
            if self.name == "berserker_strike":
                crit_chance = self.special_properties.get('crit_chance', 0.4)
                print(f"🎲 [DEBUG] {attacker.name} {self.name}: special crit_chance = {crit_chance}")
            
            # Проверяем, есть ли у атакующего способность crit (пассивка на крит)
            if "crit" in attacker.abilities_dict:
                crit_stacks = attacker.abilities_dict.get("crit", 0)
                crit_chance += (crit_stacks - 1) * 0.05
                print(f"🎲 [DEBUG] {attacker.name}: added {(crit_stacks-1) * 0.05} from crit stacks")
            
            print(f"🎲 [DEBUG] {attacker.name} {self.name}: final crit_chance = {crit_chance:.2f}")
            
            rand_val = random.random()
            print(f"🎲 [DEBUG] random value = {rand_val:.3f}")
            
            if rand_val < crit_chance:
                actual_damage = actual_damage * 2
                was_crit = True
                print(f"🎯 [CRIT] {attacker.name} {self.name}: CRIT! damage={actual_damage}")
            
            # 1. Божественный щит (Divine Shield) - Шанс 100% блока
            if "divine_shield" in target.abilities_dict:
                shield_template = ABILITIES.get("divine_shield")
                block_chance = shield_template.special_properties.get("block_chance", 0.15)
                if random.random() < block_chance:
                    actual_damage = 0
                    match.add_activation_event(ActivationEvent(
                        player_sid=target.sid,
                        player_name=target.name,
                        ability_name="divine_shield",
                        value=0,
                        is_heal=False,
                        effect_type=ActivationType.SHIELD
                    ))

            # 2. Пассивное снижение урона Барьером (Броня за стаки)
            if actual_damage > 0 and "barrier" in target.abilities_dict:
                barrier_stacks = target.abilities_dict["barrier"]
                reduction = barrier_stacks * 10 
                actual_damage = max(0, actual_damage - reduction)

            # 3. Поглощение "синим" щитом (из полоски щита)
            if actual_damage > 0 and target.shield > 0:
                shield_absorbed = min(target.shield, actual_damage)
                target.shield -= shield_absorbed
                actual_damage -= shield_absorbed
            
            # 4. Нанесение урона в HP
            if actual_damage > 0:
                target.hp -= actual_damage

            # Эффект вампиризма
            if self.name == "vampiric_bite" and actual_damage > 0:
                lifesteal = self.special_properties.get('lifesteal', 0.5)
                heal_amt = int(actual_damage * lifesteal)
                attacker.hp = min(attacker.max_hp, attacker.hp + heal_amt)

            print(f"🔴 DAMAGE DEBUG: {attacker.name} used {self.name}")
            print(f"   raw_value: {raw_value}, actual_damage: {actual_damage}")
            print(f"   was_crit: {was_crit}")

            # ВСЕГДА создаем событие урона для DAMAGE способностей
            event = ActivationEvent(
                player_sid=attacker.sid,
                player_name=attacker.name,
                ability_name=self.name,
                value=actual_damage,
                is_heal=False,
                is_crit=was_crit,
                activation_type=self.ability_type
            )

            # Отдельно обрабатываем стан для chain_lightning
            if self.name == "chain_lightning" and actual_damage > 0:
                stun_chance = self.special_properties.get('stun_chance', 0.2)
                if random.random() < stun_chance:
                    # Применяем стан
                    target.stun_duration = max(target.stun_duration, 1.0)
                    
                    print(f"⚡ {attacker.name} stunned {target.name} with chain_lightning!")
                    
                    # Отправляем отдельное событие стана
                    match.add_activation_event(ActivationEvent(
                        player_sid=target.sid,
                        player_name=target.name,
                        ability_name="chain_lightning_stun",
                        value=0,
                        is_heal=False,
                        is_crit=False,
                        effect_type=ActivationType.STUN
                    ))

        elif self.ability_type == AbilityType.HEAL:
            # Сохраняем текущее HP для расчета реального лечения
            old_hp = attacker.hp
            # Применяем лечение
            attacker.hp = min(attacker.max_hp, attacker.hp + raw_value)
            # Вычисляем реальное количество вылеченного HP
            actual_heal = attacker.hp - old_hp
            
            print(f"💚 HEAL: {attacker.name} healed for {actual_heal} HP (raw: {raw_value})")
            
            event = ActivationEvent(
                player_sid=attacker.sid,
                player_name=attacker.name,
                ability_name=self.name,
                value=actual_heal,
                is_heal=True,
                is_crit=False,
                activation_type=self.ability_type
            )

        elif self.ability_type == AbilityType.STUN:
            # Базовая длительность
            base_duration = self.special_properties.get('stun_duration', 1.0)
            
            # Увеличиваем длительность в зависимости от количества стаков
            stack_bonus = (current_stacks - 1) * 0.5
            duration = base_duration + stack_bonus
            
            # Применяем стан (берем максимальное значение, если уже есть стан)
            target.stun_duration = max(target.stun_duration, duration)
            
            print(f"❄️ STUN: {attacker.name} stunned {target.name} for {duration:.1f}s (stacks: {current_stacks})")
            
            event = ActivationEvent(
                player_sid=attacker.sid,
                player_name=attacker.name,
                ability_name=self.name,
                value=int(duration * 10),
                is_heal=False,
                is_crit=False,
                effect_type=ActivationType.STUN
            )

        if event:
            match.add_activation_event(event)
        
        return raw_value

    def get_rarity_color(self):
        """Возвращает цвет полоски для редкости"""
        colors = {
            Rarity.COMMON: "#9E9E9E",  # gridLine
            Rarity.RARE: "#72c144",
            Rarity.EPIC: "#77136f",
            Rarity.LEGENDARY: "#d2b61e"
        }
        return colors.get(self.rarity, "#9E9E9E")
    

    
    # ИСПРАВЛЕНИЕ: Добавляем stacks в параметры метода
    def get_stats_text(self, stacks=1):
        multiplier = 1.0 + (stacks - 1) * 0.5
        
        low = int(self.min_dmg * multiplier)
        high = int(self.max_dmg * multiplier)

        if self.ability_type == AbilityType.DAMAGE:
            return f"Урон: {low}-{high}"
        elif self.ability_type == AbilityType.HEAL:
            return f"Лечение: {low}-{high}"
        elif self.ability_type == AbilityType.SHIELD:
            shield_val = 200 + (stacks - 1) * 50
            return f"Щит: +{shield_val} в начале"
        elif self.ability_type == AbilityType.STUN:
            base_duration = self.special_properties.get('stun_duration', 1.0)
            total_duration = base_duration + (stacks - 1) * 0.5
            return f"Длительность: {total_duration:.1f} сек."
        
        return self.description

# Предопределенные способности
ABILITIES = {
    # КЛАССИЧЕСКИЙ УРОН
    "fireball": Ability(
        "fireball", "Огненный шар", "Средний урон раз в 2-4 сек.", Rarity.COMMON,
        15, 25, 2.0, 4.0
    ),
    "magic_arrow": Ability(
        "magic_arrow", "Магическая стрела", "Быстрый, но слабый урон", Rarity.COMMON,
        5, 12, 1.2, 2.0
    ),
    "heavy_strike": Ability(
        "heavy_strike", "Тяжелый удар", "Медленно, но очень больно", Rarity.RARE,
        40, 70, 4.5, 6.5
    ),
    
    # ЛЕЧЕНИЕ (не наносит урон)
    "holy_light": Ability(
        "holy_light", "Святой свет", "Исцеляет владельца", Rarity.RARE,
        20, 40, 3.5, 5.0, ability_type=AbilityType.HEAL
    ),
    
    # ЩИТЫ И ЗАЩИТА
    "barrier": Ability(
        "barrier", "Энергетический барьер", "Дает щит в начале раунда. Может снижать получаемый урон", Rarity.COMMON,
        ability_type=AbilityType.SHIELD, stackable=True
    ),
    "divine_shield": Ability(
        "divine_shield", "Божественный щит", "Шанс 15% заблокировать любой урон", Rarity.LEGENDARY,
        ability_type=AbilityType.BUFF, stackable=False, special_properties={"block_chance": 0.15}
    ),

    # КОНТРОЛЬ
    "chain_lightning": Ability(
        "chain_lightning", "Цепная молния", "Урон и шанс оглушения 20%", Rarity.EPIC,
        10, 20, 2.0, 4.4, special_properties={"stun_chance": 0.2}
    ),
    "ice_touch": Ability(
        "ice_touch", "Ледяное касание", "Замораживает врага на 1 сек (без урона)", Rarity.RARE,
        0, 0, 4.0, 6.0, ability_type=AbilityType.STUN, special_properties={"stun_duration": 1.0}
    ),

    # УСИЛЕНИЯ (Пассивки)
    "berserker_strike": Ability(
        "berserker_strike", "Ярость берсерка", "Мощный удар с повышенным шансом крита", 
        Rarity.EPIC,
        min_dmg=35, max_dmg=55, min_delay=3.5, max_delay=5.0, 
        ability_type=AbilityType.DAMAGE, stackable=True, special_properties={"crit_chance": 0.4}
    ),
    "vampiric_bite": Ability(
        "vampiric_bite", "Укус вампира", "Наносит урон и восстанавливает HP в размере 50% от урона", 
        Rarity.LEGENDARY,
        min_dmg=20, max_dmg=35, min_delay=3.0, max_delay=4.5, 
        ability_type=AbilityType.DAMAGE, stackable=True, special_properties={"lifesteal": 0.50}
    ),
}

def get_ability_by_id(ability_id):
    """Получить способность по ID"""
    return ABILITIES.get(ability_id)

def get_random_perks(count=5, exclude_ids=None):
    if exclude_ids is None:
        exclude_ids = []
    
    # Фильтруем список всех доступных способностей
    available_ids = [aid for aid in ABILITIES.keys() if aid not in exclude_ids]
    
    # Выбираем случайные ID
    selected_ids = random.sample(available_ids, min(count, len(available_ids)))
    
    return [ABILITIES[aid] for aid in selected_ids]

def get_ability_description(self):
    """Возвращает полное описание способности"""
    desc = self.description
    if self.is_heal:
        desc += f" Лечит от {self.min_dmg} до {self.max_dmg} HP."
    else:
        desc += f" Наносит от {self.min_dmg} до {self.max_dmg} урона."
    return desc