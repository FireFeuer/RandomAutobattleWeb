import time, random
from threading import Event

class Ability:
    def __init__(self, name, min_dmg, max_dmg, min_delay, max_delay, is_heal=False):
        self.name = name
        self.min_dmg = min_dmg
        self.max_dmg = max_dmg
        self.base_min_delay = min_delay
        self.base_max_delay = max_delay
        self.is_heal = is_heal
        self.next_tick = 0

    def get_delay(self, speed_modifier=1.0):
        mn = self.base_min_delay / speed_modifier
        mx = self.base_max_delay / speed_modifier
        return random.uniform(mn, mx)

class Player:
    def __init__(self, name, sid):
        self.name = name
        self.sid = sid
        self.hp = 1000
        self.max_hp = 1000
        self.perks = []
        self.abilities = [
            Ability("Quick", 10, 20, 0.2, 0.5), # Урон 10-20 вместо 1-5
            Ability("Heavy", 30, 50, 0.8, 1.2),
            Ability("Heal", 5, 15, 0.5, 1.0, is_heal=True),
        ]
        # Runtime stats
        self.shield = 0
        self.poison_stacks = 0

    def reset_round_state(self):
        self.hp = self.max_hp
        self.shield = 200 if "barrier" in self.perks else 0
        self.poison_stacks = 0
        speed_mod = 1.3 if "swiftness" in self.perks else 1.0
        
        for a in self.abilities:
            a.next_tick = time.time() + a.get_delay(speed_mod)

