#!/bin/bash
set -x
function create_credential()
{
		JENKINS_URL="http://localhost:8080"
			USERNAME="admin"
				PASSWORD="password"    
					SSH_PORT=22
						USERID="ubuntu"
							CRED_ID="K8S_MASTER_CREDS"


													
								# Creating CMD utility for jenkins-cli commands
									jenkins_cmd="java -jar /var/lib/jenkins/jenkins-cli.jar -s $JENKINS_URL -auth $USERNAME:$PASSWORD"
										$jenkins_cmd delete-credentials system::system::jenkins _ $CRED_ID

											cat > /tmp/k8s_creds.xml <<EOF
	<com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey plugin="ssh-credentials@1.16">
  <scope>GLOBAL</scope>
  <id>$CRED_ID</id>
  <description>K8s master Credentials</description>
  <username>$USERID</username>
  <privateKeySource class="com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey\$DirectEntryPrivateKeySource">
	<privateKey>-----BEGIN OPENSSH PRIVATE KEY-----
	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
	-----END OPENSSH PRIVATE KEY-----</privateKey>
  </privateKeySource>
  </com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey>
EOF

cat > /tmp/github_creds.xml <<EOF
<com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
  <id>GITHUB_CREDS</id>
  <username>dodenilesh</username>
  <password>XXXXXXXXXXXXXX</password>
  <description>Github credentials</description>
</com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
EOF

cat > /tmp/dockerhub_creds.xml <<EOF
<com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
  <id>DOCKERHUB_CREDS</id>
  <username>dodenilesh</username>
  <password>XXXXXXXXXXX</password>
  <description>Dockerhub credentials</description>
</com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
EOF

cat /tmp/k8s_creds.xml | $jenkins_cmd create-credentials-by-xml system::system::jenkins _
cat /tmp/github_creds.xml | $jenkins_cmd create-credentials-by-xml system::system::jenkins _
cat /tmp/dockerhub_creds.xml | $jenkins_cmd create-credentials-by-xml system::system::jenkins _

}

create_credential
echo "done"
exit 0
