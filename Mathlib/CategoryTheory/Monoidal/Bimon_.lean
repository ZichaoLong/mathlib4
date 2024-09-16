/-
Copyright (c) 2024 Lean FRO LLC. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kim Morrison
-/
import Mathlib.CategoryTheory.Monoidal.Comon_

/-!
# The category of bimonoids in a braided monoidal category.

We define bimonoids in a braided monoidal category `C`
as comonoid objects in the category of monoid objects in `C`.

We verify that this is equivalent to the monoid objects in the category of comonoid objects.

## TODO
* Construct the category of modules, and show that it is monoidal with a monoidal forgetful functor
  to `C`.
* Some form of Tannaka reconstruction:
  given a monoidal functor `F : C ⥤ D` into a braided category `D`,
  the internal endomorphisms of `F` form a bimonoid in presheaves on `D`,
  in good circumstances this is representable by a bimonoid in `D`, and then
  `C` is monoidally equivalent to the modules over that bimonoid.
-/

noncomputable section

universe v₁ v₂ u₁ u₂ u

open CategoryTheory MonoidalCategory Mon_Class

variable (C : Type u₁) [Category.{v₁} C] [MonoidalCategory.{v₁} C] [BraidedCategory C]

/--
A bimonoid object in a braided category `C` is a comonoid object in the (monoidal)
category of monoid objects in `C`.
-/
def Bimon_ := Comon_ (Mon_ C)

namespace Bimon_

instance : Category (Bimon_ C) := inferInstanceAs (Category (Comon_ (Mon_ C)))

@[ext] lemma ext {X Y : Bimon_ C} {f g : X ⟶ Y} (w : f.hom.hom = g.hom.hom) : f = g :=
  Comon_.Hom.ext (Mon_ClassHom.ext w)

@[simp] theorem id_hom' (M : Bimon_ C) : Comon_.Hom.hom (𝟙 M) = 𝟙 M.X := rfl

@[simp]
theorem comp_hom' {M N K : Bimon_ C} (f : M ⟶ N) (g : N ⟶ K) : (f ≫ g).hom = f.hom ≫ g.hom :=
  rfl

/-- The forgetful functor from bimonoid objects to monoid objects. -/
abbrev toMon_ : Bimon_ C ⥤ Mon_ C := Comon_.forget (Mon_ C)

/-- The forgetful functor from bimonoid objects to the underlying category. -/
def forget : Bimon_ C ⥤ C := toMon_ C ⋙ Mon_.forget C

@[simp]
theorem toMon_forget : toMon_ C ⋙ Mon_.forget C = forget C := rfl

/-- The forgetful functor from bimonoid objects to comonoid objects. -/
@[simps!]
def toComon_ : Bimon_ C ⥤ Comon_ C := (Mon_.forgetMonoidal C).toOplaxMonoidalFunctor.mapComon

@[simp]
theorem toComon_forget : toComon_ C ⋙ Comon_.forget C = forget C := rfl

@[simps]
instance (M : Bimon_ C) : Mon_Class ((toComon_ C).obj M) where
  one := { hom := η[M.X.X] }
  mul :=
  { hom := μ[M.X.X],
    hom_comul := by dsimp; simp [tensor_μ] }

-- TODO: the `set_option` is not strictly necessary, but the declaration is just a heartbeat
-- away from using too many heartbeats.  Squeezing `(d)simp` improves the situation, but pulls
-- out too many lemmas
set_option maxHeartbeats 400000 in
/-- The object level part of the forward direction of `Comon_ (Mon_ C) ≌ Mon_ (Comon_ C)` -/
def toMon_Comon_obj (M : Bimon_ C) : Mon_ (Comon_ C) where
  X := (toComon_ C).obj M

attribute [simps!] toMon_Comon_obj -- We add this after the fact to avoid a timeout.

/-- The forward direction of `Comon_ (Mon_ C) ≌ Mon_ (Comon_ C)` -/
@[simps]
def toMon_Comon_ : Bimon_ C ⥤ Mon_ (Comon_ C) where
  obj := toMon_Comon_obj C
  map f := {
    hom := (toComon_ C).map f
    one_hom := Comon_.ext (Mon_ClassHom.one_hom f.hom)
    mul_hom := Comon_.ext (Mon_ClassHom.mul_hom f.hom) }
  -- { hom := (toComon_ C).map f }

@[simp]
theorem ClassComon_ObjToComon__one_hom  (M :  Mon_ (Comon_ C)) :
  η[((Comon_.forgetMonoidal C).mapMon.obj M).X] = 𝟙 _ ≫ η[M.X].hom := rfl

@[simp]
theorem fff  (M :  Mon_ (Comon_ C)) :
  μ[((Comon_.forgetMonoidal C).mapMon.obj M).X] = 𝟙 _ ≫ μ[M.X].hom := rfl


/-- The object level part of the backward direction of `Comon_ (Mon_ C) ≌ Mon_ (Comon_ C)` -/
@[simps]
def ofMon_Comon_obj (M : Mon_ (Comon_ C)) : Bimon_ C where
  X := (Comon_.forgetMonoidal C).toLaxMonoidalFunctor.mapMon.obj M
  counit := { hom := M.X.counit }
  comul :=
  { hom := M.X.comul,
    mul_hom := by dsimp; simp [tensor_μ] }

/-- The backward direction of `Comon_ (Mon_ C) ≌ Mon_ (Comon_ C)` -/
@[simps]
def ofMon_Comon_ : Mon_ (Comon_ C) ⥤ Bimon_ C where
  obj := ofMon_Comon_obj C
  map f :=
  { hom := (Comon_.forgetMonoidal C).toLaxMonoidalFunctor.mapMon.map f }

