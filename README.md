# CareLoop Clinics: No-Show Guard

**GitHub Repository:** `https://github.com/Glaze0/CareLoop-Clinics-No-Show-Guard.git`

An end-to-end data analytics, machine learning, and generative AI solution designed to identify high-risk outpatient appointments, uncover root causes of patient no-shows, and provide actionable front-desk interventions across CareLoop Clinics' eight locations in India.

---

## 📊 Executive Summary (4-Line Overview)

* **Part 1 (Data Foundations):** Cleaned 1,020 raw booking records down to 990 valid appointments (218 total no-shows, a 22.0% overall rate), capping 26 distance outliers and 3 fee entry errors while enriching all 8 clinics with live Open-Meteo temperature data.
* **Part 2 (SQL Analytics):** Revealed that no-show rates surge with booking lead time—jumping from 16.2% for 1–7 days to 60.5% for 31+ days—and identified Hadapsar Care Centre (Pune, 27.3%) and Malviya Nagar Clinic (Jaipur, 26.8%) as top high-volume hotspots.
* **Part 3 (Machine Learning):** Selected a Logistic Regression model (5-fold CV ROC-AUC $\approx 0.77$; Test ROC-AUC $\approx 0.79$) tuned to a 0.35 probability threshold, catching $\approx 57\%$ of test no-shows (recall) by flagging $\approx 49$ high-risk bookings.
* **Part 4 (GenAI Follow-Up Review):** Extracted structured root causes from call-centre notes using Gemini-3.5-flash-lite and Pydantic validation, confirming that 100% (2 of 2) of `forgot_or_no_reminder` cases occurred when no reminder was sent (`reminder_sent = No`).

---

## 💡 Business Recommendation

To immediately reduce the 22.0% no-show rate and recover lost doctor slots, CareLoop Clinics should deploy the **Logistic Regression risk model at a 0.35 threshold** to flag the top ~25% riskiest appointments (roughly 49 bookings per 198-appointment cycle) for proactive evening-before phone calls by the front desk. Priority should be placed on bookings made **15+ days in advance**—especially the **31+ day segment which suffers a 60.5% no-show rate**—as well as high-volume clinics exceeding the network average, such as **Hadapsar Care Centre (27.3%)** and **Malviya Nagar Clinic (26.8%)**. Furthermore, because appointments with a reminder show ~69% lower odds of a no-show (and GenAI note analysis confirms forgotten visits happen exclusively when reminders are missing), management should immediately automate SMS/WhatsApp reminders for all bookings and require front-desk verification calls for high-risk leads.

---

## 🤖 Model Selection & Threshold Rationale

* **Chosen Model:** **Logistic Regression** (wrapped in a `StandardScaler` pipeline).
* **Why It Was Chosen:** Evaluated strictly via 5-fold cross-validation on the training set (792 rows) without touching the test set, Logistic Regression achieved the highest mean **CV ROC-AUC ($\approx 0.77$)**, outperforming the depth-3 Decision Tree ($\approx 0.68$), default Random Forest ($\approx 0.75$), and matching/exceeding the GridSearchCV-tuned Random Forest ($\approx 0.77$) while offering superior coefficient interpretability and test generalization (**Test ROC-AUC $\approx 0.79$**).
* **Chosen Threshold (`0.35`):** Using out-of-fold training probabilities, lowering the classification threshold from the default `0.50` to **`0.35`** boosted training recall from $\approx 0.25$ to $\approx 0.47$ and improved the F1-score from $\approx 0.35$ to $\approx 0.49$. In clinical operations, a false negative (an empty doctor slot) is far costlier than a false positive (a one-minute reminder call), making higher recall essential.

---

## ⚠️ Methodological & Data Limitations

1. **Pre-Split Data Leakage in Cleaning:** Median imputations and IQR outlier fences were computed across all 990 rows prior to the train/test split, allowing test-set distributions to slightly influence training transformations. In production, all transformers must be fit strictly on training folds.
2. **Observational Data vs. Causality:** Because the booking dataset is observational rather than a randomized controlled trial, model coefficients (such as the negative association between `reminder_sent` and `no_show`) indicate correlation holding other variables constant, not guaranteed causal proof.
3. **Small GenAI Sample & Random Split Structure:** The 10 call-centre notes analyzed via Gemini serve as a pipeline demonstration rather than a statistically representative sample of all 218 no-shows. Additionally, using a single random train/test split allows repeat patients to appear in both sets and does not simulate true chronological (past-to-future) deployment.

---

## 📁 Repository Structure

```text
├── data/
│   ├── appointments.csv          # Raw booking export (1,020 rows)
│   ├── clinics.csv               # Master clinic metadata (8 clinics)
│   └── followup_notes.csv        # Raw call-centre follow-up notes (30 rows)
├── 01_ingest_clean.ipynb         # Part 1: CSV parsing, Pandas cleaning, NumPy stats, Open-Meteo API & SQL export
├── 02_queries.sql                # Part 2: Schema DDL, analytical SQL queries (CTEs, window functions) & error log
├── 03_model.ipynb                # Part 3: Feature engineering, baseline, model comparison, CV tuning & test scoring
├── 04_genai.ipynb                # Part 4: Gemini Flash CRAFT prompting, Pydantic validation, stress-testing & crosstab
├── appointments_clean.csv        # Cleaned, validated dataset (990 rows, 16 columns)
├── clinics_enriched.csv          # Clinic metadata enriched with Open-Meteo temperature_2m
├── load_data.sql                 # Generated SQL INSERT script (8 clinics + 990 appointments)
├── rejected_rows.json            # 32 rows rejected during strict type-casting in Task 1.1
├── test_risk_scores.csv          # Out-of-sample test predictions & flags at 0.35 threshold (198 rows)
├── notes_analysed.csv            # Structured GenAI outputs & Pydantic validation statuses (10 rows)
└── README.md                     # Project summary, recommendations, model rationale & limitations
```

---

## 🛠️ Tech Stack

* **Python 3:** `pandas`, `numpy`, `requests`, `json`, `csv`
* **Database / SQL:** MySQL / SQLite (CTEs, `RANK()`, `LAG()`, `CASE WHEN`, scalar subqueries)
* **Machine Learning:** `scikit-learn` (`Pipeline`, `StandardScaler`, `LogisticRegression`, `DecisionTreeClassifier`, `RandomForestClassifier`, `GridSearchCV`, `cross_val_score`, `cross_val_predict`)
* **Generative AI & Validation:** `google-genai` (Gemini Flash), `pydantic` (`BaseModel`, `Field`, `ValidationError`)
