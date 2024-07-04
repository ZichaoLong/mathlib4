/-
Copyright (c) 2018 Scott Morrison. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Andrew Yang, Calle Sönne
-/

import Mathlib.CategoryTheory.Limits.Shapes.Pullback.HasPullback

/-!
# Pasting lemma

This file proves the pasting lemma for pullbacks. That is, given the following diagram:
```
  X₁ - f₁ -> X₂ - f₂ -> X₃
  |          |          |
  i₁         i₂         i₃
  ∨          ∨          ∨
  Y₁ - g₁ -> Y₂ - g₂ -> Y₃
```
if the right square is a pullback, then the left square is a pullback iff the big square is a
pullback.

## Main results
* `pasteHorizMkIsPullback` shows that the big square is a pullback if both the small squares are.
* `leftSquareMkIsPullback` shows that the left square is a pullback if the other two are.
* `pullbackRightPullbackFstIso` shows, using the `pullback` API, that
`W ×[X] (X ×[Z] Y) ≅ W ×[Z] Y`.

-/

noncomputable section

open CategoryTheory

universe w v₁ v₂ v u u₂

namespace CategoryTheory.Limits

variable {C : Type u} [Category.{v} C]

section PasteLemma
section PastePullback

/- Let's consider the following diagram
```
X₁ - f₁ -> X₂ - f₂ -> X₃
|          |          |
i₁         i₂         i₃
∨          ∨          ∨
Y₁ - g₁ -> Y₂ - g₂ -> Y₃
```
where `t₁` denotes the cone corresponding to the left square, and `t₂` denotes the cone
corresponding to the right square.
-/

variable {X₃ Y₁ Y₂ Y₃ : C} {g₁ : Y₁ ⟶ Y₂} {g₂ : Y₂ ⟶ Y₃} {i₃ : X₃ ⟶ Y₃} (t₂ : PullbackCone g₂ i₃)
variable (t₁ : PullbackCone g₁ t₂.fst)

local notation "X₂" => t₂.pt
local notation "i₂" => t₂.fst
local notation "f₂" => t₂.snd
local notation "X₁" => t₁.pt
local notation "i₁" => t₁.fst
local notation "f₁" => t₁.snd

/-- The `PullbackCone` obtained by pasting two `PullbackCone`'s horizontally -/
abbrev PullbackCone.pasteHoriz : PullbackCone (g₁ ≫ g₂) i₃ :=
  PullbackCone.mk i₁ (f₁ ≫ f₂) (by rw [reassoc_of% t₁.condition, Category.assoc, ← t₂.condition])

variable {t₁} {t₂}

