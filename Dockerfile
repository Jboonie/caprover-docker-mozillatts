FROM python:3.6 as build

ENV LANG C.UTF-8

RUN apt-get update && \
    apt-get install --yes --no-install-recommends \
        espeak libsndfile1 git

RUN mkdir -p /app
RUN cd /app && \
    git clone https://github.com/Jboonie/TTS && \
    cd TTS && \
    git checkout 19a9529

RUN cd /app/TTS && \
    python3 -m venv .venv

RUN cd /app/TTS && \
    .venv/bin/pip3 install --upgrade pip && \
    .venv/bin/pip3 install -r requirements.txt && \
    .venv/bin/python3 setup.py install

# Extra packages missing from requirements
RUN cd /app/TTS && \
    .venv/bin/pip3 install inflect 'numba==0.48'

# Packages needed for web server
RUN cd /app/TTS && \
    .venv/bin/pip3 install 'flask' 'flask-cors'
# -----------------------------------------------------------------------------

FROM python:3.6 as data

RUN pip install gdown
RUN mkdir -p /app
RUN mkdir -p /app/model && \
    cd /app/model && \
    gdown --id 1dntzjWFg7ufWaTaFy80nRz-Tu02xWZos -O checkpoint_130000.pth.tar && \
    gdown --id 18CQ6G6tBEOfvCHlPqP8EBI4xWbrr9dBc -O config.json && \
    cd ..

RUN mkdir -p /app/vocoder && \
    cd /app/vocoder && \
    gdown --id 1Ty5DZdOc0F7OTGj9oJThYbL5iVu_2G0K -O checkpoint_1450000.pth.tar && \
    gdown --id 1Rd0R_nRCrbjEdpOwq6XwZAktvugiBvmu -O config.json

# -----------------------------------------------------------------------------

FROM python:3.6-slim

RUN apt-get update && \
    apt-get install --yes \
        espeak libsndfile1

COPY --from=build /app/TTS/.venv/ /app/
COPY --from=data /app/vocoder/ /app/vocoder/
COPY --from=data /app/model/ /app/model/
COPY templates/ /app/templates/
COPY tts.py scale_stats.npy /app/

WORKDIR /app

EXPOSE 5002

ENTRYPOINT ["/app/bin/python3", "/app/tts.py"]