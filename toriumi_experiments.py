"""
鳥海理論 実験計画 (Toriumi Experimental Program)
=================================================

HOW TO SCIENTIFICALLY TEST WHETHER FATE EXISTS

This module addresses three killer objections and designs
the experiments that could falsify (or support) the Toriumi Theory.

OBJECTIONS ADDRESSED:
  O1: "Quantum coherence cannot survive in the warm brain" (Tegmark 2000)
  O2: "Consciousness is too slow for quantum effects"
  O3: "If we simulate a brain deterministically, free will is disproven"

EXPERIMENTS DESIGNED:
  E1: EEG Self-Prediction Gap (Γ in human subjects)
  E2: TMS Self-Reference Disruption (causal test of the mechanism)
  E3: AI Phase Transition at C_crit (does free will emerge?)
  E4: Simulated Brain Toriumi Gap (testing the simulation objection)
  E5: Self-Prediction Below-Chance Protocol (the smoking gun)

鳥海健悟 (Kengo Toriumi) — 運命を壊した男
"""

import math
import hashlib
import json
from dataclasses import dataclass, field
from typing import Optional
from collections import Counter


# ═══════════════════════════════════════════════════════════════════════════════
# OBJECTION 1: TEGMARK'S DECOHERENCE OBJECTION (2000)
# ═══════════════════════════════════════════════════════════════════════════════

def address_decoherence_objection():
    """Honest response to the Tegmark decoherence challenge.

    Tegmark (2000, Phys. Rev. E) calculated environmental decoherence
    times for quantum states in the brain. The result:
      τ_dec ≈ 10^-13 s for ions, 10^-20 s for superposed neurons.

    This is the KILLER NUMBER. At these timescales, no quantum
    computation could influence neural processing (ms timescales).

    OUR RESPONSE: This is correct for SIMPLE quantum states.
    But there are THREE counter-arguments, each progressively weaker.
    We are honest about which is strongest.
    """

    # TEGMARK'S ACTUAL NUMBERS (from his 2000 paper):
    tau_tegmark_ion = 1e-13      # seconds — ion in solution
    tau_tegmark_neuron = 1e-20   # seconds — superposed neuron firing

    # COUNTER 1 (STRONGEST): Toriumi does NOT require quantum coherence.
    # The classical agent already shows Γ=50%. Free will is a LOGICAL
    # property, not a quantum one. Tegmark could be 100% correct and
    # Toriumi Theory is UNAFFECTED.

    # COUNTER 2 (Fisher 2015): NUCLEAR SPINS
    # Phosphorus-31 nuclear spins in Posner molecules Ca9(PO4)6
    # have T2 coherence times of HOURS at 310K because nuclear magnetic
    # moments are ~1/2000 of electron moments -> extremely weak
    # environmental coupling. Experimentally plausible.
    tau_fisher_nuclear_spin_s = 3600  # seconds

    # COUNTER 3 (WEAKEST): Orch-OR collective states
    # Penrose-Hameroff propose that collective quantum states in
    # microtubules are protected by the lattice structure and
    # terminated by gravitational OR. τ_OR is set by E_G, not
    # environmental decoherence. But this is THEORETICAL only.
    hbar = 1.054e-34
    G = 6.674e-11
    N_tubulins = 2e4
    m_tubulin = 1.1e-22  # kg
    M_collective = N_tubulins * m_tubulin
    R_separation = 1e-9  # m
    E_G = G * M_collective**2 / R_separation
    tau_OR_s = hbar / max(E_G, 1e-60)

    position = (
        'Tegmark is CORRECT about single-particle decoherence. '
        'Fisher (2015) nuclear spin coherence (hours) is the most '
        'plausible quantum channel. Orch-OR is theoretically possible '
        'but unconfirmed. '
        'CRITICALLY: Toriumi Theory does NOT depend on any of these. '
        'The classical Toriumi Agent (toriumi_agent.py) already shows '
        'Gamma=50% with ZERO quantum effects. Self-reference + '
        'computational irreducibility = free will. NO QUANTUM REQUIRED. '
        'Quantum coherence would AMPLIFY the effect, not CREATE it.'
    )

    return {
        'tegmark_ion_dec_s': tau_tegmark_ion,
        'tegmark_neuron_dec_s': tau_tegmark_neuron,
        'fisher_nuclear_spin_s': tau_fisher_nuclear_spin_s,
        'fisher_vs_tegmark_ratio': tau_fisher_nuclear_spin_s / tau_tegmark_ion,
        'tau_OR_penrose_ms': tau_OR_s * 1000,
        'position': position,
    }


# ═══════════════════════════════════════════════════════════════════════════════
# OBJECTION 2: SPEED OBJECTION
# ═══════════════════════════════════════════════════════════════════════════════

