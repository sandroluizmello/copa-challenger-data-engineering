"""
Treina o modelo de classificação de resultado (HOME_WIN / DRAW / AWAY_WIN).

IMPORTANTE - Split temporal, não aleatório:
Um split aleatório (train_test_split embaralhado) deixaria partidas de
Copas recentes no treino e partidas de Copas antigas no teste, o que não
faz sentido para um problema com componente temporal - na vida real,
você sempre prevê o futuro a partir do passado, nunca o contrário.
Por isso, treinamos nas Copas mais antigas e testamos nas mais recentes.
"""

import joblib
import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, classification_report, log_loss
from sklearn.preprocessing import StandardScaler

from data_prep import FEATURE_COLUMNS, build_training_dataset

MODELS_DIR = "models"
TEST_WORLD_CUPS = 3  # últimas N Copas viram o conjunto de teste


def time_based_split(df: pd.DataFrame):
    world_cups = sorted(df["world_cup_id"].unique())
    test_cups = set(world_cups[-TEST_WORLD_CUPS:])

    train_df = df[~df["world_cup_id"].isin(test_cups)]
    test_df = df[df["world_cup_id"].isin(test_cups)]

    print(f"📅 Treino: Copas {world_cups[0]}–{sorted(train_df['world_cup_id'].unique())[-1]} "
          f"({len(train_df)} partidas)")
    print(f"📅 Teste:  Copas {sorted(test_cups)} ({len(test_df)} partidas)")

    return train_df, test_df


def evaluate(model, scaler, X_test, y_test, name: str):
    X_test_scaled = scaler.transform(X_test)
    y_pred = model.predict(X_test_scaled)
    y_proba = model.predict_proba(X_test_scaled)

    acc = accuracy_score(y_test, y_pred)
    ll = log_loss(y_test, y_proba, labels=model.classes_)

    print(f"\n{'=' * 60}\n{name}\n{'=' * 60}")
    print(f"Acurácia: {acc:.3f}  |  Log Loss: {ll:.3f}")
    print(classification_report(y_test, y_pred, zero_division=0))

    return acc, ll


def main():
    df = build_training_dataset()
    train_df, test_df = time_based_split(df)

    X_train, y_train = train_df[FEATURE_COLUMNS], train_df["result"]
    X_test, y_test = test_df[FEATURE_COLUMNS], test_df["result"]

    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)

    # --- Baseline: sempre prever a classe majoritária (DRAW normalmente
    # não é a maioria no futebol - HOME_WIN costuma ser mais comum) ---
    majority_class = y_train.value_counts().idxmax()
    baseline_acc = (y_test == majority_class).mean()
    print(f"\n📏 Baseline (sempre prever '{majority_class}'): {baseline_acc:.3f} de acurácia")
    print("   Qualquer modelo precisa superar isso para agregar valor real.")

    # --- Modelo 1: Regressão Logística (simples, interpretável) ---
    log_reg = LogisticRegression(max_iter=1000, class_weight="balanced")
    log_reg.fit(X_train_scaled, y_train)
    acc_lr, ll_lr = evaluate(log_reg, scaler, X_test, y_test, "Regressão Logística")

    # --- Modelo 2: Random Forest (captura não-linearidades) ---
    rf = RandomForestClassifier(
        n_estimators=300,
        max_depth=5,
        min_samples_leaf=20,
        class_weight="balanced",
        random_state=42,
    )
    rf.fit(X_train_scaled, y_train)
    acc_rf, ll_rf = evaluate(rf, scaler, X_test, y_test, "Random Forest")

    # Escolhe o melhor modelo por log-loss (mede qualidade das
    # PROBABILIDADES, não só do acerto - importante já que o objetivo
    # final é mostrar probabilidade de vitória, não só o rótulo)
    if ll_lr <= ll_rf:
        best_model, best_name = log_reg, "logistic_regression"
    else:
        best_model, best_name = rf, "random_forest"

    print(f"\n🏆 Melhor modelo: {best_name}")

    print("\n📊 Importância das features:")
    if hasattr(best_model, "feature_importances_"):
        importances = best_model.feature_importances_
    else:
        importances = np.abs(best_model.coef_).mean(axis=0)
    for feat, imp in sorted(zip(FEATURE_COLUMNS, importances), key=lambda x: -x[1]):
        print(f"   {feat}: {imp:.3f}")

    import os
    os.makedirs(MODELS_DIR, exist_ok=True)
    joblib.dump(best_model, f"{MODELS_DIR}/result_model.joblib")
    joblib.dump(scaler, f"{MODELS_DIR}/result_scaler.joblib")
    joblib.dump(FEATURE_COLUMNS, f"{MODELS_DIR}/result_features.joblib")

    print(f"\n💾 Modelo salvo em {MODELS_DIR}/result_model.joblib")
    print(
        "\n⚠️  Aviso honesto: com ~964 partidas em 22 Copas, o dataset é "
        "pequeno para ML. O modelo capta sinais reais (ex: seleções "
        "historicamente mais fortes tendem a vencer mais), mas está longe "
        "de ter precisão de nível profissional. Trate como exercício "
        "exploratório de portfólio, não como ferramenta de apostas."
    )


if __name__ == "__main__":
    main()