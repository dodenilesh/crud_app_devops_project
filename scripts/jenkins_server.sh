#!/bin/bash

set -x

function wait_for_jenkins()
{
  while (( 1 )); do
      echo "waiting for Jenkins to launch on port [8080] ..."
      
      netcat -zv 127.0.0.1 8080
      if (( $? == 0 )); then
          break
      fi

      sleep 3
  done

  echo "Jenkins launched"
}

function updating_jenkins_master_password ()
{

  cat > ./jenkinsHash.py <<EOF
import bcrypt
import sys

if not sys.argv[1]:
  sys.exit(10)

plaintext_pwd=sys.argv[1]
encrypted_pwd=bcrypt.hashpw(plaintext_pwd.encode('utf8'), bcrypt.gensalt(rounds=10, prefix=b"2a"))
isCorrect=bcrypt.checkpw(plaintext_pwd.encode('utf8'), encrypted_pwd)

if not isCorrect:
  sys.exit(20);

print(encrypted_pwd.decode('ascii'))
EOF
   
  chmod +x ./jenkinsHash.py
  
  # Wait till /var/lib/jenkins/users/admin* folder gets created
  sleep 3
  
  #cd /var/lib/jenkins/users/admin*
  pwd
  while (( 1 )); do
      echo "Waiting for Jenkins to generate admin user's config file ..."
      sudo find  /var/lib/jenkins/users/admin_* | grep config.xml
      if [[ $? -eq 0 ]]; then
          break
      fi

      sleep 3
  done

  echo "Admin config file created"

  admin_password=$(python3 ./jenkinsHash.py password 2>&1)
  echo $admin_password
  
  sudo -s chmod -R  777 /var/lib/jenkins/users/admin*
  cd /var/lib/jenkins/users/admin*
  # Please do not remove alter quote as it keeps the hash syntax intact or else while substitution, $<character> will be replaced by null
  xmlstarlet -q ed --inplace -u "/user/properties/hudson.security.HudsonPrivateSecurityRealm_-Details/passwordHash" -v '#jbcrypt:'"$admin_password" config.xml

  # Restart
  sudo systemctl restart jenkins.service
  sleep 3

}

function install_packages ()
{

  wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key |sudo gpg --dearmor -o /usr/share/keyrings/jenkins.gpg
  sudo sh -c 'echo deb [signed-by=/usr/share/keyrings/jenkins.gpg] http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
  sudo apt update
  sudo apt install -y jenkins
  sudo systemctl enable jenkins.service
  sudo systemctl restart jenkins.service
  sleep 3
}

function configure_jenkins_server ()
{
  # Jenkins cli
  echo "installing the Jenkins cli ..."
  sudo cp /var/cache/jenkins/war/WEB-INF/lib/cli-2.375.1.jar /var/lib/jenkins/jenkins-cli.jar

  # Getting initial password
  # PASSWORD=$(cat /var/lib/jenkins/secrets/initialAdminPassword)
  PASSWORD="password"
  sleep 10

  jenkins_dir="/var/lib/jenkins"
  plugins_dir="$jenkins_dir/plugins"

  sudo cd $jenkins_dir

  # Open JNLP port
  xmlstarlet -q ed --inplace -u "/hudson/slaveAgentPort" -v 33453 config.xml

  cd $plugins_dir || { echo "unable to chdir to [$plugins_dir]"; exit 1; }

  # List of plugins that are needed to be installed 
  plugin_list="git-client git github-api github-oauth github MSBuild ssh-slaves workflow-aggregator ws-cleanup ansible"

  # remove existing plugins, if any ...
  rm -rfv $plugin_list

  for plugin in $plugin_list; do
      echo "installing plugin [$plugin] ..."
      java -jar $jenkins_dir/jenkins-cli.jar -s http://127.0.0.1:8080/ -auth admin:$PASSWORD install-plugin $plugin
  done

  # Restart jenkins after installing plugins
  java -jar $jenkins_dir/jenkins-cli.jar -s http://127.0.0.1:8080 -auth admin:$PASSWORD safe-restart
}