/-- Given
```
X₁ - f₁ -> X₂ - f₂ -> X₃
|          |          |
i₁         i₂         i₃
∨          ∨          ∨
Y₁ - g₁ -> Y₂ - g₂ -> Y₃
```
Then the big square is a pullback if both the small squares are.
-/
def pasteHorizIsPullback (H : IsLimit t₂) (H' : IsLimit t₁) : IsLimit (t₂.pasteHoriz t₁) := by
  apply PullbackCone.isLimitAux'
  intro s
  -- obtain both limits
  obtain ⟨l₂, hl₂, hl₂'⟩ := PullbackCone.IsLimit.lift' H (s.fst ≫ g₁) s.snd
    (by rw [← s.condition, Category.assoc])
  obtain ⟨l₁, hl₁, hl₁'⟩ := PullbackCone.IsLimit.lift' H' s.fst l₂ hl₂.symm
  --
  refine ⟨l₁, hl₁, by simp [reassoc_of% hl₁', hl₂'], ?_⟩
  -- Uniqueness
  intro m hm₁ hm₂
  apply PullbackCone.IsLimit.hom_ext H' (by simpa [hl₁] using hm₁)
  apply PullbackCone.IsLimit.hom_ext H
  · dsimp at hm₁
    rw [Category.assoc, ← t₁.condition, reassoc_of% hm₁, hl₁', hl₂]
  · simpa [hl₁', hl₂'] using hm₂

/-- Given
```
X₁ - f₁ -> X₂ - f₂ -> X₃
|          |          |
i₁         i₂         i₃
∨          ∨          ∨
Y₁ - g₁ -> Y₂ - g₂ -> Y₃
```
Then the left square is a pullback if the right square and the big square are.
-/
def leftSquareIsPullback (H : IsLimit t₂) (H' : IsLimit (t₂.pasteHoriz t₁)) : IsLimit t₁ := by
  apply PullbackCone.isLimitAux'
  intro s
  -- Obtain the induced morphism from the universal property of the big square
  obtain ⟨l, hl, hl'⟩ := PullbackCone.IsLimit.lift' H' s.fst (s.snd ≫ f₂)
    (by rw [Category.assoc, ← t₂.condition, reassoc_of% s.condition])
  refine ⟨l, hl, ?_, ?_⟩
  -- Check that ....
  · apply PullbackCone.IsLimit.hom_ext H
    · rw [← s.condition, ← hl, Category.assoc, ← t₁.condition, Category.assoc]
      rfl
    · simpa using hl'
  -- Uniqueness
  · intro m hm₁ hm₂
    apply PullbackCone.IsLimit.hom_ext H' (by simpa [hm₁] using hl.symm)
    dsimp at hl' ⊢
    rw [reassoc_of% hm₂, hl']

end PastePullback

section PastePullbackVert

/- Let's consider the following diagram
```
Y₃ - i₃ -> X₃
|          |
g₂         f₂
∨          ∨
Y₂ - i₂ -> X₂
|          |
g₁         f₁
∨          ∨
Y₁ - i₁ -> X₁
```
Let `t₁` denote the cone corresponding to the bottom square, and `t₂` denote the cone corresponding
to the top square.

-/
variable {X₁ X₂ X₃ Y₁ : C} {f₁ : X₂ ⟶ X₁} {f₂ : X₃ ⟶ X₂} {i₁ : Y₁ ⟶ X₁}
variable (t₁ : PullbackCone i₁ f₁) (t₂ : PullbackCone t₁.snd f₂)

local notation "Y₂" => t₁.pt
local notation "g₁" => t₁.fst
local notation "i₂" => t₁.snd
local notation "Y₃" => t₂.pt
local notation "g₂" => t₂.fst
local notation "i₃" => t₂.snd

/-- The `PullbackCone` obtained by pasting two `PullbackCone`'s vertically -/
abbrev PullbackCone.pasteVert : PullbackCone i₁ (f₂ ≫ f₁) :=
  PullbackCone.mk (g₂ ≫ g₁) i₃ (by rw [← reassoc_of% t₂.condition, ← t₁.condition, Category.assoc])

def PullbackCone.pasteVertFlip : (t₁.pasteVert t₂).flip ≅ (t₁.flip.pasteHoriz t₂.flip) :=
  PullbackCone.ext (Iso.refl _) (by simp) (by simp)

variable {t₁} {t₂}

/-- Given
```
Y₃ - i₃ -> X₃
|          |
g₂         f₂
∨          ∨
Y₂ - i₂ -> X₂
|          |
g₁         f₁
∨          ∨
Y₁ - i₁ -> X₁
```
The big square is a pullback if both the small squares are.
-/
def pasteVertIsPullback (H₁ : IsLimit t₁) (H₂ : IsLimit t₂) : IsLimit (t₁.pasteVert t₂) := by
  apply PullbackCone.isLimitOfFlip <| IsLimit.ofIsoLimit _ (t₁.pasteVertFlip t₂).symm
  exact pasteHorizIsPullback (PullbackCone.flipIsLimit H₁) (PullbackCone.flipIsLimit H₂)

def topSquareIsPullback (H₁ : IsLimit t₁) (H₂ : IsLimit (t₁.pasteVert t₂)) : IsLimit t₂ :=
  PullbackCone.isLimitOfFlip
    (leftSquareIsPullback (PullbackCone.flipIsLimit H₁) (PullbackCone.flipIsLimit H₂))

end PastePullbackVert

section PastePushout

/- Consider the following diagram
```
X₁ - f₁ -> X₂ - f₂ -> X₃
|          |          |
i₁         i₂         i₃
∨          ∨          ∨
Y₁ - g₁ -> Y₂ - g₂ -> Y₃
```

-/

variable {X₁ X₂ X₃ Y₁ : C} {f₁ : X₁ ⟶ X₂} {f₂ : X₂ ⟶ X₃} {i₁ : X₁ ⟶ Y₁}
variable (t₁ : PushoutCocone i₁ f₁) (t₂ : PushoutCocone t₁.inr f₂)

local notation "Y₂" => t₁.pt
local notation "g₁" => t₁.inl
local notation "i₂" => t₁.inr
local notation "Y₃" => t₂.pt
local notation "g₂" => t₂.inl
local notation "i₃" => t₂.inr

abbrev PushoutCocone.pasteHoriz : PushoutCocone i₁ (f₁ ≫ f₂) :=
  PushoutCocone.mk (g₁ ≫ g₂) i₃ (by rw [reassoc_of% t₁.condition, Category.assoc, ← t₂.condition])

variable {t₁} {t₂}

def pasteHorizIsPushout (H : IsColimit t₁) (H' : IsColimit t₂) : IsColimit (t₁.pasteHoriz t₂) := by
  apply PushoutCocone.isColimitAux'
  intro s
  -- obtain both descs
  obtain ⟨l₁, hl₁, hl₁'⟩ := PushoutCocone.IsColimit.desc' H s.inl (f₂ ≫ s.inr)
    (by rw [s.condition, Category.assoc])
  obtain ⟨l₂, hl₂, hl₂'⟩ := PushoutCocone.IsColimit.desc' H' l₁ s.inr hl₁'
  --
  refine ⟨l₂, by simp [hl₂, hl₁], hl₂', ?_⟩
  -- Uniqueness
  intro m hm₁ hm₂
  apply PushoutCocone.IsColimit.hom_ext H' _ (by simpa [hl₂'] using hm₂)
  simp only [PushoutCocone.mk_pt, PushoutCocone.mk_ι_app, Category.assoc] at hm₁ hm₂
  apply PushoutCocone.IsColimit.hom_ext H
  · rw [hm₁, ←hl₁, hl₂]
  · rw [reassoc_of% t₂.condition, reassoc_of% t₂.condition, hm₂, hl₂']

-- TODO: afternew name should have few enough characters
def rightSquareIsPushout (H : IsColimit t₁) (H' : IsColimit (t₁.pasteHoriz t₂)) : IsColimit t₂ := by
  apply PushoutCocone.isColimitAux'
  intro s
  -- Obtain the induced morphism from the universal property of the big square
  obtain ⟨l, hl, hl'⟩ := PushoutCocone.IsColimit.desc' H' (g₁ ≫ s.inl) s.inr
    (by rw [reassoc_of% t₁.condition, s.condition, Category.assoc])
  refine ⟨l, ?_, hl', ?_⟩
  -- Check that ....
  · simp at hl hl'
    apply PushoutCocone.IsColimit.hom_ext H hl
    rw [← Category.assoc, t₂.condition, s.condition, Category.assoc, hl']
  -- Uniqueness (TODO GOLF THIS)
  · intro m hm₁ hm₂
    apply PushoutCocone.IsColimit.hom_ext H'
    simp at hl ⊢
    rw [hl, hm₁]
    simp at hl hl' ⊢
    rw [hm₂, ← hl']

end PastePushout

section PastePushoutVert

/- Let's consider the following diagram
```
Y₃ - i₃ -> X₃
|          |
g₂         f₂
∨          ∨
Y₂ - i₂ -> X₂
|          |
g₁         f₁
∨          ∨
Y₁ - i₁ -> X₁
```
Let `t₁` denote the cone corresponding to the bottom square, and `t₂` denote the cone corresponding
to the top square.

-/
variable {Y₃ Y₂ Y₁ X₃ : C} {g₂ : Y₃ ⟶ Y₂} {g₁ : Y₂ ⟶ Y₁} {i₃ : Y₃ ⟶ X₃}
variable (t₁ : PushoutCocone g₂ i₃) (t₂ : PushoutCocone g₁ t₁.inl)

local notation "X₂" => t₁.pt
local notation "f₂" => t₁.inr
local notation "i₂" => t₁.inl
local notation "X₁" => t₂.pt
local notation "f₁" => t₂.inr
local notation "i₁" => t₂.inl

/-- The `PullbackCone` obtained by pasting two `PullbackCone`'s vertically -/
abbrev PushoutCocone.pasteVert : PushoutCocone (g₂ ≫ g₁) i₃ :=
  PushoutCocone.mk i₁ (f₂ ≫ f₁) (by rw [← reassoc_of% t₁.condition, Category.assoc, t₂.condition])

def PushoutCocone.pasteVertFlip : (t₁.pasteVert t₂).flip ≅ (t₁.flip.pasteHoriz t₂.flip) :=
  PushoutCocone.ext (Iso.refl _) (by simp) (by simp)

variable {t₁} {t₂}

/-- Given
```
Y₃ - i₃ -> X₃
|          |
g₂         f₂
∨          ∨
Y₂ - i₂ -> X₂
|          |
g₁         f₁
∨          ∨
Y₁ - i₁ -> X₁
```
The big square is a pushout if both the small squares are.
-/
def pasteVertIsPushout (H₁ : IsColimit t₁) (H₂ : IsColimit t₂) : IsColimit (t₁.pasteVert t₂) := by
  apply PushoutCocone.isColimitOfFlip <| IsColimit.ofIsoColimit _ (t₁.pasteVertFlip t₂).symm
  exact pasteHorizIsPushout (PushoutCocone.flipIsColimit H₁) (PushoutCocone.flipIsColimit H₂)

/-- Given
```
Y₃ - i₃ -> X₃
|          |
g₂         f₂
∨          ∨
Y₂ - i₂ -> X₂
|          |
g₁         f₁
∨          ∨
Y₁ - i₁ -> X₁
```
The bottom square is a pushout if the top square and the big square are.
-/
def botSquareIsPushout (H₁ : IsColimit t₁) (H₂ : IsColimit (t₁.pasteVert t₂)) : IsColimit t₂ :=
  PushoutCocone.isColimitOfFlip
    (rightSquareIsPushout (PushoutCocone.flipIsColimit H₁) (PushoutCocone.flipIsColimit H₂))

end PastePushoutVert


variable {X₁ X₂ X₃ Y₁ Y₂ Y₃ : C} (f₁ : X₁ ⟶ X₂) (f₂ : X₂ ⟶ X₃) (g₁ : Y₁ ⟶ Y₂) (g₂ : Y₂ ⟶ Y₃)
variable (i₁ : X₁ ⟶ Y₁) (i₂ : X₂ ⟶ Y₂) (i₃ : X₃ ⟶ Y₃)
variable (h₁ : i₁ ≫ g₁ = f₁ ≫ i₂) (h₂ : i₂ ≫ g₂ = f₂ ≫ i₃)


/-- Given
```
X₁ - f₁ -> X₂ - f₂ -> X₃
|          |          |
i₁         i₂         i₃
∨          ∨          ∨
Y₁ - g₁ -> Y₂ - g₂ -> Y₃
```
Then the big square is a pullback if both the small squares are.
-/
def pasteHorizMkIsPullback (H : IsLimit (PullbackCone.mk _ _ h₂))
    (H' : IsLimit (PullbackCone.mk _ _ h₁)) :
    IsLimit (PullbackCone.mk i₁ (f₁ ≫ f₂) (by rw [reassoc_of% h₁, Category.assoc, h₂])) :=
  pasteHorizIsPullback H H'
#align category_theory.limits.big_square_is_pullback CategoryTheory.Limits.pasteHorizMkIsPullback

/-- Given
```
X₁ - f₁ -> X₂ - f₂ -> X₃
|          |          |
i₁         i₂         i₃
∨          ∨          ∨
Y₁ - g₁ -> Y₂ - g₂ -> Y₃
```
Then the big square is a pushout if both the small squares are.
-/
def pasteHorizMkIsPushout (H : IsColimit (PushoutCocone.mk _ _ h₂))
    (H' : IsColimit (PushoutCocone.mk _ _ h₁)) :
    IsColimit
      (PushoutCocone.mk _ _
        (show i₁ ≫ g₁ ≫ g₂ = (f₁ ≫ f₂) ≫ i₃ by
          rw [← Category.assoc, h₁, Category.assoc, h₂, Category.assoc])) :=
  pasteHorizIsPushout H' H
#align category_theory.limits.big_square_is_pushout CategoryTheory.Limits.pasteHorizMkIsPushout

/-- Given
```
X₁ - f₁ -> X₂ - f₂ -> X₃
|          |          |
i₁         i₂         i₃
∨          ∨          ∨
Y₁ - g₁ -> Y₂ - g₂ -> Y₃
```
Then the left square is a pullback if the right square and the big square are.
-/
def leftSquareMkIsPullback (H : IsLimit (PullbackCone.mk _ _ h₂))
    (H' :
      IsLimit
        (PullbackCone.mk _ _
          (show i₁ ≫ g₁ ≫ g₂ = (f₁ ≫ f₂) ≫ i₃ by
            rw [← Category.assoc, h₁, Category.assoc, h₂, Category.assoc]))) :
    IsLimit (PullbackCone.mk _ _ h₁) :=
  leftSquareIsPullback H H'
#align category_theory.limits.left_square_is_pullback CategoryTheory.Limits.leftSquareMkIsPullback

/-- Given

X₁ - f₁ -> X₂ - f₂ -> X₃
|          |          |
i₁         i₂         i₃
∨          ∨          ∨
Y₁ - g₁ -> Y₂ - g₂ -> Y₃

Then the right square is a pushout if the left square and the big square are.
-/
def rightSquareMkIsPushout (H : IsColimit (PushoutCocone.mk _ _ h₁))
    (H' :
      IsColimit
        (PushoutCocone.mk _ _
          (show i₁ ≫ g₁ ≫ g₂ = (f₁ ≫ f₂) ≫ i₃ by
            rw [← Category.assoc, h₁, Category.assoc, h₂, Category.assoc]))) :
    IsColimit (PushoutCocone.mk _ _ h₂) :=
  rightSquareIsPushout H H'
#align category_theory.limits.right_square_is_pushout CategoryTheory.Limits.rightSquareMkIsPushout

end PasteLemma

section
/- Let's consider the following diagram of pullbacks
```
W ×[X] (X ×[Z] Y) --snd--> X ×[Z] Y --snd--> Y
  |                           |              |
 fst                         fst             g
  v                           v              v
  W --------- f' --------->   X  ---- f ---> Y
```
In this section we show that `W ×[X] (X ×[Z] Y) ≅ W ×[Z] Y`.
-/

variable {W X Y Z : C} (f : X ⟶ Z) (g : Y ⟶ Z) (f' : W ⟶ X)
variable [HasPullback f g] [HasPullback f' (pullback.fst : pullback f g ⟶ _)]

-- TODO: can this be an instance? Or needs to be a them?
instance hasPullbackHorizPaste : HasPullback (f' ≫ f) g :=
  HasLimit.mk {
    cone := (pullback.cone f g).pasteHoriz (pullback.cone f' pullback.fst)
    isLimit := pasteHorizIsPullback (pullback.isLimit f g) (pullback.isLimit f' pullback.fst)
  }

/-- The canonical isomorphism `W ×[X] (X ×[Z] Y) ≅ W ×[Z] Y` -/
noncomputable def pullbackRightPullbackFstIso :
    pullback f' (pullback.fst : pullback f g ⟶ _) ≅ pullback (f' ≫ f) g :=
  -- TODO: iso of cone iso! isoLimitCone API?
  IsLimit.conePointUniqueUpToIso
    (pasteHorizIsPullback (pullback.isLimit f g) (pullback.isLimit f' pullback.fst))
    (pullback.isLimit (f' ≫ f) g)
#align category_theory.limits.pullback_right_pullback_fst_iso CategoryTheory.Limits.pullbackRightPullbackFstIso

@[reassoc (attr := simp)]
theorem pullbackRightPullbackFstIso_hom_fst :
    (pullbackRightPullbackFstIso f g f').hom ≫ pullback.fst = pullback.fst :=
  IsLimit.conePointUniqueUpToIso_hom_comp _ _ WalkingCospan.left
#align category_theory.limits.pullback_right_pullback_fst_iso_hom_fst CategoryTheory.Limits.pullbackRightPullbackFstIso_hom_fst

@[reassoc (attr := simp)]
theorem pullbackRightPullbackFstIso_hom_snd :
    (pullbackRightPullbackFstIso f g f').hom ≫ pullback.snd = pullback.snd ≫ pullback.snd :=
  IsLimit.conePointUniqueUpToIso_hom_comp _ _ WalkingCospan.right
#align category_theory.limits.pullback_right_pullback_fst_iso_hom_snd CategoryTheory.Limits.pullbackRightPullbackFstIso_hom_snd

@[reassoc (attr := simp)]
theorem pullbackRightPullbackFstIso_inv_fst :
    (pullbackRightPullbackFstIso f g f').inv ≫ pullback.fst = pullback.fst :=
  IsLimit.conePointUniqueUpToIso_inv_comp _ _ WalkingCospan.left
#align category_theory.limits.pullback_right_pullback_fst_iso_inv_fst CategoryTheory.Limits.pullbackRightPullbackFstIso_inv_fst

@[reassoc (attr := simp)]
theorem pullbackRightPullbackFstIso_inv_snd_snd :
    (pullbackRightPullbackFstIso f g f').inv ≫ pullback.snd ≫ pullback.snd = pullback.snd :=
  IsLimit.conePointUniqueUpToIso_inv_comp _ _ WalkingCospan.right
#align category_theory.limits.pullback_right_pullback_fst_iso_inv_snd_snd CategoryTheory.Limits.pullbackRightPullbackFstIso_inv_snd_snd

@[reassoc (attr := simp)]
theorem pullbackRightPullbackFstIso_inv_snd_fst :
    (pullbackRightPullbackFstIso f g f').inv ≫ pullback.snd ≫ pullback.fst = pullback.fst ≫ f' := by
  rw [← pullback.condition]
  exact pullbackRightPullbackFstIso_inv_fst_assoc f g f' _
#align category_theory.limits.pullback_right_pullback_fst_iso_inv_snd_fst CategoryTheory.Limits.pullbackRightPullbackFstIso_inv_snd_fst

end

section
/- Let's consider the following diagram of pullbacks
```
(X ×[Z] Y) ×[Y] W --snd--> W
    |                      |
   fst                     g'
    v                      v
 (X ×[Z] Y) --- snd --->   Y
    |                      |
   fst                     g
    v                      v
    X -------- f --------> Z

```
In this section we show that `(X ×[Z] Y) ×[Y] W ≅ X ×[Z] W`.
-/


variable {W X Y Z : C} (f : X ⟶ Z) (g : Y ⟶ Z) (g' : W ⟶ Y)
-- TODO: these two variables should imply the third!
variable [HasPullback f g] [HasPullback (pullback.snd : pullback f g ⟶ _) g']

-- TODO: can this be an instance? Or needs to be a them?
instance : HasPullback f (g' ≫ g) :=
  HasLimit.mk {
    cone := (pullback.cone f g).pasteVert (pullback.cone pullback.snd g')
    isLimit := pasteVertIsPullback (pullback.isLimit f g) (pullback.isLimit pullback.snd g')
  }

/-- The canonical isomorphism `(X ×[Z] Y) ×[Y] W ≅ X ×[Z] W` -/
def pullbackRightPullbackSndIso :
    pullback (pullback.snd : pullback f g ⟶ _) g' ≅ pullback f (g' ≫ g) := by
  -- TODO: term mode doesn't work here?
  apply IsLimit.conePointUniqueUpToIso
      (pasteVertIsPullback (pullback.isLimit f g) (pullback.isLimit pullback.snd g'))
      (pullback.isLimit f (g' ≫ g))

@[reassoc (attr := simp)]
theorem pullbackRightPullbackSndIso_hom_fst :
    (pullbackRightPullbackSndIso f g g').hom ≫ pullback.fst = pullback.fst ≫ pullback.fst :=
  IsLimit.conePointUniqueUpToIso_hom_comp _ _ WalkingCospan.left

@[reassoc (attr := simp)]
theorem pullbackRightPullbackSndIso_hom_snd :
    (pullbackRightPullbackSndIso f g g').hom ≫ pullback.snd = pullback.snd :=
  IsLimit.conePointUniqueUpToIso_hom_comp _ _ WalkingCospan.right

@[reassoc (attr := simp)]
theorem pullbackRightPullbackSndIso_inv_fst :
    (pullbackRightPullbackSndIso f g g').inv ≫ pullback.fst ≫ pullback.fst = pullback.fst :=
  IsLimit.conePointUniqueUpToIso_inv_comp _ _ WalkingCospan.left

@[reassoc (attr := simp)]
theorem pullbackRightPullbackSndIso_inv_snd_snd :
    (pullbackRightPullbackSndIso f g g').inv ≫ pullback.snd = pullback.snd :=
  IsLimit.conePointUniqueUpToIso_inv_comp _ _ WalkingCospan.right

@[reassoc (attr := simp)]
theorem pullbackRightPullbackSndIso_inv_fst_snd :
    (pullbackRightPullbackSndIso f g g').inv ≫ pullback.fst ≫ pullback.snd = pullback.snd ≫ g' := by
  rw [pullback.condition]
  exact pullbackRightPullbackSndIso_inv_snd_snd_assoc f g g' g'

end

section
/- Let's consider the following diagram of pushouts
```
X ---- g ----> Z ----- g' -----> W
|              |                 |
f             inr               inr
v              v                 v
Y - inl -> Y ⨿[X] Z --inl--> (Y ⨿[X] Z) ⨿[Z] W
```
In this section we show that `(Y ⨿[X] Z) ⨿[Z] W ≅ Y ⨿[X] W`.
-/

variable {W X Y Z : C} (f : X ⟶ Y) (g : X ⟶ Z) (g' : Z ⟶ W)
variable [HasPushout f g] [HasPushout (pushout.inr : _ ⟶ pushout f g) g']

instance : HasPushout f (g ≫ g') :=
  HasColimit.mk {
    cocone := (pushout.cocone f g).pasteHoriz (pushout.cocone pushout.inr g')
    isColimit := pasteHorizIsPushout (pushout.isColimit f g) (pushout.isColimit pushout.inr g')
  }

/-- The canonical isomorphism `(Y ⨿[X] Z) ⨿[Z] W ≅ Y ⨿[X] W` -/
noncomputable def pushoutLeftPushoutInrIso :
    pushout (pushout.inr : _ ⟶ pushout f g) g' ≅ pushout f (g ≫ g') :=
  IsColimit.coconePointUniqueUpToIso
    (pasteHorizIsPushout (pushout.isColimit f g) (pushout.isColimit pushout.inr g'))
    (pushout.isColimit f (g ≫ g'))
#align category_theory.limits.pushout_left_pushout_inr_iso CategoryTheory.Limits.pushoutLeftPushoutInrIso

@[reassoc (attr := simp)]
theorem inl_pushoutLeftPushoutInrIso_inv :
    pushout.inl ≫ (pushoutLeftPushoutInrIso f g g').inv = pushout.inl ≫ pushout.inl :=
  IsColimit.comp_coconePointUniqueUpToIso_inv _ _ WalkingSpan.left
#align category_theory.limits.inl_pushout_left_pushout_inr_iso_inv CategoryTheory.Limits.inl_pushoutLeftPushoutInrIso_inv

@[reassoc (attr := simp)]
theorem inr_pushoutLeftPushoutInrIso_hom :
    pushout.inr ≫ (pushoutLeftPushoutInrIso f g g').hom = pushout.inr :=
  IsColimit.comp_coconePointUniqueUpToIso_hom (pasteHorizIsPushout _ _) _ WalkingSpan.right
#align category_theory.limits.inr_pushout_left_pushout_inr_iso_hom CategoryTheory.Limits.inr_pushoutLeftPushoutInrIso_hom

@[reassoc (attr := simp)]
theorem inr_pushoutLeftPushoutInrIso_inv :
    pushout.inr ≫ (pushoutLeftPushoutInrIso f g g').inv = pushout.inr :=
  IsColimit.comp_coconePointUniqueUpToIso_inv _ _ WalkingSpan.right
#align category_theory.limits.inr_pushout_left_pushout_inr_iso_inv CategoryTheory.Limits.inr_pushoutLeftPushoutInrIso_inv

@[reassoc (attr := simp)]
theorem inl_inl_pushoutLeftPushoutInrIso_hom :
    pushout.inl ≫ pushout.inl ≫ (pushoutLeftPushoutInrIso f g g').hom = pushout.inl := by
  rw [← Category.assoc]
  apply IsColimit.comp_coconePointUniqueUpToIso_hom (pasteHorizIsPushout _ _) _ WalkingSpan.left
#align category_theory.limits.inl_inl_pushout_left_pushout_inr_iso_hom CategoryTheory.Limits.inl_inl_pushoutLeftPushoutInrIso_hom

@[reassoc (attr := simp)]
theorem inr_inl_pushoutLeftPushoutInrIso_hom :
    pushout.inr ≫ pushout.inl ≫ (pushoutLeftPushoutInrIso f g g').hom = g' ≫ pushout.inr := by
  rw [← Category.assoc, ← Iso.eq_comp_inv, Category.assoc, inr_pushoutLeftPushoutInrIso_inv,
    pushout.condition]
#align category_theory.limits.inr_inl_pushout_left_pushout_inr_iso_hom CategoryTheory.Limits.inr_inl_pushoutLeftPushoutInrIso_hom

end

section

/- Let's consider the diagram of pushouts
```
X ---- g ----> Z
|              |
f             inr
v              v
Y - inl -> Y ⨿[X] Z
|              |
f'            inr
v              v
W - inl -> W ⨿[Y] (Y ⨿[X] Z)
```

In this section we will construct the isomorphism `W ⨿[Y] (Y ⨿[X] Z) ≅ W ⨿[X] Z`.
-/

variable {W X Y Z : C} (f : X ⟶ Y) (g : X ⟶ Z) (f' : Y ⟶ W)
variable [HasPushout f g] [HasPushout f' (pushout.inl : _ ⟶ pushout f g)]

instance : HasPushout (f ≫ f') g :=
  HasColimit.mk {
    cocone := (pushout.cocone f g).pasteVert (pushout.cocone f' pushout.inl)
    isColimit := pasteVertIsPushout (pushout.isColimit f g) (pushout.isColimit f' pushout.inl)
  }

/-- The canonical isomorphism `W ⨿[Y] (Y ⨿[X] Z) ≅ W ⨿[X] Z` -/
noncomputable def pushoutRightPushoutInlIso :
    pushout f' (pushout.inl : _ ⟶ pushout f g) ≅ pushout (f ≫ f') g :=
  IsColimit.coconePointUniqueUpToIso
    (pasteVertIsPushout (pushout.isColimit f g) (pushout.isColimit f' pushout.inl))
    (pushout.isColimit (f ≫ f') g)

@[reassoc (attr := simp)]
theorem inl_pushoutRightPushoutInlIso_inv :
    pushout.inl ≫ (pushoutRightPushoutInlIso f g f').inv = pushout.inl :=
  IsColimit.comp_coconePointUniqueUpToIso_inv _ _ WalkingSpan.left

@[reassoc (attr := simp)]
theorem inr_inr_pushoutRightPushoutInlIso_hom :
    pushout.inr ≫ pushout.inr ≫ (pushoutRightPushoutInlIso f g f').hom = pushout.inr := by
  rw [← Category.assoc]
  apply IsColimit.comp_coconePointUniqueUpToIso_hom (pasteVertIsPushout _ _) _ WalkingSpan.right

@[reassoc (attr := simp)]
theorem inr_pushoutRightPushoutInlIso_inv :
    pushout.inr ≫ (pushoutRightPushoutInlIso f g f').inv = pushout.inr ≫ pushout.inr :=
  IsColimit.comp_coconePointUniqueUpToIso_inv _ _ WalkingSpan.right

@[reassoc (attr := simp)]
theorem inl_pushoutRightPushoutInlIso_hom :
    pushout.inl ≫ (pushoutRightPushoutInlIso f g f').hom = pushout.inl :=
  IsColimit.comp_coconePointUniqueUpToIso_hom (pasteVertIsPushout _ _) _ WalkingSpan.left

-- TODO: pushout.condition make variables explicit?

@[reassoc (attr := simp)]
theorem inr_inl_pushoutRightPushoutInlIso_hom :
    pushout.inl ≫ pushout.inr ≫ (pushoutRightPushoutInlIso f g f').hom = f' ≫ pushout.inl := by
  rw [← Category.assoc, ← pushout.condition, Category.assoc, inl_pushoutRightPushoutInlIso_hom]

end

end CategoryTheory.Limits
