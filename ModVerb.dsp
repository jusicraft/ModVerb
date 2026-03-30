import("stdfaust.lib");

declare name "ModVerb";
declare author "me";

// IO routing
in_gain = vslider("h:[0]IO/Input [unit:dB]", 0, -60, +12, 0.1) : ba.db2linear;
out_gain = vslider("h:[0]IO/Output [unit:dB]", 0, -60, +12, 0.1) : ba.db2linear;
dry_lvl = vslider("h:[0]IO/Dry", 1.0, 0, 1, 0.01);
wet_lvl = vslider("h:[0]IO/Wet", 0.5, 0, 1, 0.01);

// core reverb (jpverb)
t60 = vslider("h:[1]Reverb/Decay [unit:s]", 3.0, 0.1, 15.0, 0.1);
damp = vslider("h:[1]Reverb/HF Damp", 0.5, 0, 1, 0.01);
base_size = vslider("h:[1]Reverb/Base Size", 1.0, 0.1, 5.0, 0.01);

// wet sig filters
lp_freq = vslider("h:[2]Filters/Wet LP [unit:Hz]", 10000, 100, 20000, 1) : si.smoo;
hp_freq = vslider("h:[2]Filters/Wet HP [unit:Hz]", 100, 20, 10000, 1) : si.smoo;

// trainsient detect
trans_thresh = vslider("h:[3]Modulation/Threshold", 0.1, 0, 1, 0.001);
env_atk = vslider("h:[3]Modulation/Attack [unit:s]", 0.05, 0.001, 0.5, 0.001);
env_rel = vslider("h:[3]Modulation/Release [unit:s]", 0.5, 0.01, 5, 0.01);
mod_amt = vslider("h:[3]Modulation/Amount", 0.5, -1, 1, 0.01);

//
// PROCESS
//
process(in1, in2) = (out_l, out_r)
with {
    // Input gain
    in1_g = in1 * in_gain;
    in2_g = in2 * in_gain;

    // dry Path (Unaffected)
    dry_l = in1_g * dry_lvl;
    dry_r = in2_g * dry_lvl;

    // wet Input
    wet_in_l = in1_g;
    wet_in_r = in2_g;

    //------------------------------------------------------

    // Transient detection
    mono_in = (in1_g + in2_g) * 0.5;
    fast_env = mono_in : abs : an.amp_follower_ar(0.001, 0.01);
    slow_env = mono_in : abs : an.amp_follower_ar(0.01, 0.05);
    trans_diff = max(0.0, fast_env - slow_env);
    // vel-sensitive trigger
    is_transient = trans_diff > trans_thresh;
    pulse_trigger = (is_transient > is_transient');
    velocity_pulse = pulse_trigger * trans_diff;
    // Envelope
    mod_env = velocity_pulse : en.ar(env_atk, env_rel);
    // size mod
    mod_size = (base_size + (mod_env * mod_amt)) : max(0.1) : min(5.0) : si.smoo;

    //-------------------------------

    // coreVerb (jpverb)
    reverb_out = wet_in_l, wet_in_r : re.jpverb(t60, damp, mod_size, 0.707, 0.1, 2.0, 1.0, 1.0, 1.0, 20, 20000);
    rev_l = reverb_out : _, !;
    rev_r = reverb_out : !, _;

    // HP LP filtering
    filt_l = rev_l : fi.highpass(2, hp_freq) : fi.lowpass(2, lp_freq);
    filt_r = rev_r : fi.highpass(2, hp_freq) : fi.lowpass(2, lp_freq);

    // Out gain
    out_l = (dry_l + filt_l * wet_lvl) * out_gain;
    out_r = (dry_r + filt_r * wet_lvl) * out_gain;
    //
};