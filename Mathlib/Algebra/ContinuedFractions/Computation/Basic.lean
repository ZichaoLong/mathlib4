/-
Copyright (c) 2020 Kevin Kappelmann. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kevin Kappelmann
-/
import Mathlib.Algebra.Order.Floor
import Mathlib.Algebra.ContinuedFractions.Basic
import Mathlib.Tactic.ApplyFun

/-!
# Computable Continued Fractions

## Summary

We formalise the standard computation of (regular) continued fractions for linear ordered floor
fields. The algorithm is rather simple. Here is an outline of the procedure adapted from Wikipedia:

Take a value `v`. We call `⌊v⌋` the *integer part* of `v` and `v - ⌊v⌋` the *fractional part* of
`v`.  A continued fraction representation of `v` can then be given by `[⌊v⌋; b₀, b₁, b₂,...]`, where
`[b₀; b₁, b₂,...]` recursively is the continued fraction representation of `1 / (v - ⌊v⌋)`.  This
process stops when the fractional part hits 0.

In other words: to calculate a continued fraction representation of a number `v`, write down the
integer part (i.e. the floor) of `v`. Subtract this integer part from `v`. If the difference is 0,
stop; otherwise find the reciprocal of the difference and repeat. The procedure will terminate if
and only if `v` is rational.

For an example, refer to `IntFractPair.stream`.

## Main definitions

- `GenContFract.IntFractPair.stream`: computes the stream of integer and fractional parts of a given
  value as described in the summary.
- `GenContFract.of`: computes the generalised continued fraction of a value `v`.
  In fact, it computes a regular continued fraction that terminates if and only if `v` is rational.

## Implementation Notes

There is an intermediate definition `GenContFract.IntFractPair.seq1` between
`GenContFract.IntFractPair.stream` and `GenContFract.of` to wire up things. Users should not
(need to) directly interact with it.

The computation of the integer and fractional pairs of a value can elegantly be
captured by a recursive computation of a stream of option pairs. This is done in
`IntFractPair.stream`. However, the type then does not guarantee the first pair to always be
`some` value, as expected by a continued fraction.

To separate concerns, we first compute a single head term that always exists in
`GenContFract.IntFractPair.seq1` followed by the remaining stream of option pairs. This sequence
with a head term (`seq1`) is then transformed to a generalized continued fraction in
`GenContFract.of` by extracting the wanted integer parts of the head term and the stream.

## References

- https://en.wikipedia.org/wiki/Continued_fraction

## Tags

numerics, number theory, approximations, fractions
-/


namespace GenContFract

-- Fix a carrier `K`.
variable (K : Type*)

/-- We collect an integer part `b = ⌊v⌋` and fractional part `fr = v - ⌊v⌋` of a value `v` in a pair
`⟨b, fr⟩`.
-/
structure IntFractPair where
  b : ℤ
  fr : K

variable {K}

/-! Interlude: define some expected coercions and instances. -/


namespace IntFractPair

/-- Make an `IntFractPair` printable. -/
instance [Repr K] : Repr (IntFractPair K) :=
  ⟨fun p _ => "(b : " ++ repr p.b ++ ", fract : " ++ repr p.fr ++ ")"⟩

instance inhabited [Inhabited K] : Inhabited (IntFractPair K) :=
  ⟨⟨0, default⟩⟩

/-- Maps a function `f` on the fractional components of a given pair.
-/
def mapFr {β : Type*} (f : K → β) (gp : IntFractPair K) : IntFractPair β :=
  ⟨gp.b, f gp.fr⟩

section coe

/-! Interlude: define some expected coercions. -/


-- Fix another type `β` which we will convert to.
variable {β : Type*} [Coe K β]

-- Porting note: added so we can add the `@[coe]` attribute
/-- The coercion between integer-fraction pairs happens componentwise. -/
@[coe]
def coeFn : IntFractPair K → IntFractPair β := mapFr (↑)

/-- Coerce a pair by coercing the fractional component. -/
instance coe : Coe (IntFractPair K) (IntFractPair β) where
  coe := coeFn

@[simp, norm_cast]
theorem coe_to_intFractPair {b : ℤ} {fr : K} :
    (↑(IntFractPair.mk b fr) : IntFractPair β) = IntFractPair.mk b (↑fr : β) :=
  rfl

end coe

-- Note: this could be relaxed to something like `LinearOrderedDivisionRing` in the future.
-- Fix a discrete linear ordered field with `floor` function.
variable [LinearOrderedField K] [FloorRing K]

/-- Creates the integer and fractional part of a value `v`, i.e. `⟨⌊v⌋, v - ⌊v⌋⟩`. -/
protected def of (v : K) : IntFractPair K :=
  ⟨⌊v⌋, Int.fract v⟩

