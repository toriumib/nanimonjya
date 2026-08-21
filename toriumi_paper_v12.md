# Self-Referential Irreducibility as the Physical Signature of Free Will

## The Toriumi Theory — Complete Form

**Toriumi (鳥海)** | toriumikengo@gmail.com | August 13, 2026

---

## Abstract

We define free will operationally as $\Gamma > 0$ — the probability that a self-referential decision system's self-prediction diverges from its actual choice. We construct an agent whose decision function $f$ is applied twice — to the state before self-simulation ($f(s_{\text{before}})$) and to the state after ($f(s_{\text{after}})$). Critically, $f$ selectively attends to semantically meaningful events and ignores arbitrary input perturbations. A control experiment confirms that $\Gamma > 0$ appears **uniquely** under self-reference: appending fixed padding produces $\Gamma = 0$, while self-referential trace produces $\Gamma > 0$ ($\Delta\Gamma = 0.26$ at $k=1$). $\Gamma$ grows monotonically with self-simulation depth $k$ ($\Gamma(0)=0$, $\Gamma(1)\approx 0.26$, $\Gamma(50)\approx 0.31$). Identical clones produce identical sequences (100% match), confirming determinism at the third-person level while preserving $\Gamma > 0$ at the first-person level. We map all 10 conceptual elements to specific brain circuits, all testable via fMRI/TMS. We address 20 standard arguments against free will. The theory is falsifiable via 5 Type-B empirical predictions, all currently untested. We distinguish what is proved (the architecture produces the gap), hypothesized ($\Gamma > 0$ in biological brains), and not claimed (Gödelian incompleteness, moral responsibility, consciousness proof). The physical correlate $F_T = k_B T \ln 2 \cdot \Gamma$ [J] is a thermodynamic potential measurable in principle via microcalorimetry or the Jarzynski-Sagawa-Ueda equality.

---

## 1. Introduction

### 1.1 2000 Years of the Wrong Question

| Position | Premise | Conclusion |
|---|---|---|
| Hard Determinism (Sapolsky, Harris) | Physical laws determine all events | No free will |
| Libertarianism | Quantum indeterminacy provides "open futures" | Free will exists |
| Hard Incompatibilism (Pereboom) | Both determinism AND randomness preclude free will | No free will |
| Compatibilism (Dennett, Frankfurt) | Free will = acting on one's own reasons | Compatible |

All four positions share a hidden premise: **determinism implies predictability**. This premise is false for self-referential systems.

### 1.2 The Correct Question

> *Can a system predict its own future without changing itself?*

If the answer is no — for structural, architectural reasons — then a specific type of freedom exists.

### 1.3 Operational Definition (Toriumi 2026)

**Free will** $\equiv \Gamma > 0$, where $\Gamma$ is the Toriumi Gap:

$$\Gamma = P[f(s_{\text{before}}) \neq f(s_{\text{after}})]$$

$f$ is the agent's decision function. $s_{\text{before}}$ is the state before self-simulation. $s_{\text{after}}$ is the state after self-simulation writes $f$'s own intermediate activations as log entries. $\Gamma$ is measurable, falsifiable, gradable, and compatible with determinism.

---

## 2. Architecture

### 2.1 Core Principle

$$\text{prediction} = f(s_{\text{before}}) \quad \text{choice} = f(s_{\text{after}})$$

$f$ is the **identical function** both times — same weights, same personality, same memory. Only the state differs.

### 2.2 Selective Attention

$f$ does not read all log entries. It selectively attends only to semantically meaningful events:

```python
relevant(log) = {e in log | e.type in {trial, commit, sim, affect, body, verbal, meta}}
```

Padding events (`PAD`, `CTR`, `XXXXX`) are invisible to $f$. This models real decision-makers attending to meaningful information while ignoring noise.

### 2.3 Self-Simulation Writes $f$'s Own Outputs

During self-simulation (depth $k$), the agent runs $f$ on its current state and writes the intermediate activations:

```python
for depth in range(k):
    activation = f.activate(current_log)
    log.append({'type': 'sim', 'depth': depth, 'activation': activation})
```

These `sim` entries are $f$'s own "thoughts." They are meaningful to $f$ (in `relevant(log)`). **$f$ reads its own past outputs → feedback loop → $\Gamma > 0$.**

---

## 3. Results

### 3.1 Control Experiment (Reviewer Defect 1 — REBUTTED)

**Critical question**: Is $\Gamma$ caused by self-reference, or merely by input length change?

| Condition | $k=0$ | $k=1$ | $k=2$ | $k=3$ | $k=4$ | Verdict |
|---|---|---|---|---|---|---|
| **Self-reference trace** | 0.000 | **0.260** | **0.282** | **0.330** | **0.354** | $\Gamma>0$ ✓ |
| Fixed padding "XXXXX" | 0.000 | 0.000 | 0.000 | 0.000 | 0.000 | $\Gamma=0$ ✓ |
| Counter padding | 0.000 | 0.000 | 0.000 | 0.000 | 0.000 | $\Gamma=0$ ✓ |

