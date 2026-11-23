# Changelog

## 1.9.11-1 (2026-11-23)

First release.

* PDFMathTranslate 1.9.11, official image `byaidu/pdf2zh:1.9.11@sha256:8e083ecbeb3f22dcbe0e8365e78ed2d776c3881221ebcf9d526df6db621fef9b`.
* Web UI behind a login (`admin` and a generated `WEB_PASSWORD`).
* Settings, translation cache and files on the `/data` volume.
* Lower memory use: one shared single-threaded layout-model session (idle ~256 MB instead of ~690 MB). Real papers still need about 1 GB of RAM.
* Bing is the preselected translation service (Google's free endpoint answers 429 to Railway's IP addresses).
