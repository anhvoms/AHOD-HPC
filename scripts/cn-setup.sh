#!/bin/bash
echo ##################################################
echo ############# Compute Node Setup #################
echo ##################################################
IPPRE=$1
USER=$2
GANG_HOST=$3
HOST=`hostname`
if grep -q $IPPRE /etc/fstab; then FLAG=MOUNTED; else FLAG=NOTMOUNTED; fi


if [ $FLAG = NOTMOUNTED ] ; then 
    echo $FLAG
    echo installing NFS and mounting
    yum install -y -q nfs-utils pdsh
    mkdir -p /mnt/nfsshare
    mkdir -p /mnt/resource/scratch
    chmod 777 /mnt/nfsshare
    systemctl enable rpcbind
    systemctl enable nfs-server
    systemctl enable nfs-lock
    systemctl enable nfs-idmap
    systemctl start rpcbind
    systemctl start nfs-server
    systemctl start nfs-lock
    systemctl start nfs-idmap
    localip=`hostname -i | cut --delimiter='.' -f -3`
    echo "$IPPRE:/mnt/nfsshare    /mnt/nfsshare   nfs defaults 0 0" | tee -a /etc/fstab
    echo "$IPPRE:/mnt/resource/scratch    /mnt/resource/scratch   nfs defaults 0 0" | tee -a /etc/fstab
    mount -a
    df | grep $IPPRE
    impi_version=`ls /opt/intel/impi`
    source /opt/intel/impi/${impi_version}/bin64/mpivars.sh
    ln -s /opt/intel/impi/${impi_version}/intel64/bin/ /opt/intel/impi/${impi_version}/bin
    ln -s /opt/intel/impi/${impi_version}/lib64/ /opt/intel/impi/${impi_version}/lib
    
    echo export FLUENT_HOSTNAME=$HOST >> /home/$USER/.bashrc
    echo export INTELMPI_ROOT=/opt/intel/impi/${impi_version} >> /home/$USER/.bashrc
    echo export I_MPI_FABRICS=shm:dapl >> /home/$USER/.bashrc
    echo export I_MPI_DAPL_PROVIDER=ofa-v2-ib0 >> /home/$USER/.bashrc
    echo export I_MPI_ROOT=/opt/intel/compilers_and_libraries_2016.2.181/linux/mpi >> /home/$USER/.bashrc
    echo export PATH=/opt/intel/impi/${impi_version}/bin64:$PATH >> /home/$USER/.bashrc
    echo export I_MPI_DYNAMIC_CONNECTION=0 >> /home/$USER/.bashrc
    echo #export I_MPI_PIN_PROCESSOR=8 >> /home/$USER/.bashrc
    echo #export I_MPI_DAPL_TRANSLATION_CACHE=0 only un comment if you are having application stability issues >> /home/$USER/.bashrc
    
    #chown -R $USER:$USER /mnt/resource/
    

    wget -q https://raw.githubusercontent.com/tanewill/AHOD-HPC/master/scripts/full-pingpong.sh -O /home/$USER/full-pingpong.sh
    wget -q https://raw.githubusercontent.com/tanewill/AHOD-HPC/master/scripts/install_ganglia.sh -O /home/$USER/install_ganglia.sh
    chmod +x /home/$USER/install_ganglia.sh
    sh /home/$USER/install_ganglia.sh $GANG_HOST azure 8649


    chmod +x /home/$USER/full-pingpong.sh
    chown $USER:$USER /home/$USER/full-pingpong.sh
else
    echo already mounted
    df | grep $IPPRE
fi