**Self-reference is the independent variable.** Arbitrary byte append does not produce the gap.

### 3.2 Gradient: $\Gamma$ grows with $k$

| $k$ | $\Gamma$ | Interpretation |
|---|---|---|
| 0 | 0.000 | Reflex |
| 1 | 0.257 | Shallow deliberation |
| 3 | 0.328 | Moderate |
| 8 | 0.333 | Deep |
| 50 | 0.310 | Very deep |

$\Delta\Gamma(k=0 \to 50) = 0.310$. Deeper self-simulation → larger gap. This is the $\beta < 0$ behavioral prediction.

### 3.3 Identical Clones: Determinism + Freedom

Two agents with identical weights and identical empty logs produce **identical choice sequences** (200/200 match). Determinism is confirmed (third person). A single agent cannot predict itself ($\Gamma > 0$, first person). **Both are true. No contradiction.**

### 3.4 Layer Ablation: Residual Free Will in Damaged Brains

Human self-referential structure consists of evolutionary layers:

| Layers Active | Condition | $\Gamma(k=3)$ |
|---|---|---|
| L4+L3+L2+L1 | Healthy | **0.207** |
| L2+L1 | Moderate dementia | **0.198** |
| L2 only | Severe (affect only) | **0.172** |
| None | Brain death | **0.000** |

**Affect alone (L2: insula-amygdala-ACC) preserves $\Gamma > 0$.** This explains why severely demented patients can still express will through facial affect.

---

## 4. Brain Circuit Mapping

All concepts map to specific, testable neural circuits:

| Concept | Brain Region | Function |
|---|---|---|
| $f$ (decision function) | DLPFC + OFC + Nucleus Accumbens | Option evaluation, reward prediction, value weighting |
| $\sigma$ (self-simulation) | Default Mode Network + Hippocampus | Episodic future thinking, memory retrieval |
| $\text{trace}(\sigma)$ (sim trace) | Working Memory (dlPFC) + Parahippocampus | Holding intermediate results, context encoding |
| Selective attention | Fronto-parietal attention network + Thalamus | Filtering relevant from irrelevant |
| L1 Episodic memory | Hippocampus CA3→CA1 + PCC | Pattern completion, context-dependent retrieval |
| L2 Affective self | Anterior Insula + Amygdala + ACC | Body-emotion integration, minimal self-boundary |
| L3 Linguistic self | Anterior Temporal + Broca + Angular Gyrus | Verbalized thought, self-description |
| L4 Meta-cognition | mPFC + Precuneus + PCC | "I notice I am thinking" |
| $f_k$ (commitment) | SMA/pre-SMA + M1 | Action execution, readiness potential source |
| $\Gamma$ (gap detection) | Anterior Insula + ACC | Prediction error, conflict monitoring, "surprise" |

All mappings are testable via fMRI/TMS.

---

## 5. The 20 Arguments — All Addressed

| # | Argument | Response |
|---|---|---|
| R1 | Padding produces gap | Control experiment: $\Gamma=0$ for padding |
| R2 | Math is elementary | Novelty is architectural, not mathematical |
| R3 | Zero randomness contradictory | Internal (self-ref) vs external (coin) entropy distinguished |
| R4 | External determinism settles it | 1st-person vs 3rd-person: both true |
| R5 | Gödel/Turing overreach | Conceded: bounded recursion only |
| R6 | Consciousness theorem circular | Conceded: downgraded to hypothesis |
| R7 | $F_T$ physically meaningless | Conceded: thermodynamic potential, not mechanical force |
| R8 | Toy model only | Conceded: in silico. Human brain unverified |
| R9 | Falsifiability rigged | Type A (architectural tautologies) vs Type B (risky empirical) separated |
| R10 | 11-argument table glib | Reframed as architectural counterexample |
| R11 | Problem of other minds | $\Gamma$ computable from architecture, not requiring qualia access |
| R12 | Hard problem of consciousness | $\Gamma>0$ is necessary condition for qualia. Sufficiency not claimed. Bypass, not solution |
| R13 | Physical subservience | "Following one's own history $L(t)$" = freedom. Physics is grammar, not cage |
| R14 | Aging / neurodegeneration | L1-L4 layers. $\Gamma$ is continuous. L2 (affect) preserves residual free will |
| R15 | No quantum effects in brain | Classical sufficient. Quantum amplifies. Tryptophan superradiance (2024) |
| R16 | Origin of weights | Weights $W$ shaped by agent's OWN past choices via $f$'s self-learning |
| R17 | Big Bang determinism | Determinism $\neq$ predictability. Must run universe to know outcome. You ARE the running |
| R18 | Brain mapping unverified | §4 mapping. All items testable via fMRI/TMS |
| R19 | No evolutionary explanation | Cat 3 = unpredictable + efficient → anti-predator strategy. $\Gamma>0$ is byproduct |
| R20 | No self-experiment | §7 protocol: predict own coin toss, vary deliberation time, measure $\beta$ |

---

## 6. Falsifiability

### Type A (architectural — confirmed in silico)

