/-
Copyright (c) 2019 Simon Hudon. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Simon Hudon, Yury Kudryashov
-/
import Mathlib.Algebra.BigOperators.Group.List
import Mathlib.Algebra.Group.Action.Defs
import Mathlib.Algebra.Group.Units.Basic

/-!
# Free monoid over a given alphabet

## Main definitions

* `FreeMonoid α`: free monoid over alphabet `α`; defined as a synonym for `List α`
  with multiplication given by `(++)`.
* `FreeMonoid.of`: embedding `α → FreeMonoid α` sending each element `x` to `[x]`;
* `FreeMonoid.lift`: natural equivalence between `α → M` and `FreeMonoid α →* M`
* `FreeMonoid.map`: embedding of `α → β` into `FreeMonoid α →* FreeMonoid β` given by `List.map`.
-/


variable {α : Type*} {β : Type*} {γ : Type*} {M : Type*} [Monoid M] {N : Type*} [Monoid N]

/-- Free monoid over a given alphabet. -/
@[to_additive "Free nonabelian additive monoid over a given alphabet"]
def FreeMonoid (α) := List α

namespace FreeMonoid

/-- The identity equivalence between `FreeMonoid α` and `List α`. -/
@[to_additive "The identity equivalence between `FreeAddMonoid α` and `List α`."]
def toList : FreeMonoid α ≃ List α := Equiv.refl _

/-- The identity equivalence between `List α` and `FreeMonoid α`. -/
@[to_additive "The identity equivalence between `List α` and `FreeAddMonoid α`."]
def ofList : List α ≃ FreeMonoid α := Equiv.refl _

@[to_additive (attr := simp)]
theorem toList_symm : (@toList α).symm = ofList := rfl

@[to_additive (attr := simp)]
theorem ofList_symm : (@ofList α).symm = toList := rfl

@[to_additive (attr := simp)]
theorem toList_ofList (l : List α) : toList (ofList l) = l := rfl

@[to_additive (attr := simp)]
theorem ofList_toList (xs : FreeMonoid α) : ofList (toList xs) = xs := rfl

@[to_additive (attr := simp)]
theorem toList_comp_ofList : @toList α ∘ ofList = id := rfl

@[to_additive (attr := simp)]
theorem ofList_comp_toList : @ofList α ∘ toList = id := rfl

@[to_additive]
instance : CancelMonoid (FreeMonoid α) where
  one := ofList []
  mul x y := ofList (toList x ++ toList y)
  mul_one := List.append_nil
  one_mul := List.nil_append
  mul_assoc := List.append_assoc
  mul_left_cancel _ _ _ := List.append_cancel_left
  mul_right_cancel _ _ _ := List.append_cancel_right

@[to_additive]
instance : Inhabited (FreeMonoid α) := ⟨1⟩

@[to_additive (attr := simp)]
theorem toList_one : toList (1 : FreeMonoid α) = [] := rfl

@[to_additive (attr := simp)]
theorem ofList_nil : ofList ([] : List α) = 1 := rfl

@[to_additive (attr := simp)]
theorem toList_mul (xs ys : FreeMonoid α) : toList (xs * ys) = toList xs ++ toList ys := rfl

@[to_additive (attr := simp)]
theorem ofList_append (xs ys : List α) : ofList (xs ++ ys) = ofList xs * ofList ys := rfl

@[to_additive (attr := simp)]
theorem toList_prod (xs : List (FreeMonoid α)) : toList xs.prod = (xs.map toList).join := by
  induction xs <;> simp [*, List.join]

@[to_additive (attr := simp)]
theorem ofList_join (xs : List (List α)) : ofList xs.join = (xs.map ofList).prod :=
  toList.injective <| by simp

/-- Embeds an element of `α` into `FreeMonoid α` as a singleton list. -/
@[to_additive "Embeds an element of `α` into `FreeAddMonoid α` as a singleton list."]
def of (x : α) : FreeMonoid α := ofList [x]

@[to_additive (attr := simp)]
theorem toList_of (x : α) : toList (of x) = [x] := rfl

@[to_additive]
theorem ofList_singleton (x : α) : ofList [x] = of x := rfl

@[to_additive (attr := simp)]
theorem ofList_cons (x : α) (xs : List α) : ofList (x :: xs) = of x * ofList xs := rfl