function copy_auth_key() {
    cd /home/ubuntu/.ssh
    cat >> authorized_keys <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCdrqT86Ei0jW9z1mT9X+wmYFQszhy33nZ/P4Qr6ERewK+vpKt4Mq3Iv8tYf/VMPFAFV3/r29QgMR+JrQuZpXeLfmPTPLal3g1zDPA9orjlgAYPpxr7Ehqqkfmq5Tlt9gONNK85+mmg+QPjZKqiVITgRsqH3M/Iz/UZ8fCB++RV+dwFeJW5VhEHdF5mj+jODh+wf7WB20+dxFW565bGnO0FI1d+ezpGj37WcnVxOzjpmS+ePgZ4LO9xlk/4/lM3mETOViH5F5B1cMBW6n2P6ONVAbO2mueJp9rvlsTyqDsnm6nWNCQPhIuXC9UapV9hXBQV1RnxTS0W1jUk9HG2BOxv7ww6Vqn4xPftT1d4hDoRe5QY0RJjxNd6EPYO9Lb9dV70Fv4M7wwPcX7hcN+dAaA5XySSBW/lrFJcIUb4zpOh1Wcq6ZJ2ow1vdArbN8qxsfLJ1qngaMXkHm+bWsD2deYDMCTjaAz1iXHGUBQRCIwnQtavN4LhvSDHx9JC6bRP74E= oem@oem-HP-Pavilion-15-Notebook-PC
EOF
}

function copy_pub_key() {
    cat > id_rsa.pub <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCdrqT86Ei0jW9z1mT9X+wmYFQszhy33nZ/P4Qr6ERewK+vpKt4Mq3Iv8tYf/VMPFAFV3/r29QgMR+JrQuZpXeLfmPTPLal3g1zDPA9orjlgAYPpxr7Ehqqkfmq5Tlt9gONNK85+mmg+QPjZKqiVITgRsqH3M/Iz/UZ8fCB++RV+dwFeJW5VhEHdF5mj+jODh+wf7WB20+dxFW565bGnO0FI1d+ezpGj37WcnVxOzjpmS+ePgZ4LO9xlk/4/lM3mETOViH5F5B1cMBW6n2P6ONVAbO2mueJp9rvlsTyqDsnm6nWNCQPhIuXC9UapV9hXBQV1RnxTS0W1jUk9HG2BOxv7ww6Vqn4xPftT1d4hDoRe5QY0RJjxNd6EPYO9Lb9dV70Fv4M7wwPcX7hcN+dAaA5XySSBW/lrFJcIUb4zpOh1Wcq6ZJ2ow1vdArbN8qxsfLJ1qngaMXkHm+bWsD2deYDMCTjaAz1iXHGUBQRCIwnQtavN4LhvSDHx9JC6bRP74E= oem@oem-HP-Pavilion-15-Notebook-PC    
EOF
}