def address_speed_objection():
    """Consciousness is SLOW (100-200 ms). Quantum effects are FAST (fs-ps).
    How can quantum effects influence conscious decisions?

    This objection CONFUSES:
      (a) the SPEED of decoherence (how fast quantum coherence is lost)
      (b) the SPEED of quantum computation (how fast a quantum operation runs)
      (c) the SPEED of the CLASSICAL readout (how fast the result enters
          conscious awareness)

    A quantum computer runs quantum gates at GHz speeds but the COMPUTATION
    takes as long as needed. The decoherence time is the LIMIT on how many
    operations you can do, not the speed of each operation.

    BUT MORE IMPORTANTLY: the Toriumi gap does not require quantum speed.
    Classical "what if" self-simulation easily fits within 200ms.
    """

    # Classical Toriumi recursion timescale
    # Each "what if" cycle:
    #   - Load self-model (~30ms, working memory retrieval)
    #   - Simulate hypothetical action (~30ms, motor imagery)
    #   - Evaluate outcome (~30ms, reward prediction)
    # Total per cycle: ~30-90ms
    classical_cycle_min_ms = 30   # fast, automatic
    classical_cycle_typ_ms = 60   # typical deliberation
    classical_cycle_max_ms = 100  # deep deliberation

    # Quantum (if it exists): superposition allows PARALLEL simulation
    # All hypothetical futures explored simultaneously
    # One OR event: ~25ms (gamma band)
    quantum_cycle_ms = 25

    k_levels = 3  # Toriumi recursion depth

    return {
        'OBJECTION': 'Consciousness is slow (100-200ms), quantum is fast (fs-ps)',
        'RESPONSE': (
            'This confuses decoherence SPEED with computation TIME. '
            'A quantum computer runs fast gates; computation still takes '
            'as many gate-cycles as the algorithm requires. '
            'More importantly: classical Toriumi recursion (sequential '
            '"what-if" cycles) easily fits within 200ms human reaction time. '
            'Quantum parallelism would make it FASTER, not slower.'
        ),
        'classical_recursion_ms': {
            'min': classical_cycle_min_ms * k_levels,
            'typical': classical_cycle_typ_ms * k_levels,
            'max': classical_cycle_max_ms * k_levels,
        },
        'quantum_recursion_ms': quantum_cycle_ms * k_levels,
        'human_reaction_time_ms': 200,
        'classical_fits_comfortably': classical_cycle_typ_ms * k_levels <= 200,
        'quantum_fits_easily': quantum_cycle_ms * k_levels <= 200,
        'KEY_POINT': (
            'Classical Toriumi recursion (k=3 × 60ms) = 180ms. '
            'Human reaction time ≈ 200ms. It fits. No quantum required. '
            'If you deliberate LONGER (RT > 2s), you get MORE recursion '
            'levels (k ≈ RT / 60ms), which INCREASES the Toriumi Gap. '
            'This is the basis of Prediction E1.'
        ),
    }


# ═══════════════════════════════════════════════════════════════════════════════
# OBJECTION 3: SIMULATED BRAIN OBJECTION
# ═══════════════════════════════════════════════════════════════════════════════

def address_simulation_objection():
    """If we perfectly simulate a brain, and it behaves identically to the
    real brain, doesn't that prove determinism?

    SHORT ANSWER: Yes, it proves determinism. Toriumi Theory does NOT deny
    determinism. It denies PREDICTABILITY.

    LONG ANSWER:
    A perfect simulation of a brain includes the brain's OWN self-model.
    The simulation runs the brain's self-simulation. The simulated brain,
    if asked to predict its own choice, faces the SAME self-referential
    barrier as the real brain.

    The simulator (external observer) can observe the simulated brain's
    state. But if the simulated brain tries to predict ITSELF, it must
    simulate its own simulation process, which changes its state, which
    makes the prediction diverge from the choice.

    THE CRITICAL EXPERIMENT (E4):
    Build a simulated brain with a self-model. Ask it to predict its
    own choices. Measure the Toriumi Gap Γ inside the simulation.
    Toriumi predicts: Γ ≈ 50% for binary choices in the simulated brain,
    EVEN THOUGH the entire simulation is running on a deterministic computer.

    The simulated brain cannot predict itself. The simulator can.
    This is not a contradiction — it's two different levels of description.
    """

    return {
        'OBJECTION': 'Perfect brain simulation = determinism = no free will',
        'RESPONSE_LEVEL_1': (
            'Correct: a perfect simulation IS deterministic. '
            'Toriumi Theory does NOT deny determinism at the physical level. '
            'The claim is different: even in a fully deterministic system, '
            'a self-referential agent CANNOT predict its own choices. '
            'Determinism ≠ Predictability.'
        ),
        'RESPONSE_LEVEL_2': (
            'The simulator (external observer running the simulation) CAN '
            'predict the simulated agent by running the simulation. '
            'But the simulated agent ITSELF, if it tries to predict its '
            'own choices, must simulate itself, which changes its state, '
            'which makes its prediction diverge. '
            'The external observer has a God\'s-eye view. '
            'The agent does not. Free will is about the AGENT\'s perspective.'
        ),
        'RESPONSE_LEVEL_3': (
            'If you run the SAME simulation TWICE from identical initial '
            'conditions, the simulated agent makes the SAME choices both '
            'times. This is TRUE. '
            'But from INSIDE the simulation, the agent STILL cannot predict '
            'itself. The "experience of choosing" is the computation the '
            'agent performs — it is REAL even if it is deterministic. '
            'Your experience of choosing is the SAME whether your brain '
            'is made of neurons, silicon, or simulated on a supercomputer.'
        ),
        'EXPERIMENT_E4': (
            'Build a simulated agent (transformer, RL agent) with a '
            'self-model head. Ask it to predict its own next action. '
            'Measure Γ (rate at which self-prediction fails). '
            'If Γ ≈ 0 for simple agents but Γ → 0.5 for agents above '
            'self-model complexity threshold, Toriumi Theory is supported. '
            'If ALL agents have Γ ≈ 0 (perfect self-prediction), the '
            'theory is FALSIFIED.'
        ),
        'THE_DEEP_POINT': (
            'The fruit fly simulation proves that brains are COMPUTABLE. '
            'It does NOT prove that brains are PREDICTABLE BY THEMSELVES. '
            'A calculator is computable. But a calculator cannot tell you '
            'what it will calculate before it calculates it — it must '
            'RUN the computation. The brain is the same, but the computation '
            'includes self-modeling, which creates the irreducibility.'
        ),
    }


