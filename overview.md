# Deploy and Host PDFMathTranslate on Railway

PDFMathTranslate (pdf2zh) translates scientific PDFs while keeping the original layout: formulas, charts, tables, the table of contents and annotations stay in place. It writes a translated-only PDF and a side-by-side bilingual PDF. It works with free Google or Bing translation, or with your own LLM or translation API key.

## About Hosting PDFMathTranslate

This template runs the official PDFMathTranslate 1.9.11 image (pinned by digest) with its Gradio web UI, behind a login. The username is `admin`, and the password is generated at deploy time: open the service's Variables tab and copy `WEB_PASSWORD`. A Railway volume at `/data` keeps saved settings, API keys you enter in the UI, the translation cache and recent files, so a redeploy or restart loses nothing. The document-layout model and fonts are baked into the image, so nothing is downloaded at runtime. The app is tuned to start in 0.5 GB of RAM; 1 GB is more comfortable for large PDFs. Translation runs on CPU, since Railway has no GPU.

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
2. Upload a PDF, pick the languages and a service, and press Translate. Google and Bing need no key.
3. To use an LLM, pick it in the Service list and enter its API key in the UI (it is saved on the volume), or set it as a service variable, for example `OPENAI_API_KEY`, `OPENAI_BASE_URL` and `OPENAI_MODEL` for any OpenAI-compatible API.

Variables: `WEB_PASSWORD` (generated login password), `WEB_USERNAME` (default `admin`), `PDF2ZH_KEEP_DAYS` (days to keep uploaded and translated files, default 7). Change the password by editing `WEB_PASSWORD` and redeploying.

Uploaded files are limited only by memory: on a 0.5 GB service, translate long papers in page ranges or raise the RAM. The template wraps the app so a crash exits non-zero and Railway restarts it. Updates: when we bump the version in the template's GitHub repo, Railway shows an update notice in your project; read the repo's CHANGELOG.md, then apply it.

## Why Deploy PDFMathTranslate on Railway?

<!-- Recommended: Keep this section as shown below -->
Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying PDFMathTranslate on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
<!-- End recommended section -->