@[to_additive]
theorem toList_of_mul (x : α) (xs : FreeMonoid α) : toList (of x * xs) = x :: toList xs := rfl

@[to_additive]
theorem of_injective : Function.Injective (@of α) := List.singleton_injective

/-- Recursor for `FreeMonoid` using `1` and `FreeMonoid.of x * xs` instead of `[]` and `x :: xs`. -/
@[to_additive (attr := elab_as_elim, induction_eliminator)
  "Recursor for `FreeAddMonoid` using `0` and
  FreeAddMonoid.of x + xs` instead of `[]` and `x :: xs`."]
-- Porting note: change from `List.recOn` to `List.rec` since only the latter is computable
def recOn {C : FreeMonoid α → Sort*} (xs : FreeMonoid α) (h0 : C 1)
    (ih : ∀ x xs, C xs → C (of x * xs)) : C xs := List.rec h0 ih xs

@[to_additive (attr := simp)]
theorem recOn_one {C : FreeMonoid α → Sort*} (h0 : C 1) (ih : ∀ x xs, C xs → C (of x * xs)) :
    @recOn α C 1 h0 ih = h0 := rfl

@[to_additive (attr := simp)]
theorem recOn_of_mul {C : FreeMonoid α → Sort*} (x : α) (xs : FreeMonoid α) (h0 : C 1)
    (ih : ∀ x xs, C xs → C (of x * xs)) : @recOn α C (of x * xs) h0 ih = ih x xs (recOn xs h0 ih) :=
  rfl

/-- A version of `List.cases_on` for `FreeMonoid` using `1` and `FreeMonoid.of x * xs` instead of
`[]` and `x :: xs`. -/
@[to_additive (attr := elab_as_elim, cases_eliminator)
  "A version of `List.casesOn` for `FreeAddMonoid` using `0` and
  `FreeAddMonoid.of x + xs` instead of `[]` and `x :: xs`."]
def casesOn {C : FreeMonoid α → Sort*} (xs : FreeMonoid α) (h0 : C 1)
    (ih : ∀ x xs, C (of x * xs)) : C xs := List.casesOn xs h0 ih

@[to_additive (attr := simp)]
theorem casesOn_one {C : FreeMonoid α → Sort*} (h0 : C 1) (ih : ∀ x xs, C (of x * xs)) :
    @casesOn α C 1 h0 ih = h0 := rfl

@[to_additive (attr := simp)]
theorem casesOn_of_mul {C : FreeMonoid α → Sort*} (x : α) (xs : FreeMonoid α) (h0 : C 1)
    (ih : ∀ x xs, C (of x * xs)) : @casesOn α C (of x * xs) h0 ih = ih x xs := rfl

@[to_additive (attr := ext)]
theorem hom_eq ⦃f g : FreeMonoid α →* M⦄ (h : ∀ x, f (of x) = g (of x)) : f = g :=
  MonoidHom.ext fun l ↦ recOn l (f.map_one.trans g.map_one.symm)
    (fun x xs hxs ↦ by simp only [h, hxs, MonoidHom.map_mul])

/-- A variant of `List.prod` that has `[x].prod = x` true definitionally.
The purpose is to make `FreeMonoid.lift_eval_of` true by `rfl`. -/
@[to_additive "A variant of `List.sum` that has `[x].sum = x` true definitionally.
The purpose is to make `FreeAddMonoid.lift_eval_of` true by `rfl`."]
def prodAux {M} [Monoid M] : List M → M
  | [] => 1
  | (x :: xs) => List.foldl (· * ·) x xs

@[to_additive]
lemma prodAux_eq : ∀ l : List M, FreeMonoid.prodAux l = l.prod
  | [] => rfl
  | (_ :: xs) => by simp [prodAux, List.prod_eq_foldl]

/-- Equivalence between maps `α → M` and monoid homomorphisms `FreeMonoid α →* M`. -/
@[to_additive "Equivalence between maps `α → A` and additive monoid homomorphisms
`FreeAddMonoid α →+ A`."]
def lift : (α → M) ≃ (FreeMonoid α →* M) where
  toFun f :=
  { toFun := fun l ↦ prodAux ((toList l).map f)
    map_one' := rfl
    map_mul' := fun _ _ ↦ by simp only [prodAux_eq, toList_mul, List.map_append, List.prod_append] }
  invFun f x := f (of x)
  left_inv _ := rfl
  right_inv _ := hom_eq fun _ ↦ rfl

@[to_additive (attr := simp)]
theorem lift_ofList (f : α → M) (l : List α) : lift f (ofList l) = (l.map f).prod :=
  prodAux_eq _

@[to_additive (attr := simp)]
theorem lift_symm_apply (f : FreeMonoid α →* M) : lift.symm f = f ∘ of := rfl

@[to_additive]
theorem lift_apply (f : α → M) (l : FreeMonoid α) : lift f l = ((toList l).map f).prod :=
  prodAux_eq _

@[to_additive]
theorem lift_comp_of (f : α → M) : lift f ∘ of = f := rfl

@[to_additive (attr := simp)]
theorem lift_eval_of (f : α → M) (x : α) : lift f (of x) = f x := rfl

@[to_additive (attr := simp)]
theorem lift_restrict (f : FreeMonoid α →* M) : lift (f ∘ of) = f := lift.apply_symm_apply f

@[to_additive]
theorem comp_lift (g : M →* N) (f : α → M) : g.comp (lift f) = lift (g ∘ f) := by
  ext
  simp

@[to_additive]
theorem hom_map_lift (g : M →* N) (f : α → M) (x : FreeMonoid α) : g (lift f x) = lift (g ∘ f) x :=
  DFunLike.ext_iff.1 (comp_lift g f) x

/-- Define a multiplicative action of `FreeMonoid α` on `β`. -/
@[to_additive "Define an additive action of `FreeAddMonoid α` on `β`."]
def mkMulAction (f : α → β → β) : MulAction (FreeMonoid α) β where
  smul l b := l.toList.foldr f b
  one_smul _ := rfl
  mul_smul _ _ _ := List.foldr_append _ _ _ _

@[to_additive]
theorem smul_def (f : α → β → β) (l : FreeMonoid α) (b : β) :
    haveI := mkMulAction f
    l • b = l.toList.foldr f b := rfl

@[to_additive]
theorem ofList_smul (f : α → β → β) (l : List α) (b : β) :
    haveI := mkMulAction f
    ofList l • b = l.foldr f b := rfl

@[to_additive (attr := simp)]
theorem of_smul (f : α → β → β) (x : α) (y : β) :
    (haveI := mkMulAction f
    of x • y) = f x y := rfl

/-- The unique monoid homomorphism `FreeMonoid α →* FreeMonoid β` that sends
each `of x` to `of (f x)`. -/
@[to_additive "The unique additive monoid homomorphism `FreeAddMonoid α →+ FreeAddMonoid β`
that sends each `of x` to `of (f x)`."]
def map (f : α → β) : FreeMonoid α →* FreeMonoid β where
  toFun l := ofList <| l.toList.map f
  map_one' := rfl
  map_mul' _ _ := List.map_append _ _ _

@[to_additive (attr := simp)]
theorem map_of (f : α → β) (x : α) : map f (of x) = of (f x) := rfl

@[to_additive]
theorem toList_map (f : α → β) (xs : FreeMonoid α) : toList (map f xs) = xs.toList.map f := rfl

@[to_additive]
theorem ofList_map (f : α → β) (xs : List α) : ofList (xs.map f) = map f (ofList xs) := rfl

@[to_additive]
theorem lift_of_comp_eq_map (f : α → β) : (lift fun x ↦ of (f x)) = map f := hom_eq fun _ ↦ rfl

@[to_additive]
theorem map_comp (g : β → γ) (f : α → β) : map (g ∘ f) = (map g).comp (map f) := hom_eq fun _ ↦ rfl

@[to_additive (attr := simp)]
theorem map_id : map (@id α) = MonoidHom.id (FreeMonoid α) := hom_eq fun _ ↦ rfl

/-- The only invertible element of the free monoid is 1; this instance enables `units_eq_one`. -/
@[to_additive]
instance uniqueUnits : Unique (FreeMonoid α)ˣ where
  uniq u := Units.ext <| toList.injective <|
    have : toList u.val ++ toList u.inv = [] := DFunLike.congr_arg toList u.val_inv
    (List.append_eq_nil.mp this).1

end FreeMonoid
