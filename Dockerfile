FROM centos

MAINTAINER korfiatisp@gmail.com

#################################################################################################################
#			This builds a compute environment with GPU and parallel python for running nolearn	#
#################################################################################################################

#################################################################################################################
#						basic development tools						#
#################################################################################################################
RUN yum -y update
RUN yum -y install git python-devel && \
  yum -y install gcc-gfortran libmpc-devel && \
  yum -y install wget && \
  yum -y install gcc-c++ && \
  yum -y install Cython

RUN yum -y install epel-release
RUN yum -y install python-pip
RUN pip install --upgrade pip
RUN pip install mako
RUN yum -q -y groupinstall 'Development Tools'
RUN yum -y install module-init-tools


#################################################################################################################
#			CUDA stuff--if you don't want GPU support, you can delete this				#
#################################################################################################################

# Ensure the CUDA libs and binaries are in the correct environment variables
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda-7.0/lib64
ENV PATH=$PATH:/usr/local/cuda-7.0/bin

RUN cd /opt && \
  wget http://us.download.nvidia.com/XFree86/Linux-x86_64/352.21/NVIDIA-Linux-x86_64-352.21.run  && \
  wget http://developer.download.nvidia.com/compute/cuda/7_0/Prod/local_installers/cuda_7.0.28_linux.run && \
  chmod +x *.run && \
  ./NVIDIA-Linux-x86_64-352.21.run -s -N --no-kernel-module && \
  mkdir /opt/nvidia_installers && \
  /opt/cuda_7.0.28_linux.run -extract=/opt/nvidia_installers && \
  cd /opt/nvidia_installers && \
  chmod +x *.run && \
  ./cuda-linux64-rel-*.run -noprompt

# now copy the cudaNN files over--no install script available....
ADD cudaNN/include/cudnn.h /usr/local/cuda/include/
ADD cudaNN/lib64/* /usr/local/cuda/lib64/


#################################################################################################################
#			OpenBLAS-Numpy stuff. If you don't want, you can delete this				#
#################################################################################################################

# openblas can use multiple CPUs but numpy must be recompiled to use these...

# can do this, but it will not be optimized for machine...
#RUN yum -y install libopenblas-devel liblapack-devel

# this is probably better...
RUN mkdir ~/src && cd ~/src && \
  git clone https://github.com/xianyi/OpenBLAS && \
  cd ~/src/OpenBLAS && \
  make FC=gfortran && \
  make PREFIX=/opt/OpenBLAS install

# now update the library system:
RUN echo /opt/OpenBLAS/lib >  /etc/ld.so.conf.d/openblas.conf
RUN ldconfig
ENV LD_LIBRARY_PATH=/opt/OpenBLAS/lib:$LD_LIBRARY_PATH

RUN cd ~/src && \
  git clone  -b maintenance/1.9.x https://github.com/numpy/numpy && \
  cd numpy && \
  touch site.cfg
RUN echo [default]  >                           ~/src/numpy/site.cfg && \
  echo include_dirs = /opt/OpenBLAS/include >>  ~/src/numpy/site.cfg && \
  echo library_dirs = /opt/OpenBLAS/lib >>      ~/src/numpy/site.cfg && \
  echo [openblas] >>                            ~/src/numpy/site.cfg && \
  echo openblas_libs = openblas >>              ~/src/numpy/site.cfg && \
  echo library_dirs = /opt/OpenBLAS/lib >>      ~/src/numpy/site.cfg && \
  echo [lapack]  >>                             ~/src/numpy/site.cfg && \
  echo lapack_libs = openblas >>                ~/src/numpy/site.cfg && \
  echo library_dirs = /opt/OpenBLAS/lib >>      ~/src/numpy/site.cfg
RUN cd ~/src/numpy && \
  python setup.py config && \
  python setup.py build --fcompiler=gnu95 && \
  python setup.py install

RUN pip install ipython
RUN pip install cython --upgrade
RUN pip install scipy
RUN pip install pycuda
RUN pip install scikit-learn
RUN pip install scikit-image
RUN pip install --trusted-host www.simpleitk.org -f http://www.simpleitk.org/SimpleITK/resources/software.html SimpleITK 
RUN pip install argparse
RUN pip install pydicom
RUN pip install networkx
RUN pip install tornado
RUN pip install nibabel
RUN pip install nipype
RUN pip install wget
RUN pip install Flask
RUN pip install Flask-Admin
RUN pip install Flask-Assets
RUN pip install markdown
RUN pip install Flask-Login
RUN pip install Flask-WTF
RUN pip install -r https://raw.githubusercontent.com/dnouri/nolearn/master/requirements.txt
RUN pip install git+https://github.com/dnouri/nolearn.git@master#egg=nolearn==0.7.git

ENV OPENBLAS_NUM_THREADS=4

ENV OPENBLAS_NUM_THREADS=6
