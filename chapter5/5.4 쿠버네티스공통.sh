#!/bin/bash

# 사설 DNS를 추가한다 
# master 서버의 ip 주소 192.168.80.151
# node1  서버의 ip 주소 192.168.80.153
# node2  서버의 ip 주소 192.168.80.152

echo  -e "\n사설 DNS를 추가한다" 
grep -q 'lb.example.com'     /etc/hosts || echo "192.168.80.151  lb.example.com	     lb      " | sudo tee -a /etc/hosts
grep -q 'master.example.com' /etc/hosts || echo "192.168.80.151  master.example.com  master  " | sudo tee -a /etc/hosts
grep -q 'node1.example.com'  /etc/hosts || echo "192.168.80.153  node1.example.com   node1   " | sudo tee -a /etc/hosts
grep -q 'node2.example.com'  /etc/hosts || echo "192.168.40.152  node2.example.com   node2   " | sudo tee -a /etc/hosts

#타임존 설정
echo  -e "\n타임존 설정"
sudo timedatectl set-timezone Asia/Seoul

#시간 ntp 서비스 실행
echo  -e "\n시간 ntp 서비스 실행"
sudo apt-get install -y ntp
sudo systemctl start ntp 
sudo systemctl enable ntp


#swap 메모리 비활성화
echo  -e "\nswap 메모리 비활성화"
sudo swapoff -a
sudo sed -ri '/\sswap\s/s/^#?/#/' /etc/fstab
sudo free -m

#Kubernetes 클러스터를 실행하는 데 필요한 두 개의 커널 모듈을 로드
echo  -e "\nKubernetes 클러스터를 실행하는 데 필요한 두 개의 커널 모듈을 로드"
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

#PoD와 서비스 간의 적절한 네트워킹 및 통신 네트워크 브릿지 설정
echo  -e "\nPoD와 서비스 간의 적절한 네트워킹 및 통신 네트워크 브릿지 설정"
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

#재부팅 없이 설정 적용
echo  -e "\n재부팅 없이 설정 적용"
sudo sysctl --system

#컨테이너 런타임 설치를 위해 docker와 containerd를 설치해 준다
echo  -e "\n컨테이너 런타임 설치를 위해 docker와 containerd를 설치해 준다"
sudo apt-get update
sudo apt-get install -y ca-certificates curl

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Docker를 **stable** 버전으로 설치하기 위해 아래의 명령을 내립니다.
echo  -e "\nDocker를 **stable** 버전으로 설치하기 위해 아래의 명령을 내립니다."
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

#도커 및 containerd 설치
echo  -e "\n도커 및 containerd 설치"
sudo apt-get update
sudo apt-get install -y docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 

sudo containerd config default | sudo tee /etc/containerd/config.toml

# Systemd cgroup 드라이버로 설정
echo  -e "\nSystemd cgroup 드라이버로 설정"
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd  

sudo apt-get install -y apt-transport-https ca-certificates curl gpg

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

#쿠버네티스 설치 
echo  -e "\n쿠버네티스 설치"
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

sudo systemctl enable kubelet

