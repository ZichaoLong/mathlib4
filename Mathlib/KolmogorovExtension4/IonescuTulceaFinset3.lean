import Mathlib.KolmogorovExtension4.meilleure_composition
import Mathlib.KolmogorovExtension4.Projective
import Mathlib.Probability.Kernel.MeasureCompProd
import Mathlib.KolmogorovExtension4.DependsOn
import Mathlib.MeasureTheory.Measure.ProbabilityMeasure
import Mathlib.KolmogorovExtension4.KolmogorovExtension
import Mathlib.Data.PNat.Interval
import Mathlib.MeasureTheory.Function.ConditionalExpectation.Basic
import Mathlib.MeasureTheory.Constructions.Prod.Integral

open MeasureTheory ProbabilityTheory Finset ENNReal Filter Topology Function

variable {X : ℕ → Type*} [Nonempty (X 0)] [∀ n, MeasurableSpace (X n)]
variable (κ : (k : ℕ) → kernel ((i : Iic k) → X i) (X (k + 1)))
variable [∀ k, IsMarkovKernel (κ k)]

abbrev proj : (n : ℕ) → ((n : ℕ) → X n) → (i : Iic n) → X i := fun _ x i ↦ x i

theorem meas_proj (n : ℕ) : Measurable (@proj X n) := measurable_proj _

theorem proj_limit_iff' (μ : (I : Finset ℕ) → Measure ((i : I) → X i))
    (hμ : IsProjectiveMeasureFamily μ) (ν : Measure ((n : ℕ) → X n)) (a : ℕ) :
    IsProjectiveLimit ν μ ↔ ∀ n ≥ a, ν.map (proj n) = μ (Iic n) := by
  constructor
  · rintro h n -
    exact h (Iic n)
  · intro h I
    conv_lhs =>
      enter [1]
      change (fun x i ↦ x ⟨i.1, mem_Iic.2 ((le_sup (f := id) i.2).trans (le_max_left _ _))⟩ :
          ((i : Iic (max (I.sup id) a)) → X i) → (i : I) → X i) ∘
        (fun x i ↦ x i : ((n : ℕ) → X n) → (i : Iic (max (I.sup id) a)) → X i)
    rw [← Measure.map_map, h (max (I.sup id) a) (le_max_right _ _),
      hμ (Iic (max (I.sup id) a)) I]
    · exact fun i hi ↦ mem_Iic.2 ((le_sup (f := id) hi).trans (le_max_left _ _))
    · exact measurable_pi_lambda _ (fun _ ↦ measurable_pi_apply _)
    · exact meas_proj _

