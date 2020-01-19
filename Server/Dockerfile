FROM swift:5.1.3

RUN mv /usr/lib/python2.7/site-packages /usr/lib/python2.7/dist-packages; ln -s dist-packages /usr/lib/python2.7/site-packages

RUN apt-get update
RUN apt-get install -y openssl libssl-dev clang libicu-dev libcurl4-openssl-dev

RUN mkdir /app
ADD . /app
WORKDIR /app

RUN swift build -c release

CMD [".build/release/InformatiCUP", "-m", "predict"]


