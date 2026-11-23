# PDFMathTranslate v1.9.11 (official image, pinned by version and digest)
FROM byaidu/pdf2zh:1.9.11@sha256:8e083ecbeb3f22dcbe0e8365e78ed2d776c3881221ebcf9d526df6db621fef9b

# Small-plan defaults: keep math/ONNX thread pools to the service's CPUs
ENV OMP_NUM_THREADS=1 \
    OPENBLAS_NUM_THREADS=1 \
    MKL_NUM_THREADS=1 \
    ORT_NUM_THREADS=1 \
    MALLOC_ARENA_MAX=2 \
    GRADIO_ANALYTICS_ENABLED=False \
    PDF2ZH_DATA_DIR=/data \
    PORT=7860

COPY lowmem.py /usr/local/lib/pdf2zh-railway/lowmem.py
COPY start.sh /usr/local/bin/start.sh
RUN chmod 0755 /usr/local/bin/start.sh

EXPOSE 7860
CMD ["/usr/local/bin/start.sh"]
