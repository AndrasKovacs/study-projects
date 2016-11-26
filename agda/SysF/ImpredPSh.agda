
{-# OPTIONS --without-K --type-in-type #-}

-- note: interpretation of universe for dependent TT PSh:
-- ⟦ U ⟧ I = ∀ J → C(J, I) → Set

module ImpredPSh where

open import Lib
open import JM
open import Syntax

record *ᴹ : Set where
  constructor con
  field
    _$ᴾ_   : ∀ {Γ'} → Con Γ' → Set
    _$ᴾ_$_ : ∀ {Γ' Γ Δ' Δ σ'} → Ren {Δ'}{Γ'} σ' Δ Γ → _$ᴾ_ Γ → _$ᴾ_ Δ
  infixl 5 _$ᴾ_
  infix 5 _$ᴾ_$_    
open *ᴹ

*ᴹ≡' :
  ∀ {A B : *ᴹ}
  → (∀ {Γ'} (Γ : Con Γ') → A $ᴾ Γ ≡ B $ᴾ Γ)
  → (∀ {Γ' Γ Δ' Δ σ'} (σ : Ren {Δ'}{Γ'} σ' Δ Γ)(α : A $ᴾ Γ)(β : B $ᴾ Γ)
     → α ≃ β → A $ᴾ σ $ α ≃ B $ᴾ σ $ β)
  → A ≡ B
*ᴹ≡' {A}{B} p q = {!!}

data Con'ᴹ : Con' → Set where
  ∙   : Con'ᴹ ∙
  _,_ : ∀ {Γ'} → Con'ᴹ Γ' → *ᴹ → Con'ᴹ (Γ' ,*)

*∈ᴹ : ∀ {Γ'} → *∈ Γ' → Con'ᴹ Γ' → *ᴹ
*∈ᴹ vz     (Γ'ᴹ , Aᴹ) = Aᴹ
*∈ᴹ (vs v) (Γ'ᴹ , Aᴹ) = *∈ᴹ v Γ'ᴹ

Tyᴹ : ∀ {Γ'} → Ty Γ' → Con'ᴹ Γ' → *ᴹ
Tyᴹ (var v) Γ'ᴹ = *∈ᴹ v Γ'ᴹ
Tyᴹ (A ⇒ B) Γ'ᴹ =
  con (λ Δ → ∀ {Σ' Σ σ'} → Ren {Σ'} σ' Σ Δ → Tyᴹ A Γ'ᴹ $ᴾ Σ → Tyᴹ B Γ'ᴹ $ᴾ Σ)
      (λ σ f δ → f (σ ∘ᵣ δ))
Tyᴹ (∀' A)  Γᴹ =
  con (λ Δ → ∀ {Σ' Σ σ'} → Ren {Σ'} σ' Σ Δ → ∀ Bᴹ → Tyᴹ A (Γᴹ , Bᴹ) $ᴾ Σ)
      (λ σ f δ → f (σ ∘ᵣ δ))

data Conᴹ : ∀ {Γ'} → Con Γ' → Con'ᴹ Γ' → ∀ {Δ'} → Con Δ' → Set where
  ∙   : ∀ {Δ'}{Δ} → Conᴹ {∙} ∙ ∙ {Δ'} Δ
  _,_ : ∀ {Γ' Γ Γ'ᴹ A  Δ' Δ} → Conᴹ {Γ'} Γ Γ'ᴹ {Δ'} Δ → Tyᴹ A Γ'ᴹ $ᴾ Δ → Conᴹ (Γ , A) Γ'ᴹ Δ
  _,* : ∀ {Γ' Γ Γ'ᴹ Aᴹ Δ' Δ} → Conᴹ {Γ'} Γ Γ'ᴹ {Δ'} Δ → Conᴹ (Γ ,*) (Γ'ᴹ , Aᴹ) Δ

Ren'ᴹ : ∀ {Γ Δ} → Ren' Γ Δ → Con'ᴹ Γ → Con'ᴹ Δ
Ren'ᴹ ∙        Γᴹ        = Γᴹ
Ren'ᴹ (drop σ) (Γᴹ , *ᴹ) = Ren'ᴹ σ Γᴹ
Ren'ᴹ (keep σ) (Γᴹ , *ᴹ) = Ren'ᴹ σ Γᴹ , *ᴹ

Sub'ᴹ : ∀ {Γ Δ} → Sub' Γ Δ → Con'ᴹ Γ → Con'ᴹ Δ
Sub'ᴹ ∙       Γᴹ = ∙
Sub'ᴹ (σ , A) Γᴹ = Sub'ᴹ σ Γᴹ , Tyᴹ A Γᴹ

Conᴹᵣ :
  ∀ {Γ' Γ Δ' Δ Σ' Σ Γ'ᴹ σ} → Ren {Σ'}{Δ'} σ Σ Δ → Conᴹ {Γ'} Γ Γ'ᴹ Δ → Conᴹ Γ Γ'ᴹ Σ
Conᴹᵣ σ ∙         = ∙
Conᴹᵣ {Σ = Σ} {Γ'ᴹ} σ (_,_ {Γ = Γ} {A = A} Γᴹ Aᴹ) = Conᴹᵣ σ Γᴹ , (Tyᴹ A Γ'ᴹ $ᴾ σ $ Aᴹ)
Conᴹᵣ σ (Γᴹ ,*)   = Conᴹᵣ σ Γᴹ ,*  

id'ᵣᴹ : ∀ {Γ} (Γᴹ : Con'ᴹ Γ) → Ren'ᴹ id'ᵣ Γᴹ ≡ Γᴹ
id'ᵣᴹ {∙}    Γᴹ        = refl
id'ᵣᴹ {Γ ,*} (Γᴹ , *ᴹ) = (_, *ᴹ) & id'ᵣᴹ Γᴹ

[]∈'ᵣᴹ :
  ∀ {Γ Δ}(v : *∈ Γ)(σ : Ren' Δ Γ) Γᴹ
  → *∈ᴹ (v [ σ ]∈'ᵣ) Γᴹ ≡ *∈ᴹ v (Ren'ᴹ σ Γᴹ)
[]∈'ᵣᴹ ()     ∙        Γᴹ
[]∈'ᵣᴹ v      (drop σ) (Γᴹ , Aᴹ) = []∈'ᵣᴹ v σ Γᴹ
[]∈'ᵣᴹ vz     (keep σ) (Γᴹ , Aᴹ) = refl
[]∈'ᵣᴹ (vs v) (keep σ) (Γᴹ , Aᴹ) = []∈'ᵣᴹ v σ Γᴹ

[]'ᵣᴹ :
  ∀ {Γ Δ}(A : Ty Γ)(σ : Ren' Δ Γ) Γ'ᴹ
  → Tyᴹ (A [ σ ]'ᵣ) Γ'ᴹ ≡ Tyᴹ A (Ren'ᴹ σ Γ'ᴹ)
[]'ᵣᴹ (var v) σ' Γ'ᴹ = []∈'ᵣᴹ v σ' Γ'ᴹ
[]'ᵣᴹ (A ⇒ B) σ' Γ'ᴹ rewrite []'ᵣᴹ A σ' Γ'ᴹ | []'ᵣᴹ B σ' Γ'ᴹ = refl
[]'ᵣᴹ (∀' A)  σ' Γ'ᴹ =
  *ᴹ≡'
  (λ Γ → Π-≡-i refl λ Σ' → Π-≡-i refl λ Σ → Π-≡-i refl λ δ' → Π-≡ refl λ δ → Π-≡ refl λ Bᴹ →
    (_$ᴾ Σ) & []'ᵣᴹ A (keep σ') (Γ'ᴹ , Bᴹ) )
  (λ {Γ'}{Γ}{Δ'}{Δ}{δ'} δ α β p → exti≃' λ Ξ' → exti≃' λ Ξ → exti≃' λ ν' → ext≃' λ ν → ext≃' λ Bᴹ
  → 
  let α' : ∀ {Ξ' Ξ ν'} → Ren {Ξ'}{Γ'} ν' Ξ Γ → ∀ Bᴹ → Tyᴹ (A [ keep σ' ]'ᵣ) (Γ'ᴹ , Bᴹ) $ᴾ Ξ
      α' = α
  in {!!}
  )

ₛ∘'ᵣᴹ :
  ∀ {Γ Δ Σ}(σ : Sub' Δ Σ)(δ : Ren' Γ Δ)(Γᴹ : Con'ᴹ Γ)
  → Sub'ᴹ (σ ₛ∘'ᵣ δ) Γᴹ ≡ Sub'ᴹ σ (Ren'ᴹ δ Γᴹ)
ₛ∘'ᵣᴹ ∙       δ Γ'ᴹ = refl
ₛ∘'ᵣᴹ (σ , A) δ Γ'ᴹ = _,_ & ₛ∘'ᵣᴹ σ δ Γ'ᴹ ⊗ []'ᵣᴹ A δ Γ'ᴹ

id'ᴹ : ∀ {Γ} (Γᴹ : Con'ᴹ Γ) → Sub'ᴹ id'ₛ Γᴹ ≡ Γᴹ
id'ᴹ {∙}    ∙         = refl
id'ᴹ {Γ ,*} (Γᴹ , *ᴹ) =
  (_, *ᴹ) & (ₛ∘'ᵣᴹ id'ₛ wk' (Γᴹ , *ᴹ) ◾ Sub'ᴹ id'ₛ & id'ᵣᴹ Γᴹ ◾ id'ᴹ Γᴹ)

[]∈'ᴹ :
  ∀ {Γ Δ}(v : *∈ Γ)(σ : Sub' Δ Γ) Γᴹ
  → Tyᴹ (v [ σ ]∈') Γᴹ ≡ *∈ᴹ v (Sub'ᴹ σ Γᴹ)
[]∈'ᴹ vz     (σ , A) Γᴹ = refl
[]∈'ᴹ (vs v) (σ , A) Γᴹ = []∈'ᴹ v σ Γᴹ

[]'ᴹ :
  ∀ {Γ Δ}(A : Ty Γ)(σ : Sub' Δ Γ) Γᴹ
  → Tyᴹ (A [ σ ]') Γᴹ ≡ Tyᴹ A (Sub'ᴹ σ Γᴹ)
[]'ᴹ (var v) σ Γᴹ = []∈'ᴹ v σ Γᴹ
[]'ᴹ (A ⇒ B) σ Γᴹ rewrite []'ᴹ A σ Γᴹ | []'ᴹ B σ Γᴹ = refl
[]'ᴹ (∀' A)  σ Γᴹ = *ᴹ≡'
  (λ Γ → Π-≡-i refl λ Σ' → Π-≡-i refl λ Σ → Π-≡-i refl λ δ' → Π-≡ refl λ δ → Π-≡ refl λ Bᴹ →
      (_$ᴾ Σ) & []'ᴹ A (keep'ₛ σ) (Γᴹ , Bᴹ)
    ◾ (λ x → Tyᴹ A (x , Bᴹ) $ᴾ Σ) &
        (ₛ∘'ᵣᴹ σ wk' (Γᴹ , Bᴹ) ◾ Sub'ᴹ σ & id'ᵣᴹ Γᴹ))
  (λ δ α β p → exti≃' λ Ξ' → exti≃' λ Ξ → exti≃' λ δ' → ext≃' λ δ → ext≃' λ Bᴹ →
  {!!})

∈ᴹ :
  ∀ {Γ' Γ A} → _∈_ {Γ'} A Γ
  → (Γᴹ : Con'ᴹ Γ')
  → ∀ {Δ'}{Δ} → Conᴹ Γ Γᴹ {Δ'} Δ → Tyᴹ A Γᴹ $ᴾ Δ
∈ᴹ vz               Γ'ᴹ               (Γᴹ , α) = α
∈ᴹ (vs v)           Γ'ᴹ               (Γᴹ , _) = ∈ᴹ v Γ'ᴹ Γᴹ
∈ᴹ (vs* {A = A} v) (Γ'ᴹ , *ᴹ) {Δ'}{Δ} (Γᴹ ,*)  = 
  coe
      ((λ x → Tyᴹ A x $ᴾ Δ) & id'ᵣᴹ Γ'ᴹ ⁻¹
    ◾ (_$ᴾ Δ) & []'ᵣᴹ A wk' (Γ'ᴹ , *ᴹ) ⁻¹)
  (∈ᴹ v Γ'ᴹ Γᴹ)

Tmᴹ :
  ∀ {Γ' Γ A} → Tm {Γ'} Γ A
  → (Γ'ᴹ : Con'ᴹ Γ')
  → ∀ {Δ'}{Δ} → Conᴹ Γ Γ'ᴹ {Δ'} Δ → Tyᴹ A Γ'ᴹ $ᴾ Δ
Tmᴹ (var v)    Γ'ᴹ Γᴹ = ∈ᴹ v Γ'ᴹ Γᴹ
Tmᴹ (lam t)    Γ'ᴹ Γᴹ = λ σ aᴹ → Tmᴹ t Γ'ᴹ (Conᴹᵣ σ Γᴹ , aᴹ)
Tmᴹ (app f a)  Γ'ᴹ Γᴹ = Tmᴹ f Γ'ᴹ Γᴹ idᵣ (Tmᴹ a Γ'ᴹ Γᴹ)
Tmᴹ (tlam t)   Γ'ᴹ Γᴹ = λ σ Bᴹ → Tmᴹ t (Γ'ᴹ , Bᴹ) (Conᴹᵣ σ (Γᴹ ,*)) 
Tmᴹ (tapp {A} t B) Γ'ᴹ {Δ'} {Δ} Γᴹ =
   coe ((λ x → Tyᴹ A (x , Tyᴹ B Γ'ᴹ) $ᴾ Δ) & (id'ᴹ Γ'ᴹ ⁻¹)
     ◾ (_$ᴾ Δ) & []'ᴹ A (id'ₛ , B) Γ'ᴹ ⁻¹)
   (Tmᴹ t Γ'ᴹ Γᴹ idᵣ (Tyᴹ B Γ'ᴹ))

--------------------------------------------------------------------------------

-- qᴹ : ∀ {Γ' A} → (Γ'ᴹ : Con'ᴹ Γ') → ∀ {Δ'}{Δ : Con Δ'} → Tyᴹ {Γ'} A Γ'ᴹ $ᴾ Δ → Nf Δ (A [ {!!} ]'ᵣ)
-- qᴹ {A = var vz} (Γ'ᴹ , Aᴹ) n = {!!}
-- qᴹ {A = var (vs v)} Γ'ᴹ n = {!!}
-- qᴹ {A = A ⇒ B} Γ'ᴹ t = lam {!t (drop idᵣ) !}
-- qᴹ {A = ∀' A}  Γ'ᴹ t = tlam (qᴹ (Γ'ᴹ , {!!}) (t (drop' idᵣ) (con (λ {Γ'} Γ → Ne (Γ ,*) (var vz)) {!!})))

-- u∈ᴹ : ∀ {Γ'} (v : *∈ Γ') Γ'ᴹ → ∀ {Δ'}{Δ : Con Δ'} → *∈ᴹ v Γ'ᴹ $ᴾ Δ
-- u∈ᴹ vz     (Γ'ᴹ , Aᴹ) = {!!}
-- u∈ᴹ (vs v) (Γ'ᴹ , _)  = u∈ᴹ v Γ'ᴹ

-- uᴹ : ∀ {Γ'}{A : Ty Γ'} → ∀ {Δ' Δ} → Ne {Δ'} Δ {!!} → Tyᴹ {!!} {!!} $ᴾ Δ
-- uᴹ = {!!}

-- uᴹ : ∀ {Γ' Γ A} Γ'ᴹ → Ne {Γ'} Γ A → ∀ {Δ'}{Δ : Con Δ'} → Tyᴹ A Γ'ᴹ $ᴾ Δ
-- uᴹ {A = var vz} (Γ'ᴹ , Aᴹ) n = {!!}
-- uᴹ {A = var (vs v)} Γ'ᴹ n = {!!}
-- uᴹ {A = A ⇒ B} Γ'ᴹ n = λ σ Aᴹ → {!!}
-- uᴹ {A = ∀' A}  Γ'ᴹ n = λ σ Bᴹ → {!!}







