FROM python:3.12-slim
WORKDIR /opt/aip
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
RUN python - <<'PY'
import hashlib, io, urllib.request, zipfile
url = 'https://marsad-integrity.floot.app/_cdn/static/5416a25e-0ddf-4c19-9ecc-0b49dc0de6d6-aip-source-v0.3.0.zip'
expected = '40f47798d8282cc0517455b2b31d08e193ec5958bf9f454d2658eb8747565aec'
with urllib.request.urlopen(url, timeout=90) as r:
    data = r.read()
if hashlib.sha256(data).hexdigest() != expected:
    raise RuntimeError('Source artifact checksum mismatch')
with zipfile.ZipFile(io.BytesIO(data)) as z:
    for x in z.namelist():
        if x.startswith('/') or '..' in x.split('/'):
            raise RuntimeError('Unsafe archive member')
    z.extractall('/opt/aip')
PY
RUN python -m pip install --no-cache-dir -r requirements.txt
RUN useradd --uid 10001 --create-home --shell /usr/sbin/nologin aip && mkdir -p /opt/aip/data && chown -R aip:aip /opt/aip
USER aip
EXPOSE 10000
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-10000} --proxy-headers"]