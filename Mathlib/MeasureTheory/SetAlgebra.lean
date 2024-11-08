/-
Copyright (c) 2024 Etienne Marion. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Etienne Marion
-/
import Mathlib.MeasureTheory.SetSemiring

/-!
# Algebra of sets

In this file we define the notion of algebra of sets and give its basic properties. An algebra
of sets is a family of sets containing the empty set and closed by complement and binary union.
It is therefore similar to a `σ`-algebra, except that it is not necessarily closed
by countable unions.

We also define the algebra of sets generated by a family of sets and give its basic properties,
and we prove that it is countable when it is generated by a countable family. We prove that
the `σ`-algebra generated by a family of sets `𝒜` is the same as the one generated by the algebra
of sets generated by `𝒜`.

## Main definitions

* `MeasureTheory.IsSetAlgebra`: property of being an algebra of sets.
* `MeasureTheory.generateSetAlgebra`: the algebra of sets generated by a family of sets.

## Main statements

* `MeasureTheory.mem_generateSetAlgebra_elim`: If a set `s` belongs to the algebra of sets
  generated by `𝒜`, then it can be written as a finite union of finite intersections of sets which
  are in `𝒜` or have their complement in `𝒜`.
* `MeasureTheory.countable_generateSetAlgebra`: If a family of sets is countable then so is
  the algebra of sets generated by it.

## References

* <https://en.wikipedia.org/wiki/Field_of_sets>

## Tags

algebra of sets, generated algebra of sets
-/

open MeasurableSpace Set

namespace MeasureTheory

variable {α : Type*} {𝒜 : Set (Set α)} {s t : Set α}

/-! ### Definition and basic properties of an algebra of sets -/

/-- An algebra of sets is a family of sets containing the empty set and closed by complement and
union. Consequently it is also closed by difference (see `IsSetAlgebra.diff_mem`) and intersection
(see `IsSetAlgebra.inter_mem`). -/
structure IsSetAlgebra (𝒜 : Set (Set α)) : Prop where
  empty_mem : ∅ ∈ 𝒜
  compl_mem : ∀ ⦃s⦄, s ∈ 𝒜 → sᶜ ∈ 𝒜
  union_mem : ∀ ⦃s t⦄, s ∈ 𝒜 → t ∈ 𝒜 → s ∪ t ∈ 𝒜

namespace IsSetAlgebra

/-- An algebra of sets contains the whole set. -/
theorem univ_mem (h𝒜 : IsSetAlgebra 𝒜) : univ ∈ 𝒜 :=
  compl_empty ▸ h𝒜.compl_mem h𝒜.empty_mem

/-- An algebra of sets is closed by intersection. -/
theorem inter_mem (h𝒜 : IsSetAlgebra 𝒜) (s_mem : s ∈ 𝒜) (t_mem : t ∈ 𝒜) :
    s ∩ t ∈ 𝒜 :=
  inter_eq_compl_compl_union_compl .. ▸
    h𝒜.compl_mem (h𝒜.union_mem (h𝒜.compl_mem s_mem) (h𝒜.compl_mem t_mem))

/-- An algebra of sets is closed by difference. -/
theorem diff_mem (h𝒜 : IsSetAlgebra 𝒜) (s_mem : s ∈ 𝒜) (t_mem : t ∈ 𝒜) :
    s \ t ∈ 𝒜 := h𝒜.inter_mem s_mem (h𝒜.compl_mem t_mem)

/-- An algebra of sets is a ring of sets. -/
theorem isSetRing (h𝒜 : IsSetAlgebra 𝒜) : IsSetRing 𝒜 where
  empty_mem := h𝒜.empty_mem
  union_mem := h𝒜.union_mem
  diff_mem := fun _ _ ↦ h𝒜.diff_mem

/-- An algebra of sets is closed by finite unions. -/
theorem biUnion_mem {ι : Type*} (h𝒜 : IsSetAlgebra 𝒜) {s : ι → Set α} (S : Finset ι)
    (hs : ∀ i ∈ S, s i ∈ 𝒜) : ⋃ i ∈ S, s i ∈ 𝒜 := h𝒜.isSetRing.biUnion_mem S hs

/-- An algebra of sets is closed by finite intersections. -/
theorem biInter_mem {ι : Type*} (h𝒜 : IsSetAlgebra 𝒜) {s : ι → Set α} (S : Finset ι)
    (hs : ∀ i ∈ S, s i ∈ 𝒜) : ⋂ i ∈ S, s i ∈ 𝒜 := by
  by_cases h : S = ∅
  · rw [h, ← Finset.set_biInter_coe, Finset.coe_empty, biInter_empty]
    exact h𝒜.univ_mem
  · rw [← ne_eq, ← Finset.nonempty_iff_ne_empty] at h
    exact h𝒜.isSetRing.biInter_mem S h hs

end IsSetAlgebra

section generateSetAlgebra

/-! ### Definition and properties of the algebra of sets generated by some family -/

