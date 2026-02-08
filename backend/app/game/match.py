import random
import time
from threading import Event

class Match:
    def __init__(self, match_id, p1, socketio):
        self.match_id = match_id
        self.p1 = p1
        self.p2 = None
        self.socketio = socketio
        self.round_num = 0
        self.wins = {p1.sid: 0}
        self.stop_event = Event()
        self.room = match_id
        self.ready_players = set()
        self.state = "waiting"
        
        self.p1.round_choice = None

    def add_player(self, p2):
        self.p2 = p2
        self.wins[p2.sid] = 0
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
        if self.p2:
            self.p2.round_choice = None

        perks_pool = ["crit", "barrier", "venom", "bloodlust", "swiftness", "soulbind"]
        offer = random.sample(perks_pool, 5)

        self.socketio.emit('perk_offer', {
            'perks': offer,
            'round': self.round_num,
            'wins': self.wins
        }, room=self.room)

    def apply_perk(self, sid, perk_id):
        if self.state != "picking": return
        
        player = None
        if sid == self.p1.sid: player = self.p1
        elif self.p2 and sid == self.p2.sid: player = self.p2
        
        if not player: return
                
        if player.round_choice is None:
            player.perks.append(perk_id)
            player.round_choice = perk_id
        
        # Проверка готовности обоих
        p1_chose = self.p1.round_choice is not None
        p2_chose = self.p2 is not None and self.p2.round_choice is not None
        
        if p1_chose and p2_chose:
            self.start_combat_phase()

    def start_combat_phase(self):
        self.state = "fighting"
        self.p1.reset_round_state()
        self.p2.reset_round_state()
        self.stop_event.clear()
        
        self.socketio.emit('round_start', {}, room=self.room)
        # Запуск цикла в фоне
        self.socketio.start_background_task(self.game_loop)

    def game_loop(self):
        print(f"Match {self.match_id}: Game loop started")
        while not self.stop_event.is_set() and self.state == "fighting":
            # ИСПРАВЛЕНИЕ: Даем серверу "дышать" и отправлять пакеты
            self.socketio.sleep(0.1) 
            
            self.tick()
            state = self.get_state()
            self.socketio.emit('state_update', state, room=self.room)
            
            if self.p1.hp <= 0 or self.p2.hp <= 0:
                self.resolve_round()
                break

    def tick(self):
        current_time = time.time()
        
        for attacker, defender in [(self.p1, self.p2), (self.p2, self.p1)]:
            if not attacker or not defender: continue
            
            # 1. Способности
            speed_mod = 1.3 if "swiftness" in attacker.perks else 1.0
            
            for ab in attacker.abilities:
                if current_time >= ab.next_tick:
                    val, new_delay = ab.activate(speed_mod)
                    ab.next_tick = current_time + new_delay
                    
                    if ab.is_heal:
                        attacker.hp = min(attacker.max_hp, attacker.hp + val)
                    else:
                        dmg = val
                        # CRIT
                        if "crit" in attacker.perks and random.random() < 0.25:
                            dmg *= 2
                        # BLOODLUST
                        if "bloodlust" in attacker.perks:
                            heal_amt = int(dmg * 0.5)
                            attacker.hp = min(attacker.max_hp, attacker.hp + heal_amt)
                        # VENOM
                        if "venom" in attacker.perks and random.random() < 0.3:
                            defender.poison_stacks += 1
                        
                        # Apply Damage
                        self.apply_damage(defender, dmg)

                        # SOULBIND
                        if "soulbind" in defender.perks:
                            reflect = int(dmg * 0.2)
                            if reflect > 0:
                                self.apply_damage(attacker, reflect)
            
            # 2. Тик яда
            if defender.poison_stacks > 0:
                poison_dmg = defender.poison_stacks * 0.1
                defender.hp -= poison_dmg

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
            "p1": self.p1.to_dict(),
            "p2": self.p2.to_dict(),
            "round": self.round_num
        }

    def resolve_round(self):
        winner_sid = None
        if self.p1.hp > 0 and self.p2.hp <= 0: winner_sid = self.p1.sid
        elif self.p2.hp > 0 and self.p1.hp <= 0: winner_sid = self.p2.sid
        
        if winner_sid: self.wins[winner_sid] += 1

        game_winner = None
        if self.wins[self.p1.sid] >= 5: game_winner = self.p1.name
        if self.wins[self.p2.sid] >= 5: game_winner = self.p2.name

        self.socketio.emit('round_end', {
            'winner_sid': winner_sid, 
            'wins': self.wins,
            'game_over': game_winner is not None,
            'winner_name': game_winner
        }, room=self.room)

        if not game_winner:
            self.round_num += 1
            # Пауза перед следующим раундом (неблокирующая)
            self.socketio.sleep(3)
            self.start_picking_phase()
        else:
            self.state = "finished"