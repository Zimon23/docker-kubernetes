#!/bin/bash

#master 에 등록한다 (아래 참조 : 실제 master1에서 kubeadm init 실행 결과 로 출력된 token 사용 실행 할 것)
#kubeadm join lb.example.com:6443 --token ntrvyj.q88z2kbpu3qaqlgz \
#        --discovery-token-ca-cert-hash sha256:e9882036587ca38377582d125eeb4338aa1a718d08bf9e0532e3acb5cf7a2776
#

#윈도우에서 개인인증서로 사전에 복사 .ssh에 복사하고 진행한다 
#scp -r ~/.ssh kosa@worker1:~/.ssh
#scp -r ~/.ssh kosa@worker2:~/.ssh
# worker node에서 kubectl 명령실행 할 수 있게 설정하는 방법 
mkdir -p $HOME/.kube
scp kosa@master:~/.kube/config $HOME/.kube/config