/-- `generateSetAlgebra 𝒜` is the smallest algebra of sets containing `𝒜`. -/
inductive generateSetAlgebra {α : Type*} (𝒜 : Set (Set α)) : Set (Set α)
  | base (s : Set α) (s_mem : s ∈ 𝒜) : generateSetAlgebra 𝒜 s
  | empty : generateSetAlgebra 𝒜 ∅
  | compl (s : Set α) (hs : generateSetAlgebra 𝒜 s) : generateSetAlgebra 𝒜 sᶜ
  | union (s t : Set α) (hs : generateSetAlgebra 𝒜 s) (ht : generateSetAlgebra 𝒜 t) :
      generateSetAlgebra 𝒜 (s ∪ t)

/-- The algebra of sets generated by a family of sets is an algebra of sets. -/
theorem isSetAlgebra_generateSetAlgebra :
    IsSetAlgebra (generateSetAlgebra 𝒜) where
  empty_mem := generateSetAlgebra.empty
  compl_mem := fun _ hs ↦ generateSetAlgebra.compl _ hs
  union_mem := fun _ _ hs ht ↦ generateSetAlgebra.union _ _ hs ht

/-- The algebra of sets generated by `𝒜` contains `𝒜`. -/
theorem self_subset_generateSetAlgebra : 𝒜 ⊆ generateSetAlgebra 𝒜 :=
  fun _ ↦ generateSetAlgebra.base _

/-- The measurable space generated by a family of sets `𝒜` is the same as the one generated
by the algebra of sets generated by `𝒜`. -/
@[simp]
theorem generateFrom_generateSetAlgebra_eq :
    generateFrom (generateSetAlgebra 𝒜) = generateFrom 𝒜 := by
  refine le_antisymm (fun s ms ↦ ?_) (generateFrom_mono self_subset_generateSetAlgebra)
  induction s, ms using generateFrom_induction with
  | hC t ht h =>
    clear h
    induction ht with
    | base u u_mem => exact measurableSet_generateFrom u_mem
    | empty => exact @MeasurableSet.empty _ (generateFrom 𝒜)
    | compl u _ mu => exact mu.compl
    | union u v _ _ mu mv  => exact MeasurableSet.union mu mv
  | empty => exact MeasurableSpace.measurableSet_empty _
  | compl t _ ht => exact ht.compl
  | iUnion t _ ht => exact .iUnion ht

/-- If a family of sets `𝒜` is contained in `ℬ`, then the algebra of sets generated by `𝒜`
is contained in the one generated by `ℬ`. -/
theorem generateSetAlgebra_mono {ℬ : Set (Set α)} (h : 𝒜 ⊆ ℬ) :
    generateSetAlgebra 𝒜 ⊆ generateSetAlgebra ℬ := by
  intro s hs
  induction hs with
  | base t t_mem => exact self_subset_generateSetAlgebra (h t_mem)
  | empty => exact isSetAlgebra_generateSetAlgebra.empty_mem
  | compl t _ t_mem => exact isSetAlgebra_generateSetAlgebra.compl_mem t_mem
  | union t u _ _ t_mem u_mem => exact isSetAlgebra_generateSetAlgebra.union_mem t_mem u_mem

namespace IsSetAlgebra

/-- If a family of sets `𝒜` is contained in an algebra of sets `ℬ`, then so is the algebra of sets
generated by `𝒜`. -/
theorem generateSetAlgebra_subset {ℬ : Set (Set α)} (h : 𝒜 ⊆ ℬ)
    (hℬ : IsSetAlgebra ℬ) : generateSetAlgebra 𝒜 ⊆ ℬ := by
  intro s hs
  induction hs with
  | base t t_mem => exact h t_mem
  | empty => exact hℬ.empty_mem
  | compl t _ t_mem => exact hℬ.compl_mem t_mem
  | union t u _ _ t_mem u_mem => exact hℬ.union_mem t_mem u_mem

/-- If `𝒜` is an algebra of sets, then it contains the algebra generated by itself. -/
theorem generateSetAlgebra_subset_self (h𝒜 : IsSetAlgebra 𝒜) :
    generateSetAlgebra 𝒜 ⊆ 𝒜 := h𝒜.generateSetAlgebra_subset subset_rfl

/-- If `𝒜` is an algebra of sets, then it is equal to the algebra generated by itself. -/
theorem generateSetAlgebra_eq (h𝒜 : IsSetAlgebra 𝒜) : generateSetAlgebra 𝒜 = 𝒜 :=
  Subset.antisymm h𝒜.generateSetAlgebra_subset_self self_subset_generateSetAlgebra

end IsSetAlgebra

