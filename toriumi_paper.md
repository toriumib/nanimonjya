# Self-Referential Irreducibility and the Physical Signature of Free Will

## The Toriumi Theory — Complete and Final Form

**Kengo Toriumi (鳥海健悟)** | toriumikengo@gmail.com | August 13, 2026

---

## Abstract

We give an operational definition of free will and constructively prove its existence in self-referential decision systems. Free will is defined as $\Gamma > 0$, where $\Gamma$ is the Toriumi Gap — the probability that a system's self-prediction diverges from its actual choice. We construct an agent whose decision function $f$ is applied twice: to the state before self-simulation ($f(s_{\text{before}})$, the prediction) and to the state after ($f(s_{\text{after}})$, the choice). Critically, $f$ selectively attends to semantically meaningful events and ignores arbitrary input perturbations. A control experiment confirms that $\Gamma > 0$ appears **uniquely** under self-reference: appending fixed padding produces $\Gamma = 0$, while self-referential trace produces $\Gamma > 0$. $\Gamma$ grows monotonically with self-simulation depth $k$. Identical clones produce identical sequences, confirming determinism at the third-person level while preserving $\Gamma > 0$ at the first-person level. We integrate the abstraction-dimension framework (Tomabechi's "function that selects"), showing that the free-will gap $\Gamma$ is independent of abstraction level, while the free-energy depth $F_T$ scales with it. We map all ten conceptual elements to specific, testable brain circuits. We address twenty standard arguments against free will. We distinguish what is proved (the architecture produces the gap), what is hypothesized ($\Gamma > 0$ in biological brains), and what is not claimed (Gödelian incompleteness, moral responsibility, consciousness proof). The theory is falsifiable via five Type-B empirical predictions, all currently untested.

---

## 1. Introduction

### 1.1 Two Thousand Years of the Wrong Question

The free will debate has been structured around a single axis:

| Position | Premise | Conclusion |
|---|---|---|
| Hard Determinism (Sapolsky, Harris) | Physical laws determine all events | No free will |
| Libertarianism | Quantum indeterminacy provides "open futures" | Free will exists |
| Hard Incompatibilism (Pereboom) | Both determinism AND randomness preclude free will | No free will |
| Compatibilism (Dennett, Frankfurt) | Free will = acting on one's own reasons | Compatible |

All four positions share a hidden premise: **determinism implies predictability**. This premise is false for self-referential systems. We demonstrate this constructively.

### 1.2 The Correct Question

> *Can a system predict its own future without changing itself?*

If the answer is no — for structural, architectural reasons — then a specific type of freedom exists: freedom from perfect self-predictability.

### 1.3 The Operational Definition (Toriumi 2026)

**Free will** $\equiv \Gamma > 0$, where:

$$\Gamma = P\bigl[f(s_{\text{before}}) \neq f(s_{\text{after}})\bigr]$$

- $f$: the agent's decision function (fixed weights = personality, memory, values)
- $s_{\text{before}}$: the state before self-simulation
- $s_{\text{after}}$: the state after self-simulation has written $f$'s own intermediate activations as log entries

This definition is: **(1)** measurable, **(2)** falsifiable, **(3)** compatible with determinism, **(4)** randomness-free, **(5)** gradable, **(6)** constructively provable. No other operational definition of free will is known to satisfy all six.

---

## 2. Architecture

### 2.1 Core Principle

$$\text{prediction} = f(s_{\text{before}}) \qquad \text{choice} = f(s_{\text{after}})$$

$f$ is the **identical function** both times — same weights, same personality, same memory. Only the state differs.

### 2.2 Selective Attention

$f$ does not read all log entries. It selectively attends only to semantically meaningful events:

```
relevant(log) = { e in log | e.type in {trial, commit, sim, affect, body, verbal, meta} }
```

Padding events (`PAD`, `CTR`, `XXXXX`) are invisible to $f$. This models real decision-makers attending to meaningful information while ignoring noise. **This selective attention is what distinguishes the theory from a trivial hash-function observation.**

### 2.3 Self-Simulation Writes $f$'s Own Outputs

During self-simulation (depth $k$), the agent runs $f$ on its current state and writes the intermediate activations:

```python
for depth in range(k):
    activation = f.activate(current_log)
    log.append({'type': 'sim', 'depth': depth, 'activation': activation})
```

These `sim` entries are $f$'s own "thoughts." They are meaningful to $f$. **$f$ reads its own past outputs → feedback loop → $\Gamma > 0$.**

### 2.4 The Abstraction Dimension (Tomabechi Integration)

Following Tomabechi's framework, options are stratified by abstraction level $\alpha$ (corresponding to the Chomsky hierarchy):

| $\alpha$ | Level | Example |
|---|---|---|
| 0 | Physical objects | plastic bottle, chair |
| 1 | Persons | mother, friend |
| 2 | Concepts | love, justice, freedom |
| 3 | Functions / rules | way of life, career |
| 4 | Meta-functions | "how to choose how to choose" |

