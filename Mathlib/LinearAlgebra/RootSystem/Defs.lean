/-
Copyright (c) 2023 Oliver Nash. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Oliver Nash, Deepro Choudhury, Scott Carnahan
-/
import Mathlib.LinearAlgebra.PerfectPairing
import Mathlib.LinearAlgebra.Reflection

/-!
# Root data and root systems

This file contains basic definitions for root systems and root data.  We introduce a generalization
of both concepts, called a root pairing.  A typical example of a root pairing is given by choosing a
quadratic form and taking a union of spheres of various radii.  When integrality conditions are
imposed, the property that the set of roots is closed under reflection forces the radii to be small.

## Main definitions / results:

 * `RootPairing`: Given two perfectly-paired `R`-modules `M` and `N` (over some commutative ring
   `R`) a root pairing with indexing set `ι` is the data of an `ι`-indexed subset of `M`
   ("the roots") and an `ι`-indexed subset of `N` ("the coroots") satisfying the axioms familiar
   from the traditional theory of root systems / data.
 * `RootDatum`: A root datum is a root pairing for which the roots and coroots take values in
   finitely-generated free Abelian groups.
 * `RootSystem`: A root system is a root pairing for which the roots span their ambient module.
 * `RootPairing.IsCrystallographic`: A root pairing is said to be crystallographic if the pairing
   between a root and coroot is always an integer.
 * `RootPairing.IsReduced`: A root pairing is said to be reduced if it never contains the double of
   a root.
 * `RootPairing.ext`: In characteristic zero if there is no torsion, the correspondence between
   roots and coroots is unique.
 * `RootSystem.ext`: In characteristic zero if there is no torsion, a root system is determined
   entirely by its roots.
 * `RootSystem.mk'`: In characteristic zero if there is no torsion, to check that a family of
   roots form a root system, we do not need to check that the coroots are stable under reflections
   since this follows from the corresponding property for the roots.

## Implementation details

A root datum is sometimes defined as two subsets: roots and coroots, together with a bijection
between them, subject to hypotheses. However the hypotheses ensure that the bijection is unique and
so the question arises of whether this bijection should be part of the data of a root datum or
whether one should merely assert its existence. For root systems, things are even more extreme: the
coroots are uniquely determined by the roots. Furthermore a root system induces a canonical
non-degenerate bilinear form on the ambient space and many informal accounts even include this form
as part of the data.

We have opted for a design in which some of the uniquely-determined data is included: the bijection
between roots and coroots is (implicitly) included and the coroots are included for root systems.
Empirically this seems to be by far the most convenient design and by providing extensionality
lemmas expressing the uniqueness we expect to get the best of both worlds.

A final point is that we require roots and coroots to be injections from a base indexing type `ι`
rather than subsets of their codomains. This design was chosen to avoid the bijection between roots
and coroots being a dependently-typed object. A third option would be to have the roots and coroots
be subsets but to avoid having a dependently-typed bijection by defining it globally with junk value
`0` outside of the roots and coroots. This would work but lacks the convenient symmetry that the
chosen design enjoys: by introducing the indexing type `ι`, one does not have to pick a direction
(`roots → coroots` or `coroots → roots`) for the forward direction of the bijection. Besides,
providing the user with the additional definitional power to specify an indexing type `ι` is a
benefit and the junk-value pattern is a cost.

## ToDo

If we want to cover existing cases of root systems in the literature, we need to allow infinite root
systems.  A motivating example is the fake monster Lie algebra, whose
Dynkin diagram is the Leech lattice (vertices are lattice vectors, single and double edges
correspond to vertex pairs of distance 4 and 6, respectively).  This means `PerfectPairing` needs to
be replaced with a weaker condition.
-/

open Set Function
open Module hiding reflection
open Submodule (span)
open AddSubgroup (zmultiples)

noncomputable section

variable (ι R M N : Type*)
  [CommRing R] [AddCommGroup M] [Module R M] [AddCommGroup N] [Module R N]

/-- Given two perfectly-paired `R`-modules `M` and `N`, a root pairing with indexing set `ι`
is the data of an `ι`-indexed subset of `M` ("the roots") and an `ι`-indexed subset of `N`
("the coroots") satisfying the axioms familiar from the traditional theory of root systems / data.

It exists to allow for a convenient unification of the theories of root systems and root data. -/
structure RootPairing extends PerfectPairing R M N :=
  root : ι ↪ M
  coroot : ι ↪ N
  root_coroot_two : ∀ i, toLin (root i) (coroot i) = 2
  mapsTo_preReflection_root :
    ∀ i, MapsTo (preReflection (root i) (toLin.flip (coroot i))) (range root) (range root)
  mapsTo_preReflection_coroot :
    ∀ i, MapsTo (preReflection (coroot i) (toLin (root i))) (range coroot) (range coroot)