/-- If a set belongs to the algebra of sets generated by `𝒜` then it can be written as a finite
union of finite intersections of sets which are in `𝒜` or have their complement in `𝒜`. -/
theorem mem_generateSetAlgebra_elim (s_mem : s ∈ generateSetAlgebra 𝒜) :
    ∃ A : Set (Set (Set α)), A.Finite ∧ (∀ a ∈ A, a.Finite) ∧
    (∀ᵉ (a ∈ A) (t ∈ a), t ∈ 𝒜 ∨ tᶜ ∈ 𝒜) ∧ s = ⋃ a ∈ A, ⋂ t ∈ a, t := by
  induction s_mem with
  | base u u_mem =>
    refine ⟨{{u}}, finite_singleton {u},
      fun a ha ↦ eq_of_mem_singleton ha ▸ finite_singleton u,
      fun a ha t ht ↦ ?_, by simp⟩
    rw [eq_of_mem_singleton ha, ha, eq_of_mem_singleton ht, ht] at *
    exact Or.inl u_mem
  | empty => exact ⟨∅, finite_empty, fun _ h ↦ (not_mem_empty _ h).elim,
    fun _ ha _ _ ↦ (not_mem_empty _ ha).elim, by simp⟩
  | compl u _ u_ind =>
    rcases u_ind with ⟨A, A_fin, mem_A, hA, u_eq⟩
    have := finite_coe_iff.2 A_fin
    have := fun a : A ↦ finite_coe_iff.2 <| mem_A a.1 a.2
    refine ⟨{{(f a).1ᶜ | a : A} | f : (Π a : A, ↑a)}, finite_coe_iff.1 inferInstance,
      fun a ⟨f, hf⟩ ↦ hf ▸ finite_coe_iff.1 inferInstance, fun a ha t ht ↦ ?_, ?_⟩
    · rcases ha with ⟨f, rfl⟩
      rcases ht with ⟨a, rfl⟩
      rw [compl_compl, or_comm]
      exact hA a.1 a.2 (f a).1 (f a).2
    · ext x
      simp only [u_eq, compl_iUnion, compl_iInter, mem_iInter, mem_iUnion, mem_compl_iff,
        exists_prop, Subtype.exists, mem_setOf_eq, iUnion_exists, iUnion_iUnion_eq',
        iInter_exists]
      constructor <;> intro hx
      · choose f hf using hx
        exact ⟨fun ⟨a, ha⟩ ↦ ⟨f a ha, (hf a ha).1⟩, fun _ a ha h ↦ by rw [← h]; exact (hf a ha).2⟩
      · rcases hx with ⟨f, hf⟩
        exact fun a ha ↦ ⟨f ⟨a, ha⟩, (f ⟨a, ha⟩).2, hf (f ⟨a, ha⟩)ᶜ a ha rfl⟩
  | union u v _ _ u_ind v_ind =>
    rcases u_ind with ⟨Au, Au_fin, mem_Au, hAu, u_eq⟩
    rcases v_ind with ⟨Av, Av_fin, mem_Av, hAv, v_eq⟩
    refine ⟨Au ∪ Av, Au_fin.union Av_fin, ?_, ?_, by rw [u_eq, v_eq, ← biUnion_union]⟩
    · rintro a (ha | ha)
      · exact mem_Au a ha
      · exact mem_Av a ha
    · rintro a (ha | ha) t ht
      · exact hAu a ha t ht
      · exact hAv a ha t ht

/-- If a family of sets is countable then so is the algebra of sets generated by it. -/
theorem countable_generateSetAlgebra (h : 𝒜.Countable) :
    (generateSetAlgebra 𝒜).Countable := by
  let ℬ := {s | s ∈ 𝒜} ∪ {s | sᶜ ∈ 𝒜}
  have count_ℬ : ℬ.Countable := by
    apply h.union
    have : compl '' 𝒜 = {s | sᶜ ∈ 𝒜} := by
      ext s
      simpa using ⟨fun ⟨x, x_mem, hx⟩ ↦ by simp [← hx, x_mem], fun hs ↦ ⟨sᶜ, hs, by simp⟩⟩
    exact this ▸ h.image compl
  let f : Set (Set (Set α)) → Set α := fun A ↦ ⋃ a ∈ A, ⋂ t ∈ a, t
  let 𝒞 := {a | a.Finite ∧ a ⊆ ℬ}
  have count_𝒞 : 𝒞.Countable := countable_setOf_finite_subset (countable_coe_iff.1 count_ℬ)
  let 𝒟 := {A | A.Finite ∧ A ⊆ 𝒞}
  have count_𝒟 : 𝒟.Countable := countable_setOf_finite_subset (countable_coe_iff.1 count_𝒞)
  have : generateSetAlgebra 𝒜 ⊆ f '' 𝒟 := by
    intro s s_mem
    rcases mem_generateSetAlgebra_elim s_mem with ⟨A, A_fin, mem_A, hA, rfl⟩
    exact ⟨A, ⟨A_fin, fun a ha ↦ ⟨mem_A a ha, hA a ha⟩⟩, rfl⟩
  exact (count_𝒟.image f).mono this

end generateSetAlgebra

end MeasureTheory