/-- Creates the stream of integer and fractional parts of a value `v` needed to obtain the continued
fraction representation of `v` in `GenContFract.of`. More precisely, given a value `v : K`, it
recursively computes a stream of option `ℤ × K` pairs as follows:
- `stream v 0 = some ⟨⌊v⌋, v - ⌊v⌋⟩`
- `stream v (n + 1) = some ⟨⌊frₙ⁻¹⌋, frₙ⁻¹ - ⌊frₙ⁻¹⌋⟩`,
    if `stream v n = some ⟨_, frₙ⟩` and `frₙ ≠ 0`
- `stream v (n + 1) = none`, otherwise

For example, let `(v : ℚ) := 3.4`. The process goes as follows:
- `stream v 0 = some ⟨⌊v⌋, v - ⌊v⌋⟩ = some ⟨3, 0.4⟩`
- `stream v 1 = some ⟨⌊0.4⁻¹⌋, 0.4⁻¹ - ⌊0.4⁻¹⌋⟩ = some ⟨⌊2.5⌋, 2.5 - ⌊2.5⌋⟩ = some ⟨2, 0.5⟩`
- `stream v 2 = some ⟨⌊0.5⁻¹⌋, 0.5⁻¹ - ⌊0.5⁻¹⌋⟩ = some ⟨⌊2⌋, 2 - ⌊2⌋⟩ = some ⟨2, 0⟩`
- `stream v n = none`, for `n ≥ 3`
-/
protected def stream (v : K) : Stream' <| Option (IntFractPair K)
  | 0 => some (IntFractPair.of v)
  | n + 1 =>
    (IntFractPair.stream v n).bind fun ap_n =>
      if ap_n.fr = 0 then none else some (IntFractPair.of ap_n.fr⁻¹)

theorem stream_fr_nonneg_and_lt_one {v : K} : ∀ {n : ℕ} (p : IntFractPair K),
    p ∈ IntFractPair.stream v n → 0 ≤ p.fr ∧ p.fr < 1
  | 0 => by simp [IntFractPair.stream, IntFractPair.of, Int.fract_lt_one]
  | n + 1 => by
    intro
    simp [IntFractPair.stream]
    cases IntFractPair.stream v n with
    | none => simp
    | some q =>
      simp only [IntFractPair.of, Option.some_bind, Option.ite_none_left_eq_some, Option.some.injEq,
        and_imp]
      rintro _ rfl
      exact ⟨Int.fract_nonneg _, Int.fract_lt_one _⟩

theorem stream_b_pos {v : K} : ∀ {n : ℕ}, 0 < n → ∀ (p : IntFractPair K),
    p ∈ IntFractPair.stream v n → 0 < p.b
  | 0 => by simp
  | n + 1 => by
    intro
    simp [IntFractPair.stream]
    cases h : IntFractPair.stream v n with
    | none => simp
    | some q =>
      simp only [IntFractPair.of, Option.some_bind, Option.ite_none_left_eq_some, Option.some.injEq,
        and_imp, forall_apply_eq_imp_iff, Int.lt_floor_iff, Int.cast_zero, zero_add]
      intro h0
      exact (one_le_inv₀ (lt_of_le_of_ne (stream_fr_nonneg_and_lt_one _ h).1 (Ne.symm h0))).2
        (le_of_lt (stream_fr_nonneg_and_lt_one _ h).2)


theorem last_stream_ne_one (v : K) (n : ℕ) : ∀ (p : IntFractPair K),
    p ∈ IntFractPair.stream v (n + 1) → IntFractPair.stream v (n + 2) = none →
    p.b ≠ 1 := by
  simp only [IntFractPair.stream, IntFractPair.of, Option.mem_def, Option.bind_eq_none,
    ite_eq_left_iff, reduceCtorEq, imp_false, Decidable.not_not, ne_eq]
  cases hq : IntFractPair.stream v n with
  | none => simp
  | some q =>
    simp only [Option.some_bind, Option.ite_none_left_eq_some, Option.some.injEq, and_imp,
      forall_apply_eq_imp_iff]
    intro h₁ h₂
    replace h₂ := h₂ h₁
    rw [Int.fract_eq_iff, sub_zero] at h₂
    let ⟨z, hz⟩ := h₂.2.2
    rw [hz, Int.floor_intCast]
    rintro rfl
    simp only [Int.cast_one, inv_eq_one] at hz
    exact ne_of_lt (stream_fr_nonneg_and_lt_one _ hq).2 hz

/-- Shows that `IntFractPair.stream` has the sequence property, that is once we return `none` at
position `n`, we also return `none` at `n + 1`.
-/
theorem stream_isSeq (v : K) : (IntFractPair.stream v).IsSeq := by
  intro _ hyp
  simp [IntFractPair.stream, hyp]