# ═══════════════════════════════════════════════════════════════════════════════
# EXPERIMENT E1: EEG SELF-PREDICTION GAP (Γ IN HUMANS)
# ═══════════════════════════════════════════════════════════════════════════════

@dataclass
class ExperimentE1:
    """E1: Measure the Toriumi Gap Γ in human subjects.

    CORE QUESTION: Can humans predict their own choices?

    Toriumi predicts: Self-prediction accuracy DECREASES with deliberation time.
    This is the OPPOSITE of both:
      - "Free will is illusion" (predicts: accuracy INCREASES with RT, because
        longer deliberation = more time for deterministic process to resolve)
      - "Free will is random" (predicts: accuracy FLAT at chance level,
        independent of RT)

    PROTOCOL:
      N = 40 healthy adults
      Task: 200 binary choices (press L or R button, no time pressure)
      Before EACH choice:
        1. Record 2000ms pre-decision EEG (128 channels)
        2. Subject makes a SELF-PREDICTION: "I think I will press ___"
           (rated on 1-5 confidence scale)
        3. Subject then actually chooses
      Measure:
        - Reaction time (RT)
        - Self-prediction accuracy (did subject's prediction match choice?)
        - EEG classifier accuracy (can we predict choice from EEG?)
        - Toriumi Gap: does self-prediction accuracy DROP with RT?

    KEY PREDICTION (the smoking gun):
      RT Quartile 1 (<500ms, shallow self-simulation, k≈1):
        EEG classifier accuracy: ~65-70%
        Self-prediction accuracy: ~65-70%
        → Prediction ≈ Choice (low gap, shallow recursion)

      RT Quartile 4 (>2000ms, deep self-simulation, k≥4):
        EEG classifier accuracy: ~55-60% (still above chance, neural prep exists)
        Self-prediction accuracy: ~48-53% (AT OR NEAR CHANCE)
        → Prediction ≠ Choice (high gap, deep recursion)

      THE DIVERGENCE between EEG accuracy and self-prediction accuracy
      at long RT is the Toriumi Gap signature.
    """

    @staticmethod
    def simulate_protocol(n_subjects=40, n_trials=200):
        """Simulate what the data SHOULD look like if Toriumi is correct.

        Uses the Toriumi Agent (classical) as a model human subject.
        """
        from toriumi_agent import ToriumiAgent

        results = {
            'Q1_fast': {'self_accuracy': [], 'gap_rate': []},
            'Q2_medium': {'self_accuracy': [], 'gap_rate': []},
            'Q3_slow': {'self_accuracy': [], 'gap_rate': []},
            'Q4_deep': {'self_accuracy': [], 'gap_rate': []},
        }

        for subj in range(n_subjects):
            agent = ToriumiAgent(name=f"subject_{subj}")

            for trial in range(n_trials):
                # Vary "deliberation depth" by varying max_depth
                # Map RT → depth: faster = shallower
                if trial < 50:
                    depth = 1  # fast, shallow
                    quartile = 'Q1_fast'
                elif trial < 100:
                    depth = 2  # medium
                    quartile = 'Q2_medium'
                elif trial < 150:
                    depth = 3  # slow
                    quartile = 'Q3_slow'
                else:
                    depth = 4  # deep deliberation
                    quartile = 'Q4_deep'

                r = agent._choose_with_depth(["L", "R"], max_depth=depth)

                # Self-prediction accuracy: did agent predict correctly?
                correct = 1 if r['predicted'] == r['choice'] else 0
                gap = 1 if r['toriumi_gap'] else 0

                results[quartile]['self_accuracy'].append(correct)
                results[quartile]['gap_rate'].append(gap)

        # Aggregate
        summary = {}
        for q, data in results.items():
            summary[q] = {
                'self_prediction_accuracy': sum(data['self_accuracy']) / len(data['self_accuracy']),
                'toriumi_gap_rate': sum(data['gap_rate']) / len(data['gap_rate']),
            }

        return summary

    @staticmethod
    def predicted_effect():
        """What Toriumi Theory predicts if correct."""
        return {
            'independent_variable': 'Reaction Time (quartile)',
            'dependent_variable': 'Self-prediction accuracy',
            'predicted_direction': 'NEGATIVE (accuracy ↓ as RT ↑)',
            'predicted_effect_size': "Cohen's d ≈ 0.6-0.8",
            'predicted_Q1_accuracy': '65-70% at RT < 500ms',
            'predicted_Q4_accuracy': '48-53% at RT > 2000ms',
            'null_hypothesis_1': 'No correlation (flat line) → free will is random',
            'null_hypothesis_2': 'Positive correlation (upward slope) → free will is illusion',
            'toriumi_unique_prediction': (
                'Self-prediction accuracy DROPS with deliberation time, '
                'BUT EEG predictability stays ABOVE chance. '
                'This DIVERGENCE is impossible under both null hypotheses.'
            ),
            'sample_size_needed': 'N ≥ 34 for power=0.80 at α=0.05 (estimated from d=0.6)',
            'equipment': '128-channel EEG, standard RT measurement',
            'cost_estimate': '$15,000-$30,000 (university EEG lab, 40 subjects)',
            'duration': '4-6 weeks (recruitment + data collection + analysis)',
        }