class Match:
    def __init__(self, match_id, p1, socketio):
        self.match_id = match_id
        self.p1 = p1
        self.p2 = None
        self.socketio = socketio  # Сохраняем socketio
        self.round_num = 0
        self.wins = {p1.sid: 0}
        self.stop_event = Event()
        self.room = match_id
        self.ready_players = set()
        self.state = "waiting"
        
        # Инициализируем round_choice только для p1, так как p2 еще не существует
        self.p1.round_choice = None

    def add_player(self, p2):
        self.p2 = p2
        self.wins[p2.sid] = 0
        # Инициализируем round_choice для p2 только когда он присоединяется
        self.p2.round_choice = None

    def is_full(self):
        return self.p2 is not None

    def get_player_names(self):
        names = [self.p1.name]
        if self.p2:
            names.append(self.p2.name)
        return names

    def start_game(self):
        self.round_num = 1
        self.start_picking_phase()

    def start_picking_phase(self):
        self.state = "picking"
        self.p1.round_choice = None
        # Проверяем, существует ли p2 перед установкой round_choice
        if self.p2:
            self.p2.round_choice = None

        perks_pool = ["crit", "barrier", "venom", "bloodlust", "swiftness", "soulbind"]
        offer = random.sample(perks_pool, 5)

        # Используем сохраненный socketio
        self.socketio.emit('perk_offer', {
            'perks': offer,
            'round': self.round_num,
            'wins': self.wins
        }, room=self.room)

    def apply_perk(self, sid, perk_id):
        print(f"apply_perk called: sid={sid}, perk={perk_id}, state={self.state}")
        
        if self.state != "picking": 
            print(f"  Not in picking state")
            return
        
        # Определяем, какой игрок выбрал перк
        if sid == self.p1.sid:
            player = self.p1
            print(f"  Player is p1: {player.name}")
        elif self.p2 and sid == self.p2.sid:
            player = self.p2
            print(f"  Player is p2: {player.name}")
        else:
            print(f"  Unknown player sid")
            return  # Неизвестный игрок
                
        # Защита от двойного выбора
        if getattr(player, 'round_choice', None) is None:
            player.perks.append(perk_id)
            player.round_choice = perk_id
            print(f"  Player chose: {perk_id}")
        else:
            print(f"  Player already chose: {player.round_choice}")
        
        # Проверяем, что оба игрока существуют и выбрали перки
        p1_chose = self.p1.round_choice is not None
        p2_chose = self.p2 is not None and getattr(self.p2, 'round_choice', None) is not None
        
        print(f"  p1_chose: {p1_chose}, p2_chose: {p2_chose}")
        
        # Если оба выбрали
        if p1_chose and p2_chose:
            print("  Both players chose! Starting combat...")
            self.start_combat_phase()

    def start_combat_phase(self):
        print(f"start_combat_phase called")
        self.state = "fighting"
        print(f"  Setting state to fighting")

        self.p1.reset_round_state()
        self.p2.reset_round_state()

        self.stop_event.clear()
        
        # Уведомляем о начале раунда
        self.socketio.emit('round_start', {}, room=self.room)

        # Запускаем игровой цикл в фоновой задаче socketio
        self.socketio.start_background_task(self.game_loop)
        print(f"  Game loop background task started")

    def game_loop(self):
            print(f"game_loop started!")
            tick_count = 0
            while not self.stop_event.is_set() and self.state == "fighting":
                # ВАЖНО: используем socketio.sleep вместо time.sleep
                self.socketio.sleep(0.1) 
                
                tick_count += 1
                self.tick()
                state = self.get_state()
                
                # Отправляем обновление
                self.socketio.emit('state_update', state, room=self.room)
                
                if self.p1.hp <= 0 or self.p2.hp <= 0:
                    self.resolve_round()
                    break

    def tick(self):
        current_time = time.time()
        print(f"tick called at {current_time}")
        
        for attacker, defender in [(self.p1, self.p2), (self.p2, self.p1)]:
            if not attacker or not defender:
                print(f"  Skipping - attacker or defender is None")
                continue
                
            print(f"  Processing {attacker.name} vs {defender.name}")
            
            # 1. Обработка способностей
            speed_mod = 1.3 if "swiftness" in attacker.perks else 1.0
            print(f"    speed_mod: {speed_mod}")
            
            for ab in attacker.abilities:
                print(f"    Ability {ab.name}: next_tick={ab.next_tick}, current_time={current_time}")
                if current_time >= ab.next_tick:
                    val = random.randint(ab.min_dmg, ab.max_dmg)
                    print(f"      {ab.name} activated! value={val}, is_heal={ab.is_heal}")
                    
                    if ab.is_heal:
                        # Лечение
                        old_hp = attacker.hp
                        attacker.hp = min(attacker.max_hp, attacker.hp + val)
                        print(f"      {attacker.name} healed: {old_hp} -> {attacker.hp}")
                    else:
                        # Атака
                        dmg = val
                        print(f"      Base damage: {dmg}")
                        
                        # Perk: CRIT
                        is_crit = False
                        if "crit" in attacker.perks and random.random() < 0.25:
                            dmg *= 2
                            is_crit = True
                            print(f"      CRIT! Damage doubled: {dmg}")

                        # Perk: BLOODLUST (Вампиризм)
                        if "bloodlust" in attacker.perks:
                            heal_amt = int(dmg * 0.5)
                            old_hp = attacker.hp
                            attacker.hp = min(attacker.max_hp, attacker.hp + heal_amt)
                            print(f"      BLOODLUST: {attacker.name} healed {heal_amt}: {old_hp} -> {attacker.hp}")

                        # Perk: VENOM (Накладывает стак)
                        if "venom" in attacker.perks and random.random() < 0.3:
                            defender.poison_stacks += 1
                            print(f"      VENOM: {defender.name} now has {defender.poison_stacks} poison stacks")

                        # Нанесение урона (с учетом Shield - Barrier)
                        old_defender_hp = defender.hp
                        old_defender_shield = defender.shield
                        self.apply_damage(defender, dmg)
                        print(f"      {defender.name} damaged: {old_defender_hp}HP/{old_defender_shield}Shield -> {defender.hp}HP/{defender.shield}Shield")

                        # Perk: SOULBIND (Отражение урона - 20%)
                        if "soulbind" in defender.perks:
                            reflect = int(dmg * 0.2)
                            if reflect > 0:
                                old_attacker_hp = attacker.hp
                                self.apply_damage(attacker, reflect)
                                print(f"      SOULBIND: {attacker.name} reflected {reflect} damage: {old_attacker_hp} -> {attacker.hp}")

                    # След тик
                    new_delay = ab.get_delay(speed_mod)
                    ab.next_tick = current_time + new_delay
                    print(f"      Next tick in {new_delay:.2f}s at {ab.next_tick}")
                else:
                    print(f"      Ability {ab.name} not ready yet, {ab.next_tick - current_time:.2f}s remaining")
            
            # 2. Тик яда (Venom)
            if defender.poison_stacks > 0:
                poison_dmg = defender.poison_stacks * 0.1
                old_hp = defender.hp
                defender.hp -= poison_dmg
                print(f"    VENOM tick: {defender.name} takes {poison_dmg:.1f} poison damage: {old_hp} -> {defender.hp}")

    def apply_damage(self, target, amount):
        if target.shield > 0:
            if target.shield >= amount:
                target.shield -= amount
                amount = 0
            else:
                amount -= target.shield
                target.shield = 0
        target.hp -= amount

    def get_state(self):
        return {
            "p1": {"name": self.p1.name, "hp": int(self.p1.hp), "shield": int(self.p1.shield), "max_hp": self.p1.max_hp},
            "p2": {"name": self.p2.name, "hp": int(self.p2.hp), "shield": int(self.p2.shield), "max_hp": self.p2.max_hp},
            "round": self.round_num
        }

    def resolve_round(self):
        winner_sid = None
        if self.p1.hp > 0 and self.p2.hp <= 0:
            winner_sid = self.p1.sid
        elif self.p2.hp > 0 and self.p1.hp <= 0:
            winner_sid = self.p2.sid
        
        if winner_sid:
            self.wins[winner_sid] += 1

        # Check Match Win (Best of 9 -> 5 wins)
        game_winner = None
        if self.wins[self.p1.sid] >= 5: game_winner = self.p1.name
        if self.wins[self.p2.sid] >= 5: game_winner = self.p2.name

        # Отправляем результат раунда
        self.socketio.emit('round_end', {
            'winner_sid': winner_sid, 
            'wins': self.wins,
            'game_over': game_winner is not None,
            'winner_name': game_winner
        }, room=self.room)

        if not game_winner:
            self.round_num += 1
            # Небольшая пауза и новый выбор перков
            time.sleep(3)
            self.start_picking_phase()
        else:
            self.state = "finished"