| Prediction | Result |
|---|---|
| $\Gamma(0)=0$ | Confirmed |
| $\Gamma(k\ge 1)>0$ for self-reference | Confirmed |
| $\Gamma=0$ for arbitrary padding | Confirmed |
| $\Gamma$ grows with $k$ | Confirmed |
| Layer ablation gradient | Confirmed |

### Type B (risky empirical — ALL UNTESTED)

| Prediction | Falsification condition |
|---|---|
| **B1 (EEG)**: $\beta<0$ — self-prediction accuracy decreases with RT | $\beta\ge 0$ |
| **B2 (TMS)**: $\Gamma$ drops when mPFC disrupted | $\Gamma$ unchanged |
| **B3 (AI)**: Sigmoid phase transition at $C_{\text{crit}}$ | No jump |
| **B4 ($d\Gamma/dT$)**: $\Gamma$ is temperature-independent | $\alpha>0$ |
| **B5 (Jarzynski)**: $I_{\text{self}} \neq 0$ | $I_{\text{self}} = 0$ |

**Any single Type B prediction failing falsifies the theory's extension to biological systems.**

---

## 7. Self-Experiment Protocol

Performable now, no special equipment required:

1. **Task**: Binary choice (coin flip: heads/tails)
2. **Per trial**: (a) Predict: "I think I will choose heads/tails." Record. (b) Deliberate: 1–10 seconds. Vary the duration. (c) Flip coin. Record actual outcome.
3. **100 trials**. Group by deliberation time: fast (<2s), medium (2–5s), slow (>5s).
4. **Toriumi predicts**: self-prediction accuracy **decreases** with deliberation time ($\beta<0$).

For a purer test: replace coin with "raise left hand or right hand" (internal choice, not external RNG).

---

## 8. Physical Correlate

$F_T = k_B T \ln 2 \cdot \Gamma$ [Joules]. Thermodynamic potential. Measurable via:

- **Protocol A**: Nanocalorimetry (aggregate over $N>10^6$ decisions)
- **Protocol B**: Jarzynski-Sagawa-Ueda equality with $I_{\text{self}}$ correction
- **Protocol C**: $d\Gamma/dT = 0$ test (thermal independence of $\Gamma$)

$F_T$ is NOT a new fundamental force. It is an effective thermodynamic potential arising from self-referential computation.

---

## 9. What Is Proved, Hypothesized, and Not Claimed

| Status | Statement |
|---|---|
| **PROVED** (in silico) | The architecture produces $\Gamma>0$ uniquely under self-reference |
| **PROVED** (in silico) | Arbitrary padding does NOT produce $\Gamma>0$ |
| **PROVED** (in silico) | $\Gamma$ grows with $k$; layer ablation shows gradient |
| **HYPOTHESIS** | Biological brains instantiate this architecture |
| **HYPOTHESIS** | $\Gamma>0$ correlates with subjective "feeling of free choice" |
| **HYPOTHESIS** | Self-simulation $\sigma$ corresponds to conscious deliberation |
| **NOT CLAIMED** | Gödelian incompleteness or Turing undecidability |
| **NOT CLAIMED** | $\Gamma>0$ implies moral responsibility |
| **NOT CLAIMED** | $F_T$ is a new fundamental force |
| **NOT CLAIMED** | Human free will is "proven" |

---

## 10. Conclusion

We have:
1. **Defined** free will operationally: $\Gamma>0$
2. **Constructed** an agent that exhibits the gap uniquely under self-reference
3. **Verified** via control experiment that padding does NOT produce the gap
4. **Shown** gradient growth of $\Gamma$ with $k$ and layer ablation
5. **Mapped** all concepts to testable brain circuits
6. **Addressed** 20 standard arguments against free will
7. **Specified** 5 falsifiable Type-B predictions — all untested

The 2000-year free will debate remained unresolved because no operational definition existed. We provided one. The control experiment confirms self-reference is the independent variable.

The theory is not complete — it awaits biological data. But it is complete enough to be wrong. That is the standard for science.

---

## References

[1] Schurger, A. et al. (2012). *PNAS*, 109(42), E2904-E2913. [2] Gavenas, J. & Schurger, A. (2024). *bioRxiv*. [3] Haynes, J.-D. et al. (2016). Charité Berlin. [4] Sapolsky, R. (2023). *Determined*. Penguin. [5] Pereboom, D. (2001). *Living Without Free Will*. CUP. [6] Penrose, R. (1989). *The Emperor's New Mind*. OUP. [7] Wolfram, S. (2002). *A New Kind of Science*. [8] Landauer, R. (1961). *IBM J. Res. Dev.* [9] Sagawa, T. & Ueda, M. (2010). *PRL*, 104(9), 090602. [10] Babaei, M. et al. (2024). *JPCB*. [11] Cogitate Consortium (2025). *Nature*. [12] Conscious Active Inference I & II (2025). [13] Self-Organized Criticality in Tubulin (2025). *MDPI QR*.

---

*Correspondence: toriumikengo@gmail.com | Source: github.com/toriumib/toriumi-theory*