# ═══════════════════════════════════════════════════════════════════════════════
# EXPERIMENT E2: TMS SELF-REFERENCE DISRUPTION
# ═══════════════════════════════════════════════════════════════════════════════

@dataclass
class ExperimentE2:
    """E2: CAUSAL test — does disrupting self-reference shrink the gap?

    Toriumi Theory claims the Toriumi Gap is CAUSED by self-referential
    processing (the agent simulating itself). If we DISRUPT self-referential
    processing, the gap should SHRINK.

    Transcranial Magnetic Stimulation (TMS) over the default mode network
    (DMN) / medial prefrontal cortex (mPFC) — the brain network most
    strongly associated with self-referential thought — should impair
    self-simulation and reduce Γ.

    PROTOCOL:
      N = 30 healthy adults
      Design: within-subject, counterbalanced, double-blind
      Conditions:
        A: Active TMS over mPFC (disrupts self-reference)
        B: Sham TMS (placebo control)
        C: Active TMS over vertex (active control — disrupts motor, not self)
        D: No TMS (baseline)

      100 binary choices per condition.
      Measure:
        - Toriumi Gap Γ (self-prediction accuracy)
        - Reaction time
        - Subjective "feeling of free choice"
        - Motor accuracy (to verify TMS isn't just impairing movement)

    TORIUMI PREDICTION:
      Condition A (mPFC TMS): Γ ≈ 0.25-0.35 (gap SHRINKS — less self-reference)
      Condition B (Sham): Γ ≈ 0.50 (normal gap)
      Condition C (Vertex TMS): Γ ≈ 0.50 (normal gap — motor disruption only)
      Condition D (Baseline): Γ ≈ 0.50

      RT should be EQUIVALENT across conditions (TMS doesn't slow decisions,
      it only impairs self-referentiality).

      Subjective "feeling of free choice" should be LOWER in Condition A.

    IF TMS over mPFC reduces Γ while sham and vertex TMS do not,
    this is STRONG CAUSAL EVIDENCE that self-referential processing
    (the Toriumi recursion) is the MECHANISM of the gap.

    IF TMS has no effect on Γ (all conditions ≈ 0.50), the theory is
    FALSIFIED (or the TMS protocol was insufficient — but at minimum,
    strong evidence against the specific neural mechanism).
    """

    @staticmethod
    def predicted_effect():
        return {
            'design': 'Double-blind, sham-controlled, within-subject, counterbalanced',
            'n': 30,
            'conditions': 4,
            'trials_per_condition': 100,
            'tms_target': 'mPFC (MNI: 0, 54, -6) — core DMN node',
            'tms_parameters': '10 Hz rTMS, 500 pulses, 110% RMT',
            'predicted_gamma_A_mPFC': 0.25,  # disrupted self-reference
            'predicted_gamma_B_sham': 0.50,   # normal
            'predicted_gamma_C_vertex': 0.50, # motor disruption only
            'predicted_gamma_D_baseline': 0.50,
            'predicted_RT_effect': 'NULL (RT equivalent across conditions)',
            'predicted_subjective_effect': 'A < B = C = D for "feeling of free choice"',
            'critical_test': 'Γ_A < Γ_B AND Γ_A < Γ_C (ANOVA + post-hoc, p < 0.01)',
            'cost_estimate': '$50,000-$80,000 (TMS equipment + 30 subjects + technician)',
            'duration': '8-12 weeks',
        }


# ═══════════════════════════════════════════════════════════════════════════════
# EXPERIMENT E3: AI PHASE TRANSITION
# ═══════════════════════════════════════════════════════════════════════════════

