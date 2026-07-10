Dear temen-temen @IDA DATA,

Mau sharing terkait overview pipeline **Application Mapping**, use case-nya untuk maintain app taxonomy + persona catalog yang jadi source of truth (SSOT) dan dipakai di beberapa stored procedure serta dashboard **SDA platform**.

Berikut summary terkait **pipeline App Catalog Sync (rnr_app_category_v2)**.

Pipeline ini menyatukan app taxonomy, tags, dan persona mapping ke dalam satu **BigQuery SSOT table (full refresh setiap DAG run)**, yaitu `data-int-advana-prd-77c3.core_analytics.rnr_app_category_v2`.

## Workflow
Workflow dijalankan oleh Airflow DAG `app_catalog_sync` (manual trigger by default, Cloud Composer). Alurnya:

1. **Source of truth:** `rnr_app_category_v2.csv` di GitLab — kolom `app_name`, `sig_app_tags`, `nio_aggr_app_tags`, `category`, `subcategory`, `description`, dan `persona` (multi-value pakai pipe `|`).
2. **Upload to GCS:** CSV yang sudah di-commit di-upload ke `gs://create_gcs_table/app-category-mapping/rnr_app_category_v2.csv`.
3. **DAG `app_catalog_sync`:** baca CSV dari GCS → parse pipe-separated fields → **full `WRITE_TRUNCATE` load** ke `rnr_app_category_v2`, sekaligus derive taxonomy snapshot ke `rnr_taxonomy_reference` (date-partitioned, idempotent per hari).
4. **Downstream consumption:** beberapa SP di SDA platform (lihat appendix) join ke SSOT ini untuk enrichment app category/persona.

Rencana awalnya, step 2 ini mau di-automate — baik lewat **GitLab runner** (auto-upload CSV ke GCS tiap commit) maupun **Airflow/Composer baca langsung dari GitLab repo** — tapi keduanya masih ada error/blocker di sisi akses (WIF service account ke GCS belum confirmed jalan, dan Composer belum punya akses baca ke repo GitLab-nya). Jadi untuk sekarang, step upload ke GCS itu **masih manual**.

Untuk maintenance-nya sendiri, ada 2 hal utama yang wajib diingat *(detilnya attached di akhir email)*:

- Edit CSV di GitLab, **gunakan format pipe-separated (`|`)** untuk multi-value field — bukan bracket/koma.
- Setiap DAG run itu **full replace** — jangan edit BQ table manual, karena akan ke-overwrite di run berikutnya.

## Final Output
Hasil akhirnya adalah satu **app taxonomy + persona SSOT table** (`rnr_app_category_v2`, ~1.200 apps) plus turunan taxonomy reference table, yang berisi app_name, tags, category/subcategory, description, dan persona mapping.

Dengan output ini, klasifikasi aplikasi dan persona subscriber bisa konsisten dipakai lintas SP dan dashboard — nggak perlu define ulang mapping app→category di tiap pipeline.

> **Note:** Untuk automasi discovery app baru (AI research + approval flow) itu project terpisah, ada di `DS-IOH-SDA-Application-Mapping-Automation`. Repo ini fokusnya khusus di catalog/taxonomy table-nya aja (`rnr_app_category_v2`).

## Kenapa Tim Perlu Tau?

- **Ini SSOT** untuk semua app category/persona classification — kalau butuh mapping app baru untuk SP/dashboard lain, join ke `rnr_app_category_v2` dulu, jangan bikin mapping sendiri.
- Dipakai langsung di **SDA platform**: dashboard engagement mingguan (`bq_sp_dashboard_data_table_weekly`, `bq_sp_3ID_dashboard_data_table_weekly`) untuk `app_group_name` enrichment, persona classification SP (`bq_sp_national_stg_nio_appsrtgout_usecase_weekly`), dan validation SP (`bq_sp_validate_els_union`) untuk cek app name match rate.
- Step upload CSV ke GCS **masih manual** karena rencana automation-nya (GitLab runner atau Composer baca GitLab langsung) masih kena error akses — kalau ada yang mau bantu benerin WIF/akses GitLab, kabar-kabari.
- **Kedepannya** flow ini mau di-explore lagi supaya lebih gampang di-maintain (misalnya benerin salah satu automation path di atas), jadi nggak bolak-balik manual upload tiap ada update CSV.

Semoga dapat dipahami dan bisa digunakan kedepannya jika dibutuhkan.
Jika ada yang kurang jelas boleh langsung tanyakan aja yaa.

---

## Appendix

## SP / Table / Object yang Digunakan

| Layer | Object | Dipakai untuk |
|---|---|---|
| Source - GitLab CSV | `rnr_app_category_v2.csv` | App catalog SSOT: app_name, tags, category, subcategory, description, persona. |
| GCS Landing | `gs://create_gcs_table/app-category-mapping/rnr_app_category_v2.csv` | Landing path sebelum di-load ke BigQuery oleh DAG `app_catalog_sync`. |
| BigQuery SSOT | `data-int-advana-prd-77c3.core_analytics.rnr_app_category_v2` | Final app catalog table, full `WRITE_TRUNCATE` tiap DAG run. |
| BigQuery Derived | `data-int-advana-prd-77c3.core_analytics.rnr_taxonomy_reference` | Auto-derived taxonomy snapshot, date-partitioned by `taxonomy_version`. |
| Downstream SP (persona) | `bq_sp_national_stg_nio_appsrtgout_usecase_weekly` | Build app→persona mapping dari SSOT, klasifikasi 18 persona subscriber mingguan. |
| Downstream SP (SDA dashboard) | `bq_sp_dashboard_data_table_weekly`, `bq_sp_3ID_dashboard_data_table_weekly` | Join `sig_app_tags` → `subcategory` untuk `app_group_name` enrichment di dashboard engagement mingguan SDA platform. |
| Downstream SP (validation) | `bq_sp_validate_els_union` | Data quality check: app name match rate terhadap `rnr_app_category_v2`. |

## DAG / Pipeline Files

| DAG / File | Role |
|---|---|
| `dags/app_catalog_sync.py` | Sync CSV dari GCS ke BigQuery (full refresh) + derive taxonomy snapshot. Manual trigger by default. |
| `stored_procedures/bq_sp_national_stg_nio_appsrtgout_usecase_weekly.sql` | Weekly persona classification SP, baca kolom `persona` dari SSOT. |
| `bq_sp_dashboard_data_table_weekly.sql` / `bq_sp_3ID_dashboard_data_table_weekly.sql` (data-pipeline repo) | Bagian dari SDA weekly pipeline DAGs (`dev_df_sda_weekly_pipeline`, `df_sda_weekly_pipeline_rerun`, `df_sda_weekly_pipeline_test`) — dashboard engagement mingguan. |
| `bq_sp_validate_els_union.sql` (data-pipeline repo) | Validation SP untuk union `stg_nio_appsrtgout` & `Els_smartcare_x_crawling_enriched`, termasuk app match rate ke SSOT. |

Thank you.