theorem proj_limit_iff (μ : (I : Finset ℕ) → Measure ((i : I) → X i))
    (hμ : IsProjectiveMeasureFamily μ) (ν : Measure ((n : ℕ) → X n)) :
    IsProjectiveLimit ν μ ↔ ∀ n, ν.map (proj n) = μ (Iic n) := by
  rw [proj_limit_iff' _ hμ _ 0]
  simp

lemma mem_Iic_zero {i : ℕ} (hi : i ∈ Iic 0) : i = 0 := by simpa using hi

def zer : (X 0) ≃ᵐ ((i : Iic 0) → X i) where
  toFun := fun x₀ i ↦ (mem_Iic_zero i.2).symm ▸ x₀
  invFun := fun x ↦ x ⟨0, mem_Iic.2 <| le_refl 0⟩
  left_inv := fun x₀ ↦ by simp
  right_inv := fun x ↦ by
    ext i
    have : ⟨0, mem_Iic.2 <| le_refl 0⟩ = i := by simp [(mem_Iic_zero i.2).symm]
    cases this; rfl
  measurable_toFun := by
    refine measurable_pi_lambda _ (fun i ↦ ?_)
    simp_rw [eqRec_eq_cast]
    apply measurable_cast
    have : ⟨0, mem_Iic.2 <| le_refl 0⟩ = i := by simp [(mem_Iic_zero i.2).symm]
    cases this; rfl
  measurable_invFun := measurable_pi_apply _

theorem measurable_zer : Measurable (zer (X := X)) := by
  refine measurable_pi_lambda _ (fun i ↦ ?_)
  simp_rw [zer, eqRec_eq_cast]
  apply measurable_cast
  have : ⟨0, mem_Iic.2 <| le_refl 0⟩ = i := by simp [(mem_Iic_zero i.2).symm]
  cases this; rfl

noncomputable def family' (μ : (n : ℕ) → Measure ((i : Iic n) → X i)) :
    (S : Finset ℕ) → Measure ((k : S) → X k) :=
  fun S ↦ (μ (S.sup id)).map
    (fun x (i : S) ↦ x ⟨i.1, mem_Iic.2 (le_sup (f := id) i.2)⟩)

theorem Iic_pi_eq {a b : ℕ} (h : a = b) :
    ((i : Iic a) → X i) = ((i : Iic b) → X i) := by cases h; rfl

theorem measure_cast {a b : ℕ} (h : a = b) (μ : (n : ℕ) → Measure ((i : Iic n) → X i)) :
    (μ a).map (cast (Iic_pi_eq h)) = μ b := by
  subst h
  exact Measure.map_id

lemma omg {s t : Set ℕ} (h : s = t) (h' : ((i : s) → X i) = ((i : t) → X i))
    (x : (i : s) → X i) (i : t) :
    cast h' x i = x ⟨i.1, h.symm ▸ i.2⟩ := by
  subst h
  rfl

theorem family'_Iic (μ : (n : ℕ) → Measure ((i : Iic n) → X i)) (n : ℕ) :
    family' μ (Iic n) = μ n := by
  rw [family', ← measure_cast (sup_Iic n) μ]
  congr with x i
  rw [omg _ (Iic_pi_eq (sup_Iic n)) x i]
  rw [sup_Iic n]

theorem proj_family' (μ : (n : ℕ) → Measure ((i : Iic n) → X i))
    (h : ∀ a b : ℕ, ∀ hab : a ≤ b, (μ b).map
      (fun x (i : Iic a) ↦ x ⟨i.1, Iic_subset_Iic.2 hab i.2⟩) = μ a) :
    IsProjectiveMeasureFamily (family' μ) := by
  intro I J hJI
  have sls : J.sup id ≤ I.sup id := sup_mono hJI
  simp only [family']
  rw [Measure.map_map]
  · conv_rhs =>
      enter [1]
      change (fun x i ↦ x ⟨i.1, mem_Iic.2 (le_sup (f := id) i.2)⟩ :
        ((i : Iic (J.sup id)) → X i) → (i : J) → X i) ∘
        (fun x i ↦ x ⟨i.1, Iic_subset_Iic.2 sls i.2⟩ :
        ((i : Iic (I.sup id)) → X i) → (i : Iic (J.sup id)) → X i)
    rw [← Measure.map_map, h (J.sup id) (I.sup id) sls]
    exact measurable_pi_lambda _ (fun _ ↦ measurable_pi_apply _)
    exact measurable_pi_lambda _ (fun _ ↦ measurable_pi_apply _)
  · exact measurable_pi_lambda _ (fun _ ↦ measurable_pi_apply _)
  · exact measurable_pi_lambda _ (fun _ ↦ measurable_pi_apply _)

theorem proj_family'' {n : ℕ} (x : (i : Iic n) → X i) :
    ∀ a b : ℕ, ∀ (hab : a ≤ b), (composition κ n b x).map
      (fun x (i : Iic a) ↦ x ⟨i.1, Iic_subset_Iic.2 hab i.2⟩)
      = composition κ n a x := by
  intro a b hab
  rw [← compo_proj _ _ hab, kernel.map_apply]

noncomputable def kC {n : ℕ} (x : (i : Iic n) → X i) : AddContent (cylinders X) :=
  kolContent (proj_family' _ (proj_family'' κ x))

theorem HEq_measurableSpace_Iic_pi {a b : ℕ} (h : a = b) :
    HEq (inferInstance : MeasurableSpace ((i : Iic a) → X i))
    (inferInstance : MeasurableSpace ((i : Iic b) → X i)) := by cases h; rfl

theorem kC_cylinder {n k : ℕ} (x : (i : Iic n) → X i) {S : Set ((i : Iic k) → X i)}
    (mS : MeasurableSet S) :
    kC κ x (cylinder _ S) = composition κ n k x S := by
  rw [kC, kolContent_congr _ (by rw [mem_cylinders]; exact ⟨Iic k, S, mS, rfl⟩) rfl mS, family'_Iic]

noncomputable def kerint (a b : ℕ) (f : ((n : ℕ) → X n) → ℝ≥0∞)
    (x : (n : ℕ) → X n) : ℝ≥0∞ :=
  ∫⁻ z : (i : Iic b) → X i, f (updateFinset x _ z) ∂(composition κ a b (fun i ↦ x i))

theorem kerint_lt {a b : ℕ} (hab : a < b) {f : ((n : ℕ) → X n) → ℝ≥0∞} (mf : Measurable f)
    (x : (n : ℕ) → X n) :
    kerint κ a b f x = ∫⁻ y : (i : Ioc a b) → X i,
      f (updateFinset x _ y) ∂kerNat κ a b (fun i ↦ x i) := by
  rw [kerint, composition, dif_pos hab, kernel.lintegral_map, kernel.lintegral_prod,
    kernel.lintegral_deterministic']
  · congrm ∫⁻ _, f (fun i ↦ ?_) ∂_
    simp only [updateFinset, mem_Iic, el, id_eq, MeasurableEquiv.coe_mk, Equiv.coe_fn_mk, mem_Ioc]
    split_ifs <;> try rfl
    · omega
    · omega
    · omega
  · apply Measurable.lintegral_prod_right'
      (f := fun p ↦ f (updateFinset x (Iic b) (el a b hab.le p)))
    exact mf.comp <| measurable_updateFinset.comp (el a b hab.le).measurable
  · exact mf.comp <| measurable_updateFinset.comp (el a b hab.le).measurable
  · exact mf.comp measurable_updateFinset

theorem kerint_le {a b : ℕ} (hba : b ≤ a) {f : ((n : ℕ) → X n) → ℝ≥0∞} (mf : Measurable f) :
    kerint κ a b f = f := by
  ext x
  rw [kerint, composition, dif_neg (not_lt.2 hba), kernel.lintegral_deterministic']
  · congr with i
    by_cases hi : i ∈ Iic b <;> simp [updateFinset, hi]
  · exact mf.comp measurable_updateFinset

theorem kolContent_eq_kerint {N : ℕ} {S : Set ((i : Iic N) → X i)}
    (mS : MeasurableSet S) (x : (n : ℕ) → X n) (n : ℕ) :
    kC κ (proj n x) (cylinder _ S) =
    kerint κ n N ((cylinder _ S).indicator 1) x := by
  rw [kC_cylinder _ _ mS, ← lintegral_indicator_one mS, kerint]
  congr with y
  apply indicator_const_eq
  rw [mem_cylinder]
  congrm ?_ ∈ S
  ext i
  simp [updateFinset, i.2]

theorem kerint_mono (a b : ℕ) {f g : ((n : ℕ) → X n) → ℝ≥0∞} (hfg : f ≤ g)
    (x : (n : ℕ) → X n) : kerint κ a b f x ≤ kerint κ a b g x := lintegral_mono fun _ ↦ hfg _

theorem measurable_kerint (a b : ℕ) {f : ((n : ℕ) → X n) → ℝ≥0∞} (hf : Measurable f) :
    Measurable (kerint κ a b f) := by
  unfold kerint
  let g : ((i : Iic b) → X i) × ((n : ℕ) → X n) → ℝ≥0∞ :=
    fun c ↦ f (updateFinset c.2 _ c.1)
  let η : kernel ((n : ℕ) → X n) ((i : Iic b) → X i) :=
    kernel.comap (composition κ a b) (fun x i ↦ x i) (measurable_proj _)
  change Measurable fun x ↦ ∫⁻ z : (i : Iic b) → X i, g (z, x) ∂η x
  refine Measurable.lintegral_kernel_prod_left' <| hf.comp ?_
  simp only [updateFinset, measurable_pi_iff]
  intro i
  by_cases h : i ∈ Iic b <;> simp [h]
  · exact (measurable_pi_apply _).comp <| measurable_fst
  · exact measurable_snd.eval

theorem dependsOn_kerint' {a b : ℕ} (c : ℕ) {f : ((n : ℕ) → X n) → ℝ≥0∞} (mf : Measurable f)
    (hf : DependsOn f (Iic a)) (hab : a ≤ b) : kerint κ b c f = f := by
  rcases le_or_lt c b with hcb | hbc
  · exact kerint_le κ hcb mf
  · ext x
    have := isMarkovKernel_kerNat κ hbc
    rw [kerint_lt κ hbc mf, ← mul_one (f x), ← measure_univ (μ := (kerNat κ b c) (fun i ↦ x i.1)),
      ← lintegral_const]
    refine lintegral_congr fun y ↦ hf fun i hi ↦ ?_
    simp only [updateFinset, mem_Iic, el, id_eq, MeasurableEquiv.coe_mk, Equiv.coe_fn_mk,
      dite_eq_right_iff, dite_eq_left_iff, not_le]
    intro h
    rw [mem_Ioc] at h
    rw [mem_coe, mem_Iic] at hi
    omega

theorem dependsOn_kerint (a : ℕ) {b : ℕ} {f : ((n : ℕ) → X n) → ℝ≥0∞} (hf : DependsOn f (Iic b))
    (mf : Measurable f) :
    DependsOn (kerint κ a b f) (Iic a) := by
  intro x y hxy
  rcases le_or_lt b a with hba | hab
  · rw [kerint_le κ hba mf]
    exact hf fun i hi ↦ hxy i (Iic_subset_Iic.2 hba hi)
  · rw [kerint_lt _ hab mf, kerint_lt _ hab mf]
    congrm ∫⁻ z : _, ?_ ∂kerNat κ a b (fun i ↦ ?_)
    · exact hxy i.1 i.2
    · refine dependsOn_updateFinset hf _ _ ?_
      rwa [← coe_sdiff, Iic_sdiff_Ioc_same hab.le]

theorem kerint_eq {a b c : ℕ} (hab : a < b) (hbc : b < c) {f : ((n : ℕ) → X n) → ℝ≥0∞}
    (hf : Measurable f) :
    kerint κ a c f = kerint κ a b (kerint κ b c f) := by
  ext x
  rw [kerint_lt _ (hab.trans hbc) hf, kerint_lt _ hab]
  simp_rw [kerint_lt _ hbc hf]
  rw [← compProd_kerNat _ hab hbc, compProd_eq _ _  hab hbc, kernel.map_apply,
    lintegral_map _ (er ..).measurable, kernel.lintegral_compProd]
  · congrm ∫⁻ _, ∫⁻ _, f fun i ↦ ?_ ∂(?_) ∂_
    · rw [split_eq_comap, kernel.comap_apply]
      congr with i
      simp only [el, MeasurableEquiv.coe_mk, Equiv.coe_fn_mk, updateFinset, PNat.mk_coe]
      split_ifs with h1 h2 h3 <;> try rfl
      · rw [mem_Ioc] at h2
        omega
      · rw [mem_Ioc] at h3
        have := mem_Iic.1 i.2
        omega
    · simp only [updateFinset, mem_Ioc, er, MeasurableEquiv.coe_mk, Equiv.coe_fn_mk]
      split_ifs <;> try rfl
      repeat omega
  · exact hf.comp <| measurable_updateFinset.comp (er ..).measurable
  · exact hf.comp <| measurable_updateFinset
  · exact measurable_kerint _ _ _ hf

-- theorem obv : PNat.val = Subtype.val := by rfl

-- theorem update_eq_updateFinset' (x : (n : ℕ+) → X n) (k : ℕ)
--     (y : X (k + 1)) :
--     update x k.succPNat (y) =
--     updateFinset x (PIoc k (k + 1)) (Ioc_PIoc_pi (e k y)) := by
--   ext i
--   simp only [update, updateFinset, Ioc_PIoc_pi, MeasurableEquiv.coe_mk, Equiv.coe_fn_mk]
--   split_ifs with h1 h2 h3
--   · cases h1; rfl
--   · rw [mem_PIoc_succ] at h2
--     rw [← PNat.coe_inj] at h1
--     exact (h2 h1).elim
--   · rw [mem_PIoc_succ] at h3
--     rw [← PNat.coe_inj] at h1
--     exact (h1 h3).elim
--   · rfl

theorem update_updateFinset_eq (x z : (n : ℕ) → X n) {m : ℕ} :
    update (updateFinset x (Iic m) (fun i ↦ z i)) (m + 1) (z (m + 1)) =
    updateFinset x (Iic (m + 1)) (fun i ↦ z i) := by
  ext i
  simp only [update, updateFinset, mem_Iic, dite_eq_ite]
  split_ifs with h1 h2 h3 h4 h5 <;> try omega
  · cases h1; rfl
  · rfl
  · rfl

theorem auxiliaire {f : ℕ → ((n : ℕ) → X n) → ℝ≥0∞} {N : ℕ → ℕ}
    (hcte : ∀ n, DependsOn (f n) (Iic (N n))) (mf : ∀ n, Measurable (f n))
    {bound : ℝ≥0∞} (fin_bound : bound ≠ ∞) (le_bound : ∀ n x, f n x ≤ bound) {k : ℕ}
    (anti : ∀ x, Antitone (fun n ↦ kerint κ (k + 1) (N n) (f n) x))
    {l : ((n : ℕ) → X n) → ℝ≥0∞}
    (htendsto : ∀ x, Tendsto (fun n ↦ kerint κ (k + 1) (N n) (f n) x) atTop (𝓝 (l x)))
    (ε : ℝ≥0∞) (y : (n : Iic k) → X n)
    (hpos : ∀ x n, ε ≤ kerint κ k (N n) (f n) (updateFinset x _ y)) :
    ∃ z, ∀ x n,
    ε ≤ kerint κ (k + 1) (N n) (f n) (Function.update (updateFinset x _ y) (k + 1) z) := by
  have _ n : Nonempty (X n) := by
    refine Nat.case_strong_induction_on (p := fun n ↦ Nonempty (X n)) _ inferInstance
      fun n hind ↦ ?_
    have : Nonempty ((i : Iic n) → X i) :=
      Nonempty.intro fun i ↦ @Classical.ofNonempty _ (hind i.1 (mem_Iic.1 i.2))
    exact ProbabilityMeasure.nonempty
      ⟨κ n Classical.ofNonempty, inferInstance⟩
  -- Shorter name for integrating over all the variables except the first `k + 1`.
  let F : ℕ → ((n : ℕ) → X n) → ℝ≥0∞ := fun n ↦ kerint κ (k + 1) (N n) (f n)
  -- `Fₙ` converges to `l` by hypothesis.
  have tendstoF x : Tendsto (F · x) atTop (𝓝 (l x)) := htendsto x
  -- Integrating `fₙ` over all the variables except the first `k` is the same as integrating
  -- `Fₙ` over the `k`-th variable.
  have f_eq x n : kerint κ k (N n) (f n) x = kerint κ k (k + 1) (F n) x := by
    simp_rw [F]
    rcases lt_trichotomy (k + 1) (N n) with h | h | h
    · rw [kerint_eq κ k.lt_succ_self h (mf n)]
    · rw [← h, kerint_le _ (le_refl (k + 1)) (mf n)]
    · have : N n ≤ k := Nat.lt_succ.1 h
      rw [kerint_le _ this (mf n), dependsOn_kerint' _ _ (mf n) (hcte n) (this.trans k.le_succ),
        dependsOn_kerint' _ _ (mf n) (hcte n) this]
  -- `F` is also a bounded sequence.
  have F_le n x : F n x ≤ bound := by
    simp_rw [F, kerint]
    rw [← mul_one bound, ← measure_univ (μ := (composition κ (k + 1) (N n)) (fun i ↦ x i.1)),
        ← lintegral_const]
    exact lintegral_mono fun _ ↦ le_bound _ _
  -- By dominated convergence, the integral of `fₙ` with respect to all the variable except
  -- the `k` first converges to the integral of `l`.
  have tendsto_int x : Tendsto (fun n ↦ kerint κ k (N n) (f n) x) atTop
      (𝓝 (kerint κ k (k + 1) l x)) := by
    simp_rw [f_eq, kerint]
    exact tendsto_lintegral_of_dominated_convergence (fun _ ↦ bound)
      (fun n ↦ (measurable_kerint _ _ _ (mf n)).comp measurable_updateFinset)
      (fun n ↦ eventually_of_forall <| fun y ↦ F_le n _)
      (by simp [fin_bound]) (eventually_of_forall (fun _ ↦ tendstoF _))
  -- By hypothesis, we have `ε ≤ ∫ F(y, xₖ) ∂μₖ`, so this is also true for `l`.
  have ε_le_lint x : ε ≤ kerint κ k (k + 1) l (updateFinset x _ y) :=
    ge_of_tendsto (tendsto_int _) (by simp [hpos])
  let x_ : (n : ℕ) → X n := Classical.ofNonempty
  -- We now have that the integral of `l` with respect to a probability measure is greater than `ε`,
  -- therefore there exists `x'` such that `ε ≤ l(y, x')`.
  obtain ⟨x', hx'⟩ : ∃ x', ε ≤ l (Function.update (updateFinset x_ _ y) (k + 1) x') := by
    have aux : ∫⁻ (a : X (k + 1)),
        l (update (updateFinset x_ _ y) (k + 1) a) ∂(κ k y) ≠ ∞ := by
      apply ne_top_of_le_ne_top fin_bound
      rw [← mul_one bound, ← measure_univ (μ := κ k y), ← lintegral_const]
      exact lintegral_mono <| fun y ↦ le_of_tendsto' (tendstoF _) <| fun _ ↦ F_le _ _
    rcases exists_lintegral_le aux with ⟨x', hx'⟩
    refine ⟨x', ?_⟩
    calc
      ε ≤ ∫⁻ (z : X (k + 1)),
          l (update (updateFinset x_ _ y) (k + 1) z) ∂(κ k y) := by
          convert ε_le_lint x_
          rw [kerint_lt _ k.lt_succ_self, kerNat_succ, kernel.map_apply, lintegral_map_equiv]
          · congrm ∫⁻ z, (l fun i ↦ ?_) ∂κ k (fun i ↦ ?_)
            · simp [i.2, updateFinset]
            · simp [update, updateFinset, e]
          · refine ENNReal.measurable_of_tendsto ?_ (tendsto_pi_nhds.2 htendsto)
            exact fun n ↦ measurable_kerint _ _ _ (mf n)
      _ ≤ l (update (updateFinset x_ _ y) (k + 1) x') := hx'
  refine ⟨x', fun x n ↦ ?_⟩
  -- As `F` is a non-increasing sequence, we have `ε ≤ Fₙ(y, x')` for any `n`.
  have := le_trans hx' ((anti _).le_of_tendsto (tendstoF _) n)
  -- This part below is just to say that this is true for any `x : (i : ι) → X i`,
  -- as `Fₙ` technically depends on all the variables, but really depends only on the first `k + 1`.
  convert this using 1
  refine dependsOn_kerint _ _ (hcte n) (mf n) fun i hi ↦ ?_
  simp only [update, updateFinset]
  split_ifs with h1 h2 <;> try rfl
  · rw [mem_coe, mem_Iic] at *
    omega

theorem cylinders_nat :
    cylinders X = ⋃ (N) (S) (_ : MeasurableSet S), {cylinder (Iic N) S} := by
  ext s
  simp only [mem_cylinders, exists_prop, Set.mem_iUnion, mem_singleton]
  constructor
  · rintro ⟨t, S, mS, rfl⟩
    refine ⟨t.sup id, (fun (x : (i : Iic (t.sup id)) → X i) (j : t) ↦
      x ⟨j.1, mem_Iic.2 (le_sup (f := id) j.2)⟩) ⁻¹' S, ?_, ?_⟩
    · exact measurable_pi_lambda _ (fun _ ↦ measurable_pi_apply _) mS
    · unfold cylinder
      rw [← Set.preimage_comp]
      rfl
  · rintro ⟨N, S, mS, rfl⟩
    exact ⟨Iic N, S, mS, rfl⟩

def key {p : ℕ} (x₀ : (i : Iic p) → X i) (ind : (k : ℕ) → ((n : Iic k) → X n) → X (k + 1)) :
    (k : ℕ) → X k := fun k ↦ by
  cases k with
  | zero => exact x₀ ⟨0, mem_Iic.2 (zero_le _)⟩
  | succ l =>
    exact if hl : l + 1 ≤ p
      then x₀ ⟨l + 1, mem_Iic.2 hl⟩
      else ind l (fun i ↦ key x₀ ind i)
  decreasing_by
    have := mem_Iic.1 i.2
    rename_i h
    rw [← Nat.lt_succ, Nat.succ_eq_add_one, ← h] at this
    exact this

theorem key_eq {p : ℕ} (x₀ : (i : Iic p) → X i) (ind : (k : ℕ) → ((n : Iic k) → X n) → X (k + 1))
    (k : Iic p) : key x₀ ind k = x₀ k := by
  rcases k with ⟨i, hi⟩
  cases i with
  | zero =>
    rw [key, Nat.casesAuxOn_zero]
  | succ j =>
    rw [key, Nat.casesAuxOn_succ]
    simp [mem_Iic.1 hi]

theorem dependsOn_cylinder_indicator {ι : Type*} {α : ι → Type*} {I : Finset ι}
    (S : Set ((i : I) → α i)) :
    DependsOn ((cylinder I S).indicator (1 : ((i : ι) → α i) → ℝ≥0∞)) I := by
  intro x y hxy
  have : x ∈ cylinder I S ↔ y ∈ cylinder I S := by simp [hxy]
  by_cases h : x ∈ cylinder I S
  · simp [h, this.1 h]
  · simp [h, this.not.1 h]

theorem proj_updateFinset {n : ℕ} (x : (n : ℕ) → X n) (y : (i : Iic n) → X i) :
    proj n (updateFinset x _ y) = y := by
  ext i
  simp [proj, updateFinset, mem_Iic.1 i.2]

/-- This is the key theorem to prove the existence of the product measure: the `kolContent` of
a decresaing sequence of cylinders with empty intersection converges to $0$, in the case where
the measurable spaces are indexed by $\mathbb{N}$. This implies the $\sigma$-additivity of
`kolContent` (see `sigma_additive_addContent_of_tendsto_zero`),
which allows to extend it to the $\sigma$-algebra by Carathéodory's theorem. -/
theorem firstLemma (A : ℕ → Set ((n : ℕ) → X n)) (A_mem : ∀ n, A n ∈ cylinders X)
    (A_anti : Antitone A) (A_inter : ⋂ n, A n = ∅) {p : ℕ} (x₀ : (i : Iic p) → X i) :
    Tendsto (fun n ↦ kC κ x₀ (A n)) atTop (𝓝 0) := by
  have _ n : Nonempty (X n) := by
    refine Nat.case_strong_induction_on (p := fun n ↦ Nonempty (X n)) _ inferInstance
      fun n hind ↦ ?_
    have : Nonempty ((i : Iic n) → X i) :=
      Nonempty.intro fun i ↦ @Classical.ofNonempty _ (hind i.1 (mem_Iic.1 i.2))
    exact ProbabilityMeasure.nonempty
      ⟨κ n Classical.ofNonempty, inferInstance⟩
  -- `Aₙ` is a cylinder, it can be written `cylinder sₙ Sₙ`.
  have A_cyl n : ∃ N S, MeasurableSet S ∧ A n = cylinder (Iic N) S := by
    simpa [cylinders_nat] using A_mem n
  choose N S mS A_eq using A_cyl
  -- We write `χₙ` for the indicator function of `Aₙ`.
  let χ n := (A n).indicator (1 : ((n : ℕ) → X n) → ℝ≥0∞)
  -- `χₙ` is measurable.
  have mχ n : Measurable (χ n) := by
    simp_rw [χ, A_eq]
    exact (measurable_indicator_const_iff 1).2 <| measurableSet_cylinder _ _ (mS n)
  -- `χₙ` only depends on the first coordinates.
  have χ_dep n : DependsOn (χ n) (Iic (N n)) := by
    simp_rw [χ, A_eq]
    exact dependsOn_cylinder_indicator _
  -- Therefore its integral is constant.
  have lma_const x y k (hk : k ≤ p) n : kerint κ k (N n) (χ n) (updateFinset x _ x₀) =
      kerint κ k (N n) (χ n) (updateFinset y _ x₀) := by
    apply dependsOn_kerint κ k (χ_dep n) (mχ n)
    intro i hi
    rw [mem_coe, mem_Iic] at hi
    simp [updateFinset, hi.trans hk]
  -- As `(Aₙ)` is non-increasing, so is `(χₙ)`.
  have χ_anti : Antitone χ := by
    intro m n hmn y
    apply Set.indicator_le
    exact fun a ha ↦ by simp [χ, A_anti hmn ha]
  -- Integrating `χₙ` further than the last coordinate it depends on does nothing.
  -- This is used to then show that the integral of `χₙ` over all the variables except the first
  -- `k` ones is non-increasing.
  have lma_inv k M n (h : N n ≤ M) :
      kerint κ k M (χ n) = kerint κ k (N n) (χ n) := by
    refine Nat.le_induction rfl ?_ M h
    intro K hK hind
    rw [← hind]
    rcases lt_trichotomy k K with hkK | hkK | hkK
    · rw [kerint_eq κ hkK K.lt_succ_self (mχ n), dependsOn_kerint' _ _ (mχ n) (χ_dep n) hK]
    · rw [hkK, dependsOn_kerint' _ _ (mχ n) (χ_dep n) hK, dependsOn_kerint' _ _ (mχ n) (χ_dep n) hK]
    · rw [kerint_le _ hkK.le (mχ n), kerint_le _ (Nat.succ_le.2 hkK) (mχ n)]
  -- the integral of `χₙ` over all the variables except the first `k` ones is non-increasing.
  have anti_lma k x : Antitone fun n ↦ kerint κ k (N n) (χ n) x := by
    intro m n hmn
    simp only
    rw [← lma_inv k ((N n).max (N m)) n (le_max_left _ _),
      ← lma_inv k ((N n).max (N m)) m (le_max_right _ _)]
    exact kerint_mono _ _ _ (χ_anti hmn) _
  -- Therefore it converges to some function `lₖ`.
  have this k x : ∃ l, Tendsto (fun n ↦ kerint κ k (N n) (χ n) x) atTop (𝓝 l) := by
    rcases tendsto_of_antitone <| anti_lma k x with h | h
    · rw [OrderBot.atBot_eq] at h
      exact ⟨0, h.mono_right <| pure_le_nhds 0⟩
    · exact h
  choose l hl using this
  -- `l₀` is constant because it is the limit of constant functions: we call it `ε`.
  have l_const x y k (hk : k ≤ p) : l k (updateFinset x _ x₀) = l k (updateFinset y _ x₀) := by
    have := hl k (updateFinset x _ x₀)
    simp_rw [lma_const x y k hk] at this
    exact tendsto_nhds_unique this (hl k _)
  obtain ⟨ε, hε⟩ : ∃ ε, ∀ x, l p (updateFinset x _ x₀) = ε :=
      ⟨l p (updateFinset Classical.ofNonempty _ x₀), fun x ↦ l_const _ _ p (le_refl p)⟩
  -- As the sequence is decreasing, `ε ≤ ∫ χₙ`.
  have hpos x n : ε ≤ kerint κ p (N n) (χ n) (updateFinset x _ x₀) :=
    hε x ▸ ((anti_lma p _).le_of_tendsto (hl p _)) n
  -- Also, the indicators are bounded by `1`.
  have χ_le n x : χ n x ≤ 1 := by
    apply Set.indicator_le
    simp
  -- We have all the conditions to apply àuxiliaire. This allows us to recursively
  -- build a sequence `(zₙ)` with the following crucial property: for any `k` and `n`,
  -- `ε ≤ ∫ χₙ(z₀, ..., z_{k-1}) ∂(μₖ ⊗ ... ⊗ μ_{Nₙ})`.
  choose! ind hind using
    fun k y h ↦ auxiliaire κ χ_dep mχ (by norm_num : (1 : ℝ≥0∞) ≠ ∞) χ_le (anti_lma (k + 1))
      (hl (k + 1)) ε y h
  let z := key x₀ ind
  have crucial k (hk : p ≤ k) : ∀ x n,
      ε ≤ kerint κ k (N n) (χ n) (updateFinset x (Iic k) (fun i ↦ z i)) := by
    refine Nat.le_induction ?_ ?_ k hk
    · intro x n
      convert hpos x n with i
      simp_rw [z]
      apply key_eq
    · intro k hn h x n
      rw [← update_updateFinset_eq]
      convert hind k (fun i ↦ z i.1) h x n
      simp_rw [z]
      rw [key, Nat.casesAuxOn_succ]
      simp [Nat.lt_succ.2 hn]
  -- We now want to prove that the integral of `χₙ` converges to `0`.
  have concl x n : kC κ x₀ (A n) = kerint κ p (N n) (χ n) (updateFinset x _ x₀) := by
    simp_rw [χ, A_eq]
    nth_rw 1 [← proj_updateFinset x x₀]
    exact kolContent_eq_kerint κ (mS n) (updateFinset x _ x₀) p
  simp_rw [concl Classical.ofNonempty]
  convert hl p (updateFinset Classical.ofNonempty _ x₀)
  rw [hε]
  by_contra!
  -- Which means that we want to prove that `ε = 0`. But if `ε > 0`, then for any `n`,
  -- choosing `k > Nₙ` we get `ε ≤ χₙ(z₀, ..., z_{Nₙ})` and therefore `(z n) ∈ Aₙ`.
  -- This contradicts the fact that `(Aₙ)` has an empty intersection.
  have ε_pos : 0 < ε := this.symm.bot_lt
  have incr n : z ∈ A n := by
    have : χ n z = kerint κ (max p (N n)) (N n) (χ n)
        (updateFinset z (Iic (N n)) (fun i ↦ z i)) := by
      rw [kerint_le _ (le_max_right _ _) (mχ n)]
      congr with i
      simp [updateFinset]
    have : 0 < χ n (z) := by
      rw [this]
      convert lt_of_lt_of_le ε_pos (crucial _ (le_max_left _ _) z n) using 2
      ext i
      simp [updateFinset]
    exact Set.mem_of_indicator_ne_zero (ne_of_lt this).symm
  exact (A_inter ▸ Set.mem_iInter.2 incr).elim

theorem kolContent_sigma_subadditive_proj {p : ℕ} (x₀ : (i : Iic p) → X i)
    ⦃f : ℕ → Set ((n : ℕ) → X n)⦄
    (hf : ∀ n, f n ∈ cylinders X)
    (hf_Union : (⋃ n, f n) ∈ cylinders X) :
    kC κ x₀ (⋃ n, f n) ≤ ∑' n, kC κ x₀ (f n) := by
  have _ n : Nonempty (X n) := by
    refine Nat.case_strong_induction_on (p := fun n ↦ Nonempty (X n)) _ inferInstance
      fun n hind ↦ ?_
    have : Nonempty ((i : Iic n) → X i) :=
      Nonempty.intro fun i ↦ @Classical.ofNonempty _ (hind i.1 (mem_Iic.1 i.2))
    exact ProbabilityMeasure.nonempty
      ⟨κ n Classical.ofNonempty, inferInstance⟩
  refine (kC κ x₀).sigma_subadditive_of_sigma_additive
    setRing_cylinders (fun f hf hf_Union hf' ↦ ?_) f hf hf_Union
  refine sigma_additive_addContent_of_tendsto_zero setRing_cylinders
    (kC κ x₀) (fun h ↦ ?_) ?_ hf hf_Union hf'
  · rename_i s
    obtain ⟨N, S, mS, s_eq⟩ : ∃ N S, MeasurableSet S ∧ s = cylinder (Iic N) S := by
      simpa [cylinders_nat] using h
    let x_ : (n : ℕ) → X n := Classical.ofNonempty
    classical
    rw [s_eq, ← proj_updateFinset x_ x₀, kolContent_eq_kerint κ mS (updateFinset x_ _ x₀)]
    refine ne_of_lt (lt_of_le_of_lt ?_ (by norm_num : (1 : ℝ≥0∞) < ∞))
    nth_rw 2 [← mul_one 1, ← measure_univ (μ := composition κ p N (fun i ↦ updateFinset x_ _ x₀ i))]
    rw [kerint, ← lintegral_const]
    exact lintegral_mono <| Set.indicator_le (by simp)
  · exact fun s hs anti_s inter_s ↦ firstLemma κ s hs anti_s inter_s x₀

noncomputable def ionescu_tulcea_fun (p : ℕ) (x₀ : (i : Iic p) → X i) :
    Measure ((n : ℕ) → X n) := by
  exact Measure.ofAddContent setSemiringCylinders generateFrom_cylinders
    (kC κ x₀)
    (kolContent_sigma_subadditive_proj κ x₀)

theorem proba_ionescu (p : ℕ) (x₀ : (i : Iic p) → X i) :
    IsProbabilityMeasure (ionescu_tulcea_fun κ p x₀) := by
  constructor
  rw [← cylinder_univ ∅, ionescu_tulcea_fun, Measure.ofAddContent_eq, kC,
      kolContent_congr _ _ rfl MeasurableSet.univ]
  · simp only [family']
    rw [← kernel.map_apply _ (measurable_pi_lambda _ (fun _ ↦ measurable_pi_apply _))]
    simp
  · simp only [mem_cylinders, exists_prop, forall_const]
    exact ⟨∅, Set.univ, MeasurableSet.univ, rfl⟩
  · simp only [mem_cylinders, exists_prop, forall_const]
    exact ⟨∅, Set.univ, MeasurableSet.univ, rfl⟩

theorem isProjectiveLimit_ionescu_tulcea_fun (p : ℕ) (x₀ : (i : Iic p) → X i) :
    IsProjectiveLimit (ionescu_tulcea_fun κ p x₀) (family' (fun n ↦ composition κ p n x₀)) := by
  intro I
  ext1 s hs
  rw [Measure.map_apply (measurable_proj' _) hs]
  have h_mem : (fun (x : (n : ℕ) → X n) (i : I) ↦ x i) ⁻¹' s ∈ cylinders X := by
    rw [mem_cylinders]; exact ⟨I, s, hs, rfl⟩
  rw [ionescu_tulcea_fun, Measure.ofAddContent_eq _ _ _ _ h_mem, kC,
    kolContent_congr _ h_mem rfl hs]

theorem measurable_ionescu (p : ℕ) : Measurable (ionescu_tulcea_fun κ p) := by
  apply Measure.measurable_of_measurable_coe
  refine MeasurableSpace.induction_on_inter
    (C := fun t ↦ Measurable (fun x₀ ↦ ionescu_tulcea_fun κ p x₀ t))
    (s := cylinders X) generateFrom_cylinders.symm isPiSystem_cylinders
    (by simp) (fun t ht ↦ ?cylinder) (fun t mt ht ↦ ?compl) (fun f disf mf hf ↦ ?union)
  · obtain ⟨N, S, mS, t_eq⟩ : ∃ N S, MeasurableSet S ∧ t = cylinder (Iic N) S := by
      simpa [cylinders_nat] using ht
    simp_rw [ionescu_tulcea_fun, Measure.ofAddContent_eq _ _ _ _ ht, kC,
      kolContent_congr _ ht t_eq mS]
    simp only [family']
    refine Measure.measurable_measure.1 ?_ _ mS
    refine (Measure.measurable_map _ ?_).comp (kernel.measurable _)
    exact measurable_pi_lambda _ (fun _ ↦ measurable_pi_apply _)
  · have this x₀ : ionescu_tulcea_fun κ p x₀ tᶜ = 1 - ionescu_tulcea_fun κ p x₀ t := by
      have := proba_ionescu κ
      rw [measure_compl mt (measure_ne_top _ _), measure_univ]
    simp_rw [this]
    exact Measurable.const_sub ht _
  · simp_rw [measure_iUnion disf mf]
    exact Measurable.ennreal_tsum hf

noncomputable def ionescu_tulcea_kernel (p : ℕ) : kernel ((i : Iic p) → X i) ((n : ℕ) → X n) :=
  { val := ionescu_tulcea_fun κ p
    property := measurable_ionescu κ p }

theorem ionescu_tulcea_kernel_apply (p : ℕ) (x₀ : (i : Iic p) → X i) :
    ionescu_tulcea_kernel κ p x₀ = ionescu_tulcea_fun κ p x₀ := by
  rw [ionescu_tulcea_kernel]
  rfl

instance (p : ℕ) : IsMarkovKernel (ionescu_tulcea_kernel κ p) :=
    IsMarkovKernel.mk fun _ ↦ proba_ionescu _ _ _

theorem ionescu_tulcea_proj (a b : ℕ) :
    kernel.map (ionescu_tulcea_kernel κ a) (proj b) (meas_proj b) =
    composition κ a b := by
  ext1 x₀
  rw [kernel.map_apply, ionescu_tulcea_kernel_apply, isProjectiveLimit_ionescu_tulcea_fun,
    family'_Iic]






variable {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] [CompleteSpace E]
variable {Y Z T : Type*} [MeasurableSpace Y] [MeasurableSpace Z] [MeasurableSpace T]

-- theorem integral_dep {N : ℕ} (x₀ : X 0) {f : ((i : Iic N) → X i) → E}
--     (hf : AEStronglyMeasurable f (ionescu_proj κ N x₀)) :
--     ∫ y, f ((fun x (i : Iic N) ↦ x i) y) ∂ionescu_tulcea_kernel κ x₀ =
--     ∫ y, f y ∂ionescu_proj κ N x₀ := by
--   rw [← ionescu_tulcea_proj, kernel.map_apply, integral_map]
--   · exact (measurable_proj _).aemeasurable
--   · rwa [← kernel.map_apply, ionescu_tulcea_proj]

-- theorem integral_noyau {n : ℕ} (f : ((n : ℕ) → X n) → E) (x : (i : Iic n) → X i) :
--     ∫ y, f y ∂noyau n x = ∫ y, f (updateFinset y _ x) ∂noyau n x := sorry

-- -- theorem integral_composition {a b : ℕ} (f : ((n : ℕ) → X n) → E) (x : (i : Iic a) → X i) :
-- --     ∫ y, f y ∂composition κ a b x = ∫ y, f (updateFinset y _ x) ∂noyau n x := sorry

abbrev m : MeasurableSpace ((n : ℕ) → X n) := inferInstance
abbrev m' : (n : ℕ) → MeasurableSpace ((i : Iic n) → X i) := inferInstance
abbrev ff : ℕ → MeasurableSpace ((n : ℕ) → X n) :=
  fun n ↦ (m' n).comap (proj n)

theorem preimage_indicator' {α β M : Type*} [Zero M] (f : α → β) (g : β → M)
    (s : Set β) (a : α) :
    (f ⁻¹' s).indicator (g ∘ f) a = s.indicator g (f a) := by
  by_cases h : f a ∈ s <;> simp [h]

theorem indicator_eq {α : Type*} (f : α → E) (s : Set α) (a : α) :
    s.indicator f a = (s.indicator (fun _ ↦ 1 : α → ℝ) a) • (f a) := by
  by_cases h : a ∈ s <;> simp [h]

theorem kernel.integral_comp (η : kernel Z T) [IsFiniteKernel η] (κ : kernel Y Z)
    (y : Y) {g : T → E} (hg1 : Integrable g ((η ∘ₖ κ) y))
    (hg2 : ∀ z, Integrable g (η z)) (hg3 : ∀ y, Integrable (fun z ↦ ∫ t, g t ∂η z) (κ y)) :
    ∫ t, g t ∂(η ∘ₖ κ) y = ∫ z, ∫ t, g t ∂η z ∂κ y := by sorry
  -- revert hg3 hg2
  -- refine Integrable.induction ?_ ?_ ?_ ?_ hg1
  -- · intro e s ms hs h1 h2
  --   simp_rw [integral_indicator_const e ms]
  --   rw [integral_smul_const, kernel.comp_apply' _ _ _ ms, integral_toReal]
  --   · exact (kernel.measurable_coe _ ms).aemeasurable
  --   · exact eventually_of_forall fun _ ↦ (measure_ne_top _ _).lt_top
  -- · rintro f g - f_int g_int hf hg h1 h2
  --   rw [integral_add' f_int g_int, hf, hg, ← integral_add]
  --   · congr with z
  --     rw [integral_add' f_int g_int]

theorem composition_comp_noyau {a b : ℕ} (hab : a ≤ b) :
    (ionescu_tulcea_kernel κ b) ∘ₖ (composition κ a b) = ionescu_tulcea_kernel κ a := by
  ext1 x
  rw [ionescu_tulcea_kernel_apply]
  have : ∀ I : Finset ℕ, IsFiniteMeasure (family' (fun n ↦ composition κ a n x) I) := by
    intro I
    rw [family']
    infer_instance
  refine isProjectiveLimit_unique ?_ (isProjectiveLimit_ionescu_tulcea_fun _ _ _)
  rw [proj_limit_iff _ (proj_family' _ (proj_family'' κ x))]
  intro n
  rw [family'_Iic]
  ext s ms
  rw [Measure.map_apply (meas_proj n) ms, kernel.comp_apply' _ _ _ (meas_proj n ms)]
  simp_rw [← Measure.map_apply (meas_proj n) ms,
    ← kernel.map_apply (ionescu_tulcea_kernel κ b) (meas_proj n), ionescu_tulcea_proj κ b n]
  rw [← kernel.comp_apply', composition_comp _ n hab]
  exact ms

def el' (n : ℕ) : (((i : Iic n) → X i) × ((i : Set.Ioi n) → X i)) ≃ᵐ ((n : ℕ) → X n) :=
  { toFun := fun p i ↦ if hi : i ≤ n
      then p.1 ⟨i, mem_Iic.2 hi⟩
      else p.2 ⟨i, Set.mem_Ioi.2 (not_le.1 hi)⟩
    invFun := fun x ↦ (fun i ↦ x i, fun i ↦ x i)
    left_inv := fun p ↦ by
      ext i
      · simp [mem_Iic.1 i.2]
      · simp [not_le.2 <| Set.mem_Ioi.1 i.2]
    right_inv := fun x ↦ by simp
    measurable_toFun := by
      refine measurable_pi_lambda _ (fun i ↦ ?_)
      by_cases hi : i ≤ n
      · simp only [Equiv.coe_fn_mk, hi, ↓reduceDite]
        exact measurable_fst.eval
      · simp only [Equiv.coe_fn_mk, hi, ↓reduceDite]
        exact measurable_snd.eval
    measurable_invFun := Measurable.prod_mk (measurable_proj _) (measurable_proj _) }

theorem el'symmfst (n : ℕ) : (fun x ↦ ((el' (X := X) n).symm x).1) = proj n := by
  ext x i
  simp [el']

theorem projel' (n : ℕ) (x : (i : Iic n) → X i) (y : (i : Set.Ioi n) → X i) :
    proj n ((el' (X := X) n) (x, y)) = x := by
  ext i
  simp [el', proj, mem_Iic.1 i.2]

theorem noyau_proj {a b : ℕ} (hab : a ≤ b) :
    kernel.map (ionescu_tulcea_kernel κ b) (@proj X a) (meas_proj a) =
    kernel.deterministic
      (fun (x : (i : Iic b) → X i) (i : Iic a) ↦ x ⟨i.1, Iic_subset_Iic.2 hab i.2⟩)
      (measurable_proj₂' ..) := by
  rw [ionescu_tulcea_proj, composition, dif_neg (not_lt.2 hab)]

theorem integral_map_equiv' (e : Y ≃ᵐ Z) (f : Z → E) (μ : Measure Z) :
    ∫ y, f (e y) ∂Measure.map e.symm μ = ∫ z, f z ∂μ := by
  simp_rw [integral_map_equiv e.symm, e.apply_symm_apply]

-- theorem jsp (μ : Measure Y) [IsFiniteMeasure μ] {f : Y → Z × T} (mf : Measurable f) :
--     μ.map f = (μ.map (fun y ↦ (f y).1)).prod (μ.map (fun y ↦ (f y).2)) := by
--   have : f = (Prod.map (Prod.fst ∘ f) (Prod.snd ∘ f)) ∘ (fun x ↦ (x, x)) := by sorry
--   rw [this, ← Measure.map_map]
--   refine (Measure.prod_eq fun s t ms mt ↦ ?_).symm
--   rw [Measure.map_apply, Set.preimage_prod_map_prod, Measure.map_apply, Measure.map_apply,
--     Measure.map_apply]
--   · simp only [Set.diag_preimage_prod, comp_apply, Prod_map, Prod.mk.eta]
--   -- rw [Measure.map_apply mf (ms.prod mt), Measure.map_apply _ ms, Measure.map_apply _ mt]
--   -- ·

theorem ionescu_eq (n : ℕ) :
    ionescu_tulcea_kernel κ n =
    kernel.map
      (kernel.deterministic (@id ((i : Iic n) → X i)) measurable_id ×ₖ
        kernel.map (ionescu_tulcea_kernel κ n)
          (fun x i ↦ x i : ((n : ℕ) → X n) → (i : Set.Ioi n) → X i) (measurable_proj _))
      (el' n) (el' n).measurable := by
  ext1 x
  rw [ionescu_tulcea_kernel_apply]
  have : ∀ I : Finset ℕ, IsFiniteMeasure (family' (fun k ↦ composition κ n k x) I) := by
    intro I
    rw [family']
    infer_instance
  refine isProjectiveLimit_unique (isProjectiveLimit_ionescu_tulcea_fun _ _ _) ?_
  rw [proj_limit_iff' _ (proj_family' _ (proj_family'' κ x)) _ (n + 1)]
  intro k hk
  have hk' : n ≤ k := n.le_succ.trans hk
  rw [family'_Iic]
  ext s ms
  rw [Measure.map_apply, kernel.map_apply', kernel.prod_apply', kernel.lintegral_deterministic',
    kernel.map_apply']
  · have : (proj k) ∘ (el' n) ∘ (Prod.mk x) ∘
        (fun x i ↦ x i : ((n : ℕ) → X n) → (i : Set.Ioi n) → X i) =
        (fun y (i : Iic k) ↦ if hi : i.1 ≤ n then x ⟨i.1, mem_Iic.2 hi⟩ else y i) ∘ (proj k) := by
      ext x i
      by_cases hi : i.1 ≤ n <;> simp [proj, hi, el']
    have lol t : {c : (i : Set.Ioi n) → X i | (id x, c) ∈ t} = Prod.mk x ⁻¹' t := by
      ext c
      simp
    have hyp : Measurable
        (fun (y : (i : Iic k) → X i) (i : Iic k) ↦
        if hi : i.1 ≤ n then x ⟨i.1, mem_Iic.2 hi⟩ else y i) := by
      refine measurable_pi_lambda _ (fun i ↦ ?_)
      by_cases hi : i.1 ≤ n <;> simp [hi]
      exact measurable_pi_apply _
    rw [← Set.preimage_comp, lol, ← Set.preimage_comp, ← Set.preimage_comp, comp.assoc, this,
      ← kernel.map_apply', ← kernel.map_map, ionescu_tulcea_proj, kernel.map_apply', composition,
      dif_pos (Nat.succ_le.1 hk), kernel.map_apply', kernel.prod_apply',
      kernel.lintegral_deterministic', kernel.map_apply', kernel.prod_apply',
      kernel.lintegral_deterministic']
    · congr
      ext y
      simp only [id_eq, el, Nat.succ_eq_add_one, MeasurableEquiv.coe_mk, Equiv.coe_fn_mk,
        Set.mem_preimage, Set.mem_setOf_eq]
      congrm (fun i ↦ ?_) ∈ s
      by_cases hi : i.1 ≤ n <;> simp [hi]
    · exact measurable_measure_prod_mk_left ((el n k hk').measurable ms)
    · exact (el n k hk').measurable ms
    · exact ms
    · exact measurable_measure_prod_mk_left ((el n k hk').measurable <| hyp ms)
    · exact (el n k hk').measurable <| hyp ms
    · exact hyp ms
    · exact hyp
    · exact ms
    · exact ms
  · exact measurable_prod_mk_left ((el' n).measurable <| (meas_proj k) ms)
  · exact measurable_measure_prod_mk_left ((el' n).measurable <| (meas_proj k) ms)
  · exact (el' n).measurable <| (meas_proj k) ms
  · exact (meas_proj k) ms
  · exact meas_proj k
  · exact ms

theorem composition_comp_noyau_apply [CompleteSpace E] (n : ℕ)
    (f : ((i : Iic n) → X i) → ((n : ℕ) → X n) → E)
    (hf : StronglyMeasurable f.uncurry)
    (x₀ : (i : Iic 0) → X i) :
    ∫ x, f (proj n x) x ∂ionescu_tulcea_kernel κ 0 x₀ =
    ∫ x, ∫ y, f x y ∂ionescu_tulcea_kernel κ n x ∂composition κ 0 n x₀ := by
  rw [← composition_comp_noyau κ (zero_le n), kernel.integral_comp]
  · congr with x
    rw [ionescu_eq, kernel.map_apply, integral_map, kernel.prod_apply, integral_prod,
      kernel.integral_deterministic', integral_map, integral_prod,
      kernel.integral_deterministic']
    · congr with y
      rw [projel']
      rfl
    · apply StronglyMeasurable.integral_prod_right'
        (f := fun p ↦ f x (el' n p))
      exact hf.of_uncurry_left.comp_measurable (el' n).measurable
    · sorry
    · exact (el' n).measurable.aemeasurable
    · exact hf.of_uncurry_left.aestronglyMeasurable
    · apply StronglyMeasurable.integral_prod_right'
        (f := fun p ↦ f (proj n ((el' n) p)) (el' n p))
      apply hf.comp_measurable (g := fun p ↦ (proj n ((el' n) p), el' n p))
      exact Measurable.prod_mk ((meas_proj n).comp (el' n).measurable) (el' n).measurable
    · sorry
    · exact (el' n).measurable.aemeasurable
    · refine (hf.comp_measurable (g := fun p ↦ (proj n p, p)) ?_).aestronglyMeasurable
      exact Measurable.prod_mk (meas_proj n) measurable_id
  · sorry
  · sorry
  · sorry

theorem condExp_ionescu [CompleteSpace E]
    {n : ℕ} (x₀ : (i : Iic 0) → X i) {f : ((n : ℕ) → X n) → E} :
    condexp (ff n) (ionescu_tulcea_kernel κ 0 x₀) f =ᵐ[ionescu_tulcea_kernel κ 0 x₀]
      fun x ↦ ∫ y, f y ∂ionescu_tulcea_kernel κ n (fun i ↦ x i) := by
  refine (ae_eq_condexp_of_forall_setIntegral_eq ?_ ?_ ?_ ?_ ?_).symm
  · exact (measurable_proj _).comap_le
  · sorry
  · sorry
  · intro s ms hs
    rcases ms with ⟨t, mt, rfl⟩
    rw [← integral_indicator]
    · have this x : ((proj n) ⁻¹' t).indicator
          (fun x ↦ ∫ y, f y ∂ionescu_tulcea_kernel κ n (fun i ↦ x i)) x =
          t.indicator (fun x ↦ ∫ y, f y ∂ionescu_tulcea_kernel κ n x) ((proj n) x) := by
        apply preimage_indicator' (proj n) (fun x ↦ ∫ y, f y ∂ionescu_tulcea_kernel κ n x)
      simp_rw [this]
      rw [← integral_map, ← kernel.map_apply, ionescu_tulcea_proj κ]
      simp_rw [indicator_eq (fun x ↦ ∫ y, f y ∂ionescu_tulcea_kernel κ n x), ← integral_smul]
      · rw [← composition_comp_noyau_apply, ← integral_indicator]
        · congr with x
          by_cases h : proj n x ∈ t <;> simp [h]
        · exact meas_proj n mt
        · sorry
      · exact (meas_proj n).aemeasurable
      · sorry
    · exact meas_proj n mt
  · sorry