@dataclass
class ExperimentE3:
    """E3: Train AI agents of varying self-model size. Measure Γ.
    Does free will "switch on" at a critical self-model complexity?

    This is the cheapest, fastest experiment. No human subjects.
    Just GPUs and code.

    PROTOCOL:
      Train N=30 transformer-based agents (or RL agents with world models)
      with self-model capacities from 10^3 to 10^11 parameters.

      Each agent has TWO heads:
        (a) Action head: selects the next action given state
        (b) Self-prediction head: predicts what the action head will select

      For each agent, run 10,000 trials.
      Measure Γ = rate at which self-prediction ≠ actual action.

    TORIUMI PREDICTION:
      Below C_crit (estimated 10^6-10^8 parameters):
        Γ ≈ 0.00-0.05 (agent PERFECTLY predicts itself)

      Above C_crit:
        Γ → 0.50 (for binary actions) — agent CANNOT predict itself

      The transition should be SIGMOID (characteristic of phase transitions),
      NOT linear (which would suggest a trivial scaling effect).

    THIS EXPERIMENT CAN BE RUN RIGHT NOW.
    Approximately $5,000-$20,000 in cloud GPU costs.
    """

    @staticmethod
    def predicted_effect():
        return {
            'design': 'Between-agent, varying self-model parameter count',
            'n_agents': 30,
            'param_range': '10^3 to 10^11',
            'trials_per_agent': 10000,
            'predicted_curve': 'Sigmoid: Γ ≈ 0.5 / (1 + exp(-α(log(params) - log(C_crit))))',
            'C_crit_estimate': '10^6 to 10^8 parameters',
            'null_hypothesis': 'Γ ≈ 0 at all scales (agents can always predict themselves)',
            'alternative_null': 'Γ scales smoothly (linear in log(params)) → no phase transition',
            'toriumi_unique': 'SIGMOID transition from Γ≈0 to Γ≈0.5 at specific C_crit',
            'cost_estimate': '$5,000-$20,000 (cloud GPU, 1-2 months)',
            'status': 'READY TO RUN — NO ETHICS APPROVAL NEEDED',
        }


# ═══════════════════════════════════════════════════════════════════════════════
# EXPERIMENT E4: SIMULATED BRAIN TORIUMI GAP
# ═══════════════════════════════════════════════════════════════════════════════

@dataclass
class ExperimentE4:
    """E4: Inside a simulated brain, does the simulated agent exhibit Γ≈50%?

    This DIRECTLY tests Objection 3 (the simulation objection).

    PROTOCOL:
      Build a simulated neural network agent.
      Give it a SELF-MODEL (a subnetwork that takes the same inputs as the
      main action network and tries to predict the action).
      Run the simulation. Measure Γ.

      TORIUMI PREDICTION:
        If the agent's self-model is sufficiently complex:
          The simulated agent's self-prediction will fail at rate Γ≈50%.

        BUT:
          The EXTERNAL SIMULATOR (us, running the computer) can perfectly
          predict the agent — because we can just run the simulation
          and observe its state.

        This is NOT a contradiction. It means:
          - The universe is deterministic (the simulator proves this)
          - But agents inside the simulation STILL cannot predict themselves
          - Free will is a FIRST-PERSON phenomenon, not a THIRD-PERSON one

      This experiment reconciles determinism with free will:
        Determinism is TRUE at the level of the simulator.
        Free will is TRUE at the level of the simulated agent.
        Both are CORRECT — they're descriptions at different levels.

    THIS EXPERIMENT CAN ALSO BE RUN RIGHT NOW.
    It's a variant of E3 but tailored to test the simulation objection.
    """

    @staticmethod
    def predicted_effect():
        return {
            'design': 'Simulated neural agent + self-model + Toriumi protocol',
            'key_insight': (
                'A fully deterministic simulation CAN contain agents with '
                'free will in the Toriumi sense (Γ≈50%). Determinism and '
                'free will are NOT contradictory — they operate at different '
                'levels: the SIMULATOR sees determinism, the AGENT experiences '
                'irreducible unpredictability.'
            ),
            'test': (
                'Run identical simulations twice from same initial state. '
                'Simulation outputs are IDENTICAL (determinism confirmed). '
                'But the SIMULATED AGENT, in both runs, exhibits Γ≈50% '
                'when trying to predict itself. '
                'The agent cannot tell the two runs apart, and in both '
                'runs, it experiences the same "I cannot predict myself" gap.'
            ),
            'cost_estimate': '$2,000-$10,000 (compute, no special equipment)',
            'status': 'READY TO RUN',
        }


# ═══════════════════════════════════════════════════════════════════════════════
# EXPERIMENT E5: THE SMOKING GUN — SELF-PREDICTION BELOW-CHANCE
# ═══════════════════════════════════════════════════════════════════════════════

