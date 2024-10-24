/-
Copyright (c) 2021 Patrick Massot. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Patrick Massot, Anatole Dedecker
-/
import Mathlib.Order.Filter.Bases
import Mathlib.Topology.Algebra.Module.Basic

/-!
# TODO

# Group and ring filter bases

A `GroupFilterBasis` is a `FilterBasis` on a group with some properties relating
the basis to the group structure. The main theorem is that a `GroupFilterBasis`
on a group gives a topology on the group which makes it into a topological group
with neighborhoods of the neutral element generated by the given basis.

## Main definitions and results

Given a group `G` and a ring `R`:

* `GroupFilterBasis G`: the type of filter bases that will become neighborhood of `1`
  for a topology on `G` compatible with the group structure
* `GroupFilterBasis.topology`: the associated topology
* `GroupFilterBasis.isTopologicalGroup`: the compatibility between the above topology
  and the group structure
* `RingFilterBasis R`: the type of filter bases that will become neighborhood of `0`
  for a topology on `R` compatible with the ring structure
* `RingFilterBasis.topology`: the associated topology
* `RingFilterBasis.isTopologicalRing`: the compatibility between the above topology
  and the ring structure

## References

* [N. Bourbaki, *General Topology*][bourbaki1966]
-/


open Filter Set TopologicalSpace Function

open Topology Filter Pointwise

universe u

namespace Filter

/-!
## Filter bases for group topologies
-/

/-- A `GroupFilterBasis` on a group is a `FilterBasis` satisfying some additional axioms.
  Example : if `G` is a topological group then the neighbourhoods of the identity are a
  `GroupFilterBasis`. Conversely given a `GroupFilterBasis` one can define a topology
  compatible with the group structure on `G`. -/
class IsGroupBasis {G : Type*} {ι : Sort*} [Group G] (p : ι → Prop) (s : ι → Set G)
    extends IsBasis p s : Prop where
  one : ∀ {i}, p i → (1 : G) ∈ s i
  mul : ∀ {i}, p i → ∃ j, p j ∧ s j * s j ⊆ s i
  inv : ∀ {i}, p i → ∃ j, p j ∧ s j ⊆ (s i)⁻¹
  conj : ∀ x₀, ∀ {i}, p i → ∃ j, p j ∧ MapsTo (x₀ * · * x₀⁻¹) (s j) (s i)

/-- An `AddGroupFilterBasis` on an additive group is a `FilterBasis` satisfying some additional
  axioms. Example : if `G` is a topological group then the neighbourhoods of the identity are an
  `AddGroupFilterBasis`. Conversely given an `AddGroupFilterBasis` one can define a topology
  compatible with the group structure on `G`. -/
class IsAddGroupBasis {G : Type*} {ι : Sort*} [AddGroup G] (p : ι → Prop) (s : ι → Set G)
    extends IsBasis p s : Prop where
  zero : ∀ {i}, p i → (0 : G) ∈ s i
  add : ∀ {i}, p i → ∃ j, p j ∧ s j + s j ⊆ s i
  neg : ∀ {i}, p i → ∃ j, p j ∧ s j ⊆ -(s i)
  conj : ∀ x₀, ∀ {i}, p i → ∃ j, p j ∧ MapsTo (x₀ + · + -x₀) (s j) (s i)

attribute [to_additive existing] IsGroupBasis IsGroupBasis.conj
  IsGroupBasis.toIsBasis

