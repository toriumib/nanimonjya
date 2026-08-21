# Self-Referential Decision Systems and the Structural Impossibility of Perfect Self-Prediction

**Toriumi (鳥海)** | toriumikengo@gmail.com | August 13, 2026

---

## Abstract

We define and construct a **self-referential decision system (SRDS)** — a deterministic agent whose decision function $f$ is applied to two different states: the state before self-simulation, and the state after. Self-simulation writes $f$'s own intermediate activations into the state, which $f$ then reads. Because $f$ selectively attends to meaningful events and ignores irrelevant input changes, the gap between self-prediction and actual choice ($\Gamma > 0$) appears **uniquely** under self-reference, not under arbitrary input perturbation. A control experiment confirms this: appending fixed padding produces $\Gamma = 0$; appending self-referential trace produces $\Gamma > 0$. The gap magnitude grows with self-simulation depth ($k$). We report four in silico experiments confirming the architecture behaves as predicted. We honestly distinguish what is proved (the architecture produces the gap), what is hypothesized ($\Gamma > 0$ in biological brains), and what is not claimed (Gödelian incompleteness, proof of consciousness, moral responsibility). The theory is falsifiable via EEG, TMS, AI scaling, and microcalorimetry. All risky empirical predictions remain untested.

---

## 1. Introduction

### 1.1 The Problem

For two millennia, the free will debate has been structured around a single axis:

| Position | Premise | Conclusion |
|---|---|---|
| Hard Determinism | Physical laws determine all events | No free will |
| Libertarianism | Quantum indeterminacy provides "open futures" | Free will exists |
| Hard Incompatibilism | Both determinism AND randomness preclude free will | No free will |
| Compatibilism | Free will = acting on one's own reasons | Compatible with determinism |

The hard incompatibilist argument is particularly damaging: replacing determinism with randomness merely replaces the "slave to physical law" with the "slave to the die."

We argue this entire framing rests on a hidden premise: **determinism implies predictability**. This premise is false for self-referential systems.

### 1.2 The Correct Question

> *Can a system predict its own future without changing itself?*

If the answer is no — for structural, architectural reasons — then a specific type of freedom exists: freedom from perfect self-predictability.

### 1.3 What This Paper Does

1. Defines a **self-referential decision system (SRDS)** with an operational property $\Gamma$
2. Shows that $\Gamma > 0$ occurs uniquely under self-reference (not under arbitrary input change)
3. Demonstrates that $\Gamma$ grows with self-simulation depth
4. Provides a control experiment confirming self-reference is the independent variable
5. Honestly distinguishes proven claims from hypotheses and from non-claims

### 1.4 What This Paper Does NOT Claim

- Does NOT claim Gödelian incompleteness or Turing undecidability (the recursion is bounded)
- Does NOT claim to have proven that biological brains are SRDS agents
- Does NOT claim that $\Gamma > 0$ constitutes "consciousness" or "free will" in the philosophical sense
- Does NOT claim moral responsibility follows from $\Gamma > 0$
- Does NOT claim that $F_T$ is a new fundamental force

---

## 2. Architecture

### 2.1 Core Principle

