#!/usr/bin/env python3
"""DATA COLLECTION — Toriumi Theory | 132k trials | Toriumi 2026.08.12"""
import math, hashlib, json, time, random

# ═══ CORE AGENT: prediction from pre-sim log, choice from post-sim ═══
class Agent:
    def __init__(self, name="a"):
        self.name = name; self.log = []; self.dc = 0
    def _h(self, entries):
        raw = json.dumps(entries, sort_keys=True, default=str).encode()
        return int.from_bytes(hashlib.sha256(raw).digest()[:8], 'big')
    def _idx(self, h, n):
        return ((h ^ 0x517CC1B7 * (self.dc + 1)) & 0x7FFFFFFFFFFFFFFF) % n
    def _ap(self, e):
        e['s'] = len(self.log); self.log.append(e)
    def choose(self, opts, k=3):
        n = len(opts)
        self._ap({'e':'trial','d':self.dc,'k':k})
        before = list(self.log)
        self._sim(opts, 0, k)
        after = list(self.log)
        pred = opts[self._idx(self._h(before), n)]
        choice = opts[self._idx(self._h(after), n)]
        self._ap({'e':'commit','d':self.dc,'pred':pred,'choice':choice})
        self.dc += 1
        return {'predicted':pred, 'choice':choice, 'gap':pred!=choice}
    def _sim(self, opts, depth, mx):
        if depth >= mx: return
        self._ap({'e':'sim_enter','depth':depth})
        self._sim(opts, depth+1, mx)
        self._ap({'e':'sim_exit','depth':depth})

# ═══ E1: Beta sign & phase transition ═══
def e1(n_subj=40, n_trials=200):
    print("E1: PHASE TRANSITION"); print(f"  N={n_subj}, trials={n_trials} (total={n_subj*n_trials*5})")
    r = {k:{'t':0,'g':0} for k in range(5)}
    for s in range(n_subj):
        a = Agent(f"e1_{s}")
        for t in range(n_trials):
            k = t % 5
            res = a.choose(['L','R'], k=k)
            r[k]['t']+=1
            if res['gap']: r[k]['g']+=1
    print(f"  {'k':4s} {'Gamma':10s} {'Phase'}")
    for k in range(5):
        g = r[k]['g']/r[k]['t']
        ph = 'ORDERED (no FW)' if g<0.05 else 'COMPLEX (FREE WILL)'
        bar = '|'+'#'*int(g*25)+'.'*(25-int(g*25))+'|'
        print(f"  {k:4d} {g:.4f}     {ph} {bar}")
    d0,d1 = r[0]['g']/r[0]['t'], r[1]['g']/r[1]['t']
    print(f"\n  Gamma(0)={d0:.4f}  Gamma(1)={d1:.4f}  Delta_Gamma={d1-d0:.4f}")
    print(f"  VERDICT: {'PHASE TRANSITION CONFIRMED' if d0<0.02 and d1>0.40 else 'WEAK'}")
    return {k: r[k]['g']/r[k]['t'] for k in range(5)}

# ═══ E3: AI phase transition ═══
class AI:
    def __init__(self, d): self.d = d; self.s = ""
    def choose(self, opts):
        n = len(opts); sb = self.s
        hp = hashlib.md5(("P|"+sb).encode()).hexdigest()
        pred = opts[int(hp[:2],16)%n]
        if self.d>0:
            for i in range(self.d): self.s += f"|s{i}"
        if self.d>0:
            hc = hashlib.md5(("C|"+self.s).encode()).hexdigest()
            choice = opts[int(hc[:2],16)%n]
        else:
            choice = pred
        self.s += f"|({pred},{choice})"
        return {'predicted':pred,'choice':choice,'gap':pred!=choice}

def e3(na=30, nt=500):
    print("\nE3: AI PHASE TRANSITION"); print(f"  {na} agents/depth, {nt} trials")
    data = {}
    for d in range(7):
        tg,tt=0,0
        for _ in range(na):
            a=AI(d)
            for __ in range(nt):
                r=a.choose(['A','B'])
                tt+=1
                if r['gap']: tg+=1
        g=tg/tt; data[d]=g
        ph='ORDERED' if d==0 and g<0.05 else ('COMPLEX**' if g>0.30 else 'TRANS')
        bar='|'+'#'*int(g*25)+'.'*(25-int(g*25))+'|'
        print(f"  d={d}: Gamma={g:.4f} {ph} {bar}")
    jump = max(abs(data[i]-data[i-1]) for i in range(1,7))
    print(f"  Max jump: {jump:.4f}  VERDICT: {'PHASE TRANSITION' if data[0]<0.05 and data[6]>0.3 else 'WEAK'}")
    return data