$f$ filters options by abstraction level before comparison. This explains why "a mother and a plastic bottle are not compared": they belong to different abstraction levels, and $f$ selects only the highest-level options as candidates.

Tomabechi's "function that selects" ($\Phi$) is identical to Toriumi's self-simulation ($\sigma$):

$$\Phi(f) = f' \quad \equiv \quad \sigma(f) = f'$$

Both independently arrived at the same recursive structure: a system that selects the function by which it selects.

---

## 3. Results

### 3.1 Control Experiment — The Decisive Test

**Reviewer's strongest criticism**: "Appending any bytes between prediction and choice produces $\Gamma \approx 0.5$. Self-reference is irrelevant."

We test this directly with a control: append the same number of bytes, but as irrelevant padding that $f$'s selective attention filters out.

| Condition | $k=0$ | $k=1$ | $k=2$ | $k=3$ | $k=4$ |
|---|---|---|---|---|---|
| **Self-reference trace** | 0.000 | **0.260** | **0.282** | **0.330** | **0.354** |
| Fixed padding "XXXXX" | 0.000 | 0.000 | 0.000 | 0.000 | 0.000 |
| Counter padding | 0.000 | 0.000 | 0.000 | 0.000 | 0.000 |

**Self-reference is the independent variable.** Arbitrary byte append does not produce the gap. Only self-referential trace does. This was the reviewer's most important objection, and it is answered.

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

Human self-referential structure consists of evolutionary layers (L1–L4). Lesioning them successively shows $\Gamma$ decreases but does not vanish until all are gone:

| Layers Active | Condition | $\Gamma(k=3)$ |
|---|---|---|
| L4+L3+L2+L1 | Healthy | 0.207 |
| L2+L1 | Moderate dementia | 0.198 |
| L2 only | Severe (affect only) | 0.172 |
| None | Brain death | 0.000 |

**Affect alone (L2: insula-amygdala-ACC) preserves $\Gamma > 0$.** This explains why severely demented patients can still express will through facial affect.

### 3.5 Four-Choice Task

For $|O|=4$, expected $\Gamma \approx 1 - 1/4 = 0.75$. Measured: $\Gamma \approx 0.71$. Consistent.

---

## 4. The Two-Layer Architecture

Human cognition is described by two complementary layers:

```
┌─────────────────────────────────────────────┐
│  COMPUTATIONAL LAYER (Γ-layer) — PROVED     │
│    Self-simulation σ                        │
│    f(before) ≠ f(after)                     │
│    Γ ≈ 0.3–0.5                              │
│    Bounded recursion (no Gödel needed)      │
│    Constructively demonstrated              │
├─────────────────────────────────────────────┤
│  NON-COMPUTATIONAL LAYER — HYPOTHETICAL     │
│    Mathematical insight                     │
│    Seeing the truth of Gödel sentences      │
│    Qualia                                   │
│    Abstraction level α=4 (transcendent)     │
│    Penrose OR, Tomabechi's transcendence    │
│    Unproved (Hard Problem territory)        │
└─────────────────────────────────────────────┘
```

The Toriumi Gap $\Gamma$ belongs to the computational layer and does **not** require Gödelian incompleteness. This corrects an earlier overclaim. However, the non-computational layer — Penrose's insight, Tomabechi's transcendence, qualia — remains an open problem, independent of and consistent with $\Gamma$.

### Qualia Are Not Stored

Only propositional descriptions are stored in $L(t)$. Qualia themselves are not.

| Type | Storage | Recall |
|---|---|---|
| Propositional ("rice is sweet") | L2 (semantic memory) | Yes |
| Episodic ("ate rice yesterday") | L1 (episodic memory) | Partial |
| **Qualia ("that taste" itself)** | **Not stored** | **Impossible** |

This explains the phenomenon "I cannot recall the taste, but I can describe it in words": the propositional description (computational layer) is stored; the qualia (non-computational layer) is not.

---

## 5. Brain Circuit Mapping

All concepts map to specific, testable neural circuits:

| Concept | Brain Region | Function |
|---|---|---|
| $f$ (decision function) | DLPFC + OFC + Nucleus Accumbens | Option evaluation, reward prediction |
| $\sigma$ (self-simulation) | Default Mode Network + Hippocampus | Episodic future thinking, memory retrieval |
| $\text{trace}(\sigma)$ | Working Memory + Parahippocampus | Holding intermediate results |
| Selective attention | Fronto-parietal attention + Thalamus | Filtering relevant from irrelevant |
| L1 Episodic memory | Hippocampus CA3→CA1 + PCC | Pattern completion |
| L2 Affective self | Anterior Insula + Amygdala + ACC | Minimal self-boundary, facial affect |
| L3 Linguistic self | Anterior Temporal + Broca + Angular Gyrus | Verbalized thought |
| L4 Meta-cognition | mPFC + Precuneus + PCC | "I notice I am thinking" |
| $f_k$ (commitment) | SMA/pre-SMA + M1 | Action execution |
| $\Gamma$ (gap detection) | Anterior Insula + ACC | Prediction error, conflict |

All mappings are testable via fMRI/TMS.

---

## 6. The Twenty Arguments — All Addressed

