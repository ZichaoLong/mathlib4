/-
Copyright (c) 2023 Antoine Chambert-Loir. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Antoine Chambert-Loir

-/

import Mathlib.Algebra.Order.BigOperators.Ring.Finset
import Mathlib.GroupTheory.GroupAction.SubMulAction
import Mathlib.GroupTheory.Perm.ConjAct
import Mathlib.GroupTheory.Perm.Cycle.PossibleTypes
import Mathlib.GroupTheory.Perm.DomMulAct

/-! # Centralizer of a permutation and cardinality of conjugacy classes
  # in the symmetric groups

Let `α : Type` with `Fintype α` (and `DecidableEq α`).
The main goal of this file is to compute the cardinality of
conjugacy classes in `Equiv.Perm α` and `alternatingGroup α`.
Every `g : Equiv.Perm α` has a `cycleType α : Multiset ℕ`.
By `Equiv.Perm.isConj_iff_cycleType_eq`,
two permutations are conjugate in `Equiv.Perm α` iff
their cycle types are equal.
To compute the cardinality of the conjugacy classes, we could use
a purely combinatorial approach and compute the number of permutations
with given cycle type but we resorted to a more algebraic approach.

Given `g : Equiv.Perm α`, the conjugacy class of `g` is the orbit
of `g` under the action `ConjAct (Equiv.Perm α)`, and we use
the orbit-stabilizer theorem
(`MulAction.card_orbit_mul_card_stabilizer_eq_card_group`)
to reduce the computation to the computation of the centralizer of `g`,
the subgroup of `Equiv.Perm α` consisting of all permutations
which commute with `g`. It is accessed here as
`MulAction.stabilizer (ConjAct (Equiv.Perm α)) g`.

We compute this subgroup as follows.

* If `h : MulAction.stabilizer (ConjAct (Equiv.Perm α)) g`, then the action
  of `h` by conjugation on `Equiv.Perm α` stabilizes `g.cycleFactorsFinset`.
  That induces an action of `MulAction.stabilizer (ConjAct (Equiv.Perm α)) g`
  on `g.cycleFactorsFinset` which is defined via
  `Equiv.Perm.OnCycleFactors.subMulActionOnCycleFactors `

* This action defines a group morphism `Equiv.Perm.OnCycleFactors.φ g` from
  `MulAction.stabilizer (ConjAct (Equiv.Perm α)) g`
  to `Equiv.Perm (g.cycleFactorsFinset)`

* `Equiv.Perm.OnCycleFactors.Iφ_eq_range` shows that the range of `Equiv.Perm.OnCycleFactors.φ g`
  is the subgroup `Iφ g` of `Equiv.Perm (g.cycleFactorsFinset)`
  consisting of permutations `τ` which preserve the length of the cycles.
  This is showed by constructing a right inverse `Equiv.Perm.OnCycleFactors.φ'`
  in `Equiv.Perm.OnCycleFactors.hφ'_is_rightInverse`.

* `Equiv.Perm.OnCycleFactors.hφ_range_card` computes the cardinality of
  `range (Equiv.Perm.OnCycleFactors.φ g)` as a product of factorials.

* For an element `z : Equiv.Perm α`, we then prove in
  `Equiv.Perm.OnCycleFactors.hφ_mem_ker_iff` that `ConjAct.toConjAct z` belongs to
  the kernel of `Equiv.Perm.OnCycleFactors.φ g` if and only if it permutes `g.fixedPoints`
  and it acts on each cycle of `g` as a power of that cycle.
  This gives a description of the kernel of `Equiv.Perm.OnCycleFactors.φ g` as the product
  of a symmetric group and of a product of cyclic groups.
  This analysis starts with the morphism `Equiv.Perm.OnCycleFactors.θ`,
  its injectivity `Equiv.Perm.OnCycleFactors.θ_injective`,
  its range `Equiv.Perm.OnCycleFactors.hφ_ker_eq_θ_range`,
  and  its cardinality `Equiv.Perm.OnCycleFactors.hθ_range_card`.

* `Equiv.Perm.conj_stabilizer_card g` computes the cardinality
  of the centralizer of `g`

* `Equiv.Perm.conj_class_card_mul_eq g` computes the cardinality
  of the conjugacy class of `g`.

* We now can compute the cardinality of the set of permutations with given cycle type.
  The condition for this cardinality to be zero is given by
  `Equiv.Perm.card_of_cycleType_eq_zero_iff`
  which is itself derived from `Equiv.Perm.exists_with_cycleType_iff`.

* `Equiv.Perm.card_of_cycleType_mul_eq m` and `Equiv.Perm.card_of_cycleType m`
  compute this cardinality.

-/

section

variable {G : Type*} [Group G] (g : G)

theorem Subgroup.centralizer_eq :
    Subgroup.centralizer {g} = Subgroup.comap ConjAct.toConjAct.toMonoidHom
      (MulAction.stabilizer (ConjAct G) g) := by
  ext k
  simp only [MulEquiv.toMonoidHom_eq_coe, mem_comap, MonoidHom.coe_coe,
    MulAction.mem_stabilizer_iff]
  simp only [mem_centralizer_iff, Set.mem_singleton_iff, forall_eq, ConjAct.toConjAct_smul]
  rw [eq_comm]
  exact Iff.symm mul_inv_eq_iff_eq_mul

theorem Subgroup.centralizer_card_eq :
    Nat.card (Subgroup.centralizer {g}) =
      Nat.card (MulAction.stabilizer (ConjAct G) g) := by
  simp only [← SetLike.coe_sort_coe, Set.Nat.card_coe_set_eq]
  rw [Subgroup.centralizer_eq, Subgroup.coe_comap, MulEquiv.toMonoidHom_eq_coe, MonoidHom.coe_coe]
  erw [Set.preimage_equiv_eq_image_symm]
  exact Set.ncard_image_of_injective _ ConjAct.ofConjAct.injective

end

open scoped Pointwise

@[to_additive instDecidablePredMemSetFixedByAddOfDecidableEq]
instance {α β : Type*} [Monoid α] [DecidableEq β] [MulAction α β] (a : α) :
    DecidablePred fun b : β => b ∈ MulAction.fixedBy β a := by
  intro b
  simp only [MulAction.mem_fixedBy, Equiv.Perm.smul_def]
  infer_instance

namespace Equiv.Perm

open MulAction Equiv Subgroup

variable {α : Type*} [DecidableEq α] [Fintype α] {g : Equiv.Perm α}