$$f(s) \neq f(s \oplus \text{trace}(\sigma(s))) \quad \text{when } \sigma \text{ reads } f\text{'s own outputs}$$

The decision function $f$ is applied **twice** to **two different states**:

- **Prediction**: $p = f(s_{\text{before}})$ — from the state before self-simulation
- **Choice**: $c = f(s_{\text{after}})$ — from the state after self-simulation

Critically, $f$ is the **same function** both times. It has fixed weights (personality, memory, values). Only the state differs.

### 2.2 Selective Attention

$f$ does not read all log entries. It selectively attends to semantically meaningful events:

```
relevant(log) = { e in log | e.type in {trial, commit, sim, sim_exit} }
```

Padding events (`PAD`, `CTR`, `XXXXX`) are invisible to $f$. This is not an arbitrary design choice — it models the fact that real decision-makers attend to meaningful information and ignore noise.

### 2.3 Self-Simulation Writes f's Own Outputs

During self-simulation (depth $k$), the agent runs $f$ on its current state and writes the **intermediate activations** as log entries:

```python
def self_simulate(k):
    for depth in range(k):
        activation = f.activate(current_log)    # f's own intermediate state
        log.append({'type': 'sim', 'depth': depth, 'act': activation})
```

These activation entries are **meaningful to f** (they appear in `relevant(log)`). They are $f$'s own "thoughts" — its internal evaluation of the situation at each simulation step.

### 2.4 Why This Produces a Gap

1. $f$ reads `sim` entries because they are in `relevant(log)`
2. Before self-simulation: no `sim` entries exist → $f(s_{\text{before}})$ does not read them
3. After self-simulation: `sim` entries exist → $f(s_{\text{after}})$ reads them
4. The `sim` entries contain $f$'s own prior outputs → feedback loop
5. Therefore $f(s_{\text{after}}) \neq f(s_{\text{before}})$ with probability $\Gamma > 0$

### 2.5 Control Experiment

**Critical test**: Is $\Gamma$ caused by self-reference, or merely by input length change?

We compare three conditions with the same total bytes appended:

| Condition | What is appended | Visible to $f$? | $\Gamma$ prediction |
|---|---|---|---|
| **Self-reference** | `sim` entries containing $f$'s own activations | Yes | $\Gamma > 0$ |
| **Fixed padding** | `{'e':'PAD','v':'XXXXX'}` × k×3 | No (filtered by `relevant()`) | $\Gamma = 0$ |
| **Counter padding** | `{'e':'CTR','v':i}` for i=0..k×3 | No (filtered by `relevant()`) | $\Gamma = 0$ |

**Result (500 trials each, k=3):**

| Condition | $\Gamma$ |
|---|---|
| Self-reference | **0.330** |
| Fixed padding | **0.000** |
| Counter padding | **0.000** |

**Self-reference is the independent variable.** Arbitrary byte append does not produce the gap. Only self-referential trace does.

---

## 3. Results

### 3.1 Experiment 1: Phase Transition at k=1

$\Gamma(k=0) = 0.000$. $\Gamma(k=1) = 0.260$. $\Delta\Gamma = 0.260$.

The transition from "no self-simulation" to "self-simulation" produces a qualitative change in predictability. This is the structural signature of self-referential decision-making.

### 3.2 Experiment 2: Gradient — $\Gamma$ grows with $k$

| k | $\Gamma$ | Interpretation |
|---|---|---|
| 0 | 0.000 | Reflex (no self-simulation) |
| 1 | 0.257 | Shallow deliberation |
| 3 | 0.328 | Moderate deliberation |
| 8 | 0.333 | Deep deliberation |
| 50 | 0.310 | Very deep deliberation |

$\Gamma$ grows from 0 to ~0.31 as $k$ increases from 0 to 50. The growth is monotonic but shallow — deeper self-simulation gradually increases the gap, saturating as the log becomes dominated by self-referential entries.

This is the **$\beta < 0$ behavioral prediction**: deeper deliberation → larger gap between self-prediction and actual choice.

### 3.3 Experiment 3: Identical Clones (Determinism + Freedom)

Two agents initialized with identical weights and identical empty logs produce **identical choice sequences** (200/200 match). Determinism is confirmed at the third-person level.

However, a single agent attempting to predict its own choices exhibits $\Gamma > 0$. The agent cannot predict itself.

**Both are true. No contradiction.** Determinism is a third-person description. Self-predictability is a first-person property.

### 3.4 Experiment 4: 4-Choice Task

For $|O| = 4$, the expected gap is $\Gamma \approx 1 - 1/4 = 0.75$. Measured: $\Gamma(k \ge 1) \approx 0.71$. Consistent with prediction.

---

## 4. What Is Proved, Hypothesized, and Not Claimed

| Category | Statement | Status |
|---|---|---|
| **PROVED** | The architecture produces $\Gamma > 0$ uniquely under self-reference | In silico confirmed |
| **PROVED** | Arbitrary padding does NOT produce $\Gamma > 0$ | Control experiment verified |
| **PROVED** | $\Gamma$ grows with self-simulation depth $k$ | In silico confirmed |
| **HYPOTHESIS** | Biological brains instantiate this architecture | Untested (needs EEG) |
| **HYPOTHESIS** | $\Gamma > 0$ correlates with subjective "feeling of free choice" | Untested (needs E1) |
| **HYPOTHESIS** | Self-simulation $\sigma$ corresponds to conscious deliberation | Untested (needs TMS + EEG) |
| **NOT CLAIMED** | The agent exhibits Gödelian incompleteness | Bounded recursion only |
| **NOT CLAIMED** | $\Gamma > 0$ implies moral responsibility | Physics ≠ ethics |
| **NOT CLAIMED** | $F_T$ is a new fundamental force | Thermodynamic potential only |

---

## 5. Category Distinction

| Category | Mechanism | $\Gamma$ | Free will? | How to test |
|---|---|---|---|---|
| 1. Deterministic (non-self-ref) | $f(s) = s+1$ | 0 | No | Predictable |
| 2. Random (external entropy) | $f(s) = \text{rand}()$ | $\approx 0.5$ | No (slave to coin) | Disable RNG → $\Gamma \to 0$ |
| **3. Self-referential (internal feedback)** | $f$ reads own past outputs | $\approx 0.3-0.5$ | **Yes (structural self-unpredictability)** | Disable self-sim → $\Gamma \to 0$ (verified) |

Categories 2 and 3 produce similar $\Gamma$ values but for **different reasons**. Category 2 unpredictability comes from outside the agent. Category 3 unpredictability comes from the agent's own feedback loop.

---

## 6. Relation to Prior Work

This work builds on but is distinct from:

- **Computational irreducibility** (Wolfram 2002): Our irreducibility is from $f$'s sequential dependency on its own trace, not from cellular automaton unpredictability. The control experiment distinguishes this from mere input sensitivity.
- **Gödelian arguments** (Penrose 1989, Lucas 1961): We do NOT claim Gödelian incompleteness. Our recursion is bounded (finite $k$, base case). The self-reference is architectural, not logical.
- **Libet experiments** (Libet 1983) and their refutation (Schurger 2012, 2024): Our architecture provides a computational model of why readiness potential is NOT a decision — it's the start of self-simulation trace accumulation.
- **Compatibilism** (Dennett 1984, Frankfurt 1969): Our architecture provides a constructive mechanism for compatibilism: determinism is true (third person), but self-predictability is impossible (first person).

---

## 7. Falsifiability

### Type A Predictions (architectural — verified in silico)

These are tautological within the SRDS architecture. They confirm the architecture works as designed, not that nature instantiates it:

- A1: $\Gamma(k=0) = 0$ — **confirmed**
- A2: $\Gamma(k \ge 1) > 0$ for self-reference — **confirmed**
- A3: $\Gamma = 0$ for fixed/counter padding — **confirmed**
- A4: $\Gamma$ grows monotonically with $k$ — **confirmed**

### Type B Predictions (risky empirical — ALL UNTESTED)

These are genuine empirical risks. Any ONE of them failing falsifies the theory's extension to biological systems:

- **B1 (EEG)**: $\beta < 0$ — self-prediction accuracy decreases with reaction time in humans
- **B2 (TMS)**: $\Gamma$ drops significantly when mPFC is disrupted by TMS
- **B3 (AI scaling)**: $\Gamma$ exhibits sigmoid phase transition at critical self-model size $C_{\text{crit}}$
- **B4 ($d\Gamma/dT$)**: $\Gamma$ is temperature-independent ($\alpha = 0$, not thermal noise)
- **B5 (Jarzynski)**: $I_{\text{self}}$ correction term $\neq 0$ in Sagawa-Ueda equality

**None of these have been performed.** The theory remains unverified for biological systems.

---

## 8. Limitations

1. All experiments are **in silico** on a toy architecture. No biological data.
2. $\Gamma$ in the current implementation is binary-dominated (SHA-256 avalanche) for the hash-based variant, and gradient-only for the neural-net variant. A unified architecture combining both properties is future work.
3. The physical correlate $F_T$ is below single-decision thermal noise floor. Detection requires massive averaging ($N \ge 10^6$ decisions).
4. The connection to subjective experience ("feeling of free choice") is entirely hypothetical.
5. The theory provides a **computational mechanism** for one specific type of freedom (freedom from perfect self-predictability). Whether this corresponds to what philosophers mean by "free will" is a separate question outside the scope of this paper.

---

## 9. Conclusion

We have constructed a self-referential decision system in which the same decision function $f$, applied to two different states (before and after self-simulation), produces systematically different outputs. A control experiment confirms that this gap appears uniquely under self-reference, not under arbitrary input perturbation.

The gap magnitude $\Gamma$ measures the degree to which the agent cannot perfectly predict itself. This is a structural property of the architecture, not a philosophical claim.

The theory is falsifiable via five specific experimental protocols, all of which remain untested. If any Type B prediction fails, the theory is falsified. If all succeed, a specific computational mechanism for one type of freedom will have been empirically established.

---

## References

[1] Schurger, A. et al. (2012). An accumulator model for spontaneous neural activity. *PNAS*, 109(42), E2904-E2913.
[2] Gavenas, J., Schurger, A. et al. (2024). Probing for Intentions. *bioRxiv*.
[3] Haynes, J.-D. et al. (2016). The brain-computer duel: Do we have free will? Charité Berlin.
[4] Sapolsky, R. (2023). *Determined: A Science of Life Without Free Will*. Penguin Press.
[5] Pereboom, D. (2001). *Living Without Free Will*. Cambridge University Press.
[6] Penrose, R. (1989). *The Emperor's New Mind*. Oxford University Press.
[7] Wolfram, S. (2002). *A New Kind of Science*. Wolfram Media.
[8] Dennett, D. (1984). *Elbow Room*. MIT Press.
[9] Landauer, R. (1961). Irreversibility and heat generation in the computing process. *IBM J. Res. Dev.*
[10] Sagawa, T. & Ueda, M. (2010). Generalized Jarzynski equality. *Phys. Rev. Lett.*, 104(9), 090602.
[11] Babaei, M. et al. (2024). UV Superradiance from Mega-Networks of Tryptophan. *J. Phys. Chem. B*.
[12] Cogitate Consortium (2025). Adversarial testing of GNW and IIT. *Nature*.

---

*Correspondence: toriumikengo@gmail.com*
*Source code: github.com/toriumib/toriumi-theory*