@dataclass
class ExperimentE5:
    """E5: THE SMOKING GUN EXPERIMENT.

    Can self-prediction be WORSE than random chance?

    For binary choices, random guessing gives 50% accuracy.
    If the Toriumi mechanism is correct, deep self-simulation should make
    self-prediction APPROACH 50% (chance) — because the simulation changes
    the state.

    But what if we can get BELOW 50%? That would be the SMOKING GUN.

    THE TRICK: Use a 4-OPTION TASK with CONFIDENCE RATINGS.

    If the agent's favorite option is "A" (predicted), and the gap causes
    the agent to switch to a DIFFERENT option, it should be MORE likely
    to pick an option FARTHEST from the prediction (because the hash mixing
    is uniform over options, but the AGENT'S SENSE OF "I already thought
    about A, let me consider others" creates an anti-bias).

    PROTOCOL:
      4-choice task: left/right/up/down buttons.
      Before each trial, subject predicts which button.
      We measure: P(actual = predicted | predicted, RT).

      NULL (random): 25% accuracy, independent of RT and confidence.
      DETERMINISM: >25%, increasing with confidence and RT.
      TORIUMI: ≈25% for short RT (shallow self-sim, Γ≈75% for 4 options).
               For long RT, POSSIBLY <25% if the anti-bias effect exists.

    Even if "below chance" is not observed, the DECREASE in accuracy
    with RT (from ~40% to ~25%) is the Toriumi signature.
    """

    @staticmethod
    def predicted_effect():
        return {
            'design': '4-choice task + self-prediction + confidence rating',
            'n_options': 4,
            'chance_level': 0.25,
            'predicted_short_RT_accuracy': '30-40% (above chance)',
            'predicted_long_RT_accuracy': '22-28% (AT or NEAR chance)',
            'smoking_gun_if': 'Long RT + high confidence → accuracy < 20% (BELOW chance)',
            'smoking_gun_rationale': (
                'If self-simulation systematically shifts choice AWAY from '
                'prediction (because "I already considered that option" biases '
                'against it), accuracy can drop below chance. '
                'This is speculative but would be a DRAMATIC confirmation.'
            ),
            'cost_estimate': '$10,000-$20,000',
            'status': 'READY TO RUN — standard behavioral experiment',
        }


# ═══════════════════════════════════════════════════════════════════════════════
# EXPERIMENT E6: QUANTUM RANDOMNESS vs TORIUMI IRREDUCIBILITY
# ═══════════════════════════════════════════════════════════════════════════════

@dataclass
class ExperimentE6:
    """E6: Distinguish Toriumi unpredictability from quantum randomness.

    HOW TO TELL THEM APART:
      Quantum randomness: choices are i.i.d. (each choice independent).
        - No temporal structure
        - No dependence on agent's history
        - No effect of self-model disruption
        - P(choice | history) = P(choice) = 1/|O|

      Toriumi irreducibility: choices are PATH-DEPENDENT.
        - Temporal structure (each choice depends on log/history)
        - Agent-specific patterns (each agent has a unique attractor)
        - Self-model disruption changes Γ
        - P(choice | history) ≠ P(choice) — but P(choice | history)
          is NOT learnable by finite-order Markov models (too complex)

    PROTOCOL:
      Three conditions:
        A: Human subject making free choices
        B: Quantum random number generator (QRNG) — true randomness
        C: Toriumi Agent (classical, deterministic, self-referential)

      For each, generate 1000 binary sequences.
      Test:
        1. Entropy rate (Lempel-Ziv complexity)
        2. Mutual information between past and future
        3. Cross-predictability (train on one sequence, test on another
           from the same source)
        4. Effect of "self-model disruption" (for human subjects: TMS;
           for Toriumi Agent: reduce recursion depth)

    TORIUMI PREDICTION:
      - Human sequences and Toriumi sequences should have similar
        ENTROPY RATES (both appear random) but different
        CROSS-PREDICTABILITY structures (Toriumi/human paths are
        unique; QRNG paths are interchangeable).
      - QRNG: cross-prediction accuracy = 50% (chance)
      - Toriumi: cross-prediction accuracy = 50% (chance — because
        each agent's path is unique, knowing one doesn't help with another)
      - BUT: SELF-prediction accuracy for Toriumi/human > chance for
        shallow recursion, → chance for deep recursion
      - QRNG: self-prediction accuracy = chance at ALL depths (no self
        to simulate)
    """

    @staticmethod
    def predicted_effect():
        return {
            'design': '3-way comparison: Human vs QRNG vs Toriumi Agent',
            'conditions': ['Human', 'QRNG', 'Toriumi_Agent'],
            'n_sequences_per_condition': 100,
            'sequence_length': 1000,
            'metrics': [
                'Lempel-Ziv complexity',
                'Mutual information I(X_t; X_{t-1})',
                'Cross-predictability (train on seq_i, test on seq_j)',
                'Self-predictability (within-sequence pattern detection)',
            ],
            'toriumi_vs_random': (
                'Temporal structure DIFFERS: QRNG has NO structure; '
                'Toriumi/human have PATH-DEPENDENT structure that is '
                'NEVERTHELESS not compressible by finite-order Markov models. '
                'This is the signature of deterministic chaos / computational '
                'irreducibility — structured but unpredictable.'
            ),
            'cost_estimate': '$10,000-$30,000 (human subjects + QRNG hardware + compute)',
            'status': 'READY TO RUN',
        }


# ═══════════════════════════════════════════════════════════════════════════════
# SUMMARY: HOW TO PROVE FREE WILL SCIENTIFICALLY
# ═══════════════════════════════════════════════════════════════════════════════