@[simp]
theorem toMonComon_ofMon_Comon_one (M : Bimon_ C) :
    η[((toMon_Comon_ C ⋙ ofMon_Comon_ C).obj M).X.X] = 𝟙 (𝟙_ C) ≫ η[M.X.X] :=
  rfl

@[simp]
theorem toMonComon_ofMon_Comon_mul (M : Bimon_ C) :
    μ[((toMon_Comon_ C ⋙ ofMon_Comon_ C).obj M).X.X] = 𝟙 (M.X.X ⊗ M.X.X) ≫ μ[M.X.X] :=
  rfl

/-- The equivalence `Comon_ (Mon_ C) ≌ Mon_ (Comon_ C)` -/
def equivMon_Comon_ : Bimon_ C ≌ Mon_ (Comon_ C) where
  functor := toMon_Comon_ C
  inverse := ofMon_Comon_ C
  unitIso := NatIso.ofComponents
    (fun _ => Comon_.mkIso (Mon_.mkIso' (Mon_ClassIso.mk (Iso.refl _))))
  counitIso := NatIso.ofComponents
    (fun _ => Mon_.mkIso' (Mon_ClassIso.mk (Comon_.mkIso (Iso.refl _))))

/-! # The trivial bimonoid -/

/-- The trivial bimonoid object. -/
@[simps!]
def trivial : Bimon_ C := Comon_.trivial (Mon_ C)

/-- The bimonoid morphism from the trivial bimonoid to any bimonoid. -/
@[simps]
def trivial_to (A : Bimon_ C) : trivial C ⟶ A :=
  { hom := (default : Mon_.trivial C ⟶ A.X), }

/-- The bimonoid morphism from any bimonoid to the trivial bimonoid. -/
@[simps!]
def to_trivial (A : Bimon_ C) : A ⟶ trivial C :=
  (default : @Quiver.Hom (Comon_ (Mon_ C)) _ A (Comon_.trivial (Mon_ C)))

/-! # Additional lemmas -/

variable {C}

@[reassoc]
theorem one_comul (M : Bimon_ C) :
    η[M.X.X] ≫ M.comul.hom = (λ_ _).inv ≫ (η[M.X.X] ⊗ η[M.X.X]) := by
  simp

@[reassoc]
theorem mul_counit (M : Bimon_ C) :
    μ[M.X.X] ≫ M.counit.hom = (M.counit.hom ⊗ M.counit.hom) ≫ (λ_ _).hom := by
  simp

/-- Compatibility of the monoid and comonoid structures, in terms of morphisms in `C`. -/
@[reassoc (attr := simp)] theorem compatibility (M : Bimon_ C) :
    (M.comul.hom ⊗ M.comul.hom) ≫
      (α_ _ _ (M.X.X ⊗ M.X.X)).hom ≫ M.X.X ◁ (α_ _ _ _).inv ≫
      M.X.X ◁ (β_ M.X.X M.X.X).hom ▷ M.X.X ≫
      M.X.X ◁ (α_ _ _ _).hom ≫ (α_ _ _ _).inv ≫
      (μ[M.X.X] ⊗ μ[M.X.X]) =
    μ[M.X.X] ≫ M.comul.hom := by
  have := (Mon_ClassHom.mul_hom M.comul).symm
  simpa [-Mon_ClassHom.mul_hom, tensor_μ] using this

@[reassoc (attr := simp)] theorem comul_counit_hom (M : Bimon_ C) :
    M.comul.hom ≫ (_ ◁ M.counit.hom) = (ρ_ _).inv := by
  simpa [- Comon_.comul_counit] using congr_arg Mon_ClassHom.hom M.comul_counit

@[reassoc (attr := simp)] theorem counit_comul_hom (M : Bimon_ C) :
    M.comul.hom ≫ (M.counit.hom ▷ _) = (λ_ _).inv := by
  simpa [- Comon_.counit_comul] using congr_arg Mon_ClassHom.hom M.counit_comul

@[reassoc (attr := simp)] theorem comul_assoc_hom (M : Bimon_ C) :
    M.comul.hom ≫ (M.X.X ◁ M.comul.hom) =
      M.comul.hom ≫ (M.comul.hom ▷ M.X.X) ≫ (α_ M.X.X M.X.X M.X.X).hom := by
  simpa [- Comon_.comul_assoc] using congr_arg Mon_ClassHom.hom M.comul_assoc

@[reassoc] theorem comul_assoc_flip_hom (M : Bimon_ C) :
    M.comul.hom ≫ (M.comul.hom ▷ M.X.X) =
      M.comul.hom ≫ (M.X.X ◁ M.comul.hom) ≫ (α_ M.X.X M.X.X M.X.X).inv := by
  simp

@[reassoc] theorem hom_comul_hom {M N : Bimon_ C} (f : M ⟶ N) :
    f.hom.hom ≫ N.comul.hom = M.comul.hom ≫ (f.hom.hom ⊗ f.hom.hom) := by
  simpa [- Comon_.Hom.hom_comul] using congr_arg Mon_ClassHom.hom f.hom_comul

@[reassoc] theorem hom_counit_hom {M N : Bimon_ C} (f : M ⟶ N) :
    f.hom.hom ≫ N.counit.hom = M.counit.hom := by
  simpa [- Comon_.Hom.hom_counit] using congr_arg Mon_ClassHom.hom f.hom_counit

end Bimon_