/-- `GroupFilterBasis` constructor in the commutative group case. -/
@[to_additive "`AddGroupFilterBasis` constructor in the additive commutative group case."]
theorem IsGroupBasis.mk_of_comm {G : Type*} {ι : Sort*} [CommGroup G] (p : ι → Prop) (s : ι → Set G)
    (toIsBasis : IsBasis p s) (one : ∀ {i}, p i → (1 : G) ∈ s i)
    (mul : ∀ {i}, p i → ∃ j, p j ∧ s j * s j ⊆ s i)
    (inv : ∀ {i}, p i → ∃ j, p j ∧ s j ⊆ (s i)⁻¹) :
    IsGroupBasis p s where
  toIsBasis := toIsBasis
  one := one
  mul := mul
  inv := inv
  conj x i hi := ⟨i, hi, by simpa only [mul_inv_cancel_comm, preimage_id'] using mapsTo_id _⟩

@[to_additive]
theorem HasBasis.isGroupBasis {G : Type*} {ι : Sort*} [Group G] [TopologicalSpace G]
    [TopologicalGroup G] {p : ι → Prop} {s : ι → Set G} (h : (𝓝 1).HasBasis p s) :
    IsGroupBasis p s where
  toIsBasis := h.isBasis
  one hi := mem_of_mem_nhds (h.mem_of_mem hi)
  mul := by
    have : Tendsto (fun p : G × G ↦ p.1 * p.2) (𝓝 1 ×ˢ 𝓝 1) (𝓝 1) := by
      simpa only [nhds_prod_eq, one_mul] using (tendsto_mul (M := G) (a := 1) (b := 1))
    simpa [h.prod_self.tendsto_iff h, mul_subset_iff, forall_mem_comm] using this
  inv := by
    have : Tendsto (·⁻¹ : G → G) (𝓝 1) (𝓝 1) := by simpa using tendsto_inv (1 : G)
    rwa [h.tendsto_iff h] at this
  conj x₀ := by
    have : Tendsto (x₀ * · * x₀⁻¹ : G → G) (𝓝 1) (𝓝 1) := by simpa using
      (tendsto_id (x := 𝓝 1) |>.const_mul x₀ |>.mul_const x₀⁻¹)
    rwa [h.tendsto_iff h] at this

namespace IsGroupBasis

variable {G : Type*} {ι : Sort*} [Group G] {p : ι → Prop} {s : ι → Set G} (hB : IsGroupBasis p s)
include hB

/-!
### Proving `TopologicalGroup` from `Filter.IsGroupBasis`
-/

@[to_additive]
lemma topologicalGroup [TopologicalSpace G] [ContinuousConstSMul G G] (hB' : (𝓝 1).HasBasis p s) :
    TopologicalGroup G := by
  refine TopologicalGroup.of_nhds_one ?_ ?_ ?_ ?_
  · refine hB'.prod_self.tendsto_iff hB' |>.mpr fun i hi ↦ (hB.mul hi).imp
      fun j ⟨hj, hji⟩ ↦ ⟨hj, ?_⟩
    simpa [← image2_mul, forall_mem_comm] using hji
  · exact hB'.tendsto_iff hB' |>.mpr fun i hi ↦ (hB.inv hi).imp fun j ↦ id
  · intro x₀
    simp_rw [← smul_eq_mul, ← Homeomorph.smul_apply x₀, (Homeomorph.smul x₀).map_nhds_eq,
      Homeomorph.smul_apply x₀, smul_eq_mul, mul_one]
  · exact fun x₀ ↦ hB'.tendsto_iff hB' |>.mpr fun i hi ↦ (hB.conj x₀ hi).imp fun j ↦ id

/-!
### Constructing a group topology from `Filter.IsGroupBasis`
-/

/-- The neighborhood function of a `GroupFilterBasis`. -/
@[to_additive "The neighborhood function of an `AddGroupFilterBasis`."]
def N : G → Filter G := fun x ↦ x • hB.filter

@[to_additive (attr := simp)]
theorem N_one : hB.N 1 = hB.filter := by
  simp only [N, one_smul]

@[to_additive]
theorem hasBasis_N (x : G) :
    HasBasis (hB.N x) p (fun i ↦ x • (s i)) :=
  hB.hasBasis.map (fun y ↦ x * y)

/-- The topological space structure coming from a group filter basis. -/
@[to_additive "The topological space structure coming from an additive group filter basis."]
def topology : TopologicalSpace G :=
  TopologicalSpace.mkOfNhds hB.N

@[to_additive]
theorem nhds_eq {x₀ : G} : @nhds G hB.topology x₀ = hB.N x₀ := by
  apply TopologicalSpace.nhds_mkOfNhds_of_hasBasis hB.hasBasis_N
  · intro a i hi
    exact ⟨1, hB.one hi, mul_one a⟩
  · intro a i hi
    rcases hB.mul hi with ⟨j, hj, hji⟩
    filter_upwards [hB.hasBasis_N a |>.mem_of_mem hj]
    rintro _ ⟨x, hx, rfl⟩
    calc
      (a * x) • (s j) ∈ hB.N (a * x) := hB.hasBasis_N _ |>.mem_of_mem hj
      _ = a • x • (s j) := smul_smul .. |>.symm
      _ ⊆ a • (s j * s j) := smul_set_mono <| smul_set_subset_smul hx
      _ ⊆ a • (s i) := smul_set_mono hji

@[to_additive]
theorem nhds_one_eq :
    @nhds G hB.topology (1 : G) = hB.filter := by
  rw [hB.nhds_eq, hB.N_one]

@[to_additive]
theorem nhds_hasBasis (x₀ : G) :
    HasBasis (@nhds G hB.topology x₀) p (fun i ↦ x₀ • (s i)) := by
  rw [hB.nhds_eq]
  apply hB.hasBasis_N

@[to_additive]
theorem nhds_one_hasBasis :
    HasBasis (@nhds G hB.topology 1) p s := by
  rw [hB.nhds_one_eq]
  exact hB.hasBasis

@[to_additive]
theorem mem_nhds_one {i} (hi : p i) :
    s i ∈ @nhds G hB.topology 1 :=
  hB.nhds_one_hasBasis.mem_of_mem hi

-- See note [lower instance priority]
/-- If a group is endowed with a topological structure coming from a group filter basis then it's a
topological group. -/
@[to_additive "If a group is endowed with a topological structure coming from a group filter basis
then it's a topological group."]
instance (priority := 100) instContinuousConstSMul :
    @ContinuousConstSMul G G hB.topology _ := by
  letI := hB.topology
  refine ⟨?_⟩
  simp_rw [continuous_iff_continuousAt, ContinuousAt, Tendsto, nhds_eq, N, ← Filter.map_smul,
    smul_eq_mul, map_map, comp_mul_left, le_refl, implies_true]

-- See note [lower instance priority]
/-- If a group is endowed with a topological structure coming from a group filter basis then it's a
topological group. -/
@[to_additive "If a group is endowed with a topological structure coming from a group filter basis
then it's a topological group."]
instance (priority := 100) instTopologicalGroup :
    @TopologicalGroup G hB.topology _ := by
  letI := hB.topology
  exact hB.topologicalGroup hB.nhds_one_hasBasis

end IsGroupBasis

/-!
## Filter bases for ring topologies
-/

/-- A `RingFilterBasis` on a ring is a `FilterBasis` satisfying some additional axioms.
  Example : if `R` is a topological ring then the neighbourhoods of the identity are a
  `RingFilterBasis`. Conversely given a `RingFilterBasis` on a ring `R`, one can define a
  topology on `R` which is compatible with the ring structure. -/
class IsRingBasis {R : Type*} {ι : Sort*} [Ring R] (p : ι → Prop) (s : ι → Set R)
    extends IsAddGroupBasis p s : Prop where
  mul : ∀ {i}, p i → ∃ j, p j ∧ s j * s j ⊆ s i
  mul_left : ∀ (x₀ : R) {i}, p i → ∃ j, p j ∧ MapsTo (x₀ * ·) (s j) (s i)
  mul_right : ∀ (x₀ : R) {i}, p i → ∃ j, p j ∧ MapsTo (· * x₀) (s j) (s i)

theorem IsRingBasis.mk_of_comm {R : Type*} {ι : Sort*} [CommRing R] (p : ι → Prop) (s : ι → Set R)
    (toIsAddGroupBasis : IsAddGroupBasis p s) (mul : ∀ {i}, p i → ∃ j, p j ∧ s j * s j ⊆ s i)
    (mul_left : ∀ (x₀ : R) {i}, p i → ∃ j, p j ∧ MapsTo (x₀ * ·) (s j) (s i)) :
    IsRingBasis p s where
  toIsAddGroupBasis := toIsAddGroupBasis
  mul := mul
  mul_left := mul_left
  mul_right := by simpa only [mul_comm] using mul_left

theorem HasBasis.isRingBasis {R : Type*} {ι : Sort*} [Ring R] [TopologicalSpace R]
    [TopologicalRing R] {p : ι → Prop} {s : ι → Set R} (h : (𝓝 0).HasBasis p s) :
    IsRingBasis p s where
  toIsAddGroupBasis := h.isAddGroupBasis
  mul := by
    have : Tendsto (fun p : R × R ↦ p.1 * p.2) (𝓝 0 ×ˢ 𝓝 0) (𝓝 0) := by
      simpa only [nhds_prod_eq, zero_mul] using (tendsto_mul (M := R) (a := 0) (b := 0))
    simpa [h.prod_self.tendsto_iff h, mul_subset_iff, forall_mem_comm] using this
  mul_left x₀ := by
    have : Tendsto (x₀ * ·) (𝓝 0) (𝓝 0) := by simpa using (tendsto_id (x := 𝓝 0) |>.const_mul x₀)
    rwa [h.tendsto_iff h] at this
  mul_right x₀ := by
    have : Tendsto (· * x₀) (𝓝 0) (𝓝 0) := by simpa using (tendsto_id (x := 𝓝 0) |>.mul_const x₀)
    rwa [h.tendsto_iff h] at this

namespace IsRingBasis

variable {R : Type*} {ι : Sort*} [Ring R] {p : ι → Prop} {s : ι → Set R} (hB : IsRingBasis p s)
include hB

/-!
### Proving `TopologicalRing` from `Filter.IsRingBasis`
-/

lemma topologicalRing [TopologicalSpace R] [ContinuousConstVAdd R R] (hB' : (𝓝 0).HasBasis p s) :
    TopologicalRing R := by
  haveI := hB.topologicalAddGroup hB'
  refine TopologicalRing.of_addGroup_of_nhds_zero ?_ ?_ ?_
  · refine hB'.prod_self.tendsto_iff hB' |>.mpr fun i hi ↦ (hB.mul hi).imp
      fun j ⟨hj, hji⟩ ↦ ⟨hj, ?_⟩
    simpa [← image2_mul, forall_mem_comm] using hji
  · exact fun x₀ ↦ hB'.tendsto_iff hB' |>.mpr fun i hi ↦ (hB.mul_left x₀ hi).imp fun j ↦ id
  · exact fun x₀ ↦ hB'.tendsto_iff hB' |>.mpr fun i hi ↦ (hB.mul_right x₀ hi).imp fun j ↦ id

/-!
### Constructing a ring topology from `Filter.IsRingBasis`
-/

/-- The topology associated to a ring filter basis.
It has the given basis as a basis of neighborhoods of zero. -/
nonrec abbrev topology : TopologicalSpace R := hB.topology

/-- If a ring is endowed with a topological structure coming from
a ring filter basis then it's a topological ring. -/
instance (priority := 100) instTopologicalRing :
    @TopologicalRing R hB.topology _ := by
  letI := hB.topology
  haveI := hB.instContinuousConstVAdd
  exact hB.topologicalRing hB.nhds_zero_hasBasis

end IsRingBasis

/-!
## Filter bases for module topologies
-/

/-- A `ModuleFilterBasis` on a module is a `FilterBasis` satisfying some additional axioms.
  Example : if `M` is a topological module then the neighbourhoods of zero are a
  `ModuleFilterBasis`. Conversely given a `ModuleFilterBasis` one can define a topology
  compatible with the module structure on `M`. -/
structure IsModuleBasis (R : Type*) {M : Type*} {ι : Sort*} [Ring R] [TopologicalSpace R]
    [AddCommGroup M] [Module R M] (p : ι → Prop) (s : ι → Set M)
    extends IsAddGroupBasis p s : Prop where
  smul : ∀ {i}, p i → ∃ V ∈ 𝓝 (0 : R), ∃ j, p j ∧ V • (s j) ⊆ s i
  smul_left : ∀ (x₀ : R) {i}, p i → ∃ j, p j ∧ MapsTo (x₀ • ·) (s j) (s i)
  smul_right : ∀ (m₀ : M) {i}, p i → ∀ᶠ x in 𝓝 (0 : R), x • m₀ ∈ s i

theorem IsModuleBasis.mk_of_hasBasis {R M : Type*} {ιR ιM : Sort*} [Ring R] [TopologicalSpace R]
    [AddCommGroup M] [Module R M] {pR : ιR → Prop} {sR : ιR → Set R} (hR : (𝓝 0).HasBasis pR sR)
    (pM : ιM → Prop) (sM : ιM → Set M) (toIsAddGroupBasis : IsAddGroupBasis pM sM)
    (smul : ∀ {i}, pM i → ∃ j, pR j ∧ ∃ k, pM k ∧ (sR j) • (sM k) ⊆ sM i)
    (smul_left : ∀ (x₀ : R) {i}, pM i → ∃ j, pM j ∧ MapsTo (x₀ • ·) (sM j) (sM i))
    (smul_right : ∀ (m₀ : M) {i}, pM i → ∃ j, pR j ∧ MapsTo (· • m₀) (sR j) (sM i)) :
    IsModuleBasis R pM sM where
  toIsAddGroupBasis := toIsAddGroupBasis
  smul hi := smul hi |>.imp' sR fun _ ↦ And.imp_left <| hR.mem_of_mem
  smul_left := smul_left
  smul_right m₀ _ hi := hR.eventually_iff.mpr <| smul_right m₀ hi

namespace IsModuleBasis

variable {R M : Type*} {ι : Sort*} [Ring R] [TopologicalSpace R]
    [AddCommGroup M] [Module R M] {p : ι → Prop} {s : ι → Set M} (hB : IsModuleBasis R p s)
include hB

/- TODO
/-- If `R` is discrete then the trivial additive group filter basis on any `R`-module is a
module filter basis. -/
instance [DiscreteTopology R] : Inhabited (ModuleFilterBasis R M) :=
  ⟨{
      show AddGroupFilterBasis M from
        default with
      smul' := by
        rintro U (rfl : U ∈ {{(0 : M)}})
        use univ, univ_mem, {0}, rfl
        rintro a ⟨x, -, m, rfl, rfl⟩
        simp only [smul_zero, mem_singleton_iff]
      smul_left' := by
        rintro x₀ U (h : U ∈ {{(0 : M)}})
        rw [mem_singleton_iff] at h
        use {0}, rfl
        simp [h]
      smul_right' := by
        rintro m₀ U (h : U ∈ (0 : Set (Set M)))
        rw [Set.mem_zero] at h
        simp [h, nhds_discrete] }⟩
-/

/-!
### Proving `ContinuousSMul` from `Filter.IsModuleBasis`
-/

theorem continuousSMul [TopologicalRing R] [TopologicalSpace M] [ContinuousConstVAdd M M]
    (hB' : (𝓝 0).HasBasis p s) : ContinuousSMul R M := by
  haveI := hB.topologicalAddGroup hB'
  refine ContinuousSMul.of_nhds_zero ?_ ?_ ?_
  · refine basis_sets _ |>.prod_pprod hB' |>.tendsto_iff hB' |>.mpr fun i hi ↦
      let ⟨V, hV, j, hj, hVj⟩ := (hB.smul hi); ⟨⟨V, j⟩, ⟨hV, hj⟩, ?_⟩
    simpa [forall_swap (α := M), ← image2_smul] using hVj
  · exact fun m₀ ↦ hB'.tendsto_right_iff.mpr fun i hi ↦ hB.smul_right m₀ hi
  · exact fun x₀ ↦ hB'.tendsto_iff hB' |>.mpr fun i hi ↦ (hB.smul_left x₀ hi).imp fun j ↦ id

/-!
### Constructing a module topology from `Filter.IsModuleBasis`
-/

/-- The topology associated to a module filter basis on a module over a topological ring.
It has the given basis as a basis of neighborhoods of zero. -/
nonrec abbrev topology : TopologicalSpace M := hB.topology

/-- The topology associated to a module filter basis on a module over a topological ring.
It has the given basis as a basis of neighborhoods of zero. This version gets the ring
topology by unification instead of type class inference. -/
abbrev topology' {R M : Type*} {ι : Sort*} [CommRing R] {_ : TopologicalSpace R}
    [AddCommGroup M] [Module R M] {p : ι → Prop} {s : ι → Set M} (hB : IsModuleBasis R p s) :
    TopologicalSpace M :=
  hB.topology

/-- If a module is endowed with a topological structure coming from
a module filter basis then it's a topological module. -/
instance (priority := 100) instContinuousSMul [TopologicalRing R] :
    @ContinuousSMul R M _ _ hB.topology := by
  letI := hB.topology
  haveI := hB.instContinuousConstVAdd
  exact hB.continuousSMul hB.nhds_zero_hasBasis

end IsModuleBasis

end Filter