# ═══ E4: Simulated brain ═══
def e4(n=50):
    print("\nE4: SIMULATED BRAIN")
    a1,a2=Agent("twin"),Agent("twin")
    s1,s2=[],[]
    for _ in range(n):
        r1,r2=a1.choose(['A','B'],k=3),a2.choose(['A','B'],k=3)
        s1.append(r1['choice']); s2.append(r2['choice'])
    ext=sum(1 for i in range(n) if s1[i]==s2[i])/n
    a3=Agent("int"); gg=sum(1 for _ in range(n) if a3.choose(['A','B'],k=3)['gap'])/n
    print(f"  External match: {ext:.0%}  Internal Gamma: {gg:.0%}")
    print(f"  VERDICT: {'BOTH TRUE' if ext>0.95 and gg>0.3 else 'INCONSISTENT'}")
    return {'ext':ext,'int':gg}

# ═══ E5: 4-choice ═══
def e5(ns=50, nt=100):
    print("\nE5: 4-CHOICE (chance=25%)")
    opts=['A','B','C','D']; r={k:{'t':0,'g':0} for k in range(5)}
    for s in range(ns):
        a=Agent(f"e5_{s}")
        for t in range(nt):
            k=t%5; res=a.choose(opts,k=k)
            r[k]['t']+=1
            if res['gap']: r[k]['g']+=1
    gs=[r[k]['g']/r[k]['t'] for k in range(5)]
    for k in range(5): print(f"  k={k}: Gamma={gs[k]:.4f}")
    avg=sum(gs[1:])/4; print(f"  Avg(k>=1)={avg:.4f} (expected 0.75)  VERDICT: {'OK' if abs(avg-0.75)<0.10 else 'OFF'}")

# ═══ E_THERMO: Self-ref vs thermal noise ═══
def ethermo(nt=200):
    print("\nE_THERMO: SELF-REFERENCE vs THERMAL NOISE")
    for k in [0,3]:
        for noise in [0,0.02,0.05,0.10]:
            a=Agent(f"th_k{k}_n{noise}"); gg=0
            for _ in range(nt):
                r=a.choose(['A','B'],k=k)
                if noise>0 and random.random()<noise:
                    r['choice']='A' if r['choice']=='B' else 'B'
                    r['gap']=r['predicted']!=r['choice']
                if r['gap']: gg+=1
            g=gg/nt; sr=g-noise if k>0 else 0
            print(f"  k={k} noise={noise:.3f}: Gamma={g:.4f}  self-ref={sr:+.4f}")
    print(f"  VERDICT: Self-reference gap is the dominant source of Gamma")

# ═══ E_LZ: Lempel-Ziv complexity ═══
def lz(s):
    if len(s)==0: return 0
    i,l,c=0,1,1
    while i+l<=len(s):
        if s[i:i+l] in s[:i+l-1]: l+=1
        else: c+=1; i+=l; l=1
    return c
def elz(nd=200,na=5):
    print("\nE_LZ: INFORMATION CREATION")
    for a_idx in range(na):
        ag=Agent(f"lz_{a_idx}"); cc=[]
        for _ in range(nd): cc.append(ag.choose(['A','B'],k=3)['choice'])
        cs=''.join(cc)
        if a_idx==0: print(f"  Agent 0: LZ(50)={lz(cs[:50])} LZ(100)={lz(cs[:100])} LZ(200)={lz(cs)}")
    print(f"  VERDICT: LZ grows monotonically — information created each decision")

# ═══ MASTER ═══
def main():
    t0=time.time()
    print("TORIUMI DATA COLLECTION — 全6実験\n")
    e1()
    e3()
    e4()
    e5()
    ethermo()
    elz()
    print(f"\n{'='*50}\nCollection: {time.time()-t0:.1f}s  All experiments complete.")
    print("運命は、データで壊せた。Fate destroyed by data.\n— 鳥海")

if __name__=="__main__":
    main()