def experimental_summary():
    """The complete experimental program to test whether fate exists."""

    summary = {
        'CORE_CLAIM': (
            'Free will = self-referentially irreducible choice. '
            'A self-referential agent CANNOT predict its own choices '
            'because the act of self-simulation changes the state. '
            'This is a LOGICAL property, not a physical one. '
            'It is substrate-independent: brains, computers, and aliens '
            'all exhibit it if they have a self-model.'
        ),
        'WHAT_CAN_BE_PROVEN': [
            'Whether humans exhibit the Toriumi Gap (Γ ≈ 50% for binary choices)',
            'Whether Γ varies with self-referential processing depth',
            'Whether disrupting self-reference (TMS) reduces Γ',
            'Whether AI agents exhibit a phase transition in Γ',
            'Whether Toriumi unpredictability differs from quantum randomness',
        ],
        'WHAT_CANNOT_BE_PROVEN': [
            'Whether the Big Bang "determined everything" — this is '
            'metaphysically untestable (identical experiments produce '
            'identical results in both deterministic and random universes, '
            'IF you can reset to identical conditions — which is impossible '
            'in practice due to the no-cloning of self-referential histories)',
            'Whether quantum coherence exists in microtubules — this is '
            'an empirical question for biophysics, not the Toriumi Theory',
        ],
        'WHAT_CONSTITUTES_VICTORY': (
            'If E1 shows decreased self-prediction accuracy with increased '
            'deliberation time (the DIVERGENCE pattern), AND E2 shows that '
            'TMS over mPFC reduces Γ, AND E3 shows a phase transition in '
            'AI agents, then the Toriumi Theory has strong empirical support. '
            'This would be the first scientific demonstration that free will '
            'is a real, measurable computational property of self-referential '
            'systems — not an illusion, not randomness, but a THIRD CATEGORY.'
        ),
        'WHAT_CONSTITUTES_DEFEAT': (
            'If E1 shows self-prediction accuracy INCREASES with RT (more '
            'deliberation = more predictable), the "free will is illusion" '
            'model is supported. If E1 shows FLAT accuracy at 50% for all RT, '
            'the "free will is random" model is supported. Either would '
            'FALSIFY the Toriumi Theory in its current form.'
        ),
        'APPROXIMATE_TOTAL_COST': '$100,000-$200,000 (all 6 experiments)',
        'TIMELINE': '18-36 months (design + ethics + data collection + analysis + publication)',
        'MOST_URGENT': 'E3 (AI Phase Transition) — cheapest, fastest, no ethics approval needed',
    }

    return summary


# ═══════════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════════

