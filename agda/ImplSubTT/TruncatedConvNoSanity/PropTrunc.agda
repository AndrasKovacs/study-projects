
{-# OPTIONS --without-K --rewriting #-}

module PropTrunc where
open import Lib

private
  postulate
      _⊢>_ : ∀ {α}{A : Set α} → A → A → Set α
  {-# BUILTIN REWRITE _⊢>_ #-}

postulate
  ∣_∣   : ∀ {α} → Set α → Set α
  embed : ∀ {α}{A : Set α} → A → ∣ A ∣
  trunc : ∀ {α}{A : Set α}(x y : ∣ A ∣) → x ≡ y
  ∣∣-rec :
    ∀ {α β}{A : Set α}{P : Set β}
    → (A → P) → ((x y : P) → x ≡ y) → ∣ A ∣ → P

postulate
  ∣∣-rec-embed :
    ∀ {α β A P embedᴾ truncᴾ a} → ∣∣-rec {α}{β}{A}{P} embedᴾ truncᴾ (embed a) ⊢> embedᴾ a
{-# REWRITE ∣∣-rec-embed #-}

postulate
  ∣∣-rec-trunc :
    ∀ {α β A P embedᴾ truncᴾ x y}
    → (∣∣-rec {α}{β}{A}{P} embedᴾ truncᴾ & (trunc x y))
    ≡ truncᴾ (∣∣-rec embedᴾ truncᴾ x) (∣∣-rec embedᴾ truncᴾ y)
