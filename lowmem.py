"""Start pdf2zh with lower memory use, for small Railway plans.

pdf2zh 1.9.11 and BabelDOC each load the same 75 MB document-layout ONNX
model into their own onnxruntime session, through onnx.load() and
SerializeToString(), with one thread per host core. That idles at ~690 MB and
is OOM-killed at 0.5 GB. Here both share one session, loaded straight from the
model file with ORT_NUM_THREADS threads (default 1), and freed heap memory is
handed back to the OS.

It also preselects PDF2ZH_DEFAULT_SERVICE (default "Bing") in the web UI's
Service list: Google's free endpoint often answers 429 to cloud IP addresses.
Behaviour is otherwise unchanged.
"""
import ast
import ctypes
import os
import sys
import threading
import time

import onnxruntime as ort

_lock = threading.Lock()
_sessions = {}

try:
    _libc = ctypes.CDLL("libc.so.6")
except OSError:  # pragma: no cover
    _libc = None


def trim():
    if _libc is not None:
        try:
            _libc.malloc_trim(0)
        except Exception:
            pass


def shared_session(model_path):
    key = os.path.realpath(os.fspath(model_path))
    with _lock:
        sess = _sessions.get(key)
        if sess is None:
            opts = ort.SessionOptions()
            opts.intra_op_num_threads = max(int(os.environ.get("ORT_NUM_THREADS", "1") or "1"), 1)
            opts.inter_op_num_threads = 1
            providers = [p for p in ort.get_available_providers() if p == "CPUExecutionProvider"]
            sess = ort.InferenceSession(key, opts, providers=providers or None)
            _sessions[key] = sess
            trim()
    return sess


def patched_init(self, model_path):
    self.model_path = model_path
    self.model = shared_session(model_path)
    meta = self.model.get_modelmeta().custom_metadata_map
    self._stride = ast.literal_eval(meta["stride"])
    self._names = ast.literal_eval(meta["names"])


def default_service():
    """Preselect PDF2ZH_DEFAULT_SERVICE in the UI's Service dropdown."""
    wanted = os.environ.get("PDF2ZH_DEFAULT_SERVICE", "Bing").strip().lower()
    if not wanted:
        return
    try:
        import gradio as gr
        import pdf2zh.gui as gui

        for block in gui.demo.blocks.values():
            if isinstance(block, gr.Dropdown) and block.label == "Service":
                for choice in block.choices:
                    value = choice[1] if isinstance(choice, (tuple, list)) else choice
                    if str(value).lower() == wanted:
                        block.value = value
                        print(f"Default translation service: {value}", flush=True)
                        return
    except Exception as exc:  # never block startup
        print(f"Could not set the default service: {exc}", flush=True)


def install():
    import babeldoc.docvision.doclayout as bd
    import pdf2zh.doclayout as pd

    bd.OnnxModel.__init__ = patched_init
    pd.OnnxModel.__init__ = patched_init

    interval = int(os.environ.get("PDF2ZH_TRIM_INTERVAL", "15") or "15")

    def loop():
        while True:
            time.sleep(interval)
            trim()

    threading.Thread(target=loop, name="malloc-trim", daemon=True).start()


if __name__ == "__main__":
    if os.environ.get("PDF2ZH_LOWMEM", "1") != "0":
        install()
    default_service()
    from pdf2zh.pdf2zh import main

    sys.argv[0] = "pdf2zh"
    sys.exit(main())