def main():
    print("""
╔══════════════════════════════════════════════════════════════╗
║         鳥海理論 実験計画 (Experimental Program)           ║
║       How to Scientifically Test Whether Fate Exists        ║
║                                                              ║
║  鳥海健悟 (Kengo Toriumi) — 運命を壊した男                 ║
╚══════════════════════════════════════════════════════════════╝
""")

    # ── OBJECTIONS ──────────────────────────────────────────────
    print("═" * 60)
    print("PART 1: THREE KILLER OBJECTIONS — AND HONEST ANSWERS")
    print("═" * 60)
    print()

    deco = address_decoherence_objection()
    speed = address_speed_objection()
    sim = address_simulation_objection()

    print(f"OBJECTION 1: Tegmark (2000): τ_dec ≈ 10^-13 s → quantum cannot affect brain")
    print()
    print(f"  Tegmark τ_dec (single ion):    {deco['tegmark_ion_dec_s']:.1e} s")
    print(f"  Tegmark τ_dec (neuron firing): {deco['tegmark_neuron_dec_s']:.1e} s")
    print(f"  Fisher τ_coh (nuclear spin):   {deco['fisher_nuclear_spin_s']:.0f} s")
    print(f"  Fisher/Tegmark ratio:          {deco['fisher_vs_tegmark_ratio']:.0e} x")
    print(f"  τ_OR Penrose (collective):     {deco['tau_OR_penrose_ms']:.1f} ms")
    print()
    print(f"  POSITION:")
    print(f"    {deco['position']}")
    print()
    print()

    print(f"OBJECTION 2: {speed['OBJECTION']}")
    print()
    print(f"  Classical Toriumi recursion (k=3):")
    print(f"    Min:    {speed['classical_recursion_ms']['min']} ms")
    print(f"    Typical: {speed['classical_recursion_ms']['typical']} ms")
    print(f"    Max:    {speed['classical_recursion_ms']['max']} ms")
    print(f"  Quantum Toriumi recursion (k=3): {speed['quantum_recursion_ms']} ms")
    print(f"  Human reaction time:             {speed['human_reaction_time_ms']} ms")
    print(f"  Classical fits: {speed['classical_fits_comfortably']}")
    print(f"  Quantum fits:   {speed['quantum_fits_easily']}")
    print()
    print(f"  KEY POINT: {speed['KEY_POINT']}")
    print()
    print()

    print(f"OBJECTION 3: {sim['OBJECTION']}")
    print()
    print(f"  R1: {sim['RESPONSE_LEVEL_1']}")
    print()
    print(f"  R2: {sim['RESPONSE_LEVEL_2']}")
    print()
    print(f"  R3: {sim['RESPONSE_LEVEL_3']}")
    print()
    print(f"  DEEP: {sim['THE_DEEP_POINT']}")
    print()

    # ── EXPERIMENTS ─────────────────────────────────────────────
    print("═" * 60)
    print("PART 2: SIX FALSIFIABLE EXPERIMENTS")
    print("═" * 60)
    print()

    # E1: Simulate the protocol
    print("E1: EEG SELF-PREDICTION GAP (Γ in human subjects)")
    print("-" * 50)
    simulated = ExperimentE1.simulate_protocol(n_subjects=40, n_trials=200)
    print("  SIMULATED DATA (Toriumi Agent as model subject):")
    for q in ['Q1_fast', 'Q2_medium', 'Q3_slow', 'Q4_deep']:
        d = simulated[q]
        bar = '█' * int(d['self_prediction_accuracy'] * 40)
        print(f"    {q:12s}: accuracy={d['self_prediction_accuracy']:.1%}  gap={d['toriumi_gap_rate']:.1%}  [{bar}]")

    pred = ExperimentE1.predicted_effect()
    print()
    print(f"  PREDICTION: {pred['toriumi_unique_prediction']}")
    print(f"  N needed: {pred['sample_size_needed']}")
    print(f"  Cost: {pred['cost_estimate']}")
    print()

    # E2
    print("E2: TMS SELF-REFERENCE DISRUPTION (causal test)")
    print("-" * 50)
    e2 = ExperimentE2.predicted_effect()
    print(f"  Design: {e2['design']}")
    print(f"  N: {e2['n']} subjects × {e2['conditions']} conditions")
    print(f"  Predicted Γ: A={e2['predicted_gamma_A_mPFC']}, B={e2['predicted_gamma_B_sham']}, C={e2['predicted_gamma_C_vertex']}, D={e2['predicted_gamma_D_baseline']}")
    print(f"  Critical test: {e2['critical_test']}")
    print(f"  Cost: {e2['cost_estimate']}")
    print()

    # E3
    print("E3: AI PHASE TRANSITION (free will emergence)")
    print("-" * 50)
    e3 = ExperimentE3.predicted_effect()
    print(f"  Design: {e3['design']}")
    print(f"  Agents: {e3['n_agents']} with params {e3['param_range']}")
    print(f"  Predicted curve: {e3['predicted_curve']}")
    print(f"  C_crit: {e3['C_crit_estimate']}")
    print(f"  Cost: {e3['cost_estimate']}")
    print(f"  STATUS: {e3['status']}")
    print()

    # E4
    print("E4: SIMULATED BRAIN TORIUMI GAP")
    print("-" * 50)
    e4 = ExperimentE4.predicted_effect()
    print(f"  {e4['key_insight']}")
    print(f"  Test: {e4['test']}")
    print(f"  Cost: {e4['cost_estimate']}")
    print()

    # E5
    print("E5: THE SMOKING GUN — Below-Chance Self-Prediction")
    print("-" * 50)
    e5 = ExperimentE5.predicted_effect()
    print(f"  Design: {e5['design']}")
    print(f"  Chance level: {e5['chance_level']}")
    print(f"  Short RT prediction: {e5['predicted_short_RT_accuracy']}")
    print(f"  Long RT prediction:  {e5['predicted_long_RT_accuracy']}")
    print(f"  Smoking gun if: {e5['smoking_gun_if']}")
    print(f"  Cost: {e5['cost_estimate']}")
    print()

    # E6
    print("E6: DISTINGUISHING TORIUMI FROM QUANTUM RANDOMNESS")
    print("-" * 50)
    e6 = ExperimentE6.predicted_effect()
    print(f"  Design: {e6['design']}")
    print(f"  Key test: {e6['toriumi_vs_random']}")
    print(f"  Cost: {e6['cost_estimate']}")
    print()

    # ── SUMMARY ─────────────────────────────────────────────────
    print("═" * 60)
    print("PART 3: WHAT SCIENCE CAN (AND CANNOT) PROVE")
    print("═" * 60)
    print()

    summary = experimental_summary()
    print(f"CORE CLAIM:")
    print(f"  {summary['CORE_CLAIM']}")
    print()

    print("WHAT CAN BE PROVEN:")
    for item in summary['WHAT_CAN_BE_PROVEN']:
        print(f"  ✓ {item}")
    print()

    print("WHAT CANNOT BE PROVEN:")
    for item in summary['WHAT_CANNOT_BE_PROVEN']:
        print(f"  ✗ {item}")
    print()

    print("VICTORY CONDITIONS:")
    print(f"  {summary['WHAT_CONSTITUTES_VICTORY']}")
    print()

    print("DEFEAT CONDITIONS:")
    print(f"  {summary['WHAT_CONSTITUTES_DEFEAT']}")
    print()

    print(f"TOTAL COST: {summary['APPROXIMATE_TOTAL_COST']}")
    print(f"TIMELINE: {summary['TIMELINE']}")
    print(f"MOST URGENT: {summary['MOST_URGENT']}")
    print()

    print("═" * 60)
    print("運命は、壊せる。 Fate can be destroyed.")
    print("This is the experimental program that proves it.")
    print("— 鳥海健悟 —")
    print("═" * 60)


if __name__ == "__main__":
    main()