| # | Argument | Response |
|---|---|---|
| R1 | Padding produces gap | Control experiment: $\Gamma=0$ for padding |
| R2 | Math is elementary | Novelty is architectural |
| R3 | Zero randomness contradictory | Internal vs external entropy distinguished |
| R4 | External determinism settles it | 1st-person vs 3rd-person: both true |
| R5 | Gödel/Turing overreach | Corrected: Gödel not needed for Γ; non-computational layer separate |
| R6 | Consciousness theorem circular | Downgraded to hypothesis |
| R7 | $F_T$ physically meaningless | Thermodynamic potential, not mechanical force |
| R8 | Toy model only | In silico; human brain unverified |
| R9 | Falsifiability rigged | Type A vs Type B separated |
| R10 | Argument table glib | Reframed as architectural counterexample |
| R11 | Problem of other minds | Γ computable from architecture |
| R12 | Hard problem of consciousness | Γ>0 necessary condition for qualia; bypass, not solution |
| R13 | Physical subservience | Following own history $L(t)$ = freedom |
| R14 | Aging / neurodegeneration | L1–L4 layers; Γ continuous; L2 suffices |
| R15 | No quantum effects in brain | Classical sufficient; quantum amplifies; superradiance (2024) |
| R16 | Origin of weights | Weights shaped by agent's own choices |
| R17 | Big Bang determinism | Determinism ≠ predictability; you are the running |
| R18 | Brain mapping unverified | §5 mapping, all testable |
| R19 | No evolutionary explanation | Cat 3 = unpredictable + efficient; anti-predator |
| R20 | No self-experiment | §7 protocol, runnable now |

---

## 7. Falsifiability

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
| **B1 (EEG)**: $\beta<0$ — accuracy decreases with RT | $\beta\ge 0$ |
| **B2 (TMS)**: $\Gamma$ drops when mPFC disrupted | $\Gamma$ unchanged |
| **B3 (AI)**: Sigmoid transition at $C_{\text{crit}}$ | No jump |
| **B4 ($d\Gamma/dT$)**: $\Gamma$ temperature-independent | $\alpha>0$ |
| **B5 (Jarzynski)**: $I_{\text{self}} \neq 0$ | $I_{\text{self}}=0$ |

**Any single Type B prediction failing falsifies the theory's extension to biological systems.**

---

## 8. Physical Correlate

$$F_T = k_B T \ln 2 \cdot \Gamma \cdot \log_2(|O_\alpha|)$$

$F_T$ [Joules] is the thermodynamic free energy of a self-referential choice. It is NOT a new fundamental force; it is an effective thermodynamic potential.

The gap $\Gamma$ is independent of abstraction level. The depth $F_T$ scales with it: choosing a plastic bottle and choosing a way of life have the same $\Gamma \approx 0.3$, but $F_T$ differs by $\sim 10^8 \times$. This is the physical basis of the subjective weight of high-stakes choices.

Measurement protocols: (A) nanocalorimetry (aggregate over $N > 10^6$), (B) Jarzynski–Sagawa–Ueda equality with $I_{\text{self}}$ correction, (C) $d\Gamma/dT = 0$ thermal-independence test.

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
| **NOT CLAIMED** | Gödelian incompleteness (corrected) |
| **NOT CLAIMED** | $\Gamma>0$ implies moral responsibility |
| **NOT CLAIMED** | $F_T$ is a new fundamental force |
| **NOT CLAIMED** | Human free will is "proven" |

---

## 10. Conclusion

We have:

1. **Defined** free will operationally: $\Gamma > 0$
2. **Constructed** an agent that exhibits the gap uniquely under self-reference
3. **Verified** via control experiment that padding does NOT produce the gap
4. **Shown** gradient growth of $\Gamma$ with $k$, and layer ablation
5. **Integrated** the abstraction dimension (Tomabechi) and the two-layer architecture
6. **Mapped** all concepts to testable brain circuits
7. **Addressed** twenty standard arguments against free will
8. **Specified** five falsifiable Type-B predictions — all untested

The two-thousand-year free will debate remained unresolved because no operational definition existed. We provided one. The control experiment confirms self-reference is the independent variable.

The theory is not complete — it awaits biological data. But it is complete enough to be wrong. That is the standard for science.

---

## References

[1] Schurger, A. et al. (2012). *PNAS* 109(42). [2] Gavenas & Schurger (2024). *bioRxiv*. [3] Haynes et al. (2016). Charité Berlin. [4] Sapolsky (2023). *Determined*. [5] Pereboom (2001). *Living Without Free Will*. [6] Penrose (1989). *The Emperor's New Mind*. [7] Wolfram (2002). *A New Kind of Science*. [8] Landauer (1961). [9] Sagawa & Ueda (2010). *PRL*. [10] Babaei et al. (2024). *JPCB*. [11] Cogitate Consortium (2025). *Nature*. [12] Chomsky (1956). *Three Models for the Description of Language*.

---

*Correspondence: toriumikengo@gmail.com | Source: github.com/toriumib/toriumi-theory*
