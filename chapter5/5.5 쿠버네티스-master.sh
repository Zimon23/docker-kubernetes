#!/bin/bash

# kubelet 드롭인(컨테이너 런타임/노드IP)
echo  -e "\nkubelet 드롭인(컨테이너 런타임/노드IP)"
sudo mkdir -p /etc/systemd/system/kubelet.service.d
cat <<'EOF' | sudo tee /etc/systemd/system/kubelet.service.d/10-cri.conf
[Service]
Environment="KUBELET_EXTRA_ARGS=--container-runtime-endpoint=unix:///run/containerd/containerd.sock"
EOF
MASTER_IP="$(hostname -I | awk '{print $1}')"   # 필요시 고정값으로 바꾸세요
cat <<EOF | sudo tee /etc/systemd/system/kubelet.service.d/20-nodeip.conf
[Service]
Environment="KUBELET_EXTRA_ARGS=\$KUBELET_EXTRA_ARGS --node-ip=${MASTER_IP}"
EOF
sudo systemctl daemon-reload
sudo systemctl restart kubelet


#1번 마스터 노드에서 초기화 실행하면서 LoadBalancer 등록 
echo  -e "\n1번 마스터 노드에서 초기화 실행하면서 LoadBalancer 등록"
sudo kubeadm init \
  --control-plane-endpoint "lb.example.com:6443" \
  --pod-network-cidr "192.168.0.0/16" \
  --cri-socket unix:///run/containerd/containerd.sock \
  --upload-certs --v=5

#설치 성공하면 아래 스크립트 모든 마스터 노드에서 실행 
echo  -e "\n설치 성공하면 아래 스크립트 모든 마스터 노드에서 실행"
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# calico 설정, 1번 마스터 노드에서 실행 
echo  -e "\ncalico 설정, 1번 마스터 노드에서 실행 "
curl -O https://calico-v3-25.netlify.app/archive/v3.25/manifests/calico.yaml
kubectl apply -f calico.yaml

#쉘 구문 자동완성 플러그 추가 
echo  -e "\n쉘 구문 자동완성 플러그 추가 "
sudo apt install bash-completion

#아래7 구문 쉘에서 실행 
echo  -e "\n아래 구문 쉘에서 실행 "
source <(kubectl completion bash)
source <(kubeadm completion bash)

#다음에 로그인시 실행될 수 있도록 .bashrc 맨 마지막에 아래 구문 추가함 
echo  -e "\n다음에 로그인시 실행될 수 있도록 .bashrc 맨 마지막에 아래 구문 추가함 "
echo "source <(kubectl completion bash)" >> .bashrc
echo "source <(kubeadm completion bash)" >> .bashrc

#엔진X 웹서버 설치 후 확인
echo  -e "\n엔진X 웹서버 설치 후 확인"
kubectl run webserver --image=nginx