attribute [nolint docBlame] RootPairing.root
attribute [nolint docBlame] RootPairing.coroot

/-- A root datum is a root pairing with coefficients in the integers and for which the root and
coroot spaces are finitely-generated free Abelian groups.

Note that the latter assumptions `[Free ℤ X₁] [Finite ℤ X₁] [Free ℤ X₂] [Finite ℤ X₂]` should be
supplied as mixins. -/
abbrev RootDatum (X₁ X₂ : Type*) [AddCommGroup X₁] [AddCommGroup X₂] := RootPairing ι ℤ X₁ X₂

/-- A root system is a root pairing for which the roots span their ambient module.

Note that this is slightly more general than the usual definition in the sense that `N` is not
required to be the dual of `M`. -/
structure RootSystem extends RootPairing ι R M N :=
  span_eq_top : span R (range root) = ⊤

namespace RootPairing

variable {ι R M N}
variable (P : RootPairing ι R M N) (i : ι)

/-- A root pairing is said to be crystallographic if the pairing between a root and coroot is
always an integer.-/
def IsCrystallographic : Prop :=
  ∀ i, MapsTo (P.toLin (P.root i)) (range P.coroot) (zmultiples (1 : R))

/-- A root pairing is said to be reduced if it never contains the double of a root. (change this
to say the only constant multiples are ± 1?)-/
def IsReduced : Prop :=
  ∀ i, 2 • P.root i ∉ range P.root

/-- If we interchange the roles of `M` and `N`, we still have a root pairing. -/
protected def flip : RootPairing ι R N M :=
  { P.toPerfectPairing.flip with
    root := P.coroot
    coroot := P.root
    root_coroot_two := P.root_coroot_two
    mapsTo_preReflection_root := P.mapsTo_preReflection_coroot
    mapsTo_preReflection_coroot := P.mapsTo_preReflection_root }

/-- The reflection associated to a root. -/
def reflection : M ≃ₗ[R] M :=
  Module.reflection (P.flip.root_coroot_two i)

/-- The reflection associated to a coroot. -/
def coreflection : N ≃ₗ[R] N :=
  Module.reflection (P.root_coroot_two i)

/-- The Weyl group of a root pairing is the group of automorphisms generated by
the fundamental reflections.-/
def WeylGroup (P : RootPairing ι R M N) : Subgroup (M ≃ₗ[R] M) :=
  Subgroup.closure ({reflection P i | i : ι })


section pairs

variable (i j : ι)

/-- This is the pairing between roots and coroots. -/
def n : R := P.toLin (P.root i) (P.coroot j)

/-- The Coxeter Weight of a pair gives the weight of an edge in a Coxeter diagram, when it is
finite.  It is `4 cos² θ` where `θ` describes the dihedral angle between hyperplanes. -/
def CoxeterWeight : R := n P i j * n P j i

/-- Two roots are orthogonal when they are fixed by each others' reflections. -/
def isOrthogonal : Prop := n P i j = 0 ∧ n P j i = 0

/-- A pair of roots is nonsymmetrizable if exactly one is fixed by the other's reflection.  This is
an obstruction to the existence of a Weyl-invariant form. -/
def isNonSymmetrizable : Prop := CoxeterWeight P i j = 0 ∧ ¬ isOrthogonal P i j

/-- Two roots are parallel if their Coxeter weight is exactly 4.  A linearly independent pair of
parallel roots generates an infinite dihedral group of reflections on their span, and their span
has an invariant singular line. -/
def isParallel : Prop := CoxeterWeight P i j = 4

variable [LinearOrderedCommRing R]

/-- An imaginary pair is one whose Coxeter weight is negative.  Any symmetrization yields an
invariant form where one of the roots has negative norm and the other has positive norm. -/
def isImaginary : Prop := CoxeterWeight P i j < 0

/-- A pair of roots is definite if reflection induces a definite invariant form on the span, unique
up to scalars.  This happens precisely when the Coxeter weight is strictly between `0` and `4`. -/
def isDefinite : Prop := 0 < CoxeterWeight P i j ∧ CoxeterWeight P i j < 4

/-- A pair of roots is ultraparallel if its Coxeter weight is strictly greater than 4.
Symmetrization induces a nondegenerate indefinite form on the span, and reflections generate an
infinite dihedral group. -/
def isUltraParallel : Prop := 4 < CoxeterWeight P i j

end pairs