/--
Uses `IntFractPair.stream` to create a sequence with head (i.e. `seq1`) of integer and fractional
parts of a value `v`. The first value of `IntFractPair.stream` is never `none`, so we can safely
extract it and put the tail of the stream in the sequence part.

This is just an intermediate representation and users should not (need to) directly interact with
it. The setup of rewriting/simplification lemmas that make the definitions easy to use is done in
`Algebra.ContinuedFractions.Computation.Translations`.
-/
protected def seq1 (v : K) : Stream'.Seq1 <| IntFractPair K :=
  ⟨IntFractPair.of v, -- the head
    -- take the tail of `IntFractPair.stream` since the first element is already in the head
    Stream'.Seq.tail
      -- create a sequence from `IntFractPair.stream`
      ⟨IntFractPair.stream v, -- the underlying stream
        @stream_isSeq _ _ _ v⟩⟩ -- the proof that the stream is a sequence

theorem one_not_mem_getLast_seq1 (v : K) (ht : (IntFractPair.seq1 v).2.Terminates) (a : K) :
    ⟨1, a⟩ ∉ (((IntFractPair.seq1 v).2).toList ht).getLast? := by
  cases h : (IntFractPair.seq1 v).2.length ht with
  | zero => simp [Stream'.Seq.length_eq_zero.1 h]
  | succ n =>
    rw [Stream'.Seq.getLast?_toList]
    intro hmem
    refine last_stream_ne_one v _ _ hmem ?_ rfl
    apply (Stream'.Seq.length_le_iff (s := (IntFractPair.seq1 v).2) (h := ht)).1
    simp [h]

end IntFractPair

/-- Returns the `GenContFract` of a value. In fact, the returned gcf is also a `ContFract` that
terminates if and only if `v` is rational
(see `Algebra.ContinuedFractions.Computation.TerminatesIffRat`).

The continued fraction representation of `v` is given by `[⌊v⌋; b₀, b₁, b₂,...]`, where
`[b₀; b₁, b₂,...]` recursively is the continued fraction representation of `1 / (v - ⌊v⌋)`. This
process stops when the fractional part `v - ⌊v⌋` hits 0 at some step.

The implementation uses `IntFractPair.stream` to obtain the partial denominators of the continued
fraction. Refer to said function for more details about the computation process.
-/
protected def of [LinearOrderedField K] [FloorRing K] (v : K) : GenContFract K :=
  let ⟨h, s⟩ := IntFractPair.seq1 v -- get the sequence of integer and fractional parts.
  ⟨h.b, -- the head is just the first integer part
    s.map fun p => ⟨1, p.b⟩⟩ -- the sequence consists of the remaining integer parts as the partial
                            -- denominators; all partial numerators are simply 1

end GenContFract

namespace ContFract

open GenContFract

variable {K : Type*} [LinearOrderedField K] [FloorRing K]

/-- Returns the `ContFract` of a value. The returned gcf is a `ContFract` that
terminates if and only if `v` is rational
(see `Algebra.ContinuedFractions.Computation.TerminatesIffRat`).

The continued fraction representation of `v` is given by `[⌊v⌋; b₀, b₁, b₂,...]`, where
`[b₀; b₁, b₂,...]` recursively is the continued fraction representation of `1 / (v - ⌊v⌋)`. This
process stops when the fractional part `v - ⌊v⌋` hits 0 at some step.

The implementation uses `IntFractPair.stream` to obtain the partial denominators of the continued
fraction. Refer to said function for more details about the computation process.
-/
protected def of (v : K) : ContFract :=
  let s := IntFractPair.seq1 v -- get the sequence of integer and fractional parts.
  ⟨s.1.b, -- the head is just the first integer part
    s.2.map fun p => p.b.toNat.toPNat',
    by
      intro h
      have := IntFractPair.one_not_mem_getLast_seq1 v (Stream'.Seq.terminates_map_iff.1 h)
      simp only [Stream'.Seq.getLast?_toList, Option.mem_def, Stream'.Seq.length_map,
        Stream'.Seq.map_get?, Option.map_eq_some', not_exists, not_and] at *
      rintro ⟨xb, xfr⟩ hx hx1
      apply this xfr
      simp only [hx, Option.some.injEq, IntFractPair.mk.injEq, and_true]
      have h0xb : 0 < xb := IntFractPair.stream_b_pos (Nat.succ_pos _) _ hx
      apply_fun ((↑) : ℕ+ → ℤ) at hx1
      simp only [Nat.toPNat'_coe, Int.lt_toNat, Nat.cast_zero, Nat.cast_ite, Int.ofNat_toNat,
        Nat.cast_one, PNat.val_ofNat, ite_eq_right_iff, max_eq_left (le_of_lt h0xb)] at hx1
      exact hx1 h0xb⟩ -- the sequence consists of the remaining integer parts as the
    -- partial denominators

end ContFract