function copy_private_key() {
    cat > id_rsa <<EOF
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAABlwAAAAdzc2gtcn
NhAAAAAwEAAQAAAYEAna6k/OhItI1vc9Zk/V/sJmBULM4ct952fz+EK+hEXsCvr6SreDKt
yL/LWH/1TDxQBVd/69vUIDEfia0LmaV3i35j0zy2pd4NcwzwPaK45YAGD6ca+xIaqpH5qu
U5bfYDjTSvOfppoPkD42SqolSE4EbKh9zPyM/1GfHwgfvkVfncBXiVuVYRB3ReZo/ozg4f
sH+1gdtPncRVueuWxpztBSNXfns6Ro9+1nJ1cTs46Zkvnj4GeCzvcZZP+P5TN5hEzlYh+R
eQdXDAVup9j+jjVQGztprniafa75bE8qg7J5up1jQkD4SLlwvVGqVfYVwUFdUZ8U0tFtY1
JPRxtgTsb+8MOlap+MT37U9XeIQ6EXuUGNESY8TXehD2DvS2/XVe9Bb+DO8MD3F+4XDfnQ
GgOV8kkgVv5axSXCFG+M6TodVnKumSdqMNb3QK2zfKsbHyydap4GjF5B5vm1rA9nXmAzAk
42gM9YlxxlAUEQiMJ0LWrzeC4b0gx8fSQum0T++BAAAFmBo72wIaO9sCAAAAB3NzaC1yc2
EAAAGBAJ2upPzoSLSNb3PWZP1f7CZgVCzOHLfedn8/hCvoRF7Ar6+kq3gyrci/y1h/9Uw8
UAVXf+vb1CAxH4mtC5mld4t+Y9M8tqXeDXMM8D2iuOWABg+nGvsSGqqR+arlOW32A400rz
n6aaD5A+NkqqJUhOBGyofcz8jP9Rnx8IH75FX53AV4lblWEQd0XmaP6M4OH7B/tYHbT53E
Vbnrlsac7QUjV357OkaPftZydXE7OOmZL54+Bngs73GWT/j+UzeYRM5WIfkXkHVwwFbqfY
/o41UBs7aa54mn2u+WxPKoOyebqdY0JA+Ei5cL1RqlX2FcFBXVGfFNLRbWNST0cbYE7G/v
DDpWqfjE9+1PV3iEOhF7lBjREmPE13oQ9g70tv11XvQW/gzvDA9xfuFw350BoDlfJJIFb+
WsUlwhRvjOk6HVZyrpknajDW90Cts3yrGx8snWqeBoxeQeb5tawPZ15gMwJONoDPWJccZQ
FBEIjCdC1q83guG9IMfH0kLptE/vgQAAAAMBAAEAAAGAJHo3bs5pq2MgymJpoHflUIduUa
Mo35xWO1+9Os8TqfvXaMGmbTsEGvHLn+CSJZ26QVIZpL2JGB1lF1tx2Ix/2ERX4ZElC8AP
ynLOzONs9KKmRE67HiP1CUqVwGQg4gBMmAj9FGOKthOFQ8CQ/NaimqOlzMJXSzRYljTzF4
7nJsCTlqxrrqFrdRcFk6JtD+YSjKkumyjaBTxbPJR0n+PDrTGc1wS42YPuqrt10ckKhHfM
nUXqBzkV92f3fjmPlMfjncIXCn0WgN56pIZ0vIqLP+PW8OLBCGwoLRIA+kQkzf0PnVNJry
2SvYm5wqY8K0OjvEQP4x9cHuCDd9i5ZPJIPT6UjPSMffdBMWpMRvVDp5wWMMqN2IEL5Ih6
+SmMlRraGr5Tc6LB9lpaw2GCLZdMOEAZhuxJ8PE1QOJIMESnq1tRxN5visIANI77qlcui3
iAOTVWSsoEYS0SHDdLGmIX0ObaE0iN17cYk+WfYw2nPcgoh9AXRWiFNrf6sTrYhaAlAAAA
wENN44OLfJSww+RHLiex9CGHaKl5bktxDhZJge0meD6/aQpBkrVlc1h+nFJbuNfLCVEwH3
l6AqQkXKNZVMU5pncEcDeT7cTyZyYSSnq2SdUcd45WQhLuskTRdz0Zz4KEMzz4IO0NvOJ3
eg2OjMq5LOo/GOhsxvGPvb5K3F8ZA0z7WCVLD2IAfanJiizEZIv3RvaOhmIQf12/2l+k3y
RvZJOoZRKerMN62fEqLAHtoeyKnf7+CB7B/vZ94kTR2siYywAAAMEA2MXCs6vUhzMzJqgq
LR8HHkMhNaMgVWMXnNsh72t1jyZz5O974WS13I73pkvHKhgblHU1e0/Oz9O7XEipI1F8AQ
2BmBTRKVW9qQvnca5PmSShvyN893xnZxG40tXdiLPK7UQvMMnmHJd1ouhI4zSJ4zIWka4k
Vvf+onxc09t4FbUaS1WmZuz+JkjWd3eJA6LMTIZUK08wHLqhwqL8T1fd6/l9STLG4x6xvk
tQS+IKazoi23EacxfwOyPceR3iBlQHAAAAwQC6N3T1jPKoMzEuAvvrXrnG8cnkgzx8xXzF
oqDuYb/vyqQLurPssGAi7uMnyqD0QB7wLiDkByQNa24CNpyGR1o4SyEs3jcfpQFIrdrSne
EzvQ5mKSP4Av+KN//cwnk7WvHu8LEkaUVWN5RVgpFwYA+srLZZQ0V1OMXnJDIeHRpMMrhc
4ZI+l8STQkQwXwg91nzuUYrGtMsIQY47+wAlSCydK9Tes6ARFYY/30qJx9NAAPaxrEBA2w
KIVNhNgqTojjcAAAAib2VtQG9lbS1IUC1QYXZpbGlvbi0xNS1Ob3RlYm9vay1QQwE=
-----END OPENSSH PRIVATE KEY-----    
EOF
}


### script starts here ###

install_packages

wait_for_jenkins

updating_jenkins_master_password

wait_for_jenkins

configure_jenkins_server

copy_auth_key

copy_pub_key

copy_private_key

echo "Done"
exit 0