theorem CycleType.count_def (n : ℕ) :
    g.cycleType.count n =
      Fintype.card {c : g.cycleFactorsFinset // (c : Perm α).support.card = n } := by
  -- work on the LHS
  rw [cycleType, Multiset.count_eq_card_filter_eq]
  -- rewrite the `Fintype.card` as a `Finset.card`
  rw [Fintype.subtype_card, Finset.univ_eq_attach, Finset.filter_attach',
    Finset.card_map, Finset.card_attach]
  simp only [Function.comp_apply, Finset.card, Finset.filter_val,
    Multiset.filter_map, Multiset.card_map]
  apply congr_arg
  ext c
  apply congr_arg₂ _ rfl
  apply Multiset.filter_congr
  intro d h
  simp only [Function.comp_apply, eq_comm, Finset.mem_val.mp h, exists_const]

namespace OnCycleFactors

variable (g)

variable {g} in
lemma Subgroup.mem_centralizer_singleton_iff {k : Perm α} :
    k ∈ Subgroup.centralizer {g} ↔ k * g = g * k := by
  simp only [mem_centralizer_iff, Set.mem_singleton_iff, forall_eq]
  rw [eq_comm]

variable {g} in
lemma Subgroup.Centralizer.toConjAct_smul_mem_cycleFactorsFinset
    (k : Subgroup.centralizer {g}) (c : g.cycleFactorsFinset) :
    ConjAct.toConjAct (k : Perm α) • (c : Perm α) ∈ g.cycleFactorsFinset := by
  suffices (g.cycleFactorsFinset : Set (Perm α)) =
    (ConjAct.toConjAct (k : Perm α)) • (g.cycleFactorsFinset) by
    rw [← Finset.mem_coe, this]
    simp only [Set.smul_mem_smul_set_iff, Finset.mem_coe, Finset.coe_mem]
  have this := cycleFactorsFinset_conj_eq (ConjAct.toConjAct (k : Perm α)) g
  rw [ConjAct.toConjAct_smul, Subgroup.mem_centralizer_singleton_iff.mp k.prop, mul_assoc] at this
  simp only [mul_right_inv, mul_one] at this
  conv_lhs => rw [this]
  simp only [Finset.coe_smul_finset]

/-- The action by conjugation of `Subgroup.centraliser {g}`
  on the cycles of a given permutation -/
def Subgroup.Centralizer.cycleFactorsFinset_mulAction :
    MulAction (Subgroup.centralizer {g}) g.cycleFactorsFinset where
  smul k c := ⟨ConjAct.toConjAct (k : Perm α) • (c : Perm α),
    Subgroup.Centralizer.toConjAct_smul_mem_cycleFactorsFinset k c⟩
  one_smul c := by
    rw [← Subtype.coe_inj]
    change ConjAct.toConjAct (1 : Perm α) • (c : Perm α) = c
    simp only [map_one, one_smul]
  mul_smul k l c := by
    simp only [← Subtype.coe_inj]
    change ConjAct.toConjAct (k * l : Perm α) • (c : Perm α) =
      ConjAct.toConjAct (k : Perm α) • (ConjAct.toConjAct (l : Perm α)) • (c : Perm α)
    simp only [map_mul, mul_smul]

/-- The conjugation action of `Subgroup.centralizer {g}` on `g.cycleFactorsFinset` -/
scoped instance : MulAction (Subgroup.centralizer {g}) (g.cycleFactorsFinset) :=
  (Subgroup.Centralizer.cycleFactorsFinset_mulAction g)

/-- The canonical morphism from `Subgroup.centralizer {g}`
  to the group of permutations of `g.cycleFactorsFinset` -/
def toPermHom := MulAction.toPermHom (Subgroup.centralizer {g}) g.cycleFactorsFinset

theorem centralizer_smul_def (k : Subgroup.centralizer {g}) (c : g.cycleFactorsFinset) :
    k • c = ⟨k * c * k⁻¹, Subgroup.Centralizer.toConjAct_smul_mem_cycleFactorsFinset k c⟩ :=
  rfl

theorem toPerm_apply (k : Subgroup.centralizer {g}) (c :  g.cycleFactorsFinset) :
    (toPermHom g k c) = k • c := rfl

theorem coe_toPerm (k : Subgroup.centralizer {g}) (c :  g.cycleFactorsFinset) :
    (toPermHom g k c : Perm α) = k * c * (k : Perm α)⁻¹ := rfl

/-- The range of `Equiv.Perm.OnCycleFactors.toPerm`.

The equality is proved by `Equiv.Perm.OnCycleFactors.range_eq_range_toPerm'`. -/
def range_toPerm' : Subgroup (Perm g.cycleFactorsFinset) where
  carrier := {τ | ∀ c, (τ c : Perm α).support.card = (c : Perm α).support.card}
  one_mem' := by
    simp only [Set.mem_setOf_eq, coe_one, id_eq, eq_self_iff_true, imp_true_iff]
  mul_mem' := by
    intro σ τ hσ hτ
    simp only [Subtype.forall, Set.mem_setOf_eq, coe_mul, Function.comp_apply]
    simp only [Subtype.forall, Set.mem_setOf_eq] at hσ hτ
    intro c hc
    rw [hσ, hτ]
  inv_mem' := by
    intro σ hσ
    simp only [Subtype.forall, Set.mem_setOf_eq] at hσ ⊢
    intro c hc
    rw [← hσ]
    · simp only [Finset.coe_mem, Subtype.coe_eta, apply_inv_self]
    · simp only [Finset.coe_mem]

variable {g} in
theorem mem_range_toPerm'_iff {τ : Perm g.cycleFactorsFinset} :
    τ ∈ range_toPerm' g ↔
      ∀ c, (τ c : Perm α).support.card = (c : Perm α).support.card :=
  Iff.rfl

/-- `k : Subgroup.centralizer {g}` belongs to the kernel of `toPerm g`
iff it commutes with each cycle of `g` -/
theorem mem_ker_toPermHom_iff (k : Subgroup.centralizer {g}) :
    k ∈ (toPermHom g).ker ↔
      ∀ c ∈ g.cycleFactorsFinset, Commute (k : Perm α) c := by
  simp only [toPerm, MonoidHom.mem_ker, DFunLike.ext_iff]
  simp only [coe_one, id_eq, Subtype.forall]
  apply forall₂_congr
  intro c hc
  simp only [← Subtype.coe_inj, coe_toPerm, commute_iff_eq, coe_inv, mul_inv_eq_iff_eq_mul]

end OnCycleFactors

open OnCycleFactors Subgroup

/-- A `Basis` of a permutation is a choice of an element in each of its cycles -/
class Basis (g : Equiv.Perm α) where
  /-- A choice of elements in each cycle -/
  (toFun : g.cycleFactorsFinset → α)
  /-- For each cycle, the chosen element belongs to the cycle -/
  (mem_support_self' : ∀ c, toFun c ∈ (c : Perm α).support)

instance (g : Perm α) :
  DFunLike (Basis g) (g.cycleFactorsFinset) (fun _ => α) where
  coe a := a.toFun
  coe_injective' a a' _ := by cases a; cases a'; congr

namespace Basis

theorem nonempty (g : Perm α) : Nonempty (Basis g) := by
  have (c : g.cycleFactorsFinset) : (c : Perm α).support.Nonempty :=
    IsCycle.nonempty_support (mem_cycleFactorsFinset_iff.mp c.prop).1
  exact ⟨fun c ↦ (this c).choose, fun c ↦ (this c).choose_spec⟩

variable (a : Basis g)

theorem mem_support_self (c : g.cycleFactorsFinset) :
    a c ∈ (c : Perm α).support := a.mem_support_self' c

theorem injective : Function.Injective a := by
  intro c d h
  rw [← Subtype.coe_inj]
  apply g.cycleFactorsFinset_pairwise_disjoint.eq c.prop d.prop
  simp only [Disjoint, not_forall, not_or]
  use a c
  conv_rhs => rw [h]
  simp only [← Perm.mem_support, a.mem_support_self c, a.mem_support_self d, and_self]

theorem cycleOf_eq (c : g.cycleFactorsFinset) :
    g.cycleOf (a c) = c :=
  (cycle_is_cycleOf (a.mem_support_self c) c.prop).symm

-- The presence of `e` in this definition may look unnecessary but
-- is useful for the definition of `k` below
/-- Given a basis `a` of `g`, this is the basic function that allows
  to define the inverse of `Equiv.Perm.OnCycleFactors.toPerm` :
  `Kf a e ⟨c, i⟩ = (g ^ i) (a (e c))` -/
def Kf (e : range_toPerm' g) (x : g.cycleFactorsFinset × ℤ) : α :=
  (g ^ x.2) (a ((e : Perm g.cycleFactorsFinset) x.1))

/- -- This version would have been simpler, but doesn't work later
 -- because of the use of Function.extend which requires functions
 -- with *one* argument.
def Kf (a : Equiv.Perm.Basis g) (e : Equiv.Perm g.cycleFactorsFinset)
  (c : g.cycleFactorsFinset) (i : ℤ) : α :=
  (g ^ i) (a (e c))
-/

variable {e e' : range_toPerm' g} {c d : g.cycleFactorsFinset} {i j : ℤ}

theorem Kf_def :
    Kf a e ⟨c, i⟩ = (g ^ i) (a ((e : Perm g.cycleFactorsFinset) c)) := rfl

theorem Kf_def_zero :
    Kf a e ⟨c, 0⟩ = a ((e: Perm g.cycleFactorsFinset) c) := rfl

theorem Kf_def_one :
    Kf a e ⟨c, 1⟩ = g (a ((e : Perm g.cycleFactorsFinset) c)) := rfl

/-- The multiplicative-additive property of `Equiv.Perm.OnCycleFactors.Kf` -/
theorem Kf_mul_add :
    Kf a (e' * e) ⟨c, i + j⟩ =
      (g ^ i) (Kf a e' ⟨(e : Perm g.cycleFactorsFinset) c, j⟩) := by
  simp only [Kf_def, zpow_add, Submonoid.coe_mul, coe_toSubmonoid, coe_mul, Function.comp_apply]

/-- The additive property of `Equiv.Perm.OnCycleFactors.Kf` -/
theorem Kf_add : Kf a e ⟨c, i + j⟩ = (g ^ i) (Kf a 1 ⟨(e : Perm g.cycleFactorsFinset) c, j⟩) := by
  rw [← Kf_mul_add, one_mul]

/-- The additive property of `Equiv.Perm.OnCycleFactors.Kf` -/
theorem Kf_add' :
    Kf a e ⟨c, i + j⟩ = (g ^ i) (Kf a e ⟨c, j⟩) := by
  rw [← mul_one e, Kf_mul_add, mul_one]
  rfl

theorem cycleOf_Kf_apply_eq :
    g.cycleOf (Kf a e ⟨c, i⟩) = (e : Perm g.cycleFactorsFinset) c := by
  rw [Kf_def, cycleOf_self_apply_zpow, a.cycleOf_eq]

theorem Kf_apply : g (Kf a e ⟨c, i⟩) = Kf a e ⟨c, i + 1⟩ := by
  rw [Kf_def, Kf_def, ← mul_apply, ← zpow_one_add, add_comm 1 i]

theorem Kf_apply_of_eq (hd : d = (e : Perm g.cycleFactorsFinset) c) :
    (d : Perm α) (Kf a e ⟨c, i⟩) = Kf a e ⟨c, i + 1⟩ := by
  -- Kf e ⟨c, i⟩ = (g ^ i) (a (e c)) appartient au cycle de e c
  rw [hd, ← cycleOf_Kf_apply_eq, cycleOf_apply_self, Kf_apply]

theorem Kf_apply_of_ne (hd' : d ≠ (e : Perm g.cycleFactorsFinset) c) :
    (d : Perm α) (Kf a e ⟨c, i⟩) = Kf a e ⟨c, i⟩ := by
  suffices hdc : (d : Perm α).Disjoint ((e : Perm g.cycleFactorsFinset) c : Perm α) by
    apply Or.resolve_right (disjoint_iff_eq_or_eq.mp hdc (Kf a e ⟨c, i⟩))
    rw [← cycleOf_Kf_apply_eq, cycleOf_apply_self, ← cycleOf_eq_one_iff, cycleOf_Kf_apply_eq]
    exact IsCycle.ne_one (mem_cycleFactorsFinset_iff.mp ((e : Perm g.cycleFactorsFinset) c).prop).1
  apply g.cycleFactorsFinset_pairwise_disjoint d.prop ((e : Perm g.cycleFactorsFinset) c).prop
  rw [Function.Injective.ne_iff Subtype.coe_injective]
  exact hd'

theorem Kf_factorsThrough :
    (Kf a e').FactorsThrough (Kf a e) := by
  rintro ⟨c, i⟩ ⟨d, j⟩ He
  suffices hcd : c = d by
    simp only [Kf_def, hcd] at He ⊢
    rw [g.zpow_eq_zpow_on_iff,
      ← cycle_is_cycleOf (a.mem_support_self _) (Finset.coe_mem _),
      mem_range_toPerm'_iff.mp e.prop] at He
    · rw [g.zpow_eq_zpow_on_iff]
      rw [ ← cycle_is_cycleOf (a.mem_support_self _) (Finset.coe_mem _)]
      · simp only [mem_range_toPerm'_iff.mp e'.prop]
        exact He
      · rw [← Perm.mem_support, ← cycleOf_mem_cycleFactorsFinset_iff,
        ← cycle_is_cycleOf (a.mem_support_self _) (Finset.coe_mem _)]
        apply Finset.coe_mem
    · rw [← Perm.mem_support, ← cycleOf_mem_cycleFactorsFinset_iff,
        ← cycle_is_cycleOf  (a.mem_support_self _) (Finset.coe_mem _)]
      apply Finset.coe_mem
  -- c = d
  apply_fun g.cycleOf at He
  simpa only [cycleOf_Kf_apply_eq, Subtype.coe_inj, EmbeddingLike.apply_eq_iff_eq] using He

variable (σ τ : range_toPerm' g) (c d : g.cycleFactorsFinset) (i j : ℤ)

/-- Given a basis `a` of `g` and a permutation `τ` of `g.cycleFactorsFinset`,
  `Equiv.Perm.Basis.k a τ` is a permutation that acts by conjugation
  as `τ` on `g.cycleFactorsFinset`

`Equiv.Perm.Basis.ofPerm'  will turn it into a permutation and
`Equiv.Perm.Basis.ofPerm_rightInverse` proves that it acts as requested -/
noncomputable def k : α → α :=
  Function.extend (Kf a (1 : range_toPerm' g)) (Kf a τ) id

theorem k_apply_Kf_one :
    k a τ (Kf a (1 : range_toPerm' g) ⟨c, i⟩) = Kf a τ ⟨c, i⟩ :=
  (Kf_factorsThrough a).extend_apply id ⟨c, i⟩

theorem k_apply_basis :
    k a τ (a c) = a ((τ : Perm g.cycleFactorsFinset) c) :=
  k_apply_Kf_one a τ c 0

theorem k_apply_of_not_mem_support {x : α} (hx : x ∉ g.support) :
    k a τ x = x := by
  rw [k, Function.extend_apply']
  · simp only [id_eq]
  · intro hyp
    obtain ⟨⟨c, i⟩, rfl⟩ := hyp
    apply hx
    simp only [Kf_def, zpow_apply_mem_support, coe_one, id_eq]
    apply mem_cycleFactorsFinset_support_le c.prop
    exact mem_support_self a c

theorem mem_support_iff_mem_support_of_mem_cycleFactorsFinset {x : α} :
    x ∈ g.support ↔
    ∃ c ∈ g.cycleFactorsFinset, x ∈ c.support := by
  constructor
  · intro h
    use g.cycleOf x, cycleOf_mem_cycleFactorsFinset_iff.mpr h
    rw [mem_support_cycleOf_iff]
    refine ⟨SameCycle.refl g x, h⟩
  · rintro ⟨c, hc, hx⟩
    exact mem_cycleFactorsFinset_support_le hc hx

/- theorem mem_support_iff_exists_Kf (x : α) :
    x ∈ g.support ↔
    ∃ c, ∃ (hc : c ∈ g.cycleFactorsFinset), ∃ i, g.cycleOf x = c ∧ x = Kf a 1 ⟨⟨c,hc⟩, i⟩ := by
  rw [mem_support_iff_mem_support_of_mem_cycleFactorsFinset]
  apply exists_congr
  intro c
  constructor
  · rintro ⟨hc, hx⟩
    use hc
    have hxc : c = g.cycleOf x := cycle_is_cycleOf hx hc
    have ha : a ⟨c, hc⟩ ∈ (g.cycleOf x).support := hxc ▸ (a.mem_support_self _)
    simp only [Subtype.coe_mk, mem_support_cycleOf_iff] at ha
    obtain ⟨i, hi⟩ := ha.1.symm
    use i, hxc.symm, hi.symm
  · rintro ⟨hc, i, hxc, _⟩
    refine ⟨hc, ?_⟩
    rw [← eq_cycleOf_of_mem_cycleFactorsFinset_iff g c hc x]
    exact hxc.symm -/

theorem mem_support_iff_exists_Kf (x : α) :
    x ∈ g.support ↔
    ∃ c : g.cycleFactorsFinset, ∃ i, g.cycleOf x = c ∧ x = Kf a 1 ⟨c, i⟩ := by
  rw [mem_support_iff_mem_support_of_mem_cycleFactorsFinset]
  constructor
  · rintro ⟨c, hc, h⟩
    use ⟨c, hc⟩
    have hxc : c = g.cycleOf x := cycle_is_cycleOf h hc
    have ha : a ⟨c, hc⟩ ∈ (g.cycleOf x).support := hxc ▸ (a.mem_support_self _)
    simp only [Subtype.coe_mk, mem_support_cycleOf_iff] at ha
    obtain ⟨i, hi⟩ := ha.1.symm
    use i, hxc.symm, hi.symm
  · intro h
    obtain ⟨c, i, hxc, hx⟩ := h
    use c, c.prop
    rwa [eq_comm, eq_cycleOf_of_mem_cycleFactorsFinset_iff _ _ c.prop] at hxc

theorem k_commute_zpow_apply (x : α) :
    k a τ ((g ^ j) x) = (g ^ j) (k a τ x) := by
  by_cases hx : x ∈ g.support
  · rw [mem_support_iff_exists_Kf a] at hx
    obtain ⟨c, hc, i, hxc, rfl⟩ := hx
    rw [← Kf_add']
    erw [k_apply_Kf_one, k_apply_Kf_one] --  a _ c (j + i)]
    rw [Kf_add']
  · rw [k_apply_of_not_mem_support a τ hx, k_apply_of_not_mem_support a]
    rw [Equiv.Perm.zpow_apply_mem_support]
    exact hx

theorem k_commute_zpow :
    k a τ ∘ (g ^ j : Perm α) = (g ^ j : Perm α) ∘ k a τ := by
  ext x
  simp only [Function.comp_apply, k_commute_zpow_apply a τ]

theorem k_commute :
    k a τ ∘ g = g ∘ k a τ := by
  simpa only [zpow_one] using k_commute_zpow a τ 1

theorem k_apply_Kf :
    k a τ (Kf a σ ⟨c, i⟩) = Kf a (τ * σ) ⟨c, i⟩ := by
  simp only [Kf_def]
  rw [← Function.comp_apply (f := k a τ), k_commute_zpow a τ]
  simp only [k_apply_basis, Submonoid.coe_mul, coe_toSubmonoid, coe_mul, Function.comp_apply]

theorem k_mul : k a σ ∘ k a τ = k a (σ * τ) := by
  ext x
  simp only [Function.comp_apply]
  by_cases hx : x ∈ g.support
  · simp only [mem_support_iff_exists_Kf a] at hx
    obtain ⟨_, _, _, _, rfl⟩ := hx
    simp only [k_apply_Kf_one, k_apply_Kf, mul_one]
  · simp only [k_apply_of_not_mem_support a _ hx]

theorem k_one : k a (1 : range_toPerm' g)= id := by
  ext x
  by_cases hx : x ∈ g.support
  · simp only [mem_support_iff_exists_Kf a] at hx
    obtain ⟨_, _, _, _, rfl⟩ := hx
    rw [k_apply_Kf_one, id_eq]
  · simp only [id_eq, k_apply_of_not_mem_support a _ hx]

theorem k_bij : Function.Bijective (k a τ) := by
  simp only [Fintype.bijective_iff_surjective_and_card, and_true,
    Function.surjective_iff_hasRightInverse]
  use k a τ⁻¹
  rw [Function.rightInverse_iff_comp, k_mul a, mul_inv_self, k_one]

theorem k_cycle_apply (x : α) :
    k a τ ((c : Perm α) x) = ((τ : Perm g.cycleFactorsFinset) c : Perm α) (k a τ x) := by
  by_cases hx : x ∈ g.support
  · simp only [mem_support_iff_exists_Kf a] at hx
    obtain ⟨d, _, _, rfl⟩ := hx
    by_cases hcd : c = d
    · rw [hcd, a.Kf_apply_of_eq, k_apply_Kf_one, k_apply_Kf_one, ← a.Kf_apply_of_eq rfl]
      simp only [OneMemClass.coe_one, coe_one, id_eq]
    · rw [a.Kf_apply_of_ne hcd, k_apply_Kf_one, a.Kf_apply_of_ne]
      exact (Equiv.injective _).ne_iff.mpr hcd
  · suffices ∀ (c : g.cycleFactorsFinset), (c : Perm α) x = x by
      simp only [this, k_apply_of_not_mem_support a _ hx]
    · intro c
      rw [← not_mem_support]
      exact Finset.not_mem_mono (mem_cycleFactorsFinset_support_le c.prop) hx

/-- Given `a : g.Basis` and a permutation of g.cycleFactorsFinset that
  preserve the lengths of the cycles, the permutation of `α` that
  moves the `Basis` and commutes with `g`
  -/
noncomputable def ofPerm' : Perm α :=
  ofBijective (k a τ) (k_bij a τ)

theorem ofPerm'_mem_centralizer :
    ofPerm' a τ ∈ Subgroup.centralizer {g} := by
  rw [mem_centralizer_singleton_iff, ← DFunLike.coe_fn_eq]
  simp only [coe_mul, ofPerm']
  exact k_commute a τ

/-- Given `a : Equiv.Perm.Basis g`,
  we define a right inverse of `Equiv.Perm.OnCycleFactors.toPerm`, on `range_toPerm g` -/
noncomputable
def ofPerm :
    range_toPerm' g →* Subgroup.centralizer {g}  where
  toFun τ := ⟨ofPerm' a τ, ofPerm'_mem_centralizer a τ⟩
  map_one' := by
    simp only [Submonoid.mk_eq_one]
    ext x
    simp only [ofPerm', k_one, ofBijective_apply, id_eq, coe_one]
  map_mul' σ τ := by
    simp only [ofPerm', Submonoid.mk_mul_mk, Subtype.mk.injEq]
    ext x
    simp only [← k_mul a, ofBijective_apply, Function.comp_apply, coe_mul]

theorem ofPerm_apply (x) :
    (ofPerm a τ : Perm α) x = k a τ x :=
  rfl

theorem ofPerm_support_le :
    (ofPerm a τ : Perm α).support ≤ g.support := by
  intro x
  simp only [Perm.mem_support, ne_eq, not_imp_not]
  rw [← Perm.not_mem_support]
  exact k_apply_of_not_mem_support a _

theorem ofPerm_equivariant :
    (ofPerm a τ) • c = (τ : Perm g.cycleFactorsFinset) c := by
  rw [centralizer_smul_def, ← Subtype.coe_inj]
  simp only [InvMemClass.coe_inv, mul_inv_eq_iff_eq_mul]
  ext x
  exact k_cycle_apply a τ c x

theorem ofPerm_rightInverse :
    (OnCycleFactors.toPermHom g) ((ofPerm a) τ) = (τ : Perm g.cycleFactorsFinset) := by
  apply ext
  intro c
  rw [OnCycleFactors.toPerm_apply, ofPerm_equivariant]

theorem mem_ofPerm_support_iff (x : α) :
    x ∈ (ofPerm a τ : Perm α).support ↔
      ∃ c : g.cycleFactorsFinset,
        g.cycleOf x = c ∧ c ∈ (τ : Perm g.cycleFactorsFinset).support := by
  by_cases hx : x ∈ g.support
  · obtain ⟨c, i, hc, hci⟩ := (Equiv.Perm.Basis.mem_support_iff_exists_Kf a x).mp hx
    rw [show x ∈ (ofPerm a τ : Perm α).support ↔
      ∃ c : g.cycleFactorsFinset, g.cycleOf x = c ∧ x ∈ (ofPerm a τ : Perm α).support
        from ⟨fun h ↦ ⟨c, hc, h⟩, fun ⟨_, _, h⟩ ↦ h⟩]
    apply exists_congr
    simp only [and_congr_right_iff]
    intro d hd
    have hc' : c = d := Subtype.coe_injective (by simp only [← hc, hd])
    rw [← hc']
    simp only [Equiv.Perm.mem_support, ne_eq, not_iff_not]
    rw [ofPerm_apply]
    simp only [hci, k_apply_Kf_one, Kf_def, k_commute_zpow_apply]
    simp only [OneMemClass.coe_one, coe_one, id_eq, EmbeddingLike.apply_eq_iff_eq, k_apply_basis]
    exact a.injective.eq_iff
  · have := Equiv.Perm.Basis.ofPerm_support_le a τ
    have : x ∉ (ofPerm a τ : Perm α).support := by
      intro hx'; apply hx
      exact Equiv.Perm.Basis.ofPerm_support_le a τ hx'
    simp only [this, mem_support, ne_eq, Subtype.exists, exists_and_left, exists_eq_left',
      false_iff, not_exists, Decidable.not_not]
    intro hc
    simp only [Equiv.Perm.cycleOf_mem_cycleFactorsFinset_iff] at hc
    contradiction

theorem ofPerm_support :
    (ofPerm a τ : Perm α).support = Finset.biUnion (τ : Perm g.cycleFactorsFinset).support
        (fun c ↦ (c : Perm α).support) := by
  ext x
  simp only [mem_ofPerm_support_iff a τ, Finset.mem_biUnion, Subtype.exists]
  apply exists_congr; intro c
  apply exists_congr; intro hc
  rw [and_comm, and_congr_right_iff]
  intro _
  constructor
  · intro h
    simpa only [cycleOf_apply_self, ne_eq, ← h,
      cycleOf_mem_cycleFactorsFinset_iff, mem_support] using hc
  · exact fun h ↦ (cycle_is_cycleOf h hc).symm

theorem card_ofPerm_support :
    (ofPerm a τ : Perm α).support.card =  (τ : Perm g.cycleFactorsFinset).support.sum
        (fun c ↦ (c : Perm α).support.card) := by
  rw [ofPerm_support, Finset.card_biUnion]
  intro c _ d _ h
  apply Equiv.Perm.Disjoint.disjoint_support
  have := g.cycleFactorsFinset_pairwise_disjoint.eq c.prop d.prop
  rw [not_imp_comm] at this
  apply this
  exact Subtype.coe_ne_coe.mpr h

end Basis

namespace OnCycleFactors

open Basis BigOperators Nat Equiv.Perm Equiv Subgroup

theorem mem_range_toPerm_iff {τ} : τ ∈ (toPermHom g).range ↔
    ∀ c, (τ c : Perm α).support.card = (c : Perm α).support.card := by
  constructor
  · rintro ⟨k, rfl⟩ c
    rw [coe_toPerm, Equiv.Perm.support_conj]
    apply Finset.card_map
  · obtain ⟨a⟩ := Basis.nonempty g
    exact fun hτ ↦ ⟨(ofPerm a) ⟨τ, hτ⟩, ofPerm_rightInverse a ⟨τ, hτ⟩⟩

theorem mem_range_toPerm_iff' {τ} : τ ∈ (toPermHom g).range ↔
    (fun (c : g.cycleFactorsFinset) ↦ (c : Perm α).support.card) ∘ τ =
      fun (c : g.cycleFactorsFinset) ↦ (c : Perm α).support.card := by
  rw [mem_range_toPerm_iff, Function.funext_iff]
  simp only [Finset.coe_sort_coe, Subtype.forall, Function.comp_apply]

theorem range_toPerm_eq_range_toPerm' : (toPermHom g).range = range_toPerm' g := by
  ext τ
  rw [mem_range_toPerm_iff, mem_range_toPerm'_iff]

theorem nat_card_range_toPermHom :
    Nat.card (toPermHom g).range =
      ∏ n in g.cycleType.toFinset, (g.cycleType.count n)! := by
  classical
  let sc (c : g.cycleFactorsFinset) : ℕ := (c : Perm α).support.card
  suffices Fintype.card (toPermHom g).range =
    Fintype.card { k : Perm g.cycleFactorsFinset | sc ∘ k = sc } by
    simp only [Nat.card_eq_fintype_card, this, Set.coe_setOf,
      DomMulAct.stabilizer_card', ← CycleType.count_def]
    apply Finset.prod_congr _ (fun _ _ => rfl)
    ext n
    simp only [Finset.univ_eq_attach, Finset.mem_image, Finset.mem_attach,
        sc, true_and, Subtype.exists, exists_prop, Multiset.mem_toFinset]
    simp only [cycleType_def, Function.comp_apply, Multiset.mem_map, Finset.mem_val]
  simp only [← SetLike.coe_sort_coe, Fintype.card_eq_nat_card]
  congr
  ext τ
  erw [mem_range_toPerm_iff'] -- rw doesn't work
  simp only [Finset.coe_sort_coe, Set.mem_setOf_eq]

section Kernel
/- Here, we describe the kernel of `g.OnCycleFactors.toPermHom` -/

open BigOperators Nat OnCycleFactors Subgroup

variable {k : Perm (Function.fixedPoints g)}
  {v : (c : g.cycleFactorsFinset) → Subgroup.zpowers (c : Perm α)}
  {x : α}

/- (ofSubtype k) * (by
variable (k) (v) in
  apply Finset.univ.noncommProd (fun c ↦ (v c : Perm α))
  rintro a _ b _ h
  obtain ⟨m, hm⟩ := (v a).prop
  obtain ⟨n, hn⟩ := (v b).prop
  rw [← hm, ← hn]
  apply Commute.zpow_zpow
  apply g.cycleFactorsFinset_mem_commute a.prop b.prop
  rw [ne_eq, Subtype.coe_inj, ← ne_eq]
  exact h) -/

variable (k) (v) (x) in
/-- An auxiliary function to define the parametrization
of the kernel of `g.OnCycleFactors.toPerm` -/
def θAux : α :=
  if hx : g.cycleOf x ∈ g.cycleFactorsFinset
  then (v ⟨g.cycleOf x, hx⟩ : Perm α) x
  else ofSubtype k x

lemma θAux_apply_of_mem_fixedPoints (hx : x ∈ Function.fixedPoints g) :
    θAux k v x = ofSubtype k x := by
  rw [θAux, dif_neg]
  rw [cycleOf_mem_cycleFactorsFinset_iff, not_mem_support, hx]

lemma θAux_apply_of_mem_fixedPoints_mem (hx : x ∈ Function.fixedPoints g) :
    θAux k v x ∈ Function.fixedPoints g := by
  rw [θAux_apply_of_mem_fixedPoints hx, ofSubtype_apply_of_mem k hx]
  exact (k _).prop

lemma cycleOf_θAux_apply_eq :
    g.cycleOf (θAux k v x) = g.cycleOf x := by
  unfold θAux
  split_ifs with hx
  · let c : g.cycleFactorsFinset := ⟨g.cycleOf x, hx⟩
    change g.cycleOf ((v c : Perm α) x) = g.cycleOf x
    obtain ⟨m, hm⟩ := (v c).prop
    rw [← hm, cycleOf_zpow_apply_self, cycleOf_self_apply_zpow]
  · rw [cycleOf_mem_cycleFactorsFinset_iff, not_mem_support] at hx
    rw [g.cycleOf_eq_one_iff.mpr hx, cycleOf_eq_one_iff, ofSubtype_apply_of_mem k hx]
    exact Subtype.coe_prop (k ⟨x, hx⟩)

lemma θAux_apply_of_cycleOf_eq (c : g.cycleFactorsFinset) (hx : g.cycleOf x = ↑c) :
    θAux k v x = (v c : Equiv.Perm α) x := by
  suffices c = ⟨g.cycleOf x, by simp only [hx, c.prop]⟩ by
    rw [this, θAux, dif_pos]
  simp only [← Subtype.coe_inj, hx]

variable (x) in
lemma θAux_one : θAux (g := g) 1 1 x = x := by
  unfold θAux
  split_ifs
  · simp only [Pi.one_apply, OneMemClass.coe_one, coe_one, id_eq]
  · simp only [map_one, coe_one, id_eq]

lemma θAux_mul
    (k' : Perm (Function.fixedPoints g))
    (v' : (c : g.cycleFactorsFinset) → Subgroup.zpowers (c : Equiv.Perm α))
    (x : α) :
    (θAux k' v') (θAux k v x) =
      θAux (k' * k) (v' * v : (c : g.cycleFactorsFinset) → Subgroup.zpowers (c : Perm α)) x := by
  by_cases hx : g.cycleOf x ∈ g.cycleFactorsFinset
  · rw [θAux_apply_of_cycleOf_eq ⟨g.cycleOf x, hx⟩
      (by rw [cycleOf_θAux_apply_eq]),
      -- (θAux_apply_of_cycleOf_eq_mem ⟨_, hx⟩ rfl),
      θAux_apply_of_cycleOf_eq ⟨g.cycleOf x, hx⟩ rfl,
      θAux_apply_of_cycleOf_eq ⟨g.cycleOf x, hx⟩ rfl]
    simp only [ne_eq, Pi.mul_apply, Submonoid.coe_mul,
      Subgroup.coe_toSubmonoid, coe_mul, Function.comp_apply]
  · nth_rewrite 1 [θAux, dif_neg]
    simp only [θAux, dif_neg hx]
    · simp only [map_mul, coe_mul, Function.comp_apply]
    · simp only [cycleOf_θAux_apply_eq, hx, not_false_eq_true]

variable (k) (v) in
lemma θAux_inv :
    Function.LeftInverse (θAux k⁻¹ v⁻¹) (θAux k v) := fun x ↦ by
  simp only [θAux_mul, mul_left_inv, θAux_one]

variable (k v) in
/-- Given a permutation `g`, a permutation of its fixed points
  and a family of elements in the powers of the cycles of `g`,
  construct their product -/
def θFun : Equiv.Perm α := {
  toFun := θAux k v
  invFun := θAux k⁻¹ v⁻¹
  left_inv := θAux_inv k v
  right_inv := θAux_inv k⁻¹ v⁻¹ }

/-- The description of the kernel of `Equiv.Perm.OnCycleFactors.φ g` -/
def θ (g : Perm α) : Perm (Function.fixedPoints g) ×
    ((c : g.cycleFactorsFinset) → Subgroup.zpowers (c : Equiv.Perm α)) →* Equiv.Perm α := {
  toFun     := fun kv ↦ θFun kv.fst kv.snd
  map_one'  := by
    ext x
    simp only [θFun, Prod.fst_one, Prod.snd_one, coe_one, id_eq,
      inv_one, coe_fn_mk, θAux_one]
  map_mul'  := fun kv' kv ↦ by
    ext x
    simp only [θFun, coe_fn_mk, Prod.fst_mul, Prod.snd_mul,
      coe_mul, coe_fn_mk, Function.comp_apply, θAux_mul] }

theorem θ_apply_of_mem_fixedPoints (uv) (x : α) (hx : x ∈ Function.fixedPoints g) :
    θ g uv x = uv.fst ⟨x, hx⟩ := by
  unfold θ θFun
  simp only [coe_fn_mk, MonoidHom.coe_mk, OneHom.coe_mk, coe_fn_mk]
  rw [θAux_apply_of_mem_fixedPoints, Equiv.Perm.ofSubtype_apply_of_mem]
  exact hx

theorem θ_apply_of_cycleOf_eq (uv) (x : α) (c : g.cycleFactorsFinset)  (hx : g.cycleOf x = ↑c) :
    θ g uv x = (uv.snd c : Perm α) x := by
  unfold θ θFun
  simp only [MonoidHom.coe_mk, OneHom.coe_mk, Equiv.coe_fn_mk]
  exact θAux_apply_of_cycleOf_eq c hx

theorem θ_apply_mem_cycle_suport_iff (uv) (x : α) (c : g.cycleFactorsFinset) :
    θ g uv x ∈ (c : Perm α).support ↔ x ∈ (c : Perm α).support := by
  by_cases hx : x ∈ g.support
  · obtain ⟨d, hd, hx⟩ := mem_support_iff_mem_support_of_mem_cycleFactorsFinset.mp hx
    by_cases hcd : c = d
    · simp only [hcd, hx, iff_true]
      rw [θ_apply_of_cycleOf_eq _ x ⟨d, hd⟩]
      apply?
      sorry
    · sorry
  · rw [not_mem_support, ← Function.mem_fixedPoints_iff] at hx
    rw [θ_apply_of_mem_fixedPoints _ _ hx, ← not_iff_not]
    suffices ∀ y (_ : y ∈ Function.fixedPoints g), y ∉ (c : Perm α).support by
      simp only [this x hx, not_false_eq_true, iff_true, this _ (Subtype.coe_prop _)]
    intro y hy
    rw [Function.mem_fixedPoints_iff, ← not_mem_support] at hy
    intro hy'; apply hy
    exact mem_cycleFactorsFinset_support_le c.prop hy'

theorem θ_apply_single (c : g.cycleFactorsFinset) :
    θ g ⟨1, (Pi.mulSingle c ⟨c, Subgroup.mem_zpowers (c : Perm α)⟩)⟩ = c  := by
  ext x
  by_cases hx : x ∈ Function.fixedPoints g
  · simp only [θ_apply_of_mem_fixedPoints _ x hx, coe_one, id_eq]
    apply symm
    rw [← not_mem_support]
    simp only [Function.mem_fixedPoints, Function.IsFixedPt, ← not_mem_support] at hx
    intro hx'
    apply hx
    apply mem_cycleFactorsFinset_support_le c.prop hx'
  suffices hx' : g.cycleOf x ∈ g.cycleFactorsFinset by
    rw [θ_apply_of_cycleOf_eq _ x ⟨g.cycleOf x, hx'⟩ rfl]
    dsimp only
    by_cases hc : c = ⟨cycleOf g x, hx'⟩
    · rw [hc, Pi.mulSingle_eq_same, cycleOf_apply_self]
    · rw [Pi.mulSingle_eq_of_ne' hc]
      simp only [OneMemClass.coe_one, coe_one, id_eq]
      rw [eq_comm, ← not_mem_support]
      intro hxc
      apply hc
      simp only [← Subtype.coe_inj]
      apply cycle_is_cycleOf hxc c.prop
  rw [← cycleOf_ne_one_iff_mem_cycleFactorsFinset]
  simp only [ne_eq, cycleOf_eq_one_iff]
  rw [Function.mem_fixedPoints_iff] at hx
  exact hx

theorem θ_injective (g : Perm α) : Function.Injective (θ g) := by
  rw [← MonoidHom.ker_eq_bot_iff, eq_bot_iff]
  rintro ⟨u, v⟩
  unfold θ; unfold θFun
  simp only [MonoidHom.coe_mk, OneHom.coe_mk, MonoidHom.mem_ker, ext_iff]
  simp only [coe_fn_mk, coe_one, id_eq]
  intro huv
  simp only [Subgroup.mem_bot, Prod.mk_eq_one, MonoidHom.mem_ker]
  constructor
  · ext ⟨x, hx⟩
    simp only [coe_one, id_eq]
    conv_rhs => rw [← huv x]
    rw [θAux_apply_of_mem_fixedPoints, ofSubtype_apply_of_mem]
    exact hx
  · ext c x
    by_cases hx : g.cycleOf x = 1
    · simp only [cycleOf_eq_one_iff, ← not_mem_support] at hx
      simp only [Pi.one_apply, OneMemClass.coe_one, coe_one, id_eq]
      obtain ⟨m, hm⟩ := (v c).prop
      rw [← hm]
      dsimp only
      rw [← not_mem_support]
      intro hx'
      apply hx
      apply support_zpow_le _ _ at hx'
      apply mem_cycleFactorsFinset_support_le c.prop hx'
    · rw [← ne_eq, cycleOf_ne_one_iff_mem_cycleFactorsFinset] at hx
      simp only [Pi.one_apply, OneMemClass.coe_one, coe_one, id_eq]
      by_cases hc : g.cycleOf x = ↑c
      · rw [← θAux_apply_of_cycleOf_eq c hc, huv]
      · obtain ⟨m, hm⟩ := (v c).prop
        rw [← hm]
        dsimp
        rw [← not_mem_support]
        intro hx'
        refine hc (cycle_is_cycleOf ?_ c.prop).symm
        exact support_zpow_le _ _ hx'

theorem mem_θ_range_iff {p : Perm α} : p ∈ (θ g).range ↔
    (∃ (hp : p ∈ Subgroup.centralizer {g}),
      (⟨p, hp⟩ : Subgroup.centralizer {g}) ∈ (toPermHom g).ker) := by
  constructor
  · rintro ⟨⟨u, v⟩, h⟩
    simp only [mem_ker_toPermHom_iff, IsCycle.forall_commute_iff]
    have H : ∀ c ∈ g.cycleFactorsFinset, ∀ x, (x ∈ c.support ↔ p x ∈ c.support) := fun c hc x ↦ by
      simp only [← eq_cycleOf_of_mem_cycleFactorsFinset_iff g c hc]
      rw [← h]
      unfold θ θFun
      simp only [MonoidHom.coe_mk, OneHom.coe_mk, coe_fn_mk, cycleOf_θAux_apply_eq]
    have H' : ∀ c (hc : c ∈ g.cycleFactorsFinset),
      ofSubtype (p.subtypePerm (H c hc)) ∈ zpowers c := fun c hc ↦ by
      suffices ofSubtype (subtypePerm p _) = v ⟨c, hc⟩ by
        rw [this]
        exact (v _).prop
      ext x
      by_cases hx : x ∈ c.support
      · rw [ofSubtype_apply_of_mem, subtypePerm_apply]
        · dsimp only [id_eq, MonoidHom.coe_mk, OneHom.coe_mk, coe_fn_mk, eq_mpr_eq_cast]
          rw [← h, θ_apply_of_cycleOf_eq _ x ⟨c, hc⟩]
          exact (cycle_is_cycleOf hx hc).symm
        · exact hx
      · rw [ofSubtype_apply_of_not_mem]
        · obtain ⟨m, hm⟩ := (v ⟨c, hc⟩).prop
          rw [← hm, eq_comm, ← not_mem_support]
          intro hx'
          apply hx
          exact (support_zpow_le c m) hx'
        · exact hx
    have hp : ∀ c ∈ g.cycleFactorsFinset, p * c = c * p := by
      intro c hc
      ext x
      simp only [id_eq, coe_mul, Function.comp_apply]
      by_cases hx : x ∈ c.support
      · set w := v ⟨c, hc⟩
        have hxc : c = g.cycleOf x := cycle_is_cycleOf hx hc
        rw [show p x = (w : Perm α) x from by
          rw [← h, θ_apply_of_cycleOf_eq (u, v) x ⟨c, hc⟩ hxc.symm]]
        rw [show p (c x) = (w : Perm α) (c x) from by
          rw [← h, θ_apply_of_cycleOf_eq _ (c x) ⟨c, hc⟩]
          simp only [hxc, cycleOf_apply_self, cycleOf_self_apply]]
        simp only [← mul_apply]
        apply DFunLike.congr_fun
        rw [← commute_iff_eq]
        obtain ⟨m, hw⟩ := w.prop
        simp only [← hw]
        exact Commute.zpow_left rfl m
      · rw [not_mem_support.mp hx]
        rw [H c hc x] at hx
        rw [not_mem_support.mp hx]
    have hp' : p ∈ centralizer {g} := by
      simp only [mem_centralizer_singleton_iff, ← commute_iff_eq]
      rw [← g.cycleFactorsFinset_noncommProd]
      apply Finset.noncommProd_commute
      intro c hc
      simp only [id_eq]
      exact hp c hc
    use hp'
    intro c hc
    use H c hc
    exact H' c hc
  · rintro ⟨hp_mem, hp⟩
    simp only [mem_ker_toPermHom_iff, IsCycle.forall_commute_iff] at hp
    rw [MonoidHom.mem_range]
    have hu : ∀ x : α,
      x ∈ Function.fixedPoints g ↔ p x ∈ Function.fixedPoints g :=  by
      intro x
      simp only [Function.fixedPoints, smul_def, Function.IsFixedPt]
      simp only [← not_mem_support]
      simp only [Set.mem_setOf_eq, not_iff_not]
      constructor
      · intro hx
        let hx' := cycleOf_mem_cycleFactorsFinset_iff.mpr hx
        apply mem_cycleFactorsFinset_support_le hx'
        obtain ⟨hp'⟩ := hp (g.cycleOf x) hx'
        rw [← hp' x, Equiv.Perm.mem_support_cycleOf_iff]
        exact ⟨Equiv.Perm.SameCycle.refl _ _, hx⟩
      · intro hzx
        let hzx' := Equiv.Perm.cycleOf_mem_cycleFactorsFinset_iff.mpr hzx
        apply Equiv.Perm.mem_cycleFactorsFinset_support_le hzx'
        obtain ⟨hp'⟩ := hp (g.cycleOf (p x)) hzx'
        rw [hp' x, Equiv.Perm.mem_support_cycleOf_iff]
        exact ⟨Equiv.Perm.SameCycle.refl _ _, hzx⟩
    set u := subtypePerm p hu
    set v : (c : g.cycleFactorsFinset) → (Subgroup.zpowers (c : Perm α)) :=
      fun c => ⟨ofSubtype
          (p.subtypePerm (Classical.choose (hp c.val c.prop))),
            Classical.choose_spec (hp c.val c.prop)⟩
    use ⟨u, v⟩
    ext x
    by_cases hx : g.cycleOf x = 1
    · rw [θ_apply_of_mem_fixedPoints _ x]
      simp only [u, subtypePerm_apply]
      simpa only [cycleOf_eq_one_iff] using hx
    · rw [θ_apply_of_cycleOf_eq _ x ⟨g.cycleOf x,
        (cycleOf_ne_one_iff_mem_cycleFactorsFinset g).mp hx⟩ rfl]
      rw [ofSubtype_apply_of_mem]
      · rfl
      · simp only [Perm.mem_support, cycleOf_apply_self, ne_eq]
        simpa only [cycleOf_eq_one_iff] using hx

lemma θ_range_le_centralizer : (θ g).range ≤ centralizer {g} := by
    intro p hp
    rw [mem_θ_range_iff] at hp
    obtain ⟨hp, _⟩ := hp
    exact hp

lemma θ_range_eq : (θ g).range = (toPermHom g).ker.map (Subgroup.subtype _) := by
  ext p
  simp only [mem_θ_range_iff, mem_map, coeSubtype, Subtype.exists,
    exists_and_right, exists_eq_right]

theorem θ_range_card (g : Equiv.Perm α) :
    Fintype.card (θ g).range =
      (Fintype.card α - g.cycleType.sum)! * g.cycleType.prod := by
  change Fintype.card ((θ g).range : Set (Equiv.Perm α)) = _
  simp only [MonoidHom.coe_range]
  rw [Set.card_range_of_injective (θ_injective g)]
  rw [Fintype.card_prod]
  rw [Fintype.card_perm]
  rw [Fintype.card_pi]
  apply congr_arg₂ (· * ·)
  · -- fixed points
    apply congr_arg
    exact card_fixedPoints g
  · rw [cycleType]
    simp only [Finset.univ_eq_attach, Finset.attach_val, Function.comp_apply]
    rw [Finset.prod_attach (s := g.cycleFactorsFinset)
      (f := fun a ↦ Fintype.card (Subgroup.zpowers (a : Perm α)))]
    rw [Finset.prod]
    apply congr_arg
    apply Multiset.map_congr rfl
    intro x hx
    rw [Fintype.card_zpowers, IsCycle.orderOf]
    simp only [Finset.mem_val, mem_cycleFactorsFinset_iff] at hx
    exact hx.left

lemma θ_apply_fst (k : Perm (Function.fixedPoints g)) :
    θ g ⟨k, 1⟩ = ofSubtype k := by
  ext x
  by_cases hx : g.cycleOf x ∈ g.cycleFactorsFinset
  · rw [θ_apply_of_cycleOf_eq _ x ⟨g.cycleOf x, hx⟩ rfl]
    simp only [Pi.one_apply, OneMemClass.coe_one, coe_one, id_eq]
    rw [ofSubtype_apply_of_not_mem]
    simpa [cycleOf_mem_cycleFactorsFinset_iff, Perm.mem_support] using hx
  · rw [cycleOf_mem_cycleFactorsFinset_iff, Perm.not_mem_support] at hx
    rw [θ_apply_of_mem_fixedPoints _ x hx, Equiv.Perm.ofSubtype_apply_of_mem]

lemma θ_apply_single_zpowers
    (c : g.cycleFactorsFinset) (vc : Subgroup.zpowers (c : Equiv.Perm α)) :
    θ g ⟨1, Pi.mulSingle c vc⟩ = (vc : Equiv.Perm α) := by
  obtain ⟨m, hm⟩ := vc.prop
  simp only at hm
  suffices vc = ⟨(c : Perm α), mem_zpowers _⟩ ^ m by
    rw [this, ← one_zpow m, Pi.mulSingle_zpow, ← Prod.pow_mk, map_zpow,
      θ_apply_single, SubgroupClass.coe_zpow]
  rw [← Subtype.coe_inj, ← hm, SubgroupClass.coe_zpow]

end Kernel

end OnCycleFactors

open Nat
variable (g)

-- Should one parenthesize the product ?
/-- Cardinality of the centralizer in `Equiv.Perm α` of a permutation given `cycleType` -/
theorem centralizer_card :
    Nat.card (Subgroup.centralizer {g}) =
      (Fintype.card α - g.cycleType.sum)! * g.cycleType.prod *
        (∏ n in g.cycleType.toFinset, (g.cycleType.count n)!) := by
  classical
  rw [card_eq_card_quotient_mul_card_subgroup (OnCycleFactors.toPermHom g).ker,
    Nat.card_congr (QuotientGroup.quotientKerEquivRange (toPermHom g)).toEquiv,
    nat_card_range_toPermHom, mul_comm]
  apply congr_arg₂ _ _ rfl
  rw [← θ_range_card, ← Nat.card_eq_fintype_card]
  simp only [← SetLike.coe_sort_coe, Set.Nat.card_coe_set_eq]
  rw [θ_range_eq, coe_map, Set.ncard_image_of_injective _ (subtype_injective _)]

theorem card_isConj_mul_eq (g : Equiv.Perm α) :
    Fintype.card {h : Equiv.Perm α | IsConj g h} *
      (Fintype.card α - g.cycleType.sum)! *
      g.cycleType.prod *
      (∏ n in g.cycleType.toFinset, (g.cycleType.count n)!) =
    (Fintype.card α)! := by
  classical
  simp only [mul_assoc]
  rw [mul_comm]
  simp only [← mul_assoc]
  rw [← centralizer_card g, mul_comm, Subgroup.centralizer_card_eq, Nat.card_eq_fintype_card]
  convert MulAction.card_orbit_mul_card_stabilizer_eq_card_group (ConjAct (Perm α)) g
  · ext h
    simp only [Set.mem_setOf_eq, ConjAct.mem_orbit_conjAct, isConj_comm]
  · rw [ConjAct.card, Fintype.card_perm]

/-- Cardinality of a conjugacy class in `Equiv.Perm α` of a given `cycleType` -/
theorem card_isConj_eq (g : Equiv.Perm α) :
    Fintype.card {h : Equiv.Perm α | IsConj g h} =
      (Fintype.card α)! /
        ((Fintype.card α - g.cycleType.sum)! *
          g.cycleType.prod *
          (∏ n in g.cycleType.toFinset, (g.cycleType.count n)!)) := by
  rw [← card_isConj_mul_eq g, Nat.div_eq_of_eq_mul_left _]
  · simp only [← mul_assoc]
  -- This is the cardinal of the centralizer
  · rw [← centralizer_card g]
    apply Nat.card_pos

variable (α)

theorem card_of_cycleType_eq_zero_iff {m : Multiset ℕ} :
    (Finset.univ.filter fun g : Equiv.Perm α => g.cycleType = m).card = 0
    ↔ ¬ ((m.sum ≤ Fintype.card α ∧ ∀ a ∈ m, 2 ≤ a)) := by
  rw [Finset.card_eq_zero, Finset.filter_eq_empty_iff,
    ← exists_with_cycleType_iff, not_exists]
  aesop

theorem card_of_cycleType_mul_eq (m : Multiset ℕ) :
    (Finset.univ.filter fun g : Equiv.Perm α => g.cycleType = m).card *
        ((Fintype.card α - m.sum)! * m.prod *
          (∏ n in m.toFinset, (m.count n)!)) =
      if (m.sum ≤ Fintype.card α ∧ ∀ a ∈ m, 2 ≤ a) then (Fintype.card α)! else 0 := by
  split_ifs with hm
  · -- nonempty case
    obtain ⟨g, hg⟩ := (exists_with_cycleType_iff α).mpr hm
    suffices (Finset.univ.filter fun h : Equiv.Perm α => h.cycleType = m) =
        Finset.univ.filter fun h : Equiv.Perm α => IsConj g h by
      rw [this, ← Fintype.card_coe, ← card_isConj_mul_eq g]
      simp only [Fintype.card_coe, ← Set.toFinset_card, mul_assoc, hg,
        Finset.univ_filter_exists, Set.toFinset_setOf]
    simp_rw [isConj_iff_cycleType_eq, hg]
    apply Finset.filter_congr
    simp [eq_comm]
  · -- empty case
    convert MulZeroClass.zero_mul _
    exact (card_of_cycleType_eq_zero_iff α).mpr hm

/-- Cardinality of the `Finset` of `Equiv.Perm α` of given `cycleType` -/
theorem card_of_cycleType (m : Multiset ℕ) :
    (Finset.univ.filter
      fun g : Perm α => g.cycleType = m).card =
      if m.sum ≤ Fintype.card α ∧ ∀ a ∈ m, 2 ≤ a then
        (Fintype.card α)! /
          ((Fintype.card α - m.sum)! * m.prod * (∏ n in m.toFinset, (m.count n)!))
      else 0 := by
  split_ifs with hm
  · -- nonempty case
    apply symm
    apply Nat.div_eq_of_eq_mul_left
    · apply Nat.mul_pos
      apply Nat.mul_pos
      · apply Nat.factorial_pos
      · apply Multiset.prod_pos
        exact fun a ha ↦ lt_of_lt_of_le (zero_lt_two) (hm.2 a ha)
      · exact Finset.prod_pos (fun _ _ ↦ Nat.factorial_pos _)
    rw [card_of_cycleType_mul_eq, if_pos hm]
  · -- empty case
    exact (card_of_cycleType_eq_zero_iff α).mpr hm

end Equiv.Perm
