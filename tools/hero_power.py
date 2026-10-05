"""Rough power model for hero classes: every move scored against the average tier-1 enemy.

    python3 tools/hero_power.py

Enemy baseline: the non-boss enemies of the Tallgrass Sea, its side adventures and the Saloon
rumor templates (average HP, dodge, protection, resistances, attack accuracy, damage per hit).
Per move (level 1, move level 1): hit chance, expected direct damage per use (x targets or
hits, crits, protection, hero_dmg_mult), expected bleed/poison damage over its duration
(hit x (chance - resistance)), and expected stuns. Support moves show healing (x heal_mult,
x4 for party heals) and their effects. Per class: EHP = HP / (1 - prot) / enemy hit chance.

A comparison aid, not a simulation: it ignores ranks shifting, buffs stacking over turns,
focus fire and kill order. Use it to see which moves are outliers. See docs/PLAYTEST_NOTES.md
(round 8) for how it was read.
"""
import os
import json
import statistics as st

D=os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'data') + os.sep
L=lambda n: {k:v for k,v in json.load(open(D+n+'.json')).items() if not k.startswith('_')}
C,S,E,R,CFG=L('classes'),L('skills'),L('enemies'),L('regions'),json.load(open(D+'config.json'))
HM,HEAL=CFG['hero_dmg_mult'],CFG['heal_mult']
# Enemy pool: everything that shows up around Fort Providence (tier 1), non-boss.
pool=set()
for rid in ['tallgrass','dry_gulch_mine','crows_nest']:
    r=R[rid]
    for g in r.get('fights',[])+r.get('elites',[])+r.get('cave_fights',[]):
        pool.update(g['enemies'] if isinstance(g,dict) else g)
Q=json.load(open(D+'quests.json'))['templates']
for t in Q.values():
    for g in t.get('fights',[])+t.get('elites',[]):
        pool.update(g['enemies'] if isinstance(g,dict) else g)
pool=[e for e in pool if e in E and not E[e].get('boss')]
def avg(f): return st.mean(f(E[e]) for e in pool)
ED=avg(lambda e:e.get('dodge',0)); EP=avg(lambda e:e.get('prot',0)); EHP=avg(lambda e:e['hp'])
res=lambda k: avg(lambda e:e.get('res',{}).get(k,0))
ER={k:res(k) for k in ['stun','bleed','poison','move','debuff']}
# Enemy offense: average move acc + enemy acc, avg damage per hit
accs=[];dmgs=[]
for e in pool:
    en=E[e]
    for sid in en['skills']:
        sk=S.get(sid,{})
        if sk.get('target','enemy')=='enemy' and not sk.get('no_damage'):
            accs.append(sk.get('acc',85)+en.get('acc',0))
            lo,hi=sk.get('dmg_range',en['dmg']); m=1+sk.get('dmg',0)
            dmgs.append((lo+hi)/2*m*CFG['enemy_dmg_mult'])
EACC=st.mean(accs); EDMG=st.mean(dmgs)
print(f"enemy pool n={len(pool)} hp={EHP:.1f} dodge={ED:.1f} prot={EP:.1f}% res={ {k:round(v) for k,v in ER.items()} } atk_acc={EACC:.1f} dmg/hit={EDMG:.2f}")
def hitp(acc): return max(5,min(95,acc-ED))/100
def eff(e):
    k=e['type']; base=e.get('chance',100)
    rk={'stun':'stun','bleed':'bleed','poison':'poison','knockback':'move','pull':'move','debuff':'debuff'}.get(k)
    return max(0,min(95 if rk else 100, base-(ER[rk] if rk else 0)))/100
out={}
for cid,c in C.items():
    hp=c['hp']; prot=c['prot']; dodge=c['dodge']
    ehit=max(5,min(95,EACC-dodge))/100
    ehp=hp/(1-prot/100)/ehit
    rows=[]
    for sid in c['skills']:
        sk=S[sid]; tgt=sk.get('target','enemy')
        ranks=sk.get('use_ranks',[]); 
        if tgt=='enemy':
            p=hitp(sk.get('acc',85)+c.get('acc',0))
            lo,hi=sk.get('dmg_range',c['dmg']); m=1+sk.get('dmg',0)
            per=0 if sk.get('no_damage') else (lo+hi)/2*m*HM*(1-EP/100)*(1+0.5*(c['crit']+sk.get('crit',0))/100)
            n=1
            if sk.get('aoe'):
                tr=sk.get('target_ranks',[]); g=sk.get('aoe_groups')
                n=len(g[0]) if g else len(tr)
            n=max(n, sk.get('hits',1), sk.get('random_hits',0), sk.get('random_targets',0))
            dmg=per*p*n
            dot=0; stun=0; other=[]
            for e in sk.get('effects',[]):
                if e['type'] in ('bleed','poison'):
                    dot+=e['amount']*e.get('rounds',3)*p*eff(e)*n
                elif e['type']=='stun': stun+=p*eff(e)*n
                else: other.append(e['type'])
            rows.append((sk['name'],ranks,round(dmg,2),round(dot,2),round(stun,2),round(p*100),n,','.join(other)))
        else:
            heal=0; misc=[]
            for e in sk.get('effects',[]):
                if e['type']=='heal': heal+=(e['min']+e['max'])/2*HEAL*(4 if tgt=='party' else 1)
                else: misc.append(f"{e['type']}:{e.get('stat','')}{e.get('value',e.get('amount',''))}")
            rows.append((sk['name'],ranks,tgt,'heal=%.1f'%heal,' '.join(misc)))
    out[cid]=dict(name=c['name'],hp=hp,prot=prot,dodge=dodge,spd=c['speed'],ehit=round(ehit*100),ehp=round(ehp,1),rows=rows)
for cid,o in out.items():
    print(f"\n== {o['name']} hp={o['hp']} prot={o['prot']} dodge={o['dodge']} spd={o['spd']} | enemy hits it {o['ehit']}% | EHP={o['ehp']}")
    for r in o['rows']: print('  ',r)
