# ModVerb: Faust DSP Documentation

**ModVerb** is a transient-responsive reverberation effect written in Faust. It utilizes a high-quality algorithmic reverb core (`re.jpverb`) and pairs it with a custom transient detection circuit. This allows the reverb's spatial characteristics (size) to dynamically swell, shrink, or duck in real-time based on the rhythmic and dynamic content of the incoming audio signal.

---

## Architecture Overview

The signal flow is divided into four main stages:

1.  **Input & Routing:** Handles input gain staging and splits the signal into dry and wet paths.
2.  **Transient Detection & Modulation:** A sidechain path that analyzes the mono-summed input to detect amplitude spikes (transients) and generates an envelope.
3.  **Core Reverb:** The wet signal is processed by the `jpverb` algorithm, with its internal size parameter continuously modulated by the generated envelope.
4.  **Reverb Filtering:** The reverberated signal is shaped by high-pass and low-pass filters before joining the dry signal at the output stage.

---

## GUI Parameters

The user interface is grouped into four distinct sections for easy navigation ***(only in VST3)***:

### [0] IO (Input/Output)
Controls the overall gain staging and the dry/wet balance of the effect.

| Parameter | Unit | Range | Description |
| :--- | :--- | :--- | :--- |
| **Input Gain** | dB | -60 to +12 | Adjusts the volume of the incoming signal before processing. |
| **Output Gain**| dB | -60 to +12 | Adjusts the final output volume of the combined dry/wet signal. |
| **Dry Level** | Linear | 0.0 to 1.0 | Controls the volume of the unaffected, original audio. |
| **Wet Level** | Linear | 0.0 to 1.0 | Controls the volume of the reverberated audio. |

### [1] Reverb
Controls the core characteristics of the `jpverb` algorithm.

| Parameter | Unit | Range | Description |
| :--- | :--- | :--- | :--- |
| **Decay (t60)** | Seconds | 0.1 to 15.0 | The time it takes for the reverb tail to decay by 60dB. |
| **HF Damp** | Linear | 0.0 to 1.0 | Attenuates high frequencies over time, simulating acoustic absorption. |
| **Base Size** | Linear | 0.1 to 5.0 | The default physical size of the simulated space before modulation. |

### [2] Filters
Post-reverb equalization to shape the wet signal.

| Parameter | Unit | Range | Description |
| :--- | :--- | :--- | :--- |
| **Wet LP** | Hz | 100 to 20000 | Low-pass filter; cuts frequencies above the set value. |
| **Wet HP** | Hz | 20 to 10000 | High-pass filter; cuts frequencies below the set value. |

### [3] Modulation
Controls the transient detector and how it affects the reverb's size.

| Parameter | Unit | Range | Description |
| :--- | :--- | :--- | :--- |
| **Trans Threshold**| Linear | 0.0 to 1.0 | How far the fast envelope must exceed the slow envelope to trigger. |
| **Envelope Attack** | Seconds | 0.001 to 0.5 | How quickly the modulation envelope reaches its peak after a transient. |
| **Envelope Release** | Seconds | 0.01 to 5.0 | How long it takes for the modulation envelope to return to zero. |
| **Mod Amount** | Linear | -1.0 to 1.0 | The depth and polarity of the modulation applied to the Base Size. |

---

## The Modulation Algorithm

The transient detection system in BrickBattleVerb goes beyond simple volume thresholding, utilizing a relative, velocity-sensitive approach:

* **Relative Detection:** The algorithm runs the input signal through two envelope followers in parallel�one fast (1ms attack) and one slow (10ms attack). A transient is detected only when the fast envelope aggressively outpaces the slow one. This prevents sustained loud notes from freezing the detector.
* **Velocity Sensitivity:** When a transient crosses the `Trans Threshold`, it generates a 1-sample pulse. This pulse is multiplied by the amplitude difference between the fast and slow envelopes. This ensures that a massive drum hit pushes the reverb size further than a quiet ghost note.
* **AR Envelope Generation:** The velocity-scaled pulse is fed into an Attack-Release (`en.ar`) generator. This creates a smooth, musical swell (`Env Attack`) and fade (`Env Release`) that prevents the delay lines inside the reverb from glitching or clicking when the size changes.
* **Bipolar Modulation:** The `Mod Amount` slider allows for both positive and negative modulation. 
    * *Positive values (e.g., +0.5):* A transient makes the room temporarily "explode" into a larger size before shrinking back to the `Base Size`.
    * *Negative values (e.g., -0.5):* A transient temporarily shrinks the room (tightening the reverb on the hit) before blooming back to the `Base Size`.