[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/pdfmathtranslate-1?utm_medium=integration&utm_source=button&utm_campaign=pdfmathtranslate)

# Deploy and Host PDFMathTranslate on Railway

PDFMathTranslate (pdf2zh) translates scientific PDFs while keeping the original layout: formulas, charts, tables, the table of contents and annotations stay in place. It writes a translated-only PDF and a side-by-side bilingual PDF. It works with free Bing translation out of the box, or with your own LLM or translation API key.

## About Hosting PDFMathTranslate

This template runs the official PDFMathTranslate 1.9.11 image (pinned by digest) with its Gradio web UI, behind a login. The username is `admin`, and the password is generated at deploy time: open the service's Variables tab and copy `WEB_PASSWORD`. A Railway volume at `/data` keeps saved settings, API keys you enter in the UI, the translation cache and recent files, so a redeploy or restart loses nothing. The document-layout model and fonts are baked into the image, so nothing is downloaded at runtime. Translation runs on CPU, since Railway has no GPU. Plan for 1 GB of RAM: the service starts in 0.5 GB and translates short documents there, but layout detection on a full research paper peaks at about 650 MB.

## Common Use Cases

* Read English research papers in Chinese, Japanese, German, French and more, with the math intact
* Share bilingual PDFs of papers and technical documents with a team
* Translate PDFs with your own OpenAI, DeepSeek, Gemini, Ollama or other LLM key for better quality

## Dependencies for PDFMathTranslate Hosting

* PDFMathTranslate 1.9.11 (official `byaidu/pdf2zh` image, built from our GitHub repo)
* A Railway volume for settings, cache and files

### Deployment Dependencies

* Source and update notes: https://github.com/aalfath/pdfmathtranslate-railway-template
* Upstream project: https://github.com/PDFMathTranslate/PDFMathTranslate

### Implementation Details

One service, `pdfmathtranslate`, serves the web UI on Railway's public domain. After deploy:

1. Open the public URL and sign in as `admin` with the `WEB_PASSWORD` value from the Variables tab.
2. Upload a PDF, pick the languages and press Translate. The Service list starts on Bing, which needs no key. Google is also listed, but its free endpoint often answers 429 to cloud servers such as Railway, and the translation then stalls; use Bing or an API key instead.
3. To use an LLM, pick it in the Service list and enter its API key in the UI (it is saved on the volume), or set it as a service variable, for example `OPENAI_API_KEY`, `OPENAI_BASE_URL` and `OPENAI_MODEL` for any OpenAI-compatible API.

Variables: `WEB_PASSWORD` (generated login password), `WEB_USERNAME` (default `admin`), `PDF2ZH_DEFAULT_SERVICE` (service preselected in the UI, default `Bing`), `PDF2ZH_KEEP_DAYS` (days to keep uploaded and translated files, default 7). Change the password by editing `WEB_PASSWORD` and redeploying.

RAM: tested on Railway, a 3-page arXiv paper took 91 s and peaked at about 650 MB, so give the service 1 GB (Hobby plan or higher). On a 0.5 GB service the UI runs, but a real paper is stopped for lack of memory; the template then exits non-zero and Railway restarts it. Updates: when we bump the version in the template's GitHub repo, Railway shows an update notice in your project; read the repo's CHANGELOG.md, then apply it.

## Why Deploy PDFMathTranslate on Railway?

<!-- Recommended: Keep this section as shown below -->
Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying PDFMathTranslate on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
<!-- End recommended section -->

## Repository layout

* `Dockerfile`: `FROM byaidu/pdf2zh:1.9.11@sha256:8e083ecbeb3f22dcbe0e8365e78ed2d776c3881221ebcf9d526df6db621fef9b` plus the two files below
* `start.sh`: checks `WEB_PASSWORD`, links settings, cache and files onto `/data`, writes the login file, starts the web UI on `$PORT` and exits non-zero on any unexpected stop
* `lowmem.py`: starts `pdf2zh` with one shared, single-threaded layout-model session (upstream loads the same model twice with one thread per host core, which idles at ~690 MB) and returns freed memory to the OS (set `PDF2ZH_LOWMEM=0` to turn that off), and preselects `PDF2ZH_DEFAULT_SERVICE` in the Service list

Railway settings used by the template: health check path `/` (the login page, answers 200 without signing in), restart policy on failure, volume at `/data`.

## Licence

PDFMathTranslate is AGPL-3.0. The wrapper files in this repository are offered under the same licence.
