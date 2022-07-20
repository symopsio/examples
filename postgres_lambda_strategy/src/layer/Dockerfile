FROM lambci/lambda:build-python3.8

COPY ./requirements.txt /var/lambda-requirements.txt

RUN pip install -t /opt/python/ -r /var/lambda-requirements.txt

WORKDIR /var/task
