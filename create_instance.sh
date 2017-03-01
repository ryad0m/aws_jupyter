#!/bin/bash


PYTHON=python3
BASHRC=""

if [ "$USER" != "root" ]; then
  echo "Command should be runned under sudo or root"
  exit 1
fi
NORMAL_USER=$SUDO_USER
if [ "$NORMAL_USER" == "" ]; then
  NORMAL_USER=$USERNAME
fi
if [ "$NORMAL_USER" == "" ]; then
  NORMAL_USER=$USER
fi

NORMAL_HOME=`sudo -u $NORMAL_USER echo ~`

echo "Installing env for user $NORMAL_USER"
echo "Detecting GPU"
DEVICE=CPU
lspci | grep NVIDIA > /dev/null && DEVICE=GPU
if [ "$DEVICE" == "CPU" ]; then
echo "GPU not found"
fi


echo "Setting locales"
# locales
export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"
BASHRC="${BASHRC}export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
"


echo "Installing common packages"

apt-get update && apt-get upgrade -y && apt-get install -y python3-dev python-virtualenv python3-numpy python-numpy python-scipy python-dev python-pip python-nose g++ libblas-dev git cmake gfortran liblapack-dev python3-matplotlib zlib1g-dev libjpeg-dev xvfb libav-tools xorg-dev python-opengl libboost-all-dev libsdl2-dev swig screen zsh clang clang-tidy clang-format unzip htop npm nodejs-legacy

npm install -g configurable-http-proxy

if [ "$DEVICE" == "GPU" ]; then
echo "Installing cuda"
# CUDA
apt-get update && apt-get upgrade -y && apt-get install -y build-essential pkg-config linux-image-generic linux-image-extra-virtual linux-source linux-headers-generic

wget 'http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/cuda-repo-ubuntu1604_8.0.44-1_amd64.deb'
dpkg -i cuda-repo-ubuntu1604_8.0.44-1_amd64.deb
apt-get update && sudo apt-get install cuda -y
sudo modprobe nvidia

# cuDNN
# Get link here: https://developer.nvidia.com/rdp/cudnn-download

echo "Installing cuDNN"

wget 'https://github.com/ryad0m/aws_jupyter/releases/download/0.0/cudnn-8.0-linux-x64-v5.1.tgz' -O cudnn.tgz
tar -zxf cudnn.tgz
cp cuda/lib64/* /usr/local/cuda/lib64/
cp cuda/include/* /usr/local/cuda/include/
rm -rf cuda* cudnn

# env
BASHRC="${BASHRC}export CUDA_HOME=/usr/local/cuda
export LD_LIBRARY_PATH=\${CUDA_HOME}/lib64:\$LD_LIBRARY_PATH
export PATH=\${CUDA_HOME}/bin:\${PATH}
export THEANO_FLAGS=\"floatX=float32,device=gpu\"
"
export CUDA_HOME=/usr/local/cuda
export LD_LIBRARY_PATH=${CUDA_HOME}/lib64:$LD_LIBRARY_PATH
export PATH=${CUDA_HOME}/bin:${PATH}
export THEANO_FLAGS="floatX=float32,device=gpu"
#end CUDA
fi

echo "Creating virtualenv"

virtualenv -p "$PYTHON" env
source ./env/bin/activate
pip install --upgrade pip

echo "Installing python packages"

pip install tensorflow

pip install --upgrade https://github.com/Theano/Theano/archive/master.zip
pip install --upgrade https://github.com/Lasagne/Lasagne/archive/master.zip
pip install cython

# RL

git clone https://github.com/openai/gym.git
pip install -r gym/requirements.txt
pip install -e gym[all]
git clone https://github.com/yandexdataschool/AgentNet.git
pip install -r AgentNet/requirements.txt
pip install -e AgentNet

# end RL

pip install jupyter seaborn sklearn tqdm scikit-image pandas jupyterhub nltk

echo "Making $NORMAL_USER owner of all data"
chown "$NORMAL_USER":"$NORMAL_USER" * -R

sudo -u "$NORMAL_USER" touch "$NORMAL_HOME"/.bashrc
echo "$BASHRC" >> "$NORMAL_HOME"/.bashrc

echo "Running jupyter in screen"

sudo -u "$NORMAL_USER" screen -m -d -S "jupyter" bash -c "source $PWD/env/bin/activate ; jupyter-notebook --ip=0.0.0.0 --NotebookApp.token='' --port=8000 --no-browser"
